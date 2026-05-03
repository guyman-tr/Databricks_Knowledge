# Lineage: eMoney_Tribe.CardsSnapshots_CardSnapshot-140457

## Source Objects

| # | Source Object | Source Type | Schema | Database | Server | Relationship |
|---|---|---|---|---|---|---|
| 1 | CardsSnapshots_CardSnapshot-140457 | Table | Tribe | FiatDwhDB | prod-banking | Generic Pipeline (Append, daily, parquet) → eMoney_Tribe raw landing |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | local | Reader — selects columns into #CardsSnapshots_140457 temp table for ETL_CardSnapshot |
| 3 | CardsSnapshots-890718 | Table | eMoney_Tribe | Synapse | local | Joined by SP via @Id — parent snapshot header record |
| 4 | CardsSnapshots_Accounts-350640 | Table | eMoney_Tribe | Synapse | local | Joined by SP via @Id — account-level snapshot data |
| 5 | CardsSnapshots_Account-513255 | Table | eMoney_Tribe | Synapse | local | Joined by SP via @Id — individual account details |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Created | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | @Created | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | @Id | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | @Id | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | @CardsSnapshots@Id-890718 | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | @CardsSnapshots@Id-890718 | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | FileDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | FileDate | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | WorkDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | WorkDate | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | @WorkDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | @WorkDate | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | IssuerIdentificationNumber | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | IssuerIdentificationNumber | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | ProgramName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ProgramName | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | ProgramId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ProgramId | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | ProductName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ProductName | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | ProductId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ProductId | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | SubProductId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | SubProductId | Passthrough (Generic Pipeline) | Tier 3 |
| 13 | HolderId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | HolderId | Passthrough (Generic Pipeline) | Tier 3 |
| 14 | CardNumber | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardNumber | Passthrough (Generic Pipeline) | Tier 3 |
| 15 | CardNumberId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardNumberId | Passthrough (Generic Pipeline) | Tier 3 |
| 16 | CardRequestId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardRequestId | Passthrough (Generic Pipeline) | Tier 3 |
| 17 | IsVirtual | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | IsVirtual | Passthrough (Generic Pipeline) | Tier 3 |
| 18 | CardExpirationDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardExpirationDate | Passthrough (Generic Pipeline) | Tier 3 |
| 19 | CardCreationDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardCreationDate | Passthrough (Generic Pipeline) | Tier 3 |
| 20 | CardActivationDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardActivationDate | Passthrough (Generic Pipeline) | Tier 3 |
| 21 | CardStatusDate | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusDate | Passthrough (Generic Pipeline) | Tier 3 |
| 22 | CardStatusCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusCode | Passthrough (Generic Pipeline) | Tier 3 |
| 23 | CardStatusCodeDescription | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusCodeDescription | Passthrough (Generic Pipeline) | Tier 3 |
| 24 | CardStatusChangeSource | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusChangeSource | Passthrough (Generic Pipeline) | Tier 3 |
| 25 | CardStatusChangeReasonCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusChangeReasonCode | Passthrough (Generic Pipeline) | Tier 3 |
| 26 | CardStatusChangeNote | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusChangeNote | Passthrough (Generic Pipeline) | Tier 3 |
| 27 | CardStatusChangeOriginatorId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardStatusChangeOriginatorId | Passthrough (Generic Pipeline) | Tier 3 |
| 28 | LimitsGroupName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | LimitsGroupName | Passthrough (Generic Pipeline) | Tier 3 |
| 29 | LimitsGroupId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | LimitsGroupId | Passthrough (Generic Pipeline) | Tier 3 |
| 30 | FeeGroupName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | FeeGroupName | Passthrough (Generic Pipeline) | Tier 3 |
| 31 | FeeGroupId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | FeeGroupId | Passthrough (Generic Pipeline) | Tier 3 |
| 32 | UsageGroupName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | UsageGroupName | Passthrough (Generic Pipeline) | Tier 3 |
| 33 | UsageGroupId | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | UsageGroupId | Passthrough (Generic Pipeline) | Tier 3 |
| 34 | FirstName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | FirstName | Passthrough (Generic Pipeline) | Tier 3 |
| 35 | LastName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | LastName | Passthrough (Generic Pipeline) | Tier 3 |
| 36 | Address | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | Address | Passthrough (Generic Pipeline) | Tier 3 |
| 37 | City | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | City | Passthrough (Generic Pipeline) | Tier 3 |
| 38 | State | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | State | Passthrough (Generic Pipeline) | Tier 3 |
| 39 | ZipCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ZipCode | Passthrough (Generic Pipeline) | Tier 3 |
| 40 | CountryCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CountryCode | Passthrough (Generic Pipeline) | Tier 3 |
| 41 | CountryCodeAlpha | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CountryCodeAlpha | Passthrough (Generic Pipeline) | Tier 3 |
| 42 | CountryName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CountryName | Passthrough (Generic Pipeline) | Tier 3 |
| 43 | Dob | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | Dob | Passthrough (Generic Pipeline) | Tier 3 |
| 44 | EmailAddress | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | EmailAddress | Passthrough (Generic Pipeline) | Tier 3 |
| 45 | PhoneNumber | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | PhoneNumber | Passthrough (Generic Pipeline) | Tier 3 |
| 46 | PhoneNumberCountryCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | PhoneNumberCountryCode | Passthrough (Generic Pipeline) | Tier 3 |
| 47 | ApplicationIpAddress | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ApplicationIpAddress | Passthrough (Generic Pipeline) | Tier 3 |
| 48 | KycVerification | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | KycVerification | Passthrough (Generic Pipeline) | Tier 3 |
| 49 | CardEvent | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | CardEvent | Passthrough (Generic Pipeline) | Tier 3 |
| 50 | DefaultCardCurrency | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DefaultCardCurrency | Passthrough (Generic Pipeline) | Tier 3 |
| 51 | Network | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | Network | Passthrough (Generic Pipeline) | Tier 3 |
| 52 | DeliveryTitle | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryTitle | Passthrough (Generic Pipeline) | Tier 3 |
| 53 | DeliveryFirstName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryFirstName | Passthrough (Generic Pipeline) | Tier 3 |
| 54 | DeliveryLastName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryLastName | Passthrough (Generic Pipeline) | Tier 3 |
| 55 | DeliveryAddress | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryAddress | Passthrough (Generic Pipeline) | Tier 3 |
| 56 | DeliveryCity | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryCity | Passthrough (Generic Pipeline) | Tier 3 |
| 57 | DeliveryState | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryState | Passthrough (Generic Pipeline) | Tier 3 |
| 58 | DeliveryZipCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryZipCode | Passthrough (Generic Pipeline) | Tier 3 |
| 59 | DeliveryCountryCode | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryCountryCode | Passthrough (Generic Pipeline) | Tier 3 |
| 60 | DeliveryCountryName | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | DeliveryCountryName | Passthrough (Generic Pipeline) | Tier 3 |
| 61 | ActiveWallet | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | ActiveWallet | Passthrough (Generic Pipeline) | Tier 3 |
| 62 | etr_y | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | etr_y | Passthrough (Generic Pipeline) | Tier 3 |
| 63 | etr_ym | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | etr_ym | Passthrough (Generic Pipeline) | Tier 3 |
| 64 | etr_ymd | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | etr_ymd | Passthrough (Generic Pipeline) | Tier 3 |
| 65 | SynapseUpdateDate | Synapse ETL | — | GETDATE() at pipeline load time | Tier 3 |
| 66 | partition_date | Synapse ETL | — | Derived from @Created or pipeline load date | Tier 3 |
| 67 | Created | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | Created | Passthrough (Generic Pipeline) | Tier 3 |
