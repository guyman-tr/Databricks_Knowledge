# BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement — Column Lineage

## Writer SP

`BI_DB_dbo.SP_Daily_HighCashoutEmailsForManagement` (Priority 0, Daily, SB_Daily)

## Source Objects

| Source Object | Role |
|--------------|------|
| DWH_dbo.Fact_BillingWithdraw | Withdrawal requests (RequestDate >= yesterday, FundingTypeID_Withdraw<>27, CashoutStatusID_Withdraw NOT IN 3,4) |
| DWH_dbo.Dim_Customer | Customer demographics (CountryID, BirthDate, VerificationLevelID, AccountManagerID, RegulationID, PlayerStatusID) |
| DWH_dbo.Dim_Country | Country name |
| DWH_dbo.Dim_Regulation | Regulation name |
| DWH_dbo.Dim_PlayerStatus | Customer status name |
| DWH_dbo.Dim_FundingType | Funding type name |
| DWH_dbo.Dim_ClientWithdrawReason | Withdraw reason name |
| DWH_dbo.Dim_CashoutReason | Cashout reason name |
| DWH_dbo.Dim_Manager | Account manager name |
| DWH_dbo.Dim_Position | CommissionOnClose (revenues) |
| DWH_dbo.V_Liabilities | BonusCredit (NWA), Liabilities+ActualNWA (Equity), Credit (Balance) |
| DWH_dbo.Fact_CustomerAction | ActionTypeID=36 (compensation) |
| BI_DB_dbo.External_etoro_BackOffice_Customer | AMLComment, RiskComment |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | Selfie document check (DocumentTypeID=15) |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | Document type mapping |
| BI_DB_dbo.BI_DB_UsageTracking_SF | SalesForce call tracking (Phone_Call_Succeed__c, last 12 months) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | DWH_dbo.Fact_BillingWithdraw | RequestDate | CAST(RequestDate AS DATE) |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Passthrough |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Passthrough |
| CO Amount | — | — | SUM(Amount_Withdraw) per CID — total cashout amount (filtered to >=50K) |
| ClientWithdrawReason | DWH_dbo.Dim_ClientWithdrawReason | ClientWithdrawReasonName | ISNULL(...,'n/a') |
| RequestorComments | — | — | Always NULL in DDL — column exists but not populated by SP |
| Category | — | — | CASE: 50K-100K='50K TO 100K', 100K-250K='100K to 250k', >=250K='>250K' |
| Country | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryID |
| Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(year, BirthDate, GETDATE()) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.RegulationID |
| AMLComment | External_etoro_BackOffice_Customer | AMLComment | ISNULL(...,'') |
| RiskComment | External_etoro_BackOffice_Customer | RiskComment | ISNULL(...,'') |
| ProvidedSelfie | External_etoro_BackOffice_CustomerDocument | — | 'Yes' if DocumentTypeID=15 exists, else 'No' |
| WasContactedLast12Months | BI_DB_UsageTracking_SF | — | 'yes' if Phone_Call_Succeed__c in last 12 months, else 'no' |
| Account Manager | DWH_dbo.Dim_Manager | FirstName + LastName | From SF contact or Dim_Customer.AccountManagerID fallback |
| NWA | DWH_dbo.V_Liabilities | BonusCredit | ISNULL(BonusCredit,0) |
| Revenues | DWH_dbo.Dim_Position | CommissionOnClose | SUM(CommissionOnClose) per CID |
| CustomerStatus | DWH_dbo.Dim_PlayerStatus | Name | Via Dim_Customer.PlayerStatusID |
| Verification | DWH_dbo.Dim_Customer | VerificationLevelID | CASE WHEN =3 THEN 'Verified' ELSE 'Not Verified' |
| ExpiredPOI | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | 'yes' if expired, 'no' otherwise |
| CompensationAmount | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=36 |
| UpdateDate | — | — | ETL metadata: GETDATE() |
| Amount_Withdraw | DWH_dbo.Fact_BillingWithdraw | Amount_Withdraw | Passthrough (per-WithdrawID amount) |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Computed sum |
| Balance | DWH_dbo.V_Liabilities | Credit | Passthrough |
| FundingType | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID_Withdraw |
| CashoutReason | DWH_dbo.Dim_CashoutReason | Name | Via CashoutReasonID |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.
