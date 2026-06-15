-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v
-- Captured: 2026-05-19T12:41:01Z
-- ==========================================================================

SELECT 
  DateID as Date
  ,CASE  InstrumentTypeID 
    WHEN 1 THEN 'Currencies'
    WHEN 2 THEN 'Commodities' 
    WHEN 4 THEN 'Indices'
    WHEN 5 THEN 'Stocks'
    WHEN 6 THEN 'ETF' 
    WHEN 10 THEN 'Crypto Currencies' 
    ELSE 'NA' 
  END AS Asset
  ,Exchange
  ,InstrumentID
  ,InstrumentDisplayName
  ,EventName
  ,sum(TotalLocks) as TotalLocks
  ,sum(TotalDuration) as TotalDuration
  FROM main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly
  where
  DateID = date_format(current_date(), 'yyyyMMdd')
  and DuringSession=1
  group by DateID,InstrumentTypeID,Exchange,InstrumentID,InstrumentDisplayName,EventName
  having sum(TotalLocks)>50
UNION ALL
SELECT 
    NULL as Date
    ,NULL AS Asset
    ,NULL as Exchange
    ,NULL as InstrumentID
    ,NULL as InstrumentDisplayName
    ,NULL as EventName
    ,NULL as TotalLocks
    ,NULL as TotalDuration
order by Date desc,Asset,InstrumentID
