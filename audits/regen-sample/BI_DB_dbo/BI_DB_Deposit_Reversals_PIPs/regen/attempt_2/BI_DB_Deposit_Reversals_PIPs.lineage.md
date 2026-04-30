# Lineage: BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs

## Source Objects

| Source Object | Schema | Type | Relationship |
|---|---|---|---|
| Fact_BillingDeposit | DWH_dbo | Table | Primary deposit data (amount, currency, exchange rate, funding, depot, card, MID) |
| Fact_CustomerAction | DWH_dbo | Table | Historical deposit status reconstruction (ActionTypeID 7,11,12,13,43) |
| Fact_SnapshotCustomer | DWH_dbo | Table | Customer attributes at event date (regulation, label, player level, status, validity) |
| Dim_Range | DWH_dbo | Table | Snapshot date range resolution |
| Dim_Customer | DWH_dbo | Table | Customer ExternalID, CountryIDByIP, AccountManagerID |
| Dim_PaymentStatus | DWH_dbo | Table | Payment status name resolution |
| Dim_Label | DWH_dbo | Table | Label name resolution |
| Dim_VerificationLevel | DWH_dbo | Table | Verification level name |
| Dim_PlayerLevel | DWH_dbo | Table | Player level / club name |
| Dim_PlayerStatus | DWH_dbo | Table | Player status name |
| Dim_FundingType | DWH_dbo | Table | Payment method name |
| Dim_Currency | DWH_dbo | Table | Currency abbreviation |
| Dim_Country | DWH_dbo | Table | Country name (registration, IP, BIN) |
| Dim_Manager | DWH_dbo | Table | Account manager details |
| Dim_BillingDepot | DWH_dbo | Table | Depot name |
| Dim_BillingProtocolMIDSettingsID | DWH_dbo | Table | MID settings (Value, Description, DepotID) |
| Dim_Regulation | DWH_dbo | Table | Regulation name |
| Dim_CardType | DWH_dbo | Table | Card type name |
| BI_DB_DepositWithdrawFee | BI_DB_dbo | Table | PIPsCalculation for deposit rows |
| External_eToro_Dictionary_MerchantAccount | BI_DB_dbo | External Table | Merchant account name/BODescription |
| External_eToro_Dictionary_MapMerchantCodeToMid | BI_DB_dbo | External Table | MerchantCode-to-MID mapping |
| External_etoro_history_credit_yesterday | BI_DB_dbo | External Table | History credit rows for reversal CreditTypeIDs (11,12,16,32) |
| External_etoro_Billing_DepositRollbackTracking | BI_DB_dbo | External Table | Rollback tracking (amount, date, reason, status) |
| External_eToro_Dictionary_DepositRollbackTypeReason | BI_DB_dbo | External Table | Rollback reason name |
| External_eToro_Billing_FundingPaymentDetailsForWithdraw | BI_DB_dbo | External Table | Funding payment details (FundingTypeID) |
| External_eToro_Billing_MerchantAccountRouting | BI_DB_dbo | External Table | Merchant account routing rules |

## Column Lineage

| Target Column | Source Object | Source Column | Transform |
|---|---|---|---|
| DateID | ETL-computed | @BeginDateID | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| CID | Fact_BillingDeposit / Fact_SnapshotCustomer | CID / RealCID | Passthrough |
| DepositWithdrawID | Fact_BillingDeposit | DepositID | Passthrough (renamed) |
| Occurred | ETL-computed | DepositStatusModificationTime | CASE WHEN rollback CreateDate IS NOT NULL THEN CreateDate ELSE credit.Occurred END |
| CreditTypeID | External_etoro_history_credit_yesterday | CreditTypeID | Passthrough |
| TransactionID | Fact_BillingDeposit | DepositID | CAST(DepositID AS VARCHAR(20)) + 'D' |
| Date | ETL-computed | @BeginDate | Parameter date |
| Customer | Dim_Customer | ExternalID | Passthrough |
| TransactionType | ETL-computed | DepositStatus + PreviousStatus | Complex CASE matrix mapping (current, previous) to transaction type name |
| PaymentMethod | Dim_FundingType | Name | Dim-lookup passthrough via FundingID to FundingPaymentDetails to Dim_FundingType |
| Amount | External_etoro_Billing_DepositRollbackTracking | RollbackAmountInCurrency | Passthrough (rollback amount in original currency) |
| Currency | Dim_Currency | Abbreviation | Dim-lookup passthrough via CurrencyID |
| ExchangeRate | Fact_BillingDeposit | ExchangeRate | Passthrough (BDEP.ExchangeRate only) |
| AmountUSD | External_etoro_Billing_DepositRollbackTracking / External_etoro_history_credit_yesterday | RollbackAmountInUSD / ReturnedAmount | COALESCE(RollbackAmountInUSD, ReturnedAmount) |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Passthrough via snapshot |
| LabelID | Fact_SnapshotCustomer | LabelID | Passthrough via snapshot |
| PlayerLevelID | Fact_SnapshotCustomer | PlayerLevelID | Passthrough via snapshot |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough |
| Label | Dim_PlayerLevel | Name | Note: SP maps Label column to Dim_PlayerLevel.Name (not Dim_Label) |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough via snapshot |
| UpdateDate | ETL-computed | GETDATE() | ETL timestamp |
| BaseExchangeRate | Fact_BillingDeposit | BaseExchangeRate | Passthrough |
| ExchangeFee | External_etoro_Billing_DepositRollbackTracking | ExchangeFee | Passthrough (named ConversionFee in SP) |
| ExternalTransactionID | External_etoro_Billing_DepositRollbackTracking / Fact_BillingDeposit | ReferenceNumber / RefundVerificationCode | COALESCE(ReferenceNumber, RefundVerificationCode) |
| Depot | Dim_BillingDepot | Name | Dim-lookup passthrough via DepotID |
| MIDValue | ETL-computed | MID | Complex CASE: FundingTypeID=2 to BPMSValue; DepotID IN (78,79,80,4,75,86) to maName; ELSE COALESCE chain |
| Club | Dim_PlayerLevel | Name | Dim-lookup passthrough |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough |
| PIPsCalculation | BI_DB_DepositWithdrawFee + ETL-computed | PIPsCalculation x PIPsRatio | ROUND(DW_fee.PIPsCalculation, 2) * ROUND(RollbackAmountInCurrency / Amount, 32) |
| RegCountry | Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID |
| RegCountryByIP | Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryIDByIP |
| CardType | Dim_CardType | CarTypeName | Dim-lookup passthrough via Fact_BillingDeposit.CardTypeIDAsInteger |
| CardCategory | Fact_BillingDeposit | CardCategory | Passthrough |
| BinCountry | Dim_Country | Name | Dim-lookup passthrough via Fact_BillingDeposit.BinCountryIDAsInteger |
| MOPCountry | ETL-computed | 'NA' | Hardcoded literal 'NA' |
| IsGermanBaFin | ETL-computed | NULL | Hardcoded NULL |
| Entity | ETL-computed | MIDName | Complex CASE: FundingTypeID=2 to BPMSDescription; DepotID IN (78,79,80,4,75,86) to maBODescription; ELSE COALESCE chain |
