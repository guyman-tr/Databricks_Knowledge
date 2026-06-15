with exp_users as (
  select
    mp.mp_user_id gcid,
    mp.variationid,
    min(from_unixtime(mp.time)) first_exp_ts
  from
    main.mixpanel.silver mp
  where
        mp.etr_ymd >= '2023-09-06'
    and mp.mp_event_name in ('Experiment Started','$experiment_started')
    and	mp.variationid in ('portfolio_local_currency_control','portfolio_local_currency_test') 
    and mp.rule_name = 'portfolio_local_currency_phase_2'
    and mp.time > 1693996571
    -- and (split(mp.appversion,'[.]')[0] * 100000000 + split(mp.appversion,'[.]')[1] * 10000 + split(mp.appversion,'[.]')[2]) >= 58900000002
  group by
    1,2
)

-- , a as (
select
  mp.mp_user_id                                                       gcid,
  eu.variationid                                                      variant,
  mp.display_currency                                                 last_currency,
  -- mp.mp_event_name                                                 event,
  from_unixtime(mp.time)                                              last_currency_ts,
  dc.RegisteredReal                                                   reg_ts,
  dc.FirstDepositDate                                                 ftd_date,
  dco.Name                                                            country,
  case when dcu.cur_symbol is null then 'USD' else dcu.cur_symbol end local_currency,
  case when dcu.cur_symbol is null then 0 else 1 end                  has_local_currency
from
  main.mixpanel.silver mp
join exp_users eu
  on mp.mp_user_id = eu.gcid
  and from_unixtime(mp.time) > eu.first_exp_ts
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  on mp.mp_user_id = dc.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dco
  on dc.CountryID = dco.CountryID
left join main.product_analytics.BI_OUTPUT_Product_Analytics_almoglo_Tables_etoro_currencies_by_country dcu
  on dco.Name = dcu.country
where
      mp.etr_ymd >= '2023-09-06'
  and mp.display_currency is not null
  and mp.mp_user_id is not null
qualify row_number() over (partition by mp.mp_user_id order by from_unixtime(time) desc) = 1