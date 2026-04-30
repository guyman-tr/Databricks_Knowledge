# BackOffice.AccountStatement_GetTaxReport_v3

> Generates a comprehensive single-row tax summary (23 categories) for a customer's account activity over a date range, extending v2 with a unified Commission column and enhanced CA Type dividend detection.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the latest version of eToro's customer tax report SP. It aggregates all financial events for a customer within a date range into 23 distinct tax categories for multi-jurisdictional regulatory reporting. It covers CFD P&L (with and without TRS), crypto P&L, real stocks and ETF P&L, dividends (including CA Type corporate action dividends), staking income, airdrops, spin-offs, index adjustments, SDRT, fees, compensation, stocks lending, and a unified Commission category - making it the most complete version in the AccountStatement_GetTaxReport series.

v3 extends v2 in two key ways: it adds a `Commission` output column that sums open and close total fees (CreditTypeID=3 -> OpenTotalFees, CreditTypeID=4 -> CloseTotalFees) for a single unified commission figure; and it extends `DividendsFromReal` to also capture CA Type corporate action dividend events via LIKE patterns (`CA Type=3:Cash Dividend`, `CA Type=1:Dividend`), which v2 missed.

Data flows as follows: BackOffice or the reporting layer calls this procedure with a customer ID and date range (typically a tax year). The CTE `HistoryCreditRecords` reads `History.CreditWithFee` as the primary source; `RawData` enriches records by joining to `Trade.GetPositionDataForExternalUse` (position data), `Trade.InstrumentMetaData` (InstrumentTypeID), `DB_Logs.History` tables (IsTransferredOut detection), and `Trade.PositionsProcessedForIndexDividnds`/`Trade.IndexDividends` (TaxCode and DLT markup fields). The `UserRegulation` CTE captures the customer's regulation history during the period but is not included in the final SELECT output. All data is aggregated into a single row with 23 SUM/ISNULL columns.

---

## 2. Business Logic

### 2.1 Asset Class Classification via IsSettled + InstrumentTypeID + SettlementTypeID

**What**: Distinguishes five taxable asset classes using position settlement attributes.

**Columns/Parameters Involved**: `IsSettled`, `InstrumentTypeID` (from Trade.InstrumentMetaData), `SettlementTypeID` (from GetPositionDataForExternalUse), `ActionType`

**Rules**:
- `ActionType=19` = Redeem transaction - excluded from all P&L columns (ActionType != 19 filter)
- `IsSettled=0` (or NULL) = CFD position
- `COALESCE(SettlementTypeID, IsSettled, 0) = 0` = CFD excluding TRS (CFDWithoutTRSPnL)
- `SettlementTypeID=2` = TRS (Total Return Swap) position - separate tax category
- `IsSettled=1` AND `InstrumentTypeID=10` = Crypto real position
- `IsSettled=1` AND `InstrumentTypeID=5` = Real Stocks
- `IsSettled=1` AND `InstrumentTypeID=6` = Real ETF

**Diagram**:
```
CreditTypeID=4 (Close Position)
   ActionType=19 (Redeem)               ->  excluded from ALL P&L columns
   ActionType!=19, IsSettled=0/NULL     ->  CFDPnL + CFDWithoutTRSPnL
   ActionType!=19, SettlementTypeID=2   ->  TRSPnL (+ CFDPnL)
   ActionType!=19, IsSettled=1, InstrType=10  ->  CryptoPnL
   ActionType!=19, IsSettled=1, InstrType=5   ->  RealStocksPnL
   ActionType!=19, IsSettled=1, InstrType=6   ->  RealETFPnL
```

### 2.2 TRS (Total Return Swap) as Distinct Tax Category

**What**: TRS positions are synthetic exposures to real assets via swap contracts. They occupy a different tax category from standard CFDs and real positions.

**Columns/Parameters Involved**: `SettlementTypeID`, `CFDPnL`, `CFDWithoutTRSPnL`, `TRSPnL`, `TRSFullCommissionOnClose`

