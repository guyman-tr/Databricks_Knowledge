# Lineage: eMoney_Tribe.AccountsSnapshots_BankAccounts-795870

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|--------------|-------------|--------------|----------|
| 1 | Tribe Platform API (BankAccounts entity) | External API | Raw data landing | DDL column naming convention (@-prefixed IDs, etr_ partitioning fields) |
| 2 | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Stored Procedure | Downstream consumer (reader) | LEFT JOIN on [@Id] to build ETL_AccountSnapshot |

## Column Lineage

| Synapse Column | Source | Source Column | Transform | Tier |
|---|---|---|---|---|
| @Id | Tribe Platform API | @Id | Passthrough (UUID primary key) | Tier 3 |
| @AccountsSnapshots_AccountSnapshot@Id-956050 | Tribe Platform API | Parent entity FK | Passthrough (parent snapshot reference) | Tier 3 |
| etr_y | Tribe Platform API | etr_y | Passthrough (ETL year partition, mostly empty) | Tier 3 |
| etr_ym | Tribe Platform API | etr_ym | Passthrough (ETL year-month partition, mostly empty) | Tier 3 |
| etr_ymd | Tribe Platform API | etr_ymd | Passthrough (ETL year-month-day partition, mostly empty) | Tier 3 |
| SynapseUpdateDate | Synapse ETL | N/A | System-generated timestamp | Tier 3 |
| Created | Tribe Platform API | Created | Passthrough (record creation timestamp) | Tier 3 |
| partition_date | Tribe Platform API / ETL | partition_date | Date partition key derived from Created | Tier 3 |

## Downstream Consumers

| Consumer | Schema | Relationship |
|---|---|---|
| SP_eMoney_Reconciliation_ETLs | eMoney_dbo | LEFT JOIN on @Id to AccountsSnapshots_AccountSnapshot-956050; only @Id selected to identify snapshots with bank account associations |
| ETL_AccountSnapshot | eMoney_dbo | Indirect — receives @Id via SP_eMoney_Reconciliation_ETLs join chain |
