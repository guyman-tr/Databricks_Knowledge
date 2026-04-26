# BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers

> 1.22M-row daily custody and transfer report for **real futures positions hedged through Marex** (HedgeServerID=150). 75 columns tracking position-level margin, settlement price, mark-to-market, Marex P&L, eToro P&L, and cash transfers for SP500, NatGas, Gold, Oil, DOW30 futures (25 distinct instruments). Covers 96 CIDs and ~192 positions/day. Dec 2024--Apr 2026, ~4-6K rows/day. Written by `SP_Finance_Real_Futures_Custody_And_Transfers` with a date-2 to date loop (holiday coverage), DELETE+INSERT per ReportDateID. Dummy NULL rows inserted for weekends.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Finance_Real_Futures_Custody_And_Transfers (Guy Manova, 2025-02-13) |
| **Refresh** | Daily (SB_Daily, Priority 0, ProcessType 1) — loop @date-2 to @date |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | _Not_Migrated |
| **UC Partitioned By** | _Not_Migrated |
| **UC Table Type** | _Not_Migrated |

---

## 1. Business Meaning

This table is a **daily position-level custody and transfer ledger** for real futures positions hedged through the Marex broker. Each row represents a single position-change event (open, hold, partial close, SL edit) for one original position on one report date, capturing the full financial lifecycle: settlement prices, margin requirements, mark-to-market, Marex-side P&L, eToro-side P&L, and the resulting cash transfers between eToro and Marex.

It answers: "For each real futures position on each day, what are the margin obligations, the P&L from settlement price movements, and how much cash must be transferred to/from Marex?"

**Row grain**: One position-change event per OriginalPositionID per ReportDateID (multiple events possible per position per day: Open, Hold, EditSL, PartialClose).

**ETL pattern**: The SP loops from @date-2 to @date for holiday coverage. For each date it DELETE+INSERTs all rows for that ReportDateID. Weekend dates receive dummy NULL rows to maintain date continuity.

**Sentinel values**:
- Weekend/holiday rows: most columns NULL except ReportDateID
- IsStartOfDay / IsEndOfDay: 1 for first/last event of the day per position; all margin and balance calculations keyed to IsEndOfDay=1
- IsSQF: 1 when a Synthetic Quarterly Futures adjustment is applied (0.3% of rows)

---

## 2. Business Logic

### 2.1 Position Event Processing (PARENTS/CHILDS CTEs)

**What**: Raw position change events are split into parent and child streams before assembly.

**Columns**: PositionID, OriginalPositionID, ActionType, ChangeTypeID, all amount/rate columns

**Rules**:
- PARENTS CTE: ChangeTypeID <> 11 (excludes parent-side of splits)
- CHILDS CTE: ChangeTypeID <> 12 (excludes child-side of splits)
- The two CTEs are combined to build the complete event timeline per OriginalPositionID
- ChangeTypeID values: 1=open, 6=close, 11=parent split, 12=child split

### 2.2 SQF (Synthetic Quarterly Futures) Adjustment

**What**: Settlement prices and forex rates are adjusted for SQF rollovers using external Google Sheets data.

**Columns**: InitForexRate, EndForexRate, SettlementPrice, SettlementPricePrev, SettlementPriceChange, Adj, PreviousAdj, AdjChange, IsSQF

**Rules**:
- Adjustment values sourced from `External_Fivetran_google_sheets_adj` (Fivetran-synced Google Sheet)
- `InitForexRate = raw_InitForexRate + ISNULL(adj.Adj, 0)` — adjusted open rate
- `SettlementPrice = raw_SettlementPrice + ISNULL(adj.Adj, 0)` — adjusted settlement
- `IsSQF = CASE WHEN ISNULL(Adj, 0) <> 0 THEN 1 ELSE 0 END`
- UnAdjusted columns (65-69) preserve original values before SQF adjustment
- Only 0.3% of rows have IsSQF=1

### 2.3 Settlement Price and Mark-to-Market

**What**: Daily settlement prices drive MTM and P&L calculations.

**Columns**: SettlementPrice, SettlementPricePrev, SettlementPriceChange, MTM, MTMRunning

