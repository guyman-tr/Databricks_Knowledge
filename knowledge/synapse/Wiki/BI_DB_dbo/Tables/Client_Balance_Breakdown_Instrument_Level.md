# BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

> Daily PnL and commission breakdown at the (customer × instrument × segmentation) grain — decomposed into realized/unrealized components across 53 dimensions. Designed as a robust replacement for raw PositionPnL + DimPosition queries in financial reporting.

---

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Computed (aggregated from Fact_CustomerAction, BI_DB_PositionPnL, Dim_Position, Dim_SnapshotCustomer) |
| **Author** | Guy Manova (2023-04-20) |
| **Refresh** | Daily (P20 — runs after position and customer snapshot data is available) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX (optimized for aggregation) |
| **Rows** | ~5M per day; >2B total (INT overflow on COUNT) |
| **Date Range** | 2023-04-20 (SP creation) to present |

---

## 1. Business Meaning

`Client_Balance_Breakdown_Instrument_Level` is a **daily pre-aggregated fact table** that decomposes each customer's daily PnL and commission activity by instrument, position characteristics, and all customer segmentation dimensions. It was created as a high-performance alternative to joining `BI_DB_PositionPnL` + `Dim_Position` directly in reports — a join pattern that was previously over-used and expensive.

Each row represents one combination of (date × instrument × position attributes × customer attributes). The table covers all customers with active or closed positions on a given day, aggregating USD PnL and commission contributions from four position lifecycle categories:

1. **OpenBeforeClosedDuring**: Position opened before the date, closed on the date → contributes realized PnL
2. **OpenBeforeNotClosed**: Position opened before the date, still open at end of day → contributes unrealized daily PnL change (DailyPnL)
3. **OpenDuringNotClosed**: Position opened on the date, still open at end of day → contributes new unrealized PnL
4. **OpenDuringClosedDuring**: Position opened and closed on the same date (intraday) → contributes realized PnL

**Scale** (April 12, 2026): ~4.94M rows/day. InstrumentType breakdown: Stocks 78.5%, ETF 11.4%, Crypto 9.1%, Commodities 0.4%, Indices 0.4%, Currencies 0.2%.

**⚠ CRITICAL WARNING (from SP header):**
> Customers who changed regulation on a given day appear as TWO rows — one with RegTransferDirection=-1 (old regulation) and one with RegTransferDirection=+1 (new regulation). **NEVER GROUP BY CID AND Regulation simultaneously.** Use either CID alone OR Regulation alone.

---

## 2. Business Logic

### 2.1 Four Position Types

The SP classifies every position-day event into one of four types and assembles them with different PnL component assignments:

| Type | OpenDateID | CloseDateID | RealizedPnL | UnrealizedChange | CommissionOnOpen | CommissionOnClose |
|------|-----------|------------|-------------|-----------------|-----------------|------------------|
| OpenBeforeClosedDuring | < @DateID | = @DateID | dp.NetProfit | -1 × prev PnL (reversal) | 0 | dp.CommissionOnClose |
| OpenBeforeNotClosed | < @DateID | > @DateID or 0 | 0 | DailyPnL (from PositionPnL) | 0 | 0 |
| OpenDuringNotClosed | = @DateID | > @DateID or 0 | 0 | DailyPnL (new position) | dp.Commission | 0 |
| OpenDuringClosedDuring | = @DateID | = @DateID | dp.NetProfit | 0 | dp.Commission | dp.CommissionOnClose |

### 2.2 Commission vs FullCommission

The SP tracks two parallel commission structures:

- **Commission / RealizedCommission / etc.**: Standard position commission — what the customer sees. For non-leveraged positions (stocks, crypto), this equals the spread.
- **FullCommission / RealizedFullCommission / etc.**: Accounting/revenue commission — total spread revenue eToro earns. For leveraged positions, FullCommission > Commission (includes overnight funding).

`TotalZero = UnrealizedFullCommissionChange + UnrealizedPnLChange + RealizedFullCommission + RealizedPnL`  
This metric should approximate zero over time (revenue + cost balance). Used for reconciliation.

### 2.3 Regulation Transfer Handling

