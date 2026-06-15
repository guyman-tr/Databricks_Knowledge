select ec.CID ,dpl.Name Club,g.Name Regulation ,ec.IsEligible,ec.Agreed_Typeform,net_Deposits,Net_MI,Credit_30_04_24,
SUM(coalesce(gc.PnL, 0) + coalesce(gc.DetachedPosInvestment, 0) + coalesce(gc.Dit_PnL, 0)) AS CopyPnL
from (select pp.CID,
nd.net_Deposits,
cc.Credit_30_04_24,
atp.Agreed_Typeform,
pp.Net_MI,
case when (coalesce(nd.net_Deposits,0) + coalesce(cc.Credit_30_04_24,0 ) >=10000
and atp.Agreed_Typeform=1
and  pp.Net_MI>=10000) or (pp.GCID in (select gcid
from bi_db.bronze_fivetran_google_sheets_manually_approved_tactical_edge
where TO_DATE(TO_TIMESTAMP(date, 'dd/MM/yyyy') ,'MM/dd/yyyy')
<=cast(<[Parameters].[Parameter 1]> as date))
and  pp.Net_MI>=10000)

 then 1 else 0 end IsEligible,
 pp.ParentCID
from (SELECT
    fca.RealCID CID

    --,fca.DateID
    ,dm.ParentCID
    --,g.Name Regulation
    --,dm.MirrorID
    --,SUM(CASE WHEN fca.ActionTypeID IN (16, 18) THEN (-1*fca.Amount) ELSE 0 END) MoneyOut
   -- ,SUM(CASE WHEN fca.ActionTypeID IN (15, 17) THEN (-1*fca.Amount) ELSE 0 END) MoneyIn
    ,SUM(CASE WHEN fca.ActionTypeID IN (15, 17) THEN (-1*fca.Amount) ELSE 0 END)+SUM(CASE WHEN fca.ActionTypeID IN (16, 18) THEN (-1*fca.Amount) ELSE 0 END) Net_MI
    ,dc.GCID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm
    ON fca.MirrorID = dm.MirrorID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype dmt
    ON dm.MirrorTypeID = dmt.MirrorTypeID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON dc.RealCID=fca.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc on fsc.RealCID=fca.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range g ON fsc.DateRangeID = g.DateRangeID and fca.DateID between fsc.FromDateID and fsc.ToDateID
   -- inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation g ON fsc.RegulationID = g.DWHRegulationID
    --inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
WHERE  
     fca.DateID>= 20240520
    and fca.DateID<=date_format(<[Parameters].[Parameter 1]>, 'yyyyMMdd')
    AND fca.ActionTypeID IN (15, 16, 17, 18)
    AND dm.ParentCID  = 37890645
   AND fsc.IsValidCustomer=1
   and fsc.IsCreditReportValidCB=1
group by
    fca.RealCID,
dc.GCID

    --,fca.DateID
    ,dm.ParentCID
   -- ,g.Name
   ) pp
left join
(select vl.CID,
vl.Credit  Credit_30_04_24
from main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
where vl.DateID=20240430
) cc on pp.CID=cc.CID
left join (SELECT fca1.RealCID CID
    ,SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount END) Deposit
    ,SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN (-1*fca1.Amount) END) Cashout
    ,SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount else 0 END) + SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN -1*fca1.Amount else 0 end)  Net_Deposits
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca1
   
    WHERE fca1.ActionTypeID IN (7,8)
    AND fca1.DateID>=20240501
    and fca1.DateID<=date_format(<[Parameters].[Parameter 1]>, 'yyyyMMdd')-- add here the parameter
    AND fca1.DateID<=20240708
    GROUP BY fca1.RealCID
    ) nd on pp.CID=nd.CID
left join (
select aa.RealCID CID,
aa.Action,
case when aa.Action='Accept' then 1 else 0 end Agreed_Typeform
from  (
select *
,ROW_NUMBER() OVER (PARTITION BY a.GCID/*,a.etr_ymd*/ ORDER BY a.Message DESC) rn

from
(
SELECT DISTINCT a.*
,b.UserName
,b.RealCID
,CONCAT(dm1.FirstName, ' ', dm1.LastName) AS Manager    
,dc.Name

from main.sfmc.silver_sfmc_accountjourneylogtracking a
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b
on a.GCID=b.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm1
ON b.AccountManagerID = dm1.ManagerID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
ON b.PlayerLevelID = dpl.PlayerLevelID
join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on dc.CountryID=b.CountryID
where Journey_Name='6451190453_CG24_TCsFormSubmissions'
and IsValidCustomer=1
and TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')<=cast(<[Parameters].[Parameter 1]> as date)
)a
)aa
where aa.rn=1
) atp on atp.CID=pp.CID) ec
LEFT JOIN main.general.bronze_etorogeneral_history_gurucopiers gc
ON  ec.ParentCID=gc.ParentCID AND ec.CID=gc.CID AND cast(gc.Timestamp as date)=date_add(day,1,<[Parameters].[Parameter 1]>)
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc on fsc.RealCID=ec.CID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range g ON fsc.DateRangeID = g.DateRangeID and date_format(<[Parameters].[Parameter 1]>, 'yyyyMMdd') between fsc.FromDateID and fsc.ToDateID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation g ON fsc.RegulationID = g.DWHRegulationID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID 
--where 
--ec.IsEligible=1
--coalesce(gc.PnL, 0) + coalesce(gc.DetachedPosInvestment, 0) + coalesce(gc.Dit_PnL, 0)<0
group by ec.CID,dpl.Name,ec.IsEligible,g.Name,ec.Agreed_Typeform,net_Deposits,Net_MI,Credit_30_04_24