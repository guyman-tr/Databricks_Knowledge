-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_positionsvolumeandattributes_lc4_source
-- Captured: 2026-06-19T14:35:19Z
-- ==========================================================================

WITH BaseOpen AS (
    SELECT
          di.SellCurrencyID
        , di.InstrumentType
        , dp.IsSettled
        , dp.CID
        , CAST(dp.OpenOccurred AS DATE) AS Date_
        , 'OpenDataFlag' AS position_event_flag
        , COALESCE(SUM(dp.Amount), 0) AS Amount_Total
        , COALESCE(SUM(CASE WHEN oi.PositionID IS NOT NULL THEN dp.Amount END), 0) AS Amount_lc
        , COALESCE(COUNT(*), 0) AS num_positions_total
        , COALESCE(COUNT(CASE WHEN oi.PositionID IS NOT NULL THEN dp.PositionID END), 0) AS num_positions_lc
    FROM main.dwh.dim_position dp
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet oi
        ON dp.PositionID = oi.PositionID
    WHERE dp.OpenOccurred  >= DATE('2024-04-01')
      AND (dp.IsPartialCloseChild = 0 OR dp.IsPartialCloseChild IS NULL)
      AND dp.MirrorID = 0
    GROUP BY 
          di.SellCurrencyID, di.InstrumentType,
          dp.IsSettled, dp.CID,
          CAST(dp.OpenOccurred AS DATE)
),

/********************************************
    FinalOpen
********************************************/
FinalOpen AS (
    SELECT
          fsc.AccountTypeID
        , c.Region
        , c.Name AS CountryName
        , bse.SellCurrencyID
        , bse.InstrumentType
        , bse.IsSettled
        , bse.CID
        , bse.Date_
        , bse.position_event_flag
        , COALESCE(bse.Amount_Total, 0) AS Amount_Total
        , COALESCE(bse.Amount_lc, 0) AS Amount_lc
        , COALESCE(bse.num_positions_total, 0) AS num_positions_total
        , COALESCE(bse.num_positions_lc, 0) AS num_positions_lc
        , dpl.Name AS Club
        , CASE WHEN ema.CID IS NOT NULL THEN 1 ELSE 0 END AS HasEMoneyAccount
    FROM BaseOpen bse
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON bse.CID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND CAST(date_format(bse.Date_, 'yyyyMMdd') AS INT)
           BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c
        ON fsc.CountryID = c.CountryID
    LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ema
        ON bse.CID = ema.CID
       AND ema.GCID_Unique_Count = 1
       AND ema.IsValidCustomer = 1
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
        , CAST(dp.CloseOccurred AS DATE) AS Date_
        , 'CloseDataFlag' AS position_event_flag
        , COALESCE(SUM(dp.Amount), 0) AS Amount_Total
        , COALESCE(SUM(CASE WHEN ci.PositionID IS NOT NULL THEN dp.Amount END), 0) AS Amount_lc
        , COALESCE(COUNT(*), 0) AS num_positions_total
        , COALESCE(COUNT(CASE WHEN ci.PositionID IS NOT NULL THEN dp.PositionID END), 0) AS num_positions_lc
    FROM main.dwh.dim_position dp
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet ci
        ON dp.PositionID = ci.PositionID
    WHERE  dp.CloseOccurred >= DATE('2024-04-01')
      AND dp.MirrorID = 0
    GROUP BY
          di.SellCurrencyID, di.InstrumentType,
          dp.IsSettled, dp.CID,
          CAST(dp.CloseOccurred AS DATE)
),

/********************************************
    FinalClose
********************************************/
FinalClose AS (
    SELECT
          fsc.AccountTypeID
        , c.Region
        , c.Name AS CountryName
        , bse.SellCurrencyID
        , bse.InstrumentType
        , bse.IsSettled
        , bse.CID
        , bse.Date_
        , bse.position_event_flag
        , COALESCE(bse.Amount_Total, 0) AS Amount_Total
        , COALESCE(bse.Amount_lc, 0) AS Amount_lc
        , COALESCE(bse.num_positions_total, 0) AS num_positions_total
        , COALESCE(bse.num_positions_lc, 0) AS num_positions_lc
        , dpl.Name AS Club
        , CASE WHEN ema.CID IS NOT NULL THEN 1 ELSE 0 END AS HasEMoneyAccount
    FROM BaseClose bse
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON bse.CID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND CAST(date_format(bse.Date_, 'yyyyMMdd') AS INT)
           BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c
        ON fsc.CountryID = c.CountryID
    LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ema
        ON bse.CID = ema.CID
       AND ema.GCID_Unique_Count = 1
       AND ema.IsValidCustomer = 1
)

/********************************************
    FINAL OUTPUT
********************************************/
SELECT
      AccountTypeID        AS AccountTypeID_as_of_position_date
    , Region               AS Region_as_of_position_date
    , CountryName          AS CountryName_as_of_position_date
    , SellCurrencyID
    , InstrumentType
    , IsSettled
    , CID
    , Date_               AS position_event_date
    , position_event_flag
    , Amount_Total
    , Amount_lc
    , num_positions_total
    , num_positions_lc
    , Club                 AS Club_as_of_position_date
    , HasEMoneyAccount
FROM FinalOpen

UNION ALL

SELECT
      AccountTypeID        AS AccountTypeID_as_of_position_date
    , Region               AS Region_as_of_position_date
    , CountryName          AS CountryName_as_of_position_date
    , SellCurrencyID
    , InstrumentType
    , IsSettled
    , CID
    , Date_               AS position_event_date
    , position_event_flag
    , Amount_Total
    , Amount_lc
    , num_positions_total
    , num_positions_lc
    , Club                 AS Club_as_of_position_date
    , HasEMoneyAccount
FROM FinalClose
