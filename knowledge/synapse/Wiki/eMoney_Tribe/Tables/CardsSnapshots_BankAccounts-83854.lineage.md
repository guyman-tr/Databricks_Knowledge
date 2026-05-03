# Lineage: eMoney_Tribe.CardsSnapshots_BankAccounts-83854

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|--------------|-------------|-------------- |--------|
| 1 | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | Production Table | Generic Pipeline (Append, daily) | Tribe |
| 2 | eMoney_Tribe.CardsSnapshots_Account-513255 | Synapse Table | Parent (FK via @CardsSnapshots_Account@Id-513255) | eMoney_Tribe |
| 3 | eMoney_Tribe.CardsSnapshots_BankAccount-341626 | Synapse Table | Child (FK via @CardsSnapshots_BankAccounts@Id-83854) | eMoney_Tribe |
| 4 | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader — LEFT JOINs this table to build ETL_CardSnapshot | eMoney_dbo |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | @Id | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | @Id | Passthrough | Tier 1 |
| 2 | @CardsSnapshots_Account@Id-513255 | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | (no matching production column) | Synapse-specific FK to CardsSnapshots_Account-513255; production has @CardsSnapshots@Id-890718 instead | Tier 3 |
| 3 | etr_y | Generic Pipeline | etr_y | Pipeline partition year marker | Tier 3 |
| 4 | etr_ym | Generic Pipeline | etr_ym | Pipeline partition year-month marker | Tier 3 |
| 5 | etr_ymd | Generic Pipeline | etr_ymd | Pipeline partition year-month-day marker | Tier 3 |
| 6 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Ingestion timestamp | Tier 3 |
| 7 | Created | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | Created | Passthrough | Tier 1 |
| 8 | partition_date | Generic Pipeline | partition_date | Derived partition date | Tier 3 |
