# Column Lineage: BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|---------------|
| BI_DB_dbo.External_etoro_BackOffice_Customer | BI_DB_dbo | Master-sub account relationship | bc.CID / bc.MasterAccountCID |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes (PII, VL, status, regulation) | dc.RealCID = mf.CID |
| DWH_dbo.Dim_Country | DWH_dbo | Country name (x3: Country, POB, Citizenship) | dc1/dc2/dc3.CountryID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name (x2) | dr/dr1.ID = dc.RegulationID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name | ps.PlayerStatusID |
| DWH_dbo.Dim_AccountType | DWH_dbo | Account type name | at1.AccountTypeID |
| DWH_dbo.Dim_RiskStatus | DWH_dbo | Risk status name | rcs.RiskStatusID |
| DWH_dbo.Dim_RiskClassification | DWH_dbo | Risk classification name | rc.RiskClassificationID |
| DWH_dbo.Dim_ScreeningStatus | DWH_dbo | Screening status name | ds1.ScreeningStatusID |
| DWH_dbo.Dim_PendingClosureStatus | DWH_dbo | Pending closure status name | pcs.PendingClosureStatusID |
| DWH_dbo.Fact_BillingDeposit | DWH_dbo | Total deposits | bd.CID, PaymentStatusID=2 |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Total compensations | ca.RealCID, ActionTypeID=36 |
| DWH_dbo.Fact_BillingWithdraw | DWH_dbo | Withdrawals + pending | bd.CID |
| DWH_dbo.Fact_BillingRedeem | DWH_dbo | Lifetime redeems | fca.CID, RedeemStatusID=8 |
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | DWH_dbo | PendingClosureDate | fsc.RealCID |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | KYC questionnaire (Q2-Q26) | kycp.RealCID |
| BI_DB_dbo.External_UserApiDB_dbo_V_CustomerAnswers | BI_DB_dbo | Additional KYC (Q12/Q32/Q150) | kycans.GCID |
| BI_DB_dbo.External_BackOffice_CustomerDocument | BI_DB_dbo | Selfie doc check | cd.CID |
| BI_DB_dbo.External_ScreeningService | BI_DB_dbo | Screening date | SC.CID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| CID | External_etoro_BackOffice_Customer | CID/MasterAccountCID | Passthrough (UNION ALL) |
| MasterAccountCID | External_etoro_BackOffice_Customer | MasterAccountCID | Passthrough |
| AccountType | -- | -- | ETL-computed: CASE Master/SubAccount |
| TotalDeposits | Fact_BillingDeposit | AmountUSD | SUM WHERE PaymentStatusID=2 |
| Q2_Experience | BI_DB_KYC_Panel | Q2_Experience | Passthrough |
| Q2_AnswerText | BI_DB_KYC_Panel | Q2_AnswerText | Passthrough |
| Q3-Q26 columns | BI_DB_KYC_Panel | Corresponding columns | Passthrough |
| Name | Dim_Customer | FirstName + LastName | ETL-computed: concatenation |
| Address/BirthDate/Gender/Phone | Dim_Customer | Same | Passthrough |
| Country | Dim_Country | Name | Dim-lookup via CountryID |
| POB | Dim_Country | Name | Dim-lookup via POBCountryID |
| Citizenship | Dim_Country | Name | Dim-lookup via CitizenshipCountryID |
| VerificationLevelID | Dim_Customer | VerificationLevelID | Passthrough (filtered IN 2,3) |
| Regulation/DesignatedRegulation | Dim_Regulation | Name | Dim-lookup |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup |
| AccountTypeBO | Dim_AccountType | Name | Dim-lookup |
| RiskStatus | Dim_RiskStatus | Name | Dim-lookup |
| RiskClassificationName | Dim_RiskClassification | RiskClassificationName | Dim-lookup |
| ScreeningStatus | Dim_ScreeningStatus | Name | Dim-lookup |
| PendingClosureStatusName | Dim_PendingClosureStatus | PendingClosureStatusName | Dim-lookup |
| PendingClosureStatusID/ScreeningStatusID | Dim_Customer | Same | Passthrough |
| TotalCompensation | Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=36, Amount>0 |
| TotalAmountDepositsAndCompensations | Multiple | Deposits + Compensations | COALESCE sum |
| TotalRedeemsLifetime | Fact_BillingRedeem | AmountOnClose | SUM WHERE RedeemStatusID=8 |
| TotalWithdraws | Fact_BillingWithdraw | Amount_WithdrawToFunding | SUM excl crypto |
| TotalPendingWithdraws | Fact_BillingWithdraw | Amount_Withdraw | SUM recent pending |
| HasSelfie | External BackOffice docs | DocumentTypeID | 1 when 15/18/23 exist |
| PendingClosureDate | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN date |
| ScreeningDate | External_ScreeningService | BeginTime | MIN matching status |
| Q26_Sources_of_Funds/Q26_AnswerText | BI_DB_KYC_Panel | Same | Passthrough |
| Q32_PEP_MM_Question | BI_DB_KYC_Panel | Same | Passthrough |
| Q150_AnswerText/Q12_AnswerText/Q32_AnswerText | V_CustomerAnswers | AnswerText | Latest per GCID via DENSE_RANK |
| UpdateDate | -- | -- | GETDATE() |
