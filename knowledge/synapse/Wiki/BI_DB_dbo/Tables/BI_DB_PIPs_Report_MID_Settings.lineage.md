# Lineage: BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings

## Source Objects

| Source Object | Schema | Type | Relationship |
|--------------|--------|------|-------------|
| BI_DB_DepositWithdrawFee | BI_DB_dbo | Table | Deposit transactions — provides DepositWithdrawID, CID, TransactionType, RegulationID, Depot, MIDValue, DateID |
| Fact_BillingDeposit | DWH_dbo | Table | Deposit billing metadata — DepotID, FundingTypeID, ProtocolMIDSettingsID, MerchantAccountID, CurrencyID, FundingID |
| Fact_BillingWithdraw | DWH_dbo | Table | Withdraw transactions — WithdrawPaymentID, DepotID, ProtocolMIDSettingsID, FundingTypeID_Funding, DepositID, ModificationDate_WithdrawToFunding |
| Fact_CustomerAction | DWH_dbo | Table | Withdraw history — filters ActionTypeID=8 (cashout) for WithdrawPaymentID matching |
| Fact_SnapshotCustomer | DWH_dbo | Table | Customer snapshot — RegulationID, CountryID, LabelID for MID routing |
| Dim_Range | DWH_dbo | Table | Date range lookup for Fact_SnapshotCustomer DateRangeID resolution |
| Dim_BillingProtocolMIDSettingsID | DWH_dbo | Table | MID routing configuration — Value, Description, DepotID, RegulationID |
| Dim_Regulation | DWH_dbo | Table | Regulation name resolution — DWHRegulationID to Name mapping |
| External_eToro_Dictionary_MerchantAccount | BI_DB_dbo | External Table | Merchant account names and BODescription for MID resolution |
| External_eToro_Billing_MerchantAccountRouting | BI_DB_dbo | External Table | Merchant account routing rules by depot, regulation, currency |
| External_eToro_Dictionary_MapMerchantCodeToMid | BI_DB_dbo | External Table | MerchantCode-to-MID mapping with currency and regulation |
| External_etoro_billing_vWithdrawToFunding_Alltime | BI_DB_dbo | External Table | WithdrawToFunding details for withdraw MID resolution |
| External_Etoro_History_WithdrawToFundingAction | Dealing_staging | External Table | Withdraw processing action history — MerchantAccountID, FundingID |
| etoro_History_WithdrawToFundingAction | DWH_staging | Staging Table | Withdraw action history for MerchantAccountID resolution (ROW_NUMBER by ModificationDate) |

## Column Lineage

| Target Column | Source Column(s) | Source Object(s) | Transform |
|--------------|-----------------|-----------------|-----------|
| Date | @StartDate parameter | SP_PIPs_Report_MID_Settings | SP input parameter passed as literal |
| DateID | @StartDate parameter | SP_PIPs_Report_MID_Settings | CONVERT(VARCHAR(8), @StartDate, 112) |
| TransactionID | DepositWithdrawID / WithdrawPaymentID | BI_DB_DepositWithdrawFee / Fact_BillingWithdraw | CAST(DepositID AS VARCHAR(20)) + 'D' for deposits; CAST(WithdrawPaymentID AS VARCHAR(20)) + 'W' for withdraws |
| MIDName | Multiple: ProtocolMIDSettingsID.Description, MerchantAccount.BODescription, Dim_Regulation.Name, DepotID-based CASE | Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / MerchantAccountRouting / Dim_Regulation | Complex CASE resolution: FundingTypeID=2 uses BPMS Description; DepotID IN (78,79,80,4,75,86) uses MerchantAccount BODescription; else COALESCE(DMA.BODescription, ma.BODescription, BillingGetMerchantDetail, Regulation.Name). Fallback maps regulation to entity name (eToroEU/eToroUK/eToroAU/eToroUS). Withdraws use similar logic with depot-based CASE. |
| MID | Multiple: ProtocolMIDSettingsID.Value, MerchantAccount.Name, MapMerchantCodeToMid.MID | Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / Dictionary.MapMerchantCodeToMid | Complex CASE resolution: FundingTypeID=2 uses BPMS Value; DepotID IN (78,79,80,4,75,86) uses MerchantAccount Name; else COALESCE(DMA.Name, ma.Name, BPMS.Description, BMMC.MID, BPMS.Value). Withdraws use similar depot-based CASE with additional Checkout/Wire/eToroMoney patterns. |
| ActionType | Literal | SP_PIPs_Report_MID_Settings | Literal 'Deposit' or 'Withdraw' based on UNION branch |
| UpdateDate | GETDATE() | SP_PIPs_Report_MID_Settings | Row load timestamp |
