select
bc.RealCID as CID,
l.Liabilities + l.ActualNWA AS TotalEquity,  ----Total Equity
ev.EvMatchStatusName,
dc.Name as Country,
fd.LastLoggedIn,
CASE WHEN bc.IsIDProof=1 THEN 'yes' ELSE 'no' END AS 'IsIDProof',
CASE WHEN bc.IsAddressProof=1 THEN 'yes' ELSE 'no' END AS 'IsAddressProof',
pcs.PendingClosureStatusName,
dr.Name as DesignatedRegulation,
bc.VerificationLevelID,
ps.Name as PlayerStatus,
pl.Name as PlayerLevel,
dss.Name as PEPCheck,
bc.IsDepositor

from DWH_dbo.Dim_Customer bc
join DWH_dbo.Dim_PlayerStatus ps on bc.PlayerStatusID=ps.PlayerStatusID
left join DWH_dbo.Dim_EvMatchStatus ev on bc.EvMatchStatus=ev.EvMatchStatusID
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dss.ScreeningStatusID=bc.ScreeningStatusID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=bc.PlayerLevelID
join DWH_dbo.Dim_Country dc on dc.CountryID=bc.CountryID
join DWH_dbo.Dim_Regulation dr on dr.ID=bc.DesignatedRegulationID
LEFT JOIN DWH_dbo.Dim_PendingClosureStatus pcs ON pcs.PendingClosureStatusID=bc.PendingClosureStatusID
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd ON bc.RealCID=fd.CID
left join DWH_dbo.V_Liabilities l on l.CID=bc.RealCID and DateID = CONVERT(VARCHAR(6), getdate()-1, 112)  --always put yesterdays date
WHERE bc.VerificationLevelID=3
AND bc.PlayerStatusID=13 --PendingVerification
AND bc.AccountTypeID=1--Private