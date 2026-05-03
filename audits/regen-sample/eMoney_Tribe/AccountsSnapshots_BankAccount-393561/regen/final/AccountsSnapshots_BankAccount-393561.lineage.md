# Lineage: eMoney_Tribe.AccountsSnapshots_BankAccount-393561

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Notes |
|---|---|---|---|---|---|---|
| 1 | AccountsSnapshots_BankAccount-393561 | Table | Tribe | FiatDwhDB | Production source (Generic Pipeline #552) | Raw Tribe export from prod-banking, daily append |
| 2 | AccountsSnapshots_BankAccounts-795870 | Table | eMoney_Tribe | Synapse | Parent table | Container for bank accounts within an account snapshot |
| 3 | AccountsSnapshots_AccountSnapshot-956050 | Table | eMoney_Tribe | Synapse | Grandparent table | Account snapshot record |
| 4 | AccountsSnapshots-509416 | Table | eMoney_Tribe | Synapse | Root table | Root file-level record for account snapshots |
| 5 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Consumer (reader) | Reads bank account columns into ETL_AccountSnapshot |
| 6 | ETL_AccountSnapshot | Table | eMoney_dbo | Synapse | Downstream target | Reconciliation table populated by SP_eMoney_Reconciliation_ETLs |

## Column Lineage

| # | Synapse Column | Source Column | Source Object | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | @Id | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | @AccountsSnapshots_BankAccounts@Id-795870 | @AccountsSnapshots_BankAccounts@Id-795870 | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | BankAccountId | BankAccountId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | BankAccountExternalId | BankAccountExternalId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | BankAccountStatus | BankAccountStatus | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | BankAccountBankProviderId | BankAccountBankProviderId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | BankAccountAccountName | BankAccountAccountName | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | BankAccountAccountNumber | BankAccountAccountNumber | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | BankAccountSortCode | BankAccountSortCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | BankAccountIban | BankAccountIban | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | BankAccountBic | BankAccountBic | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | BankAccountStatusChangeReasonCode | BankAccountStatusChangeReasonCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 13 | BankAccountStatusChangeNote | BankAccountStatusChangeNote | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 14 | BankAccountStatusChangeSource | BankAccountStatusChangeSource | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 15 | etr_y | etr_y | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 16 | etr_ym | etr_ym | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 17 | etr_ymd | etr_ymd | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 18 | SynapseUpdateDate | SynapseUpdateDate | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 19 | Created | Created | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 20 | EpmMethodId | EpmMethodId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 21 | partition_date | partition_date | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 22 | BankAccountBankStateBranch | BankAccountBankStateBranch | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
| 23 | BankAccountBankBranchCode | BankAccountBankBranchCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Passthrough (Generic Pipeline) | Tier 3 |
