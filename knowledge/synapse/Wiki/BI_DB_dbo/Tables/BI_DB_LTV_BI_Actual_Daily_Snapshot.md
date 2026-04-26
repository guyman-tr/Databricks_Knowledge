# BI_DB_LTV_BI_Actual_Daily_Snapshot

> Daily point-in-time archive of the customer LTV (Lifetime Value) model output. One row per depositor per snapshot date. Captures 8-year revenue predictions, behavior clusters, and acquisition channel at T-1 each day. CRITICAL: 70 of 86 DDL columns are always NULL — only 16 are actively populated by the current SP.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | HASH(CID) |
| **Index** | HEAP |
| **Row Count** | ~4.54B rows |
| **Snapshot Range** | 2023-10-22 to 2026-04-11 (865 distinct dates) |
| **Distinct CIDs** | ~5.84M |
| **Rows per Snapshot** | ~5.24M avg (one row per depositor in BI_DB_LTV_BI_Actual) |
| **Writer SP** | SP_D_LTV_BI_Actual_Snapshot |
| **Write Pattern** | DELETE WHERE SnapshotDate + INSERT (daily idempotent) |
| **SnapshotDate** | DATEADD(dd,-1,GETDATE()) — captures T-1 state |
| **Author** | Jan Iablunovskey (created 2023-09-07) |
| **Active Columns** | 16 of 86 DDL columns |
| **Inactive Columns** | 70 of 86 — always NULL (legacy DDL remnants) |
| **UC Status** | Not Migrated |

---

## Business Context

`BI_DB_LTV_BI_Actual_Daily_Snapshot` is the historical time series of the LTV model output. Each day, SP_D_LTV_BI_Actual_Snapshot reads the current state of `BI_DB_LTV_BI_Actual` (the live LTV output table) and appends a timestamped copy as a new SnapshotDate partition, enabling trend analysis of LTV predictions over time.

The table enables:
- **LTV trend analysis**: How does a cohort's predicted 8-year LTV change week over week?
- **Model drift tracking**: Did a model refresh on a given date shift LTV predictions significantly?
- **Retrospective segmentation**: What cluster/channel composition did the book look like on a given historical date?

**LTV model variants in this table** (all 8-year horizon):
- `Revenue8Y_LTV_New` — Base 8Y prediction (new methodology, 2023+)
- `Revenue8Y_LTV_NoExtreme_New` — Base 8Y excluding statistical outliers
- `LTV_8Y_GroupLevel` — LTV assigned at the group level (for thinly-traded customers, falls back to peer-group avg)
- `Revenue8Y_LTV_New_WO_Group_LTV` — Individual 8Y LTV without group-level assignment (0 where group LTV was applied)
- `Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV` — Same, without extremes
- `Revenue8Y_LTV_New_Group_LTV` — 8Y LTV with group-level supplement applied
- `Revenue8Y_LTV_NoExtreme_New_Group_LTV` — 8Y without extremes, with group supplement
- `Revenue_Change_Percentage_Fixed` — Fixed percentage adjustment applied to the base prediction (calibration factor)

**Important**: The upstream table `BI_DB_LTV_BI_Actual` is itself refreshed daily by `SP_LTV_BI_Actual` (P0). The snapshot SP runs at P20, after the upstream refresh. The `UpdateDate` column in the snapshot reflects when `BI_DB_LTV_BI_Actual` was last calculated, not when the snapshot was taken — use `Snapshot_UpdateDate` for the snapshot timestamp.

---

## Business Logic

### 2.1 Snapshot Pattern
SnapshotDate = DATEADD(dd,-1,GETDATE()) — always captures yesterday. When the SP runs on 2026-04-12, SnapshotDate = 2026-04-11. The snapshot is idempotent: DELETE WHERE SnapshotDate = @date ensures no duplicates if the SP re-runs.

### 2.2 LTV Group Level Assignment
`LTV_8Y_GroupLevel` applies when a customer has insufficient personal trading history for an individual LTV prediction. The model falls back to the average LTV of a peer group (segment/cohort). This value is typically larger than `Revenue8Y_LTV_New` for inactive/new customers because it reflects the group median, not a zero-history individual estimate.

Consumers should choose between:
- `Revenue8Y_LTV_New` — individual prediction only (may be low for inactive customers)
- `LTV_8Y_GroupLevel` — group-adjusted prediction (better for thin-history customers)
- `Revenue8Y_LTV_New_Group_LTV` — blended: individual where available, group supplement where not

### 2.3 Channel Join Behavior
Channel is sourced from `BI_DB_First5Actions` via LEFT JOIN. Customers not present in `BI_DB_First5Actions` (non-depositors, or edge cases) receive Channel = string `'NULL'` (not SQL NULL) due to `ISNULL(bdfa.Channel,'NULL')`. Consumers filtering for unknown acquisition should check `Channel = 'NULL'`, not `Channel IS NULL`.

