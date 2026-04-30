# Lineage: BI_DB_dbo.BI_DB_EY_Audit_CashoutReason

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| DWH_dbo.Fact_BillingWithdraw | Table | Primary withdrawal fact — WithdrawID, CID, WithdrawPaymentID, CashoutReasonID, ModificationDate_WithdrawToFunding, FundingTypeID_Funding |
| DWH_dbo.Dim_CashoutReason | Table | Lookup — CashoutReasonID → Name (CashoutReason) |
| DWH_dbo.Fact_SnapshotCustomer | Table | Point-in-time customer attributes — CountryID, PlayerLevelID, GuruStatusID, AccountTypeID |
| DWH_dbo.Dim_Range | Table | Date range decode — bridges Fact_SnapshotCustomer.DateRangeID to ModificationDateID |
| DWH_dbo.Dim_Country | Table | Lookup — CountryID → Name (Country) |
| DWH_dbo.Dim_PlayerLevel | Table | Lookup — PlayerLevelID → Name (Club) |
| DWH_dbo.Dim_GuruStatus | Table | Lookup — GuruStatusID → GuruStatusName |
| DWH_dbo.Dim_AccountType | Table | Lookup — AccountTypeID → Name (AccountType) |
| DWH_dbo.Dim_FundingType | Table | Lookup — FundingTypeID_Funding → Name (FundingType) |
| DWH_dbo.Dim_Customer | Table | Customer master — ExternalID |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Passthrough | Tier 1 — Billing.Withdraw |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Passthrough | Tier 1 — Billing.Withdraw |
| WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | WithdrawPaymentID | Passthrough | Tier 1 — Billing.WithdrawToFunding |
| ModificationDate_WithdrawToFunding_DateID | DWH_dbo.Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | CAST(CONVERT(VARCHAR(10), CAST(ModificationDate_WithdrawToFunding AS DATE), 112) AS INT) | Tier 2 — Fact_BillingWithdraw |
| CashoutReasonID | DWH_dbo.Fact_BillingWithdraw | CashoutReasonID | Passthrough | Tier 1 — Billing.Withdraw |
| CashoutReason | DWH_dbo.Dim_CashoutReason | Name | Dim-lookup passthrough (renamed Name → CashoutReason) | Tier 1 — Dictionary.CashoutReason |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID (renamed Name → Country) | Tier 1 — Dictionary.Country |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID (renamed Name → Club) | Tier 1 — Dictionary.PlayerLevel |
| GuruStatusName | DWH_dbo.Dim_GuruStatus | GuruStatusName | Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID | Tier 1 — Dictionary.GuruStatus |
| AccountType | DWH_dbo.Dim_AccountType | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.AccountTypeID (renamed Name → AccountType) | Tier 1 — Dictionary.AccountType |
| ExternalID | DWH_dbo.Dim_Customer | ExternalID | Passthrough via Dim_Customer (joined on Fact_SnapshotCustomer.RealCID) | Tier 1 — Customer.CustomerStatic |
| FundingType | DWH_dbo.Dim_FundingType | Name | Dim-lookup passthrough via Fact_BillingWithdraw.FundingTypeID_Funding (renamed Name → FundingType) | Tier 1 — Dictionary.FundingType |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 — SP_EY_Audit_Automation_CashoutReason |
