select d.InstrumentId
      ,di.InstrumentType
      ,di.Symbol
      ,MarketReceivedTime
      ,2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded) as Spread_Percent_Latest_Day
from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates d
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
on di.InstrumentID = d.InstrumentID
where d.etr_ymd >= date_sub(current_date(),1)
and MarketReceivedTime >= current_timestamp() - interval 24 hour