### 2.4 Legacy Schema — 70 Inactive Columns
The DDL contains 86 columns but only 16 are written by the current SP. The remaining 70 were populated in earlier pipeline versions (pre-2023) and are commented out in the current SP. These columns — including all `Percent_*` projections, `Rev_*` realized revenue windows, `Seniority*`, `Revenue360days_LTV`, `Revenue3Y_LTV`, `Revenue8Y_LTV` (old methodology), and `Equity_tier` — are always NULL in live data. Do not query them expecting data.

---

## Column Elements

### Identity

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | CID | int | NO | Tier 1 | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | SnapshotDate | date | YES | Tier 2 | Snapshot date — DATEADD(dd,-1,GETDATE()) at SP execution. Always = yesterday. Partition key for point-in-time queries. DELETE+INSERT on this date makes each day idempotent. |

### ETL Control

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 26 | UpdateDate | datetime | NO | Tier 2 | Timestamp when BI_DB_LTV_BI_Actual last calculated this customer's LTV. Sourced from the upstream table — reflects the LTV model refresh time, not the snapshot time. |
| 78 | Snapshot_UpdateDate | datetime | YES | Tier 2 | Timestamp when SP_D_LTV_BI_Actual_Snapshot ran and inserted this row (GETDATE()). Use this to timestamp the snapshot event itself. |

### Marketing & Segmentation

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 5 | Channel | nvarchar(500) | NO | Tier 2 | Marketing acquisition channel from BI_DB_First5Actions. LEFT JOIN on CID; ISNULL(,'NULL') maps missing to string 'NULL'. Values: Direct (~35%), Affiliate (~20%), SEM (~14%), SEO (~13%), Friend Referral (~7%), Mobile Acquisition (~7%), etc. |
| 81 | First_Month_Equity_Tier | int | YES | Tier 2 | Customer's equity tier during their first funded month. Integer tier level (1=lowest). Frozen at first-month value for cohort stability. Observed: 1 dominant. |
| 82 | First_Month_Cluster | varchar(100) | YES | Tier 2 | Customer behavior cluster assigned in first funded month. Frozen at first-month value. Values observed: No Cluster - Active, Crypto, Equities Investors, No Cluster - Inactive, Equities Crypto, Leveraged Traders, Equities Traders, Diversified Traders. |
| 83 | Currency | varchar(300) | YES | Tier 2 | Customer account currency classification. Values: 'Non_USD' (~67%), 'USD' (~32%), '' empty (~1%). Binary USD vs. non-USD flag — does not store actual currency code. |

### LTV Model Output

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 67 | Revenue8Y_LTV_New | money | YES | Tier 2 | Predicted 8-year cumulative broker revenue for this customer (new methodology, 2023+). Individual prediction only. May be low for inactive customers. |
| 68 | Revenue8Y_LTV_NoExtreme_New | money | YES | Tier 2 | 8-year LTV (new methodology) with statistical outliers excluded. Lower bound of prediction for conservative planning. |
| 73 | LTV_8Y_GroupLevel | money | YES | Tier 2 | 8-year LTV assigned at group/cohort level. Applied when individual history is thin. May exceed Revenue8Y_LTV_New for inactive customers because group median > individual estimate. |
| 79 | Revenue8Y_LTV_New_WO_Group_LTV | money | YES | Tier 2 | Individual 8Y LTV without group-level supplement. Zero where group-level assignment was applied; otherwise equals Revenue8Y_LTV_New. Use for pure individual-model analysis. |
| 80 | Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | money | YES | Tier 2 | Individual 8Y LTV without extremes and without group supplement. Most conservative individual prediction. |
| 84 | Revenue_Change_Percentage_Fixed | float | YES | Tier 2 | Fixed calibration multiplier applied to base LTV prediction. Adjusts for known revenue projection bias. Observed range: small positive float (~0.02–0.05 in sample). |
| 85 | Revenue8Y_LTV_New_Group_LTV | money | YES | Tier 2 | Blended 8Y LTV: individual prediction where history is sufficient; group-level supplement applied otherwise. Recommended for most downstream use cases. |
| 86 | Revenue8Y_LTV_NoExtreme_New_Group_LTV | money | YES | Tier 2 | Blended 8Y LTV without outliers. Conservative version of Revenue8Y_LTV_New_Group_LTV. |

### Legacy / Inactive Columns (always NULL)

> **All 70 columns below are always NULL in live data.** They are defined in the DDL but commented out in SP_D_LTV_BI_Actual_Snapshot. Do not use for analysis.

