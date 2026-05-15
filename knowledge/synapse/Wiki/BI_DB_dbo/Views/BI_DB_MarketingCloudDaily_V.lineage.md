# Column Lineage: BI_DB_dbo.BI_DB_MarketingCloudDaily_V

| Property | Value |
|----------|-------|
| **Parent table** | `BI_DB_MarketingCloudDaily` |
| **UC view** | `BI_DB_MarketingCloudDaily_V` |
| **Generated** | 2026-05-14 |

## Predicate

```
SELECT * FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily WHERE AccountId IS NOT NULL
```

(Column lineage identical to parent document after predicate — refer to `Tables/BI_DB_MarketingCloudDaily.lineage.md`; partition columns `etr_*` originate from Gold ingestion stack.)
