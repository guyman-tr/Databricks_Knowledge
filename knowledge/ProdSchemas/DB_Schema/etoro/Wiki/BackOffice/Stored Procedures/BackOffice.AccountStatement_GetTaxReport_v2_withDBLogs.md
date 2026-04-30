# BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs

> Generates a 19-column single-row tax summary using GetPositionData with PositionSlim-validated transfer detection and TRS support, an intermediate variant between v1 and the full v2 production version.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a transitional variant in the tax report SP family, sitting between v1 (2019-2021 original) and v2 (full production). It produces a single-row tax summary covering CFD P&L (with/without TRS), real stocks, ETF, crypto, dividends, SDRT, fees, staking, airdrops, and spin-off income. It was the version that first introduced TRS (Total Return Swap) as a distinct tax category, added via COFKV-2781 in January 2022 by Sergey Gladchenko.

The "_withDBLogs" suffix reflects that this version queries both `DB_Logs.History` tables (for transfer detection, like v2) AND joins to `etoro.History.PositionSlim` to validate PartitionCol alignment - a stricter transfer detection approach compared to the pure v2. It also uses `Trade.GetPositionData` (the internal view) rather than `GetPositionDataForExternalUse`, and does not apply the DLT markup logic introduced in v2 for crypto commissions.

Key differences from v2: (1) CommissionOnClose columns are not negated - returned as raw database values (costs are negative numbers). (2) No DLT markup for crypto commissions. (3) No StocksLending or IndexAdjustments columns. (4) Simpler dividend logic (no TaxCode filter). (5) Less granular Compensation exclusion list (only excludes 57, 58, 91). (6) IsTransferredOut uses `!= 1` comparison (not `IS NULL`) meaning explicit BIT=0 rows still pass the filter.

Data flows identically to v2: reads `History.CreditWithFee` as primary source, enriches via position data and instrument metadata, applies IsTransferredOut detection through DB_Logs + PositionSlim, and aggregates into SUM/CASE columns by tax category.

---

## 2. Business Logic

### 2.1 Asset Class Classification via IsSettled + InstrumentTypeID + SettlementTypeID

**What**: Distinguishes five taxable asset classes using the same logic as v2.

**Columns/Parameters Involved**: `IsSettled`, `InstrumentTypeID`, `SettlementTypeID`, `ActionType`

**Rules**:
- `ActionType=19` = Redeem - excluded from all P&L columns
- `IsSettled=0` or NULL = CFD position -> CFDPnL
- `COALESCE(SettlementTypeID, IsSettled, 0) = 0` = pure CFD (no TRS) -> CFDWithoutTRSPnL
- `SettlementTypeID=2` = TRS -> TRSPnL
- `IsSettled=1` AND `InstrumentTypeID=10` = Crypto -> CryptoPnL
- `IsSettled=1` AND `InstrumentTypeID=5` = Real Stocks -> RealStocksPnL
- `IsSettled=1` AND `InstrumentTypeID=6` = Real ETF -> RealETFPnL

### 2.2 Transfer Detection via PositionSlim Partition Validation

**What**: Positions physically transferred out of eToro are excluded from P&L. This version adds a stricter PartitionCol alignment check via History.PositionSlim.

**Columns/Parameters Involved**: `IsTransferredOut` (derived BIT), `CryptoPnL`, `RealStocksPnL`

**Rules**:
- Source: `DB_Logs.History.ManualPositionClose_Crisis` (ManualOperationReasonID='6') INNER JOINed to `DB_Logs.History.ManualOperationPositionClose_Crisis`
- Additional INNER JOIN to `etoro.History.PositionSlim ON pos.PositionID = c.PositionID AND pos.PartitionCol = c.PartitionCol` - validates the position is in the correct partition
- Also filters `AND CID = @CID` in the subquery (not done in v2) for narrower scan
- `IsTransferredOut != 1` comparison: rows where IsTransferredOut is NULL (not a transfer) or BIT=0 pass; only explicit BIT=1 is excluded
- Differs from v2's `IS NULL` check - v2 treats any non-NULL as a transfer

### 2.3 TRS as Distinct Category (COFKV-2781, Jan 2022)

**What**: TRS (Total Return Swap) P&L and commissions reported as separate tax category. Introduced in this version before being carried forward to v2.

**Columns/Parameters Involved**: `TRSPnL`, `TRSFullCommissionOnClose`, `CFDWithoutTRSPnL`, `CFDWithoutTRSFullCommissionOnClose`

