with log_in_6M as (
    select distinct 
          dc.GCID
    from main.mixpanel.login_events l
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        on l.GCID = dc.GCID
    where to_date(l.DateID, 'yyyyMMdd') >= (current_date() - interval 6 months)
      and dc.IsValidCustomer = 1
      and dc.IsDepositor = 1
    union
    select distinct
          dc.GCID
    from main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        on fca.RealCID = dc.RealCID
    where to_date(fca.DateID, 'yyyyMMdd') >= (current_date() - interval 6 months)
      and fca.ActionTypeID = 14
      and dc.IsValidCustomer = 1
      and dc.IsDepositor = 1
),

mp_data_raw as (
    select 
          coalesce(mp.mp_user_id, user_id) as GCID,
          chosen_currency,
          from_unixtime(mp.time) as event_timestamp
    from main.mixpanel.silver mp  
    where
      mp.etr_ymd >= '20230701'
      and mp.mp_event_name = 'Currency Change'
      and coalesce(mp.mp_user_id, user_id) is not null
),

currency_change_data as (
    select 
          mp.GCID,
          dc.RealCID,
          chosen_currency,
          event_timestamp as Start_Timestamp,
          LEAD(event_timestamp, 1, current_timestamp()) OVER(PARTITION BY mp.GCID ORDER BY event_timestamp) as End_Timestamp,
          case when ROW_NUMBER() OVER(PARTITION BY mp.GCID ORDER BY event_timestamp) = 1 and mp.chosen_currency = 'USD' then 1 else 0 end as is_usd_first_currency_change
    from mp_data_raw mp
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked as dc
        on mp.gcid = CAST(dc.GCID as string)
),

first_last_currency as (
    select
        GCID,
        RealCID,
        min(Start_Timestamp) as First_Timestamp,
        max(Start_Timestamp) as Last_Timestamp
    from currency_change_data
    where is_usd_first_currency_change = 0
    group by GCID,RealCID
),
first_last_currency_values as (
     select distinct
        flc.GCID,
        flc.RealCID,
        FIRST_VALUE(ccd.chosen_currency) OVER (PARTITION BY flc.GCID ORDER BY ccd.Start_Timestamp) as First_Currency,
        LAST_VALUE(ccd.chosen_currency) OVER (PARTITION BY flc.GCID ORDER BY ccd.Start_Timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as Last_Currency
    from first_last_currency flc
    join currency_change_data ccd
        on flc.GCID = ccd.GCID
),

fact_actions as (
SELECT fca.*
       ,CAST(fcv.First_Timestamp AS DATE) AS First_Timestamp
       ,CAST(fcv.Last_Timestamp AS DATE) AS Last_Timestamp
       ,CAST(fca.Occurred AS DATE) AS Occurred2
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca 
join first_last_currency fcv on fcv.RealCID = fca.RealCID AND CAST (fca.Occurred AS DATE)>=DATEADD(day,-90,CAST(fcv.Last_Timestamp AS DATE))
AND  CAST (fca.Occurred AS DATE)<=DATEADD(day,90,CAST(fcv.Last_Timestamp AS DATE))
where fca.ActionTypeID in (7,1,4) and fca.DateID>=20230101
),

deposits as (
select f.RealCID,
       f.Last_Timestamp,
       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp) then 1 else 0 end) as Deposits_before_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp) then 1 else 0 end) as Deposits_after_90,
       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp) then Amount else 0 end) as Deposits_before_Amount_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp) then Amount else 0 end) as Deposits_after_Amount_90,
       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp) then 1 else 0 end) as Deposits_before_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp) then 1 else 0 end) as Deposits_after_30,
       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp) then Amount else 0 end) as Deposits_before_Amount_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp) then Amount else 0 end) as Deposits_after_Amount_30
from fact_actions f 
where f.ActionTypeID =7   
group by f.RealCID,
       f.Last_Timestamp
),
positions as (
select f.RealCID,
       f.Last_Timestamp,
       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 1) then 1 else 0 end) as Pos_open_before_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 1) then 1 else 0 end) as Pos_open_after_90,
       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 1) then ABS(Amount) else 0 end) as Pos_open_before_Amount_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 1) then ABS(Amount) else 0 end) as Pos_open_after_Amount_90,

       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 4) then 1 else 0 end) as Pos_close_before_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 4) then 1 else 0 end) as Pos_close_after_90,
       sum(case when (Occurred2 >=DATEADD(day,-90,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 4) then Amount else 0 end) as Pos_close_before_Amount_90,
       sum(case when (Occurred2 <=DATEADD(day,90,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 4) then Amount else 0 end) as Pos_close_after_Amount_90,
       
       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 1) then 1 else 0 end) as Pos_open_before_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 1) then 1 else 0 end) as Pos_open_after_30,
       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 1) then ABS(Amount) else 0 end) as Pos_open_before_Amount_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 1) then ABS(Amount) else 0 end) as Pos_open_after_Amount_30,

       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 4) then 1 else 0 end) as Pos_close_before_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 4) then 1 else 0 end) as Pos_close_after_30,
       sum(case when (Occurred2 >=DATEADD(day,-30,Last_Timestamp) and Occurred2<=Last_Timestamp and ActionTypeID = 4) then Amount else 0 end) as Pos_close_before_Amount_30,
       sum(case when (Occurred2 <=DATEADD(day,30,Last_Timestamp) AND Occurred2>Last_Timestamp and ActionTypeID = 4) then Amount else 0 end) as Pos_close_after_Amount_30