**Rules**:
- Settlement prices from `Fact_Settlement_Prices`, joined by InstrumentID and date
- Previous settlement uses OUTER APPLY + COALESCE for missing previous data (holiday gaps)
- `MTM = (SettlementPrice - SettlementPricePrev) * TodayBeginLotCountRunning * Multiplier`
- MTM only meaningful on held positions (ActionType='Hold')

### 2.4 Marex P&L and Transfer Calculation

**What**: Computes Marex broker-side P&L and the resulting cash transfer obligations.

**Columns**: TodayMarexPnL, TodayMarexPnLPlusMTM, ProviderMargin, ProviderMarginChange, TransferToMarex, TransferToMarexRunning

**Rules**:
- `TodayMarexPnL = (SettlementPrice - InitForexRate/EndForexRate) * ActionLotCount * Multiplier`
- `TodayMarexPnLPlusMTM = TodayMarexPnL + MTM` — combined Marex P&L
- `ProviderMargin = ABS(TodayLotCountFinal * ProviderMarginPerLot)` — only on IsEndOfDay=1 rows
- `TransferToMarex = ProviderMarginChange - TodayMarexPnLPlusMTM` — daily cash transfer obligation
- Running totals accumulated via windowed SUM

### 2.5 eToro P&L and User Transfers

**What**: Computes eToro-side P&L and cash flows to/from the customer.

**Columns**: eToroPnL, InvestedAmountChange, InvestedAmountRunning, ToUser, ToUserRunning, PositionValueAtSettlement, eToroBalance

**Rules**:
- `eToroPnL = IsBuy_direction * (EndRate/SettlementPrice - InitForexRate) * lots * Multiplier`
- `InvestedAmountChange = IsBuy * ActionLotCount * eToroMarginPerLot + AmountChanged`
- `PositionValueAtSettlement = InvestedAmountRunning + TodayLotCountFinal * Multiplier * (SettlementPrice - InitForexRate)` — only on IsEndOfDay=1
- `eToroBalance = PositionValueAtSettlement - ProviderMargin` — net eToro custody balance

### 2.6 Lot Count and Running Position

**What**: Tracks lot-level position size through the day.

**Columns**: ActionLotCount, RunningLotCount, TodayBeginLotCountRunning, TodayLotCountFinal, LotCountDecimal, PreviousLotCountDecimal

**Rules**:
- `ActionLotCount = CASE on IsBuy * ActionType * LotCount delta` — signed lot change per event
- `RunningLotCount = SUM(ActionLotCount) OVER (PARTITION BY OriginalPositionID ORDER BY ...)` — cumulative
- `TodayBeginLotCountRunning = LAG(RunningLotCount)` — start-of-day position
- `TodayLotCountFinal` populated only on IsEndOfDay=1 rows

### 2.7 Trader Assignment

**What**: Assigns the Marex tag50 trader ID to each position.

**Columns**: Trader

**Rules**:
- Sourced from `External_Gold_Dealing_Marex_Trader_OrderID` joined by PositionID
- Deduplicated and corrected for reopened positions (2025-03-16 fix)
- 2025-05-29 fix: corrected wrong join to ETO marex identification table that caused duplication

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `CID` with a CLUSTERED COLUMNSTORE INDEX. Always include `CID` or `ReportDateID` in WHERE clauses for optimal segment elimination. With 1.22M rows, the table is moderate-sized but grows ~4-6K rows/day.

### 3.1b UC (Databricks) Storage & Partitioning