**Rules**:
- `SettlementTypeID=2` = TRS position
- TRS included in CFDPnL (same IsSettled=0/NULL check) but broken out separately
- CFDWithoutTRSPnL = pure CFD excluding TRS: `COALESCE(SettlementTypeID, IsSettled, 0) = 0`
- Commission columns NOT negated (raw values; costs appear as negative numbers in output)

### 2.4 Simpler Dividend and Fee Logic vs v2

**What**: Dividend and Fee aggregation is less granular than v2 - no TaxCode filtering and no overnight/weekend fee credits in CFDPnL.

**Rules**:
- DividendsFromReal/CFD: filtered by `IsBuy=1` but NO TaxCode filter (no IndexAdjustments split)
- Fees: `CreditTypeID IN (15,14)` AND Description NOT IN dividend/SDRT strings - no overnight/weekend exclusion, no CompensationReasonID 111/112 inclusion
- Compensation: excludes only (57, 58, 91) vs v2's (57, 58, 91, 111, 112, 119)
- No StocksLending column (CompensationReasonID=119 falls into Compensation in this version)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters History.CreditWithFee, History.BackOfficeCustomer, and the ManualPositionClose_Crisis subquery. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of reporting period (inclusive: `Occurred >= @StartDate`). Typically first day of a tax year. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of reporting period (exclusive: `Occurred < @EndDate`). Typically first day of the following year. |

