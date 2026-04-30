# Column Lineage — BI_DB_dbo.BI_DB_Deposits

## Source Objects

| Source Object | Type | Role | Wiki |
|---|---|---|---|
| DWH_dbo.Fact_BillingDeposit | Table | Primary deposit fact source | [Fact_BillingDeposit.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingDeposit.md) |
| DWH_dbo.Dim_PaymentStatus | Table | Payment status lookup | [Dim_PaymentStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PaymentStatus.md) |
| DWH_dbo.Dim_Funnel | Table | Funnel name lookup (3 joins) | [Dim_Funnel.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Funnel.md) |
| DWH_dbo.Dim_FundingType | Table | Funding type name lookup | [Dim_FundingType.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_FundingType.md) |
| DWH_dbo.Dim_Customer | Table | Customer demographics | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| DWH_dbo.Dim_Country | Table | Country name lookup (2 joins) | [Dim_Country.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md) |
| DWH_dbo.Dim_CardType | Table | Card type name lookup | [Dim_CardType.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CardType.md) |
| DWH_dbo.Dim_CountryBin | Table | BIN card sub-type/category | [Dim_CountryBin.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryBin.md) |
| DWH_dbo.Dim_BillingDepot | Table | Depot name lookup | [Dim_BillingDepot.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingDepot.md) |
| DWH_dbo.Dim_Affiliate | Table | Affiliate channel/subchannel | [Dim_Affiliate.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Affiliate.md) |
| DWH_dbo.Dim_Channel | Table | Channel classification | [Dim_Channel.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Channel.md) |
| BI_DB_dbo.External_etoro_Dictionary_RiskManagementStatus | External | Risk management status lookup | — |
| BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | External | FTD attempt/success dates | — |
| BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | External | Marketing region name | — |
| BI_DB_dbo.External_etoro_History_DepositAction_Yesterday | External | Response name (latest action) | — |
| BI_DB_dbo.External_etoro_Dictionary_Response | External | Response name lookup | — |
| BI_DB_dbo.External_etoro_Billing_Funding_Datafactory | External | FundingTypeID resolution | — |

## Column Lineage

