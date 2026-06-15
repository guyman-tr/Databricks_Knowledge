with potential_participants as ( -- get all users who received a variant
	select
		mp_user_id gcid,
		case 
			when variationid = 'portfolio_local_currency_control' 						then 'Control' 						 
			when variationid = 'portfolio_local_currency_default_change_test' then 'Default Change'
			else'Optinal Change'
		end variant,
		min(from_unixtime(time)) exp_started_timestamp
	from
		mixpanel.silver
	where
				etr_ymd >= '2023-05-04'
		and mp_event_name in ('Experiment Started','$experiment_started')
		and	variationid in ('portfolio_local_currency_control','portfolio_local_currency_default_change_test','portfolio_local_currency_test')
		and player_level_id != 4
		and mp_user_id is not null
	group by
		1,2
)

, actual_participants as ( -- filter out users who received variant but didn't see it + add cid
	select
		pp.gcid,
		pp.variant,
		min(from_unixtime(mp.time)) actual_exp_started_timestamp -- from this date and forth, the user is IN the experiment
	from
		mixpanel.silver mp
	join potential_participants pp
		on mp.mp_user_id = pp.gcid
	where
				etr_ymd >= '2023-05-04'
		and mp.mp_event_name = 'Portfolio - Page View'
		and from_unixtime(mp.time) >= pp.exp_started_timestamp -- get only events that occurred after the exp_started_timestamp
	group by
		1,2
)

, participants_data as (
  select
    ap.gcid														gcid,
		ap.variant												variant,
		ap.actual_exp_started_timestamp		exp_started_timestamp,
		dco.Name													country,
		dcu.cur_symbol 										local_currency,
		date(dc.RegisteredReal)						reg_date
  from
    actual_participants ap
	join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
		on ap.gcid = dc.GCID 
  join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dco
		on dc.CountryID = dco.CountryID
	left join 
		product_analytics.BI_OUTPUT_Product_Analytics_almoglo_Tables_etoro_currencies_by_country dcu
		on dco.Name = dcu.country
)

select
	*
from
	participants_data pd