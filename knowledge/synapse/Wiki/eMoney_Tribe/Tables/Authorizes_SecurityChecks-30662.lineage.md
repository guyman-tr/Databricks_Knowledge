# Lineage: eMoney_Tribe.Authorizes_SecurityChecks-30662

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | Production Table | Generic Pipeline (Append) | Tribe |
| 2 | eMoney_Tribe.Authorizes_Authorize-312243 | Synapse Tribe Table | Parent record (JOIN on @Id) | eMoney_Tribe |
| 3 | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader — joins this table into ETL_Authorize | eMoney_dbo |
| 4 | eMoney_dbo.ETL_Authorize | Synapse Table | Downstream target (INSERT INTO) | eMoney_dbo |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Id | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | @Authorizes_Authorize@Id-312243 | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Authorizes_Authorize@Id-312243 | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | CardExpirationDatePresent | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | CardExpirationDatePresent | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | OnlinePIN | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | OnlinePIN | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | OfflinePIN | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | OfflinePIN | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | ThreeDomainSecure | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | ThreeDomainSecure | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | Cvv2 | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | Cvv2 | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | MagneticStripe | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | MagneticStripe | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | ChipData | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | ChipData | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | AVS | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | AVS | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | PhoneNumber | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | PhoneNumber | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | Signature | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | Signature | Passthrough (Generic Pipeline) | Tier 3 |
| 13 | etr_y | Generic Pipeline | etr_y | ETL metadata — extraction year | Tier 3 |
| 14 | etr_ym | Generic Pipeline | etr_ym | ETL metadata — extraction year-month | Tier 3 |
| 15 | etr_ymd | Generic Pipeline | etr_ymd | ETL metadata — extraction year-month-day | Tier 3 |
| 16 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | ETL metadata — Synapse load timestamp | Tier 3 |
| 17 | Created | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Created | Passthrough (Generic Pipeline) | Tier 3 |
| 18 | AccountNames | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | AccountNames | Passthrough (Generic Pipeline) | Tier 3 |
| 19 | partition_date | Generic Pipeline | partition_date | ETL metadata — partition date derived from Created | Tier 3 |
