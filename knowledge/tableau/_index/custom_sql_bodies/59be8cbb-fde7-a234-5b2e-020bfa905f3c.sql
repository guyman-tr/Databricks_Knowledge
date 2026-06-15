select s.*,c.IsDepositor,pl.Name as PlayerLevel

from  
	BI_DB_dbo.[BI_DB_OPS_VerificationLevel2Stuck] s
left join 
	DWH_dbo.Dim_Customer c on c.RealCID = s.CID
LEFT JOIN DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID = c.PlayerLevelID