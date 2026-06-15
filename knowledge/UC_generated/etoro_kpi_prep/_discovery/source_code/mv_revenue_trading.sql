-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.mv_revenue_trading
-- Captured: 2026-05-19T12:08:31Z
-- ==========================================================================

WITH BASEDATA AS (-- Harvesting from Virtual Atom Views
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    TotalFullCommission AS Amount,
    'FullCommission' AS Metric,
    ActionType,
    1 AS IncludedInTotalRevenue,
    IsActiveTrade,
    IsSettled,
    MirrorID,
    SettlementTypeID
  FROM
    main.etoro_kpi_prep.v_revenue_fullcommission
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    TotalCommission AS Amount,
    'Commission' AS Metric,
    ActionType,
    0 AS IncludedInTotalRevenue,
    IsActiveTrade,
    IsSettled,
    MirrorID,
    SettlementTypeID
  FROM
    main.etoro_kpi_prep.v_revenue_commission
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    TicketFeeFixed AS Amount,
    'TicketFeeFixed' AS Metric,
    ActionType,
    1 AS IncludedInTotalRevenue,
    NULL AS IsActiveTrade,
    NULL AS IsSettled,
    NULL AS MirrorID,
    NULL AS SettlementTypeID
  FROM
    main.etoro_kpi_prep.v_revenue_ticketfee_fixed
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    TicketFeeByPercent AS Amount,
    'TicketFeeByPercent' AS Metric,
    ActionType,
    1 AS IncludedInTotalRevenue,
    NULL,
    NULL,
    NULL,
    NULL
  FROM
    main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    RolloverFee AS Amount,
    'RolloverFee' AS Metric,
    NULL,
    1 AS IncludedInTotalRevenue,
    NULL,
    NULL,
    NULL,
    NULL
  FROM
    main.etoro_kpi_prep.v_revenue_rollover
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    Dividend AS Amount,
    'Dividend' AS Metric,
    NULL,
    0 AS IncludedInTotalRevenue,
    NULL,
    NULL,
    NULL,
    NULL
  FROM
    main.etoro_kpi_prep.v_revenue_dividend
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    AdminFee AS Amount,
    'AdminFee' AS Metric,
    NULL,
    1 AS IncludedInTotalRevenue,
    NULL,
    IsSettled,
    MirrorID,
    SettlementTypeID
  FROM
    main.etoro_kpi_prep.v_revenue_adminfee
  UNION ALL
  SELECT
    PositionID,
    RealCID,
    DateID,
    Occurred,
    SpotAdjustFee AS Amount,
    'SpotAdjustFee' AS Metric,
    NULL,
    1 AS IncludedInTotalRevenue,
    NULL,
    IsSettled,
    MirrorID,
    SettlementTypeID
  FROM
    main.etoro_kpi_prep.v_revenue_spotadjustfee
),
DIMPOS AS (SELECT
    PositionID,
    InstrumentID,
    MirrorID,
    IsSettled,
    SettlementTypeID
  FROM
    main.dwh.dim_Position
),
MIRRORS AS (SELECT
    MirrorID,
    MirrorTypeID
  FROM
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
),
IBANOPEN AS (SELECT DISTINCT
    TreeID AS PositionID
  FROM
    main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
),
IBANCLOSE AS (SELECT DISTINCT
    PositionID
  FROM
    main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
),
SQF AS (SELECT DISTINCT
    InstrumentID
  FROM
    main.trading.bronze_etoro_trade_instrumentgroups
  WHERE
    GroupID = 59
)
SELECT
  fca.*,
  COALESCE(fca.IsSettled, dp.IsSettled) AS IsSettled_Final,
  COALESCE(fca.MirrorID, dp.MirrorID) AS MirrorID_Final,
  COALESCE(fca.SettlementTypeID, dp.SettlementTypeID) AS SettlementTypeID_Final,
  CASE
    WHEN io.PositionID IS NOT NULL THEN 1
    ELSE 0
  END AS IsOpenFromIBAN,
  CASE
    WHEN ic.PositionID IS NOT NULL THEN 1
    ELSE 0
  END AS IsClosedToIBAN,
  CASE
    WHEN dm.MirrorTypeID = 4 THEN 1
    ELSE 0
  END AS IsCopyFund,
  di.InstrumentID,
  di.InstrumentTypeID,
  di.InstrumentType,
  di.Name AS InstrumentName,
  di.Symbol,
  CASE
    WHEN sqf.InstrumentID IS NOT NULL THEN 1
    ELSE 0
  END AS IsSQF
FROM
  BASEDATA fca
    LEFT JOIN DIMPOS dp
      ON fca.PositionID = dp.PositionID
    LEFT JOIN MIRRORS dm
      ON COALESCE(fca.MirrorID, dp.MirrorID) = dm.MirrorID
    LEFT JOIN IBANOPEN io
      ON fca.PositionID = io.PositionID
    LEFT JOIN IBANCLOSE ic
      ON fca.PositionID = ic.PositionID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN SQF sqf
      ON di.InstrumentID = sqf.InstrumentID
