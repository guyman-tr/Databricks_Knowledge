with status_change 
as
(select event_date
      ,user_id
      ,concat(event_status,' - ',subscription_type) Event
      ,CASE 
      WHEN event_status = LAG(concat(event_status,' - ',subscription_type) ) OVER (PARTITION BY user_id ORDER BY event_date ASC) 
      THEN 0 
      ELSE 1 
    END as IsStatusChanged
    ,subscription_plan_id
    ,event_type
    ,period_start_date
    ,period_end_date
    ,event_status
from main.bi_output.bi_output_deltaapp_subscription_view
where  event_origin = 'subscriptions_api'
and event_type IN ('customer.subscription.created','customer.subscription.updated','customer.subscription.deleted','subscription.cancelled.priority','club_level.sufficient','club_level.insufficient')
--and user_id = '10205625'
)
, create_group 
as
(
   select Event_date
      ,user_id
      ,Event
      ,SUM(IsStatusChanged) OVER (PARTITION BY user_id ORDER BY event_date ASC) AS StatusGroup   
      ,event_type
    ,period_start_date
    ,period_end_date
    ,event_status
from status_change
),agg as
(
select MIN(event_date) over (partition by user_id,StatusGroup) AS FromDate
      ,event_date
      ,user_id
      ,Event
      ,event_type
    ,period_start_date
    ,COALESCE(period_end_date,'9999-12-31T23:59:59Z') period_end_date
from create_group
),final
as
(
select FromDate
      ,user_id
      ,Event
      ,event_type
      ,event_date
    ,period_start_date
    ,period_end_date
    ,row_number() over (partition by user_id order by period_end_date DESC,fromdate DESC) rn
from agg), subscr_type
as
(select user_id
      ,event_date
      ,event_status
      ,CASE WHEN pv.price_id = 'price_1SCkAJRzh1NLBzh2YhU1CIcP' THEN 'EUR'
            WHEN pv.Price_id = 'price_1SNEi8Rzh1NLBzh2cPZcH6Jo' THEN 'GBP'
            WHEN pv.Price_id = 'price_1SCkAJRzh1NLBzh2kfVpBZ1t' THEN 'USD' 
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2pVJhAqV1' THEN 'EUR'
            WHEN pv.Price_id = 'price_1SNEiiRzh1NLBzh2scWiHi8L' THEN 'GBP'
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2YkjMWF9m' THEN 'USD' 
            END Price_Currency
      ,CASE WHEN pv.price_id = 'price_1SCkAJRzh1NLBzh2YhU1CIcP' THEN 4.99
            WHEN pv.Price_id = 'price_1SNEi8Rzh1NLBzh2cPZcH6Jo' THEN 4.99
            WHEN pv.Price_id = 'price_1SCkAJRzh1NLBzh2kfVpBZ1t' THEN 4.99 
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2pVJhAqV1' THEN 49.99
            WHEN pv.Price_id = 'price_1SNEiiRzh1NLBzh2scWiHi8L' THEN 49.99
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2YkjMWF9m' THEN 49.99
            END Price_Amount
      ,CASE WHEN Product_id = 'prod_T92EQnmQcA5F0U' THEN 'PLATINUM Monthly'
            WHEN Product_id = 'prod_T92E7tai3VkZFJ' THEN 'PLATINUM Yearly' END Product
from main.bi_output.bi_output_deltaapp_subscription_view pv
where event_type = 'customer.subscription.updated'
and product_id is not null)
select f.FromDate
      ,f.user_id AS GCID
      ,dc.RealCID as CID
      ,f.Event
      ,f.event_type
      ,f.event_date
      ,f.period_start_date
      ,f.period_end_date
      ,s.Price_Currency
      ,s.Price_Amount
      ,s.Product
      ,dc1.MarketingRegionManualName AS MarketingRegion
      ,dpl.Name ClubTier
      ,concat(dm.FirstName,' ',dm.LastName) AccountManager
      ,dc.AccountManagerID AccountManagerID
from final f
left join lateral 
(select user_id
      ,event_date
      ,event_status
      ,CASE WHEN pv.price_id = 'price_1SCkAJRzh1NLBzh2YhU1CIcP' THEN 'EUR'
            WHEN pv.Price_id = 'price_1SNEi8Rzh1NLBzh2cPZcH6Jo' THEN 'GBP'
            WHEN pv.Price_id = 'price_1SCkAJRzh1NLBzh2kfVpBZ1t' THEN 'USD' 
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2pVJhAqV1' THEN 'EUR'
            WHEN pv.Price_id = 'price_1SNEiiRzh1NLBzh2scWiHi8L' THEN 'GBP'
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2YkjMWF9m' THEN 'USD' 
            END Price_Currency
      ,CASE WHEN pv.price_id = 'price_1SCkAJRzh1NLBzh2YhU1CIcP' THEN 4.99
            WHEN pv.Price_id = 'price_1SNEi8Rzh1NLBzh2cPZcH6Jo' THEN 4.99
            WHEN pv.Price_id = 'price_1SCkAJRzh1NLBzh2kfVpBZ1t' THEN 4.99 
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2pVJhAqV1' THEN 49.99
            WHEN pv.Price_id = 'price_1SNEiiRzh1NLBzh2scWiHi8L' THEN 49.99
            WHEN pv.Price_id = 'price_1SCk9pRzh1NLBzh2YkjMWF9m' THEN 49.99
            END Price_Amount
      ,CASE WHEN Product_id = 'prod_T92EQnmQcA5F0U' THEN 'PLATINUM Monthly'
            WHEN Product_id = 'prod_T92E7tai3VkZFJ' THEN 'PLATINUM Yearly' END Product
     ,event_type
from main.bi_output.bi_output_deltaapp_subscription_view pv
where 
event_type in ('customer.subscription.created','customer.subscription.updated')
and product_id is not null
and f.user_id = pv.user_id
order by event_date
limit 1) s
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
on f.user_id = dc.GCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
on dc.CountryID = dc1.CountryID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
on dc.PlayerLevelID = dpl.PlayerLevelID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
on dc.AccountManagerID = ManagerID
where  IsValidCustomer = 1
and rn = 1