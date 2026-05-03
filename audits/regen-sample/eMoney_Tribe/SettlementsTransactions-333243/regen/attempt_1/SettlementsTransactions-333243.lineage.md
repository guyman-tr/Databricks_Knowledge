# Lineage: eMoney_Tribe.SettlementsTransactions-333243

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | Tribe Settlements API (XML export) | External API | Raw data ingestion via Generic Pipeline | External |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader — joins this table to child tables and inserts into ETL_SettlementsTransactions | eMoney_dbo |
| 3 | SettlementsTransactions_SettlementTransaction-637239 | Table | Child table joined via @Id (INNER JOIN) | eMoney_Tribe |
| 4 | SettlementsTransactions_RiskActions-236807 | Table | Child table joined via @Id (LEFT JOIN) | eMoney_Tribe |
| 5 | SettlementsTransactions_SecurityChecks-426253 | Table | Child table joined via @Id (LEFT JOIN) | eMoney_Tribe |

## Column Lineage

| Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|
| @Created | Tribe Settlements API | @Created | Passthrough from XML file metadata | Tier 3 |
| @Id | Tribe Settlements API | @Id | Passthrough from XML file metadata (GUID) | Tier 3 |
| @FileName | Tribe Settlements API | @FileName | Passthrough from XML file metadata | Tier 3 |
| etr_y | Generic Pipeline | — | ETL-generated year partition column (mostly NULL) | Tier 3 |
| etr_ym | Generic Pipeline | — | ETL-generated year-month partition column (mostly NULL) | Tier 3 |
| etr_ymd | Generic Pipeline | — | ETL-generated year-month-day partition column (mostly NULL) | Tier 3 |
| SynapseUpdateDate | Generic Pipeline | — | ETL housekeeping timestamp set during data load | Tier 3 |
| partition_date | Generic Pipeline | @Created | Date-only partition key derived from @Created | Tier 3 |
| Created | Tribe Settlements API | @Created | Copy of @Created; populated only for records loaded since ~2024 | Tier 3 |
