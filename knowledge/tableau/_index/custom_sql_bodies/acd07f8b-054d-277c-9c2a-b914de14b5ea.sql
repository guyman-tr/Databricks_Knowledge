-- script for tableau dashboard custom sql run

-- for each user in the experiment, find their last Currency value event, and check the currency
	select
    pd.*,
    from_unixtime(mp.time) event_timestamp,
    -- row_number() over (partition by pd.gcid order by time desc) num_of_event_from_last,
    mp.currency last_currency
	from
		mixpanel.silver mp
	join product_analytics.BI_OUTPUT_Product_Analytics_almoglo_Experiments_AB_Local_Currency_Experiment_Dashboard_Participant_Data pd
		on mp.mp_user_id = pd.gcid
	where
				etr_ymd >= '2023-05-29'
		and	mp.mp_event_name = 'Currency value'
		and from_unixtime(mp.time) >= pd.exp_started_timestamp -- get only events that occurred after user entered experiment
	QUALIFY row_number() over (PARTITION BY pd.gcid ORDER BY time desc) = 1 -- get the lastest currency