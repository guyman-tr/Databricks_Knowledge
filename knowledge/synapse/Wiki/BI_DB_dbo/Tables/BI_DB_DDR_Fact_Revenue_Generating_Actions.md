# BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

> DDR framework fact table listing **revenue-generating actions** at a granular grain: commissions (full vs internal), overnight-style fees (rollover, dividends, SDRT, ticket fees), admin and spot-adjustment fees, cashout/conversion/dormant/interest fees, share lending, crypto-to-fiat, staking (lagged), and options platform revenue — each row is an aggregated slice by customer, date, metric, and a set of trading/context flags.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — daily, multi-metric) |
| **Production Source** | Composed in Synapse from `BI_DB_dbo.Function_Revenue_*` TVFs, dimensions, external parquet, `V_C2P_Positions`, `Dim_Revenue_Metrics` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + multi-step `INSERT`; separate passes for options (`RevenueMetricID = 18`) and staking (month window, `RevenueMetricID = 12`) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_Revenue_Generating_Actions` is the **primary granular revenue fact** for the DDR (Data Delivery & Reporting) analytics layer. It unifies many revenue streams that originate from different operational and finance pipelines into one query-friendly table keyed by `RealCID`, `DateID`, and `Metric`.

Each row represents a **pre-aggregated slice** of revenue (and related transaction counts) for a specific **metric name** (`Metric`), with optional **action type** (`ActionTypeID` / `ActionType`) and **instrument** context (`InstrumentTypeID`, settlement, leverage, futures, copy, margin, SQF, C2P, IBAN, recurring, airdrop).

`IncludedInTotalRevenue` indicates whether a row should roll into **headline total revenue**; the load joins `BI_DB_dbo.Dim_Revenue_Metrics` on `Metric` so dictionary rules apply (SDRT is forced to excluded in post-processing). `CountAsActiveTrade` marks slices that count as **active trading** for KPIs (notably full commission rows for certain action types when not airdrop).

`RevenueMetricID` and `RevenueMetricCategoryID` support **ID-based filtering** instead of free-text `Metric` alone.

Special behaviors (from SP comments and logic):
- **Options** data is loaded in a **second pass** (all-time function range) because daily runs may not have options ready in time.
- **Staking** uses a **month-to-date delete/re-insert** with a **one-month lag** on recognition to handle retroactive source changes.

Author: Guy Manova (2024-07-02); extensive change history in `SP_DDR_Fact_Revenue_Generating_Actions`.

---

## 2. Business Logic

### 2.1 Metric and revenue classification

**What**: Each `Metric` value corresponds to a revenue line (e.g. `FullCommission`, `RollOverFee`, `StakingLagOneMonth`, `Options_PFOF`).

**Columns**: `Metric`, `Amount`, `CountTransactions`, `IncludedInTotalRevenue`, `RevenueMetricID`, `RevenueMetricCategoryID`

**Rules**:
- `IncludedInTotalRevenue` on insert comes from `Dim_Revenue_Metrics` (`drm.IncludedInTotalRevenue`) joined on `Metric`; SDRT rows are additionally updated to `0` in the SP.
- Staking and options rows carry **hardcoded** metric IDs in their dedicated branches (e.g. staking `RevenueMetricID = 12`, options `18`).

### 2.2 Commissions and active trade

**What**: Full commission vs internal commission split; active-trade flag for qualifying action types.

**Columns**: `ActionTypeID`, `ActionType`, `Metric` (`FullCommission` / `Commission`), `CountAsActiveTrade`, `IsAirDrop`

**Rules**:
- `CountAsActiveTrade` is set to `1` for `FullCommission`/`Commission` when `ActionTypeID` is in `(1, 39)` and `IsAirDrop` is not set — per `#revenue` grouping logic in the SP.

### 2.3 Context flags (copy, leverage, product, funding)

**What**: Dimensions describing how the revenue-related position or transaction should be segmented.

**Columns**: `IsCopy`, `IsBuy`, `IsLeveraged`, `IsFuture`, `IsCopyFund`, `IsOpenedFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsAirDrop`, `IsSQF`, `IsMarginTrade`, `IsC2P`

**Rules**:
- **C2P** (Copy to Portfolio): derived from `V_C2P_Positions` for applicable fee slices.
- **IBAN** flags: positions matched to external parquet lists joined through `Dim_Position` dates.
- **Recurring**: match to recurring-investment positions parquet.
- **Sentinel -1**: nullable dimensions are coerced to `-1` on insert for lake merge key stability (per SP history).

### 2.4 Multi-pass loads (options, staking)

**What**: Rows are not only inserted for `@dateID` in one shot.

**Columns**: `DateID`, `Date`, `RevenueMetricID`

**Rules**:
- Options: `DELETE` all `RevenueMetricID = 18` then `INSERT` from `Function_Revenue_OptionsPlatform` (wide date range).
- Staking: `DELETE` for `Date` in month of `@date` where `RevenueMetricID = 12`, then `INSERT` from lagged staking function — supports **retroactive** staking corrections.

---

## 3. Query Advisory

### 3.1 Synapse distribution and columnstore

**HASH(RealCID)**: Co-locates rows for the same customer — efficient for **customer-scoped** aggregates and joins to `Dim_Customer` on `RealCID`.