When a customer changes regulation on @DateID, the SP creates **dual rows**:
- RegTransferDirection = -1: Row attributed to the OLD regulation. PnL = open PnL reversal only (unwinding the old reg's books).
- RegTransferDirection = 1: Row attributed to the NEW regulation. Full PnL attribution going forward.

April 12, 2026: Only 142 rows had RegTransferDirection=-1 vs 4.94M rows with +1.

### 2.4 Ticket Fee by Percent

New commission pricing model (effective 2025-06-01 for newly opened positions). Tracked via:
- `Function_Revenue_TicketFeeByPercent` — identifies positions using percent-based ticket fees
- `TicketFeeByPercentPositionType`: "New" (instrument + position both qualify), "Legacy" (instrument qualifies but position predates the model), "NotRelevantToTicketFeeByPercent"
- `TicketFeeByPercentOnClose` / `TicketFeeByPercentOnOpen`: USD fee amounts

### 2.5 ETL Pattern (DELETE + INSERT Daily)

```
SP_Client_Balance_Breakdown(@Date)
  → DELETE FROM Client_Balance_Breakdown_Instrument_Level WHERE DateID = @DateID
  → 20+ temp tables assembling position events, customer snapshots, regulation changes
  → #finalPrepAll: unified position events with all commission components
  → #withCIDData: customer segmentation attributes joined
  → Final GROUP BY on all non-metric dimensions
  → INSERT INTO Client_Balance_Breakdown_Instrument_Level
```

---

## 3. Query Advisory

### 3.1 Grain

One row per **(DateID × InstrumentID × IsSettled × IsMirror × IsLeverage × IsLeverageMoreThen20 × IsAirDrop × SettlementTypeID × IsBuy × Regulation × RegTransferDirection × IsCreditReportValidCB × IsValidCustomer × AccountStatusName × AccountType × Country × US_State × Region × MiFiDCategorization × Club × PlayerStatus × Label × IsOutlier × Transition × IsGermanBaFIN × IsEtoroTradingCID × IsGlenEagleAccount × TanganyStatus × IsDLTUser × CommissionVersion × IsSQF × TicketFeeByPercentPositionType × IsC2P)**.

This is effectively the finest-grain aggregation before CID.

### 3.2 ⚠ Critical Usage Rules

1. **Never GROUP BY CID and Regulation together.** Regulation-transfer customers appear in two rows on the transfer day. Group by one or the other.
2. **Exclude RegTransferDirection = -1 for most analyses.** The -1 rows are bookkeeping adjustments, not "real" daily P&L. Filter: `WHERE RegTransferDirection = 1`.
3. **TotalZero as reconciliation only.** Do not use TotalZero as a PnL metric.
4. **COLUMNSTORE is for aggregation.** This table is not optimized for row-level lookups; use aggregated GROUP BY queries.

### 3.3 Common Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily total revenue by regulation | `SUM(RealizedCommission + UnrealizedCommissionChange) WHERE RegTransferDirection = 1 GROUP BY DateID, Regulation` |
| Daily PnL by instrument type | `SUM(TotalPnL) GROUP BY DateID, InstrumentType` |
| Crypto daily PnL trend | `WHERE InstrumentType = 'Crypto Currencies' AND RegTransferDirection = 1 GROUP BY DateID` |
| Realized vs unrealized split | `SUM(RealizedPnL)` vs `SUM(UnrealizedPnLChange)` |
| Full commission revenue (eToro perspective) | `SUM(TotalFullCommission) WHERE RegTransferDirection = 1` |
| Outlier impact | `WHERE IsOutlier = 1` |
| German BaFin scope | `WHERE IsGermanBaFIN = 1` |
| US State breakdown | `WHERE Country = 'United States' GROUP BY US_State` |

### 3.4 Gotchas

- **RegTransferDirection = -1 rows**: Always filter unless specifically analyzing regulation-transfer adjustments.
- **TanganyStatus NULL dominates (88.7%)**: Most customers don't use Tangany wallet. NULL = not a Tangany customer.
- **`@DateNextID` bug in SP**: `DateNextID = CAST(CONVERT(VARCHAR(8), @DatePrev, 112) AS INT)` — this is a copy-paste bug (uses `@DatePrev` instead of `@DateNext`). Impact: `#pnlPosNext` uses the previous day's positions to filter "positions that continue beyond today." This is a known issue. Use the table data as-is; do not attempt to reproduce the SP logic for `OpenBeforeNotClosed` type.
- **TicketFeeByPercentOnOpen** is decimal(38,18) — very high precision; may cause display issues.
- **CommissionVersion** tracks the commission calculation schema version (2 = current as of April 2026).

---

## 4. Elements

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Client_Balance_Breakdown) |
| ** | Tier 3 - inferred from context | (Tier 3 - inferred) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date of the record in YYYYMMDD integer format. ETL key: the SP deletes and reloads all rows for this DateID on each run. E.g., 20260412 = April 12, 2026. (Tier 2 - SP_Client_Balance_Breakdown) |
| 2 | Date | date | YES | Full date value corresponding to DateID. Set from `@Date` SP parameter. Redundant with DateID; use DateID for joins, Date for display. (Tier 2 - SP_Client_Balance_Breakdown) |
| 3 | IsSettled | int | YES | 1 if the position has settled (crypto: real crypto ownership transferred); 0 if CFD/unsettled. Sourced from `Dim_Position.IsSettled` with override logic for positions that changed settlement status during the day (via `#IsSettledIsMirror`). (Tier 2 - SP_Client_Balance_Breakdown) |
| 4 | IsMirror | int | YES | 1 if the position is a copy-trading (CopyTrade/Mirror) position; 0 if manually placed. Derived: `CASE WHEN MirrorID > 0 THEN 1 ELSE 0`. Override applied via `#IsSettledIsMirror` for settlement-day edge cases. (Tier 2 - SP_Client_Balance_Breakdown) |
| 5 | InstrumentID | int | YES | Instrument identifier. FK to `DWH_dbo.Dim_Instrument`. Grain dimension: one row per unique instrument active for the CID-group on this date. (Tier 2 - SP_Client_Balance_Breakdown) |
| 6 | InstrumentTypeID | int | YES | Numeric instrument type code. FK to `DWH_dbo.Dim_Instrument`. Values: 5=Stocks, 10=Crypto Currencies, 6=ETF, etc. From SP: `di.InstrumentTypeID`. (Tier 2 - SP_Client_Balance_Breakdown) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type name: "Stocks" (78.5%), "ETF" (11.4%), "Crypto Currencies" (9.1%), "Commodities" (0.4%), "Indices" (0.4%), "Currencies" (0.2%). Sourced from `DWH_dbo.Dim_Instrument.InstrumentType`. (Tier 2 - SP_Client_Balance_Breakdown) |
| 8 | IsLeverage | int | YES | 1 if the position uses leverage > 1x; 0 for non-leveraged (Leverage=1, typical for stocks/crypto). Derived: `CASE WHEN Leverage > 1 THEN 1 ELSE 0`. (Tier 2 - SP_Client_Balance_Breakdown) |
| 9 | IsLeverageMoreThen20 | int | YES | 1 if position leverage exceeds 20x; 0 otherwise. Derived: `CASE WHEN Leverage > 20 THEN 1 ELSE 0`. Used for high-leverage exposure reporting and regulatory risk filters. (Tier 2 - SP_Client_Balance_Breakdown) |
| 10 | IsAirDrop | int | YES | 1 if position originated from a crypto airdrop event; 0 otherwise. Sourced from `Dim_Position.IsAirDrop`. Relevant for eToro crypto airdrop distribution events. (Tier 2 - SP_Client_Balance_Breakdown) |
| 11 | SettlementTypeID | int | YES | Settlement type identifier from `Dim_Position.SettlementTypeID`. Distinguishes settlement methods (e.g., real crypto vs CFD). (Tier 2 - SP_Client_Balance_Breakdown) |
| 12 | IsBuy | int | YES | 1 if the position is a long (buy) position; 0 if short (sell). Sourced from `Dim_Position.IsBuy`. (Tier 2 - SP_Client_Balance_Breakdown) |
| 13 | Regulation | varchar(50) | YES | Customer's regulatory jurisdiction on this date from `Dim_Regulation.Name`. For regulation-transfer days, this column holds EITHER the old (RegTransferDirection=-1) or new (RegTransferDirection=+1) regulation. See §2.3. Top values: CySEC (59%), FCA (20%), FSA Seychelles (13%), ASIC & GAML (2.9%), FSRA (2.2%). (Tier 2 - SP_Client_Balance_Breakdown) |
| 14 | RegTransferDirection | int | YES | Direction of regulation transfer for customers who changed regulation on this date. Values: 1=standard row (all customers), -1=old-regulation reversal row (only regulation-transfer customers). April 12, 2026: 4.94M rows at +1, 142 rows at -1. Filter: `WHERE RegTransferDirection = 1` for standard analysis. (Tier 2 - SP_Client_Balance_Breakdown) |
| 15 | IsCreditReportValidCB | int | YES | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau) at this date's snapshot. ETL-computed flag from `Fact_SnapshotCustomer`. See DWH_dbo.Fact_SnapshotCustomer §2.3 for logic. (Tier 2 - SP_Client_Balance_Breakdown) |
| 16 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics (excludes demo/internal/blocked). From `Fact_SnapshotCustomer.IsValidCustomer`. Nearly all active trading rows = 1. (Tier 2 - SP_Client_Balance_Breakdown) |
| 17 | AccountStatusName | varchar(50) | YES | Customer account status name from `Dim_AccountStatus.AccountStatusName`. Values include: "Open" (active), "Closed", "Blocked", etc. (Tier 2 - SP_Client_Balance_Breakdown) |
| 18 | AccountType | varchar(50) | YES | Account type name from `Dim_AccountType.Name`. Values: "Private" (retail), "Professional", "Employee", etc. (Tier 2 - SP_Client_Balance_Breakdown) |
| 19 | Country | varchar(50) | YES | Customer's registered country name from `Dim_Country.Name`. (Tier 2 - SP_Client_Balance_Breakdown) |
| 20 | US_State | varchar(50) | YES | US state short name (e.g., "CA", "NY") from `Dim_State_and_Province.ShortName`, populated only for US customers (CountryID=219). Empty string for non-US customers. (Tier 2 - SP_Client_Balance_Breakdown) |
| 21 | Region | varchar(50) | YES | Customer's marketing region from `Dim_Country.MarketingRegionManualName`. Groups countries into business regions (e.g., "Spain", "CEE", "North Europe"). (Tier 2 - SP_Client_Balance_Breakdown) |
| 22 | MiFiDCategorization | varchar(50) | YES | Customer's MiFID II categorization from `Dim_MifidCategorization.Name`. Values: "Retail", "Retail Pending", "Professional", "Eligible Counterparty". (Tier 2 - SP_Client_Balance_Breakdown) |
| 23 | Club | varchar(50) | YES | eToro Club loyalty tier name from `Dim_PlayerLevel.Name`. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, N/A. (Tier 2 - SP_Client_Balance_Breakdown) |
| 24 | PlayerStatus | varchar(50) | YES | Customer account lifecycle status from `Dim_PlayerStatus.Name`. Values: "Normal", "Closed", "Blocked", etc. (Tier 2 - SP_Client_Balance_Breakdown) |
| 25 | Label | varchar(50) | YES | eToro brand/label from `Dim_Label.Name`. Values: "eToro", "eToro UK", "eToro Australia", etc. (Tier 2 - SP_Client_Balance_Breakdown) |
| 26 | IsOutlier | int | YES | 1 if the customer is flagged as a statistical outlier on this date by `BI_DB_Outliers_New`; 0 otherwise. Used to exclude atypical customers from aggregate PnL analysis. (Tier 2 - SP_Client_Balance_Breakdown) |
| 27 | Transition | varchar(50) | YES | Outlier transition type from `BI_DB_Outliers_New.Transition`. "NoTransition" for non-outliers. Describes the nature of outlier status (e.g., new outlier, exiting outlier). (Tier 2 - SP_Client_Balance_Breakdown) |
| 28 | IsGermanBaFIN | int | YES | 1 if the customer is a German BaFin-regulated customer with crypto holdings; 0 otherwise. ETL-computed: `CASE WHEN HoldsCrypto=1 AND CountryID=79 THEN 1 ELSE 0`. Relevant for BaFin regulatory reporting. (Tier 2 - SP_Client_Balance_Breakdown) |
| 29 | IsEtoroTradingCID | int | YES | 1 if the CID is an internal eToro trading account (hardcoded list of 7 CIDs: 2244852, 2283663, 2283668, 5969868, 5969870, 5969875, 5969866). Used to filter out eToro's own positions in customer-facing metrics. (Tier 2 - SP_Client_Balance_Breakdown) |
| 30 | IsGlenEagleAccount | int | YES | 1 if the CID is the Glen Eagle account (CID = 14155290); 0 otherwise. Glen Eagle is a specific institutional counterparty account. (Tier 2 - SP_Client_Balance_Breakdown) |
| 31 | UnrealizedPnLChange | decimal(18,6) | YES | Daily change in unrealized PnL for positions still open at end of day. Aggregates: new position's end-of-day PnL (OpenDuringNotClosed), daily mark-to-market change for existing open positions (OpenBeforeNotClosed), and reversal of prior-day PnL for positions closed today (OpenBeforeClosedDuring). USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 32 | RealizedPnL | decimal(18,6) | YES | Realized profit/loss for positions closed on this date. `Dim_Position.NetProfit` summed for OpenBeforeClosedDuring and OpenDuringClosedDuring types. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 33 | TotalPnL | decimal(18,6) | YES | `UnrealizedPnLChange + RealizedPnL`. Total daily PnL contribution including both realized and mark-to-market changes. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 34 | UnrealizedCommissionChange | decimal(18,6) | YES | Daily change in the unrealized commission component. Captures opening spread costs for new open positions and partial close adjustments. Standard commission scale (customer-facing). USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 35 | RealizedCommission | decimal(18,6) | YES | Commission realized on positions closed today. Standard commission (customer-facing). Sourced from `CommissionOnClose` for closed positions. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 36 | UnrealizedFullCommissionChange | decimal(18,6) | YES | Daily change in unrealized full commission. "Full" = accounting/revenue commission including all spread components. For non-leveraged positions, equals UnrealizedCommissionChange. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 37 | RealizedFullCommission | decimal(18,6) | YES | Full commission realized on closed positions. "Full" = accounting/revenue commission. For leveraged positions, FullCommission > Commission. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 38 | CommissionOnOpen | decimal(18,6) | YES | Commission charged at the time of position opening for positions opened on this date. From `Dim_Position.Commission` for OpenDuringNotClosed and OpenDuringClosedDuring types. Zero for positions opened before this date. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 39 | FullCommissionOnOpen | decimal(18,6) | YES | Full (accounting) commission charged at open for positions opened today. Parallel to CommissionOnOpen but using FullCommission scale. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 40 | CommissionCloseAdjustment | decimal(18,6) | YES | Adjustment to commission at position close: `CommissionOnClose - CommissionByUnits`. Captures the difference between the actual close commission and the original by-units commission. Used in partially-closed position accounting. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 41 | FullCommissionCloseAdjustment | decimal(18,6) | YES | Full commission close adjustment: `FullCommissionOnClose - FullCommissionByUnits`. Parallel to CommissionCloseAdjustment using FullCommission scale. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 42 | TotalCommission | decimal(18,6) | YES | `RealizedCommission + UnrealizedCommissionChange`. Total daily commission in standard (customer-facing) scale. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 43 | TotalFullCommission | decimal(18,6) | YES | `RealizedFullCommission + UnrealizedFullCommissionChange`. Total daily full (accounting/revenue) commission. eToro's primary revenue metric from position activity. USD. (Tier 2 - SP_Client_Balance_Breakdown) |
| 44 | TotalZero | decimal(18,6) | YES | Reconciliation metric: `UnrealizedFullCommissionChange + UnrealizedPnLChange + RealizedFullCommission + RealizedPnL`. Should approximately equal zero over time as revenue (commission) offsets customer PnL. Non-zero values indicate timing differences. Not a PnL metric. (Tier 2 - SP_Client_Balance_Breakdown) |
| 45 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was written. Set to `GETDATE()` on insert. (Tier 5 - propagation) |
| 46 | TanganyStatus | varchar(20) | YES | Customer's Tangany digital wallet status, sourced from `BI_DB_Client_Balance_CID_Level_New` (MAX per CID per day). Values: NULL (88.7% — no Tangany), "Inactive" (6.2%), "MicaCustomer" (2.9%), "Internal" (1.1%), "Customer" (0.8%), "ConsentCustomer" (0.04%), "Pending" (0.0001%). Added 2024-02-08 (Adi Meidan). (Tier 2 - SP_Client_Balance_Breakdown) |
| 47 | IsDLTUser | int | YES | 1 if the customer uses the DLT (Distributed Ledger Technology) platform (`DltStatusID=4` in Fact_SnapshotCustomer). Sourced via `#realTanganystatus` from `BI_DB_Client_Balance_CID_Level_New`. Added 2024-07-30. (Tier 2 - SP_Client_Balance_Breakdown) |
| 48 | CommissionVersion | int | YES | Version of the commission calculation schema applied to the positions in this row. Value 2 = current commission model as of 2025-06. Used to distinguish historical (pre-restructuring) vs current commission calculations. (Tier 2 - SP_Client_Balance_Breakdown) |
| 49 | TicketFeeByPercentOnClose | money | YES | USD ticket fee charged as a percentage at position close for qualifying instruments/positions. Zero for standard-commission positions. Only populated for positions where `TicketFeeByPercentAction = 'Close'` via `Function_Revenue_TicketFeeByPercent`. Added 2025-06-02. Bugfix 2026-01-01: excluded when RegTransferDirection=-1. (Tier 2 - SP_Client_Balance_Breakdown) |
| 50 | IsSQF | int | YES | **`IsSQF` (SpotQuotedFuture flag)** — 1 = position holds a SpotQuotedFuture instrument (smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 otherwise. Source: `Function_Instrument_Snapshot_Enriched.IsSQF = 1` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. Added 2025-06-18. (Tier 5 — user expert correction 2026-05-14; previously mis-described as "Small Quantity Fee pricing model") |
| 51 | TicketFeeByPercentPositionType | varchar(100) | YES | Classification of the position's ticket-fee pricing: "New" (instrument uses percent-fee AND position opened after 2025-06-01 threshold), "Legacy" (instrument qualifies but position predates new model), "NotRelevantToTicketFeeByPercent" (standard commission — the vast majority). (Tier 2 - SP_Client_Balance_Breakdown) |
| 52 | TicketFeeByPercentOnOpen | decimal(38,18) | YES | USD ticket fee charged as a percentage at position open. Zero for standard-commission positions. Populated from `Function_Revenue_TicketFeeByPercent` where `TicketFeeByPercentAction='Open'`. Added 2025-09-14. Very high precision (38,18). (Tier 2 - SP_Client_Balance_Breakdown) |
| 53 | IsC2P | int | YES | 1 if the position is a C2P (Commission to Position) compensation position — identified from `External_Bronze_etoro_Trade_AdminPositionLog` with `CompensationReasonID=134`. These are admin-created positions used for compensation payouts. Added 2025-11-25. (Tier 2 - SP_Client_Balance_Breakdown) |


---

## 5. Lineage

### 5.1 Source → Target Key Mappings

| Synapse Column Group | Primary Source Object | Notes |
|---------------------|----------------------|-------|
| DateID, Date | ETL parameter (@Date) | Grain key; ETL loads one day per run |
| IsSettled, IsMirror | DWH_dbo.Dim_Position | With IsSettledIsMirror override for settlement-day edge cases |
| InstrumentID, InstrumentTypeID, InstrumentType | DWH_dbo.Dim_Instrument | Via position joins |
| IsLeverage, IsLeverageMoreThen20 | DWH_dbo.Dim_Position (Leverage) | Computed flags |
| IsAirDrop, SettlementTypeID, IsBuy | DWH_dbo.Dim_Position | Passthrough |
| Regulation, RegTransferDirection | DWH_dbo.Dim_Regulation + Fact_SnapshotCustomer | Dual rows for reg-transfer customers |
| IsCreditReportValidCB, IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | Daily snapshot (SCD2 via Dim_Range) |
| AccountStatusName | DWH_dbo.Dim_AccountStatus | Via FSC.AccountStatusID |
| AccountType | DWH_dbo.Dim_AccountType | Via FSC.AccountTypeID |
| Country | DWH_dbo.Dim_Country | Via FSC.CountryID |
| US_State | DWH_dbo.Dim_State_and_Province | Only for CountryID=219 (USA) via RegionID |
| Region | DWH_dbo.Dim_Country (MarketingRegionManualName) | Via FSC.CountryID |
| MiFiDCategorization | DWH_dbo.Dim_MifidCategorization | Via FSC.MifidCategorizationID |
| Club | DWH_dbo.Dim_PlayerLevel | Via FSC.PlayerLevelID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Via FSC.PlayerStatusID |
| Label | DWH_dbo.Dim_Label | Via FSC.LabelID |
| IsOutlier, Transition | BI_DB_dbo.BI_DB_Outliers_New | Outlier flag on @DateID |
| IsGermanBaFIN | ETL-computed | `HoldsCrypto=1 AND CountryID=79` |
| IsEtoroTradingCID | ETL-computed | Hardcoded 7-CID list |
| IsGlenEagleAccount | ETL-computed | Hardcoded CID=14155290 |
| UnrealizedPnLChange, RealizedPnL, TotalPnL | DWH_dbo.Fact_CustomerAction + BI_DB_PositionPnL + Dim_Position | 4-type position lifecycle decomposition |
| UnrealizedCommissionChange, RealizedCommission | DWH_dbo.Fact_CustomerAction | Commission event types 1-6, 28, 39, 40 |
| UnrealizedFullCommissionChange, RealizedFullCommission | DWH_dbo.Fact_CustomerAction | FullCommission parallel track |
| CommissionOnOpen, FullCommissionOnOpen | DWH_dbo.Dim_Position | For newly opened positions |
| CommissionCloseAdjustment, FullCommissionCloseAdjustment | DWH_dbo.Dim_Position | CommissionOnClose - CommissionByUnits |
| TotalCommission, TotalFullCommission, TotalZero | ETL-computed | Aggregated from above |
| UpdateDate | ETL-computed | GETDATE() on insert |
| TanganyStatus, IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | MAX per CID per day |
| CommissionVersion | DWH_dbo.Dim_Position | Via #finalPrepAll |
| TicketFeeByPercentOnClose, TicketFeeByPercentOnOpen | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Percent-fee model amounts |
| IsSQF | BI_DB_dbo.Function_Instrument_Snapshot_Enriched | Instrument-level SQF flag |
| TicketFeeByPercentPositionType | ETL-computed | New/Legacy/NotRelevant classification |
| IsC2P | BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | CompensationReasonID=134 |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction         (ActionTypeID 1-6,28,39,40; open/close events)
DWH_dbo.Dim_PositionChangeLog       (partial close log)
BI_DB_dbo.BI_DB_PositionPnL         (daily open position PnL snapshot)
DWH_dbo.Dim_Position                (position master attributes)
DWH_dbo.Dim_Instrument              (instrument type)
DWH_dbo.Fact_SnapshotCustomer       (customer attributes; SCD2 via Dim_Range)
DWH_dbo.Dim_Country/Regulation/Club etc.  (dimension lookups)
DWH_dbo.V_Liabilities               (crypto holders filter)
BI_DB_dbo.BI_DB_Outliers_New        (outlier flags)
BI_DB_dbo.Function_Revenue_TicketFeeByPercent  (new commission model)
BI_DB_dbo.Function_Instrument_Snapshot_Enriched  (instrument enrichment)
BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog  (C2P positions)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New  (Tangany/DLT status)
    ↓
SP_Client_Balance_Breakdown(@Date)
    → 20+ temp tables assembling 4 position types
    → Regulation transfer dual-row handling
    → Customer segment join (#withCIDData)
    → Final GROUP BY aggregation
    → DELETE FROM Client_Balance_Breakdown_Instrument_Level WHERE DateID = @DateID
    → INSERT INTO BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level
```

### 5.3 Unity Catalog Target

**UC Target**: _Not_Migrated — no Unity Catalog mapping found in the generic pipeline mapping.

---

## 6. Relationships

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata (type, name) |
| (positions) | DWH_dbo.Dim_Position | Position master data (IsBuy, Leverage, NetProfit, Commission) |
| (position events) | DWH_dbo.Fact_CustomerAction | Open/close events (ActionTypeID 1-6,28,39,40) |
| (open positions) | BI_DB_dbo.BI_DB_PositionPnL | Daily open position PnL snapshot |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name |
| Club | DWH_dbo.Dim_PlayerLevel | Tier name |
| Country | DWH_dbo.Dim_Country | Country/region |
| IsOutlier/Transition | BI_DB_dbo.BI_DB_Outliers_New | Outlier flags |
| TanganyStatus/IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Wallet status source |
| DateID | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Same date grain (CID-level counterpart) |
| (C2P) | BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | Admin compensation positions |

---

## 7. Sample Queries

### 7.1 Daily total commission revenue by regulation

```sql
SELECT
    DateID,
    Regulation,
    SUM(TotalFullCommission)       AS full_commission_usd,
    SUM(TotalCommission)           AS std_commission_usd,
    SUM(TotalPnL)                  AS total_pnl_usd
FROM [BI_DB_dbo].[Client_Balance_Breakdown_Instrument_Level]
WHERE DateID = 20260412
  AND RegTransferDirection = 1   -- exclude regulation-transfer reversal rows
GROUP BY DateID, Regulation
ORDER BY full_commission_usd DESC;
```

### 7.2 Daily PnL by instrument type (trend)

```sql
SELECT
    DateID,
    InstrumentType,
    SUM(RealizedPnL)           AS realized_pnl,
    SUM(UnrealizedPnLChange)   AS unrealized_change,
    SUM(TotalPnL)              AS total_pnl,
    SUM(TotalFullCommission)   AS revenue
FROM [BI_DB_dbo].[Client_Balance_Breakdown_Instrument_Level]
WHERE DateID >= 20260401
  AND RegTransferDirection = 1
GROUP BY DateID, InstrumentType
ORDER BY DateID DESC, total_pnl ASC;
```

### 7.3 Outlier impact on PnL

```sql
SELECT
    IsOutlier,
    Transition,
    SUM(TotalPnL)              AS total_pnl,
    SUM(TotalFullCommission)   AS full_commission,
    COUNT(*)                   AS row_count
FROM [BI_DB_dbo].[Client_Balance_Breakdown_Instrument_Level]
WHERE DateID = 20260412
  AND RegTransferDirection = 1
GROUP BY IsOutlier, Transition
ORDER BY IsOutlier DESC;
```

### 7.4 Ticket fee by percent revenue

```sql
SELECT
    DateID,
    TicketFeeByPercentPositionType,
    SUM(TicketFeeByPercentOnClose)  AS tfbp_close,
    SUM(TicketFeeByPercentOnOpen)   AS tfbp_open,
    COUNT(*)                         AS rows
FROM [BI_DB_dbo].[Client_Balance_Breakdown_Instrument_Level]
WHERE DateID >= 20260401
  AND RegTransferDirection = 1
  AND TicketFeeByPercentPositionType <> 'NotRelevantToTicketFeeByPercent'
GROUP BY DateID, TicketFeeByPercentPositionType
ORDER BY DateID DESC;
```

---

## 8. Atlassian / Open Questions

No Confluence pages found. Open questions:

- **`@DateNextID` bug**: Line 54 of the SP assigns `@DateNextID = CAST(CONVERT(VARCHAR(8), @DatePrev, 112) AS INT)` — it uses `@DatePrev` instead of `@DateNext`. This means `#pnlPosNext` (used to identify positions that remain open past today) uses yesterday's data. The impact on `OpenBeforeNotClosed` type classification needs verification.
- **CommissionVersion semantics**: What distinguishes CommissionVersion 1 vs 2? When did the version change?
- **SQF definition**: "Small Quantity Fee" — is this the correct expansion of SQF? What threshold defines a "small quantity"?
- **IsC2P (CompensationReasonID=134)**: What business event creates CompensationReasonID=134 C2P positions?
- **TanganyStatus and MICA**: "MicaCustomer" status appears in 2.9% of rows — this relates to the EU MICA regulation for crypto. Is there a separate MICA compliance workflow document?

---

*Generated: 2026-04-23 | Quality: 9.0/10 (****) | Phases: 11/14*
*Tiers: 52 T2, 0 T3, 0 T4, 1 T5 | Elements: 53/53, Logic: 10/10, Relationships: 9/10, Sources: 9/10*
*Object: BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level | Type: Table | Writer SP: SP_Client_Balance_Breakdown (P20)*
