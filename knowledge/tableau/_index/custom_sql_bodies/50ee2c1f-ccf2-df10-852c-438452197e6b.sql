with mimo_enriched  AS (
        SELECT distinct
                f.RealCID,
                f.etr_ymd    AS TxDate,
                f.DateID,
                f.ActionTypeID,
                f.Amount,
                f.DepositID,
                f.WithdrawID,
                p.StateName,
                p.StateShortName,
                p.RegulationID,
                last_day(f.etr_ymd)               AS TxMonthEnd
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction f
        JOIN bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily p
                        ON p.RealCID = f.RealCID
                        AND f.DateID BETWEEN p.FromDateID and p.ToDateID
        WHERE 
                f.ActionTypeID IN (7, 8)                 -- deposits / cashouts
                AND f.FundingTypeID <> 42                -- exclude EtoroOptions (incomplete data ingestion)
                AND f.etr_ymd >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)       -- partition pruning
)
SELECT
        e.TxMonthEnd,
        r.Name as Regulation,
        e.StateName,
        e.StateShortName,
        SUM(CASE WHEN e.ActionTypeID = 7 THEN e.Amount ELSE 0 END) AS FiatDepositsAmount,
        SUM(CASE WHEN e.ActionTypeID = 8 THEN e.Amount ELSE 0 END) AS FiatCashoutsAmount,
        COUNT_IF(e.ActionTypeID = 7 AND e.DepositID IS NOT NULL) AS FiatDepositsCount,
        COUNT_IF(e.ActionTypeID = 8 AND e.WithdrawID IS NOT NULL) AS FiatCashoutsCount
FROM mimo_enriched e
        LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r
                ON e.RegulationID = r.ID     
GROUP BY
        e.TxMonthEnd,
        r.Name,
        e.StateName,
        e.StateShortName