-- Target: EOM (End-of-Month) holdings by crypto and state

SELECT
    last_day(bdppl.Date) AS EOM,
    d.Name                  as Regulation,
    di.Name                 AS CryptoName,
    m.StateName,
    m.StateShortName,
    SUM(bdppl.Amount + bdppl.PositionPnL) AS BalanceUSD
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl bdppl
JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
  ON bdppl.InstrumentID = di.InstrumentID
 AND di.InstrumentTypeID = 10
JOIN  main.bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily m
  ON bdppl.CID = m.RealCID
    AND bdppl.DateID BETWEEN m.FromDateID AND m.ToDateID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation d  
  on d.ID=m.RegulationID
WHERE
  bdppl.Date >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)           -- partition pruning
  AND bdppl.Date = last_day(bdppl.Date)  -- keep EOM snapshots only
GROUP BY
  last_day(bdppl.Date),
  d.Name,
  di.Name,
  m.StateName,
  m.StateShortName