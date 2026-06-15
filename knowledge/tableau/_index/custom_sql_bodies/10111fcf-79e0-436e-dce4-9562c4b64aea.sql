select p.CID, p.GCID, p.ID, p.Regulation, p.Country, p.Club, p.InstrumentID, p.Asset, p.first_day, p.last_day, p.staking_month, p.staking_monthID, p.EffectiveRewardsPerCustomer as Rewards,
    case when lower(p.Country) like 'jordan' then 'Jordan'
	     when lower(p.Country) like 'egypt' then 'Egypt'
	     when lower(p.Country) like 'qatar' then 'Qatar'
	     when lower(p.Country) like 'india' then 'India'
	     when lower(p.Country) like 'russia' then 'Russia'
         when lower(p.Country) like 'netherlands' then 'Netherlands'
         when lower(p.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
                                    'new caledonia', 'french polynesia', 'wallis and futuna', 'france') then 'France'
         else 'Other' end as [Group],
    ((pc.AskLast+pc.BidLast)/2) as USDprice, ((pc.AskLast+pc.BidLast)/2)*p.EffectiveRewardsPerCustomer as RewardsUSD, w.IsWaiver,
    CEILING(cast((ROW_NUMBER() over(partition by p.staking_monthID order by p.CID)) as float)/5000) as Bucket
from EXE.dbo.staking_raw3 p
join EXE.dbo.v_PriceCandle pc on lower(pc.coin) = lower(p.Asset) and pc.DateTo = p.last_day
left join [EXE].[dbo].[staking_Waiver] w on w.CID = p.CID and w.staking_monthID = p.staking_monthID
where -- p.staking_monthID = 202102 and 
    ((pc.AskLast+pc.BidLast)/2)*p.EffectiveRewardsPerCustomer >= 1 and 
    isnull(w.IsWaiver, 0) = 0 
--and
     -- p.staking_month in (<[Parameters].[staking_month Parameter]>) and
   -- case when lower(p.Country) like 'russia' then 'Russia'
    --     when lower(p.Country) like 'netherlands' then 'Netherlands'
      --   when lower(p.Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
        --                            'new caledonia', 'french polynesia', 'wallis and futuna', 'france') then 'France'
        -- else 'Other' end in(<[Parameters].[Group Parameter]>)