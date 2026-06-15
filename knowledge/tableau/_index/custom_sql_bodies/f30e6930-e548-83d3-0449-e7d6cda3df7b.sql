select row_number() over (partition by q0.RealCID order by event_date DESC) as rn
      ,q0.RealCID
      ,q0.GCID
      ,q0.trial_active
      ,q0.event_type
      ,q0.event_status
      ,q0.event_date
      ,q0.event_origin
      ,q0.price_id
      ,q0.Price_Currency
      ,q0.Price_Amount
      ,q0.product_id
      ,q0.Product
      ,q0.event_id 
      ,q0.subscription_interval
      ,q0.subscription_type
      ,q0.subscription_plan_id
      ,q0.period_start_date
      ,q0.period_end_date
      ,q0.Amount
      ,q0.payment_currency
      ,dr.Name AS Regulation
      ,dc1.Name AS Country
      ,fsc.PlayerStatusID
      ,plst.Name PlayerStatus
      ,IsCreditReportValidCB
      ,IsValidCustomer
from (
select RealCID
      ,pv.user_id as GCID
      ,pv.trial_active
      ,pv.event_type
      ,pv.event_status
      ,pv.event_date
      ,pv.event_origin
      ,pv.price_id
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
      ,pv.product_id
      ,CASE WHEN Product_id = 'prod_T92EQnmQcA5F0U' THEN 'PLATINUM Monthly'
            WHEN Product_id = 'prod_T92E7tai3VkZFJ' THEN 'PLATINUM Yearly' END Product
      ,pv.event_id 
      ,pv.subscription_interval
      ,pv.subscription_type
      ,pv.subscription_plan_id
      ,pv.period_start_date
      ,pv.period_end_date
      ,pv.payment_amount_received AS Amount
      ,pv.payment_currency
from main.bi_output.bi_output_deltaapp_subscription_view pv 
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
on pv.user_id = dc.GCID
where pv.event_origin = 'stripe'
and  pv.event_type in ('invoice.payment_succeeded','invoice.finalized')
and pv.trial_active = false
and payment_amount_received >0
group by all
union all
select RealCID
      ,pv.user_id as GCID
      ,pv.trial_active
      ,pv.event_type
      ,pv.event_status
      ,pv.event_date
      ,pv.event_origin
      ,pv.price_id
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
      ,pv.product_id
      ,CASE WHEN Product_id = 'prod_T92EQnmQcA5F0U' THEN 'PLATINUM Monthly'
            WHEN Product_id = 'prod_T92E7tai3VkZFJ' THEN 'PLATINUM Yearly' END Product
      ,pv.event_id 
      ,pv.subscription_interval
      ,pv.subscription_type
      ,pv.subscription_plan_id
      ,pv.period_start_date
      ,pv.period_end_date
      ,pv.payment_amount_refunded * -1.0 AS Amount
      ,pv.payment_currency
from main.bi_output.bi_output_deltaapp_subscription_view pv 
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked  dc 
on pv.user_id = dc.GCID
where pv.event_origin = 'stripe'
and  pv.event_type = 'charge.refunded'
and pv.trial_active = false
and payment_amount_refunded >0
group by all)q0
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
on q0.RealCID = fsc.RealCID
and FromDateID <=date_format(event_date,'yyyyMMdd')
and ToDateID >=date_format(event_date,'yyyyMMdd')
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
on fsc.RegulationID = dr.ID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
on fsc.CountryID = dc1.CountryID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus plst 
on fsc.PlayerStatusID = plst.PlayerStatusID