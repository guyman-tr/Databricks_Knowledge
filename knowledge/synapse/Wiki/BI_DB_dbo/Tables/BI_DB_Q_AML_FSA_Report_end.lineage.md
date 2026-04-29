# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Q_AML_FSA_Report` — quarterly TRUNCATE+INSERT (FSA Seychelles, RegulationID=9)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Primary — quarterly customer snapshot base (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3) |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer demographics and identifiers |
| DWH_dbo.Dim_Country | DWH_dbo | Dim-lookup — Country name, EU flag, Region, Desk from CountryID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Dim-lookup — Regulation name from RegulationID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Dim-lookup — PlayerStatus name from PlayerStatusID |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | Dim-lookup — PlayerStatusReasons name from PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | Dim-lookup — PlayerStatusSubReasonName from PlayerStatusSubReasonID |
| DWH_dbo.Dim_AccountType | DWH_dbo | Dim-lookup — AccountTypeGroupID for Account_Type_Group classification |
| DWH_dbo.Dim_MifidCategorization | DWH_dbo | Dim-lookup — MifidCategorization name |
| DWH_dbo.Dim_ScreeningStatus | DWH_dbo | Dim-lookup — ScreeningStatus name, ScreeningStatusID for PEP flag |
| BI_DB_dbo.External_etoro_BackOffice_Customer | BI_DB_dbo | SeychellesCategorizationID for Advanced/Basic classification |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | High Net Worth flag (Q11_AnswerID=38) |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | UnrealizedEquity = SUM(Amount+PositionPnL) at quarter end |
| DWH_dbo.V_Liabilities | DWH_dbo | RealizedEquity = SUM at quarter end |
| DWH_dbo.Dim_Position | DWH_dbo | Open/close position activity during quarter |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Deposit/cashout activity during quarter |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | rename (RealCID → CID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup passthrough (RegulationID=9 filter) |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup passthrough (JOIN on CountryID) |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup passthrough (JOIN on PlayerStatusID) |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons | Name | dim-lookup passthrough (JOIN on PlayerStatusReasonID) |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | Name | dim-lookup passthrough (JOIN on PlayerStatusSubReasonID) |
| EU | DWH_dbo.Dim_Country | EU | passthrough (1=EU member, 0=non-EU) |
| Desk | DWH_dbo.Dim_Country | Desk | passthrough — Tier 3 regional desk assignment |
| Region | DWH_dbo.Dim_Country | Region | passthrough — Tier 2 geographic region |
| RiskGroupID | DWH_dbo.Fact_SnapshotCustomer | RiskGroupID | passthrough |
| SeychellesCategorization | External_etoro_BackOffice_Customer | SeychellesCategorizationID | CASE: 2='Advanced', ELSE 'Basic' |
| Account_Type_Group | DWH_dbo.Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', ELSE 'Other' |
| Account_Type | DWH_dbo.Dim_AccountType | Name | dim-lookup passthrough |
| Age_Group | (computed from Dim_Customer) | BirthDate | CASE: 18-25, 26-35, 36-45, 46-55, 56-65, 66+, N/A |
| Age | (computed from Dim_Customer) | BirthDate | DATEDIFF(year, BirthDate, Report_End_Date) |
| MifidCategorization | DWH_dbo.Dim_MifidCategorization | Name | dim-lookup passthrough |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | dim-lookup passthrough |
| Is_PEP | DWH_dbo.Dim_ScreeningStatus | ScreeningStatusID | CASE: 3=1, ELSE 0 |
| Is_Closed_Account | (computed) | PlayerStatusID, PlayerStatusReasonID | CASE: PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40) = 1, ELSE 0 |
| Is_Suspended_Account | (computed) | PlayerStatusID | CASE: PlayerStatusID NOT IN (1,2,4,5) = 1, ELSE 0 |
| Is_Seychelles_Investor | DWH_dbo.Dim_Country | CountryID | CASE: CountryID=181 THEN 1 ELSE 0 |
| Is_United_States_Investor | DWH_dbo.Dim_Country | CountryID | CASE: CountryID=219 THEN 1 ELSE 0 |
| Is_EU_Investor | DWH_dbo.Dim_Country | EU | CASE: EU=1 THEN 1 ELSE 0 |
| Is_Other_Country_Investor | (computed) | — | CASE: NOT Seychelles AND NOT US AND NOT EU THEN 1 ELSE 0 |
| OpenedOrClosedPos | DWH_dbo.Dim_Position | CID | 1 if opened or closed a position during the quarter, else 0 |
| DepositesOrCashout | DWH_dbo.Fact_CustomerAction | CID | 1 if deposit or cashout during the quarter, else 0 |
| Is_Active | (computed) | — | CASE: OpenedOrClosedPos=1 OR DepositesOrCashout=1 THEN 1 ELSE 0 |
| Is_High_Net_Worth | BI_DB_dbo.BI_DB_KYC_Panel | Q11_AnswerID | CASE: Q11_AnswerID=38 (Over $1M) THEN 1 ELSE 0 |
| UnrealizedEquity | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount + PositionPnL) at quarter end date |
| RealizedEquity | DWH_dbo.V_Liabilities | — | SUM at quarter end date |
| Report_End_Date | (computed) | — | Quarter end date (e.g., 20240331, 20260331) |
| UpdateDate | (computed) | — | GETDATE() — ETL execution timestamp |

**PHASE 10B CHECKPOINT: PASS**
