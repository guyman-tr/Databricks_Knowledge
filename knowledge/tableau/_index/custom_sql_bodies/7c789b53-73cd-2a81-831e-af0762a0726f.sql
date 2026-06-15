SELECT r.CID
        ,r.StakingMonthID
        ,r.StakingMonth
        ,r.StakingYear
		,r.RevShare
		,r.USD_Compensation as StakingRewards_USD
		,r.Currency
		,(1-r.RevShare) * r.Raw_Staking_Amount *s.USD_ConversionRate as Etoro_Revshare_USD
from Dealing_dbo.Dealing_Staking_Results  r
left join Dealing_dbo.Dealing_Staking_Summary s
on r.StakingMonthID = s.StakingMonthID and r.InstrumentID = s.InstrumentID
left join (select distinct CID, StakingMonthID, Country from Dealing_dbo.Dealing_Staking_Position) p
on p.CID = r.CID and p.StakingMonthID = r.StakingMonthID
where r.NonEligible_PrimaryReason = 'Waiver'
and p.Country = 'Singapore'