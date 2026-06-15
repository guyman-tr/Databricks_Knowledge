SELECT DISTINCT 
	v.RealCID
	,v.RegisteredDate
	,v.VerificationLevel1Date
	,v.VerificationLevel2Date
	,v.EvMatchStatusDate
	,v.VerificationDate
	,v.DateAdded
	,v.Occurred
	,EOMONTH(v.EffectiveAddDate) as EffectiveAddDate
	,v.FirstDepositDate
	,v.FirstReviewed
	,v.FirstTouch
	,v.FirstTouchHour
	,v.FirstTouchMinute
	,v.DaysToVerify
	,v.MinutesToVerify
	,v.HoursToVerify
	,v.VerificationLevelID
    ,dc.[PlayerStatusID]
    ,dc.[PendingClosureStatusID]
    ,dc.[PlayerStatusReasonID]
	,v.EvMatchStatus
	,v.VerificationMethod
	,v.KYCFlow
    ,dc1.[Region]
    ,[Regulation]
    ,dc.IsDepositor
    ,dc1.[RiskGroupID]
	,dr.Name as DesignatedRegulation
	,dc1.Name as Country
FROM
	BI_DB_dbo.BI_DB_OPS_KYC_Verification v 
join 
	DWH_dbo.Dim_Customer dc on dc.RealCID=v.RealCID
join 
	DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
LEFT JOIN 
	DWH_dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID