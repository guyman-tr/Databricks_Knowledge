with trades as(
  select CID, etr_ym, count(distinct case when MirrorID = 0 then PositionID else MirrorID end) trade_count, case when sum(case when di.InstrumentTypeID in(1,2,4) then 1 else 0 end) > 0 then '1' else '0' end as CFD_Trader
  from main.dwh.dim_position dp left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di on dp.InstrumentID = di.InstrumentID
  where etr_ym >= '2023-01' and MirrorID = 0
  group by etr_ym, CID
),

dates as (
  select distinct etr_ym
  from trades
),

cids as (
  select distinct CID
  from trades
),

all_combinations as (
  select g.CID, d.etr_ym
  from cids g
  cross join dates d
),

with_trades as (
  select 
    a.CID,
    a.etr_ym,
    t.trade_count
  from all_combinations a
  left join trades t
    on a.CID = t.CID and a.etr_ym = t.etr_ym
),

with_prev as (
  select
    wt.*,
    lag(wt.trade_count) over (partition by wt.CID order by wt.etr_ym) as prev_trade_count,
    min(case when wt.trade_count is not null then wt.etr_ym end) over (partition by wt.CID) as first_trade_ym
  from with_trades wt
),

with_life_cycle as (
select
  CID,
  etr_ym,
  trade_count,
  case
    when trade_count is not null and etr_ym = first_trade_ym then 'new_user'
    when trade_count is not null and prev_trade_count is not null then 'active_user'
    when trade_count is null and prev_trade_count is not null then 'dormant_user'
    when trade_count is not null and prev_trade_count is null and etr_ym != first_trade_ym then 'resurected_user'
    else null
  end as user_status
from with_prev
),

joined as (
  select
    lc.*,
    fsm.RealCID, CountryID, VerificationLevelID, PlayerLevelID, IsDepositor,
    row_number() over (
      partition by lc.CID, lc.etr_ym
      order by fsm.UpdateDate desc nulls last
    ) as rn
  from with_life_cycle lc
  left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsm
    on lc.CID = fsm.RealCID
    and date_format(to_date(concat(lc.etr_ym, '-01')), 'yyyyMM') >= date_format(to_date(cast(fsm.FromDateID as string), 'yyyyMMdd'), 'yyyyMM')
    and date_format(to_date(concat(lc.etr_ym, '-01')), 'yyyyMM') <= date_format(to_date(cast(fsm.ToDateID as string), 'yyyyMMdd'), 'yyyyMM')
  where lc.user_status is not null 
)

select RealCID CID, etr_ym, user_status, trade_count, cc.Name Country, VerificationLevelID, pl.Name PlayerLevel, IsDepositor
from joined j left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cc 
                on cc.CountryID=j.CountryID
              left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
                on pl.PlayerLevelID = j.PlayerLevelID
where rn = 1 and etr_ym >= '2024-01'