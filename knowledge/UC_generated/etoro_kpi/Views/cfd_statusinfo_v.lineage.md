# Column Lineage: main.etoro_kpi.cfd_statusinfo_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.cfd_statusinfo_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\cfd_statusinfo_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\cfd_statusinfo_v.json` (rows: 8, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market   ←── primary upstream
        │
        ▼
main.etoro_kpi.cfd_statusinfo_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `RealCID` | `passthrough` | (Tier 1 — etoro.Account.Customer.RealCID) | sanm.RealCID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `GCID` | `passthrough` | (Tier 1 — Account.Customer) | sanm.GCID |
| 3 | `CFD_Status` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `CFD_Status` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) | sanm.CFD_Status |
| 4 | `ApproprietnessScore_Status` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `ApproprietnessScore_Status` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) | sanm.ApproprietnessScore_Status |
| 5 | `ReleaseReasonDesc` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `ReleaseReasonDesc` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) | sanm.ReleaseReasonDesc |
| 6 | `ReleaseDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `ReleaseDate` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) | sanm.ReleaseDate |
| 7 | `BlockDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `BlockDate` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) | sanm.BlockDate |
| 8 | `BlockReasonDesc` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `BlockReasonDesc` | `passthrough` | (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) | sanm.BlockReasonDesc |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **7**, WARN: **1**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `CFD_Status` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market.cfd_status` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market.blockdate`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market.cfd_status` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**
