# CardsSnapshots-890718 — Lineage

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | CardsSnapshots_CardSnapshot-140457 | Table | eMoney_Tribe | Synapse | JOIN on @Id — provides card snapshot detail columns |
| 2 | CardsSnapshots_Accounts-350640 | Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id — provides account linkage |
| 3 | CardsSnapshots_Account-513255 | Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id — provides account detail columns |
| 4 | CardsSnapshots_BankAccounts-83854 | Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id — provides bank account linkage |
| 5 | CardsSnapshots_BankAccount-341626 | Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id — provides bank account detail columns |
| 6 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Writer SP — joins this table with sub-tables to populate ETL_CardSnapshot |

## Target Objects

| # | Target Object | Target Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | ETL_CardSnapshot | Table | eMoney_dbo | Synapse | Final reconciliation target — receives joined card snapshot data |

## Column Lineage

| Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|
| @Created | Data Lake XML | @Created | Ingested as-is from XML file metadata | Tier 3 |
| @Id | Data Lake XML | @Id | GUID assigned during XML ingestion; used as JOIN key across all CardsSnapshots sub-tables | Tier 3 |
| @FileName | Data Lake XML | @FileName | Source XML file path from data lake ingestion | Tier 3 |
| etr_y | Data Lake ETR | etr_y | ETR year partition column; ~99.5% empty | Tier 3 |
| etr_ym | Data Lake ETR | etr_ym | ETR year-month partition column; ~99.5% empty | Tier 3 |
| etr_ymd | Data Lake ETR | etr_ymd | ETR year-month-day partition column; ~99.5% empty | Tier 3 |
| SynapseUpdateDate | Synapse | N/A | Synapse ingestion timestamp | Tier 3 |
| Created | Data Lake XML | @Created | Record creation timestamp; near-identical to @Created | Tier 3 |
| partition_date | Data Lake XML | @Created | Date portion derived from @Created for partitioning | Tier 3 |
