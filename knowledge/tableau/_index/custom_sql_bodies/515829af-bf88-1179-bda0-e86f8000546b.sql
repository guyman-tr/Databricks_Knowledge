select ec.CID ,dpl.Name Club,g.Name Regulation 
,ec.IsEligible
,ec.Agreed_Typeform
,net_Deposits,Net_MI
,Credit_30_04_24
,sum(gc.amount_v_mirror + gc.amount_positionpnl + gc.pnl_positionpnl) totalMirror
,gc.etr_ymd
from 
    (


    select pp.CID,
nd.net_Deposits,
cc.Credit_30_04_24,
atp.Agreed_Typeform,
pp.Net_MI,
case when (coalesce(nd.net_Deposits,0) + coalesce(cc.Credit_30_04_24,0 ) >=10000
          and atp.Agreed_Typeform=1
          and  pp.Net_MI>=10000
          ) 
          or ( pp.GCID in  (
                               select gcid
                               from bi_db.bronze_fivetran_google_sheets_manually_approved_tactical_edge
                                where TO_DATE(TO_TIMESTAMP(date, 'dd/MM/yyyy') ,'MM/dd/yyyy') <= last_day(add_months(current_date(),-1 )) -- PARAM 1 <[Parameters].[Parameter 1]>
                            )
                 and  pp.Net_MI>=10000
             )

    then 1 else 0 end IsEligible,
    
 pp.ParentCID
from 
(

    select
  mrr.MirrorID 
  ,mrr.ParentCID
  ,mrr.CID
  ,dc.GCID
  ,sum (case when mrr.MirrorOperationID = 2 then -1*mrr.Amount else mrr.Amount end ) Net_MI
  from main.trading.bronze_etoro_history_mirror mrr 
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  on dc.realcid = mrr.cid
  where mrr.MirrorOperationID in (1,2,3) 
  and mrr.ParentCID in (37890645) 
  and  cast(mrr.ModificationDate as date ) <= last_day(add_months(current_date(),-1 ))
  group by mrr.MirrorID, mrr.ParentCID, mrr.CID, dc.GCID


) pp
 join
(
    select vl.CID,
    vl.Credit  Credit_30_04_24
    from main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
    where vl.DateID=20240430
) cc 
on pp.CID=cc.CID
left join (
    SELECT fca1.RealCID CID
    ,SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount END) Deposit
    ,SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN (-1*fca1.Amount) END) Cashout
    ,SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount else 0 END) + SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN -1*fca1.Amount else 0 end)  Net_Deposits
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca1
    WHERE fca1.ActionTypeID IN (7,8)
    AND fca1.DateID>=20240501
    and fca1.DateID<=date_format(last_day(add_months(current_date(),-1 )), 'yyyyMMdd')-- PARAM 2
    AND fca1.DateID<=20240708
    GROUP BY fca1.RealCID
) nd 
on pp.CID=nd.CID
 join 
(
    select aa.RealCID CID,
    aa.Action,
    case when aa.Action='Accept' then 1 else 0 end Agreed_Typeform
    from  
    (
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
            and TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')<= last_day(add_months(current_date(),-1 )) -- PARAM 3
        )a
    )aa
    where aa.rn=1
) atp
 on atp.CID=pp.CID) ec
join 
 (


  select a.etr_ymd 
  ,a.CID, a.MirrorID
  ,b.ParentUserName
  ,b.ParentCID
  ,b.Amount as amount_v_mirror
  ,b.CloseDateID 
  ,sum(a.Amount) amount_positionpnl 
  ,sum(a.positionpnl) pnl_positionpnl
  from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl a
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror b 
  on a.MirrorID=b.MirrorID 
  and a.etr_ymd =last_day(add_months(current_date(),-1 )) --PARAM 4
  and b.etr_ymd = date_add(day,1,last_day(add_months(current_date(),-1 ))) -- PARAM 5
  and cast(a.UpdateDate as date )= cast(b.UpdateDate as date) 
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
  on a.CID = dc.RealCID and dc.IsValidCustomer = 1
  where b.ParentCID in (37890645)
  and b.CloseDateID = 0
  and b.OpenDateID >= 20240101
  group by a.etr_ymd
  ,a.CID
  , a.MirrorID
  , b.Amount
  , b.ParentUserName
  ,b.ParentCID
  ,b.CloseDateID


 ) gc
 on gc.ParentCID = ec.ParentCID
 and ec.CID = gc.CID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc on fsc.RealCID=ec.CID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range g ON fsc.DateRangeID = g.DateRangeID and date_format(last_day(add_months(current_date(),-1 )), 'yyyyMMdd') --PARAM 6
     between fsc.FromDateID and fsc.ToDateID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation g ON fsc.RegulationID = g.DWHRegulationID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID 
where gc.CloseDateID = 0
--ec.IsEligible=1
--coalesce(gc.PnL, 0) + coalesce(gc.DetachedPosInvestment, 0) + coalesce(gc.Dit_PnL, 0)<0
group by ec.CID,dpl.Name
,ec.IsEligible
,g.Name,ec.Agreed_Typeform,net_Deposits,Net_MI,Credit_30_04_24,gc.etr_ymd