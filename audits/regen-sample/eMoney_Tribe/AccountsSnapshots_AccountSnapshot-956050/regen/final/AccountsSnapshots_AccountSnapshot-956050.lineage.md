# Lineage: eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | Table | Tribe | FiatDwhDB | Production source (Generic Pipeline, Append, daily) |
| 2 | eMoney_Tribe.AccountsSnapshots-509416 | Table | eMoney_Tribe | Synapse | Parent snapshot header (joined on @Id by SP_eMoney_Reconciliation_ETLs) |
| 3 | eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | Table | eMoney_Tribe | Synapse | Sibling snapshot (LEFT JOIN on @Id by SP_eMoney_Reconciliation_ETLs) |
| 4 | eMoney_dbo.ETL_AccountSnapshot | Table | eMoney_dbo | Synapse | Downstream consumer (INSERT by SP_eMoney_Reconciliation_ETLs) |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|--------------|-----------|------|
| 1 | @Created | Generic Pipeline | — | Pipeline-injected record creation timestamp | Tier 2 |
| 2 | @Id | Generic Pipeline | — | Pipeline-assigned unique record identifier (GUID) | Tier 2 |
| 3 | @AccountsSnapshots@Id-509416 | Generic Pipeline | — | Pipeline-assigned parent snapshot link | Tier 2 |
| 4 | FileDate | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | FileDate | Passthrough (varchar) | Tier 3 |
| 5 | WorkDate | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | WorkDate | Passthrough (varchar) | Tier 3 |
| 6 | @WorkDate | Generic Pipeline | WorkDate | Typed cast of WorkDate to datetime2 | Tier 2 |
| 7 | AccountId | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountId | Passthrough | Tier 3 |
| 8 | HolderId | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | HolderId | Passthrough | Tier 3 |
| 9 | ProgramId | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | ProgramId | Passthrough | Tier 3 |
| 10 | CurrencyIson | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | CurrencyIson | Passthrough | Tier 3 |
| 11 | AvailableBalance | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AvailableBalance | Passthrough | Tier 3 |
| 12 | SettledBalance | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | SettledBalance | Passthrough | Tier 3 |
| 13 | AccountStatus | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatus | Passthrough | Tier 3 |
| 14 | AccountStatusDescription | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusDescription | Passthrough | Tier 3 |
| 15 | AccountStatusChangeDate | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusChangeDate | Passthrough | Tier 3 |
| 16 | AccountStatusChangeSource | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusChangeSource | Passthrough | Tier 3 |
| 17 | AccountStatusChangeReasonCode | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusChangeReasonCode | Passthrough | Tier 3 |
| 18 | AccountStatusChangeNote | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusChangeNote | Passthrough | Tier 3 |
| 19 | AccountStatusChangeOriginatorId | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | AccountStatusChangeOriginatorId | Passthrough | Tier 3 |
| 20 | DateUpdated | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | DateUpdated | Passthrough | Tier 3 |
| 21 | DateCreated | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | DateCreated | Passthrough | Tier 3 |
| 22 | BankAccounts | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | BankAccounts | Passthrough | Tier 3 |
| 23 | ReservedBalance | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | ReservedBalance | Passthrough | Tier 3 |
| 24 | HolderCountryIson | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 | HolderCountryIson | Passthrough | Tier 3 |
| 25 | etr_y | Generic Pipeline | — | ETL partition year | Tier 2 |
| 26 | etr_ym | Generic Pipeline | — | ETL partition year-month | Tier 2 |
| 27 | etr_ymd | Generic Pipeline | — | ETL partition year-month-day | Tier 2 |
| 28 | SynapseUpdateDate | Generic Pipeline | — | Synapse load timestamp | Tier 2 |
| 29 | partition_date | Generic Pipeline | — | Synapse partition date | Tier 2 |
| 30 | Created | Generic Pipeline | @Created | Typed copy of @Created as datetime2 | Tier 2 |
