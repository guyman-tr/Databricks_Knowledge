# DWH_dbo.Dim_Position

> The central trading-position dimension in the Synapse DWH, storing every open and historically-closed position as an end-of-day snapshot; each row is one trade held by a customer on a financial instrument.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `Trade.PositionTbl` + `Trade.PositionTreeInfo` (via `Trade.Position` → `Trade.PositionForExternalUse` → `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay`) |
| **Refresh** | Daily (midnight ETL — end-of-day snapshot) |
| | |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | CLUSTERED INDEX (PositionID) |
| | |
| **UC Target** | `main.dwh.dim_position` |
| **UC Format** | Delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | MANAGED |

---

## 1. Business Meaning

`DWH_dbo.Dim_Position` is the Synapse data-warehouse representation of every trading position ever opened on the eToro platform. Each row is one position — a customer's trade on a financial instrument (stock, crypto, forex, ETF, commodity, or index) with a specific invested amount, leverage, and settlement type. The table answers "what positions exist, what is their current state, and how did they close?" It covers both positions that are still open (`CloseDateID = 0`) and positions that have been closed (archived from production). This is the primary table analysts use for portfolio analysis, P&L reporting, commission calculations, copy-trade analysis, and regulatory compliance.

The data originates from `Trade.PositionTbl` (live open positions) and `History.Position_Active` (archived closed positions) in the production database. These flow through the `Trade.OpenPositionEndOfDay` and `History.ClosePositionEndOfDay` views, are exported to the Azure Data Lake via the Generic Pipeline, land in `DWH_staging.etoro_Trade_OpenPositionEndOfDay` and `DWH_staging.etoro_History_ClosePositionEndOfDay`, and are loaded into this table by `SP_Dim_Position_DL_To_Synapse`. Additional enrichment comes from `Trade.PositionTreeInfo` (stop/limit rates, tree structure), `Trade.PositionAirdropLog` (airdrop flags), `PriceLog_History_CurrencyPrice_Active` (forex price snapshots), and `etoro_History_BackOfficeCustomer` (regulation at open). See upstream wiki: `Trade/Tables/Trade.PositionTbl.md`, `Trade/Tables/Trade.PositionTreeInfo.md`.

The table is refreshed daily at midnight by `SP_Dim_Position_DL_To_Synapse`, which performs a delete-and-insert for newly opened/closed positions and updates existing open positions with current-day values. Post-load helper SPs compute `InitHedgeType`/`EndHedgeType`, `IsPartialCloseParent`, `IsCopyFundPosition`, `IsAirDrop`, and reopen adjustments. The table represents the **end-of-day state** — not real-time.

---

## 2. Business Logic

### 2.1 Position Lifecycle

**What**: Every position goes through a lifecycle from open to close.

**Columns Involved**: `CloseDateID`, `OpenOccurred`, `CloseOccurred`, `ClosePositionReasonID`

**Rules**:
- `CloseDateID = 0` means the position is **still open**
- `CloseDateID > 0` (format YYYYMMDD) means the position was closed on that date
- `ClosePositionReasonID` indicates why: 0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close (copy-trade cascade), 17=Manual Unregister, etc.
- In production, positions transition Open → Being Closed → Archived. In this DWH table, closed positions are retained (not deleted) and visible with `CloseDateID > 0`

### 2.2 Settlement Type: Real Ownership vs Synthetic Contract

**What**: Determines whether the customer owns the actual asset or holds a synthetic contract (CFD).

**Columns Involved**: `SettlementTypeID`, `IsSettled`, `IsSettledOnOpen`

