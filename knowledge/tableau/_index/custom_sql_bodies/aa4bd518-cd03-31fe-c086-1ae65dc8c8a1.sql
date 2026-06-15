with wallet_snapshot AS (										
    SELECT  
        efrbn.RealCID
        ,efrbn.BalanceDate
        ,efrbn.BalanceDateID
        ,SUM(efrbn.BalanceUSD) BalanceUSD
    FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew efrbn 
    JOIN main.wallet.bronze_walletdb_wallet_cryptotypes  ect  ON efrbn.CryptoID =ect.CryptoID 
    WHERE efrbn.BalanceDate >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)
    AND efrbn.RegulationID IN (7,8,14)
    AND efrbn.BalanceUSD >0 and efrbn.Balance>0
    AND efrbn.AMLClosureEvent=0
    AND efrbn.ComplianceClosureEvent=0
    AND efrbn.IsTestAccount=0
    AND ect.DisplayName NOT LIKE  'eToro%' 
    GROUP BY 	  
        efrbn.RealCID, efrbn.BalanceDate, efrbn.BalanceDateID	
)
,daily_state as (
    select
        c.BalanceDate,
        last_day(c.BalanceDate) AS EoM,
        coalesce(s.StateName, 'Unmapped') AS StateName,
        coalesce(s.StateShortName, 'Unmapped') AS StateShortName,
        sum(c.BalanceUSD) as DailyBalanceUSD
    from wallet_snapshot c
    left join bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily s
        on c.RealCID = s.RealCID
        and c.BalanceDateID between s.FromDateID and s.ToDateID
    group by 
      c.BalanceDate, last_day(c.BalanceDate), coalesce(s.StateName, 'Unmapped'), coalesce(s.StateShortName, 'Unmapped')
)
,
-- NEW CTE: Aggregate daily data to get highest daily balance, and average daily balance per month
monthly_agg as (
SELECT 
    EoM,
    StateName,
    StateShortName,
    -- We take the MAX of the balance only for the row that matches the MaxDate of that month
    SUM(CASE WHEN BalanceDate = MaxDateInMonth THEN DailyBalanceUSD ELSE 0 END) AS MonthEndWalletBalance,
    MAX(DailyBalanceUSD) AS HighestDailyBalance,
    AVG(DailyBalanceUSD) AS AverageDailyBalance
FROM (
    SELECT *,
           -- This finds the latest date available for each specific state in each specific month
           MAX(BalanceDate) OVER(PARTITION BY EoM, StateName) as MaxDateInMonth
    FROM daily_state
) t
GROUP BY 
    EoM, StateName, StateShortName
)
-- Final SELECT statement to combine aggregated data with month-end snapshot
SELECT
    EoM AS MonthEndDate,
    StateName,
    StateShortName,
    MonthEndWalletBalance,
    HighestDailyBalance,
    AverageDailyBalance
FROM monthly_agg
--ORDER BY EOM, StateShortName, StateName;