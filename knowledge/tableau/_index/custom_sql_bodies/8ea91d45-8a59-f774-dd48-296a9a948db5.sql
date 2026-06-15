select l.InstrumentId
      ,di.InstrumentDisplayName
      ,di.Symbol
      ,di.InstrumentType
        ,b.IsGroup
      ,l.Spread_Percent_Latest
      ,l.Ask_Latest
      ,l.Bid_Latest
      ,l.Spread_Value_Latest
      ,l.Spread_Value_Latest_NoMarkup
      ,l.UpdateDate
      ,h.Spread_Percent_Latest_Hour
      ,d.Spread_Percent_Latest_Day
      ,d.Max_Spread_Percent_Latest_Day
      ,w.Spread_Percent_Latest_Week
      ,w.Max_Spread_Percent_Latest_Week
      ,m.Spread_Percent_Latest_Month
from (select InstrumentId
            ,AskUnspreaded as Ask_Latest
            ,BidUnspreaded as Bid_Latest
            ,AskSpreaded-BidSpreaded as Spread_Value_Latest
            ,AskUnspreaded-BidUnspreaded as Spread_Value_Latest_NoMarkup
            ,2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded) as Spread_Percent_Latest
            ,row_number() over (partition by InstrumentId order by MarketReceivedTime desc) as rn
            ,MarketReceivedTime as UpdateDate
      from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates
      where etr_ymd >= current_date()) l
left join (select InstrumentId
      ,avg(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Spread_Percent_Latest_Hour
from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates
where etr_ymd >= date_sub(current_date(),1)
and MarketReceivedTime >= current_timestamp() - interval 1 hour
group by InstrumentId) h
on h.InstrumentId = l.InstrumentId
left join (select InstrumentId
      ,avg(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Spread_Percent_Latest_Day
      ,max(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Max_Spread_Percent_Latest_Day
from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates
where etr_ymd >= date_sub(current_date(),1)
and MarketReceivedTime >= current_timestamp() - interval 24 hour
group by InstrumentId) d
on d.InstrumentId = l.InstrumentId
left join (select InstrumentId
      ,avg(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Spread_Percent_Latest_Week
      ,max(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Max_Spread_Percent_Latest_Week
from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates
where etr_ymd >= date_sub(current_date(), 7)
group by InstrumentId) w
on w.InstrumentId = l.InstrumentId
left join (select InstrumentId
      ,avg(2*(AskSpreaded-BidSpreaded)/(AskSpreaded+BidSpreaded)) as Spread_Percent_Latest_Month
from main.dealing.bronze_kafka_dealingstreaming_dealing_main_feed_rates
where etr_ymd >= date_sub(current_date(), 30)
group by InstrumentId) m
on m.InstrumentId = l.InstrumentId
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
on di.InstrumentID = l.InstrumentID
left join (select InstrumentType,
    InstrumentID,
    case when rank <= 10 then 1 else 0 end IsGroup
from (SELECT a.InstrumentID,
        di.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY di.InstrumentType ORDER BY SUM(a.TotalVolume) DESC) AS rank
    FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients a
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
    ON a.InstrumentID = di.InstrumentID
    WHERE a.etr_ymd >= date_sub(current_date(), 90)
    GROUP BY a.InstrumentID, a.Symbol, di.InstrumentType
) a) b
on b.InstrumentID = l.InstrumentID

where rn = 1