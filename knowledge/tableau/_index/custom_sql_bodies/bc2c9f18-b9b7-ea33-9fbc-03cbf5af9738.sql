SELECT StakingMonth
	  ,StakingYear
	  ,StakingMonthID
	  ,Currency
	  ,CID
	  ,COUNT(DISTINCT PositionID) Position_Count
	  ,Total_USD
	  ,Regulation
	  ,PlayerStatus
            ,PlayerLevel
	  ,CASE WHEN PlayerLevel IN ('Silver','Gold','Platinum') THEN 'Silver, Gold & Platinum'
				WHEN PlayerLevel IN ('Diamond','Platinum Plus') THEN 'Diamond & Platinum Plus'
				ELSE PlayerLevel
			END AS ClubCategory
	  ,IsClientEligible
	  ,CASE WHEN Total_USD <1 THEN 1 ELSE 0 END IsLessThan1USD
	  ,IsEligibleCountry
	  ,IsCashEquivalentCountry
	  ,IsEtorian
	  ,IsRegulationEligible
	  ,IsAML_Restricted
	  ,IsAccountStatusEligible
	  ,IsWaiver
	  ,IsPI
FROM Dealing_dbo.Dealing_Staking_Position_US
GROUP BY StakingMonth
	  ,StakingYear
	  ,StakingMonthID
	  ,Currency
	  ,CID
	  ,Total_USD
	  ,Regulation
	  ,PlayerStatus
	  ,PlayerLevel
            ,CASE WHEN PlayerLevel IN ('Silver','Gold','Platinum') THEN 'Silver, Gold & Platinum'
				WHEN PlayerLevel IN ('Diamond','Platinum Plus') THEN 'Diamond & Platinum Plus'
				ELSE PlayerLevel
			END
	  ,IsClientEligible
	  ,CASE WHEN Total_USD <1 THEN 1 ELSE 0 END 
	  ,IsEligibleCountry
	  ,IsCashEquivalentCountry
	  ,IsEtorian
	  ,IsRegulationEligible
	  ,IsAML_Restricted
	  ,IsAccountStatusEligible
	  ,IsWaiver
	  ,IsPI