**Rules**:
- `SettlementTypeID=2` identifies TRS positions
- `CFDPnL` includes TRS P&L (IsSettled=0 check does not exclude TRS)
- `CFDWithoutTRSPnL` explicitly excludes TRS via `COALESCE(SettlementTypeID, IsSettled, 0) = 0`
- `TRSPnL` captures ONLY TRS positions via `SettlementTypeID = 2`
- Relationship: `CFDPnL ~= CFDWithoutTRSPnL + TRSPnL` (approximately, when excluding positive overnight fee credits)

### 2.3 CFD PnL Includes Positive Overnight/Weekend Fees

**What**: Positive overnight/weekend fee credits are counted as CFD income (not excluded).

**Columns/Parameters Involved**: `CreditTypeID`, `Description`, `TotalCashChange`, `CFDPnL`, `CFDWithoutTRSPnL`

**Rules**:
- `CreditTypeID=14` AND `Description IN ('Over night fee', 'Weekend fee')` AND `TotalCashChange > 0` counts as CFDPnL and CFDWithoutTRSPnL
- Negative overnight/weekend fee charges are excluded from P&L columns and may fall into Fees

### 2.4 IsTransferredOut - Excluding Transferred Positions

**What**: Positions physically transferred out of eToro should not be counted in standard P&L.

**Columns/Parameters Involved**: `IsTransferredOut` (BIT, derived from DB_Logs), `CryptoPnL`, `RealStocksPnL`

**Rules**:
- Source: `DB_Logs.History.ManualPositionClose_Crisis` WHERE `ManualOperationReasonID='6'` (reason 6 = transfer out)
- `IsTransferredOut IS NULL` = position was NOT transferred (standard close) - included in P&L
- `IsTransferredOut = 1` = position was transferred out - excluded from `CryptoPnL` and `RealStocksPnL`
- `RealETFPnL` does NOT have the `IsTransferredOut` filter (by design)

### 2.5 Crypto Commission - DLT Markup Logic

**What**: Crypto commission uses complex DLT (Digital Ledger Technology) markup logic when DLT flags are set.

**Columns/Parameters Involved**: `CryptoFullCommissionOnClose`, `DLTOpen`, `DLTClose`, `CloseMarkup`, `OpenMarkupByUnits`, `CommissionByUnits`

**Rules**:
- `DLTOpen=1 AND DLTClose=1` -> commission = `CloseMarkup + OpenMarkupByUnits`
- `DLTOpen=1 AND DLTClose=0` -> commission = `CloseMarkup + CommissionByUnits / 2.0`
- Otherwise -> standard `CommissionOnClose`
- All commission columns multiplied by -1 to return positive cost values to callers

### 2.6 Enhanced Dividend Detection (v3 Extension)

**What**: v3 extends DividendsFromReal to capture CA Type corporate action dividend events using LIKE pattern matching, in addition to the standard 'Payment caused by dividend' description used in v2.

**Columns/Parameters Involved**: `DividendsFromReal`, `TaxCode`, `IsBuy`, `Payment`, `TotalCashChange`

**Rules**:
- Standard path (from v2): `Description='Payment caused by dividend'`, `IsSettled=1`, `IsBuy=1`, `TaxCode NOT IN ('999','998')` -> uses `TotalCashChange`
- New CA Type path (v3 addition): `Description LIKE '%CA Type=3:Cash Dividend%' OR Description LIKE '%CA Type=1:Dividend%'` -> uses `Payment` field (not TotalCashChange)
- `TaxCode NOT IN ('999', '998')` OR NULL = real dividend, counted in DividendsFromReal or DividendsFromCFD
- `TaxCode IN ('999', '998')` = index adjustment event -> counted in IndexAdjustments
- `IsBuy=1` = long position - dividends counted; short positions excluded

### 2.7 Unified Commission Column (v3 Addition)

**What**: v3 introduces a `Commission` output column that aggregates open and close total fees across position open (CreditTypeID=3) and close (CreditTypeID=4) events.

**Columns/Parameters Involved**: `Commission`, `OpenTotalFees`, `CloseTotalFees`, `CreditTypeID`

