with base as (
SELECT   
      dc.RealCID, dc.GCID,
      am.OpenDDate AS Apex_OpenDate,
      op.OptionsApexID,
      MIN(ca.ProcessDate) AS Apex_FTDDate,
      min(tr.ProcessDate) as Apex_FirstTradedDate 
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.general.bronze_usabroker_apex_options op 
    ON op.GCID = dc.GCID
  JOIN (
                select AccountNumber, OpenDDate--, RegisteredRepCode
                from main.general.bronze_sodreconciliation_apex_ext765_accountmaster 
                where RegisteredRepCode='UK1'
                group by AccountNumber, OpenDDate--, RegisteredRepCode ORDER BY RegisteredRepCode
            ) am 
    ON op.OptionsApexID = am.AccountNumber
  LEFT JOIN main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca 
    ON ca.AccountNumber = op.OptionsApexID--am.AccountNumber 
       AND ca.PayTypeCode = 'C' 
       AND EnteredBy IN ('ACH','WRD')
       and ca.RegisteredRepCode='UK1'
  LEFT JOIN main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr 
    ON tr.AccountNumber = op.OptionsApexID--am.AccountNumber 
    and tr.RegisteredRepCode='UK1'
  GROUP BY 
      dc.RealCID, dc.GCID,
      am.OpenDDate,
      op.OptionsApexID
) 

SELECT  
  RealCID, GCID, OptionsApexID,
  Apex_OpenDate as EventDate,
  'Apex Account Open' as Event
FROM base
where Apex_OpenDate is not null 

union all 
SELECT  
  RealCID, GCID, OptionsApexID,
  Apex_FTDDate as EventDate,
  'Apex FTD' as Event
FROM base
where Apex_FTDDate is not null 

union all 
SELECT  
  RealCID, GCID, OptionsApexID,
  Apex_FirstTradedDate as EventDate,
  'Apex FA' as Event
FROM base
where Apex_FirstTradedDate is not null