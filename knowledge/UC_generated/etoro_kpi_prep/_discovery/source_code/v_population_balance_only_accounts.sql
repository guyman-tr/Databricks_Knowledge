-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_balance_only_accounts
-- Captured: 2026-05-19T12:19:19Z
-- ==========================================================================

WITH snapshot_dates AS (
    SELECT DISTINCT DateID
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
),
balanceprep_tp AS (
    SELECT
        bs.DateID,
        cb.CID AS RealCID,
        SUM(COALESCE(cb.TotalLiability, 0) + COALESCE(cb.actualNWA, 0)) AS Equity
    FROM snapshot_dates bs
    INNER JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new cb
        ON cb.DateID = bs.DateID
    GROUP BY bs.DateID, cb.CID
),
maxbalance_tp AS (
    SELECT DateID, RealCID, Equity AS TPMaxEquity
    FROM balanceprep_tp
    WHERE Equity > 0
),
max_iban AS (
    SELECT
        bs.DateID,
        mcb.CID AS RealCID,
        SUM(COALESCE(mcb.ClosingBalanceBO, 0) * COALESCE(mcb.USDApproxRate, 0)) AS eMoneyMaxEquity
    FROM snapshot_dates bs
    INNER JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance mcb
        ON mcb.BalanceDateID = bs.DateID
        AND mcb.ClosingBalanceCalc > 0
    GROUP BY bs.DateID, mcb.CID
),
max_options AS (
    SELECT
        CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT) AS DateID,
        dc.RealCID,
        MAX(bps.TotalEquity) AS TotalEquity
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
    INNER JOIN main.general.bronze_usabroker_apex_options op
        ON bps.AccountNumber = op.OptionsApexID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON op.GCID = dc.GCID
    WHERE bps.OfficeCode IN ('4GS', '5GU')
        AND bps.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
    GROUP BY CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT), dc.RealCID
    HAVING MAX(bps.TotalEquity) > 0
),
candidates AS (
    SELECT DateID, RealCID FROM maxbalance_tp
    UNION
    SELECT DateID, RealCID FROM max_iban
    UNION
    SELECT DateID, RealCID FROM max_options
),
balance_users AS (
    SELECT
        c.DateID,
        c.RealCID,
        COALESCE(tp.TPMaxEquity, 0) + COALESCE(ib.eMoneyMaxEquity, 0) + COALESCE(mo.TotalEquity, 0) AS MaxAnyEquity
    FROM candidates c
    LEFT JOIN maxbalance_tp tp
        ON tp.DateID = c.DateID AND tp.RealCID = c.RealCID
    LEFT JOIN max_iban ib
        ON ib.DateID = c.DateID AND ib.RealCID = c.RealCID
    LEFT JOIN max_options mo
        ON mo.DateID = c.DateID AND mo.RealCID = c.RealCID
    WHERE COALESCE(tp.TPMaxEquity, 0) + COALESCE(ib.eMoneyMaxEquity, 0) + COALESCE(mo.TotalEquity, 0) > 0
)
SELECT
    bu.DateID,
    bu.RealCID,
    bu.MaxAnyEquity
FROM balance_users bu
WHERE NOT EXISTS (
    SELECT 1
    FROM main.etoro_kpi_prep.v_population_active_traders pat
    WHERE pat.DateID = bu.DateID
        AND pat.RealCID = bu.RealCID
)
AND NOT EXISTS (
    SELECT 1
    FROM main.etoro_kpi_prep.v_population_portfolio_only ppo
    WHERE ppo.DateID = bu.DateID
        AND ppo.RealCID = bu.RealCID
)
