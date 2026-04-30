# BackOffice.AccountStatement_GetTaxReport_v2

> Generates a comprehensive single-row tax summary for a customer's account activity, covering 22 aggregated financial categories including TRS, crypto DLT commissions, staking/airdrop income, SDRT, and index adjustments - the most complete version of the tax report pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the most feature-complete version of eToro's customer tax report SP. It aggregates all financial events for a customer over a date range into 22 distinct tax categories required for multi-jurisdictional regulatory reporting. It covers CFD P&L (with and without TRS), crypto P&L, real stocks and ETF P&L, dividends, staking income, airdrops, spin-offs, index adjustments, SDRT, fees, compensation, and stocks lending - a comprehensive view of every taxable event type currently supported by the platform.

This version was introduced as part of the COFKV-787/765 redesign (July 2020) and represents the current standard for BackOffice tax report generation. It diverges from v1 in three fundamental ways: it uses `Trade.GetPositionDataForExternalUse` (the external/safe data view) instead of `Trade.GetPositionData`; it uses `Trade.InstrumentMetaData.InstrumentTypeID` instead of `Dictionary.Currency.CurrencyTypeID` for asset-class classification; and it introduces Total Return Swap (TRS) as a distinct tax category alongside the standard CFD/crypto/real split. It also adds IsTransferredOut detection via `DB_Logs.History` tables to exclude positions that were physically transferred out of eToro from P&L calculations.

Data flows as follows: BackOffice or the reporting layer calls this procedure with a customer ID and date range (typically a tax year). The CTE reads `History.CreditWithFee` as the primary source, enriches records by joining to `GetPositionDataForExternalUse` (for position data), `InstrumentMetaData` (for InstrumentTypeID/SettlementTypeID), `DB_Logs.History` (for IsTransferredOut), and `Trade.PositionsProcessedForIndexDividnds`/`Trade.IndexDividends` (for TaxCode and DLT markup fields). All data is aggregated into a single row with 22 SUM/ISNULL columns, one per tax category. Unlike v1, there is no jurisdiction/withholding-tax output - that concern is handled separately.

---

## 2. Business Logic

### 2.1 Asset Class Classification via IsSettled + InstrumentTypeID + SettlementTypeID

**What**: Distinguishes five taxable asset classes using position settlement attributes.

**Columns/Parameters Involved**: `IsSettled`, `InstrumentTypeID` (from Trade.InstrumentMetaData), `SettlementTypeID` (from GetPositionDataForExternalUse), `ActionType`

**Rules**:
- `ActionType=19` = Redeem transaction - excluded from P&L columns (ActionType != 19 filter)
- `IsSettled=0` (or NULL) = CFD position
- `COALESCE(SettlementTypeID, IsSettled, 0) = 0` = CFD excluding TRS (CFDWithoutTRSPnL)
- `SettlementTypeID=2` = TRS (Total Return Swap) position - separate tax category
- `IsSettled=1` AND `InstrumentTypeID=10` = Crypto real position
- `IsSettled=1` AND `InstrumentTypeID=5` = Real Stocks
- `IsSettled=1` AND `InstrumentTypeID=6` = Real ETF

**Diagram**:
```
CreditTypeID=4 (Close Position)
   ActionType=19 (Redeem)         ->  excluded from ALL P&L columns
   ActionType<>19, IsSettled=0/NULL  ->  CFDPnL (also includes CFDWithoutTRSPnL)
   ActionType<>19, SettlementTypeID=2  ->  TRSPnL (and CFDPnL if IsSettled=0)
   ActionType<>19, IsSettled=1, InstrumentTypeID=10  ->  CryptoPnL
   ActionType<>19, IsSettled=1, InstrumentTypeID=5   ->  RealStocksPnL
   ActionType<>19, IsSettled=1, InstrumentTypeID=6   ->  RealETFPnL
```

### 2.2 TRS (Total Return Swap) as Distinct Tax Category

**What**: TRS positions are synthetic exposures to real assets via swap contracts. They occupy a different tax category from standard CFDs and real positions.

**Columns/Parameters Involved**: `SettlementTypeID`, `CFDPnL`, `CFDWithoutTRSPnL`, `TRSPnL`, `TRSFullCommissionOnClose`

**Rules**:
- `SettlementTypeID=2` identifies TRS positions
- `CFDPnL` includes TRS P&L (IsSettled=0 check does not exclude TRS)
- `CFDWithoutTRSPnL` explicitly excludes TRS via `COALESCE(SettlementTypeID, IsSettled, 0) = 0`
- `TRSPnL` captures ONLY TRS positions via `SettlementTypeID = 2`
- Relationship: `CFDPnL = CFDWithoutTRSPnL + TRSPnL` (approximately, when no overnight fee positive credits)

