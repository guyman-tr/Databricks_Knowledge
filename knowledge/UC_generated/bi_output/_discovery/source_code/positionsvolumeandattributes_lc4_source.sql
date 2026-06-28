-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.positionsvolumeandattributes_lc4_source
-- Captured: 2026-06-19T14:32:39Z
-- ==========================================================================

WITH BaseOpen AS (
    SELECT
          di.SellCurrencyID
        , di.InstrumentType
        , dp.IsSettled
        , dp.CID
        , dp.OpenOccurred AS Date_
        , 'OpenDataFlag' AS position_event_flag
        , SUM(dp.Amount) AS Amount_Total
        , SUM(CASE WHEN oi.PositionID IS NOT NULL THEN dp.Amount END) AS Amount_lc
        , COUNT(*) AS num_position_open_total
        , COUNT(CASE WHEN oi.PositionID IS NOT NULL THEN dp.PositionID END) AS num_position_open_lc
    FROM main.dwh.dim_position dp
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet oi
        ON dp.PositionID = oi.PositionID
    WHERE dp.OpenOccurred >= date_add(current_date(), -120)
      AND (dp.IsPartialCloseChild = 0 OR dp.IsPartialCloseChild IS NULL)
      AND dp.MirrorID = 0
    GROUP BY 
          dp.CID
        , dp.OpenOccurred
        , dp.IsSettled
        , di.SellCurrencyID
        , di.InstrumentType
),

/********************************************
    FinalOpen
********************************************/
FinalOpen AS (
    SELECT
          fsc.AccountTypeID
        , fsc.CountryID AS CountryID
        , NULL AS Region
        , NULL AS CountryName
        , bse.SellCurrencyID
        , bse.InstrumentType
        , bse.IsSettled
        , bse.CID
        , bse.Date_
        , bse.position_event_flag
        , bse.Amount_Total
        , bse.Amount_lc
        , bse.num_position_open_total
        , bse.num_position_open_lc
        , dpl.Name AS Club
    FROM BaseOpen bse
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON bse.CID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND CAST(date_format(bse.Date_, 'yyyyMMdd') AS INT)
           BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    WHERE fsc.CountryID IN (
        52,19,54,72,196,95,55,12,197,165,100,67,57,184,82,154,185,13,74,
        118,218,94,135,119,164,168,191,143,79,126,102,117,32,112
    )
),

/********************************************
    BaseClose
********************************************/
BaseClose AS (
    SELECT
          di.SellCurrencyID
        , di.InstrumentType
        , dp.IsSettled
        , dp.CID
        , dp.CloseOccurred AS Date_
        , 'CloseDataFlag' AS position_event_flag
        , SUM(dp.Amount) AS Amount_Total
        , SUM(CASE WHEN ci.PositionID IS NOT NULL THEN dp.Amount END) AS Amount_lc
        , COUNT(*) AS num_position_open_total
        , COUNT(CASE WHEN ci.PositionID IS NOT NULL THEN dp.PositionID END) AS num_position_open_lc
    FROM main.dwh.dim_position dp
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet ci
        ON dp.PositionID = ci.PositionID
    WHERE dp.CloseOccurred >= date_add(current_date(), -120)
      AND dp.MirrorID = 0
    GROUP BY 
          dp.CID
        , dp.CloseOccurred
        , dp.IsSettled
        , di.SellCurrencyID
        , di.InstrumentType
),

/********************************************
    FinalClose
********************************************/
FinalClose AS (
    SELECT
          fsc.AccountTypeID
        , fsc.CountryID AS CountryID
        , NULL AS Region
        , NULL AS CountryName
        , bse.SellCurrencyID
        , bse.InstrumentType
        , bse.IsSettled
        , bse.CID
        , bse.Date_
        , bse.position_event_flag
        , bse.Amount_Total
        , bse.Amount_lc
        , bse.num_position_open_total
        , bse.num_position_open_lc
        , dpl.Name AS Club
    FROM BaseClose bse
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON bse.CID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND CAST(date_format(bse.Date_, 'yyyyMMdd') AS INT)
           BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    WHERE fsc.CountryID IN (
        52,19,54,72,196,95,55,12,197,165,100,67,57,184,82,154,185,13,74,
        118,218,94,135,119,164,168,191,143,79,126,102,117,32,112
    )
)

/********************************************
    Final (Union Open + Close)
********************************************/
SELECT * FROM FinalOpen
UNION ALL
SELECT * FROM FinalClose
