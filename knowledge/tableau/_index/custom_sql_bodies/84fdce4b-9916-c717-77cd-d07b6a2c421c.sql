select  p.cid
, p.id as planID
, planStatusID
, InstanceID
,p.CreationDate
,p.enddate
,p.amount  PlanAmount
, p.currencyID
, dcc.name as currency
,dcc.abbreviation
, dcc.abbreviation
,  tt.InstrumentType
,copytype
,tt.InstrumentDisplayName
, dc1.Name Country
, dc1.MarketingRegionManualName Region
, pl.Name Club, p.PlanStatusID  
,depositamountusd as MI_USD 
,pi.depositDate
,DepositID
,row_number() over (partition by pi.planid order by pi.CreationDate ) as CycleNumber
,case when pi.DepositStatusID <> 2 then 0 --pi.InstanceStatusid in (3,4) then 0 
when depositid is null then 0
else  row_number() over (partition by pi.depositID, DepositDate order by pi.CreationDate )  
 end Deposit_rn
, pi.depositstatusid
,pi.positionstatus
,pi.InstanceStatusID
, case when pi.InstanceStatusid in (3,4) and i.maxDepositCyclyNum = pi.DepositCycleNumber  then 1 else 0 end isSkip
,case when i.isactivePlan > 0 then 1 else 0 end isactiveUser
from main.general.bronze_recurringinvestment_recurringinvestment_planinstances pi 
join main.general.bronze_recurringinvestment_recurringinvestment_plans p 
on p.id = pi.planid
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on p.cid = dc.realCID
join   main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dcc
on dcc.currencyid = p.currencyid
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
ON dc.PlayerLevelID = pl.PlayerLevelID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument tt
on p.InstrumentID = tt.InstrumentID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
on dc.CountryID = dc1.CountryID
join (
    select p.cid, p.ID  ,sum(case when planstatusid = 1  and enddate is null  and depositamountusd > 0 then 1.0 else 0 end ) as isactivePlan,
    max(pi.DepositCycleNumber) maxDepositCyclyNum
    from main.general.bronze_recurringinvestment_recurringinvestment_planinstances pi 
    join main.general.bronze_recurringinvestment_recurringinvestment_plans p 
    on p.id = pi.planid
    group by p.CID, id

      ) i on i.id = p.id
where dc.isvalidcustomer = 1