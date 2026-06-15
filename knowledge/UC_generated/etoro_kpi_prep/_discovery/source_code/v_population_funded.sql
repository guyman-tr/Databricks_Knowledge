-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_funded
-- Captured: 2026-05-19T12:20:07Z
-- ==========================================================================

SELECT
    a.DateID,
    a.RealCID,
    SUM(a.Equity) AS Equity
FROM (
    SELECT
        cb.DateID,
        cb.CID AS RealCID,
        SUM(COALESCE(cb.TotalLiability, 0) + COALESCE(cb.actualNWA, 0)) AS Equity
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new cb
    GROUP BY cb.DateID, cb.CID

    UNION ALL

    SELECT
        mcb.BalanceDateID AS DateID,
        mcb.CID AS RealCID,
        mcb.ClosingBalanceBO * mcb.USDApproxRate AS Equity
    FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance mcb
    WHERE mcb.ClosingBalanceCalc > 0

    UNION ALL

    SELECT
        faop.DateID,
        dc.RealCID,
        faop.OptionsTotalEquity AS Equity
    FROM main.etoro_kpi_prep.v_options_aum faop
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON faop.GCID = dc.GCID
    WHERE faop.OptionsTotalEquity > 0
) a
JOIN main.etoro_kpi_prep.v_population_first_time_funded fpftf
    ON a.RealCID = fpftf.RealCID
    AND fpftf.FirstFundedDateID <= a.DateID
GROUP BY a.DateID, a.RealCID
HAVING SUM(a.Equity) > 0
