# Lineage: eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253

## Source Objects

| # | Source Object | Source Type | Relationship | Database / Server |
|---|---|---|---|---|
| 1 | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | Table | Generic Pipeline (Append, daily) | prod-banking |
| 2 | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader — LEFT JOINs this table into ETL_SettlementsTransactions | Synapse DWH |
| 3 | eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | Table | Parent entity — joined on @Id | Synapse DWH |
| 4 | eMoney_dbo.ETL_SettlementsTransactions | Table | Downstream target — SP inserts security check columns into this table | Synapse DWH |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | @Id | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | @SettlementsTransactions_SettlementTransaction@Id-637239 | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | CardExpirationDatePresent | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | CardExpirationDatePresent | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | OnlinePIN | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | OnlinePIN | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | OfflinePIN | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | OfflinePIN | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | ThreeDomainSecure | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | ThreeDomainSecure | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | Cvv2 | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | Cvv2 | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | MagneticStripe | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | MagneticStripe | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | ChipData | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | ChipData | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | AVS | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | AVS | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | PhoneNumber | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | PhoneNumber | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | Signature | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | Signature | Passthrough (Generic Pipeline) | Tier 3 |
| 13 | etr_y | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | etr_y | Passthrough (Generic Pipeline) | Tier 3 |
| 14 | etr_ym | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | etr_ym | Passthrough (Generic Pipeline) | Tier 3 |
| 15 | etr_ymd | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | etr_ymd | Passthrough (Generic Pipeline) | Tier 3 |
| 16 | SynapseUpdateDate | Generic Pipeline | N/A | Ingestion timestamp set by pipeline | Tier 3 |
| 17 | Created | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | Created | Passthrough (Generic Pipeline) | Tier 3 |
| 18 | AccountNames | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | AccountNames | Passthrough (Generic Pipeline) | Tier 3 |
| 19 | partition_date | Generic Pipeline | N/A | Partition key derived from ingestion date | Tier 3 |
