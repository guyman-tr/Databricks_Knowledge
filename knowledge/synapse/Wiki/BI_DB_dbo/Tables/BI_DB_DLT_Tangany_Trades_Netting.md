# BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting

> 17.7M-row daily crypto trade reconciliation table for DLT/Tangany custody netting, tracking every settled crypto open and close action from October 2024 to present (~872K distinct CIDs, 510 dates). Populated by `SP_BI_DB_DLT_Tangany_Trades_Netting` via DELETE-INSERT per DateID, sourcing trade events from `Fact_CustomerAction` (InstrumentTypeID=10 only), with 3 amount bug-fix scenarios correcting eToro's recording errors in position amounts based on Leverage and UnitMargin conditions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH aggregation via `SP_BI_DB_DLT_Tangany_Trades_Netting` — reads `Fact_CustomerAction`, `Dim_Position`, `Dim_Instrument`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Dim_ClosePositionReason`, `BI_DB_Client_Balance_CID_Level_New`, `External_eToro_Dictionary_TanganyStatus`, `Function_Revenue_TicketFeeByPercent` |
| **Refresh** | SB_Daily, daily DELETE-INSERT by DateID |
| **Synapse Distribution** | HASH([PositionID]) |
| **Synapse Index** | CLUSTERED INDEX([PositionID] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Guy Manova (2024-11-10) |

---

## 1. Business Meaning

This table is a daily reconciliation dataset for DLT (Distributed Ledger Technology) and Tangany crypto custody operations. Each row represents one settled crypto trade action (open or close) for one position on one day, with corrected amounts that fix known bugs in eToro's recording of position amounts.

**Purpose**: Finance teams use this data to reconcile crypto trades between eToro's internal records and the Tangany custody provider. The `AmountBugFix` column provides corrected amounts that account for recording discrepancies in the original `InvestedAmount`, eliminating false reconciliation differences.

**Population**: Only crypto instruments (InstrumentTypeID=10) and only settled trades (IsSettled=1). Opens use ActionTypeID IN (1,2,3,39) — Open, OpenCopy, OpenSmartPortfolio, OpenCopyFund. Closes use ActionTypeID IN (4,5,6,28,40) — Close, CloseCopy, CloseSmartPortfolio, CloseManualUnregister, CloseCopyFund.

**Key semantics**:
- Amounts are **sign-flipped** (`-1 * Amount`) for netting purposes — both opens and closes are negative
- `IsDLTUser` is based on `Fact_SnapshotCustomer.DltStatusID = 4`, but the table includes ALL crypto trades, not just DLT users (96.6% are non-DLT)
- `TanganyStatusID` is only populated for users with status IN (2,3,5) — Tangany-eligible or MiCA customers
- Three separate bug-fix calculations exist for `AmountBugFix` based on Leverage (1 or 2) and whether UnitMargin equals InitForexRate

---

## 2. Business Logic

### 2.1 Amount Bug Fix Scenarios

**What**: RnD has a bug in recording eToro amounts for some positions. This SP corrects the amounts using position-level data from Dim_Position.
**Columns Involved**: AmountBugFix, InvestedAmount, Leverage, UnitMargin, InitForexRate
**Rules**:
- **Bug Fix 1** (Leverage=1): `AmountBugFix = InitForexRate * InitialUnits` (open) or `-1 * (InitForexRate * AmountInUnitsDecimal + NetProfit)` (close)
- **Bug Fix 2** (Leverage=2, UnitMargin = InitForexRate): `AmountBugFix = 2 * InitialAmountCents/100` (open) or `-1 * (2 * Amount + NetProfit)` (close)
- **Bug Fix 3** (Leverage=2, UnitMargin != InitForexRate): `AmountBugFix = 2 * InitForexRate * InitialUnits` (open) or `-1 * (2 * InitForexRate * AmountInUnitsDecimal + NetProfit)` (close)
- The final INSERT UNION ALLs all 6 bug-fix temp tables (3 open + 3 close)

### 2.2 DLT/Tangany Status Classification

**What**: Identifies DLT-enabled users and their Tangany custody status.
**Columns Involved**: IsDLTUser, TanganyStatusID, TanganyID, DltID
**Rules**:
- `IsDLTUser = 1` when `Fact_SnapshotCustomer.DltStatusID = 4` (DLT-enabled)
- `TanganyStatusID` resolved via `BI_DB_Client_Balance_CID_Level_New.TanganyStatus` → JOIN to `External_eToro_Dictionary_TanganyStatus` on Status Desc; only kept for status IN (2,3,5) — others are NULL
- `TanganyID` from `Dim_Customer` — the Tangany integration UUID
- `DltID` from `Fact_SnapshotCustomer` (opens) or `Dim_Customer` (closes)

### 2.3 Coin Transfer Detection

**What**: Identifies positions closed by transferring coins out of eToro to external wallets.
**Columns Involved**: IsCoinsTransferedOut, CloseReason
**Rules**:
- `IsCoinsTransferedOut = 1` when `ClosePositionReasonID = 22` (Transferred Out)
- Only 968 such events in 2026 data (0.02% of closes)
- CloseReason from Dim_ClosePositionReason.Name — 15 distinct values, dominated by Customer (39.8%), Hierarchical Close (28.5%), Manual Unregister (15.3%)

### 2.4 Ticket Fee by Percentage

**What**: Percentage-based commission fee per position, added 2025-05-28.
**Columns Involved**: TicketFeeByPercent, CommissionVersion
**Rules**:
- From `Function_Revenue_TicketFeeByPercent(@dateID, @dateID, 0)` — a TVF that calculates percentage-based fees
- Matched by PositionID + action type (Open/Close)
- ISNULL to 0 when no fee applies
- `CommissionVersion` from Dim_Position indicates which fee algorithm version

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distributed on HASH(PositionID) with CLUSTERED INDEX on PositionID ASC. Position-level queries are efficient. For CID-level or date-level aggregations, use DateID filters.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily netting summary | `SELECT DateID, ActionType, SUM(AmountBugFix) FROM ... WHERE DateID = YYYYMMDD GROUP BY DateID, ActionType` |
| DLT-only trades | `WHERE IsDLTUser = 1` — only 3.4% of rows |
| Tangany-eligible reconciliation | `WHERE TanganyStatusID IS NOT NULL` |
| Coin transfer-out tracking | `WHERE IsCoinsTransferedOut = 1` |
| Amount discrepancy detection | `SELECT PositionID, InvestedAmount, AmountBugFix, InvestedAmount - AmountBugFix AS diff WHERE ABS(InvestedAmount - AmountBugFix) > 0.01` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Full customer profile, regulation, country name |
| DWH_dbo.Dim_Country | CountryID = CountryID | Country name resolution |
| DWH_dbo.Dim_Position | PositionID = PositionID | Full position details |
| DWH_dbo.Dim_Instrument | Instrument = Name | Instrument details (note: join on Name, not InstrumentID) |

### 3.4 Gotchas

- **All amounts are negative**: Both opens and closes have sign-flipped amounts (`-1 * Amount`). This is for netting — SUM gives net flow
- **Not DLT-only**: Despite the name, 96.6% of rows are for non-DLT users. The table covers ALL crypto trades, with DLT/Tangany flags for filtering
- **TanganyStatusID sparse**: Only populated for status IN (2,3,5) — NULL for most users
- **DltID source differs**: Opens get DltID from Fact_SnapshotCustomer, closes get it from Dim_Customer — potential for slight differences in timing
- **CloseReason = 'NA' for opens**: Open actions have hardcoded 'NA' as CloseReason, not NULL
- **AmountBugFix vs InvestedAmount**: Always use `AmountBugFix` for reconciliation — `InvestedAmount` contains the original buggy amounts
- **CommissionVersion**: Added via final JOIN to Dim_Position — may be NULL if position not found

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki documentation |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / propagation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Snapshot date as YYYYMMDD integer. DELETE-INSERT partition key. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. Set from SP @date parameter. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 3 | RealCID | int | YES | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | CountryID | int | YES | Customer's country at the trade date, from Fact_SnapshotCustomer date-range matched via Dim_Range. FK to Dim_Country. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 5 | IsDLTUser | int | YES | 1 if customer has DltStatusID=4 in Fact_SnapshotCustomer at the trade date, 0 otherwise. Only 3.4% of rows are DLT users. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 6 | TanganyStatusID | int | YES | Tangany custody status ID from External_eToro_Dictionary_TanganyStatus, resolved via BI_DB_Client_Balance_CID_Level_New.TanganyStatus. Only populated for status IN (2,3,5) — NULL for most users. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 7 | ActionType | varchar(20) | YES | Trade action type: 'Open' for ActionTypeID IN (1,2,3,39) or 'Close' for IN (4,5,6,28,40). Hardcoded string, not from a lookup table. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 8 | InvestedAmount | decimal(18,6) | YES | Original position amount sign-flipped for netting (-1 * Fact_CustomerAction.Amount). Contains the BUGGY recording — use AmountBugFix for reconciliation. DWH note: sign-flipped from source. (Tier 1 — Trade.PositionTbl, via Fact_CustomerAction.Amount) |
| 9 | Units | decimal(18,6) | YES | Position size in units/shares, sign-flipped. Open: -1 * InitialUnits from Fact_CustomerAction. Close: -1 * AmountInUnitsDecimal from Dim_Position. DWH note: sign-flipped; close uses AmountInUnitsDecimal (bug fix from 2024-11-14, previously used InitialUnits). (Tier 1 — Trade.PositionTbl) |
| 10 | TanganyID | varchar(100) | YES | Tangany crypto custody integration UUID from Dim_Customer. NULL for non-Tangany users. (Tier 2 — SP_Dim_Customer, via Dim_Customer.TanganyID) |
| 11 | DltID | varchar(100) | YES | Distributed Ledger Technology integration UUID. Opens: from Fact_SnapshotCustomer.DltID. Closes: from Dim_Customer.DltID. NULL for non-DLT users. (Tier 2 — SP_Dim_Customer, via Dim_Customer/Fact_SnapshotCustomer) |
| 12 | IsCoinsTransferedOut | int | YES | 1 if position was closed by transferring coins to an external wallet (ClosePositionReasonID=22). 0 otherwise. Always 0 for open actions. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 13 | Instrument | varchar(100) | YES | Crypto instrument name from Dim_Instrument.Name (e.g., 'SOL/USD', 'BTC/USD', 'ADA/USD'). Only crypto instruments (InstrumentTypeID=10). (Tier 3 — live data, etoro.Trade.GetInstrument, via Dim_Instrument.Name) |
| 14 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Distribution key. (Tier 1 — Trade.PositionTbl) |
| 15 | AmountBugFix | decimal(18,6) | YES | Corrected position amount fixing RnD recording bugs. 3 formulas based on Leverage and UnitMargin: (1) Lev=1: InitForexRate*Units, (2) Lev=2 + UnitMargin=InitForex: 2*InitialAmountCents/100, (3) Lev=2 + UnitMargin!=InitForex: 2*InitForexRate*Units. Use this column instead of InvestedAmount for reconciliation. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting) |
| 16 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the SP (GETDATE()). (Tier 5 — ETL metadata) |
| 17 | CloseReason | varchar(100) | YES | Close reason name from Dim_ClosePositionReason.Name. 15 distinct values: Customer, Hierarchical Close, Manual Unregister, Alignment, Copy Stop Loss, Stop Loss, Take Profit, Redeem, etc. Hardcoded 'NA' for open actions. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting, via Dim_ClosePositionReason) |
| 18 | TicketFeeByPercent | money | YES | Percentage-based ticket fee per position from Function_Revenue_TicketFeeByPercent. Matched by PositionID + action type. ISNULL to 0 when no fee applies. Added 2025-05-28. (Tier 2 — SP_BI_DB_DLT_Tangany_Trades_Netting, via Function_Revenue_TicketFeeByPercent) |
| 19 | CommissionVersion | int | YES | Version of the commission calculation algorithm used for this position, from Dim_Position.CommissionVersion. Added in final JOIN. (Tier 2 — SP_Dim_Position_DL_To_Synapse, via Dim_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| RealCID | Fact_CustomerAction | RealCID | Direct |
| PositionID | Fact_CustomerAction | PositionID | Direct |
| InvestedAmount | Fact_CustomerAction | Amount | -1 * Amount (sign-flip) |
| Units | Fact_CustomerAction / Dim_Position | InitialUnits / AmountInUnitsDecimal | -1 * (open: InitialUnits, close: AmountInUnitsDecimal) |
| CountryID | Fact_SnapshotCustomer | CountryID | Direct (date-range matched) |
| IsDLTUser | Fact_SnapshotCustomer | DltStatusID | CASE: 4 → 1, else 0 |
| TanganyID | Dim_Customer | TanganyID | Direct |
| Instrument | Dim_Instrument | Name | Direct (InstrumentTypeID=10 filter) |
| AmountBugFix | Dim_Position | Multiple | 3 bug-fix formulas |
| CloseReason | Dim_ClosePositionReason | Name | Direct |
| CommissionVersion | Dim_Position | CommissionVersion | Direct |
| TicketFeeByPercent | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | ISNULL to 0 |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (crypto trades, IsSettled=1)
DWH_dbo.Dim_Instrument (InstrumentTypeID=10 filter)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer snapshot)
DWH_dbo.Dim_Customer (TanganyID, DltID)
DWH_dbo.Dim_Position (bug fix calc + CommissionVersion)
DWH_dbo.Dim_ClosePositionReason (close reason name)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (Tangany status)
BI_DB_dbo.External_eToro_Dictionary_TanganyStatus (status ID lookup)
BI_DB_dbo.Function_Revenue_TicketFeeByPercent (% fee calc)
  |
  |-- SP_BI_DB_DLT_Tangany_Trades_Netting @date --|
  |   #openedPrep + #closedPrep (base trades)     |
  |   #ftf (ticket fees)                           |
  |   #opened + #closed (with fees)                |
  |   #openedBugFix1-3 + #closedBugFix1-3          |
  |   #final (UNION ALL 6 bug-fix tables)          |
  |   DELETE WHERE DateID = @dateID                |
  |   INSERT (final JOIN Dim_Position)             |
  v
BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting (17.7M rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country lookup |
| PositionID | DWH_dbo.Dim_Position.PositionID | Position details |
| Instrument | DWH_dbo.Dim_Instrument.Name | Instrument name (crypto only) |

### 6.2 Referenced By (other objects point to this)

| Consumer | Description |
|---|---|
| SP_CMR_ClientBalance_Report_DLT_Trades_Netting | Downstream reader for CMR client balance DLT reporting |

---

## 7. Sample Queries

### 7.1 Daily Netting Summary

```sql
SELECT DateID, ActionType,
    COUNT(*) AS trades,
    SUM(AmountBugFix) AS net_amount,
    SUM(Units) AS net_units
FROM [BI_DB_dbo].[BI_DB_DLT_Tangany_Trades_Netting]
WHERE DateID = 20260412
GROUP BY DateID, ActionType
```

### 7.2 DLT Users with Tangany Status

```sql
SELECT RealCID, TanganyStatusID, TanganyID, DltID,
    COUNT(*) AS trades,
    SUM(AmountBugFix) AS total_amount
FROM [BI_DB_dbo].[BI_DB_DLT_Tangany_Trades_Netting]
WHERE DateID = 20260412
  AND IsDLTUser = 1
  AND TanganyStatusID IS NOT NULL
GROUP BY RealCID, TanganyStatusID, TanganyID, DltID
```

### 7.3 Amount Bug Fix Discrepancies

```sql
SELECT PositionID, InvestedAmount, AmountBugFix,
    ABS(InvestedAmount - AmountBugFix) AS discrepancy,
    Instrument, ActionType
FROM [BI_DB_dbo].[BI_DB_DLT_Tangany_Trades_Netting]
WHERE DateID = 20260412
  AND ABS(InvestedAmount - AmountBugFix) > 1.00
ORDER BY discrepancy DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 3 T1, 13 T2, 1 T3, 0 T4, 1 T5 | Elements: 19/19, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting | Type: Table | Production Source: SP_BI_DB_DLT_Tangany_Trades_Netting (DWH aggregation)*