| Columns | Type Group | Legacy Purpose |
|---------|------------|----------------|
| NewMarketingRegion, IsEuropeanCountry | Geography flags | Superseded by BI_DB_First5Actions direct join |
| FirstAction, FirstAction_Detailed, FirstDepositDate, DaysFromDeposit | Onboarding | Customer first-action profile (moved to BI_DB_First5Actions) |
| Rev_14d, Rev_30d, Rev_60d, Rev_90d, Rev_120d, Rev_150d, Rev_180d | Revenue windows | Realized revenue at D+14 through D+180 post-FTD |
| Seniority, Seniority_Active_Month, Seniority_ACC_Revenue_Total | Tenure | Customer lifecycle metrics (never populated in snapshot) |
| Revenue180days_LTV, Revenue360days_LTV, Revenue3Y_LTV | Legacy LTV | Shorter-horizon LTV predictions (old methodology) |
| Revenue8Y_LTV, Revenue8Y_LTV_NoExtreme | Old LTV | 8Y predictions from pre-2023 methodology |
| Extreme_CID | Outlier flag | 1 if customer is a statistical outlier |
| Percent_Revenue14days … Percent8Y_from3Y (30 cols) | Projection ratios | % of predicted revenue realized at each window; multiplier series for extending short-term actuals to long-term predictions |
| Equity_tier, ClusterDetail, DaysFromAction, FirstTimeFunded | Current-state flags | Current (non-first-month) segmentation fields |
| Revenue8Y_LTV_New_BI, Revenue8Y_LTV_NoExtreme_New_BI, Revenue360days_LTV_BI, Revenue3Y_LTV_BI | BI variants | BI-team-adjusted LTV outputs (never populated in snapshot) |

---

## Data Profile

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | ~4.54B | MCP COUNT_BIG 2026-04-22 |
| Snapshot date range | 2023-10-22 to 2026-04-11 | MCP MIN/MAX |
| Distinct snapshots | 865 | MCP COUNT DISTINCT |
| Distinct CIDs | ~5.84M | MCP COUNT DISTINCT |
| Rows per snapshot (avg) | ~5.24M | Derived |
| Channel: Direct | ~35% (2.09M/snapshot) | MCP 2026-04-11 sample |
| Channel: Affiliate | ~20% (1.20M/snapshot) | MCP 2026-04-11 sample |
| Channel: SEM | ~14% (811K/snapshot) | MCP 2026-04-11 sample |
| Channel: SEO | ~13% (791K/snapshot) | MCP 2026-04-11 sample |
| First_Month_Cluster top | No Cluster - Active (19%), Crypto (18%) | MCP 2026-04-11 sample |
| Currency: Non_USD | ~67% | MCP 2026-04-11 sample |
| Currency: USD | ~32% | MCP 2026-04-11 sample |

---

## Gotchas

1. **70 inactive columns are always NULL** — The DDL contains 86 columns; 70 are never populated. Queries joining or filtering on `NewMarketingRegion`, `Rev_*`, `Percent_*`, `Seniority`, `Revenue360days_LTV`, `Revenue3Y_LTV`, `Revenue8Y_LTV`, `Equity_tier`, `ClusterDetail`, etc. will always return NULL. These are schema artifacts from the 2019–2022 pipeline version.

2. **Channel = 'NULL' (string) not NULL** — The SP uses `ISNULL(bdfa.Channel,'NULL')`. Customers not in BI_DB_First5Actions get the literal string `'NULL'`, not a SQL NULL. Filter `Channel = 'NULL'` to find them; `Channel IS NULL` returns zero rows.

3. **UpdateDate ≠ SnapshotDate** — `UpdateDate` is when BI_DB_LTV_BI_Actual was last recalculated (could be days earlier if the LTV model hasn't refreshed for a specific CID). `Snapshot_UpdateDate` is when the snapshot SP ran. Use `SnapshotDate` as the partition key, not `UpdateDate`.

4. **LTV_8Y_GroupLevel vs Revenue8Y_LTV_New** — LTV_8Y_GroupLevel can be significantly higher than Revenue8Y_LTV_New for inactive customers because it reflects a group median. Do not treat LTV_8Y_GroupLevel as an upper-bound estimate of individual potential.

5. **Revenue8Y_LTV_New_WO_Group_LTV = 0 for group-assigned customers** — Where the group-level LTV was applied, the individual component (`WO_Group_LTV` variants) is set to 0, not NULL. Sum-aggregations over this column undercount unless you use the `Group_LTV` blended variants.

6. **4.5B row scale** — Queries without SnapshotDate filters will scan all 865 partitions. Always filter by SnapshotDate. The HEAP index means there is no clustered index to leverage; full scans are expensive at this scale.

---

## Related Objects

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual | Upstream source — current LTV model output (refreshed by SP_LTV_BI_Actual P0) |
| BI_DB_dbo.BI_DB_First5Actions | Channel dimension source (LEFT JOIN on CID) |
| BI_DB_dbo.SP_D_LTV_BI_Actual_Snapshot | Writer SP (SB_Daily, P20) |
| BI_DB_dbo.SP_LTV_BI_Actual | Prerequisite SP that refreshes BI_DB_LTV_BI_Actual (P0) |
