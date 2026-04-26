# BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout — Column Lineage

## Writer SP

`BI_DB_dbo.SP_AffiliatesPaidAndCashout` (Priority 0, Daily, SB_Daily)

## Source Objects

| Source Object | Role |
|--------------|------|
| BI_DB_dbo.BI_DB_MarketingMonthlyRawData | Affiliate cost data (Channel='Affiliate', TotalCost<>0) |
| DWH_dbo.Dim_Affiliate | Affiliate details (AffiliatesGroupsName, Contact, WebSiteURL, Email, TradingAccount_RealCID) |
| DWH_dbo.Dim_Country | Country name lookup |
| DWH_dbo.Fact_BillingWithdraw | Withdrawal transactions (CashoutStatusID_Funding=3, CashoutStatusID_Withdraw=3) |
| DWH_dbo.Dim_Customer | Customer validation (IsValidCustomer=1) |
| DWH_dbo.Dim_FundingType | Funding type name (FundingTypeID_Funding) |
| DWH_dbo.Dim_AccountType | Account type name |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Passthrough |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Passthrough |
| WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | WithdrawPaymentID | Passthrough |
| Amount_WithdrawToFunding | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding | Passthrough |
| FTFundingType | DWH_dbo.Dim_FundingType | Name | Passthrough via FundingTypeID_Funding JOIN |
| AccountType | DWH_dbo.Dim_AccountType | Name | Passthrough via Dim_Customer.AccountTypeID |
| YearMonth | DWH_dbo.Fact_BillingWithdraw | ModificationDate | CONVERT(VARCHAR(6), ModificationDate, 112) — YYYYMM |
| AffiliateID | BI_DB_MarketingMonthlyRawData | AffiliateID | Passthrough via affiliate match |
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Passthrough |
| Contact | DWH_dbo.Dim_Affiliate | Contact | Passthrough |
| WebSiteURL | DWH_dbo.Dim_Affiliate | WebSiteURL | Passthrough |
| Email | DWH_dbo.Dim_Affiliate | Email | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via MarketingMonthlyRawData.CountryID |
| UpdateDate | — | — | ETL metadata: GETDATE() |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.