_Not_Migrated._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily Marex transfer summary | `WHERE ReportDateID = @dt AND IsEndOfDay = 1` -- SUM `TransferToMarex` |
| EOD custody balance per CID | `WHERE ReportDateID = @dt AND IsEndOfDay = 1` -- SUM `eToroBalance` |
| Position P&L timeline | `WHERE OriginalPositionID = @pid ORDER BY ReportDateID, SnapshotDateID` |
| SQF-adjusted positions | `WHERE IsSQF = 1` -- examine Adj, AdjChange columns |
| Regulation breakdown | `WHERE ReportDateID = @dt GROUP BY Regulation` -- 97% CySEC, 3% FCA |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Instrument` | `ON t.InstrumentID = di.InstrumentID` | Instrument details beyond InstrumentName |
| `DWH_dbo.Dim_Position` | `ON t.OriginalPositionID = dp.PositionID` | Full position metadata |
| `DWH_dbo.Dim_Customer` | `ON t.CID = dc.CID` | Customer demographics |
| `BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data` | `ON t.OriginalPositionID = p.OriginalPositionID AND t.SnapshotDateID = p.DateID` | Source event details |

### 3.4 Gotchas

- **Weekend/holiday dummy rows** -- most columns are NULL on these rows. Always filter `WHERE ActionType IS NOT NULL` for meaningful data, or use `IsEndOfDay = 1` for EOD snapshots.
- **IsEndOfDay = 1 for balances** -- ProviderMargin, PositionValueAtSettlement, eToroBalance, TodayLotCountFinal are only populated on IsEndOfDay=1 rows. Other rows will be NULL for these.
- **Multiple events per position per day** -- a single position can have Open + Hold + EditSL events on the same ReportDateID. Running totals accumulate across these events.
- **HedgeServerID = 150 always** -- this table is exclusively Marex-hedged positions. No filtering needed but be aware when joining with multi-broker tables.
- **ActionType distribution** -- Hold (84%), EditSLIncreaseAmount (10%), Open (4%), EditSLReduceAmount (2%), PartialCloseOrig (<0.2%). Most rows are daily hold/carry events.
- **SQF adjustments are rare** -- only 0.3% of rows. The UnAdjusted columns (65-69) preserve pre-SQF values for audit.
- **HASH(CID) distribution** -- 96 CIDs means limited distribution spread. For large aggregations, filter by ReportDateID first.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| 4 stars | Tier 1 | `(Tier 1 — ...)` | Direct from upstream dimension/fact (Dim_Position, Trade.PositionTbl) |
| 3 stars | Tier 2 | `(Tier 2 — ...)` | Derived in SP code with verified logic |
| 2 stars | Tier 3 | `(Tier 3 — ...)` | Description from live data observation only |
| 1 star | Tier 5 | `(Tier 5 — ...)` | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportDateID | int | YES | Report run date in YYYYMMDD format. DELETE/INSERT partition key. The SP loops @date-2 to @date for holiday coverage. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, @dateID) |
| 2 | SnapshotDateID | int | YES | Historical snapshot date for this event in YYYYMMDD format. From BI_DB_Futures_Finance_Prep_Data.DateID. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.DateID) |
| 3 | PositionID | bigint | YES | Child position ID from the CHILDS CTE. NULL if parent-only event. From BI_DB_Futures_Finance_Prep_Data.PositionID. (Tier 1 — BI_DB_Futures_Finance_Prep_Data.PositionID) |
| 4 | OriginalPositionID | bigint | YES | Parent/original position ID. Primary position identifier for running totals and partitioning. (Tier 1 — BI_DB_Futures_Finance_Prep_Data.OriginalPositionID) |
| 5 | CID | int | YES | Customer ID. Distribution key. 96 distinct CIDs on a typical day. (Tier 1 — BI_DB_Futures_Finance_Prep_Data.CID) |
| 6 | InstrumentID | int | YES | Futures instrument identifier. 25 distinct instruments (SP500, NatGas, Gold, Oil, DOW30 etc.). (Tier 1 — BI_DB_Futures_Finance_Prep_Data.InstrumentID) |
| 7 | ActionType | varchar(100) | YES | Position change action. Values: Hold (84%), EditSLIncreaseAmount (10%), Open (4%), EditSLReduceAmount (2%), PartialCloseOrig (<0.2%), CloseOrig, ChildClose. NULL on weekend dummy rows. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.ActionType) |
| 8 | SettlementTime | datetime | YES | Settlement timestamp for the current event. Passthrough from Prep_Data. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.SettlementTime) |
| 9 | SettlementTimePrev | datetime | YES | Previous settlement timestamp. Passthrough from Prep_Data. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.SettlementTimePrev) |
| 10 | Occurred | datetime | YES | Position change event timestamp. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.Occurred) |
| 11 | OccurredDateID | int | YES | YYYYMMDD integer of the Occurred timestamp. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.OccurredDateID) |
| 12 | ChangeTypeID | int | YES | Position change type code. 1=open, 6=close, 11=parent split, 12=child split. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.ChangeTypeID) |
| 13 | PreviousAmount | decimal(18,6) | YES | USD amount before the change event. Part of the amount delta chain. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.PreviousAmount) |
| 14 | AmountChanged | decimal(18,6) | YES | USD amount delta for this change event. Positive for increases, negative for decreases. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.AmountChanged) |
| 15 | NewAmount | decimal(18,6) | YES | USD amount after the change event. PreviousAmount + AmountChanged. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.NewAmount) |
| 16 | PreviousStopRate | decimal(18,6) | YES | Stop loss rate before the change. Relevant for EditSL action types. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.PreviousStopRate) |
| 17 | StopRate | decimal(18,6) | YES | Stop loss rate after the change. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.StopRate) |
| 18 | PreviousAmountInUnits | decimal(18,6) | YES | Previous amount in instrument units. LAG-filled via correlated subquery + UPDATE for gap-filling. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed from LastKnownAmountInUnits) |
| 19 | AmountInUnits | decimal(18,6) | YES | Current amount in instrument units. LAG-filled via correlated subquery + UPDATE for gap-filling. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed from LastKnownAmountInUnits) |
| 20 | LotCountDecimal | decimal(18,6) | YES | Current lot count with decimal precision. LAG-filled. NULLed for ChangeTypeID=1 (open events). (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed from LastKnownLotCount) |
| 21 | PreviousLotCountDecimal | decimal(18,6) | YES | Previous lot count with decimal precision. LAG-filled. NULLed for ChangeTypeID=1 (open events). (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed from LastKnownLotCount) |
| 22 | IsBuy | int | YES | Trade direction. 1=long, 0=short. From position upstream data. (Tier 1 — BI_DB_Futures_Finance_Prep_Data.IsBuy) |
| 23 | InitForexRate | decimal(18,6) | YES | SQF-adjusted open rate. Computed: raw InitForexRate + ISNULL(adj.Adj, 0). (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data + SQF adj) |
| 24 | EndForexRate | decimal(18,6) | YES | SQF-adjusted close rate. COALESCE(child.EndForexRate, parent.EndForexRate) + adj. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data + SQF adj) |
| 25 | IsStartOfDay | int | YES | 1 if this is the first event of the day for this OriginalPositionID. ROW_NUMBER partitioned by OriginalPositionID, DateID. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 26 | IsEndOfDay | int | YES | 1 if this is the last event of the day for this OriginalPositionID. Critical flag: margin and balance columns only populated on IsEndOfDay=1 rows. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 27 | Multiplier | decimal(18,6) | YES | Contract multiplier for the futures instrument. From Dim_Instrument_Snapshot (OUTER APPLY latest IsFuture=1 snapshot). (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument_Snapshot.Multiplier) |
| 28 | ProviderMarginPerLot | decimal(18,6) | YES | Marex margin requirement per lot for the current day. From Dim_Instrument_Snapshot. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument_Snapshot.ProviderMarginPerLot) |
| 29 | ProviderMarginPerLotPrev | decimal(18,6) | YES | Marex margin requirement per lot for the previous day. From Dim_Instrument_Snapshot. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument_Snapshot.ProviderMarginPerLot prev day) |
| 30 | eToroMarginPerLot | decimal(18,6) | YES | eToro margin requirement per lot for the current day. From Dim_Instrument_Snapshot. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument_Snapshot.eToroMarginPerLot) |
| 31 | eToroMarginPerLotPrev | decimal(18,6) | YES | eToro margin requirement per lot for the previous day. From Dim_Instrument_Snapshot. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument_Snapshot.eToroMarginPerLot prev day) |
| 32 | SettlementPrice | decimal(18,6) | YES | SQF-adjusted daily settlement price for the instrument. From Fact_Settlement_Prices + adj. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Fact_Settlement_Prices + SQF adj) |
| 33 | SettlementPricePrev | decimal(18,6) | YES | SQF-adjusted previous day settlement price. OUTER APPLY + COALESCE for holiday gaps. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Fact_Settlement_Prices + SQF adj) |
| 34 | SettlementPriceChange | decimal(18,6) | YES | Settlement price day-over-day delta. SettlementPrice - SettlementPricePrev. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 35 | ActionLotCount | decimal(18,6) | YES | Signed lot count change for this event. Positive for buys/increases, negative for sells/decreases. CASE on IsBuy x ActionType x LotCount delta. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 36 | RunningLotCount | decimal(18,6) | YES | Cumulative lot position for this OriginalPositionID. SUM(ActionLotCount) OVER partition by OriginalPositionID. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 37 | TodayBeginLotCountRunning | decimal(18,6) | YES | Lot count at start of day. LAG(RunningLotCount). Used as the base for MTM calculation. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 38 | TodayLotCountFinal | decimal(18,6) | YES | End-of-day lot count. Only populated on IsEndOfDay=1 rows. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 39 | ProviderMargin | decimal(18,6) | YES | EOD provider (Marex) margin. ABS(TodayLotCountFinal x ProviderMarginPerLot). Only on IsEndOfDay=1. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 40 | TodayMarexPnL | decimal(18,6) | YES | Marex P&L for this action event. (SettlementPrice - InitForexRate/EndForexRate) x ActionLotCount x Multiplier. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 41 | MTM | decimal(18,6) | YES | Mark-to-market on held positions. (SettlementPrice - SettlementPricePrev) x TodayBeginLotCountRunning x Multiplier. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 42 | PreviousProviderMargin | decimal(18,6) | YES | Previous day's provider margin. LAG of ProviderMargin across days with propagation. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 43 | TodayMarexPnLPlusMTM | decimal(18,6) | YES | Combined Marex P&L. TodayMarexPnL + MTM. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 44 | ProviderMarginChange | decimal(18,6) | YES | Day-over-day margin delta. ProviderMargin - PreviousProviderMargin. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 45 | TransferToMarex | decimal(18,6) | YES | Daily cash transfer obligation to Marex. ProviderMarginChange - TodayMarexPnLPlusMTM. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 46 | TransferToMarexRunning | decimal(18,6) | YES | Cumulative cash transferred to Marex. SUM(TransferToMarex) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 47 | InvestedAmountChange | decimal(18,6) | YES | eToro client invested amount change. IsBuy x ActionLotCount x eToroMarginPerLot + AmountChanged. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 48 | InvestedAmountRunning | decimal(18,6) | YES | Cumulative eToro client invested amount. SUM(InvestedAmountChange) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 49 | eToroPnL | decimal(18,6) | YES | eToro-side P&L. IsBuy direction x (EndRate/SettlementPrice - InitForexRate) x lots x Multiplier. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 50 | ToUser | decimal(18,6) | YES | Cash to/from user for this event. -InvestedAmountChange + close eToroPnL. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 51 | ToUserRunning | decimal(18,6) | YES | Cumulative cash to/from user. SUM(ToUser) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 52 | PositionValueAtSettlement | decimal(18,6) | YES | EOD position value. InvestedAmountRunning + TodayLotCountFinal x Multiplier x (SettlementPrice - InitForexRate). Only on IsEndOfDay=1. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 53 | eToroBalance | decimal(18,6) | YES | EOD eToro custody balance. PositionValueAtSettlement - ProviderMargin. Only on IsEndOfDay=1. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 54 | UpdateDate | datetime | NO | ETL load timestamp. GETDATE() at SP execution. Only NOT NULL column. (Tier 5 — SP_Finance_Real_Futures_Custody_And_Transfers, GETDATE()) |
| 55 | MTMRunning | decimal(18,6) | YES | Cumulative mark-to-market. SUM(MTM) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 56 | TodayMarexPnLRunning | decimal(18,6) | YES | Cumulative Marex P&L. SUM(TodayMarexPnL) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 57 | TodayMarexPnLPlusMTMRunning | decimal(18,6) | YES | Cumulative combined Marex P&L + MTM. SUM(TodayMarexPnLPlusMTM) OVER running window. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 58 | OpenPositionsMarexPnLPlusMTM | decimal(18,6) | YES | Open positions Marex P&L+MTM. TodayMarexPnLPlusMTMRunning filtered to IsEndOfDay=1 and not closed. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 59 | PreviousMarexPnLPlusMTMRunning | decimal(18,6) | YES | Previous EOD cumulative Marex P&L+MTM. LAG(TodayMarexPnLPlusMTMRunning) on EOD rows. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 60 | MarexPnLPlusMTMRunningChange | decimal(18,6) | YES | Day-over-day change in cumulative Marex P&L+MTM. TodayMarexPnLPlusMTMRunning - PreviousMarexPnLPlusMTMRunning. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 61 | Trader | varchar(100) | YES | Marex tag50 trader ID. From External_Gold_Dealing_Marex_Trader_OrderID, deduplicated and reopen-corrected. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, External_Gold_Dealing_Marex_Trader_OrderID.Trader) |
| 62 | InstrumentName | varchar(200) | YES | Futures instrument name. Passthrough from Dim_Instrument.Name. Values: SP500, NatGas, Gold, Oil, DOW30, etc. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Instrument.Name) |
| 63 | IsOpenEOD | int | YES | 1 if the position is still open at end of day. 0 if last action is CloseOrig. FIRST_VALUE(ActionType) partitioned by DateID, OriginalPositionID DESC. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 64 | HedgeServerID | int | YES | Hedge server identifier. Always 150 (Marex) for this table. From Dim_Position via OriginalPositionID JOIN. (Tier 1 — DWH_dbo.Dim_Position.HedgeServerID) |
| 65 | InitForexRateUnAdjusted | money | YES | Original unadjusted open rate before SQF adjustment. Preserves the raw value for audit. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.InitForexRate) |
| 66 | EndForexRateUnAdjusted | money | YES | Original unadjusted close rate. COALESCE(child, parent) EndForexRate before SQF adjustment. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Prep_Data.EndForexRate) |
| 67 | SettlementPriceUnAdjusted | money | YES | Original unadjusted settlement price from Fact_Settlement_Prices. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Fact_Settlement_Prices.SettlementPrice) |
| 68 | SettlementPriceUnAdjustedPrev | money | YES | Original unadjusted previous day settlement price. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Fact_Settlement_Prices.SettlementPrice prev day) |
| 69 | SettlementPriceUnAdjustedChange | money | YES | Unadjusted settlement price day-over-day delta. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 70 | Adj | money | YES | Current SQF adjustment value from External_Fivetran_google_sheets_adj. 0 or NULL for non-SQF rows. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, External_Fivetran_google_sheets_adj.adj) |
| 71 | PreviousAdj | money | YES | Previous day SQF adjustment value. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, External_Fivetran_google_sheets_adj.adj prev day) |
| 72 | AdjChange | money | YES | SQF adjustment day-over-day delta. Adj - PreviousAdj. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 73 | ClosePositionReason | varchar(100) | YES | Close reason name from Dim_ClosePositionReason via Dim_Position.ClosePositionReasonID. NULLed when EndForexRate IS NULL (position still open). (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_ClosePositionReason.Name) |
| 74 | IsSQF | int | YES | SQF adjustment flag. 1 if ISNULL(Adj, 0) <> 0, else 0. Only 0.3% of rows have IsSQF=1. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, computed) |
| 75 | Regulation | nvarchar(50) | YES | Regulation name at position open time. From Dim_Regulation via Dim_Position.RegulationIDOnOpen. Values: CySEC (97%), FCA (3%), BVI (<0.1%). Added 2025-10-29. (Tier 2 — SP_Finance_Real_Futures_Custody_And_Transfers, Dim_Regulation.Name) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ReportDateID | ETL param | @dateID | Report run date |
| SnapshotDateID | BI_DB_Futures_Finance_Prep_Data | DateID | Passthrough |
| PositionID, OriginalPositionID, CID, InstrumentID | BI_DB_Futures_Finance_Prep_Data | Same | PARENTS/CHILDS CTE split |
| ActionType | BI_DB_Futures_Finance_Prep_Data | ActionType | Passthrough |
| SettlementPrice, SettlementPricePrev | Fact_Settlement_Prices + SQF adj | SettlementPrice + adj | Adjusted; OUTER APPLY for gaps |
| InitForexRate, EndForexRate | Prep_Data + SQF adj | InitForexRate/EndForexRate + adj | SQF-adjusted rates |
| Multiplier, ProviderMarginPerLot, eToroMarginPerLot | Dim_Instrument_Snapshot | Same | OUTER APPLY IsFuture=1 |
| Trader | External_Gold_Dealing_Marex_Trader_OrderID | Trader | Deduplicated, reopen-corrected |
| InstrumentName | Dim_Instrument | Name | Passthrough |
| HedgeServerID | Dim_Position | HedgeServerID | Via OriginalPositionID |
| ClosePositionReason | Dim_ClosePositionReason | Name | Via Dim_Position.ClosePositionReasonID |
| Regulation | Dim_Regulation | Name | Via Dim_Position.RegulationIDOnOpen |
| Adj, PreviousAdj, AdjChange | External_Fivetran_google_sheets_adj | adj | SQF values + delta |
| IsSQF | Computed | — | CASE WHEN ISNULL(Adj,0) <> 0 |
| All running/cumulative cols | Computed | — | Windowed SUM/LAG over OriginalPositionID |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data (position change ledger)
  |-- PARENTS CTE (ChangeTypeID <> 11) + CHILDS CTE (ChangeTypeID <> 12) ---|
  + BI_DB_dbo.External_Fivetran_google_sheets_adj (SQF adjustments via Fivetran)
  + DWH_dbo.Dim_Instrument_Snapshot (IsFuture=1: margins, multiplier)
  + DWH_dbo.Fact_Settlement_Prices (daily settlement prices)
  + Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID (tag50 trader IDs)
  + DWH_dbo.Dim_Position (HedgeServerID, RegulationIDOnOpen, ClosePositionReasonID)
  + DWH_dbo.Dim_Instrument (InstrumentName)
  + DWH_dbo.Dim_ClosePositionReason + Dim_Regulation (lookups)
    |-- SP_Finance_Real_Futures_Custody_And_Transfers @date ---|
    |-- Loop: @date-2 to @date (holiday coverage) ---|
    |-- DELETE+INSERT per ReportDateID ---|
    v
  BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers (1.22M rows, ~4-6K/day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| OriginalPositionID | DWH_dbo.Dim_Position | Position dimension (HedgeServerID, regulation, close reason) |
| OriginalPositionID | BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data | Source position change ledger |
| InstrumentID | DWH_dbo.Dim_Instrument_Snapshot | Futures instrument margins and multiplier |
| InstrumentID + Date | DWH_dbo.Fact_Settlement_Prices | Daily settlement prices |
| PositionID | Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID | Marex trader tag50 |
| InstrumentID + Date | BI_DB_dbo.External_Fivetran_google_sheets_adj | SQF adjustment values |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No known downstream consumers identified in SP code. Table is likely consumed by Tableau/reporting directly. |

---

## 7. Sample Queries

### 7.1 Daily Marex transfer summary by instrument

```sql
SELECT  ReportDateID,
        InstrumentName,
        SUM(TransferToMarex)    AS DailyTransfer,
        SUM(ProviderMargin)     AS EOD_Margin,
        SUM(eToroBalance)       AS EOD_eToroBalance
