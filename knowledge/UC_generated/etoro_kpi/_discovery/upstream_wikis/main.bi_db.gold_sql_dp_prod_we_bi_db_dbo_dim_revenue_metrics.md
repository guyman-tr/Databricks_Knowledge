# BI_DB_dbo.Dim_Revenue_Metrics

> 18-row revenue-metric dimension that catalogs every fee/revenue type tracked in the eToro DDR pipeline and groups them into 5 categories: TradeTransactional, Overnight, MIMO, RevShare, Other. The `IncludedInTotalRevenue` boolean drives the canonical "Total Revenue" rollup — metrics with `IncludedInTotalRevenue = false` (e.g., raw `Commission` before discounts, `Dividends`, `SDRT`) are tracked but excluded from the published top-line total to avoid double-counting or non-revenue items.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Manually curated within DWH (no external upstream) |
| **Refresh** | Effectively static — only changes when a new fee type is added (last addition `Options_PFOF` on 2025-10-22) |
| **Row Count** | 18 |
| **Grain** | One row per revenue metric |
| | |
| **Synapse Distribution** | (small dim — typically REPLICATE) |
| **Synapse Index** | CLUSTERED on RevenueMetricID |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`Dim_Revenue_Metrics` is the canonical catalog of every revenue/fee component recognized in the eToro DDR (Daily Dashboard Report) framework. It serves two purposes:

1. **Decoder dimension** for joins from fact tables that store `RevenueMetricID` (one row per metric per CID per day) back to a human-readable name.
2. **Inclusion filter** — the `IncludedInTotalRevenue` boolean defines the canonical "Total Revenue" formula. Filtering with `WHERE IncludedInTotalRevenue = 1` gives the top-line revenue without double-counting components.

The 5 categories map cleanly to revenue domains documented in the `revenue-and-fees` skill:

| RevenueMetricCategory | Metrics | Notes |
|-----------------------|---------|-------|
| TradeTransactional | FullCommission, Commission, TicketFee, TicketFeeByPercent | Per-trade fees. `Commission` (before discounts) excluded from total; `FullCommission` (gross) included. |
| Overnight | RollOverFee, SpotPriceAdjustment, AdminFee | Holding-period fees on open positions. |
| MIMO | CashoutFeeExclRedeem, TransferCoinFee, ConversionFee, CryptoToFiatFee | Money-In-Money-Out fees on the DDR MIMO panel. |
| RevShare | StakingLagOneMonth, ShareLending | Revenue-share rewards earned by the customer (eToro keeps a portion). |
| Other | DormantFee, InterestFee, Dividends, SDRT, Options_PFOF | Catch-all. `Dividends` and `SDRT` excluded from total (they're pass-throughs / taxes). |

Two metrics are explicitly EXCLUDED from total revenue:
- `Commission` (id=2) — raw commission before discount; `FullCommission` (id=1) is the included version
- `Dividends` (id=16) — dividend pass-through, not eToro revenue
- `SDRT` (id=17) — Stamp Duty Reserve Tax, a UK tax, also a pass-through

---

## 2. Query Advisory

### 2.1 Common Patterns

| Question | Approach |
|----------|----------|
| Total revenue by day | `JOIN ... WHERE drm.IncludedInTotalRevenue = 1 GROUP BY day` |
| Revenue by category | `GROUP BY drm.RevenueMetricCategory` |
| MIMO fees only | `WHERE drm.RevenueMetricCategoryID = 3` |
| Decode MetricID | `LEFT JOIN Dim_Revenue_Metrics ON RevenueMetricID = drm.RevenueMetricID` |

### 2.2 Gotchas

- **`IncludedInTotalRevenue` is a bit, not int** — `WHERE IncludedInTotalRevenue = 1` (or `= TRUE` in UC).
- **`Commission` vs `FullCommission`**: never sum both — `Commission` is included inside `FullCommission`.
- **`Dividends` is a row but not revenue** — it tracks dividend payouts to customers (as fact) but is excluded from the total revenue sum.
- **Static dim**: row count grows by ~1/year as new fee types are launched. If a new metric appears in the fact table without a corresponding row here, it'll be unattributed.

---

## 3. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + UC sample (18 rows verified 2026-05-07) |
| ** | Tier 2 | Live data sample / category mapping |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Metric | nvarchar(200) | NO | Human-readable metric name. Examples: FullCommission, RollOverFee, CashoutFeeExclRedeem, ShareLending, DormantFee, Options_PFOF. The label used in DDR fact-table column names and Tableau views. (Tier 1 — UC sample) |
| 2 | IncludedInTotalRevenue | bit | NO | True if this metric contributes to the canonical "Total Revenue" rollup; False for raw/pass-through entries (`Commission`, `Dividends`, `SDRT`). Filter on this when computing top-line revenue to avoid double-counting. (Tier 1 — UC sample, 14 of 18 rows true) |
| 3 | RevenueMetricID | int | NO | Surrogate key. Stable integer 1-18 (with new entries appended). FK target from DDR fact tables when revenue is stored long-form. (Tier 1 — UC sample) |
| 4 | RevenueMetricCategoryID | int | NO | Category surrogate key 1-5. 1=TradeTransactional, 2=Overnight, 3=MIMO, 4=RevShare, 5=Other. (Tier 1 — UC sample) |
| 5 | RevenueMetricCategory | nvarchar(100) | NO | Category label (1:1 with RevenueMetricCategoryID). Used for high-level revenue rollups in the DDR. (Tier 1 — UC sample) |
| 6 | UpdateDate | datetime | YES | Timestamp of the most recent ETL touch. The 17 original metrics share `2025-07-30 09:16:17.703`; `Options_PFOF` was added later (`2025-10-22 12:50:09.737`). (Tier 1 — UC sample) |

---

## 4. Lineage

### 4.1 Production Source

No external system feeds this table — it's manually curated within DWH. New fee types are added by the BI/Finance team when a new revenue stream goes live.

### 4.2 Pipeline

```
DWH Synapse (manual curation) → BI_DB_dbo.Dim_Revenue_Metrics
                              ↓ Generic Pipeline (gold export)
       main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
```

---

## 5. Relationships

### 5.1 Referenced By

DDR fact tables and revenue rollup SPs that store revenue in long form (one row per CID per metric per day) join back to this dim on `RevenueMetricID`. Wide-form DDR tables (e.g., `BI_DB_DDR_Daily_Aggregated`) instead expose each metric as its own column — this dim is the inverse mapping.

The 5 metric categories align with:
- `revenue-and-fees` skill (super-domain doc)
- Per-fee `etoro_kpi_prep.v_revenue_*` view family in UC

---

## 6. Sample Queries

### 6.1 Inclusion split

```sql
SELECT IncludedInTotalRevenue, COUNT(*) AS metrics
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
GROUP BY IncludedInTotalRevenue
```

### 6.2 Total revenue formula (decode + filter)

```sql
SELECT drm.RevenueMetricCategory, SUM(f.Amount) AS revenue
FROM   <ddr_fact_long> f
JOIN   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics drm
  ON   f.RevenueMetricID = drm.RevenueMetricID
WHERE  drm.IncludedInTotalRevenue = TRUE
GROUP  BY drm.RevenueMetricCategory
```

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: DDL + UC sample (18 rows, 2026-05-07) + revenue-and-fees skill*
*Object: BI_DB_dbo.Dim_Revenue_Metrics | Type: Table | Production: in-warehouse curation*
