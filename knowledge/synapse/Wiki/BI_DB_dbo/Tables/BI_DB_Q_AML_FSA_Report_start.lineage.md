# Column Lineage: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Primary — quarterly customer snapshot | RegulationID=9, IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3 |
| DWH_dbo.Dim_Range | DWH_dbo | Date range filter | fsc.DateRangeID = dr.DateRangeID AND @StartDateID BETWEEN dr.FromDateID AND dr.ToDateID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name | fsc.PlayerStatusID = dps.PlayerStatusID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name (FSA) | fsc.RegulationID = dr1.DWHRegulationID AND RegulationID=9 |
| DWH_dbo.Dim_Country | DWH_dbo | Country, Region, Desk, EU | fsc.CountryID = dc.CountryID |
| DWH_dbo.Dim_AccountType | DWH_dbo | Account type name | fsc.AccountTypeID = dat.AccountTypeID |
| DWH_dbo.Dim_Customer | DWH_dbo | BirthDate, ScreeningStatusID, PlayerStatusReasonID | fsc.RealCID = dc1.RealCID |
| DWH_dbo.Dim_MifidCategorization | DWH_dbo | MiFID categorization name | fsc.MifidCategorizationID = dmc.MifidCategorizationID |
| DWH_dbo.Dim_ScreeningStatus | DWH_dbo | Screening status name | dc1.ScreeningStatusID = dss.ScreeningStatusID |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | Player status reason name | fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | Player status sub-reason name | fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID |
| BI_DB_dbo.External_etoro_BackOffice_Customer | BI_DB_dbo | SeychellesCategorizationID | cc.CID = fsc.RealCID, cc.Verified=1 |
| DWH_dbo.Dim_Position | DWH_dbo | Position activity (open/close) | dp.CID = pop.CID |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Deposit/cashout activity | fca.RealCID = pop.CID, ActionTypeID IN (7,8) |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | High net worth (Q11) | bdkp.RealCID = pop.CID, Q11_AnswerID=38 |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Unrealized equity | bdppl.CID = pop.CID, DateID=@EndDateID |
| DWH_dbo.V_Liabilities | DWH_dbo | Realized equity | vl.CID = pop.CID, DateID=@EndDateID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | rename (RealCID → CID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup passthrough (RegulationID=9 filter) |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup passthrough |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons | Name | dim-lookup passthrough |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | dim-lookup passthrough |
| EU | DWH_dbo.Dim_Country | EU | passthrough |
| Desk | DWH_dbo.Dim_Country | Desk | passthrough |
| Region | DWH_dbo.Dim_Country | Region | passthrough |
| RiskGroupID | DWH_dbo.Fact_SnapshotCustomer | RiskGroupID | passthrough |
| SeychellesCategorization | BI_DB_dbo.External_etoro_BackOffice_Customer | SeychellesCategorizationID | CASE: 2='Advanced', else 'Basic' |
| Account_Type_Group | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| Account_Type | DWH_dbo.Dim_AccountType | Name | dim-lookup passthrough |
| Age_Group | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, @Date) bucketed into bands |
| Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, @Date) |
| MifidCategorization | DWH_dbo.Dim_MifidCategorization | Name | dim-lookup passthrough |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | dim-lookup passthrough |
| Is_PEP | DWH_dbo.Dim_Customer | ScreeningStatusID | CASE: 3=1, else 0 |
| Is_Closed_Account | DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.Dim_Customer | PlayerStatusID, PlayerStatusReasonID | CASE: PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40) |
| Is_Suspended_Account | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | CASE: NOT IN (1,2,4,5) = 1 |
| Is_Seychelles_Investor | DWH_dbo.Fact_SnapshotCustomer | CountryID | CASE: 181=1 |
| Is_United_States_Investor | DWH_dbo.Fact_SnapshotCustomer | CountryID | CASE: 219=1 |
| Is_EU_Investor | DWH_dbo.Dim_Country | EU | CASE: EU=1 → 1 |
| Is_Other_Country_Investor | (computed) | — | residual: EU=0 AND CountryID<>219 AND CountryID<>181 |
| OpenedOrClosedPos | DWH_dbo.Dim_Position | CID | EXISTS check: any open/close during quarter |
| DepositesOrCashout | DWH_dbo.Fact_CustomerAction | CID | EXISTS check: ActionTypeID IN (7,8) during quarter |
| Is_Active | (computed) | — | OpenedOrClosedPos=1 OR DepositesOrCashout=1 |
| Is_High_Net_Worth | BI_DB_dbo.BI_DB_KYC_Panel | Q11_AnswerID | CASE: 38=1 (Over $1M) |
| UnrealizedEquity | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount + PositionPnL) at quarter end |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | SUM at quarter end |
| Report_Start_Date | (computed) | — | @StartDateID = quarter-start YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() at SP execution |

## Writer SP

- **SP**: `BI_DB_dbo.SP_Q_AML_FSA_Report`
- **Pattern**: DELETE + INSERT per quarter (WHERE Report_Start_Date = @StartDateID)
- **Shared with**: BI_DB_Q_AML_FSA_Report_end, BI_DB_Q_AML_FSA_Report_end_Market_Value, BI_DB_Q_AML_FSA_Report_end_Positions, BI_DB_Q_AML_FSA_Report_end_InvestorType