**CLUSTERED COLUMNSTORE**: Favor **analytics scans** filtered by `DateID` and selective dimensions; avoid `SELECT *` without filters on large ranges.

### 3.1b UC (Databricks) storage and partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID | Customer attributes |
| DWH_dbo.Dim_Date | ON DateID | Calendar |
| BI_DB_dbo.Dim_Revenue_Metrics | ON Metric or RevenueMetricID | Metric labels and categories |
| DWH_dbo.Dim_InstrumentType | ON InstrumentTypeID | Instrument type name (when populated) |

### 3.3 Gotchas

- **Grain is not “one row per trade”** — rows are **pre-grouped** in the SP; use `Metric` + flags to interpret the slice.
- **Metric text vs IDs**: Prefer `RevenueMetricID` for stable joins when populated; some rows may rely on `Metric` alone.
- **Options timing**: Options metrics may appear **outside** the same-day mental model — second-pass load uses an all-time function window.
- **Staking**: Month-level delete/re-insert can **rewrite history** in the month for `RevenueMetricID = 12`.
- **IncludedInTotalRevenue** for SDRT: enforced to **0** in SP even if upstream flags drifted historically.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Calendar key YYYYMMDD for the fact row. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 2 | Date | date | NULL | Calendar date; main load uses `@date`; staking converts from DateID. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 3 | RealCID | int | NULL | Real customer ID. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 4 | ActionTypeID | int | NULL | Action type when present; coerced to -1 when NULL on insert. May be NULL for some fee-only metrics. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 5 | ActionType | varchar(50) | NULL | Human-readable action / fee bucket name from dimension or literal. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 6 | InstrumentTypeID | int | NULL | Instrument type dimension key; -1 when unknown. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 7 | IsSettled | int | NULL | Settlement flag from source functions; -1 sentinel when NULL. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 8 | IsCopy | int | NULL | Copy-trade (mirror) context; -1 sentinel when NULL. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 9 | Metric | varchar(50) | NULL | Revenue line identifier — joins to `Dim_Revenue_Metrics.Metric`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 10 | Amount | decimal(16,6) | NULL | Revenue amount for the slice (currency as defined in source functions — typically USD for DDR). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 11 | CountTransactions | int | NULL | Transaction count for the slice; coerced toward 0 when NULL. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 12 | IncludedInTotalRevenue | int | NULL | 1/0 flag — from `Dim_Revenue_Metrics` on insert; SDRT forced 0 in SP. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 13 | CountAsActiveTrade | int | NULL | 1 if slice counts toward active-trade KPIs; 0 otherwise. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 14 | UpdateDate | datetime | NULL | Load timestamp `GETDATE()`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 15 | IsBuy | int | NULL | Direction / buy-side heuristic; -1 sentinel; dividend rows updated by sign of Amount. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 16 | IsLeveraged | int | NULL | 1 if leverage > 1 in source; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 17 | IsFuture | int | NULL | Futures product flag; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 18 | IsCopyFund | int | NULL | CopyFund position flag from `BI_DB_CopyFund_Positions`; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 19 | IsOpenedFromIBAN | int | NULL | 1 if position opened via IBAN funding path; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 20 | IsClosedToIBAN | int | NULL | 1 if position closed to IBAN; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 21 | IsRecurring | int | NULL | Recurring-investment position; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 22 | IsAirDrop | int | NULL | Crypto airdrop context; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 23 | IsSQF | int | NULL | Spot Quoted Futures flag; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 24 | RevenueMetricID | int | NULL | Foreign key to revenue metrics dictionary (`Dim_Revenue_Metrics`). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 25 | RevenueMetricCategoryID | int | NULL | Category grouping for revenue metrics. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 26 | IsMarginTrade | int | NULL | Margin trading flag; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 27 | IsC2P | int | NULL | Copy to Portfolio flag from `V_C2P_Positions`; -1 sentinel. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |

---

## 5. Lineage

### 5.1 Pipeline

```
SP_DDR_Fact_Revenue_Generating_Actions(@date)
  → DELETE + INSERT (primary #revenue + Dim_Revenue_Metrics)
  → DELETE RevenueMetricID=18 + INSERT options (#optionsalltime)
  → DELETE staking MTD + INSERT #staking
```

### 5.2 Key source tables

| Source | Role |
|--------|------|
| BI_DB_dbo.Function_Revenue_* (many TVFs) | Amounts and attributes per revenue family |
| BI_DB_dbo.Dim_Revenue_Metrics | IncludedInTotalRevenue, RevenueMetricID/Category by Metric |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | RealCID | Customer |
| DWH_dbo.Dim_Date | DateID | Calendar |
| BI_DB_dbo.Dim_Revenue_Metrics | Metric / RevenueMetricID | Metric dictionary |

### 6.2 Referenced By (other objects point to this)

| Source Object | Description |
|--------------|-------------|
| BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | View — DDR revenue breakdown |
| BI_DB_dbo.Function_Revenue_Total | Function — totals from this fact |
| BI_DB_dbo.SP_RevenueForum | Reporting |

---

*Generated: 2026-03-23 | Object: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions | Writer: SP_DDR_Fact_Revenue_Generating_Actions*
