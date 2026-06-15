select
	bc.RealCID as CID,
	bc.GCID,
	l.Liabilities + l.ActualNWA AS TotalEquity,  ----Total Equity
	ev.EvMatchStatusName,
	dds.DocumentStatusName,
	dc.Name as Country,
	bc.RegisteredReal,
	dpcs.PendingClosureStatusName,
	dr.Name as DesignatedRegulation,
	bc.VerificationLevelID,
	ps.Name as PlayerStatus,
	dss.Name as Screening,
	dpv.PhoneVerifiedName,
	bc.IsDepositor,
	bc.IsEmailVerified,
	fd.LastLoggedIn,
	CASE WHEN bc.IsIDProof=1 THEN 'yes' ELSE 'no' END AS 'IsIDProof',
	CASE WHEN bc.IsAddressProof=1 THEN 'yes' ELSE 'no' END AS 'IsAddressProof',
	pl.Name as PlayerLevel,
	CASE WHEN A.CID IS NOT NULL THEN 'Active Alert' ELSE 'No Active Alert' END AS [Alerts]
from	DWH_dbo.Dim_Customer bc
join DWH_dbo.Dim_PlayerStatus ps on bc.PlayerStatusID=ps.PlayerStatusID
left join DWH_dbo.Dim_EvMatchStatus ev on bc.EvMatchStatus=ev.EvMatchStatusID
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dss.ScreeningStatusID=bc.ScreeningStatusID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=bc.PlayerLevelID
left join DWH_dbo.Dim_Country dc on dc.CountryID=bc.CountryID
left join DWH_dbo.Dim_Regulation dr on dr.ID=bc.DesignatedRegulationID
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd ON bc.RealCID=fd.CID
LEFT JOIN DWH_dbo.Dim_DocumentStatus dds ON dds.DocumentStatusID=bc.DocumentStatusID
LEFT JOIN DWH_dbo.Dim_PhoneVerified dpv ON dpv.PhoneVerifiedID=bc.PhoneVerifiedID
left join DWH_dbo.V_Liabilities l on l.CID=bc.RealCID and DateID = CONVERT(VARCHAR(8), getdate()-1, 112)  --always put yesterdays date
LEFT JOIN DWH_dbo.Dim_PendingClosureStatus dpcs ON dpcs.PendingClosureStatusID=bc.PendingClosureStatusID
JOIN [BI_DB_dbo].[BI_DB_RiskAlertManagementTool] A ON A.CID=bc.RealCID and  A.StatusType IN ('Active') AND A.AlertType IN (
'HighRiskLogin',
'RiskRelations',
'CreditCardBruteForce',
'FundingStolenReportedByProcessor')
WHERE 
bc.VerificationLevelID=2 AND 
ev.EvMatchStatusName IN ('Verified')
AND dds.DocumentStatusName  IN ('None')
AND dss.Name IN ('NoMatch')
AND dpv.PhoneVerifiedName IN ('AutomaticallyVerified')