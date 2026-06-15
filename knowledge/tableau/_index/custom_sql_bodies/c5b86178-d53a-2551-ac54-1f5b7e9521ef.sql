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
)

SELECT  dp.PositionID
       ,dp.CID
       ,CAST(dp.OpenOccurred AS DATE) AS OpenDate
       ,dp.OpenDateID
       ,CAST(dp.CloseOccurred AS DATE) As CloseDate
       ,dp.CloseDateID
       ,di.`Exchange`
       ,di.InstrumentType
       ,fcv.Last_Currency
       ,CASE WHEN fcv.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Currency_Change_Data
       ,CASE WHEN fcv.Last_Currency !='USD' THEN 1 ELSE 0 END AS Is_Currency_Addoption
       ,da.BankAccountIBAN
       ,CASE 
        WHEN op.TreeID IS NOT NULL AND da.CurrencyBalanceISODesc = 
        CASE 
            WHEN di.SellCurrency = 'GBX' THEN 'GBP' 
            ELSE di.SellCurrency 
        END THEN 'IBAN LC'  
        WHEN op.TreeID IS NOT NULL AND da.CurrencyBalanceISODesc <> 
        CASE 
            WHEN di.SellCurrency = 'GBX' THEN 'GBP' 
            ELSE di.SellCurrency 
        END THEN 'IBAN Non-LC'
        WHEN op.TreeID IS NULL AND da.CurrencyBalanceISODesc = di.SellCurrency THEN 'TP LC'
        WHEN op.TreeID IS NULL AND da.CurrencyBalanceISODesc <> di.SellCurrency THEN 'TP Non-LC'
        ELSE 'Error' 
        END AS OpenSourceDetailed
      ,CASE 
        WHEN cl.PositionID IS NOT NULL AND da.CurrencyBalanceISODesc = 
        CASE 
            WHEN cl.ProcessCurrency = 'GBX' THEN 'GBP' 
            ELSE cl.ProcessCurrency 
        END THEN 'IBAN LC'  
        WHEN cl.PositionID IS NOT NULL AND da.CurrencyBalanceISODesc <> 
        CASE 
            WHEN cl.ProcessCurrency = 'GBX' THEN 'GBP' 
            ELSE cl.ProcessCurrency 
        END THEN 'IBAN Non-LC'
        WHEN cl.PositionID IS NULL AND da.CurrencyBalanceISODesc = di.SellCurrency THEN 'TP LC'
        WHEN cl.PositionID IS NULL AND da.CurrencyBalanceISODesc <> di.SellCurrency THEN 'TP Non-LC'
        ELSE 'Error' 
        END AS CloseSourceDetailed
       ,CASE WHEN op.TreeID is not null THEN 'IBAN' ELSE 'TP' END as OpenSource
       ,CASE WHEN cl.PositionID is not null THEN 'IBAN' ELSE 'TP' END as CloseSource
       ,da.CurrencyBalanceISODesc AS ClientsCurrency
       ,op.SellCurrency AS LCOpenCurrency
       ,cl.ProcessCurrency AS LCCloseCurrency
       ,di.SellCurrency AS InstrumentCurrency
       ,dp.InitialAmountCents/100 AS InitialAmountUSD
       ,dp.Leverage 
       ,dp.IsAirDrop
       ,dp.MirrorID
       ,dp.Amount
       ,da.Country
       ,da.RegCountry
       ,CASE WHEN da.CountryID = 218 THEN 'UK' ELSE 'EU' END as UK_EU
       ,CASE WHEN dp.IsPartialCloseChild = 0 or dp.IsPartialCloseChild is NULL THEN 0 ELSE 1 End as IsPartialCloseChild
       --,CASE WHEN op.TreeID IS NULL and op.DepositDate is not null THEN 1 else 0 end as Is_Deposit_WO_Position
FROM dwh.dim_position dp
INNER JOIN (SELECT di.InstrumentID
      ,di.InstrumentType
      ,di.Exchange
      ,di.InstrumentTypeID
      ,CASE WHEN di.SellCurrency='GBX' THEN 'GBP' ELSE di.SellCurrency END AS SellCurrency
FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
WHERE di.InstrumentTypeID IN (5,6,10) ) di 
on dp.InstrumentID=di.InstrumentID 
 JOIN bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account da on dp.CID=da.Cid and da.IsValidCustomer=1 and da.GCID_Unique_Count=1 
 LEFT JOIN bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban op on dp.PositionID=op.TreeID
 LEFT JOIN bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban cl on dp.PositionID=cl.PositionID
 left join first_last_currency_values fcv on fcv.RealCID = dp.CID
WHERE COALESCE(dp.MirrorID, 0) = 0
      AND COALESCE(dp.IsAirDrop, 0) = 0
      AND dp.Leverage=1
      AND (dp.CloseOccurred>=date_add(month,-7,getdate()) OR dp.OpenOccurred>=date_add(month,-7,getdate()))