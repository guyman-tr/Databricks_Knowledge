# Lineage: BI_DB_dbo.BI_DB_PaymentSent_Results

## Source Objects

| Source Object | Type | Schema | Role |
|--------------|------|--------|------|
| External_etoro_Billing_Withdraw | External Table | BI_DB_dbo | Base withdrawal records (CID, WithdrawID) |
| External_etoro_Billing_vWithdrawToFunding | External Table | BI_DB_dbo | Withdraw-to-funding details (Amount, ProcessCurrencyID, FundingID, CashoutStatusID, DepotID) |
| External_etoro_History_vWithdrawToFundingAction | External Table | BI_DB_dbo | History of withdraw-to-funding actions for Payment Sent status timing |
| External_etoro_Billing_Funding_Datafactory | External Table | BI_DB_dbo | Funding records (filtered to FundingTypeID=2, Wires only) |
| External_etoro_Billing_Depot | External Table | BI_DB_dbo | Depot/provider name lookup |
| Dim_Customer | Table | DWH_dbo | Customer dimension (JOIN for RegulationID) |
| Dim_Currency | Table | DWH_dbo | Currency/instrument dimension (Abbreviation for ProcessCurrencyID) |
| Dim_CashoutStatus | Table | DWH_dbo | Cashout status dimension (used in intermediate filter) |
| Dim_FundingType | Table | DWH_dbo | Funding type dimension (used in FundingTypeID=2 filter) |
| Dim_Regulation | Table | DWH_dbo | Regulation dimension (Name for Regulation column) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| CID | External_etoro_Billing_Withdraw | CID | Passthrough | Tier 1 — Customer.CustomerStatic |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID | Tier 1 — Dictionary.Regulation |
| Currency | Dim_Currency | Abbreviation | Dim-lookup passthrough via wtf.ProcessCurrencyID | Tier 1 — Dictionary.Currency |
| Amount$Withdraw | External_etoro_Billing_vWithdrawToFunding | Amount | Rename (Amount -> Amount$Withdraw) | Tier 2 — External_etoro_Billing_vWithdrawToFunding |
| DaysInPaymentSentStatus | External_etoro_History_vWithdrawToFundingAction | ModificationDate | Computed: CAST(GETDATE() - MAX(ModificationDate) AS int) | Tier 2 — External_etoro_History_vWithdrawToFundingAction |
| ModificationDate | External_etoro_History_vWithdrawToFundingAction | ModificationDate | Aggregated: MAX(ModificationDate) for CashoutStatusID=6 | Tier 2 — External_etoro_History_vWithdrawToFundingAction |
| WithdrawID | External_etoro_Billing_Withdraw | WithdrawID | Passthrough | Tier 2 — External_etoro_Billing_Withdraw |
| WithdrawProcessingID | External_etoro_Billing_vWithdrawToFunding | ID | Rename (ID -> WithdrawProcessingID) | Tier 2 — External_etoro_Billing_vWithdrawToFunding |
| FundingID | External_etoro_Billing_vWithdrawToFunding | FundingID | Passthrough | Tier 2 — External_etoro_Billing_vWithdrawToFunding |
| Provider | External_etoro_Billing_Depot | Name | Rename (Name -> Provider) | Tier 2 — External_etoro_Billing_Depot |
| UpdateDate | SP_H_PaymentSent_Results | - | GETDATE() at load time | Tier 2 — SP_H_PaymentSent_Results |