| BI_DB Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| DepositID | Fact_BillingDeposit | DepositID | Passthrough | Tier 1 — Billing.Deposit |
| CID | Fact_BillingDeposit | CID | Passthrough | Tier 1 — Billing.Deposit |
| FundingID | Fact_BillingDeposit | FundingID | Passthrough | Tier 1 — Billing.Deposit |
| FundingType | Dim_FundingType | Name | Dim-lookup via Funding.FundingTypeID | Tier 1 — Dictionary.FundingType |
| CurrencyID | Fact_BillingDeposit | CurrencyID | Passthrough | Tier 1 — Billing.Deposit |
| PaymentStatusID | Fact_BillingDeposit | PaymentStatusID | Passthrough | Tier 1 — Billing.Deposit |
| ManagerID | Fact_BillingDeposit | ManagerID | Passthrough | Tier 1 — Billing.Deposit |
| RiskManagementStatusID | Fact_BillingDeposit | RiskManagementStatusID | Passthrough | Tier 1 — Billing.Deposit |
| Amount | Fact_BillingDeposit | Amount | Passthrough (capped in upstream ETL) | Tier 1 — Billing.Deposit |
| ExchangeRate | Fact_BillingDeposit | ExchangeRate | Passthrough | Tier 1 — Billing.Deposit |
| ModificationDate | Fact_BillingDeposit | ModificationDate | Passthrough | Tier 1 — Billing.Deposit |
| TransactionID | Fact_BillingDeposit | TransactionIDAsString | Rename (XML-extracted field) | Tier 2 — SP_H_Deposits |
| IPAddress | Fact_BillingDeposit | IPAddress | Passthrough | Tier 1 — Billing.Deposit |
| Approved | Fact_BillingDeposit | Approved | Passthrough | Tier 1 — Billing.Deposit |
| Commission | Fact_BillingDeposit | Commission | Passthrough | Tier 1 — Billing.Deposit |
| PaymentDate | Fact_BillingDeposit | PaymentDate | Passthrough | Tier 1 — Billing.Deposit |
| ClearingHouseEffectiveDate | Fact_BillingDeposit | ClearingHouseEffectiveDate | Passthrough | Tier 1 — Billing.Deposit |
| OldPaymentID | — | — | Hardcoded NULL | Tier 2 — SP_H_Deposits |
| IsFTD | Fact_BillingDeposit | IsFTD | Passthrough | Tier 1 — Billing.Deposit |
| ProcessorValueDate | Fact_BillingDeposit | ProcessorValueDate | Passthrough | Tier 1 — Billing.Deposit |
| RefundVerificationCode | Fact_BillingDeposit | RefundVerificationCode | Passthrough | Tier 1 — Billing.Deposit |
| DepotID | Fact_BillingDeposit | DepotID | Passthrough | Tier 1 — Billing.Deposit |
| MatchStatusID | Fact_BillingDeposit | MatchStatusID | Passthrough | Tier 1 — Billing.Deposit |
| FunnelID | Fact_BillingDeposit | FunnelID | Passthrough | Tier 1 — Billing.Deposit |
| Code | — | — | Hardcoded NULL | Tier 2 — SP_H_Deposits |
| ExTransactionID | Fact_BillingDeposit | ExTransactionID | Passthrough | Tier 1 — Billing.Deposit |
| PaymentStatus_PaymentStatusID | Dim_PaymentStatus | PaymentStatusID | Dim-lookup on fbd.PaymentStatusID | Tier 1 — Dictionary.PaymentStatus |
| PaymentStatus_Name | Dim_PaymentStatus | Name | Dim-lookup on fbd.PaymentStatusID | Tier 1 — Dictionary.PaymentStatus |
| RiskManagementStatus_RiskManagementStatusID | External_etoro_Dictionary_RiskManagementStatus | RiskManagementStatusID | Dim-lookup on fbd.RiskManagementStatusID | Tier 2 — SP_H_Deposits |
| RiskManagementStatus_Name | External_etoro_Dictionary_RiskManagementStatus | Name | Dim-lookup on fbd.RiskManagementStatusID | Tier 2 — SP_H_Deposits |
| Channel | Dim_Affiliate + Dim_Channel | Channel | JOIN Dim_Affiliate ON SerialID → Dim_Channel ON SubChannelID | Tier 2 — SP_H_Deposits |
| SubChannel | Dim_Affiliate + Dim_Channel | SubChannel | JOIN Dim_Affiliate ON SerialID → Dim_Channel ON SubChannelID | Tier 2 — SP_H_Deposits |
| Region | External_etoro_Dictionary_MarketingRegion | Name | Dim-lookup via Dim_Country.MarketingRegionID | Tier 2 — SP_H_Deposits |
| Country | Dim_Country | Name | Dim-lookup via Dim_Customer.CountryID | Tier 1 — Dictionary.Country |
| FirstDepositAttempt | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositAttemptDate | Rename | Tier 2 — SP_H_Deposits |
| FirstDepositDate | External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstTimeDepositSuccessDate | Rename | Tier 2 — SP_H_Deposits |
| Registered | Dim_Customer | RegisteredReal | Dim-lookup via CID=RealCID | Tier 1 — Customer.CustomerStatic |
| SerialID | Dim_Customer | AffiliateID | Dim-lookup via CID=RealCID, aliased back to SerialID | Tier 1 — Customer.CustomerStatic |
| Funnel | Dim_Funnel | Name | Dim-lookup on fbd.FunnelID | Tier 1 — Dictionary.Funnel |
| FunnelFrom | Dim_Funnel | Name | Dim-lookup on CC.FunnelFromID | Tier 1 — Dictionary.Funnel |
| AcquisitionFunnel | Dim_Funnel | Name | Dim-lookup on CC.FunnelID | Tier 1 — Dictionary.Funnel |
| BinCode | Fact_BillingDeposit | BinCodeAsString | Rename (XML-extracted field) | Tier 2 — SP_H_Deposits |
| CreditCardType | Dim_CardType | CarTypeName | Dim-lookup on fbd.CardTypeIDAsInteger | Tier 1 — Dictionary.CardType |
| CardSubType | Dim_CountryBin | CardSubType | Dim-lookup on fbd.BinCodeAsString | Tier 2 — SP_H_Deposits |
| CardCategory | Dim_CountryBin | CardCategory | Dim-lookup on fbd.BinCodeAsString | Tier 2 — SP_H_Deposits |
| BINCountry | Dim_Country | Name | Dim-lookup on fbd.BinCountryIDAsInteger | Tier 1 — Dictionary.Country |
| DepoName | Dim_BillingDepot | Name | Dim-lookup on fbd.DepotID | Tier 1 — Billing.Depot |
| ResponseName | External_etoro_Dictionary_Response | ResponseName | Dim-lookup via History_DepositAction.ResponseID | Tier 2 — SP_H_Deposits |
| ResponseRN | — | — | ROW_NUMBER() OVER (PARTITION BY DepositID ORDER BY hda.ModificationDate DESC) | Tier 2 — SP_H_Deposits |
| Date | Fact_BillingDeposit | ModificationDate | Cast to date | Tier 2 — SP_H_Deposits |
| DateID | Fact_BillingDeposit | ModificationDateID | Passthrough | Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse |
| UpdateDate | — | — | GETDATE() at SP execution | Tier 2 — SP_H_Deposits |
