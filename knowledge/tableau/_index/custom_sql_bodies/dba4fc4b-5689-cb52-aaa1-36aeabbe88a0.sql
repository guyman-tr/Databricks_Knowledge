select pr.*,
dc.UserRegionID StateCode, dc.UserRegion_State as State, dc.Regulation
, dc.ComplianceClosureEvent 

 from EXW_dbo.EXW_WalletUsers_30_Days pr with (NOLOcK)
	LEFT JOIN EXW_dbo.EXW_DimUser   dc with (NOLOcK)
		ON pr.RealCID = dc.RealCID