**Rules**:
- `SettlementTypeID` is the authoritative field: 0=CFD, 1=REAL (owns shares), 2=TRS (Total Return Swap — crypto), 3=CMT (Crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE
- NULL in `SettlementTypeID` → legacy rows; use fallback: `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`
- `IsSettled`: legacy indicator — 1=Real, 0=CFD. Predates `SettlementTypeID`
- `IsSettledOnOpen`: captures settlement status at the time of position open. May differ from current `IsSettled` if converted after open
- Standard segmentation pattern: `ISNULL(dp.IsSettledOnOpen, dp.IsSettled)` for the "at open" settlement type

### 2.3 Copy Trading Tree Hierarchy

**What**: Positions opened via the CopyTrader feature form a tree structure.

**Columns Involved**: `MirrorID`, `TreeID`, `ParentPositionID`, `OrigParentPositionID`, `IsCopyFundPosition`

**Rules**:
- `MirrorID = 0` → manually opened position (no copy relationship)
- `MirrorID > 0` → position was automatically opened because the customer is copying a leader; references `Trade.Mirror.MirrorID`
- `TreeID` = root leader's PositionID. For independent positions: `TreeID = PositionID`. For copy positions: `TreeID = root leader's PositionID`
- `ParentPositionID` = direct parent in the copy tree
- `OrigParentPositionID` = original parent, preserved even after tree restructuring
- `IsCopyFundPosition = 1` → position belongs to a CopyFund (AccountTypeID=9) tree

**Diagram**:
```
Leader Position (TreeID = PositionID, MirrorID = 0)
├── Copier A Position (TreeID = Leader.PositionID, MirrorID > 0, ParentPositionID = Leader.PositionID)
├── Copier B Position (TreeID = Leader.PositionID, MirrorID > 0, ParentPositionID = Leader.PositionID)
└── ...
```

### 2.4 Partial Close

**What**: A partial close allows an investor to realize only a portion of a position.

**Columns Involved**: `IsPartialCloseChild`, `IsPartialCloseParent`, `OriginalPositionID`, `InitialAmountCents`, `Amount`

**Rules**:
- Partial close creates a **new position (child)** with `IsPartialCloseChild = 1`. The child opens and closes in the same second
- The original position is marked `IsPartialCloseParent = 1`; its `Amount` is reduced proportionally
- `OriginalPositionID` on the child links back to the parent
- `InitialAmountCents` (÷ 100 = USD) is preserved from the original open and never changes
- **When counting open positions, always filter `ISNULL(IsPartialCloseChild, 0) = 0`** to avoid double-counting

### 2.5 Hedge Type

**What**: Classification of the hedging execution model used for each position.

**Columns Involved**: `InitHedgeType`, `EndHedgeType`

**Rules**:
- `'CBH'` (Compute Before Hedge) = standard model; client trade is computed/placed first, then hedged afterward
- `'HBC'` (Hedge Before Compute) = hedge is placed before the client order is computed/executed
- Determined by checking if the execution ID exists in `Ext_Dim_Position_HBCExecutionLog`
- `InitHedgeType` is the model at open; `EndHedgeType` is the model at close

### 2.6 DLT (German Crypto Broker)

**What**: Indicates whether a position was executed on the DLT platform — a German crypto broker used for trade execution. Not generic Distributed Ledger Technology.

**Columns Involved**: `DLTOpen`, `DLTClose`

**Rules**:
- `DLTOpen = 1` → position was opened on the DLT broker platform
- `DLTClose = 1` → position was closed on the DLT broker platform
- Computed in the source view `Trade.PositionForExternalUse`: `CASE WHEN (HedgeServerID=86 OR dlt.PositionID IS NOT NULL) AND Occurred BETWEEN '2024-09-24' AND '2025-10-30' AND OpenMarkup IS NOT NULL THEN 1 ELSE 0 END`
- NULL or 0 = not executed on DLT broker

### 2.7 Reopen

**What**: Positions that were closed and then reopened (e.g., after corporate actions).

**Columns Involved**: `IsReOpen`, `ReopenForPositionID`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsPartialCloseChildFromReOpen`

**Rules**:
- `IsReOpen = 1` → this position was created by reopening a previously closed position
- `ReopenForPositionID` references the original closed position
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve the original commission values before reopen adjustments
- `IsPartialCloseChildFromReOpen = 1` → partial close child of a reopened position

### 2.8 Crypto Redemption

**What**: Lifecycle for redeeming an eToro crypto position to actual crypto in the customer's eToro crypto wallet.

**Columns Involved**: `RedeemStatus`, `RedeemID`

**Rules**:
- `RedeemStatus` tracks the status of the full redemption transaction loop (position → crypto arriving in wallet): 0=N/A (not in redeem process), 1=PositionPending, 6=PositionClosed (closed by redeem), 20=Terminated (closed by other reason while pending), 21=FailedToCancel
- `RedeemID` references the redemption transaction record

### 2.9 Airdrop Positions

**What**: Positions opened by eToro on behalf of the customer. Not limited to crypto.

**Columns Involved**: `IsAirDrop`

**Rules**:
- `IsAirDrop = 1` → position was created by eToro on behalf of the customer. Examples: crypto staking rewards, promotions, compensations
- Set by looking up the position in `Trade.PositionAirdropLog`
- NULL = not an airdrop (majority of positions)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `PositionID` with a CLUSTERED INDEX on `PositionID`. Always include `PositionID` in JOINs or WHERE clauses for optimal single-distribution queries. Queries filtering only on `CID`, `InstrumentID`, or date columns will scan all 60 distributions. Nonclustered indexes exist on `CID`, `CloseDateID`, `InstrumentID`, `OpenDateID+CloseDateID`, and `CloseOccurred+OpenOccurred` to accelerate common Synapse filter patterns.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as **Delta** (MANAGED), partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). Always include partition columns in WHERE clauses for partition pruning — e.g., `WHERE etr_y = 2025 AND etr_ym = 202503` will skip scanning irrelevant partitions. The partition columns `etr_y`, `etr_ym`, `etr_ymd` are Databricks-layer additions not present in the Synapse source.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All open positions for a customer | `WHERE CloseDateID = 0 AND CID = @cid AND ISNULL(IsPartialCloseChild, 0) = 0` |
| Positions opened on a specific date | `WHERE OpenDateID = @dateId AND ISNULL(IsPartialCloseChild, 0) = 0` |
| Positions closed in a date range | `WHERE CloseDateID BETWEEN @startDateId AND @endDateId` |
| Copy-trade positions for a leader | `WHERE TreeID = @leaderPositionId AND MirrorID > 0` |
| Real vs CFD segmentation | `CASE WHEN ISNULL(IsSettledOnOpen, IsSettled) = 1 THEN 'Real' ELSE 'CFD' END` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Instrument` | `ON dp.InstrumentID = di.InstrumentID` | Instrument name, type, symbol, sector |
| `DWH_dbo.Dim_Customer` | `ON dp.CID = dc.RealCID` | Customer demographics, country, regulation |
| `DWH_dbo.Dim_ClosePositionReason` | `ON dp.ClosePositionReasonID = dcpr.ClosePositionReasonID` | Close reason name |
| `DWH_dbo.Dim_Regulation` | `ON dp.RegulationIDOnOpen = dr.ID` | Regulation name at position open |
| `BI_DB_dbo.BI_DB_PositionPnL` | `ON dp.PositionID = ppnl.PositionID` | Daily P&L, limit/stop rates |
| `DWH_dbo.Dim_Mirror` | `ON dp.MirrorID = dm.MirrorID` | Copy-trade relationship details |
| `DWH_dbo.Dim_Date` | `ON dp.OpenDateID = dd.DateID` | Calendar attributes for open date |

### 3.4 Gotchas

- **CloseDateID = 0 means OPEN, not NULL.** Zero is the sentinel for open positions. Closed positions have `CloseDateID` in YYYYMMDD format (e.g., 20250202)
- **Always filter out partial-close children** when counting positions: `ISNULL(IsPartialCloseChild, 0) = 0`
- **InitialAmountCents is in cents**, divide by 100 for USD: `InitialAmountCents / 100 AS InitialAmount`
- **CurrencyID is always 1 (USD)** in this table — all amounts are USD-denominated
- **PlatformTypeID and PositionSegment are always NULL** — these columns are not populated
- **Many columns use NULL for "not applicable"** rather than 0 (e.g., SettlementTypeID, IsAirDrop, DLTOpen)
- **IsSettled vs IsSettledOnOpen**: `IsSettled` can change after open (e.g., conversion); `IsSettledOnOpen` preserves the at-open value. Use `ISNULL(IsSettledOnOpen, IsSettled)` for the at-open settlement
- **TreeID = PositionID** means root/independent position. **TreeID ≠ PositionID** means copy-trade child

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Unique position identifier. System-generated. Also serves as the root `TreeID` for independent (non-copy-trade) positions. HASH distribution key for this table. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries. (Tier 1 — Trade.PositionTbl) |
| 3 | CurrencyID | int | NO | Account currency in which Amount, NetProfit, commissions, and fees are denominated. References `Dim_Currency`. In practice, always 1 (USD) in this table. (Tier 1 — Trade.PositionTbl) |
| 4 | ProviderID | int | NO | Legacy field, always hardcoded to 1 by `Trade.PositionOpen`. Originally identified the trading provider. Always 1 in production. (Tier 1 — Trade.PositionTbl) |
| 5 | InstrumentID | int | NO | The financial instrument being traded (stock, forex pair, crypto, ETF, commodity, index, etc.). References `Dim_Instrument.InstrumentID`. Drives settlement rules, fee schedules, hedge routing, P&L conversion, and corporate-action processing. (Tier 1 — Trade.PositionTbl) |
| 6 | HedgeID | int | YES | Reference to a specific hedge record in `Trade.Hedge`. Links position to the corresponding hedge order placed with the liquidity provider. NULL if no direct hedge record. (Tier 1 — Trade.PositionTbl) |
| 7 | HedgeServerID | int | YES | The hedge server currently responsible for routing and executing hedges for this position. References `Trade.HedgeServer.HedgeServerID`. (Tier 1 — Trade.PositionTbl) |
| 8 | Leverage | int | NO | Leverage multiplier applied to this position (e.g., 1 = no leverage / real ownership, 5 = 5× leverage). Combined with IsSettled and instrument type to determine SettlementTypeID. Leverage=1 + isSettled → REAL settlement type. (Tier 1 — Trade.PositionTbl) |
| 9 | Amount | money | NO | Customer's invested amount in account currency (USD). Gross notional = Amount × Leverage. Updated proportionally on partial close to reflect remaining open amount. (Tier 1 — Trade.PositionTbl) |
| 10 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in units of the underlying instrument (e.g., number of shares for stocks, units for forex/crypto). Updated proportionally on partial close. Used in P&L calculation and hedge exposure aggregation. (Tier 1 — Trade.PositionTbl) |
| 11 | LotCountDecimal | decimal(16,6) | YES | Position size in standard lots. Updated on partial close. Used in overnight fee calculations and hedge lot-count aggregation. (Tier 1 — Trade.PositionTbl) |
| 12 | UnitMargin | decimal(15,8) | YES | Margin requirement per unit of the instrument at open time, in account currency. Used for margin calculations, risk checks, and regulatory reporting. (Tier 1 — Trade.PositionTbl) |
| 13 | InitForexRate | decimal(16,8) | NO | Instrument's exchange rate at position open. Foundational input to P&L formula: `(CloseRate - InitForexRate) × AmountInUnitsDecimal × ConversionRate`. (Tier 1 — Trade.PositionTbl) |
| 14 | NetProfit | money | NO | Closed profit/loss in account currency. Zero while position is open. Set at close: `ROUND(@NetProfit / 100, 2)`. Populated only when the position is closed. (Tier 1 — Trade.PositionTbl) |
| 15 | SpreadedPipBid | decimal(16,8) | YES | Bid-side spread rate applied at open (instrument bid price after spread mark-up). Used in P&L formula and hedge exposure calculations. (Tier 1 — Trade.PositionTbl) |
| 16 | SpreadedPipAsk | decimal(16,8) | YES | Ask-side spread rate applied at open (instrument ask price after spread mark-up). Used alongside SpreadedPipBid in P&L and hedge calculations. (Tier 1 — Trade.PositionTbl) |
| 17 | IsBuy | bit | NO | Trade direction: 1 = Buy (long — profits if instrument rises), 0 = Sell (short — profits if instrument falls). (Tier 1 — Trade.PositionTbl) |
| 18 | CloseOnEndOfWeek | bit | NO | Close position at weekend flag. Inherited from `Trade.PositionTreeInfo.CloseOnEndOfWeek`. Always 0 on initial INSERT (deprecated feature). (Tier 1 — Trade.PositionTreeInfo) |
| 19 | EndOfWeekFee | money | NO | Cumulative end-of-week holding fee charged to date in account currency. Updated weekly by EOW fee processes. Reduced proportionally on partial close. Default=0 at open. (Tier 1 — Trade.PositionTbl) |
| 20 | Commission | money | NO | eToro's additional spread (markup) on top of the market spread at position open, in account currency. This is what eToro charges above the market bid/ask spread — manifests as the difference between AskSpreaded/BidSpreaded and Ask/Bid. Synonym: markup. (Tier 5 — domain expert) |
| 21 | CommissionOnClose | money | NO | eToro's additional spread (markup) at position close. Same concept as Commission but at close time. May be adjusted by `SP_Dim_Position_ReOpen` for reopened positions. (Tier 5 — domain expert) |
| 22 | OpenOccurred | datetime | NO | UTC timestamp when the position was opened. DWH note: maps to `Occurred` in production `Trade.PositionTbl`. (Tier 1 — Trade.PositionTbl, renamed) |
| 23 | CloseOccurred | datetime | NO | UTC timestamp when the close was written to the database. Set to `'1900-01-01'` for open positions. (Tier 1 — Trade.PositionTbl) |
| 24 | ParentPositionID | bigint | YES | For copy-trade positions: the PositionID of the direct parent (leader's) position. Sentinel value = 1 (meaning "no parent / independent position"). (Tier 1 — Trade.PositionTbl) |
| 25 | OrigParentPositionID | bigint | YES | The original parent PositionID at the time of copy. Preserved even after tree restructuring (splits, detach operations). Sentinel = 1. (Tier 1 — Trade.PositionTbl) |
| 26 | MirrorID | int | YES | Copy-trade relationship identifier. 0 = manually opened position. > 0 = position was automatically opened because the customer is copying a leader; references `Trade.Mirror.MirrorID`. (Tier 1 — Trade.PositionTbl) |
| 27 | IsOpenOpen | bit | YES | Indicates the OPEN_OPEN mechanism: 1 = this position was created by reinvesting unrealised profit (OpenActionType=3, ADD_FUNDS). (Tier 1 — Trade.PositionTbl) |
| 28 | OpenDateID | int | NO | Position open date as integer YYYYMMDD. DWH-computed from `OpenOccurred`. Nonclustered index supports date-based queries. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 29 | CloseDateID | int | NO | Position close date as integer YYYYMMDD. 0 = position is still open. Nonclustered indexes heavily use this column. Part of the clustered index. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 30 | RegulationIDOnOpen | int | NO | Regulatory jurisdiction at the time of opening. DWH-specific: joined from `etoro_History_BackOfficeCustomer`. Values: 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 13=MAS. References `Dim_Regulation`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 31 | PlatformTypeID | tinyint | YES | [UNVERIFIED] Platform type identifier. Not populated in this table — always NULL. (Tier 4) |
| 32 | PositionSegment | smallint | YES | [UNVERIFIED] Position segment classification. Not populated in this table — always NULL. (Tier 4) |
| 33 | Volume | int | YES | Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal. (Tier 5 — domain expert) |
| 34 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run that touches the row. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 35 | OpenInd | tinyint | YES | [UNVERIFIED] Open indicator flag. Values observed: NULL, 0, or 1. Purpose unknown. (Tier 4) |
| 36 | SpreadedCommission | int | YES | Spread commission expressed in pips (integer). Used in hedge calculation and spread-group reporting. (Tier 1 — Trade.PositionTbl) |
| 37 | EndForexRate | decimal(16,8) | YES | Instrument's exchange rate at position close. Set at close. NULL for open positions. Used in final NetProfit calculation. (Tier 1 — Trade.PositionTbl) |
| 38 | LastOpConversionRate | decimal(16,8) | YES | Account-currency conversion rate from the most recent overnight operation (for non-USD-denominated instruments). (Tier 1 — Trade.PositionTbl) |
| 39 | LimitRate | decimal(16,8) | YES | Take-profit rate. Price at which position closes if market moves in favor. Inherited from `Trade.PositionTreeInfo.LimitRate`. (Tier 1 — Trade.PositionTreeInfo) |
| 40 | StopRate | decimal(16,8) | YES | Stop-loss rate. Price at which position closes if market moves against. Inherited from `Trade.PositionTreeInfo.StopRate`. (Tier 1 — Trade.PositionTreeInfo) |
| 41 | ClosePositionReasonID | int | YES | Reason the position was closed. References `Dim_ClosePositionReason`: 0=Customer, 1=Stop Loss, 2=End of Week, 3=SL(trade server), 5=Take Profit, 6=TP(trade server), 7=Contract Rollover, 8=BackOffice, 9=Hierarchical Close, 10=Hierarchical recovery, 13=Copy Stop Loss, 14=Mirror manual close, 17=Manual Unregister, 18=BackOffice Unregister, 19=Redeem, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. NULL for open positions. (Tier 1 — Trade.PositionTbl, via Dictionary.ClosePositionActionType) |
| 42 | TreeID | bigint | YES | Copy-trading tree root identifier. For independent positions: `TreeID = PositionID`. For copy-trade positions: `TreeID = root leader's PositionID`. (Tier 1 — Trade.PositionTbl) |
| 43 | FullCommission | money | YES | Full spread at position open = market spread (variable spread, i.e. Ask - Bid) + eToro markup (Commission). Represents the total spread cost to the customer. (Tier 5 — domain expert) |
| 44 | FullCommissionOnClose | money | YES | Full spread at position close = market spread + eToro markup. May be adjusted by `SP_Dim_Position_ReOpen` for reopened positions. (Tier 5 — domain expert) |
| 45 | IsComputeForHedge | smallint | YES | Hedge participation flag: 1 = this position IS included in hedge exposure calculations (default); 0 = EXCLUDED from hedge calculations (set for `PlayerLevelID = 4` customers). (Tier 1 — Trade.PositionTbl) |
| 46 | InitialAmountCents | money | YES | The original opening amount in cents (Amount × 100). Preserved at open and NEVER updated. Used as the denominator in proportional calculations for corporate actions and partial closes. Divide by 100 for USD value: `InitialAmountCents / 100 AS InitialAmount`. (Tier 1 — Trade.PositionTbl) |
| 47 | RedeemStatus | tinyint | YES | Crypto redemption transaction status — tracks the full loop from position to crypto arriving in the customer's eToro wallet. Values: 0=N/A, 1=PositionPending, 6=PositionClosed (closed by redeem), 20=Terminated, 21=FailedToCancel. References `Dim_RedeemStatus`. (Tier 5 — domain expert) |
| 48 | RedeemID | int | YES | Reference to the crypto redemption transaction record. NULL when RedeemStatus=0. (Tier 5 — domain expert) |
| 49 | ReopenForPositionID | bigint | YES | For reopened positions: references the PositionID of the original closed position this new position replaces. Enables tracing the reopen lineage. (Tier 1 — Trade.PositionTbl) |
| 50 | IsReOpen | int | YES | Reopen flag: 1 = this position was created by reopening a previously closed position (e.g., after corporate action). Default 0. (Tier 1 — Trade.PositionTbl) |
| 51 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose value before adjustment by `SP_Dim_Position_ReOpen`. Preserved for reopened positions. (Tier 2 — SP_Dim_Position_ReOpen) |
| 52 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose value before adjustment by `SP_Dim_Position_ReOpen`. Default 0. (Tier 2 — SP_Dim_Position_ReOpen) |
| 53 | OriginalPositionID | bigint | YES | For partial-close children: references the parent PositionID. When `OriginalPositionID ≠ PositionID`, this is a partial-close child. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 54 | IsPartialCloseParent | int | YES | Flag: 1 = this position has had at least one partial close child created from it. Set by `SP_Dim_Position_IsPartialCloseParent`. (Tier 2 — SP_Dim_Position_IsPartialCloseParent) |
| 55 | IsPartialCloseChild | int | YES | Flag: 1 = this position was created by a partial close of another position. Filter out when counting positions: `ISNULL(IsPartialCloseChild, 0) = 0`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 56 | InitialUnits | decimal(16,6) | YES | Original unit count at position open, preserved before partial-close adjustments. `AmountInUnitsDecimal` is updated on partial close; `InitialUnits` is not. (Tier 1 — Trade.PositionTbl) |
| 57 | IsPartialCloseChildFromReOpen | int | YES | Flag: 1 = this is a partial close child of a reopened position. Set by `SP_Dim_Position_ReOpen`. (Tier 2 — SP_Dim_Position_ReOpen) |
| 58 | IsDiscounted | int | YES | Discounted pricing flag. Inherited from `Trade.PositionTreeInfo.IsDiscounted`: 0=standard Bid/Ask for BSL; 1=BidDiscounted/AskDiscounted (VIP/partner pricing). (Tier 1 — Trade.PositionTreeInfo) |
| 59 | IsSettled | int | YES | Legacy real-ownership indicator: 1 = "settled" (customer owns actual shares/asset), 0 = CFD/synthetic. Predates `SettlementTypeID`. Use as fallback: `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`. (Tier 1 — Trade.PositionTbl) |
| 60 | VolumeOnClose | int | YES | Close volume = rounded(Units * Price * ConversionRate) at close. Same calculation as Volume but using close-time values. Pro-rated for partial close. (Tier 5 — domain expert) |
| 61 | CommissionByUnits | decimal(38,6) | YES | eToro markup (Commission) prorated by current units: `(AmountInUnitsDecimal / InitialUnits) * Commission`. Adjusts for partial closes. Computed in `Trade.Position` view. (Tier 5 — domain expert) |
| 62 | FullCommissionByUnits | decimal(38,6) | YES | Full spread (FullCommission) prorated by current units: `(AmountInUnitsDecimal / InitialUnits) * FullCommission`. Adjusts for partial closes. Computed in `Trade.Position` view. (Tier 5 — domain expert) |
| 63 | IsCopyFundPosition | int | YES | Flag: 1 = position belongs to a CopyFund (tree root CID has AccountTypeID=9 OR MirrorTypeID=4 in Dim_Mirror). Computed by ETL SP. NULL = not a copy fund position. (Tier 5 — domain expert) |
| 64 | LastOpPriceRateID | bigint | YES | Reference to the price-rate record from the most recent overnight operation. (Tier 1 — Trade.PositionTbl) |
| 65 | IsAirDrop | int | YES | Airdrop flag: 1 = position was created by eToro on behalf of the customer (crypto staking, promotions, compensations — not limited to crypto). Set by matching against `Trade.PositionAirdropLog`. NULL = not an airdrop. (Tier 5 — domain expert) |
| 66 | InitForexPriceRateID | bigint | YES | Reference to the price-rate snapshot record captured at position open. Enables exact look-up of the opening rate for audit and recalculation. (Tier 1 — Trade.PositionTbl) |
| 67 | EndForexPriceRateID | bigint | YES | Reference to the price-rate snapshot at position close. (Tier 1 — Trade.PositionTbl) |
| 68 | InitForex_Ask | numeric(16,8) | YES | Ask price from the forex price snapshot at position open. Joined from `PriceLog_History_CurrencyPrice_Active` via `InitForexPriceRateID`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 69 | InitForex_Bid | numeric(16,8) | YES | Bid price from the forex price snapshot at position open. Joined from `PriceLog_History_CurrencyPrice_Active` via `InitForexPriceRateID`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 70 | InitForex_AskSpreaded | numeric(16,8) | YES | Ask price with spread applied at open, from the forex price snapshot. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 71 | InitForex_BidSpreaded | numeric(16,8) | YES | Bid price with spread applied at open, from the forex price snapshot. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 72 | InitForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate from the forex price snapshot at open. Used for converting P&L to USD. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 73 | EndForex_Ask | numeric(16,8) | YES | Ask price from the forex price snapshot at position close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 74 | EndForex_Bid | numeric(16,8) | YES | Bid price from the forex price snapshot at position close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 75 | EndForex_AskSpreaded | numeric(16,8) | YES | Ask price with spread applied at close, from the forex price snapshot. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 76 | EndForex_BidSpreaded | numeric(16,8) | YES | Bid price with spread applied at close, from the forex price snapshot. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 77 | EndForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate from the forex price snapshot at close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 78 | InitExecutionID | bigint | YES | Execution record ID from the external exchange or LP system at position open. Used for trade-level reconciliation with LP execution reports. Also used to determine `InitHedgeType` (HBC vs CBH). (Tier 1 — Trade.PositionTbl) |
| 79 | EndExecutionID | bigint | YES | Execution record ID from the external exchange/LP system at position close. Used to determine `EndHedgeType`. (Tier 1 — Trade.PositionTbl) |
| 80 | InitConversionRate | decimal(16,8) | YES | Conversion rate from instrument currency to account currency at position open. Used in P&L currency conversion. (Tier 1 — Trade.PositionTbl) |
| 81 | InitConversionRateID | bigint | YES | Reference to the conversion-rate snapshot record at open. (Tier 1 — Trade.PositionTbl) |
| 82 | CloseMarketPriceRateID | bigint | YES | Reference to the market price-rate record at position close. (Tier 1 — Trade.PositionTbl) |
| 83 | InitHedgeType | nvarchar(5) | YES | Hedging execution model at open: 'CBH' = Compute Before Hedge (standard — client trade computed first, then hedged), 'HBC' = Hedge Before Compute (hedge placed before client order). Determined by `SP_Dim_Position_HedgeType_Real` checking HBCExecutionLog. (Tier 5 — domain expert) |
| 84 | EndHedgeType | nvarchar(5) | YES | Hedging execution model at close: 'CBH' (Compute Before Hedge) or 'HBC' (Hedge Before Compute). Determined by `SP_Dim_Position_HedgeType_History`. NULL for open positions. (Tier 5 — domain expert) |
| 85 | OrderID | int | YES | Reference to the initial order that triggered this open (for order-driven opens). NULL for positions opened without a prior order. (Tier 1 — Trade.PositionTbl) |
| 86 | ExitOrderID | int | YES | For stop/limit triggered closes: the order ID of the exit order that triggered this close. NULL for market/direct closes. (Tier 1 — Trade.PositionTbl) |
| 87 | IsSettledOnOpen | int | YES | Settlement status at the time of position open. May differ from current `IsSettled` if converted after open. Use `ISNULL(IsSettledOnOpen, IsSettled)` for at-open segmentation. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 88 | StopRateOnOpen | numeric(16,8) | YES | Stop-loss rate recorded at position open time. May differ from current `StopRate` if the user modified it after open. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 89 | LimitRateOnOpen | numeric(16,8) | YES | Take-profit rate recorded at position open time. May differ from current `LimitRate` if modified after open. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 90 | LastOpPriceRate | decimal(16,8) | YES | Instrument price rate from the most recent overnight operation. Serves as the "starting rate" for the next overnight P&L calculation. (Tier 1 — Trade.PositionTbl) |
| 91 | SettlementTypeID | int | YES | Authoritative settlement type: 0=CFD, 1=REAL, 2=TRS, 3=CMT (Crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL in legacy rows — use `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`. (Tier 5 — domain expert, via Dictionary.SettlementTypes) |
| 92 | OpenMarketPriceRateID | bigint | YES | Reference to the market price-rate record specifically captured at open execution time. (Tier 1 — Trade.PositionTbl) |
| 93 | OpenMarket_Ask | numeric(16,8) | YES | Market ask price at position open. From the open-side market price snapshot. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 94 | OpenMarket_Bid | numeric(16,8) | YES | Market bid price at position open. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 95 | OpenMarket_AskSpreaded | numeric(16,8) | YES | Market ask price with spread at open. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 96 | OpenMarket_BidSpreaded | numeric(16,8) | YES | Market bid price with spread at open. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 97 | OpenMarketCoversionRateBidSpreaded | numeric(16,8) | YES | Conversion rate (bid-spreaded) at open market price snapshot. Note: column name has typo "Coversion" (not "Conversion"). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 98 | OpenMarketCoversionRateAskSpreaded | numeric(16,8) | YES | Conversion rate (ask-spreaded) at open market price snapshot. Note: column name has typo "Coversion". (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 99 | CloseMarket_AskSpreaded | numeric(16,8) | YES | Market ask price with spread at close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 100 | CloseMarket_BidSpreaded | numeric(16,8) | YES | Market bid price with spread at close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 101 | CloseMarket_Ask | numeric(16,8) | YES | Market ask price at position close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 102 | CloseMarket_Bid | numeric(16,8) | YES | Market bid price at position close. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 103 | CloseMarketCoversionRateBidSpreaded | numeric(16,8) | YES | Conversion rate (bid-spreaded) at close market price snapshot. Note: column name has typo "Coversion". (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 104 | CloseMarketCoversionRateAskSpreaded | numeric(16,8) | YES | Conversion rate (ask-spreaded) at close market price snapshot. Note: column name has typo "Coversion". (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 105 | RequestOpenOccurred | datetime2 | YES | UTC timestamp when the position open was requested. May differ from `OpenOccurred` if execution was queued or delayed. Maps to `RequestOccurred` in production. (Tier 1 — Trade.PositionTbl, renamed) |
| 106 | RequestCloseOccurred | datetime2 | YES | UTC timestamp when the position close was requested. Used for close latency measurement. (Tier 1 — Trade.PositionTbl) |
| 107 | OrderType | int | YES | Order type used to open this position. References `Dictionary.OrderType`. Common values include NULL (no triggering order), 0, 13, 15, 16, 17, 18. (Tier 1 — Trade.PositionTbl) |
| 108 | PnLVersion | int | YES | P&L calculation formula version: 0=CFD_FORMULA (original for synthetic/CFD), 1=REAL_FORMULA (for real/settled positions). NULL for legacy rows. Determines which code path `Trade.FnCalculatePnL` uses. (Tier 1 — Trade.PositionTbl) |
| 109 | PnLInDollars | decimal(38,6) | YES | Current unrealized P&L in dollars for open positions (end-of-day snapshot). From `Trade.OpenPositionEndOfDay`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 110 | OpenMarketSpread | decimal(38,18) | YES | Market spread (aka variable spread) at position open = Ask - Bid. This is the market-side spread before eToro's markup is added. (Tier 5 — domain expert) |
| 111 | CloseMarketSpread | decimal(38,18) | YES | Market spread (variable spread) at position close = Ask - Bid. (Tier 5 — domain expert) |
| 112 | CloseMarkupOnOpen | decimal(38,18) | YES | eToro's close-side markup amount pre-computed at open time. Locks in the close markup rate at entry. (Tier 5 — domain expert) |
| 113 | OpenMarkup | decimal(38,18) | YES | eToro's markup (additional spread) amount charged at position open, in account currency. Same concept as Commission but in spread terms. (Tier 5 — domain expert) |
| 114 | CloseMarkup | decimal(38,18) | YES | eToro's markup amount charged at position close. (Tier 5 — domain expert) |
| 115 | DLTOpen | smallint | YES | DLT broker flag at open: 1 = position was opened on the DLT platform (a German crypto broker used for trade execution). 0 or NULL = not executed on DLT broker. Computed in source view `Trade.PositionForExternalUse`. (Tier 5 — domain expert) |
| 116 | DLTClose | smallint | YES | DLT broker flag at close: 1 = position was closed on the DLT broker platform. NULL or 0 = not DLT. (Tier 5 — domain expert) |
| 117 | OpenMarkupByUnits | money | YES | eToro's open markup prorated by current units: `OpenMarkup * AmountInUnitsDecimal / InitialUnits`. Adjusts for partial closes. (Tier 5 — domain expert) |
| 118 | CommissionVersion | int | YES | Commission calculation version. Different values represent different versions/models of how commission is computed on the position. (Tier 5 — domain expert) |
| 119 | ExitOrderType | int | YES | Order type of the exit order that triggered close (for stop/limit-triggered closes). Values include 19 and 20. NULL for direct closes. (Tier 1 — Trade.PositionTbl) |
| 120 | OpenPositionReasonID | int | YES | The mechanism or reason this position was opened. Maps to `Dictionary.OpenPositionActionType` (column IS `OpenActionType` from production). Standard values: 0=Customer, 1=Hierarchical (copy), 3=AddFunds, 16=specific action type. Note: 2000-series values (2020-2023) observed in DWH are likely a pipeline/ETL data quality issue — the upstream dictionary uses 0-18. (Tier 5 — domain expert) |
| 121 | OpenTotalTaxes | decimal(38,18) | YES | Total taxes charged at position open (e.g., UK stamp duty for UK-listed stocks). Default=0. (Tier 1 — Trade.PositionTbl) |
| 122 | CloseTotalTaxes | decimal(38,18) | YES | Total taxes charged at position close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |
| 123 | OpenTotalFees | decimal(38,18) | YES | Total ticket fees at position open — either a fixed dollar amount or a percentage of position volume, depending on fee configuration. Additional fees may be added later; full breakdown in `History.Cost`. (Tier 5 — domain expert) |
| 124 | CloseTotalFees | decimal(38,18) | YES | Total ticket fees at position close — either fixed or % of volume. Additional fees may accrue after close; full breakdown in `History.Cost`. NULL for open positions. (Tier 5 — domain expert) |
| 125 | EstimateCloseFeeForCFD | numeric(38,6) | YES | Estimated close fee for CFD positions. From `Trade.OpenPositionEndOfDay`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 126 | EstimateCloseFeeOnOpenByUnits | numeric(38,6) | YES | Estimated close fee at open, per unit. From `Trade.OpenPositionEndOfDay`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 127 | EstimateCloseFeeOnOpen | numeric(38,8) | YES | Estimated close fee recorded at open. From `Trade.OpenPositionEndOfDay`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 128 | Close_PnLInDollars | decimal(38,6) | YES | Same as PnLInDollars but calculated using the closing price instead of the last (current) price. (Tier 5 — domain expert) |
| 129 | Close_CalculationRate | decimal(16,8) | YES | Instrument rate used to compute `Close_PnLInDollars` (closing-price-based P&L, as opposed to last-price-based PnLInDollars). (Tier 5 — domain expert) |
| 130 | Close_ConversionRate | decimal(26,17) | YES | Currency conversion rate used to compute `Close_PnLInDollars`. Converts from instrument currency to account currency using the closing price snapshot. (Tier 5 — domain expert) |
| 131 | Close_PriceType | int | YES | Closing price source type used in the `Close_PnLInDollars` calculation. Indicates how the closing price was determined: official exchange close (price provider), unofficial close price, dealer injection (minutes before close), or last price in the internal feed. Exact value mapping TBD. (Tier 5 — domain expert) |
| 132 | CurrentCalculationRate | decimal(16,8) | YES | Current calculation rate for open position P&L (end-of-day snapshot). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 133 | CurrentConversionRate | decimal(26,17) | YES | Current conversion rate to account currency for open position P&L. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PositionID | Trade.PositionTbl | PositionID | None |
| CID | Trade.PositionTbl | CID | None |
| OpenOccurred | Trade.PositionTbl | Occurred | Renamed |
| CloseOccurred | Trade.PositionTbl | CloseOccurred | None |
| OpenDateID | Trade.PositionTbl | Occurred | `CAST(CONVERT(VARCHAR(8), Occurred, 112) AS INT)` |
| CloseDateID | Trade.PositionTbl | CloseOccurred | `CAST(CONVERT(VARCHAR(8), CloseOccurred, 112) AS INT)`, 0 if open |
| LimitRate | Trade.PositionTreeInfo | LimitRate | None (joined via TreeID) |
| StopRate | Trade.PositionTreeInfo | StopRate | None (joined via TreeID) |
| CloseOnEndOfWeek | Trade.PositionTreeInfo | CloseOnEndOfWeek | None |
| IsDiscounted | Trade.PositionTreeInfo | IsDiscounted | None |
| RegulationIDOnOpen | History.BackOfficeCustomer | RegulationID | Joined by CID + date range |
| InitHedgeType | Computed | — | 'HBC' if InitExecutionID in HBCExecutionLog, else 'CBH' |
| EndHedgeType | Computed | — | 'HBC' if EndExecutionID in HBCExecutionLog, else 'CBH' |
| IsCopyFundPosition | Computed | — | 1 if tree root CID has AccountTypeID=9 |
| IsAirDrop | Trade.PositionAirdropLog | PositionID | 1 if match found |
| IsPartialCloseParent | Computed | — | 1 if OriginalPositionID references this position |
| DLTOpen | Trade.PositionForExternalUse | DLTOpen | Computed from HedgeServerID + date range |
| CommissionByUnits | Trade.Position (view) | Computed | `(AmountInUnitsDecimal / InitialUnits) * Commission` |
| FullCommissionByUnits | Trade.Position (view) | Computed | `(AmountInUnitsDecimal / InitialUnits) * FullCommission` |
| OpenMarkupByUnits | Trade.Position (view) | Computed | `OpenMarkup * AmountInUnitsDecimal / InitialUnits` |
| CommissionVersion | Trade.PositionForExternalUse | CommissionVersion | `IIF(OpenMarketSpread IS NULL, NULL, 2)` |
| InitForex_* | PriceLog_History_CurrencyPrice_Active | Ask/Bid/etc. | Joined via InitForexPriceRateID |
| EndForex_* | PriceLog_History_CurrencyPrice_Active | Ask/Bid/etc. | Joined via EndForexPriceRateID |
| RequestOpenOccurred | Trade.PositionTbl | RequestOccurred | Renamed |

**Bulk mapping**: All columns not listed above are direct pass-throughs from `Trade.PositionTbl` via the `Trade.Position` → `Trade.PositionForExternalUse` → `Trade.OpenPositionEndOfDay` view chain. Column names are preserved (except `Occurred` → `OpenOccurred` and `RequestOccurred` → `RequestOpenOccurred`). OpenMarket_* / CloseMarket_* / InitForex_* / EndForex_* columns are joined by the ETL SP from `PriceLog_History_CurrencyPrice_Active` using the corresponding PriceRateID columns.

Full production documentation: see upstream wiki `Trade/Tables/Trade.PositionTbl.md`, `Trade/Tables/Trade.PositionTreeInfo.md`, `Trade/Views/Trade.Position.md`, `Trade/Views/Trade.PositionForExternalUse.md`, `Trade/Views/Trade.OpenPositionEndOfDay.md`

### 5.2 ETL Pipeline

```
Trade.PositionTbl + Trade.PositionTreeInfo
  → Trade.Position (view: INNER JOIN on TreeID, StatusID=1, computes CommissionByUnits/FullCommissionByUnits/OpenMarkupByUnits)
    → Trade.PositionForExternalUse (view: adds DLTOpen, CommissionVersion, NULLs legacy columns)
      → Trade.OpenPositionEndOfDay (view: adds PnLInDollars, Close_PnL, estimated fees)
        → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
          → SP_Dim_Position_DL_To_Synapse → DWH_dbo.Dim_Position

History.Position_Active
  → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Dim_Position_DL_To_Synapse → DWH_dbo.Dim_Position
```

| Step | Object | Description |
|------|--------|-------------|
| Base tables | `Trade.PositionTbl` + `Trade.PositionTreeInfo` | Core position data + tree-level SL/TP/IsDiscounted |
| View layer 1 | `Trade.Position` | Joins PositionTbl + PositionTreeInfo for open positions (StatusID=1); computes CommissionByUnits, FullCommissionByUnits, OpenMarkupByUnits |
| View layer 2 | `Trade.PositionForExternalUse` | Adds DLTOpen, CommissionVersion; NULLs legacy columns for schema alignment |
| Source (open) | `Trade.OpenPositionEndOfDay` | Adds PnLInDollars, Close_PnL, estimated close fees via FnCalculatePnLWrapper |
| Source (closed) | `History.ClosePositionEndOfDay` | Production view for closed/archived positions |
| Lake | Azure Data Lake (Bronze/DailySnapshot) | Daily parquet export via Generic Pipeline |
| Staging | `DWH_staging.etoro_Trade_OpenPositionEndOfDay` / `DWH_staging.etoro_History_ClosePositionEndOfDay` | Raw import from lake |
| ETL | `DWH_dbo.SP_Dim_Position_DL_To_Synapse` | Main ETL: delete-insert for new, update for existing open positions |
| Post-ETL | `SP_Dim_Position_HedgeType_Real`, `SP_Dim_Position_HedgeType_History` | Compute InitHedgeType/EndHedgeType |
| Post-ETL | `SP_Dim_Position_IsPartialCloseParent` | Set IsPartialCloseParent flag |
| Post-ETL | `SP_Dim_Position_ReOpen` | Adjust commissions for reopened positions |
| Target | `DWH_dbo.Dim_Position` | Final DWH dimension table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who owns this position |
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument being traded |
| CurrencyID | DWH_dbo.Dim_Currency | Account currency (always 1=USD) |
| MirrorID | DWH_dbo.Dim_Mirror | Copy-trade relationship |
| ClosePositionReasonID | DWH_dbo.Dim_ClosePositionReason | Reason for position close |
| RegulationIDOnOpen | DWH_dbo.Dim_Regulation | Regulatory jurisdiction at open |
| OpenDateID / CloseDateID | DWH_dbo.Dim_Date | Calendar dimension for dates |
| RedeemStatus | DWH_dbo.Dim_RedeemStatus | Crypto redemption transaction status |
| SettlementTypeID | Dictionary.SettlementTypes | Settlement type (CFD/REAL/TRS/CMT/REAL_FUTURES/MARGIN_TRADE) |
| TreeID | DWH_dbo.Dim_Position (self) | Root of copy-trade tree |
| OriginalPositionID | DWH_dbo.Dim_Position (self) | Parent for partial-close children |
| ReopenForPositionID | DWH_dbo.Dim_Position (self) | Original position for reopens |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_PositionPnL | PositionID | Daily P&L for open positions |
| DWH_dbo.Dim_PositionChangeLog | PositionID | Position change audit log |
| BI_DB_dbo.BI_DB_V_StockMargin_Balances | PositionID | Stock margin calculations |
| 130+ Stored Procedures | PositionID | Used across BI, Dealing, Compliance, Finance SPs |

---

## 7. Sample Queries

### 7.1 All open positions for a customer (excluding partial-close children)
```sql
SELECT dp.PositionID, dp.InstrumentID, di.InstrumentDisplayName,
       dp.Amount, dp.AmountInUnitsDecimal, dp.Leverage,
       dp.InitForexRate, dp.OpenOccurred,
       CASE WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1 THEN 'Real' ELSE 'CFD' END AS SettlementType
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
WHERE dp.CID = @cid
  AND dp.CloseDateID = 0
  AND ISNULL(dp.IsPartialCloseChild, 0) = 0
```

### 7.2 Positions closed yesterday with close reason
```sql
SELECT dp.PositionID, dp.CID, dp.InstrumentID,
       dp.Amount, dp.NetProfit,
       dp.OpenOccurred, dp.CloseOccurred,
       dcpr.Name AS CloseReason,
       dr.Name AS Regulation
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_ClosePositionReason dcpr ON dp.ClosePositionReasonID = dcpr.ClosePositionReasonID
JOIN DWH_dbo.Dim_Regulation dr ON dp.RegulationIDOnOpen = dr.ID
WHERE dp.CloseDateID = CAST(CONVERT(VARCHAR(8), DATEADD(DAY, -1, GETDATE()), 112) AS INT)
```

### 7.3 Position type segmentation (Manual Real / Manual CFD / Copy Real / Copy CFD)
```sql
SELECT
    CASE
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1 AND dp.MirrorID = 0 THEN 'Manual Real'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0 AND dp.MirrorID = 0 THEN 'Manual CFD'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1 AND dp.MirrorID <> 0 THEN 'Copy Real'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0 AND dp.MirrorID <> 0 THEN 'Copy CFD'
        ELSE 'Other'
    END AS Position_Type,
    COUNT(*) AS PositionCount,
    SUM(dp.InitialAmountCents / 100) AS TotalInitialAmount
FROM DWH_dbo.Dim_Position dp
WHERE dp.OpenDateID >= 20250101
  AND ISNULL(dp.IsPartialCloseChild, 0) = 0
GROUP BY
    CASE
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1 AND dp.MirrorID = 0 THEN 'Manual Real'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0 AND dp.MirrorID = 0 THEN 'Manual CFD'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1 AND dp.MirrorID <> 0 THEN 'Copy Real'
        WHEN ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0 AND dp.MirrorID <> 0 THEN 'Copy CFD'
        ELSE 'Other'
    END
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Summary: Dim_Position, Dim Instrument and Position_PNL](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060834495) | Confluence | Analyst guide: partial close handling, InitialAmountCents/100 formula, position type segmentation CASE pattern |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | Confluence | Table purpose: "Holds position-level data for trades opened or closed by clients", CloseDateID=0 for open positions |
| [DWH Dim_Position Data Issue - 2024-09-02](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12608077834) | Confluence | Incident: hardcoded date caused table not being updated with new positions; impacted financial reports |
| [DWH Process Failures (SP_Dim_Position_DL_To_Synapse) - 2025-09-04](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13410369563) | Confluence | Incident: Dim_Position_SWITCH_SINGLE table schema mismatch caused ETL failure |
| [Export dim_position+dim_mirror to Azure DataLake](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11810376720) | Confluence | DataLake export: Delta format, partitioned, accessible via shared Hive-Metastore |
| [Regulation Breaches Investigation Flows](https://etoro-jira.atlassian.net/wiki/spaces/ProfessionalServices/pages/13144555670) | Confluence | Compliance use of Dim_Position for regulation breach monitoring |
| [Trading Events Comparison Between Mixpanel and Dim_Position](https://etoro-jira.atlassian.net/wiki/spaces/PA/pages/11790485286) | Confluence | Dim_Position contains fulfilled positions only (not pending/failed) |
| [Dim_Position historical fixes (DSM-2145)](https://etoro-jira.atlassian.net/browse/DSM-2145) | Jira | Account statement project historical data fixes |

---

*Generated: 2026-03-02 | Enriched: 2026-03-03 | Object: DWH_dbo.Dim_Position | Type: Table | Phases: 14/14*
*Production Source: Trade/Tables/Trade.PositionTbl.md, Trade/Tables/Trade.PositionTreeInfo.md, Trade/Views/Trade.Position.md, Trade/Views/Trade.PositionForExternalUse.md, Trade/Views/Trade.OpenPositionEndOfDay.md*
