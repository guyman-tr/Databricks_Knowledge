SELECT distinct
    bps.AccountNumber,
    op.GCID,
    r.Name as Current_regulation,
    am.RegisteredRepCode,
    CAST(bps.ProcessDate AS DATE) AS ProcessDate,
    bps.TotalEquity AS OptionsTotalEquity,
    CAST(bps.PositionMarketValue AS DECIMAL(18, 2)) AS OptionsPositionMarketValue,
    CAST(bps.NetBalance AS DECIMAL(18, 2)) as OptionsTotalCashBalance /* cash balance */,
    CAST(bps.CashEquity AS DECIMAL(18, 2)) as CashAvailable_AccountTypeCash /* account type=cash */,
    CAST(
      bps.MarginEquity AS DECIMAL(18, 2)
    ) as CashAvailable_AccountTypeMargin /*account type=margin*/
  FROM
    main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
      JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
        ON bps.AccountNumber = am.AccountNumber
      JOIN main.general.bronze_usabroker_apex_options op
        ON am.AccountNumber = op.OptionsApexID
      join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked d   
        on d.GCID=op.GCID
      join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r 
        on r.ID=d.RegulationID
  WHERE
    am.OfficeCode IN ('4GS', '5GU')
    and (
      RegisteredRepCode = 'GAT'
      OR (
        RegisteredRepCode = 'FO1'
        AND OptionLevel IS NOT NULL
      )
    )
    AND am.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
    AND bps.etr_ymd >= add_months(date_trunc('month', current_date()), -6)