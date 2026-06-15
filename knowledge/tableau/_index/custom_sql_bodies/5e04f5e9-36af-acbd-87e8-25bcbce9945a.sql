with afu_def as (
  select 
  *, 
  case when   cast(
    regexp_extract(regexp_extract(str_engangements, CONCAT(<[Parameters].[Parameter 1]>, r"\d+")), r"\d+") 
    as int
  ) >= <[Parameters].[Parameter 2]> 
    then "AFU" else "Not AFU" end as is_afu
  from (
    select 
      *,
      concat(
        "likes", coalesce(likes, 0), ";", 
        "comments", coalesce(comments, 0), ";",
        "posts", coalesce(posts, 0), ";",
        "shares", coalesce(shares, 0), ";"
      ) as str_engangements
    from `etoroml.DataSet_SocialActivity.feed_traders`
  )
  where is_pi = "Not PI"
)
select 
    "# Positions Opened" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(manual_positions_opened, 0) as value,
    PERCENTILE_CONT(manual_positions_opened, 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all
 
select 
    "# Positions Closed" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(manual_positions_closed, 0) as value,
    PERCENTILE_CONT(coalesce(manual_positions_closed, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all 

select 
    "USD Invested" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(usd_invested_in_open_manual, 0) as value,
    PERCENTILE_CONT(coalesce(usd_invested_in_open_manual, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all

select 
    "# Copies" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(copies_opened, 0) as value,
    PERCENTILE_CONT(coalesce(copies_opened, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all

select 
    "Copy USD Invested" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(copies_usd_invested, 0) as value,
    PERCENTILE_CONT(coalesce(copies_usd_invested, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all

select 
    "Comission USD Manual" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(manual_positions_comission, 0) as value,
    PERCENTILE_CONT(coalesce(manual_positions_comission, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all

select 
    "Leverage" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(manual_mean_leverage, 0) as value,
    PERCENTILE_CONT(coalesce(manual_mean_leverage, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all

select 
    "Copy Comission USD" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(copies_comission, 0) as value,
    PERCENTILE_CONT(coalesce(copies_comission, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def

union all 

select 
    "Avg. Net Profit" as trading_metric,
    cid,
    is_afu,
    is_pi,
    club_tier,
    coalesce(avg_net_profit, 0) as value,
    PERCENTILE_CONT(coalesce(avg_net_profit, 0), 0.5) OVER(partition by is_afu) as value_median
from afu_def