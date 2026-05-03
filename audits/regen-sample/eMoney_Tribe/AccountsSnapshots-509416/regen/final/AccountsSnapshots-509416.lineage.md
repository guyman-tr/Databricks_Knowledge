# Lineage: eMoney_Tribe.AccountsSnapshots-509416

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|-------------|--------|----------|-------------|
| 1 | Generic Pipeline (Tribe XML ingestion) | External Pipeline | — | eMoney Tribe | Raw data landing — XML file ingestion into Synapse |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Reader — uses this table as source for ETL_AccountSnapshot (Reconciliation Table 05) |
| 3 | NewSBUpdateStatsBigTables | Stored Procedure | DE_dbo | Synapse | Statistics maintenance only |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | @Created | Tribe XML ingestion | @Created | Passthrough — XML record creation timestamp | Tier 3 |
| 2 | @Id | Tribe XML ingestion | @Id | Passthrough — XML record unique identifier (GUID) | Tier 3 |
| 3 | @FileName | Tribe XML ingestion | @FileName | Passthrough — source XML file name | Tier 3 |
| 4 | etr_y | Tribe XML ingestion | etr_y | Passthrough — ETL year partition key (appears unused) | Tier 3 |
| 5 | etr_ym | Tribe XML ingestion | etr_ym | Passthrough — ETL year-month partition key (appears unused) | Tier 3 |
| 6 | etr_ymd | Tribe XML ingestion | etr_ymd | Passthrough — ETL year-month-day partition key (appears unused) | Tier 3 |
| 7 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Synapse load timestamp | Tier 3 |
| 8 | partition_date | Generic Pipeline | partition_date | Partition date derived from record date | Tier 3 |
| 9 | Created | Tribe XML ingestion | Created | Record creation timestamp | Tier 3 |

## Notes

- This is a raw XML landing table from the eMoney Tribe data pipeline. No upstream production wiki exists.
- All columns originate from Tribe XML file ingestion with no documented upstream schema.
- The table is consumed by `SP_eMoney_Reconciliation_ETLs` as a join root for the Account Snapshot ETL (Reconciliation Table 05), where it provides `@FileName` and `@Id` to join with sub-tables `AccountsSnapshots_AccountSnapshot-956050`, `AccountsSnapshots_BankAccounts-795870`, and `AccountsSnapshots_BankAccount-393561`.