**Rules**:
- `CreditTypeID=3` (position open): uses `OpenTotalFees`
- `CreditTypeID=4` (position close): uses `CloseTotalFees`
- All other CreditTypeIDs contribute 0
- This provides a single combined commission figure vs. the per-asset-class commission columns

### 2.8 Compensation Routing by CompensationReasonID

**What**: Compensation events are routed to different output columns based on their reason code.

**Columns/Parameters Involved**: `Compensation`, `StocksLending`, `StakingIncome`, `AirDropIncome`, `SpinOffIncome`, `CompensationReasonID`

**Rules**:
- Generic Compensation: `CompensationReasonID NOT IN (57, 58, 91, 111, 112, 119)` -> `Compensation` (uses Payment)
- `CompensationReasonID=58` -> `AirDropIncome` (airdrop token distributions)
- `CompensationReasonID=91` -> `StakingIncome` (crypto staking rewards)
- `CompensationReasonID=111` and `112` -> counted in `Fees` (not Compensation)
- `CompensationReasonID=119` -> `StocksLending` (income from lending real stock positions)
- `CompensationReasonID=75` -> `SpinOffIncome` (corporate spin-off distributions)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters all source records in History.CreditWithFee and History.BackOfficeCustomer. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of reporting period (inclusive: `Occurred >= @StartDate`). Typically the first day of a tax year. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of reporting period (exclusive: `Occurred < @EndDate`). Typically the first day of the following year. |

