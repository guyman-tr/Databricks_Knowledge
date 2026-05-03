# Lineage: eMoney_Tribe.CardsSnapshots_BankAccount-341626

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | Tribe Cards API (BankAccount feed) | External API | Raw ingestion via Generic Pipeline | External |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader — joins this table into ETL_CardSnapshot | eMoney_dbo |
| 3 | CardsSnapshots_BankAccounts-83854 | Table | Parent table joined via @Id | eMoney_Tribe |
| 4 | ETL_CardSnapshot | Table | Downstream consumer (INSERT target) | eMoney_dbo |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | Tribe Cards API | @Id | Passthrough — Generic Pipeline raw ingestion | Tier 3 |
| 2 | @CardsSnapshots_BankAccounts@Id-83854 | Tribe Cards API | @CardsSnapshots_BankAccounts@Id-83854 | Passthrough — FK to parent CardsSnapshots_BankAccounts-83854 | Tier 3 |
| 3 | BankAccountNumber | Tribe Cards API | BankAccountNumber | Passthrough — raw bank account number | Tier 3 |
| 4 | BankAccountSortCode | Tribe Cards API | BankAccountSortCode | Passthrough — UK sort code | Tier 3 |
| 5 | BankAccountIban | Tribe Cards API | BankAccountIban | Passthrough — IBAN | Tier 3 |
| 6 | BankAccountBic | Tribe Cards API | BankAccountBic | Passthrough — BIC/SWIFT code | Tier 3 |
| 7 | BankAccountStatus | Tribe Cards API | BankAccountStatus | Passthrough — account active status | Tier 3 |
| 8 | BankAccountDirectDebitsIn | Tribe Cards API | BankAccountDirectDebitsIn | Passthrough — inbound direct debit capability | Tier 3 |
| 9 | BankAccountDirectDebitsOut | Tribe Cards API | BankAccountDirectDebitsOut | Passthrough — outbound direct debit capability | Tier 3 |
| 10 | BankAccountInstantPaymentsIn | Tribe Cards API | BankAccountInstantPaymentsIn | Passthrough — inbound instant payment capability | Tier 3 |
| 11 | BankAccountInstantPaymentsOut | Tribe Cards API | BankAccountInstantPaymentsOut | Passthrough — outbound instant payment capability | Tier 3 |
| 12 | etr_y | Generic Pipeline | etr_y | ETL partition year marker | Tier 3 |
| 13 | etr_ym | Generic Pipeline | etr_ym | ETL partition year-month marker | Tier 3 |
| 14 | etr_ymd | Generic Pipeline | etr_ymd | ETL partition year-month-day marker | Tier 3 |
| 15 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Synapse ingestion timestamp | Tier 3 |
| 16 | Created | Tribe Cards API | @Created | Record creation timestamp from Tribe | Tier 3 |
| 17 | partition_date | Generic Pipeline | partition_date | Partition date derived from ingestion | Tier 3 |
| 18 | BankAccountBankStateBranch | Tribe Cards API | BankAccountBankStateBranch | Passthrough — bank state/branch identifier | Tier 3 |
| 19 | BankAccountBankBranchCode | Tribe Cards API | BankAccountBankBranchCode | Passthrough — bank branch code | Tier 3 |
