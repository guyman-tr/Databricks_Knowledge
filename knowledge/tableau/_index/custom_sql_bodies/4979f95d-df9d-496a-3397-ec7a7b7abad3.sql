WITH fivetran_dedup AS (
  SELECT DISTINCT isin
  FROM main.bi_db.bronze_fivetran_google_sheets_ptp_ib
)

SELECT DISTINCT 
    a.ISINCode,
    a.InstrumentID,
    a.etr_ymd AS ReportDate,
    a.Symbol,
    a.CUSIP,
    a.IsSettled,
    a.InstrumentDisplayName,
    a.InstrumentType,
    a.InstrumentName,
    
    CASE 
        WHEN a.IsSetteled_Cnt = 2 THEN 'both'
        WHEN a.IsSetteled_Cnt = 1 AND a.IsSettled = 1 THEN 'Real Only'
        ELSE 'CFD Only'
    END AS CFD_Real,

    SUM(a.NOP) AS NOP,
    SUM(CASE WHEN a.IsSettled = 1 THEN a.NOP ELSE NULL END) AS NOP_Real,
    SUM(CASE WHEN a.IsSettled = 0 THEN a.NOP ELSE NULL END) AS NOP_CFD,

    SUM(a.Invested_Amount_USD) AS Invested_Amount_USD,
    SUM(CASE WHEN a.IsSettled = 1 THEN a.Invested_Amount_USD ELSE NULL END) AS Invested_Amount_USD_Real,
    SUM(CASE WHEN a.IsSettled = 0 THEN a.Invested_Amount_USD ELSE NULL END) AS Invested_Amount_USD_CFD,

    SUM(a.Unique_CID_Hold) AS Unique_CID_Hold,
    SUM(CASE WHEN a.IsSettled = 1 THEN a.Unique_CID_Hold ELSE NULL END) AS Unique_CID_Hold_Real,
    SUM(CASE WHEN a.IsSettled = 0 THEN a.Unique_CID_Hold ELSE NULL END) AS Unique_CID_Hold_CFD,

    SUM(a.Count_Open_Positions) AS Count_Open_Positions,
    SUM(CASE WHEN a.IsSettled = 1 THEN a.Count_Open_Positions ELSE NULL END) AS Count_Open_Positions_Real,
    SUM(CASE WHEN a.IsSettled = 0 THEN a.Count_Open_Positions ELSE NULL END) AS Count_Open_Positions_CFD

FROM (
    SELECT DISTINCT 
        di.ISINCode,
        a.InstrumentID,
        a.etr_ymd,
        di.Symbol,
        di.CUSIP,
        a.IsSettled,
        di.InstrumentDisplayName,
        di.InstrumentType,
        di.Name AS InstrumentName,
        COUNT(a.IsSettled) OVER (PARTITION BY a.InstrumentID) AS IsSetteled_Cnt,
        SUM(a.NOP) AS NOP,
        SUM(a.Amount) AS Invested_Amount_USD,
        COUNT(DISTINCT a.CID) AS Unique_CID_Hold,
        COUNT(a.PositionID) AS Count_Open_Positions

    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl a
    INNER JOIN main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc 
        ON a.CID = dc.RealCID AND dc.RegulationID NOT IN (6,7,8)
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
        ON a.InstrumentID = di.InstrumentID
    INNER JOIN fivetran_dedup ib 
        ON ib.isin = di.ISINCode

    WHERE a.etr_ymd = CAST(DATE_SUB(CURRENT_DATE(), 1) AS DATE) -- Yesterday


    GROUP BY 
        a.InstrumentID,
        a.IsSettled,
        di.Symbol,
        di.ISINCode,
        di.CUSIP,
        a.IsSettled,
        di.InstrumentDisplayName,
        a.etr_ymd,
        di.InstrumentType,
        di.Name
) a

GROUP BY 
    a.InstrumentID,
    CASE 
        WHEN a.IsSetteled_Cnt = 2 THEN 'both'
        WHEN a.IsSetteled_Cnt = 1 AND a.IsSettled = 1 THEN 'Real Only'
        ELSE 'CFD Only'
    END,
    a.Symbol,
    a.ISINCode,
    a.CUSIP,
    a.IsSettled,
    a.InstrumentDisplayName,
    a.InstrumentType,
    a.etr_ymd,
    a.InstrumentName