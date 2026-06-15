select p.*, tt.InstrumentType, dc1.MarketingRegionManualName Region, pl.Name Club
,tt.instrumentDisplayName, dc1.Name Country, 
row_number() over (partition by p.CID order by p.creationDate ) as PlanNumber
,h.WasActive as ChurnPlan
from main.general.bronze_recurringinvestment_recurringinvestment_plans p 
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument tt 
on p.InstrumentID = tt.InstrumentID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on p.CID = dc.realCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
on dc.CountryID = dc1.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
ON dc.PlayerLevelID = pl.PlayerLevelID
left join (
        select distinct(id) id, 1 as WasActive
        from main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans h
        join  main.general.bronze_recurringinvestment_recurringinvestment_planinstances pi
        on pi.PlanID = h.id and pi.DepositStatusID = 2 
        where h.planstatusid =1 
        ) h
on p.id = h.id and p.planstatusid = 2 
WHERE  dc.IsValidCustomer = 1