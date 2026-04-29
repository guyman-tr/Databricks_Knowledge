# Column Lineage: BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report

## Source Objects

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Fact_SnapshotCustomer | Fact | Core population: VL3, IsValidCustomer=1, RegulationID IN (7,8), PlayerLevelID IN (2,6,7) |
| DWH_dbo.Dim_Customer | Dimension | PII data: FirstName, MiddleName, LastName, BirthDate, HasWallet, FirstDepositDate, RegisteredReal, ScreeningStatusID, POBCountryID |
| DWH_dbo.Dim_Range | Dimension | DateRangeID decode for current-state filtering |
| DWH_dbo.Dim_Regulation | Dimension | RegulationID-to-Name (FinCEN, FinCEN+FINRA) |
| DWH_dbo.Dim_Country | Dimension | CountryID-to-Name (Country + POB_Country) |
| DWH_dbo.Dim_PlayerLevel | Dimension | PlayerLevelID-to-Name (Club tier: Platinum/Platinum Plus/Diamond) |
| DWH_dbo.Dim_PlayerStatus | Dimension | PlayerStatusID-to-Name |
| DWH_dbo.Dim_PlayerStatusReasons | Dimension | PlayerStatusReasonID-to-Name |
| DWH_dbo.Dim_PlayerStatusSubReasons | Dimension | PlayerStatusSubReasonID-to-Name |
| DWH_dbo.Dim_AccountType | Dimension | AccountTypeID-to-Name |
| DWH_dbo.Dim_ScreeningStatus | Dimension | ScreeningStatusID-to-Name |
| DWH_dbo.Dim_EvMatchStatus | Dimension | EvMatchStatus-to-Name |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | External Table | Risk classification: RiskScoreName='High' filter + RiskScore_Explanation |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB Table | KYC questionnaire answers: Q18 (Occupation), Q14 (Planned Investment) |
| DWH_dbo.Fact_CustomerAction | Fact | Total deposits (ActionTypeID=7), activity flags (deposits/cashouts/trades/logins in last 365 days) |
| BI_DB_dbo.BI_DB_AML_Documents_Request | BI_DB Table | Document status: POI, POA, Proof of Income, Selfie, VideoIdent |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | BI_DB Table | Last player status change date |
| DWH_dbo.V_Liabilities | View | Equity calculation (Liabilities + ActualNWA) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (aliased) |
| Report_Date | ETL | @EndDateID | End of previous quarter (YYYYMMDD int) |
| FirstName | DWH_dbo.Dim_Customer | FirstName | Passthrough |
| MiddleName | DWH_dbo.Dim_Customer | MiddleName | Passthrough |
| Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) |
| LastName | DWH_dbo.Dim_Customer | LastName | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim lookup passthrough |
| Country | DWH_dbo.Dim_Country | Name | Dim lookup passthrough (via fsc.CountryID) |
| POB_Country | DWH_dbo.Dim_Country | Name | Dim lookup passthrough (via dc1.POBCountryID) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim lookup passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Dim lookup passthrough |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons | Name | Dim lookup passthrough |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Passthrough |
| Account_Type | DWH_dbo.Dim_AccountType | Name | Dim lookup passthrough |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Dim lookup passthrough |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | Dim lookup passthrough |
| IsDepositor | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | Passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough |
| RiskScoreName | External_RiskClassification | RiskScoreName | Passthrough (always 'High' due to JOIN filter) |
| RiskScore_Explanation | External_RiskClassification | RiskScore_Explanation | Passthrough |
| Q18_Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | Passthrough (aliased) |
| Q14_Planned_Invested_Amount | BI_DB_dbo.BI_DB_KYC_Panel | Q14_AnswerText | Passthrough (aliased) |
| Total_Deposits | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 |
| Has_POI | BI_DB_dbo.BI_DB_AML_Documents_Request | Has_POI | ISNULL passthrough (default 0) |
| POI_ExpiryDate | BI_DB_dbo.BI_DB_AML_Documents_Request | POI_ExpiryDate | Passthrough |
| Has_POA | BI_DB_dbo.BI_DB_AML_Documents_Request | Has_POA | ISNULL passthrough (default 0) |
| POA_ExpiryDate | BI_DB_dbo.BI_DB_AML_Documents_Request | POA_ExpiryDate | Passthrough |
| Has_Proof_of_Income | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentType_POIncome, SuggestedDocumentType_POIncome | CASE: 1 if either is NOT NULL |
| DocumentDateAdded_POIncome | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | Passthrough |
| Has_Selfie | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentType_Selfie, SuggestedDocumentType_Selfie | CASE: 1 if either is NOT NULL |
| DocumentDateAdded_Selfie | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_Selfie | Passthrough |
| Has_VideoIdent | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentType_VideoIdent, SuggestedDocumentType_VideoIdent | CASE: 1 if either is NOT NULL |
| DocumentDateAdded_VideoIdent | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_VideoIdent | Passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata |
| Last_PlayerStatus_Change_Date | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Change_Date | Most recent change (ROW_NUMBER=1), excluding Current_ID IN (2,4) and Previous_ID=0 |
| Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) |
| Active_Dep_or_CO | DWH_dbo.Fact_CustomerAction | — | CASE: 1 if customer had deposit/cashout activity in last 365 days (CategoryID IN 8,4) |
| Active_Trade_or_Loggedin | DWH_dbo.Fact_CustomerAction | — | CASE: 1 if customer had trade/login activity in last 365 days (CategoryID IN 13,17,18) |
