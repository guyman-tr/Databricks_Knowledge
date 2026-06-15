# Column Lineage: main.etoro_kpi.customer_segments_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.customer_segments_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\customer_segments_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\customer_segments_v.json` (rows: 15, mismatches: 5) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi.ddr_aum_v` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ddr_aum_v.md` |
| `main.bi_dealing.bi_output_dealing_cidage_data` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_cidage_data.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_LifeStageDefinition.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   ←── primary upstream
  + main.bi_dealing.bi_output_dealing_cidage_data   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition   (JOIN)
  + main.etoro_kpi.ddr_aum_v   (JOIN)
        │
        ▼
main.etoro_kpi.customer_segments_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `GCID` | `passthrough` | — | cf.GCID |
| 2 | `CID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CID` | `passthrough` | — | cf.CID |
| 3 | `Club` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Club` | `passthrough` | — | cf.Club |
| 4 | `Channel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Channel` | `passthrough` | — | cf.Channel |
| 5 | `Country` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Country` | `passthrough` | — | cf.Country |
| 6 | `registered` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `registered` | `passthrough` | — | cf.registered |
| 7 | `FirstDepositDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `case` | — | CASE WHEN cf.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL ELSE cf.FirstDepositDate END AS FirstDepositDate |
| 8 | `FirstCashoutDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCashoutDate` | `passthrough` | — | cf.FirstCashoutDate |
| 9 | `FirstOpenPositionDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstMenualPosOpenDate` | `rename` | — | cf.FirstMenualPosOpenDate AS FirstOpenPositionDate |
| 10 | `CommunicationLanguage` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CommunicationLanguage` | `passthrough` | — | cf.CommunicationLanguage |
| 11 | `CustomerAge` | `main.bi_dealing.bi_output_dealing_cidage_data` | `Age` | `join_enriched` | — | ca.Age AS CustomerAge |
| 12 | `Is_Churn_over_14` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `case` | — | CASE WHEN LSD IN ('Churn 14-30 days', 'Churn 31-60 days', 'Churn over 60 days') THEN TRUE ELSE FALSE END AS Is_Churn_over_14 |
| 13 | `Is_Churn_over_30` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `case` | — | CASE WHEN LSD IN ('Churn 31-60 days', 'Churn over 60 days') THEN TRUE ELSE FALSE END AS Is_Churn_over_30 |
| 14 | `Is_Churn_over_60` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `case` | — | CASE WHEN LSD IN ('Churn over 60 days') THEN TRUE ELSE FALSE END AS Is_Churn_over_60 |
| 15 | `EquityScore` | `main.etoro_kpi.ddr_aum_v` | `—` | `case` | — | CASE WHEN aum.EquityGlobal >= 10000 THEN 'High' WHEN aum.EquityGlobal BETWEEN 150 AND 10000 THEN 'Medium' WHEN aum.EquityGlobal BETWEEN 0.5  |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **10**, WARN: **0**, ERROR: **5**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FirstDepositDate` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.firstdepositdate` | ERROR |
| `Is_Churn_over_14` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition.lsd` | ERROR |
| `Is_Churn_over_30` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition.lsd` | ERROR |
| `Is_Churn_over_60` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition.lsd` | ERROR |
| `EquityScore` | — | `main.etoro_kpi.ddr_aum_v.equityglobal`, `main.etoro_kpi_stg.bi_output_vg_aum_slim.equityglobal` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **6**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN bi_dealing.bi_output_dealing_cidage_data AS ca ON (ca.RealCID = cf.CID)
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition AS lsd ON (lsd.ToDateID = 99991231 AND lsd.RealCID = cf.CID)
- `LEFT JOIN` — LEFT JOIN main.etoro_kpi.ddr_aum_v AS aum ON (aum.RealCID = cf.CID AND aum.DateID = CAST(DATE_FORMAT(DATE_ADD(CURRENT_DATE, -1), 'yyyyMMdd') AS INT))
