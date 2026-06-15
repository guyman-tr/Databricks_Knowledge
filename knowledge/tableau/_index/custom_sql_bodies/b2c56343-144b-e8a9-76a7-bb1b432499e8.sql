SELECT
        a.GCID
        , di.InstrumentType
        , di.InstrumentDisplayName
        , di.Name
        , di.InstrumentID
        , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') AS ActionDate
        , MIN(TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a'))
            OVER (PARTITION BY a.GCID) AS RegDate
        , ROW_NUMBER() OVER (
            PARTITION BY a.GCID
            ORDER BY TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') DESC
        ) AS RowNumber
    FROM main.sfmc.silver_sfmc_accountjourneylogtracking a
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON di.InstrumentID = a.Message
    WHERE 1=1
    AND a.etr_ymd >= '2026-02-12'
   --- AND TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') <= '{rep_end_of_month}'
    AND a.Journey_Name = '10027452589_SB4PerFeb26_Log_BI'
    AND a.Action <> 'StockSelection'