from fact_actions f 
where f.ActionTypeID in (1,4)  
group by f.RealCID,
       f.Last_Timestamp
),

combined_data as (
    select distinct
        fcv.GCID,
        dco.Name as Country,
        dco.MarketingRegionManualName As Region,
        CASE WHEN lg.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Log_In_6M,
        CASE WHEN fcv.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Currency_Change_Data,
        CASE WHEN fcv.Last_Currency !='USD' THEN 1 ELSE 0 END AS Is_Currency_Addoption,
        CASE WHEN mda.GCID IS NULL THEN 0 ELSE 1 END as Is_eTM,
        CASE WHEN t.FMI_Date IS  NULL THEN 0 ELSE 1 END as Is_eTM_FMI,
        CASE WHEN y.RealCID is NULL THEN 0 ELSE 1 END as Iban_Trade,
        fcv.First_Currency,
        fl.EOM_Club,
        fl.ClusterDetail,
        fl.FTDdate,
        fcv.Last_Currency,
        flc.First_Timestamp AS Trial_Date,
        flc.Last_Timestamp AS Adoption_Date,
        mda.Seniority_eTM_RegDate,
        COALESCE(D.Deposits_after_90, 0) as Deposits_after_90,
        COALESCE(D.Deposits_before_90, 0) as Deposits_before_90,
        COALESCE(D.Deposits_after_Amount_90, 0) as Deposits_after_Amount_90,
        COALESCE(D.Deposits_before_Amount_90, 0) as Deposits_before_Amount_90,
        COALESCE(D.Deposits_after_30, 0) as Deposits_after_30,
        COALESCE(D.Deposits_before_30, 0) as Deposits_before_30,
        COALESCE(D.Deposits_after_Amount_30, 0) as Deposits_after_Amount_30,
        COALESCE(D.Deposits_before_Amount_30, 0) as Deposits_before_Amount_30,
        COALESCE(P.Pos_close_after_90, 0) as Pos_close_after_90,
        COALESCE(P.Pos_close_before_90, 0) as Pos_close_before_90,
        COALESCE(P.Pos_open_after_90, 0) as Pos_open_after_90,
        COALESCE(P.Pos_open_before_90, 0) as Pos_open_before_90,
        COALESCE(P.Pos_close_after_Amount_90, 0) as Pos_close_after_Amount_90,
        COALESCE(P.Pos_close_before_Amount_90, 0) as Pos_close_before_Amount_90,
        COALESCE(P.Pos_open_after_Amount_90, 0) as Pos_open_after_Amount_90,
        COALESCE(P.Pos_open_before_Amount_90, 0) as Pos_open_before_Amount_90,
        COALESCE(P.Pos_close_after_30, 0) as Pos_close_after_30,
        COALESCE(P.Pos_close_before_30, 0) as Pos_close_before_30,
        COALESCE(P.Pos_open_after_30, 0) as Pos_open_after_30,
        COALESCE(P.Pos_open_before_30, 0) as Pos_open_before_30,
        COALESCE(P.Pos_close_after_Amount_30, 0) as Pos_close_after_Amount_30,
        COALESCE(P.Pos_close_before_Amount_30, 0) as Pos_close_before_Amount_30,
        COALESCE(P.Pos_open_after_Amount_30, 0) as Pos_open_after_Amount_30,
        COALESCE(P.Pos_open_before_Amount_30, 0) as Pos_open_before_Amount_30
    from first_last_currency_values fcv
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked as dc on fcv.GCID = dc.GCID and dc.IsValidCustomer=1 and dc.IsDepositor=1
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dco on dc.CountryID = dco.CountryID 
    left join first_last_currency flc on fcv.GCID = flc.GCID
    left join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account mda on fcv.GCID = mda.GCID and mda.IsValidETM=1 and mda.GCID_Unique_Count=1
    left join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates as t on t.GCID=fcv.GCID 
    left join log_in_6M lg on lg.GCID=fcv.GCID
    left join deposits as d on d.RealCID=dc.RealCID
    left join positions as p on p.RealCID=dc.RealCID
    left join main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata fl on fl.CID=dc.RealCID and fl.Active_Month=CAST(date_format(current_date(), 'yyyyMM') AS INT)
    left join (SELECT DISTINCT fca.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    WHERE fca.ActionTypeID IN (44,45) AND fca.DateID>=20240301) y on y.RealCID=dc.RealCID    
)  

select * from combined_data