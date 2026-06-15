with primary_data as (
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
        min(Start_Timestamp) as First_Timestamp,
        max(Start_Timestamp) as Last_Timestamp
    from currency_change_data
    where is_usd_first_currency_change = 0
    group by GCID
),
first_last_currency_values as (
     select distinct
        flc.GCID,
        FIRST_VALUE(ccd.chosen_currency) OVER (PARTITION BY flc.GCID ORDER BY ccd.Start_Timestamp) as First_Currency,
        LAST_VALUE(ccd.chosen_currency) OVER (PARTITION BY flc.GCID ORDER BY ccd.Start_Timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as Last_Currency
    from first_last_currency flc
    join currency_change_data ccd
        on flc.GCID = ccd.GCID
),

combined_data as (
    select distinct
        pd.GCID,
        dco.Name as Country,
        dco.MarketingRegionManualName As Region,
        CASE WHEN pd.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Log_In,
        CASE WHEN fcv.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Currency_Change_Data,
        CASE WHEN fcv.Last_Currency !='USD' THEN 1 ELSE 0 END AS Is_Currency_Addoption,
        CASE WHEN mda.GCID IS NULL THEN 0 ELSE 1 END as Is_eTM,
        CASE WHEN t.FMI_Date IS  NULL THEN 0 ELSE 1 END as Is_eTM_FMI,
        CASE WHEN y.RealCID is NULL THEN 0 ELSE 1 END as Iban_Trade,
        fcv.First_Currency,
        fcv.Last_Currency,
        flc.First_Timestamp AS Trial_Date,
        flc.Last_Timestamp AS Adoption_Date,
        mda.Seniority_eTM_RegDate
    from primary_data pd
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked as dc on pd.GCID = dc.GCID and dc.IsValidCustomer=1 and dc.IsDepositor=1
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dco on dc.CountryID = dco.CountryID 
    left join first_last_currency_values fcv on pd.GCID = fcv.GCID
    left join first_last_currency flc on pd.GCID = flc.GCID
    left join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account mda on pd.GCID = mda.GCID and mda.IsValidETM=1 and mda.GCID_Unique_Count=1
    left join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates as t on t.GCID=pd.GCID 
    left join 
    (SELECT DISTINCT fca.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    WHERE fca.ActionTypeID IN (44,45) AND fca.DateID>=20240301) y on y.RealCID=dc.RealCID    
    )

select * from combined_data