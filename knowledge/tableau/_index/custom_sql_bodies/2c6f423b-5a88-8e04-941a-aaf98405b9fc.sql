with potential_participants as ( -- get all users who received a variant
	select
		mp.mp_user_id						 		gcid,
		case 
			when mp.variationid = 'default_amount_control' 	then 'Control'
			when mp.variationid = 'default_amount_zero_test' then 'Zero'
			when mp.variationid = 'default_amount_max_test' 	then 'Max'
		else 'Bug' end 							variant,
		min(from_unixtime(mp.time)) exp_started_timestamp
	from
		mixpanel.silver mp
	where
				mp.etr_ymd between '2023-05-11' and '2023-07-11'
		and mp.mp_event_name in ('Experiment Started','$experiment_started')
		and	mp.variationid in ('default_amount_control','default_amount_zero_test','default_amount_max_test')
		and mp.player_level_id != 4
		and mp.mp_user_id is not null
		and mp.time >= 1683816331 -- "Time as EPOCH"
	group by
		1,2
)

-- select variant, count(*) usrs from potential_participants group by 1

-- select count(*) rws, count(distinct gcid) usrs from potential_participants
-- 32399, 32399

-- for each user, find out each day they opened the Execution screen. Later on, we examine if they had enough equity to enter the experiment on that day

, mixpanel as (
select
	pp.gcid,
	pp.variant,
	from_unixtime(mp.time, 'yyyyMMdd') 	date_id,
	dc.RealCID 													cid
from
	mixpanel.silver mp
join
	potential_participants pp
	on mp.mp_user_id = pp.gcid
join
	dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
	on mp.mp_user_id = dc.GCID
where
      mp.etr_ymd between '2023-05-11' and '2023-07-11'
	and	mp.mp_event_name = 'Open Trade - Card View'
	and mp.portfolio = 'Real'
	and mp.available = 1
	and from_unixtime(mp.time) >= pp.exp_started_timestamp -- look only at actions taken after the user triggered experiment started
group by
	1,2,3,4
	)

-- select gcid, count(distinct variant) from mixpanel group by 1 order by 2 desc
-- max 1

-- DEFAULT AMOUNT EXPERIMENT
-- Create the raw data required for the KPI analysis

	-- IDEA:
	-- Currently this CTE holds the data for first time eligible
	-- i need to transition it to hold the data for the entire date range since the user is first eligible
	-- i can add a row number 

, daily_panel as ( -- this creates a table for each user & each day, their equity, club, amount etc
	select
		CID 																																		cid,
		DateID																																	date_id,
		case 	when EOD_Club like '%Bronze' then 'Bronze'
					else EOD_Club 
		end 																																		club,
		Equity																																	equity_eod,
		AmountIn_NewTrades_Total - AmountIn_NewTrades_Copy 											amount_wo_copy_today
	from
		bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata
	where
				etr_ymd >= '2023-05-10'
	QUALIFY
		row_number() over (partition by cid, date_id ORDER BY date_id) = 1 -- for each day, get only 1 row
	)

-- DEFAULT AMOUNT EXPERIMENT
-- Create table that consists: each user, each month, total amount invested, segmentation

-- this cte joins each day of Step A to the relevant daily panel data (1 day before)
-- also, it adds segment data from daily cluster and initial parameters (equity, club, segment)
-- at the end, we qualify only 1 row per user from the earliest date. this way we get each user's first actual entrance into the test (fired Open Trade - Card View & had >= 1000 equity)

, eligible_users as ( -- for each user, thier first time they are eligible for test (fired Open Trade - Card View & equity >= 1000)
	select
		mp.cid,
		mp.variant,
		mp.date_id 			date_start_of_30_days,
		dpd.equity_eod 	equity_start_of_30_days,
		dpd.club,
		dc.ClusterSF 		segment
	from
			mixpanel mp -- only relevant users who fired Open Trade - Card View event
	join 
			daily_panel dpd -- join with equity and club data
		on 	mp.cid = dpd.cid
		and mp.date_id - 1 = dpd.date_id -- join with the former day of dainly panel to get the equity at the start of the mp day
	join
			bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster dc
		on 	dpd.cid = dc.CID
		and mp.date_id between dc.FromDateID and dc.ToDateID -- get the relevant segment
	where
		dpd.equity_eod >= 1000 -- to get users' first actual entrance, we need the equity >= 1000
  QUALIFY row_number() over (partition by mp.cid ORDER BY mp.date_id asc) = 1 -- this filters in only the first time the user was eligible
)

-- select variant, count(distinct cid) from eligible_users GROUP BY 1
-- select * from eligible_users where cid = 23461 
-- max 1220, zero 1168, control 1155 without equity condition

-- select club, count(cid) usrs, count(distinct cid) dusrs from eligible_users group by 1
-- looking good, a small number of high clubs in

, with_next_30_days as ( -- for each user and each month, add the amount data of the next 30 days following the first day they were eligible
	select
		eu.*,											-- date start of 30 is redundant
		dpd.amount_wo_copy_today,
		dpd.date_id day_of_amount -- redundant
	from
		eligible_users eu -- each user with it's initial parameters (date, equity club etc)
	join
		daily_panel dpd
	on 	eu.cid = dpd.cid
	and dpd.date_id between eu.date_start_of_30_days and eu.date_start_of_30_days + 30
)

select
	cid,
	variant,
	date_start_of_30_days														entered_exp_date,
	equity_start_of_30_days 												start_equity,
	club,
	case when segment = 'Traders' then 1 else 0 end is_trader,
	sum(amount_wo_copy_today) 											amount_invested
from
	with_next_30_days
GROUP BY
	1,2,3,4,5,6