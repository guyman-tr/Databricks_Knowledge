# Column Lineage: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| DWH_dbo.Fact_BillingDeposit | Table | DWH_dbo | Primary deposit fact — 22 columns passthrough (production origin: Billing.Deposit) |
| DWH_dbo.Dim_PaymentStatus | Table | DWH_dbo | Denormalized payment status lookup (production origin: Dictionary.PaymentStatus) |
| DWH_dbo.Dim_FundingType | Table | DWH_dbo | Funding type name lookup (production origin: Dictionary.FundingType) |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Customer demographics: RegisteredReal, AffiliateID, CountryID, FunnelFromID, FunnelID (production origin: Customer.CustomerStatic) |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Country name + BIN country name lookups (production origin: Dictionary.Country) |
| DWH_dbo.Dim_Funnel | Table | DWH_dbo | Funnel name lookups — 3 joins: fbd.FunnelID, CC.FunnelFromID, CC.FunnelID (production origin: Dictionary.Funnel) |
| DWH_dbo.Dim_CardType | Table | DWH_dbo | Credit card type name lookup (production origin: Dictionary.CardType) |
| DWH_dbo.Dim_CountryBin | Table | DWH_dbo | BIN-to-country/card-subtype/card-category lookup |
| DWH_dbo.Dim_BillingDepot | Table | DWH_dbo | Depot/payment processor name lookup (production origin: Billing.Depot) |
| DWH_dbo.Dim_Affiliate + DWH_dbo.Dim_Channel | Table | DWH_dbo | Channel/SubChannel via AffiliateID->SubChannelID |
| BI_DB_dbo.External_etoro_Dictionary_RiskManagementStatus | External | BI_DB_dbo | Risk management status name lookup |
| BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | External | BI_DB_dbo | Marketing region name lookup |
| BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | External | BI_DB_dbo | FTD dates (FirstTimeDepositAttemptDate, FirstTimeDepositSuccessDate) |
| BI_DB_dbo.SP_H_Deposits | Stored Procedure | BI_DB_dbo | Writer SP (targets BI_DB_Deposits; creates #AdvancedDeposit_Ext temp with identical structure) |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | DepositID | Fact_BillingDeposit | DepositID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 2 | CID | Fact_BillingDeposit | CID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 3 | FundingID | Fact_BillingDeposit | FundingID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 4 | FundingType | Dim_FundingType | Name | Dim-lookup via External_etoro_Billing_Funding_Datafactory.FundingTypeID | Tier 2 — SP_H_Deposits code analysis |
| 5 | CurrencyID | Fact_BillingDeposit | CurrencyID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 6 | PaymentStatusID | Fact_BillingDeposit | PaymentStatusID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 7 | ManagerID | Fact_BillingDeposit | ManagerID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 8 | RiskManagementStatusID | Fact_BillingDeposit | RiskManagementStatusID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 9 | Amount | Fact_BillingDeposit | Amount | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 10 | ExchangeRate | Fact_BillingDeposit | ExchangeRate | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 11 | ModificationDate | Fact_BillingDeposit | ModificationDate | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 12 | TransactionID | Fact_BillingDeposit | TransactionIDAsString | Rename from Fact_BillingDeposit | Tier 2 — SP_H_Deposits code analysis |
| 13 | IPAddress | Fact_BillingDeposit | IPAddress | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 14 | Approved | Fact_BillingDeposit | Approved | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 15 | Commission | Fact_BillingDeposit | Commission | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 16 | PaymentDate | Fact_BillingDeposit | PaymentDate | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 17 | ClearingHouseEffectiveDate | Fact_BillingDeposit | ClearingHouseEffectiveDate | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 18 | OldPaymentID | (none) | — | Hardcoded NULL in SP | Tier 2 — SP_H_Deposits code analysis |
| 19 | IsFTD | Fact_BillingDeposit | IsFTD | Passthrough (type narrowing: int->bit) | Tier 2 — SP_H_Deposits code analysis |
| 20 | ProcessorValueDate | Fact_BillingDeposit | ProcessorValueDate | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 21 | RefundVerificationCode | Fact_BillingDeposit | RefundVerificationCode | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 22 | DepotID | Fact_BillingDeposit | DepotID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 23 | MatchStatusID | Fact_BillingDeposit | MatchStatusID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 24 | FunnelID | Fact_BillingDeposit | FunnelID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 25 | Code | (none) | — | Hardcoded NULL in SP | Tier 2 — SP_H_Deposits code analysis |
| 26 | ExTransactionID | Fact_BillingDeposit | ExTransactionID | Passthrough | Tier 2 — SP_H_Deposits code analysis |
| 27 | PaymentStatus_PaymentStatusID | Dim_PaymentStatus | PaymentStatusID | Dim-lookup on fbd.PaymentStatusID | Tier 2 — SP_H_Deposits code analysis |
| 28 | PaymentStatus_Name | Dim_PaymentStatus | Name | Dim-lookup on fbd.PaymentStatusID | Tier 2 — SP_H_Deposits code analysis |
| 29 | RiskManagementStatus_RiskManagementStatusID | External_etoro_Dictionary_RiskManagementStatus | RiskManagementStatusID | External table lookup on fbd.RiskManagementStatusID | Tier 2 — SP_H_Deposits code analysis |
| 30 | RiskManagementStatus_Name | External_etoro_Dictionary_RiskManagementStatus | Name | External table lookup on fbd.RiskManagementStatusID | Tier 2 — SP_H_Deposits code analysis |
| 31 | Channel | Dim_Channel | Channel | Dim-lookup via Dim_Affiliate.SubChannelID (joined on CC.AffiliateID) | Tier 2 — SP_H_Deposits code analysis |
| 32 | SubChannel | Dim_Channel | SubChannel | Dim-lookup via Dim_Affiliate.SubChannelID (joined on CC.AffiliateID) | Tier 2 — SP_H_Deposits code analysis |
| 33 | Region | External_etoro_Dictionary_MarketingRegion | Name | External table lookup via Dim_Country.MarketingRegionID | Tier 2 — SP_H_Deposits code analysis |
| 34 | Country | Dim_Country | Name | Dim-lookup via Dim_Customer.CountryID — customer registration country | Tier 2 — SP_H_Deposits code analysis |
| 35 | FirstDepositAttempt | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositAttemptDate | Rename from external table | Tier 2 — SP_H_Deposits code analysis |
| 36 | FirstDepositDate | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositSuccessDate | Rename from external table | Tier 2 — SP_H_Deposits code analysis |
| 37 | Registered | Dim_Customer | RegisteredReal | Dim-lookup rename | Tier 2 — SP_H_Deposits code analysis |
| 38 | SerialID | Dim_Customer | AffiliateID | Dim-lookup rename (DWH: AffiliateID; production origin: Customer.CustomerStatic.SerialID) | Tier 2 — SP_H_Deposits code analysis |
| 39 | Funnel | Dim_Funnel (df) | Name | Dim-lookup via fbd.FunnelID — deposit-level funnel | Tier 2 — SP_H_Deposits code analysis |
| 40 | FunnelFrom | Dim_Funnel (df2) | Name | Dim-lookup via Dim_Customer.FunnelFromID — customer's originating registration funnel | Tier 2 — SP_H_Deposits code analysis |
| 41 | AcquisitionFunnel | Dim_Funnel (df3) | Name | Dim-lookup via Dim_Customer.FunnelID — customer's current acquisition funnel | Tier 2 — SP_H_Deposits code analysis |
| 42 | BinCode | Fact_BillingDeposit | BinCodeAsString | Rename from Fact_BillingDeposit | Tier 2 — SP_H_Deposits code analysis |
| 43 | CreditCardType | Dim_CardType | CarTypeName | Dim-lookup via fbd.CardTypeIDAsInteger | Tier 2 — SP_H_Deposits code analysis |
| 44 | CardSubType | Dim_CountryBin | CardSubType | Dim-lookup via fbd.BinCodeAsString | Tier 2 — SP_H_Deposits code analysis |
| 45 | BINCountry | Dim_Country (dc3) | Name | Dim-lookup via fbd.BinCountryIDAsInteger — card-issuing bank country | Tier 2 — SP_H_Deposits code analysis |
| 46 | DepoName | Dim_BillingDepot | Name | Dim-lookup via fbd.DepotID | Tier 2 — SP_H_Deposits code analysis |
| 47 | CardCategory | Dim_CountryBin | CardCategory | Dim-lookup via fbd.BinCodeAsString | Tier 2 — SP_H_Deposits code analysis |

## Lineage Notes

- **TABLE IS DORMANT (0 rows)**. SP_H_Deposits creates `#AdvancedDeposit_Ext` temp table with identical 47-column structure (plus 5 extra: ResponseName, ResponseRN, Date, DateID, UpdateDate), then writes to `BI_DB_dbo.BI_DB_Deposits`, not this table.
- A backup cleanup script exists from 2024-11-17 (`BI_DB_AdvancedDeposit_Ext_Backup_20241117`), suggesting the table was active before that date.
- Column lineage is derived from SP_H_Deposits temp table construction, which matches this table's DDL exactly.
- The "_Ext" suffix indicates this was an extended/denormalized snapshot, superseded by `BI_DB_Deposits`.
- **All columns are Tier 2**: No upstream wiki was resolvable in the pre-resolved bundle. Tier 1 inheritance is impossible without a wiki to quote verbatim from. All descriptions are grounded in SP_H_Deposits code analysis and DDL structure.