**Result Set - Single-Row Comprehensive Tax Summary (23 columns):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CFDPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed CFD positions (CreditTypeID=4, ActionType!=19, IsSettled=0/NULL) PLUS positive overnight/weekend fee credits. Includes TRS P&L. Always ISNULL(...,0). |
| 5 | CFDWithoutTRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0) plus positive overnight/weekend credits. Explicitly excludes TRS (SettlementTypeID=2). |
| 6 | TRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from Total Return Swap positions (CreditTypeID=4, ActionType!=19, SettlementTypeID=2). TRS = synthetic equity exposure via swap, treated as separate tax category. |
| 7 | CryptoPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real crypto positions (CreditTypeID=4, ActionType!=19, IsSettled=1, InstrumentTypeID=10, IsTransferredOut IS NULL). Excludes physically transferred positions. |
| 8 | RealStocksPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5, IsTransferredOut IS NULL). Taxable equity capital gains; transfers excluded. |
| 9 | RealETFPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6). No IsTransferredOut filter for ETFs. |
| 10 | SdrtCharge | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from SDRT (Stamp Duty Reserve Tax) charges (CreditTypeID=14, Description='SDRT Charge'). UK-specific tax on real stock purchases. |
| 11 | DividendsFromReal | MONEY | NO | 0 | VERIFIED | Sum of dividend payments on real stock/ETF long positions. Two paths: (1) standard 'Payment caused by dividend' with IsSettled=1, IsBuy=1, TaxCode not in ('999','998') using TotalCashChange; (2) CA Type corporate action dividends (Description LIKE '%CA Type=3:Cash Dividend%' or '%CA Type=1:Dividend%') using Payment field. v3 adds path 2. |
| 12 | DividendsFromCFD | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from dividend adjustments on CFD long positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=0/NULL, IsBuy=1 or NULL, TaxCode NOT IN ('999','998')). CFD dividend-equivalent credits. |
| 13 | Compensation | MONEY | NO | 0 | VERIFIED | Sum of Payment from generic compensation credits (CreditTypeID=6, CompensationReasonID NOT IN (57,58,91,111,112,119)). Trading error refunds and goodwill payments. |
| 14 | StocksLending | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from stocks lending income (CreditTypeID=6, CompensationReasonID=119). Income earned by lending real stock positions to other market participants. |
| 15 | CFDFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL) multiplied by -1. Returns positive cost value to callers. |
| 16 | CFDWithoutTRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0) multiplied by -1. Excludes TRS commissions. |
| 17 | TRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from TRS positions (SettlementTypeID=2) multiplied by -1. |
| 18 | CryptoFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Crypto commission cost (CreditTypeID=4, IsSettled=1, InstrumentTypeID=10) using DLT markup logic when applicable (CloseMarkup+OpenMarkupByUnits or +CommissionByUnits/2), otherwise standard CommissionOnClose, multiplied by -1. |
| 19 | RealStocksFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5) multiplied by -1. |
| 20 | RealETFFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6) multiplied by -1. |
| 21 | Fees | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from fee events: CreditTypeID IN (15,14) excluding dividends, SDRT, and positive overnight/weekend fees; PLUS CreditTypeID=6 with CompensationReasonID IN (111,112). |
| 22 | StakingIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from staking rewards (CreditTypeID=6, CompensationReasonID=91). Income earned by staking crypto assets on the platform. |
| 23 | AirDropIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from airdrop credits (CreditTypeID=6, CompensationReasonID=58). Tokens distributed to existing holders as a promotional or network event. |
| 24 | SpinOffIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from corporate spin-off events (CreditTypeID=6, CompensationReasonID=75). Value received when a company distributes shares of a subsidiary to shareholders. |
| 25 | Commission | MONEY | NO | 0 | CODE-BACKED | NEW in v3. Unified commission total: sum of OpenTotalFees for position open events (CreditTypeID=3) and CloseTotalFees for position close events (CreditTypeID=4). Provides a single combined commission figure across the reporting period. |
| 26 | IndexAdjustments | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from index-dividend events with TaxCode IN ('999','998') (CreditTypeID=14, Description='Payment caused by dividend'). Synthetic dividend adjustments from index rebalancing, taxed differently from cash dividends. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.CreditWithFee | Implicit | Primary source: all fee-inclusive credit events for the customer in the date range |
| CreditTypeID | Dictionary.CreditType | Lookup (JOIN) | Joined in RawData CTE for event type name; CreditTypeID drives all CASE classification |
| @CID / PositionID | Trade.GetPositionDataForExternalUse | Lookup (LEFT JOIN) | Retrieves position data: IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, IsBuy, ActionType, OpenTotalFees, CloseTotalFees |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | Provides InstrumentTypeID for asset class classification (5=stocks, 6=ETF, 10=crypto) |
| PositionID | DB_Logs.History.ManualPositionClose_Crisis | Lookup (LEFT JOIN) | Detects positions closed via manual transfer operation (ManualOperationReasonID='6') |
| OperationID | DB_Logs.History.ManualOperationPositionClose_Crisis | Lookup (JOIN) | Joined to confirm the operation type for transfer-close detection |
| CreditID | Trade.PositionsProcessedForIndexDividnds | Lookup (LEFT JOIN) | Links credit events to index dividend processing records |
| DividendID | Trade.IndexDividends | Lookup (LEFT JOIN) | Provides TaxCode, DLTOpen, DLTClose, CloseMarkup, OpenMarkupByUnits, CommissionByUnits |
| @CID | History.BackOfficeCustomer | Lookup (CTE) | UserRegulation CTE captures regulation history during the period (structural; not returned in output) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | External | Direct call | Reporting layer calls this procedure to generate customer tax report (most current version) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatement_GetTaxReport_v3 (procedure)
|- History.CreditWithFee (table/view) [CTE HistoryCreditRecords - primary source]
|- Dictionary.CreditType (table) [INNER JOIN in RawData for event type classification]
|- Trade.GetPositionDataForExternalUse (view) [LEFT JOIN for position attributes]
|- Trade.InstrumentMetaData (table/view) [LEFT JOIN for InstrumentTypeID]
|- DB_Logs.History.ManualPositionClose_Crisis (table) [LEFT JOIN for IsTransferredOut]
|- DB_Logs.History.ManualOperationPositionClose_Crisis (table) [JOIN to confirm transfer operation]
|- Trade.PositionsProcessedForIndexDividnds (table) [LEFT JOIN via CreditID for DividendID link]
|- Trade.IndexDividends (table) [LEFT JOIN for TaxCode and DLT markup fields]
+-- History.BackOfficeCustomer (table) [CTE UserRegulation - regulation history, not in output]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditWithFee | Table/View | Primary source: fee-inclusive cash events for @CID in date range |
| Dictionary.CreditType | Table | INNER JOIN for CreditTypeID-to-name mapping; drives all CASE classification |
| Trade.GetPositionDataForExternalUse | View | LEFT JOIN for position data: IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, InstrumentID, ActionType, IsBuy, OpenTotalFees, CloseTotalFees |
| Trade.InstrumentMetaData | Table/View | LEFT JOIN on InstrumentID for InstrumentTypeID (5=stocks, 6=ETF, 10=crypto) |
| DB_Logs.History.ManualPositionClose_Crisis | Table | LEFT JOIN to detect positions transferred out of eToro (ManualOperationReasonID='6') |
| DB_Logs.History.ManualOperationPositionClose_Crisis | Table | Joined to ManualPositionClose_Crisis to confirm the operation type |
| Trade.PositionsProcessedForIndexDividnds | Table | LEFT JOIN via CreditID to link credit events to dividend processing records |
| Trade.IndexDividends | Table | LEFT JOIN via DividendID for TaxCode, DLTOpen, DLTClose, CloseMarkup, OpenMarkupByUnits, CommissionByUnits |
| History.BackOfficeCustomer | Table | UserRegulation CTE: customer regulation history during the period (not returned in output) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Primary caller for tax report generation (current version) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range | Application | Inclusive-start, exclusive-end: `Occurred >= @StartDate AND Occurred < @EndDate` |
| All outputs ISNULL wrapped | Design | Every output column uses `ISNULL(SUM(...), 0)` - no NULL values returned |
| Commission negation | Design | All `*FullCommissionOnClose` columns multiplied by -1 - costs returned as positive numbers |
| ActionType filter | Application | `ActionType != 19` excludes Redeem-type position closes from P&L and commission columns |
| IsTransferredOut | Application | Positions from ManualOperationReasonID='6' within the date range excluded from Crypto and RealStocks P&L |
| UserRegulation CTE | Design | UserRegulation CTE is defined but not used in the final SELECT - included for future use or historical alignment |

