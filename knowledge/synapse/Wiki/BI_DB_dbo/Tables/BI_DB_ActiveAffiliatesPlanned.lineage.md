# Column Lineage: BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| (manual input) | — | — | Manually populated budget/plan table. No automated ETL writer SP. |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Desk | Manual input | — | Affiliate desk/team identifier | Tier 4 |
| 2 | YearMonth | Manual input | — | Target month in YYYY-MM format | Tier 4 |
| 3 | NewAffWithFTD | Manual input | — | Planned count of new affiliates with first-time deposits | Tier 4 |
| 4 | TotalActiveAff | Manual input | — | Planned count of total active affiliates | Tier 4 |
| 5 | Churn | Manual input | — | Planned churn rate (as float) | Tier 4 |
| 6 | TotalFTDs | Manual input | — | Planned total first-time deposits | Tier 4 |
| 7 | UpdateDate | Manual input | — | Timestamp of plan entry | Tier 5 |

## Lineage Notes

- Table is a **configuration/budget input**, not an ETL output.
- Consumed by SP_M_Active_Affiliate_Monthly which LEFT JOINs planned values with actual affiliate metrics to populate BI_DB_ActiveAffiliatesPlanned_Actual.
- Currently has 0 rows — no plans have been loaded.
