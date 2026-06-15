WITH date_ref AS (
    SELECT 
        FullDate AS Friday,
        dateadd(FullDate,-1 )AS Thursday
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
    WHERE DayNumberOfWeek_Sun_Start = 6  -- Fridays
      AND DateKey BETWEEN date_format(add_months(current_date(), -3), 'yyyyMMdd')
                     AND date_format(current_date(), 'yyyyMMdd')
),
friday_data AS (
    SELECT distinct
        cast(ProcessDate as date) AS ProcessDate,
        AccountNumber,
        TotalEquity,
        NetBalance as CashEquity
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
    WHERE OfficeCode in ('4GS','5GU')
      AND AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
),
valid_fridays AS (
    SELECT *
    FROM friday_data
    WHERE ProcessDate IN (SELECT Friday FROM date_ref)
),
missing_fridays AS (
    SELECT d.Friday, d.Thursday
    FROM date_ref d
    LEFT ANTI JOIN valid_fridays f
        ON d.Friday = f.ProcessDate
),
thursday_fallback AS (
    SELECT distinct 
        cast(ProcessDate as date) AS ProcessDate,
        AccountNumber,
        TotalEquity,
        CashEquity
    FROM friday_data
    WHERE ProcessDate IN (SELECT Thursday FROM missing_fridays)
),
final_pop AS (
    SELECT * FROM valid_fridays
    UNION ALL
    SELECT * FROM thursday_fallback
),

with_saturday AS (
    SELECT 
        p.*,
        cast(dd.FullDate as date) AS Adjusted_EoW_Saturday
    FROM final_pop p
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd_base
        ON dd_base.FullDate = p.ProcessDate
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd
        ON dd.CalendarYear = dd_base.CalendarYear
       AND dd.SSWeekNumberOfYear = dd_base.SSWeekNumberOfYear
       AND dd.DayNumberOfWeek_Sun_Start = 7  -- Saturday
),

pop_info AS (
    SELECT distinct 
        p.AccountNumber, 
        am.RegisteredRepCode, 
        g.GCID, 
        r.Name AS Regulation
    FROM final_pop p
    JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
        ON am.AccountNumber = p.AccountNumber
    JOIN main.general.bronze_usabroker_apex_options op 
        ON p.AccountNumber = op.OptionsApexID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked g 
        ON op.GCID = g.GCID
       AND g.IsValidCustomer = 1
       AND g.RegulationID IN (2, 7, 8, 12,14)
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r  
        ON r.ID = g.RegulationID
    GROUP BY p.AccountNumber, am.RegisteredRepCode, g.GCID, r.Name
)

SELECT 
    ws.ProcessDate AS ApexReportDate,  -- could be Friday or Thursday fallback
    ws.Adjusted_EoW_Saturday,
    pi.Regulation, 
    SUM(ws.TotalEquity) AS Apex_4gs_TotalEquity,
    SUM(ws.CashEquity) AS Apex_4gs_CashEquity
FROM with_saturday ws
JOIN pop_info pi 
    ON ws.AccountNumber = pi.AccountNumber
GROUP BY 
    ws.ProcessDate,
    ws.Adjusted_EoW_Saturday,
    pi.Regulation