with a as ( -- gather mixpanel events and data
    select
        mp.mp_user_id               gcid,
        mp_event_name               event,
        from_unixtime(mp.`time`)    event_ts,
        mp.card_view_timestamp,
        mp.amount,
        mp.default_amount,
        mp.leverage,
        mp.default_leverage,
        mp.application,
        mp.order_id_1 order_id,
        mp.position_id,
        time,
        mp.instrument_type
    from
        main.mixpanel.silver mp
    where
            mp.etr_ymd between '2024-04-15' and '2024-05-15'
        and portfolio = 'Real'
        and mp.mp_user_id is not null
        and (
               (mp_event_name = 'Open Trade - Card View')
            or (mp_event_name = 'Open Trade - Button Clicked' and place_order is true and default_amount is not null and default_leverage is not null)
            or (mp_event_name = 'Open Order - Success')
        )
    group by all
)

, b as ( -- join cv events to bc events and orderids
    select
        bc.gcid,
        bc.application,
        cv.time                                                                                         cv_time,
        bc.time                                                                                         bc_time,
        bc.time-cv.time                                                                                 time_diff_epoch,
        bc.card_view_timestamp                                                                          bc_timestmap,
        cast(concat_ws(cast(bc.gcid as string),cast(bc.card_view_timestamp as string)) as string)       bc_id,
        case when bc.default_amount = bc.amount and bc.default_leverage = bc.leverage then 1 else 0 end is_default_trade,
        case when bc.time-cv.time <= 5 then 1 else 0 end                                                is_quick_trade,
        case 
          when bc.instrument_type = 'Stocks' and bc.leverage = 1 then 'Real Stocks'
          when bc.instrument_type = 'ETF' and bc.leverage = 1 then 'Real ETF'
          else bc.instrument_type
        end                                                                                             instrument_type_elaborated
    from
         (select * from a where event = 'Open Trade - Card View')       cv
    join (select * from a where event = 'Open Trade - Button Clicked')  bc
        on cv.card_view_timestamp = bc.card_view_timestamp    
        and cv.gcid = bc.gcid
    group by all
)

, order_data as ( -- get BE data
  select
    o.time order_time,
    o.order_id,
    o.gcid,
    dp.NetProfit pnl,
    dp.Commission     etoro_commissions,
    dp.FullCommission full_commissions,
    row_number() over (partition by o.gcid, o.order_id order by o.event_ts asc) rnum_q
  from
    (select * from a where event = 'Open Order - Success') o
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    on o.gcid = dc.GCID
  join main.dwh.dim_position dp
    on o.order_id = dp.OrderID
    and dc.RealCID = dp.CID
  where
        dp.etr_ymd >= '2024-04-01' -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    and dp.MirrorID = 0                                -- filter out positions of copy
    and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
    and coalesce(dp.IsPartialCloseChild, 0) != 1    -- filter out partial positions
  qualify rnum_q = 1
)

, c as (
  select
    b.*,
    od.order_id,
    od.pnl,
    od.etoro_commissions,
    od.full_commissions
  from
    b
  left join order_data od
    on b.gcid = od.gcid
    and od.order_time - b.bc_time between 0 and 1 -- order success fired within 3 seconds after open trade button clicked fired
)

, 2_sec_mistake as (
  select
    '2 sec' as mistake_rule,
    instrument_type_elaborated,
    application,
    case when time_diff_epoch <= 2 and is_default_trade = 1 then 'mistake' else 'normal' end is_mistake,
    sum(case when c.etoro_commissions is not null then 1 else 0 end) has_commission_data,
    sum(c.etoro_commissions)  etoro_commissions,
    sum(c.full_commissions)   full_commissions,
    count(distinct bc_id) total_open_trade_FE
  from
      c
  group by all
)

, 5_sec_mistake as (
  select
    '5 sec' as mistake_rule,
    instrument_type_elaborated,
    application,
    case when time_diff_epoch <= 5 and is_default_trade = 1 then 'mistake' else 'normal' end is_mistake,
    sum(case when c.etoro_commissions is not null then 1 else 0 end) has_commission_data,
    sum(c.etoro_commissions)  etoro_commissions,
    sum(c.full_commissions)   full_commissions,
    count(distinct bc_id) total_open_trade_FE
  from
      c
  group by all
)

select * from 2_sec_mistake
union
select * from 5_sec_mistake