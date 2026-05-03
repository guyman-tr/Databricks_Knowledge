# Lineage: eMoney_Tribe.CardsSnapshots_Account-513255

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Schema |
|---|--------------|-------------|-------------|----------|--------|
| 1 | Tribe.CardsSnapshots_Account-513255 | Table | Production source (Generic Pipeline) | FiatDwhDB | Tribe |
| 2 | Tribe.CardsSnapshots_Accounts-350640 | Table | Parent accounts collection | FiatDwhDB | Tribe |
| 3 | Tribe.CardsSnapshots-890718 | Table | Root snapshot container | FiatDwhDB | Tribe |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | @Id | Tribe.CardsSnapshots_Account-513255 | @Id | Passthrough (CAST uniqueidentifier → varchar(255)) | Tier 1 |
| 2 | @CardsSnapshots_Accounts@Id-350640 | Tribe.CardsSnapshots_Accounts-350640 | @Id | FK reference to accounts collection | Tier 3 |
| 3 | AccountId | Tribe.CardsSnapshots_Account-513255 | AccountId | Passthrough | Tier 3 |
| 4 | AccountStatus | Tribe.CardsSnapshots_Account-513255 | AccountStatus | Passthrough | Tier 3 |
| 5 | AccountStatusDate | Tribe.CardsSnapshots_Account-513255 | AccountStatusDate | Passthrough | Tier 3 |
| 6 | AccountStatusChangeSource | Tribe.CardsSnapshots_Account-513255 | AccountStatusChangeSource | Passthrough | Tier 3 |
| 7 | AccountStatusChangeReasonCode | Tribe.CardsSnapshots_Account-513255 | AccountStatusChangeReasonCode | Passthrough | Tier 3 |
| 8 | AccountStatusChangeNote | Tribe.CardsSnapshots_Account-513255 | AccountStatusChangeNote | Passthrough | Tier 3 |
| 9 | AccountStatusChangeOriginatorId | Tribe.CardsSnapshots_Account-513255 | AccountStatusChangeOriginatorId | Passthrough | Tier 3 |
| 10 | AccountLimitsGroupName | Tribe.CardsSnapshots_Account-513255 | AccountLimitsGroupName | Passthrough | Tier 3 |
| 11 | AccountLimitsGroupId | Tribe.CardsSnapshots_Account-513255 | AccountLimitsGroupId | Passthrough | Tier 3 |
| 12 | AccountFeeGroupName | Tribe.CardsSnapshots_Account-513255 | AccountFeeGroupName | Passthrough | Tier 3 |
| 13 | AccountFeeGroupId | Tribe.CardsSnapshots_Account-513255 | AccountFeeGroupId | Passthrough | Tier 3 |
| 14 | BankAccounts | Tribe.CardsSnapshots_Account-513255 | BankAccounts | Passthrough | Tier 3 |
| 15 | AvailableBalance | Tribe.CardsSnapshots_Account-513255 | AvailableBalance | Passthrough | Tier 3 |
| 16 | BlockedAmount | Tribe.CardsSnapshots_Account-513255 | BlockedAmount | Passthrough | Tier 3 |
| 17 | CurrentBalance | Tribe.CardsSnapshots_Account-513255 | CurrentBalance | Passthrough | Tier 3 |
| 18 | AccountCurrency | Tribe.CardsSnapshots_Account-513255 | AccountCurrency | Passthrough | Tier 3 |
| 19 | ReservedBalance | Tribe.CardsSnapshots_Account-513255 | ReservedBalance | Passthrough | Tier 3 |
| 20 | etr_y | — | — | Generic Pipeline framework column | Tier 3 |
| 21 | etr_ym | — | — | Generic Pipeline framework column | Tier 3 |
| 22 | etr_ymd | — | — | Generic Pipeline framework column | Tier 3 |
| 23 | SynapseUpdateDate | — | — | Synapse load timestamp | Tier 3 |
| 24 | Created | Tribe.CardsSnapshots_Account-513255 | Created | Passthrough | Tier 1 |
| 25 | partition_date | — | — | Synapse partitioning column | Tier 3 |