FROM    BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers
WHERE   ReportDateID = 20260424
  AND   IsEndOfDay = 1
GROUP BY ReportDateID, InstrumentName
ORDER BY DailyTransfer DESC;
```

### 7.2 Position P&L timeline for a specific position

```sql
SELECT  ReportDateID,
        ActionType,
        ActionLotCount,
        RunningLotCount,
        TodayMarexPnL,
        MTM,
        TodayMarexPnLPlusMTM,
        TransferToMarex,
        eToroBalance
FROM    BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers
WHERE   OriginalPositionID = 123456789
ORDER BY ReportDateID, SnapshotDateID;
```

### 7.3 Regulation breakdown for a date range

```sql
SELECT  Regulation,
        COUNT(DISTINCT CID)                     AS Customers,
        COUNT(DISTINCT OriginalPositionID)      AS Positions,
        SUM(CASE WHEN IsEndOfDay = 1
                 THEN ProviderMargin END)        AS TotalMargin
FROM    BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers
WHERE   ReportDateID BETWEEN 20260401 AND 20260424
  AND   ActionType IS NOT NULL
GROUP BY Regulation
ORDER BY TotalMargin DESC;
```

---

## 8. Atlassian Knowledge Sources

No sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 5 T1, 68 T2, 0 T3, 0 T4, 1 T5 (UpdateDate) | Elements: 75/75*
*Object: BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers | Type: Table | Production Source: SP_Finance_Real_Futures_Custody_And_Transfers*
