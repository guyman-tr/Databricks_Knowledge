WITH min_timestamp AS (
        SELECT 
        MIN(CAST(DATE_FORMAT(TimeStamp, 'yyyyMMdd') AS INT)) AS min_dateid, 
        min(cast(TimeStamp as date))min_ts_d
    FROM sfmc.silver_sfmc_accountjourneylogtracking
    WHERE Journey_Name = <[Parameters].[Parameter 6]>
        AND (Message = <[Parameters].[Parameter 3]> OR Message LIKE '%Entry%')
),

sfmc_data AS (
    SELECT 
        sfmc.GCID,
        sfmc.TimeStamp,
        sfmc.Message,
        sfmc.etr_ymd,
        dc.RealCID,
        dc.CountryID,
        dc.IsValidCustomer,
        dc1.MarketingRegionManualName,
        dc.FirstDepositDate,
        di.SymbolFull,
        dp.OpenOccurred,
        dp.IsPartialCloseChild,
        dp.IsAirdrop,
        fca.ActionTypeID,
        fca.Occurred
    FROM sfmc.silver_sfmc_accountjourneylogtracking sfmc
    JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.GCID = sfmc.GCID AND dc.IsValidCustomer = 1
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 ON dc.CountryID = dc1.CountryID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca ON fca.RealCID = dc.RealCID 
        AND fca.ActionTypeID IN (7, 14) 
        AND fca.DateID>=(SELECT min_dateid FROM min_timestamp)--fca.DateID>=20240701
        AND fca.Occurred >= CAST(date_format(sfmc.TimeStamp, 'yyyy-MM-dd') AS TIMESTAMP) 
        AND fca.Occurred <= timestampadd(day, <[Parameters].[Parameter 10]>, date_format(sfmc.TimeStamp, 'yyyy-MM-dd'))
    LEFT JOIN main.dwh.dim_position dp ON dp.CID = dc.RealCID 
        AND dp.OpenDateID>=(SELECT min_dateid FROM min_timestamp)--OpenDateID>=20240701
        AND dp.OpenOccurred >= CAST(date_format(sfmc.TimeStamp, 'yyyy-MM-dd') AS TIMESTAMP) 
        AND dp.OpenOccurred <= timestampadd(day, <[Parameters].[Parameter 10]>, date_format(sfmc.TimeStamp, 'yyyy-MM-dd'))
        AND coalesce(dp.IsPartialCloseChild, 0) = 0
        AND coalesce(dp.IsAirdrop, 0) = 0
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di ON di.InstrumentID = dp.InstrumentID
    WHERE sfmc.Journey_Name = <[Parameters].[Parameter 6]>
        AND (sfmc.Message = <[Parameters].[Parameter 3]> OR sfmc.Message LIKE '%Entry%')
        AND sfmc.etr_ymd >= (SELECT min_ts_d FROM min_timestamp)--'2024-07-01'
)
SELECT 
    COUNT(DISTINCT sfmc_data.GCID) AS Users,
    COUNT(DISTINCT CASE WHEN sfmc_data.SymbolFull IS NOT NULL THEN sfmc_data.GCID END) AS IsOpenPosition,
    COUNT(DISTINCT CASE WHEN sfmc_data.SymbolFull = <[Parameters].[Parameter 7]> THEN sfmc_data.GCID END) AS IsOpenPositionInstrument1,
    COUNT(DISTINCT CASE WHEN sfmc_data.SymbolFull = <[Parameters].[Parameter 8]> THEN sfmc_data.GCID END) AS IsOpenPositionInstrument2,
    COUNT(DISTINCT CASE WHEN sfmc_data.SymbolFull = <[Parameters].[Parameter 9]> THEN sfmc_data.GCID END) AS IsOpenPositionInstrument3,
    CASE WHEN sfmc_data.Message LIKE '%Test%' OR sfmc_data.Message LIKE '%Email%' THEN 'Test' ELSE 'Control' END AS Group,
    COUNT(DISTINCT CASE WHEN sfmc_data.ActionTypeID = 7 THEN sfmc_data.RealCID END) AS Depositors,
    COUNT(DISTINCT CASE WHEN sfmc_data.ActionTypeID = 14 THEN sfmc_data.RealCID END) AS Logins,
    COUNT(DISTINCT CASE WHEN DATEDIFF(DAY, CAST(date_format(sfmc_data.TimeStamp, 'yyyy-MM-dd') AS TIMESTAMP), sfmc_data.FirstDepositDate) BETWEEN 0 AND <[Parameters].[Parameter 10]> AND sfmc_data.TimeStamp<=sfmc_data.FirstDepositDate THEN RealCID END) AS IsFTD,
    sfmc_data.MarketingRegionManualName AS Region,
    sfmc_data.etr_ymd AS Date
FROM sfmc_data
GROUP BY all