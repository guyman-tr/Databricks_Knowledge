SELECT 
dc.RealCID AS 'CID'
,dc.GCID
,CASE WHEN dc.IsValidCustomer	= 1 THEN 'Yes' ELSE 'No' END AS 'ValidCustomer'
,CASE WHEN dc.IsCreditReportValidCB = 1 THEN 'Yes' ELSE 'No' END AS 'CreditReportValidCB'
,CAST(dc.RegisteredReal AS DATE) AS 'Registration_Date'
,CAST(dc.FirstDepositDate AS DATE) AS 'FTD_Date'	
,reg.Name AS 'Regulation'
,dat.Name AS 'Account_Type'
,dps.Name AS 'Account_Status'
,plv.Name AS 'Player_Club'

,CASE WHEN ISNULL(dc.PlayerStatusReasonID,0) = 0 THEN 'No' ELSE 'Yes' END AS 'HasAMLComments'
,dpsr.Name AS 'AML_Comments'
,dpssr.PlayerStatusSubReasonName AS 'AML_Comments_Description'

,bdrc.RiskScoreName AS 'Risk_Classification'
,pep.PEPStatusDesc AS 'PEP_Screening' 

FROM DWH.dbo.Dim_Customer dc WITH(NOLOCK)

INNER JOIN DWH.dbo.Dim_Regulation reg WITH(NOLOCK) ON dc.RegulationID = reg.DWHRegulationID 
INNER JOIN DWH.dbo.Dim_AccountType dat WITH(NOLOCK) ON dc.AccountTypeID = dat.AccountTypeID
INNER JOIN DWH.dbo.Dim_PlayerStatus dps WITH(NOLOCK) ON dc.PlayerStatusID = dps.PlayerStatusID
INNER JOIN DWH.dbo.Dim_PlayerLevel plv WITH(NOLOCK) ON dc.PlayerLevelID = plv.PlayerLevelID

LEFT JOIN DWH.dbo.Dim_PlayerStatusReasons dpsr WITH(NOLOCK) ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH.dbo.Dim_PlayerStatusSubReasons dpssr WITH(NOLOCK) ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID

LEFT JOIN BI_DB.dbo.BI_DB_RiskClassification bdrc WITH(NOLOCK) ON dc.RealCID = bdrc.CID
LEFT JOIN BI_DB.dbo.BI_DB_Compliance_PEP_Check pep WITH(NOLOCK) ON dc.RealCID = pep.CID

WHERE dc.RealCID IN (<[Parameters].[Parameter 1]>)