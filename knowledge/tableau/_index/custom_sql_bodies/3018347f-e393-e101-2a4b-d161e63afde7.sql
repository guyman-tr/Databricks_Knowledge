select a.*, 
LEFT(CONVERT(varchar(10), dateadd(day,-1, cast(a.last_day as date)),112), 6) as last_dayID,
(pc.AskLast+pc.BidLast)/2 as USDprice,
    case when EligibleUsersAbove1USD = 0 then 0 else UsersRewardsAbove1USD/EligibleUsersAbove1USD end as AvgUsersRewardsAbove1USD,
    case when EligibleUsersBelow1USD = 0 then 0 else UsersRewardsBelow1USD/EligibleUsersBelow1USD end as AvgUsersRewardsBelow1USD
FROM
    (
        select ppp.first_day, ppp.last_day, su.SplitEtoroUnits, su.SplitUserUnits, ppp.Asset, ppp.Club, ppp.Create_Date, ppp.staking_month, ppp.staking_monthID,
                ppp.Rewards/su.SplitUserUnits as OriginRewards,
                count(Distinct ppp.GCID) as EligibleUsers, 
                --count(Distinct case when w.IsWaiver = 1 then ppp.GCID else NULL end) as EligibleUsersWaiver,
count(Distinct case when w.IsWaiver = 1 and ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 then ppp.GCID else NULL end) as EligibleUsersWaiver,
                rs.UserRevShare,
                count(distinct case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 then GCID ELSE NULL end ) as EligibleUsersAbove1USD,
                count(distinct case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer < 1 then GCID ELSE NULL end ) as EligibleUsersBelow1USD,
                sum(ppp.EffectiveRewardsPerCustomer) as UsersRewards,
                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 then ppp.EffectiveRewardsPerCustomer else 0 end) as UsersRewardsAbove1USD,

                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 then ppp.EffectiveRewardsPerCustomer else 0 end) -
                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 and w.IsWaiver = 1 then ppp.EffectiveRewardsPerCustomer else 0 end)
                as UsersRewardsAbove1USDNoWaiver,
                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 and w.IsWaiver = 1 then ppp.EffectiveRewardsPerCustomer else 0 end) as UsersRewardsAbove1USDWaiver,
                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer < 1 then ppp.EffectiveRewardsPerCustomer else 0 end) as UsersRewardsBelow1USD,
                (sum(ppp.EffectiveRewardsPerCustomer)/rs.UserRevShare)-sum(ppp.EffectiveRewardsPerCustomer) as eToroRewards,
                (sum(ppp.EffectiveRewardsPerCustomer)/rs.UserRevShare)-sum(ppp.EffectiveRewardsPerCustomer) +
                    sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer < 1 then ppp.EffectiveRewardsPerCustomer else 0 end) as eToroTotalRewards,
            (sum(ppp.EffectiveRewardsPerCustomer)/rs.UserRevShare)-sum(ppp.EffectiveRewardsPerCustomer) +
                    sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer < 1 then ppp.EffectiveRewardsPerCustomer else 0 end) +
                    sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 and w.IsWaiver = 1 then ppp.EffectiveRewardsPerCustomer else 0 end)
                    as eToroTotalRewardsWaiver,        
                sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 then ppp.EffectiveRewardsPerCustomer else 0 end)*((pc.AskLast+pc.BidLast)/2) as UserRewardsUSD,

								sum(case when lower(ppp.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
												     'new caledonia', 'french polynesia', 'wallis and futuna', 'netherlands', 'france', 'russia') and 
													  --w.IsWaiver = 0 and 
													  ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1
					then ppp.EffectiveRewardsPerCustomer else 0 end) *((pc.AskLast+pc.BidLast)/2) as CompensationCountryUSD,
					sum(case when lower(ppp.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
												     'new caledonia', 'french polynesia', 'wallis and futuna', 'netherlands', 'france', 'russia') and 
													  w.IsWaiver = 1 and 
													  ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1
					then ppp.EffectiveRewardsPerCustomer else 0 end) *((pc.AskLast+pc.BidLast)/2) as CompensationCountryWaiverUSD,
				sum(case when lower(ppp.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
												     'new caledonia', 'french polynesia', 'wallis and futuna', 'netherlands', 'france', 'russia') and 
													  --w.IsWaiver = 0 and 
													  ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1
					then ppp.EffectiveRewardsPerCustomer else 0 end) as CompensationCountryRewards,
					sum(case when lower(ppp.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
												     'new caledonia', 'french polynesia', 'wallis and futuna', 'netherlands', 'france', 'russia') and 
													  w.IsWaiver = 1 and 
													  ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1
					then ppp.EffectiveRewardsPerCustomer else 0 end) as CompensationCountryWaiverRewards,
sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer >= 1 and w.IsWaiver = 1 then ppp.EffectiveRewardsPerCustomer else 0 end)*((pc.AskLast+pc.BidLast)/2) as UserWaiverRewardsUSD,
                ((sum(ppp.EffectiveRewardsPerCustomer)/rs.UserRevShare)-sum(ppp.EffectiveRewardsPerCustomer) +
                    sum(case when ((pc.AskLast+pc.BidLast)/2)*ppp.EffectiveRewardsPerCustomer < 1 then ppp.EffectiveRewardsPerCustomer else 0 end)) *((pc.AskLast+pc.BidLast)/2) as eToroRewardsUSD
        from EXE.[dbo].[staking_raw3] ppp
        left join EXE.[dbo].[staking_RevShare] rs on 
            LOWER (CONVERT (varchar, rs.Club ) collate Latin1_General_BIN )= LOWER (CONVERT (varchar, ppp.Club ) collate Latin1_General_BIN) AND
                          LOWER (CONVERT (varchar, rs.Currency ) collate Latin1_General_BIN )= LOWER (CONVERT (varchar, LEFT(ppp.Asset, 3) ) collate Latin1_General_BIN)
        left join EXE.dbo.v_PriceCandle pc on lower(pc.coin) = lower(ppp.Asset) and pc.DateTo = ppp.last_day
        left join EXE.dbo.staking_Waiver w on w.CID = ppp.CID and w.staking_monthID = ppp.staking_monthID and IsWaiver = 1
        left join EXE.[dbo].[staking_split_units] su on LEFT(su.Instrument, 3) = ppp.Asset and ppp.first_day = su.first_day
        where rs.IsActive = 1
        group by ppp.first_day, ppp.last_day, su.SplitEtoroUnits, su.SplitUserUnits, ppp.Club, ppp.Asset, rs.UserRevShare, pc.AskLast, pc.BidLast, ppp.Rewards, ppp.Create_Date, ppp.staking_month, ppp.staking_monthID
    ) a 
left join EXE.dbo.v_PriceCandle pc on lower(pc.coin) = lower(a.Asset) and pc.DateTo = a.last_day