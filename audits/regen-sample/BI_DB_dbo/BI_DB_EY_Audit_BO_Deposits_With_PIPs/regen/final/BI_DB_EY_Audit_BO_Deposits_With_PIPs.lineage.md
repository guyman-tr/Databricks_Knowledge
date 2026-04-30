# Lineage: BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs

## Source Objects

| Source Object | Type | Schema | Role |
|---|---|---|---|
| External_etoro_History_Credit_Yesterday | External Table | BI_DB_dbo | Deposit population — History Credit rows with CreditTypeID=1 for the target date |
| External_etoro_Billing_Deposit | External Table | BI_DB_dbo | Core deposit record — amount, currency, status, payment dates, exchange rates, IDs |
| External_etoro_Billing_DepositRollbackTracking | External Table | BI_DB_dbo | Rollback tracking — TotalRollbackAmountInUSD/Currency for reversed deposits |
| Dim_Customer | Table | DWH_dbo | Customer dimension — ExternalID, LabelID, CountryIDByIP, RegulationID, PlayerLevelID, FirstName, LastName |
| Dim_Label | Table | DWH_dbo | White-label brand lookup — Name as WhiteLabel |
| Dim_Country | Table | DWH_dbo | Country dimension — Name as CountyByRegIP |
| Dim_Regulation | Table | DWH_dbo | Regulation lookup — Name as Regulation, also Name as MIDName via ProtocolMIDSettings |
| Dim_Funnel | Table | DWH_dbo | Funnel dimension — Name as Funnel |
| External_etoro_Billing_Funding_Datafactory | External Table | BI_DB_dbo | Funding instrument — FundingTypeID for BaseExchangeRate wire adjustment |
| Dim_Currency | Table | DWH_dbo | Currency/instrument dimension — Abbreviation as Currency |
| Dim_PaymentStatus | Table | DWH_dbo | Payment status lookup — Name as Status |
| External_etoro_Dictionary_Deposittype | External Table | BI_DB_dbo | Deposit type lookup — Description as DepositType |
| External_etoro_Billimg_ProtocolMIDSettings | External Table | BI_DB_dbo | MID settings — Description/Value as MID, RegulationID for MIDName |
| Fact_SnapshotCustomer | Table | DWH_dbo | Customer snapshot — IsCreditReportValidCB, CountryID (point-in-time via Dim_Range) |
| Dim_Range | Table | DWH_dbo | Date range helper — joins Fact_SnapshotCustomer for point-in-time CB validity |
| Fact_CustomerAction | Table | DWH_dbo | Customer action fact — CB-valid deposit comparison (ActionTypeID=7) |
| Fact_BillingDeposit | Table | DWH_dbo | Billing deposit fact — CardTypeIDAsInteger, BankNameAsString, DepotID, FundingTypeID |
| External_etoro_Billing_Depot | External Table | BI_DB_dbo | Depot lookup — Name as Depot |
| Dim_FundingType | Table | DWH_dbo | Funding type dimension — Name as FundingType |
| Dim_CardType | Table | DWH_dbo | Card type dimension — CarTypeName as CardType |
| External_etoro_Billing_ConversionFeeOverride | External Table | BI_DB_dbo | Conversion fee override — DepositFee as ConversionOverridePIPSConfig |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| ExternalID | DWH_dbo.Dim_Customer | ExternalID | Passthrough via JOIN on CID=RealCID | Tier 1 |
| CID | External_etoro_Billing_Deposit | CID | Passthrough (aliased from BDEP.CID) | Tier 1 |
| HCAmountUSD | External_etoro_History_Credit_Yesterday | TotalCashChange | Passthrough (hc.TotalCashChange) | Tier 2 |
| DepositID | External_etoro_Billing_Deposit | DepositID | Passthrough | Tier 1 |
| Amount | External_etoro_Billing_Deposit | Amount | CAST to DECIMAL(16,2) | Tier 1 |
| Currency | DWH_dbo.Dim_Currency | Abbreviation | Lookup via CurrencyID JOIN | Tier 1 |
| Status | DWH_dbo.Dim_PaymentStatus | Name | Lookup via PaymentStatusID JOIN | Tier 1 |
| PaymentDate | External_etoro_Billing_Deposit | PaymentDate | Passthrough | Tier 1 |
| ModificationDate | External_etoro_Billing_Deposit | ModificationDate | Passthrough | Tier 1 |
| ProcessorValueDate | External_etoro_Billing_Deposit | ProcessorValueDate | Passthrough | Tier 1 |
| IPAddress | External_etoro_Billing_Deposit | IPAddress | Converted via DWH_dbo.IPNumToIPAddress() UDF; empty string if NULL | Tier 2 |
| PaymentStatusID | External_etoro_Billing_Deposit | PaymentStatusID | Passthrough | Tier 1 |
| CurrencyID | External_etoro_Billing_Deposit | CurrencyID | Passthrough | Tier 1 |
| TotalRollbackUSDAmount | External_etoro_Billing_DepositRollbackTracking / External_etoro_History_Credit_Yesterday | TotalRollbackAmountInUSD / RollbackAmount | CASE: if rollback tracking exists use it; elif PaymentStatusID=2 then 0; else -1*RollbackAmount | Tier 2 |
| TotalRollbackAmount | External_etoro_Billing_DepositRollbackTracking / External_etoro_History_Credit_Yesterday | TotalRollbackAmountInCurrency / RollbackAmount | CASE: if rollback tracking exists use it; elif PaymentStatusID=2 then 0; else (-1*RollbackAmount)/ExchangeRate | Tier 2 |
| Funnel | DWH_dbo.Dim_Funnel | Name | Lookup via FunnelID JOIN | Tier 1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID = Dim_Regulation.DWHRegulationID | Tier 1 |
| WhiteLabel | DWH_dbo.Dim_Label | Name | Lookup via Dim_Customer.LabelID = Dim_Label.LabelID | Tier 1 |
| CountyByRegIP | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CountryIDByIP = Dim_Country.CountryID | Tier 1 |
| DepositType | External_etoro_Dictionary_Deposittype | Description | Lookup via DepositTypeID JOIN | Tier 2 |
| MIDName | DWH_dbo.Dim_Regulation | Name | Lookup via ProtocolMIDSettings.RegulationID = Dim_Regulation.DWHRegulationID | Tier 1 |
| MID | External_etoro_Billimg_ProtocolMIDSettings | Description / Value | ISNULL(Description, Value) | Tier 2 |
| TransactionID | External_etoro_Billing_Deposit | TransactionID | Passthrough | Tier 1 |
| ExTransactionID | External_etoro_Billing_Deposit | ExTransactionID | Passthrough | Tier 1 |
| ExchangeRate | External_etoro_Billing_Deposit | ExchangeRate | Passthrough | Tier 1 |
| BaseExchangeRate | External_etoro_Billing_Deposit | BaseExchangeRate | Passthrough | Tier 1 |
| ExchangeFee | External_etoro_Billing_Deposit | ExchangeFee | Passthrough | Tier 1 |
| ModificationDateID | External_etoro_Billing_Deposit | ModificationDate | ETL-computed: CAST(CONVERT(VARCHAR(8), ModificationDate, 112) AS INT) | Tier 2 |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Point-in-time lookup via Dim_Range on ModificationDate | Tier 1 |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Point-in-time lookup via Dim_Range on ModificationDate | Tier 1 |
| Depot | External_etoro_Billing_Depot | Name | Lookup via Fact_BillingDeposit.DepotID = Billing_Depot.DepotID | Tier 2 |
| FundingType | DWH_dbo.Dim_FundingType | Name | Lookup via Fact_BillingDeposit.FundingTypeID = Dim_FundingType.FundingTypeID | Tier 1 |
| BankNameAsString | DWH_dbo.Fact_BillingDeposit | BankNameAsString | Passthrough from Fact_BillingDeposit (XML-extracted field) | Tier 2 |
| CardType | DWH_dbo.Dim_CardType | CarTypeName | Lookup via Fact_BillingDeposit.CardTypeIDAsInteger = Dim_CardType.CardTypeID | Tier 1 |
| CustomerNameForWires | DWH_dbo.Dim_Customer | FirstName, LastName | CASE WHEN FundingType='WireTransfer' THEN FirstName + ' ' + LastName ELSE 'NA' | Tier 2 |
| ConversionOverridePIPSConfig | External_etoro_Billing_ConversionFeeOverride | DepositFee | Lookup via PlayerLevelID + CurrencyID + FundingTypeID | Tier 2 |
| Reciprocal | External_etoro_Billing_Deposit | CurrencyID | ETL-computed: CASE WHEN CurrencyID=1 THEN 1 ELSE 0 END | Tier 2 |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 |
| DateID | — | — | ETL-computed: @StartDateBO_Int (YYYYMMDD int of the processing date) | Tier 2 |
