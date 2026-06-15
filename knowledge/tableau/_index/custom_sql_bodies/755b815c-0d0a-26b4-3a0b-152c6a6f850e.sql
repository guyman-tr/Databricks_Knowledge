with logins as (
  select GCID, etr_ym, count(*) as login_count
  from main.mixpanel.login_events
  where etr_ym >= '2024-01' and GCID is not null
  group by etr_ym, GCID
),

dates as (
  select distinct etr_ym
  from logins
),

gcids as (
  select distinct GCID
  from logins
),

all_combinations as (
  select g.GCID, d.etr_ym
  from gcids g
  cross join dates d
),

with_logins as (
  select 
    a.GCID,
    a.etr_ym,
    l.login_count
  from all_combinations a
  left join logins l
    on a.GCID = l.GCID and a.etr_ym = l.etr_ym
),

with_prev as (
  select
    wl.*,
    lag(wl.login_count) over (partition by wl.GCID order by wl.etr_ym) as prev_login_count,
    min(case when wl.login_count is not null then wl.etr_ym end) over (partition by wl.GCID) as first_login_ym
  from with_logins wl
),

with_life_cycle as (
select
  GCID,
  etr_ym,
  login_count,
  case
    when login_count is not null and etr_ym = first_login_ym then 'new_user'
    when login_count is not null and prev_login_count is not null then 'active_user'
    when login_count is null and prev_login_count is not null then 'dormant_user'
    when login_count is not null and prev_login_count is null and etr_ym != first_login_ym then 'resurected_user'
    else null
  end as user_status
from with_prev
order by GCID, etr_ym
),

joined as (
  select
    lc.*,
    fsm.RealCID, CountryID, VerificationLevelID, PlayerLevelID, IsDepositor,
    row_number() over (
      partition by lc.GCID, lc.etr_ym
      order by fsm.UpdateDate desc nulls last
    ) as rn
  from with_life_cycle lc
  left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsm
    on lc.GCID = fsm.GCID
    and date_format(to_date(concat(lc.etr_ym, '-01')), 'yyyyMM') >= date_format(to_date(cast(fsm.FromDateID as string), 'yyyyMMdd'), 'yyyyMM')
    and date_format(to_date(concat(lc.etr_ym, '-01')), 'yyyyMM') <= date_format(to_date(cast(fsm.ToDateID as string), 'yyyyMMdd'), 'yyyyMM')
  where lc.user_status is not null 
)

select RealCID CID, etr_ym, user_status, login_count, cc.Name Country, VerificationLevelID, pl.Name PlayerLevel, IsDepositor
from joined j left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cc 
                on cc.CountryID=j.CountryID
              left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
                on pl.PlayerLevelID = j.PlayerLevelID
where rn = 1