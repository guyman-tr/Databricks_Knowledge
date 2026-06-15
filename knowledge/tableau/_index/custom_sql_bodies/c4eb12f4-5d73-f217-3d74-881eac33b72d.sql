Select 
	k.EffectiveAddDate
	,k.Country
	,k.DesignatedRegulation
	,k.Regulation
	,sum(case when k.VerificationLevelID = 3 and k.HoursToVerify <= 24 then 1 end) as 'Verification in SLA'
	,sum(case when k.VerificationLevelID = 3 then 1 else 0 end) as 'verified'
	,count(k.RealCID) as CountCID
	,sum(case when k.FirstTouchHour <= 1 then 1 else 0 end) as '1st TouchHour'

FROM 
	#kyc k
GROUP BY 
	k.EffectiveAddDate
	,k.Country
	,k.DesignatedRegulation
	,k.Regulation