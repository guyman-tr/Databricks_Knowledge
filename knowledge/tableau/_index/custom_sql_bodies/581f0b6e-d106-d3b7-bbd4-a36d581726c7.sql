SELECT
	dc.RealCID
	,dc.HasWallet
	,dc.VerificationLevelID
	,dc.RegisteredReal
	,c.Name as Country
	,r.Name as Regulation
	,r1.Name as DesignatedRegulation
	,ps.Name as PlayeStatus
	,pl.Name as PlayerLevel
	,psr.Name as PlayerStatusReason
	,pssr.PlayerStatusSubReasonName
	,p.PendingClosureStatusName
	,at.Name as AccountType
FROM
	DWH_dbo.Dim_Customer dc	
LEFT JOIN 
	DWH_dbo.Dim_Country c on c.CountryID = dc.CountryID
LEFT JOIN 
	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID
LEFT JOIN 
	DWH_dbo.Dim_Regulation r1 on r1.ID = dc.DesignatedRegulationID
LEFT JOIN 
	DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID = dc.PlayerStatusID
LEFT JOIN 
	DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN 
	DWH_dbo.Dim_PlayerStatusReasons psr on psr.PlayerStatusReasonID = dc.PlayerStatusReasonID
LEFT JOIN 
	DWH_dbo.Dim_PlayerStatusSubReasons pssr on pssr.PlayerStatusSubReasonID = dc.PlayerStatusSubReasonID
LEFT JOIN 
	DWH_dbo.Dim_PendingClosureStatus p on p.PendingClosureStatusID = dc.PendingClosureStatusID
LEFT JOIN 
	DWH_dbo.Dim_AccountType at on at.AccountTypeID = dc.AccountTypeID
WHERE 
	dc.PlayerStatusID in (2) -- Blocked
	and dc.PlayerStatusReasonID in (4) --Risk
	and dc.PlayerStatusSubReasonID in (4) -- Affiliate Fraud
	and dc.AccountTypeID not in (15,6) --NOT Affiliate Corporate or Affiliate Private