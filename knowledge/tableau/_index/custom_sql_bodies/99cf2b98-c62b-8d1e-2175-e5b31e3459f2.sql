select *, case when lower(Country) like 'russia' then 'Russia'
         when lower(Country) like 'netherlands' then 'Netherlands'
         when lower(Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
                                    'new caledonia', 'french polynesia', 'wallis and futuna', 'france') then 'France'
         else 'Other' end as [Group]
FROM [EXE].[dbo].[staking_WaiverAutoSim]
WHERE [RewardsUSD] >= <[Parameters].[Parameter 1]> 
       -- and
      --case when lower(Country) like 'russia' then 'Russia'
        -- when lower(Country) like 'netherlands' then 'Netherlands'
         --when lower(Country) in ('guadeloupe', 'french guiana', 'martinique', 'reunion island', 'saint martin', 'mayotte', 
           --                         'new caledonia', 'french polynesia', 'wallis and futuna', 'france') then 'France'
         --else 'Other' end in ( <[Parameters].[Parameter 2]>)