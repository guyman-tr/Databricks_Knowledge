Select 
	c.*,
	ps.PendingClosureStatusName as PendingClosureStatus,
	dr.Name AS Regualation,
	drd.Name as DesignatedRegulation,dc.VerificationLevelID
from 
	#details c
join 
	DWH_dbo.Dim_Customer dc on dc.RealCID=c.RealCID
LEFT JOIN 
	DWH_dbo.Dim_Regulation dr ON dr.ID=dc.RegulationID
LEFT JOIN 
	DWH_dbo.Dim_Regulation drd ON drd.ID=dc.DesignatedRegulationID
LEFT JOIN 
	DWH_dbo.Dim_PendingClosureStatus ps on ps.PendingClosureStatusID=dc.PendingClosureStatusID
where 
	AccountType IN ('SMSF','Corporate','Trust')
	and dc.PlayerStatusID not in (2,4)
	and dc.PendingClosureStatusID not in (3)