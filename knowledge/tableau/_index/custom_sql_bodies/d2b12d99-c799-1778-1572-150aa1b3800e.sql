with eligible_cids AS (
  SELECT DISTINCT RealCID, FromDateID, ToDateID, StateName, StateShortName
  FROM bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily
  --WHERE ToDateID >= CAST(DATE_FORMAT(DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR), 'yyyyMMdd') AS INT)
),
cb as (
    SELECT
        DateID,
        Date, 
        CID,
        sum(COALESCE(ClosingBalance, 0) ) ClosingBalance,
        sum(CASE
            WHEN Regulation = 'FinCEN+FINRA'
            THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
            ELSE COALESCE(ClosingBalance, 0)
            END
        ) AS AdjustedClosingBalance,
        sum(
            COALESCE(
                CASE
                    WHEN AccountType IN ('Affiliate Corporate Account',
                    'Affiliate Private Account')
                    AND PlayerStatus='Trade & MIMO Blocked'
                THEN
                    CASE
                        WHEN Regulation = 'FinCEN+FINRA'
                        THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
                        ELSE COALESCE(ClosingBalance, 0)
                    END
                END
                ,0)
            ) less_affiliate_clients,
        sum(COALESCE(TotalRealCrypto, 0) + COALESCE(PositionPNLCryptoReal, 0)) AS less_RealCryptoAdjusted
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
    WHERE 
        Regulation IN ('FinCEN','FinCEN+FINRA','NYDFS+FINRA')--, 'eToroUS'
        AND IsCreditReportValidCB=1
        and IsValidCustomer=1
        and etr_ymd >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)

    GROUP BY DateID, Date, CID
),
nb as (
    SELECT
        CID
        , DateID
        , COALESCE(bdcbcln.ClosingBalance,0)
        - COALESCE(bdcbcln.RealCryptoClosingBalance,0)
        - COALESCE(bdcbcln.RealStocksClosingBalance,0)
        - COALESCE(bdcbcln.RealFuturesClosingBalance,0)
        + COALESCE(bdcbcln.actualNWA,0)
        AS AdjNegativeBalance
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new bdcbcln
    WHERE 
        Regulation IN ('FinCEN','FinCEN+FINRA','NYDFS+FINRA')--, 'eToroUS')
        AND bdcbcln.TransferDirection = 1
        AND COALESCE(bdcbcln.ClosingBalance,0)
        - COALESCE(bdcbcln.RealCryptoClosingBalance,0)
        - COALESCE(bdcbcln.RealStocksClosingBalance,0)
        - COALESCE(bdcbcln.RealFuturesClosingBalance,0)
        + COALESCE(bdcbcln.actualNWA,0) < 0
        AND bdcbcln.IsCreditReportValidCB = 1
        and bdcbcln.IsValidCustomer=1
        and etr_ymd >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)
),
cal_cb as (
    SELECT
        cb.DateID,
        cb.Date,
        last_day(cb.Date)                  AS EoM,             
        int(date_format(last_day(cb.Date),'yyyyMMdd')) AS EoM_ID, 
        cb.CID,
        COALESCE(cb.AdjustedClosingBalance,0)-
        COALESCE(nb.AdjNegativeBalance,0)-
        COALESCE(cb.less_affiliate_clients,0)-
        COALESCE(cb.less_RealCryptoAdjusted,0)
        AS MSBCashBalance
    FROM cb
    LEFT JOIN nb
        ON cb.CID = nb.CID
        AND cb.DateID = nb.DateID
),

daily_state_summary as (
    select
        c.DateID,
        c.Date,
        c.EoM,
        c.EoM_ID,
        COALESCE(s.StateName, 'Unmapped')     AS StateName,
        COALESCE(s.StateShortName, 'Unmapped')      AS StateShortName,
        sum(c.MSBCashBalance) DailyMSBCashBalance
    from cal_cb c
    left join eligible_cids s
        on c.CID = s.RealCID
        and c.DateID between s.FromDateID and s.ToDateID
    group by 
      c.DateID, c.Date, c.EoM, c.EoM_ID, 
      COALESCE(s.StateName, 'Unmapped'),
      COALESCE(s.StateShortName, 'Unmapped')
),

monthly_aggregation as (
    SELECT
        EoM,
        StateName,
        StateShortName,
        /* month-end value: there is exactly one row per (Reg, State, Date) */
        MAX(CASE WHEN DateID = EoM_ID THEN DailyMSBCashBalance END)   AS MonthEndCashBalance,
        MAX(DailyMSBCashBalance) AS HighestDailyBalance,
        AVG(DailyMSBCashBalance) AS AverageDailyBalance
    FROM daily_state_summary
    GROUP BY 
      EoM, StateName, StateShortName
)

SELECT
    EoM AS MonthEndDate,
    StateName,
    StateShortName,
    MonthEndCashBalance,
    HighestDailyBalance,
    AverageDailyBalance
FROM monthly_aggregation