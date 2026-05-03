-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_PnL_Single_Day
-- Generated: 2026-04-12 | apply_tvf_comments.py
-- Target: UC view comment + column comments
-- UC Target: main.etoro_kpi_prep.v_pnl_single_day
-- Source: Synapse TVF BI_DB_dbo.Function_PnL_Single_Day
-- UC cols: 19 total, 19 matched from wiki section 4
-- =============================================================================


-- ---- Table Comment ----
ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.Function_PnL_Single_Day > single date full PnL picture (realized + unreaized change)'
);

-- ---- Table Tags ----
ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'source_object_type' = 'TVF',
    'source_tvf' = 'Function_PnL_Single_Day',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'tvf-comments-2026-04-12'
);

-- ---- Column Descriptions (documented only; ALTER COLUMN not supported on views) ----
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `DateID`: @dateID. Source: . (T2 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `CID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `PositionID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `UnrealizedPnLStart`: SUM(UnrealizedPnLStart). Source: . (T2 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `UnrealizedPnLEnd`: SUM(UnrealizedPnLEnd). Source: . (T2 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `UnrealizedPnLChange`: SUM(UnrealizedPnLChange). Source: . (T2 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `NetProfit`: SUM(NetProfit). Source: . (T2 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `InstrumentID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `MirrorID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `Leverage`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsBuy`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsSettled`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `HedgeServerID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `SettlementTypeID`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `ClosedOnDate`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsFuture`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsCopyFund`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsMarginTrade`: Direct pass-through from . (T1 - Function_PnL_Single_Day)
-- ALTER VIEW main.etoro_kpi_prep.v_pnl_single_day (col comment not supported on views without DDL recreation)
-- Column `IsSQF`: case when InstrumentID is not null then 1 else 0 end. Source: . (T2 - Function_PnL_Single_Day)