### 2.3 CFD PnL includes Positive Overnight/Weekend Fees

**What**: In v2, positive overnight/weekend fee credits are counted as CFD income (not excluded as in v1).

**Columns/Parameters Involved**: `CreditTypeID`, `Description`, `TotalCashChange`

**Rules**:
- `CreditTypeID=14` AND `Description IN ('Over night fee', 'Weekend fee')` AND `TotalCashChange > 0` counts as CFDPnL
- Same positive overnight/weekend fees are also included in CFDWithoutTRSPnL
- Negative overnight/weekend fee charges are excluded from P&L columns and may fall into Fees

### 2.4 IsTransferredOut - Excluding Transferred Positions

**What**: Positions physically transferred out of eToro (e.g., to another broker) should not be counted in standard P&L. v2 adds this detection.

**Columns/Parameters Involved**: `IsTransferredOut` (BIT, derived from DB_Logs), `CryptoPnL`, `RealStocksPnL`

**Rules**:
- Source: `DB_Logs.History.ManualPositionClose_Crisis` WHERE `ManualOperationReasonID='6'` (reason 6 = transfer out)
- `IsTransferredOut IS NULL` = position was NOT transferred (standard close) - included in P&L
- `IsTransferredOut = 1` = position was transferred out - excluded from `CryptoPnL` and `RealStocksPnL`
- `RealETFPnL` does NOT have the `IsTransferredOut` filter (by design in current code)

### 2.5 Crypto Commission - DLT Markup Logic

**What**: Crypto commission calculation uses a complex DLT (Digital Ledger Technology) markup logic when DLT flags are set, instead of the standard CommissionOnClose.

**Columns/Parameters Involved**: `CryptoFullCommissionOnClose`, `DLTOpen`, `DLTClose`, `CloseMarkup`, `OpenMarkupByUnits`, `CommissionByUnits`

**Rules**:
- Source fields from `Trade.IndexDividends` via `Trade.PositionsProcessedForIndexDividnds`
- `DLTOpen=1 AND DLTClose=1` -> commission = `CloseMarkup + OpenMarkupByUnits`
- `DLTOpen=1 AND DLTClose=0` -> commission = `CloseMarkup + CommissionByUnits / 2.0`
- Otherwise -> standard `CommissionOnClose`
- All commission columns multiplied by -1 to represent positive cost values to callers

### 2.6 Dividend Filtering by IsBuy and TaxCode

**What**: Dividends in v2 are filtered by direction (IsBuy=1 = long positions) and by TaxCode to separate real dividends from index adjustments.

**Columns/Parameters Involved**: `DividendsFromReal`, `DividendsFromCFD`, `IndexAdjustments`, `TaxCode` (from Trade.IndexDividends), `IsBuy`

**Rules**:
- `TaxCode NOT IN ('999', '998')` OR `TaxCode IS NULL` = real dividend, counted in DividendsFromReal or DividendsFromCFD
- `TaxCode IN ('999', '998')` = index adjustment event (e.g., synthetic dividend from index rebalancing), counted in IndexAdjustments
- `IsBuy=1` = long position - dividends counted; `IsBuy=0` = short position - dividends excluded (shorts owe dividends)

### 2.7 Compensation Exclusions - More Granular than v1

**What**: v2 excludes more CompensationReasonIDs from Compensation, routing them to dedicated columns.

**Columns/Parameters Involved**: `Compensation`, `StocksLending`, `StakingIncome`, `AirDropIncome`, `SpinOffIncome`, `CompensationReasonID`

**Rules**:
- Compensation excludes: `CompensationReasonID IN (57, 58, 91, 111, 112, 119)`
- `CompensationReasonID=57` - withholding tax (handled separately, not in this SP)
- `CompensationReasonID=58` - airdrop income -> `AirDropIncome`
- `CompensationReasonID=91` - staking rewards -> `StakingIncome`
- `CompensationReasonID=111` + `112` - specific fee types -> `Fees`
- `CompensationReasonID=119` - stocks lending income -> `StocksLending`
- `CompensationReasonID=75` - spin-off events -> `SpinOffIncome`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters all source records (History.CreditWithFee, History.BackOfficeCustomer). |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of reporting period (inclusive: `Occurred >= @StartDate`). Typically first day of a tax year. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of reporting period (exclusive: `Occurred < @EndDate`). Typically first day of the following year. |

