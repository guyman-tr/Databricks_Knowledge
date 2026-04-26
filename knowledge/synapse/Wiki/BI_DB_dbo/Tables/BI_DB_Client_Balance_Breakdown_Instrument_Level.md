# BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

## 1. Overview

Daily instrument-level aggregation of PnL and commission metrics across all eToro clients. Groups client positions by instrument, regulation, and a comprehensive set of customer/position dimension attributes to provide a multi-dimensional view of daily P&L contribution.

**Primary use cases:**
- IFRS 15 revenue recognition balance calculations
- Finance audit auxiliary datapoints (EY audit, internal audit)
- CMR (Commission & Revenue) automation zero-reconciliation by instrument
- Multi-dimensional PnL slicing by instrument type, regulation, club tier, country, and customer classification

**Writer:** `BI_DB_dbo.SP_Client_Balance_Breakdown` (Author: Guy Manova, 2023-04-20; daily delete-insert)
**Grain:** One row per {DateID × InstrumentID × Regulation × RegTransferDirection × all dimension flag combination}. Metric columns are SUM aggregates over all matching CID-position records within that group.

> ⚠️ **CRITICAL — Regulation Transfer Dual-Row Rule:** On days when a client changes regulation, **two rows** exist for that CID × InstrumentID combination — one with `RegTransferDirection = 1` (receiving new regulation, gets all PnL/commission) and one with `RegTransferDirection = -1` (sending old regulation, carries reversals). **NEVER GROUP BY CID AND Regulation together.** Use either CID alone or Regulation alone when aggregating.

---

## 2. Table Metadata

| Property | Value |
|----------|-------|
| Schema | `BI_DB_dbo` |
| Table | `Client_Balance_Breakdown_Instrument_Level` |
| Distribution | `ROUND_ROBIN` |
| Index | `CLUSTERED COLUMNSTORE INDEX` |
| Columns | 55 |
| Row count (2026-04-12) | ~4.94M rows/day |
| Date range | 2023-01-01 → present (1,198 days as of 2026-04-12) |
| Estimated total rows | ~4.82B |
| OpsDB priority | 20 (third wave) |
| Frequency | `SB_Daily` |
| ProcessType | 3 (SQL & TIME) |

---

## 3. Column Reference

### 3.1 Date & ETL Metadata

| Column | Type | Description |
|--------|------|-------------|
| `DateID` | int | ETL partition column: year-month-day (YYYYMMDD format) (Tier 1 — ETL infrastructure) |
| `Date` | date | Full date value corresponding to DateID (Tier 2 — SP_Client_Balance_Breakdown) |
| `UpdateDate` | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline (Tier 1 — ETL metadata) |

### 3.2 Position Classification Flags

| Column | Type | Description |
|--------|------|-------------|
| `IsSettled` | int | 1 = settled position (crypto/real stocks on custody), 0 = CFD. Priority logic: close-action value overrides open-action value, which overrides HODL value. Sourced from `DWH_dbo.Fact_CustomerAction.IsSettled` (Tier 2 — SP_Client_Balance_Breakdown) |
| `IsMirror` | int | 1 = CopyTrader mirror position (CID is copying another trader), 0 = direct. Derived as `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` with same priority as IsSettled (Tier 2 — SP_Client_Balance_Breakdown) |
| `IsLeverage` | int | 1 = leveraged position (Leverage > 1), 0 = non-leveraged. Sourced from `Fact_CustomerAction.Leverage` (Tier 2 — SP_Client_Balance_Breakdown) |
| `IsLeverageMoreThen20` | int | 1 = high-leverage position (Leverage > 20), 0 otherwise. Regulatory significance for ESMA leverage caps (Tier 2 — SP_Client_Balance_Breakdown) |
| `IsAirDrop` | int | 1 = crypto airdrop position, 0 otherwise. Sourced from `DWH_dbo.Dim_Position.IsAirDrop` (Tier 2 — SP_Client_Balance_Breakdown) |
| `IsBuy` | int | 1 = long position, 0 = short. Sourced from `DWH_dbo.Dim_Position.IsBuy` (Tier 2 — SP_Client_Balance_Breakdown) |
| `SettlementTypeID` | int | Settlement type foreign key (references `Dim_SettlementType`). Sourced from `Fact_CustomerAction.SettlementTypeID` or `Dim_Position.SettlementTypeID` (Tier 2 — SP_Client_Balance_Breakdown) |

