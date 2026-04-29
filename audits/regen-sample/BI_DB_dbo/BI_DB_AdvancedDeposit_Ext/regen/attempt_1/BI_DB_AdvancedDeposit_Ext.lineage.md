# Column Lineage: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| DWH_dbo.Fact_BillingDeposit | Table | DWH_dbo | Primary deposit fact — 22 columns passthrough (origin: Billing.Deposit) |
| DWH_dbo.Dim_PaymentStatus | Table | DWH_dbo | Denormalized payment status lookup (origin: Dictionary.PaymentStatus) |
| DWH_dbo.Dim_FundingType | Table | DWH_dbo | Funding type name lookup (origin: Dictionary.FundingType) |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Customer demographics: RegisteredReal, AffiliateID, CountryID, FunnelFromID, FunnelID (origin: Customer.CustomerStatic) |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Country name + BIN country name lookups (origin: Dictionary.Country) |
| DWH_dbo.Dim_Funnel | Table | DWH_dbo | Funnel name lookups — 3 joins: fbd.FunnelID, CC.FunnelFromID, CC.FunnelID (origin: Dictionary.Funnel) |
| DWH_dbo.Dim_CardType | Table | DWH_dbo | Credit card type name lookup (origin: Dictionary.CardType) |
| DWH_dbo.Dim_CountryBin | Table | DWH_dbo | BIN-to-country/card-subtype/card-category lookup |
| DWH_dbo.Dim_BillingDepot | Table | DWH_dbo | Depot/payment processor name lookup (origin: Billing.Depot) |
| DWH_dbo.Dim_Affiliate + DWH_dbo.Dim_Channel | Table | DWH_dbo | Channel/SubChannel via AffiliateID->SubChannelID |
| BI_DB_dbo.External_etoro_Dictionary_RiskManagementStatus | External | BI_DB_dbo | Risk management status name lookup |
| BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | External | BI_DB_dbo | Marketing region name lookup |
| BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | External | BI_DB_dbo | FTD dates (FirstTimeDepositAttemptDate, FirstTimeDepositSuccessDate) |
| BI_DB_dbo.SP_H_Deposits | Stored Procedure | BI_DB_dbo | Writer SP (targets BI_DB_Deposits; creates #AdvancedDeposit_Ext temp with identical structure) |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | DepositID | Fact_BillingDeposit | DepositID | Passthrough | Tier 1 — Billing.Deposit |
| 2 | CID | Fact_BillingDeposit | CID | Passthrough | Tier 1 — Billing.Deposit |
| 3 | FundingID | Fact_BillingDeposit | FundingID | Passthrough | Tier 1 — Billing.Deposit |
| 4 | FundingType | Dim_FundingType | Name | Dim-lookup passthrough via External_etoro_Billing_Funding_Datafactory.FundingTypeID | Tier 1 — Dictionary.FundingType |
| 5 | CurrencyID | Fact_BillingDeposit | CurrencyID | Passthrough | Tier 1 — Billing.Deposit |
| 6 | PaymentStatusID | Fact_BillingDeposit | PaymentStatusID | Passthrough | Tier 1 — Billing.Deposit |
| 7 | ManagerID | Fact_BillingDeposit | ManagerID | Passthrough | Tier 1 — Billing.Deposit |
| 8 | RiskManagementStatusID | Fact_BillingDeposit | RiskManagementStatusID | Passthrough | Tier 1 — Billing.Deposit |
| 9 | Amount | Fact_BillingDeposit | Amount | Passthrough (capped in upstream ETL as of 2025-04-17) | Tier 1 — Billing.Deposit |
| 10 | ExchangeRate | Fact_BillingDeposit | ExchangeRate | Passthrough | Tier 1 — Billing.Deposit |
| 11 | ModificationDate | Fact_BillingDeposit | ModificationDate | Passthrough | Tier 1 — Billing.Deposit |
| 12 | TransactionID | Fact_BillingDeposit | TransactionIDAsString | Rename from XML-extracted field | Tier 2 — SP_H_Deposits |
| 13 | IPAddress | Fact_BillingDeposit | IPAddress | Passthrough | Tier 1 — Billing.Deposit |
| 14 | Approved | Fact_BillingDeposit | Approved | Passthrough | Tier 1 — Billing.Deposit |
| 15 | Commission | Fact_BillingDeposit | Commission | Passthrough | Tier 1 — Billing.Deposit |
| 16 | PaymentDate | Fact_BillingDeposit | PaymentDate | Passthrough | Tier 1 — Billing.Deposit |
| 17 | ClearingHouseEffectiveDate | Fact_BillingDeposit | ClearingHouseEffectiveDate | Passthrough | Tier 1 — Billing.Deposit |
| 18 | OldPaymentID | (none) | — | Hardcoded NULL in SP | Tier 2 — SP_H_Deposits |
| 19 | IsFTD | Fact_BillingDeposit | IsFTD | Passthrough (type narrowing: int->bit) | Tier 1 — Billing.Deposit |
| 20 | ProcessorValueDate | Fact_BillingDeposit | ProcessorValueDate | Passthrough | Tier 1 — Billing.Deposit |
| 21 | RefundVerificationCode | Fact_BillingDeposit | RefundVerificationCode | Passthrough | Tier 1 — Billing.Deposit |
| 22 | DepotID | Fact_BillingDeposit | DepotID | Passthrough | Tier 1 — Billing.Deposit |
| 23 | MatchStatusID | Fact_BillingDeposit | MatchStatusID | Passthrough | Tier 1 — Billing.Deposit |
| 24 | FunnelID | Fact_BillingDeposit | FunnelID | Passthrough | Tier 1 — Billing.Deposit |
| 25 | Code | (none) | — | Hardcoded NULL in SP | Tier 2 — SP_H_Deposits |
| 26 | ExTransactionID | Fact_BillingDeposit | ExTransactionID | Passthrough | Tier 1 — Billing.Deposit |
| 27 | PaymentStatus_PaymentStatusID | Dim_PaymentStatus | PaymentStatusID | Dim-lookup passthrough on fbd.PaymentStatusID | Tier 1 — Dictionary.PaymentStatus |
| 28 | PaymentStatus_Name | Dim_PaymentStatus | Name | Dim-lookup passthrough on fbd.PaymentStatusID | Tier 1 — Dictionary.PaymentStatus |
| 29 | RiskManagementStatus_RiskManagementStatusID | External_etoro_Dictionary_RiskManagementStatus | RiskManagementStatusID | External table lookup on fbd.RiskManagementStatusID (no upstream wiki) | Tier 2 — SP_H_Deposits |
| 30 | RiskManagementStatus_Name | External_etoro_Dictionary_RiskManagementStatus | Name | External table lookup on fbd.RiskManagementStatusID (no upstream wiki) | Tier 2 — SP_H_Deposits |
| 31 | Channel | Dim_Channel | Channel | Dim-lookup via Dim_Affiliate.SubChannelID (joined on CC.AffiliateID). Dim_Channel.Channel is itself Tier 2 (SP-computed). | Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| 32 | SubChannel | Dim_Channel | SubChannel | Dim-lookup via Dim_Affiliate.SubChannelID (joined on CC.AffiliateID). Dim_Channel.SubChannel is itself Tier 2 (SP-computed). | Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| 33 | Region | External_etoro_Dictionary_MarketingRegion | Name | External table lookup via Dim_Country.MarketingRegionID (no upstream wiki) | Tier 2 — SP_H_Deposits |
| 34 | Country | Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID | Tier 1 — Dictionary.Country |
| 35 | FirstDepositAttempt | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositAttemptDate | Rename passthrough from external table (no upstream wiki) | Tier 2 — SP_H_Deposits |
| 36 | FirstDepositDate | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositSuccessDate | Rename passthrough from external table (no upstream wiki) | Tier 2 — SP_H_Deposits |
| 37 | Registered | Dim_Customer | RegisteredReal | Dim-lookup passthrough (Dim_Customer origin: Customer.CustomerStatic) | Tier 1 — Customer.CustomerStatic |
| 38 | SerialID | Dim_Customer | AffiliateID | Dim-lookup passthrough, renamed (DWH: SerialID->AffiliateID; BI_DB: AffiliateID->SerialID). Origin: Customer.CustomerStatic.SerialID | Tier 1 — Customer.CustomerStatic |
| 39 | Funnel | Dim_Funnel | Name | Dim-lookup passthrough via fbd.FunnelID | Tier 1 — Dictionary.Funnel |
| 40 | FunnelFrom | Dim_Funnel | Name | Dim-lookup passthrough via Dim_Customer.FunnelFromID | Tier 1 — Dictionary.Funnel |
| 41 | AcquisitionFunnel | Dim_Funnel | Name | Dim-lookup passthrough via Dim_Customer.FunnelID | Tier 1 — Dictionary.Funnel |
| 42 | BinCode | Fact_BillingDeposit | BinCodeAsString | Rename from XML-extracted field | Tier 2 — SP_H_Deposits |
| 43 | CreditCardType | Dim_CardType | CarTypeName | Dim-lookup passthrough via fbd.CardTypeIDAsInteger | Tier 1 — Dictionary.CardType |
| 44 | CardSubType | Dim_CountryBin | CardSubType | Dim-lookup passthrough via fbd.BinCodeAsString. Dim_CountryBin.CardSubType is itself Tier 2 (staging passthrough). | Tier 2 — SP_Dictionaries_DL_To_Synapse |
| 45 | BINCountry | Dim_Country | Name | Dim-lookup passthrough via fbd.BinCountryIDAsInteger | Tier 1 — Dictionary.Country |
| 46 | DepoName | Dim_BillingDepot | Name | Dim-lookup passthrough via fbd.DepotID | Tier 1 — Billing.Depot |
| 47 | CardCategory | Dim_CountryBin | CardCategory | Dim-lookup passthrough via fbd.BinCodeAsString. Dim_CountryBin.CardCategory is itself Tier 2 (staging passthrough). | Tier 2 — SP_Dictionaries_DL_To_Synapse |

## Lineage Notes

- **TABLE IS DORMANT (0 rows)**. SP_H_Deposits creates `#AdvancedDeposit_Ext` temp table with identical 47-column structure (plus 5 extra: ResponseName, ResponseRN, Date, DateID, UpdateDate), then writes to `BI_DB_dbo.BI_DB_Deposits`, not this table.
- A backup cleanup script exists from 2024-11-17 (`BI_DB_AdvancedDeposit_Ext_Backup_20241117`), suggesting the table was active before that date.
- Column lineage is derived from SP_H_Deposits temp table construction, which matches this table's DDL exactly.
- The "_Ext" suffix indicates this was an extended/denormalized snapshot, likely superseded by `BI_DB_Deposits`.
- Dim-lookup passthroughs inherit the root production origin per tier transitivity rules: e.g., Country -> Dim_Country.Name -> Dictionary.Country (root), not Dim_Country (relay).
