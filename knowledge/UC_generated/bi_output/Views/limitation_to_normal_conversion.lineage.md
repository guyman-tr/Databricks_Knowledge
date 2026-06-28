# Column Lineage: main.bi_output.limitation_to_normal_conversion

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.limitation_to_normal_conversion` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\limitation_to_normal_conversion.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\limitation_to_normal_conversion.json` (rows: 6, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
        │
        ▼
main.bi_output.limitation_to_normal_conversion   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Event_Month` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `unknown` | — | DATE_TRUNC('MONTH', Limited_Timestamp) AS Event_Month |
| 2 | `Limitation_Type` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Limitation_Type` | `passthrough` | — | Limitation_Type |
| 3 | `Total_Conversions` | `—` | `—` | `aggregate` | — | COUNT(*) AS Total_Conversions |
| 4 | `Avg_Hours_To_Normal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `aggregate` | — | AVG(TIMESTAMPDIFF(HOUR, Limited_Timestamp, First_Normal_Timestamp)) AS Avg_Hours_To_Normal /* Average time */ |
| 5 | `Avg_Days_To_Normal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `aggregate` | — | AVG(DATEDIFF(DAY, Limited_Timestamp, First_Normal_Timestamp)) AS Avg_Days_To_Normal |
| 6 | `Median_Hours_To_Normal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `aggregate` | — | PERCENTILE_APPROX(TIMESTAMPDIFF(HOUR, Limited_Timestamp, First_Normal_Timestamp), 0.5) AS Median_Hours_To_Normal /* Median time (Spark SQL)  |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **5**, WARN: **0**, ERROR: **0**, INFO: **1**  ✓

## Lost / added columns

- Computed/added columns vs primary: **4**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus AS dps ON fsc.PlayerStatusID = dps.PlayerStatusID
- `INNER JOIN` — JOIN normal_events AS n ON l.CID = n.CID AND n.Normal_Timestamp > l.Limited_Timestamp
