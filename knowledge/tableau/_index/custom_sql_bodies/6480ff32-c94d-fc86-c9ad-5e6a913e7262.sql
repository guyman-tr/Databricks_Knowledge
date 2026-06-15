SELECT StakingMonthID
        ,StakingMonth
        ,StakingYear
                ,r.CID
		,r.InstrumentID
		,null Cusip
		,null ApexID
                ,null Amount
		,r.Client_Airdrop as Units
		,hs.hedge_server as HedgeServerID
		,null Rate
		,NULL RateTime
		,11 AS OpenPositionActionType --AirDropType
		,NULL AdminPositionEventID --AirDropEventID
		,NULL AdminPositionRequestID --AirDropUniqueID
		,'FALSE' as ShouldHedge
		,'TRUE' AS IsFunded
		,'TRUE' AS CheckBalance
		,91 AS CompensationReasonID
		,'TRUE' AS ValidatePositionWorth
FROM Dealing_dbo.Dealing_Staking_Results_US r
left join [Dealing_staging].[External_Fivetran_dealing_staking_airdrop_hs] hs
on hs.instrument_id = r.InstrumentID
WHERE r.IsEligible = 1 
	AND r.OriginalCompensationType = 'Airdrop'