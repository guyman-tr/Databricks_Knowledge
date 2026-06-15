-- =============================================================================
-- Crypto Balance: Month-End / Highest Daily / Average Daily, by State (USA)
-- Window: trailing 2 years from current month, dynamic on each run
-- Source: positionpnl (CID-level crypto aggregates, used to match US regulatory
--         requirement that CID-level totals reconcile to per-asset breakdowns)
-- =============================================================================

-- --- Daily NOP per (CID, state, regulation), crypto only ---------------------
-- One row per CID-day. Map join attributes each daily snapshot to the state
-- and regulation in effect on that day.

with daily_nop AS (
  SELECT
      bdppl.Date,
      last_day(bdppl.Date) AS EOM,
      d.Name                  as Regulation,
      bdppl.CID,
      m.StateName,
      m.StateShortName,
      SUM(bdppl.Amount + bdppl.PositionPnL) AS NOPCrypto
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl bdppl
  /* 
  Rationale: used positionpnl table instead of gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new:
  - to ensure cid level aggregate from crypto assets aligned with sum of crypto asset breakdown by CID (US regulatory requirements)
  */
  JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON bdppl.InstrumentID = di.InstrumentID
  AND di.InstrumentTypeID = 10
  JOIN  bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily m
    ON bdppl.CID = m.RealCID
      AND bdppl.DateID BETWEEN m.FromDateID AND m.ToDateID
  join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation d  
    on d.ID=m.RegulationID
  WHERE
    bdppl.DateID >= CAST(DATE_FORMAT(DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR),
                          'yyyyMMdd') AS INT)           -- partition pruning
  GROUP BY
    bdppl.Date, last_day(bdppl.Date), d.Name, bdppl.CID, m.StateName, m.StateShortName
),

daily_state as (
  SELECT
      Date,
      EOM,
      StateName,
      StateShortName,
      SUM(NOPCrypto) AS DailyNOPCrypto
  FROM daily_nop
  GROUP BY
      Date, EOM, StateName, StateShortName
),

monthly_agg as (
    SELECT
        EoM,
        StateName,
        StateShortName,
        -- EOM balance (exactly last_day snapshot)
        SUM(CASE WHEN Date = MaxDateInMonth THEN DailyNOPCrypto END) AS MonthEndNOPBalance,
        -- Highest daily balance across month
        MAX(DailyNOPCrypto) AS HighestDailyNOPBalance,
        -- Average daily balance across month
        AVG(DailyNOPCrypto) AS AverageDailyNOPBalance
FROM (
    SELECT *,
           -- This finds the latest date available for each specific state in each specific month
           MAX(Date) OVER(PARTITION BY EoM, StateName) as MaxDateInMonth
    FROM daily_state
) t
GROUP BY 
    EoM, StateName, StateShortName
)

SELECT
    EoM AS MonthEndDate,
    StateName,
    StateShortName,
    MonthEndNOPBalance,
    HighestDailyNOPBalance,
    AverageDailyNOPBalance
FROM monthly_agg