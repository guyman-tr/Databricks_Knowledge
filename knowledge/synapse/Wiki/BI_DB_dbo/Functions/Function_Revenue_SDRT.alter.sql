-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_SDRT
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_sdrt
-- Col comments: 5 added, 9 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_sdrt (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  GCID COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  SDRT COMMENT '-1 * Amount WHERE ActionTypeID = 35 AND IsFeeDividend = 3. Source: BI_DB_Fact_Customer_Action_Position_Distribution.Amount. (T2 — Function_Revenue_SDRT)',
  InstrumentID COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.',
  PositionID COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.',
  IsBuy COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.',
  IsSettled COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.',
  SettlementTypeID COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.',
  IsMarginTrade COMMENT 'CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END. Source: BI_DB_Fact_Customer_Action_Position_Distribution. (T2 — Function_Revenue_SDRT)',
  IsCopy COMMENT 'CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END. Source: BI_DB_Fact_Customer_Action_Position_Distribution. (T2 — Function_Revenue_SDRT)',
  InstrumentTypeID COMMENT 'Direct pass-through from Dim_Instrument.InstrumentTypeID. (T1 — Function_Revenue_SDRT)',
  IsValidCustomer COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer. (T1 — Function_Revenue_SDRT)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_SDRT > Returns UK SDRT (Stamp Duty Reserve Tax) style fee rows from the customer action position distribution (ActionTypeID 35, IsFeeDividend 3), with amount flipped to revenue sign as SDRT, copy and margin flags, and instrument type from Dim_Instrument. (SQL header comment refers generically to dividend/fee distribution; business filter is IsFeeDividend = 3.)'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_SDRT > Returns UK SDRT (Stamp Duty Reserve Tax) style fee rows from the customer action position distribution (ActionTypeID 35, IsFeeDividend 3), with amount flipped to revenue sign as SDRT, copy and margin flags, and instrument type from Dim_Instrument. (SQL header comment refers generically to dividend/fee distribution; business filter is IsFeeDividend = 3.)')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.RealCID,
    fca.GCID,
    fca.DateID,
    fca.Occurred,
    -1 * fca.Amount AS SDRT,
    fca.InstrumentID,
    fca.PositionID,
    fca.IsBuy,
    fca.IsSettled,
    fca.SettlementTypeID,
    CASE WHEN fca.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade,
    CASE WHEN fca.MirrorID <> 0 THEN 1 ELSE 0 END AS IsCopy,
    di.InstrumentTypeID,
    fca.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON fca.InstrumentID = di.InstrumentID
WHERE fca.ActionTypeID = 35
    AND fca.IsFeeDividend = 3

;