### 3.3 Instrument Dimensions

| Column | Type | Description |
|--------|------|-------------|
| `InstrumentID` | int | Foreign key to `DWH_dbo.Dim_Instrument`. Identifies the traded instrument (Tier 2 — DWH_dbo.Dim_Instrument via SP_Client_Balance_Breakdown) |
| `InstrumentTypeID` | int | Foreign key to `DWH_dbo.Dim_InstrumentType`. Numeric ID corresponding to InstrumentType (Tier 2 — DWH_dbo.Dim_Instrument) |
| `InstrumentType` | varchar(50) | Denormalized instrument category. Values: `Stocks` (78%), `ETF` (11%), `Crypto Currencies` (9%), `Commodities` (<1%), `Indices` (<1%), `Currencies` (<1%) — distribution as of 2026-04-12 (Tier 2 — DWH_dbo.Dim_Instrument) |

### 3.4 Regulation & Transfer Direction

| Column | Type | Description |
|--------|------|-------------|
| `Regulation` | varchar(50) | Regulatory jurisdiction assigned to the CID on this date. 15 observed values: CySEC (59%), FCA (20%), FSA Seychelles (13%), ASIC & GAML (3%), FSRA (2%), FinCEN+FINRA (2%), BVI, ASIC, FinCEN, MAS, eToroUS, NYDFS+FINRA, NFA, None, FINRAONLY. Sourced from `DWH_dbo.Dim_Regulation.Name` (Tier 2 — SP_Client_Balance_Breakdown) |
| `RegTransferDirection` | int | Regulation-transfer attribution direction. `1` = normal (all PnL/commission attributed to this regulation, 99.997% of rows). `-1` = sending direction on regulation-transfer days (carries PnL/commission reversals to zero-out the old regulation's attribution). **NEVER GROUP BY CID AND Regulation simultaneously.** (Tier 2 — SP_Client_Balance_Breakdown) |

### 3.5 Customer Validity & Classification Flags

| Column | Type | Description |
|--------|------|-------------|
| `IsCreditReportValidCB` | int | 1 = client has a valid credit balance report on this date, 0 otherwise. Sourced from `DWH_dbo.Fact_SalesCustomer.IsCreditReportValidCB` (Tier 2 — DWH_dbo.Fact_SalesCustomer) |
| `IsValidCustomer` | int | 1 = client is considered a valid (trading-active) customer on this date, 0 otherwise. Sourced from `DWH_dbo.Fact_SalesCustomer.IsValidCustomer` (Tier 2 — DWH_dbo.Fact_SalesCustomer) |
| `IsOutlier` | int | 1 = client flagged as an outlier (excluded from standard cohort analytics), 0 otherwise. Sourced from `DWH_dbo.Fact_SalesCustomer.IsOutlier` (Tier 2 — DWH_dbo.Fact_SalesCustomer) |
| `IsGermanBaFIN` | int | 1 = client subject to German BaFin regulatory requirements, 0 otherwise (Tier 2 — DWH_dbo.Fact_SalesCustomer) |
| `IsEtoroTradingCID` | int | 1 = eToro proprietary/internal trading account, 0 = regular client (Tier 2 — DWH_dbo.Fact_SalesCustomer) |
| `IsGlenEagleAccount` | int | 1 = Glen Eagle (acquired entity) account, 0 otherwise (Tier 2 — DWH_dbo.Fact_SalesCustomer) |

### 3.6 Customer Segmentation Dimensions (all resolved from DWH dimensions via FactSalesCustomer)

| Column | Type | Description |
|--------|------|-------------|
| `AccountStatusName` | varchar(50) | Client account status from `DWH_dbo.Dim_AccountStatus`. E.g., 'Open', 'Suspended', 'Closed', 'Prospect' (Tier 2 — DWH_dbo.Dim_AccountStatus) |
| `AccountType` | varchar(50) | Account type from `DWH_dbo.Dim_AccountType`. E.g., 'Private', 'Corporate', 'Joint' (Tier 2 — DWH_dbo.Dim_AccountType) |
| `Country` | varchar(50) | Client's registered country name from `DWH_dbo.Dim_Country` (Tier 2 — DWH_dbo.Dim_Country) |
| `US_State` | varchar(50) | US state abbreviation from `DWH_dbo.Dim_State_and_Province` for US clients only (CountryID=219). NULL for all non-US clients (Tier 2 — DWH_dbo.Dim_State_and_Province) |
| `Region` | varchar(50) | Marketing region name from `DWH_dbo.Dim_Country.MarketingRegionManualName`. Manually assigned regional grouping (e.g., 'CEE', 'LATAM', 'MENA') (Tier 2 — DWH_dbo.Dim_Country) |
| `MiFiDCategorization` | varchar(50) | MiFID II client categorization from `DWH_dbo.Dim_MifidCategorization`. E.g., 'Retail', 'Retail Pending', 'Professional', 'Elective Professional' (Tier 2 — DWH_dbo.Dim_MifidCategorization) |
| `Club` | varchar(50) | CopyTrader tier (player level) from `DWH_dbo.Dim_PlayerLevel`. E.g., 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Titanium' (Tier 2 — DWH_dbo.Dim_PlayerLevel) |
| `PlayerStatus` | varchar(50) | Client player status from `DWH_dbo.Dim_PlayerStatus`. E.g., 'Normal', 'Popular Investor', 'Champion' (Tier 2 — DWH_dbo.Dim_PlayerStatus) |
| `Label` | varchar(50) | Client brand label from `DWH_dbo.Dim_Label`. E.g., 'eToro' (Tier 2 — DWH_dbo.Dim_Label) |
| `Transition` | varchar(50) | Regulation migration transition status from `DWH_dbo.Fact_SalesCustomer.Transition`. Always 'NoTransition' in current data — legacy field reserved for regulation migration events (Tier 2 — DWH_dbo.Fact_SalesCustomer) |

### 3.7 Tangany / DLT / Commission Version

| Column | Type | Description |
|--------|------|-------------|
| `TanganyStatus` | varchar(20) | Tangany crypto custody status (MiCA compliance). NULL for ~89% of clients (pre-MiCA or non-custody). Values: `Customer` (active custody), `ConsentCustomer` (consented), `MicaCustomer` (MiCA-onboarded), `Inactive` (custody inactive), `Internal` (eToro internal), `Pending`. Sourced via `MAX()` from `BI_DB_Client_Balance_CID_Level_New` for the same DateID (Tier 2 — BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New) |
| `IsDLTUser` | int | 1 = client uses DLT (blockchain/distributed ledger) settlement, 0 otherwise. Sourced from `BI_DB_Client_Balance_CID_Level_New.IsDLTUser` (Tier 2 — BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New) |
| `CommissionVersion` | int | Commission model version from `DWH_dbo.Dim_Position.CommissionVersion`. 1 = legacy model, 2 = new half/half model introduced 2025-06 for subsidiaries accounting under the TicketFeeByPercent change (Tier 2 — DWH_dbo.Dim_Position) |

### 3.8 Ticket Fee by Percent Columns

| Column | Type | Description |
|--------|------|-------------|
| `TicketFeeByPercentPositionType` | varchar(100) | Classifies position under the TicketFeeByPercent revenue model. `New` = instrument eligible AND position opened after TicketFeeByPercent launch (2025-06-01); `Legacy` = instrument eligible but position opened before launch; `NotRelevantToTicketFeeByPercent` = instrument not eligible. Derived from `Function_Instrument_Snapshot_Enriched` (eligibility) + `Function_Revenue_TicketFeeByPercent` (open date check) (Tier 2 — SP_Client_Balance_Breakdown) |
| `TicketFeeByPercentOnClose` | money | SUM of ticket fees (percentage-based commission) for positions closed on this date. Sourced from `Function_Revenue_TicketFeeByPercent(@DateID, @DateID, 0)` where Action='Close'. Zero for `RegTransferDirection = -1` rows (Tier 2 — BI_DB_dbo.Function_Revenue_TicketFeeByPercent) |
| `TicketFeeByPercentOnOpen` | decimal(38,18) | SUM of ticket fees for positions opened on this date. Sourced from `Function_Revenue_TicketFeeByPercent(@DateID, @DateID, 0)` where Action='Open' (Tier 2 — BI_DB_dbo.Function_Revenue_TicketFeeByPercent) |
| `IsSQF` | int | 1 = Sponsored/Qualified Flow instrument, 0 otherwise. Derived from `Function_Instrument_Snapshot_Enriched(@DateID).IsSQF = 1` joined to Dim_Position. Positions opened 2025-06-01 or later on SQF instruments (Tier 2 — BI_DB_dbo.Function_Instrument_Snapshot_Enriched) |
| `IsC2P` | int | 1 = Copy-to-Portfolio position (CompensationReasonID=134 in `External_Bronze_etoro_Trade_AdminPositionLog`), 0 otherwise (Tier 2 — BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog) |

### 3.9 PnL Metrics

All metrics are SUM aggregates over all positions matching the row's dimension group.

| Column | Type | Description |
|--------|------|-------------|
| `UnrealizedPnLChange` | decimal(18,6) | Daily change in unrealized PnL. Computation varies by position lifecycle type: **OpenBeforeNotClosed** (HODL) = `DailyPnL` (mark-to-market delta from `BI_DB_PositionPnL`); **OpenDuringNotClosed** = `NewUnrealizedPnL` (DailyPnL for new open); **OpenBeforeClosedDuring** = `-Prev_EOD_OpenPnl` (reversal of previous EOD unrealized); **OpenDuringClosedDuring** = 0 (same-day open+close, no unrealized exposure). For `RegTransferDirection=-1`: `-1 * Prev_EOD_OpenPnl` (Tier 2 — SP_Client_Balance_Breakdown) |
| `RealizedPnL` | decimal(18,6) | Realized PnL from closed positions on this date. Sourced from `DWH_dbo.Fact_CustomerAction.NetProfit` for close action types (4,5,6,28,40). Zero for `RegTransferDirection=-1` rows (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| `TotalPnL` | decimal(18,6) | `UnrealizedPnLChange + RealizedPnL`. Total P&L contribution (unrealized change plus realized proceeds) (Tier 2 — SP_Client_Balance_Breakdown) |

### 3.10 Commission Metrics

| Column | Type | Description |
|--------|------|-------------|
| `UnrealizedCommissionChange` | decimal(18,6) | Change in commission attribution for open positions. For new opens: `CommissionOnOpen`; for HODL positions crossing regulation: `CommissionTransfer`; for closed positions that were open before: `-CommissionOnClose + CommissionCloseAdjustment`. For `RegTransferDirection=-1`: `-CommissionTransfer` (reversal) (Tier 2 — SP_Client_Balance_Breakdown) |
| `RealizedCommission` | decimal(18,6) | Commission realized on closed positions. From `Fact_CustomerAction.CommissionOnClose` for close actions. Zero for `RegTransferDirection=-1` rows (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| `UnrealizedFullCommissionChange` | decimal(18,6) | Same as `UnrealizedCommissionChange` using FullCommission (includes spread-derived commission component, not just the visible commission) (Tier 2 — SP_Client_Balance_Breakdown) |
| `RealizedFullCommission` | decimal(18,6) | Same as `RealizedCommission` using `FullCommissionOnClose` (full commission including spread) (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| `CommissionOnOpen` | decimal(18,6) | Commission charged at position open from `Fact_CustomerAction.Commission` (ActionTypeID 1,2,3,39). Zero for pre-existing positions and `RegTransferDirection=-1` rows (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| `FullCommissionOnOpen` | decimal(18,6) | Full commission at position open (including spread component) from `Fact_CustomerAction.FullCommission` (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| `CommissionCloseAdjustment` | decimal(18,6) | Partial-close commission adjustment: `CommissionOnClose - CommissionByUnits`. Represents the non-unit-proportional component of close commission. Only non-zero for closed positions (Tier 2 — SP_Client_Balance_Breakdown) |
| `FullCommissionCloseAdjustment` | decimal(18,6) | Same as `CommissionCloseAdjustment` using FullCommission (Tier 2 — SP_Client_Balance_Breakdown) |
| `TotalCommission` | decimal(18,6) | `RealizedCommission + UnrealizedCommissionChange`. Total commission exposure for this group (Tier 2 — SP_Client_Balance_Breakdown) |
| `TotalFullCommission` | decimal(18,6) | `RealizedFullCommission + UnrealizedFullCommissionChange`. Full commission total (Tier 2 — SP_Client_Balance_Breakdown) |
| `TotalZero` | decimal(18,6) | Balance reconciliation metric: `UnrealizedFullCommissionChange + UnrealizedPnLChange + RealizedFullCommission + RealizedPnL`. Should net approximately zero when PnL and commission are correctly double-counted across the regulation-transfer dual-row mechanism. Consumed by `SP_CMR_Automation_Zero_By_Instrument` for daily balance checks (Tier 2 — SP_Client_Balance_Breakdown) |

---

## 4. Business Rules

### 4.1 Regulation Transfer Dual-Row Rule
On days when a CID changes regulation, **exactly two rows** exist for that CID × InstrumentID combination:
- `RegTransferDirection = 1`: The **receiving** regulation. Gets all PnL/commission attribution. Carries forward the full unrealized PnL of positions now under the new regulation.
- `RegTransferDirection = -1`: The **sending** regulation. All PnL/commission metrics are set to zero or reversed. Carries `-Prev_EOD_OpenPnl` as UnrealizedPnLChange and `-CommissionTransfer` as UnrealizedCommissionChange to cancel the old regulation's attribution.

**Rule:** NEVER GROUP BY CID AND Regulation simultaneously. Aggregate by either CID alone (ignores regulation breakdown) or by Regulation alone (sums the dual rows correctly into one regulation total).

### 4.2 TotalZero Reconciliation
`TotalZero = UnrealizedFullCommissionChange + UnrealizedPnLChange + RealizedFullCommission + RealizedPnL`

For a correctly processed day, this should net ~zero across the regulation-transfer population because the dual-row mechanism ensures that the "sending" row cancels what the "receiving" row attributes. Used by CMR automation zero-checks.

### 4.3 TicketFeeByPercentPositionType Classification
- **`New`**: Instrument is TicketFeeByPercent-eligible (from `Function_Instrument_Snapshot_Enriched`) AND the position was opened via a TicketFeeByPercent open event (from `Function_Revenue_TicketFeeByPercent`)
- **`Legacy`**: Instrument is eligible but position was opened before the TicketFeeByPercent launch (2025-06-01)
- **`NotRelevantToTicketFeeByPercent`**: Instrument is not eligible — most rows (91% as of 2026-04-12)

### 4.4 TanganyStatus Null Semantics
NULL TanganyStatus (~89% of rows) means the client is NOT in the Tangany crypto custody system — they are pre-MiCA or their crypto assets are not under Tangany custody. This is not a data quality issue; it is expected for the majority of the client population.

### 4.5 Position Lifecycle Types
The SP processes four mutually exclusive position lifecycle types per date:
1. **OpenBeforeClosedDuring**: Opened before @Date, closed on @Date (realizes PnL on close)
2. **OpenBeforeNotClosed**: Opened before @Date, still open (daily mark-to-market delta)
3. **OpenDuringNotClosed**: Opened on @Date, still open (new unrealized PnL)
4. **OpenDuringClosedDuring**: Opened and closed on @Date (same-day trade; zero unrealized)

---

## 5. Data Profile

| Dimension | Top Values (2026-04-12, 4.94M rows) |
|-----------|-------------------------------------|
| InstrumentType | Stocks 78%, ETF 11%, Crypto Currencies 9%, Commodities <1%, Indices <1%, Currencies <1% |
| Regulation | CySEC 59%, FCA 20%, FSA Seychelles 13%, ASIC & GAML 3%, FSRA 2%, FinCEN+FINRA 2%, +9 others |
| RegTransferDirection | 1: 4,936,343 rows (99.997%), -1: 142 rows (regulation-transfer events) |
| TicketFeeByPercentPositionType | NotRelevantToTicketFeeByPercent 91%, Legacy 6%, New 3% |
| TanganyStatus | NULL 89%, Inactive 6%, MicaCustomer 3%, Internal 1%, Customer <1%, ConsentCustomer <1%, Pending ~0 |
| Transition | NoTransition 100% (always) |

**NULL rates (2026-04-12):** InstrumentID 0%, Regulation 0%, Country 0%, Club 0%, TotalZero 0%, UnrealizedPnLChange 0%. TanganyStatus 89% NULL (by design — non-Tangany clients).

---

## 6. Lineage & Upstream Sources

See [`BI_DB_Client_Balance_Breakdown_Instrument_Level.lineage.md`](BI_DB_Client_Balance_Breakdown_Instrument_Level.lineage.md) for full column-level lineage.

**Primary upstream sources:**
- `DWH_dbo.Fact_CustomerAction` — PnL events and commission at position level
- `DWH_dbo.Dim_Position` — Position attributes (CommissionVersion, IsAirDrop, etc.)
- `DWH_dbo.Dim_Instrument` — Instrument type resolution
- `BI_DB_dbo.BI_DB_PositionPnL` — Daily unrealized PnL for HODL positions
- `DWH_dbo.Dim_Customer` + dimension tables — Customer segmentation attributes
- `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` — TanganyStatus, IsDLTUser snapshot

---

## 7. Downstream Consumers

| Consumer | Schema | Purpose |
|----------|--------|---------|
| `SP_IFRS_15_Balance` | BI_DB_dbo | IFRS 15 revenue recognition balance calculations |
| `SP_M_Finance_Audit_Auxillary_Datapoints` | BI_DB_dbo | Finance audit auxiliary data for auditor reporting |
| `SP_CMR_Automation_Zero_By_Instrument` | BI_DB_dbo | CMR daily zero-reconciliation check by instrument |
| `SP_CMR_Automation_Zero_By_Instrument_New` | BI_DB_dbo | CMR zero-reconciliation (updated version) |
| `SP_EY_Audit_Auditor_Unrealized_Calculations` | BI_DB_dbo | EY auditor unrealized PnL calculations |
| `SP_Client_Balance_Breakdown_Quick` | BI_DB_dbo | Quick-query variant for ad-hoc analysis |

---

## 8. Notes & Review Flags

- The `Transition` column is always `NoTransition` in current data. It was designed for regulation migration events but no such events have occurred since at least 2023-01-01. The field may be repurposed or populated during future regulation migrations.
- `US_State` is NULL for all non-US clients — this is expected and not a data quality issue.
- `CommissionVersion` = 2 was introduced in 2025-06 for subsidiary accounting under the half/half commission change. Version 1 = legacy model for pre-June 2025 positions.
- `TicketFeeByPercentOnOpen` uses `decimal(38,18)` precision (unlike `money` for OnClose) — a type inconsistency introduced by different change authors. Both represent fee amounts in USD.
- The `_Junk` table (`Client_Balance_Breakdown_Instrument_Level_Junk`) exists as a holding area and is NOT the documentation target.
- This table replaces the legacy pattern of `BI_DB_PositionPnL + Dim_Position` for detailed PnL/commission reporting (see SP header comment by Guy Manova, 2023-04-20).
