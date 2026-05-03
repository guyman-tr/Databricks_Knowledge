# Lineage: eMoney_Tribe.CardsSnapshots_Accounts-350640

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 | Table | Tribe | FiatDwhDB | Generic Pipeline (Append, daily) via prod-banking |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Consumer — reads this table as JOIN bridge |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 | @Id | Passthrough via Generic Pipeline | Tier 3 |
| 2 | @CardsSnapshots_CardSnapshot@Id-140457 | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 | @CardsSnapshots_CardSnapshot@Id-140457 | Passthrough via Generic Pipeline | Tier 3 |
| 3 | etr_y | Generic Pipeline | — | ETL partition column (year) | Tier 3 |
| 4 | etr_ym | Generic Pipeline | — | ETL partition column (year-month) | Tier 3 |
| 5 | etr_ymd | Generic Pipeline | — | ETL partition column (year-month-day) | Tier 3 |
| 6 | SynapseUpdateDate | Generic Pipeline | — | Synapse sync timestamp | Tier 3 |
| 7 | Created | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 | Created | Passthrough via Generic Pipeline | Tier 3 |
| 8 | partition_date | Generic Pipeline | — | Date partition key derived from Created | Tier 3 |
