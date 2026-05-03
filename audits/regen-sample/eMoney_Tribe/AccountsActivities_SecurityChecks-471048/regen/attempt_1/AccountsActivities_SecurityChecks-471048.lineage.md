# Lineage: eMoney_Tribe.AccountsActivities_SecurityChecks-471048

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Notes |
|---|---|---|---|---|---|---|
| 1 | AccountsActivities_SecurityChecks-471048 | Table | Tribe | FiatDwhDB | Production origin | Treezor XML child node — security checks for account activities |
| 2 | AccountsActivities_AccountActivity-833937 | Table | eMoney_Tribe | Synapse | Sibling (JOIN on @Id) | Parent activity record joined in SP_eMoney_Reconciliation_ETLs |
| 3 | AccountsActivities_862157 | Table | eMoney_Tribe | Synapse | Grandparent | XML envelope table (parent of 833937) |
| 4 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Reader SP | Reads this table as `aas` via LEFT JOIN on @Id |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | Tribe.AccountsActivities_SecurityChecks-471048 | @Id | Passthrough (UNIQUEIDENTIFIER → varchar(40)) | Tier 1 |
| 2 | @AccountsActivities_AccountActivity@Id-833937 | Tribe.AccountsActivities_SecurityChecks-471048 | (structural FK) | FK to AccountActivity child node; name encodes parent entity ID | Tier 3 |
| 3 | CardExpirationDatePresent | Tribe.AccountsActivities_SecurityChecks-471048 | CardExpirationDatePresent | Passthrough — not documented in upstream wiki | Tier 3 |
| 4 | OnlinePIN | Tribe.AccountsActivities_SecurityChecks-471048 | OnlinePIN | Passthrough — not documented in upstream wiki | Tier 3 |
| 5 | OfflinePIN | Tribe.AccountsActivities_SecurityChecks-471048 | OfflinePIN | Passthrough — not documented in upstream wiki | Tier 3 |
| 6 | ThreeDomainSecure | Tribe.AccountsActivities_SecurityChecks-471048 | ThreeDomainSecure | Passthrough — not documented in upstream wiki | Tier 3 |
| 7 | Cvv2 | Tribe.AccountsActivities_SecurityChecks-471048 | Cvv2 | Passthrough — not documented in upstream wiki | Tier 3 |
| 8 | MagneticStripe | Tribe.AccountsActivities_SecurityChecks-471048 | MagneticStripe | Passthrough — not documented in upstream wiki | Tier 3 |
| 9 | ChipData | Tribe.AccountsActivities_SecurityChecks-471048 | ChipData | Passthrough — not documented in upstream wiki | Tier 3 |
| 10 | AVS | Tribe.AccountsActivities_SecurityChecks-471048 | AVS | Passthrough — not documented in upstream wiki | Tier 3 |
| 11 | PhoneNumber | Tribe.AccountsActivities_SecurityChecks-471048 | PhoneNumber | Passthrough — not documented in upstream wiki | Tier 3 |
| 12 | Signature | Tribe.AccountsActivities_SecurityChecks-471048 | Signature | Passthrough — not documented in upstream wiki | Tier 3 |
| 13 | etr_y | Generic Pipeline | etr_y | ETL partition metadata — year | Tier 3 |
| 14 | etr_ym | Generic Pipeline | etr_ym | ETL partition metadata — year-month | Tier 3 |
| 15 | etr_ymd | Generic Pipeline | etr_ymd | ETL partition metadata — year-month-day | Tier 3 |
| 16 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | ETL ingestion timestamp | Tier 3 |
| 17 | Created | Tribe.AccountsActivities_SecurityChecks-471048 | Created | Passthrough | Tier 1 |
| 18 | AccountNames | Tribe.AccountsActivities_SecurityChecks-471048 | AccountNames | Passthrough — not documented in upstream wiki | Tier 3 |
| 19 | partition_date | Generic Pipeline | partition_date | ETL partition metadata — date | Tier 3 |
