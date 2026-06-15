SELECT InstrumentDisplayName, SymbolFull, sum(InitialAmountCents/100) InvestedAmount,count(DISTINCT dp.PositionID) Positions
  FROM  sfmc.silver_sfmc_accountjourneylogtracking p
 JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cd 
ON cd.GCID = p.GCID 
  JOIN  main.dwh.dim_position dp 
ON dp.CID = cd.CID
  JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
ON di.InstrumentID=dp.InstrumentID
WHERE 
Journey_Name =<[Parameters].[Parameter 6]>
AND OpenOccurred>= CAST(date_format(TimeStamp, 'yyyy-MM-dd') AS TIMESTAMP)   AND  OpenOccurred <=  timestampadd(day, <[Parameters].[Parameter 10]>, date_format(TimeStamp, 'yyyy-MM-dd') )
AND coalesce(dp.IsPartialCloseChild,0)=0
AND coalesce(dp.IsAirdrop,0)=0 
AND (Message=<[Parameters].[Parameter 3]> OR  Message LIKE '%Entry%')
GROUP BY ALL
order by count(DISTINCT dp.PositionID) desc
limit 5