**Result Set - Single-Row Tax Summary (19 columns):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CFDPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed CFD positions (CreditTypeID=4, ActionType!=19, IsSettled=0/NULL). Includes TRS P&L. Does NOT include positive overnight/weekend fee credits (unlike v2). |
| 5 | CFDWithoutTRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0, ActionType!=19). Excludes TRS (SettlementTypeID=2). |
| 6 | TRSPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from Total Return Swap positions (CreditTypeID=4, ActionType!=19, SettlementTypeID=2). Introduced via COFKV-2781 Jan 2022. |
| 7 | CryptoPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real crypto positions (CreditTypeID=4, ActionType!=19, IsSettled=1, InstrumentTypeID=10, IsTransferredOut!=1). |
| 8 | RealStocksPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5, IsTransferredOut!=1). |
| 9 | RealETFPnL | MONEY | NO | 0 | VERIFIED | Sum of NetProfit from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6). No IsTransferredOut filter. |
| 10 | SdrtCharge | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from SDRT charges (CreditTypeID=14, Description='SDRT Charge'). UK stamp duty reserve tax on real stock purchases. |
| 11 | DividendsFromReal | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from dividends on real long positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=1, IsBuy=1). No TaxCode filter (simpler than v2). |
| 12 | DividendsFromCFD | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from dividend adjustments on CFD long positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=0/NULL, IsBuy=1 or NULL). No TaxCode filter. |
| 13 | Compensation | MONEY | NO | 0 | VERIFIED | Sum of Payment from compensation credits (CreditTypeID=6, CompensationReasonID NOT IN (57,58,91)). Note: includes CompensationReasonID=119 (StocksLending) which v2 separates out. |
| 14 | CFDFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL). NOT negated - costs appear as negative values. |
| 15 | CFDWithoutTRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from pure CFD positions (COALESCE(SettlementTypeID,IsSettled,0)=0). NOT negated. |
| 16 | TRSFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from TRS positions (SettlementTypeID=2). NOT negated. |
| 17 | CryptoFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed crypto positions (CreditTypeID=4, InstrumentTypeID=10, IsSettled=1). No DLT markup logic (simpler than v2). NOT negated. |
| 18 | RealStocksFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real stock positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=5). NOT negated. |
| 19 | RealETFFullCommissionOnClose | MONEY | NO | 0 | VERIFIED | Sum of CommissionOnClose from closed real ETF positions (CreditTypeID=4, IsSettled=1, InstrumentTypeID=6). NOT negated. |
| 20 | Fees | MONEY | NO | 0 | VERIFIED | Sum of TotalCashChange from fee events (CreditTypeID IN (15,14)) excluding dividend and SDRT descriptions. Simpler than v2 - no overnight/weekend exclusion, no CompensationReasonID 111/112 inclusion. |
| 21 | StakingIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from staking rewards (CreditTypeID=6, CompensationReasonID=91). |
| 22 | AirDropIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from airdrop credits (CreditTypeID=6, CompensationReasonID=58). |
| 23 | SpinOffIncome | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from corporate spin-off events (CreditTypeID=6, CompensationReasonID=75). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.CreditWithFee | Implicit | Primary source of all cash events for the customer |
| CreditTypeID | Dictionary.CreditType | Lookup (JOIN) | Event type name; CreditTypeID drives all CASE classification |
| @CID / PositionID | Trade.GetPositionData | Lookup (LEFT JOIN) | Position attributes: IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, IsBuy, ActionType |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | InstrumentTypeID for asset-class classification |
| PositionID | DB_Logs.History.ManualPositionClose_Crisis | Lookup (LEFT JOIN) | Transfer-close detection (ManualOperationReasonID=6) |
| OperationID | DB_Logs.History.ManualOperationPositionClose_Crisis | Lookup (INNER JOIN) | Validates operation type for transfer detection |
| PositionID / PartitionCol | etoro.History.PositionSlim | Lookup (INNER JOIN) | Partition-validated position record for transfer detection |
| @CID | History.BackOfficeCustomer | Lookup | Customer regulation history (UserRegulation CTE) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in SSDT. Called directly from BackOffice application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs (procedure)
|- History.CreditWithFee (table/view) [CTE HistoryCreditRecords - primary source]
|- Dictionary.CreditType (table) [JOIN in RawData for event classification]
|- Trade.GetPositionData (view) [LEFT JOIN for position data and attributes]
|- Trade.InstrumentMetaData (table/view) [LEFT JOIN for InstrumentTypeID]
|- DB_Logs.History.ManualPositionClose_Crisis (table) [transfer-close detection]
|- DB_Logs.History.ManualOperationPositionClose_Crisis (table) [validates operation type]
|- etoro.History.PositionSlim (table) [PartitionCol validation for transfer detection]
+-- History.BackOfficeCustomer (table) [UserRegulation CTE - regulation history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditWithFee | Table/View | Primary source: cash events for @CID in date range |
| Dictionary.CreditType | Table | JOIN in RawData CTE for event type classification |
| Trade.GetPositionData | View | LEFT JOIN for IsSettled, SettlementTypeID, NetProfit, CommissionOnClose, InstrumentID, ActionType, IsBuy |
| Trade.InstrumentMetaData | Table/View | LEFT JOIN for InstrumentTypeID (5=stocks, 6=ETF, 10=crypto) |
| DB_Logs.History.ManualPositionClose_Crisis | Table | Transfer-close detection via ManualOperationReasonID=6 |
| DB_Logs.History.ManualOperationPositionClose_Crisis | Table | INNER JOIN to validate operation type in transfer detection |
| etoro.History.PositionSlim | Table | INNER JOIN to validate PartitionCol alignment for transfer detection |
| History.BackOfficeCustomer | Table | Customer regulation history (used in UserRegulation CTE) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called as intermediate tax report version; likely for testing TRS handling or partition-validated transfer detection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range | Application | Inclusive-start, exclusive-end: `Occurred >= @StartDate AND Occurred < @EndDate` |
| Commission sign | Design | CommissionOnClose values NOT negated - costs are returned as negative MONEY values (callers must negate) |
| IsTransferredOut | Application | Uses `!= 1` not `IS NULL` - explicit BIT=0 rows pass through (vs v2 IS NULL check) |
| PartitionCol join | Design | Transfer detection requires PositionSlim partition alignment - stricter than v2 which skips this check |

---

## 8. Sample Queries

### 8.1 Get tax summary including TRS split for a customer

```sql
EXEC BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs
    @CID = 12345,
    @StartDate = '2023-01-01',
    @EndDate = '2024-01-01'
-- Note: CommissionOnClose columns are negative (not negated like v2)
```

### 8.2 Compare with v2 output for same customer

```sql
-- Run both to compare TRS handling and transfer detection differences
EXEC BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs @CID=12345, @StartDate='2023-01-01', @EndDate='2024-01-01'
EXEC BackOffice.AccountStatement_GetTaxReport_v2 @CID=12345, @StartDate='2023-01-01', @EndDate='2024-01-01'
-- Key differences: commission sign, DLT crypto markup, overnight fee credits in CFDPnL
```

### 8.3 Check ManualOperationReasonID=6 (transfer-out) records for a customer

```sql
SELECT c.PositionID, c.InsertDate, o.ManualOperationReasonID
FROM DB_Logs.History.ManualPositionClose_Crisis c WITH (NOLOCK)
INNER JOIN DB_Logs.History.ManualOperationPositionClose_Crisis o WITH (NOLOCK)
    ON c.OperationID = o.OperationID
WHERE o.ManualOperationReasonID = '6'
-- ManualOperationReasonID=6 = position physically transferred out of eToro
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs.sql*