**Result Set - Single-Row Comprehensive Tax Summary:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CFDPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed CFD positions (CreditTypeID=4, ActionType!=19, IsSettled=0/NULL) PLUS positive overnight/weekend fee credits. Includes TRS P&L. Returned as ISNULL(...,0). |
| 5 | CFDWithoutTRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0) PLUS positive overnight/weekend credits. Excludes TRS positions (SettlementTypeID=2). CFDPnL = CFDWithoutTRSPnL + TRSPnL (approximately). |
| 6 | TRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from Total Return Swap positions (CreditTypeID=4, ActionType!=19, SettlementTypeID=2). TRS = synthetic equity exposure via swap contract, treated as separate tax category. |
| 7 | CryptoPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real crypto positions (CreditTypeID=4, ActionType!=19, IsSettled=1, InstrumentTypeID=10, IsTransferredOut IS NULL). Excludes positions transferred out of eToro. |
| 8 | RealStocksPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5, IsTransferredOut IS NULL). Taxable equity capital gains, transfers excluded. |
| 9 | RealETFPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6). No IsTransferredOut filter for ETFs. |
| 10 | SdrtCharge | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from SDRT (Stamp Duty Reserve Tax) charges (CreditTypeID=14, Description='SDRT Charge'). UK-specific tax on real stock purchases. |
| 11 | DividendsFromReal | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from dividends on real stock/ETF long positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=1, IsBuy=1, TaxCode NOT IN ('999','998')). Actual cash dividends from share ownership. |
| 12 | DividendsFromCFD | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from dividend adjustments on CFD long positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=0/NULL, IsBuy=1 or NULL, TaxCode NOT IN ('999','998')). CFD dividend-equivalent credits. |
| 13 | Compensation | MONEY | NO | 0 | VERIFIED | Sum of Payment from generic compensation credits (CreditTypeID=6, CompensationReasonID NOT IN (57,58,91,111,112,119)). Trading error refunds, goodwill payments. |
| 14 | StocksLending | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from stocks lending income (CreditTypeID=6, CompensationReasonID=119). Income earned by lending real stock positions to other market participants. |
| 15 | CFDFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL) multiplied by -1. Returns positive cost value. |
| 16 | CFDWithoutTRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0) multiplied by -1. Excludes TRS commissions. |
| 17 | TRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from TRS positions (SettlementTypeID=2) multiplied by -1. |
| 18 | CryptoFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Crypto commission cost (CreditTypeID=4, IsSettled=1, InstrumentTypeID=10) using DLT markup logic when available (CloseMarkup+OpenMarkupByUnits or +CommissionByUnits/2) or standard CommissionOnClose, multiplied by -1. |
| 19 | RealStocksFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5) multiplied by -1. |
| 20 | RealETFFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6) multiplied by -1. |
| 21 | Fees | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from fee events: CreditTypeID IN (15,14) excluding dividends, SDRT, and positive overnight/weekend fees; PLUS CreditTypeID=6 with CompensationReasonID IN (111,112). |
| 22 | StakingIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from staking rewards (CreditTypeID=6, CompensationReasonID=91). Income earned by staking crypto assets on the platform. |
| 23 | AirDropIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from airdrop credits (CreditTypeID=6, CompensationReasonID=58). Tokens distributed to existing holders as a promotional or network event. |
| 24 | SpinOffIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from corporate spin-off events (CreditTypeID=6, CompensationReasonID=75). Value received when a company spins off a subsidiary distributed to shareholders. |
| 25 | IndexAdjustments | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from index-dividend events with TaxCode IN ('999','998') (CreditTypeID=14, Description='Payment caused by dividend'). Synthetic dividend adjustments from index rebalancing, taxed differently from cash dividends. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.CreditWithFee | Implicit | Primary source: all credit/fee events for the customer in the date range |
| CreditTypeID | Dictionary.CreditType | Lookup (JOIN) | Joined in RawData CTE for event type name; CreditTypeID used in all CASE logic |
| @CID / PositionID | Trade.GetPositionDataForExternalUse | Lookup (LEFT JOIN) | Retrieves position data (IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, IsBuy, ActionType, IsTransferredOut pending) |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | Provides InstrumentTypeID for asset-class classification (5=stocks, 6=ETF, 10=crypto) |
| PositionID | DB_Logs.History.ManualPositionClose_Crisis | Lookup (LEFT JOIN) | Detects positions closed via manual transfer operation (ManualOperationReasonID='6') |
| OperationID | DB_Logs.History.ManualOperationPositionClose_Crisis | Lookup (JOIN) | Joined to filter transfer-close operations |
| CreditID | Trade.PositionsProcessedForIndexDividnds | Lookup (LEFT JOIN) | Links credit events to index dividend processing records |
| DividendID | Trade.IndexDividends | Lookup (LEFT JOIN) | Provides TaxCode, DLTOpen, DLTClose, CloseMarkup, OpenMarkupByUnits, CommissionByUnits |
| @CID | History.BackOfficeCustomer | Lookup | Used for date-range overlap logic in UserRegulation CTE (though jurisdiction not returned in output) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Internal | EXEC-like usage | The `_withDBLogs` variant wraps or references v2 logic |
| BackOffice application layer | External | Direct call | Primary caller for customer tax report generation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatement_GetTaxReport_v2 (procedure)
|- History.CreditWithFee (table/view) [primary source - CTE HistoryCreditRecords]
|- Dictionary.CreditType (table) [JOIN in RawData for event classification]
|- Trade.GetPositionDataForExternalUse (view) [LEFT JOIN for position attributes]
|- Trade.InstrumentMetaData (table/view) [LEFT JOIN for InstrumentTypeID]
|- DB_Logs.History.ManualPositionClose_Crisis (table) [LEFT JOIN for IsTransferredOut]
|- DB_Logs.History.ManualOperationPositionClose_Crisis (table) [JOIN to filter transfer closes]
|- Trade.PositionsProcessedForIndexDividnds (table) [LEFT JOIN for DividendID link]
|- Trade.IndexDividends (table) [LEFT JOIN for TaxCode and DLT markup fields]
+-- History.BackOfficeCustomer (table) [CTE UserRegulation - regulation history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditWithFee | Table/View | Primary source: fee-inclusive cash events for @CID in the date range |
| Dictionary.CreditType | Table | JOIN to get event type name; CreditTypeID drives all CASE classification |
| Trade.GetPositionDataForExternalUse | View | LEFT JOIN for position data: IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, InstrumentID, ActionType, IsBuy, RedeemID |
| Trade.InstrumentMetaData | Table/View | LEFT JOIN on InstrumentID for InstrumentTypeID (5=stocks, 6=ETF, 10=crypto) |
| DB_Logs.History.ManualPositionClose_Crisis | Table | LEFT JOIN to detect positions physically transferred out of eToro (ManualOperationReasonID=6) |
| DB_Logs.History.ManualOperationPositionClose_Crisis | Table | Joined to ManualPositionClose_Crisis to confirm the operation type |
| Trade.PositionsProcessedForIndexDividnds | Table | LEFT JOIN via CreditID to link credit events to dividend processing records |
| Trade.IndexDividends | Table | LEFT JOIN via DividendID for TaxCode, DLTOpen, DLTClose, CloseMarkup, OpenMarkupByUnits, CommissionByUnits |
| History.BackOfficeCustomer | Table | UserRegulation CTE: customer's regulations during the period (used structurally, not output) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Procedure | Variant that extends v2 with DB logging capability |
| BackOffice application layer | External | Primary caller for tax report generation (current production version) |

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
| ActionType filter | Application | `ActionType != 19` excludes Redeem-type position closes from P&L columns |
| IsTransferredOut | Application | Positions from ManualOperationReasonID=6 within the date range are excluded from Crypto and RealStocks P&L |

---

## 8. Sample Queries

### 8.1 Get full tax summary for a customer for tax year 2023

```sql
EXEC BackOffice.AccountStatement_GetTaxReport_v2
    @CID = 12345,
    @StartDate = '2023-01-01',
    @EndDate = '2024-01-01'
-- Returns single row with 22 aggregated tax categories
```

### 8.2 Verify TRS vs CFD split for a customer

```sql
-- CFDPnL should approximately equal CFDWithoutTRSPnL + TRSPnL
-- Run procedure then compare columns in application layer
EXEC BackOffice.AccountStatement_GetTaxReport_v2
    @CID = 99999,
    @StartDate = '2024-01-01',
    @EndDate = '2025-01-01'
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

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [AccountStatement_GetTaxReport_v2](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11654137040/AccountStatement_GetTaxReport_v2) | Confluence | Page exists with a draw.io architecture diagram of the SP logic; diagram content not textually extractable. Confirms this SP has formal documentation in the CR (Compliance/Regulation) space. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 15 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountStatement_GetTaxReport_v2 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatement_GetTaxReport_v2.sql*