---

## 8. Sample Queries

### 8.1 Get full tax summary for a customer for tax year 2024

```sql
EXEC BackOffice.AccountStatement_GetTaxReport_v3
    @CID = 12345,
    @StartDate = '2024-01-01',
    @EndDate = '2025-01-01'
-- Returns single row with 23 aggregated tax categories including Commission
```

### 8.2 Compare v3 Commission column vs per-asset-class commissions

```sql
-- After running EXEC above, sum per-asset commissions to validate Commission column:
-- Commission = OpenTotalFees(CreditTypeID=3) + CloseTotalFees(CreditTypeID=4)
-- Verify against CFDFullCommissionOnClose + TRSFullCommissionOnClose + CryptoFullCommissionOnClose
--             + RealStocksFullCommissionOnClose + RealETFFullCommissionOnClose
SELECT SUM(CASE WHEN CreditTypeID = 3 THEN OpenTotalFees WHEN CreditTypeID = 4 THEN CloseTotalFees ELSE 0 END) AS UnifiedCommission
FROM Trade.GetPositionDataForExternalUse WITH (NOLOCK)
WHERE CID = 12345
```

### 8.3 Check InstrumentTypeID values used in asset classification

```sql
SELECT InstrumentTypeID, COUNT(*) AS InstrumentCount, MIN(InstrumentID) AS SampleID
FROM Trade.InstrumentMetaData WITH (NOLOCK)
WHERE InstrumentTypeID IN (5, 6, 10)
GROUP BY InstrumentTypeID
-- 5=Real Stocks, 6=Real ETF, 10=Crypto
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [AccountStatement_GetTaxReport_v2](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11654137040/AccountStatement_GetTaxReport_v2) for the draw.io architecture diagram covering the shared tax report logic.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 16 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.AccountStatement_GetTaxReport_v3 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatement_GetTaxReport_v3.sql*
