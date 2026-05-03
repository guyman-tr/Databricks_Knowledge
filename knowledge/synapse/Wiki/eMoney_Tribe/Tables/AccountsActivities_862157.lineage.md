# Lineage: eMoney_Tribe.AccountsActivities_862157

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | AccountsActivities_AccountActivity-833937 | Table | eMoney_Tribe | Synapse | Child detail table joined on @Id |
| 2 | AccountsActivities_RiskActions-322546 | Table | eMoney_Tribe | Synapse | Child risk-actions table joined on @Id |
| 3 | AccountsActivities_SecurityChecks-471048 | Table | eMoney_Tribe | Synapse | Child security-checks table joined on @Id |
| 4 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Writer SP — reads this table as parent envelope |
| 5 | ETL_AccountsActivities | Table | eMoney_dbo | Synapse | Downstream target — SP inserts joined result here |

## Column Lineage

| Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|
| @Created | Treezor XML export | @Created | Passthrough — XML document creation timestamp | Tier 3 |
| @Id | Treezor XML export | @Id | Passthrough — XML document UUID | Tier 3 |
| @FileName | Treezor XML export | @FileName | Passthrough — source XML file name | Tier 3 |
| etr_y | Generic Pipeline | etr_y | ETL partition key (year) — ~99.8% NULL | Tier 3 |
| etr_ym | Generic Pipeline | etr_ym | ETL partition key (year-month) — ~99.8% NULL | Tier 3 |
| etr_ymd | Generic Pipeline | etr_ymd | ETL partition key (year-month-day) — ~99.8% NULL | Tier 3 |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Passthrough — Synapse ingestion timestamp | Tier 3 |
| partition_date | Generic Pipeline | partition_date | Passthrough — date partition key | Tier 3 |
| Created | Treezor XML export | Created | Passthrough — alternate creation timestamp, ~41.6% NULL | Tier 3 |
