-- ============================================================================
-- main.etoro_kpi_prep.v_moneyfarm_aum  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/moneyfarm/schemas/etoro_kpi_prep/Views/v_moneyfarm_aum.md
-- Tier source:  T1 = view DDL ([view_def]) for all 7 columns. View-level
--               COMMENT is the existing analyst-authored text (preserved
--               byte-for-byte for idempotent re-deploy).
-- ============================================================================

COMMENT ON VIEW main.etoro_kpi_prep.v_moneyfarm_aum IS
'MoneyFarm AUM snapshot by date_id (YYYYMMDD int) and customer keys. External MoneyFarm feed; filter date_id. Example: SELECT COUNT(*) FROM main.etoro_kpi_prep.v_moneyfarm_aum WHERE date_id = 20251231;';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.date IS
'Snapshot date from silver_moneyfarm_etoro_mf_aum.etr_ymd. One row per (date, GCID) — all of a customer''s portfolios are summed for the day. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.dateid IS
'Date in YYYYMMDD integer format. CAST(DATE_FORMAT(date,''yyyyMMdd'') AS INT). Prefer for partition-friendly filtering. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.gcid IS
'eToro Global Customer ID. Filtered NOT NULL upstream (GCID IS NOT NULL in CTE). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName=''Moneyfarm''). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.total_balance_gbp IS
'Sum of Market_Value across all the GCID''s portfolios for the date, in GBP. From silver_moneyfarm_etoro_mf_aum. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.total_balance_usd IS
'total_balance_gbp x COALESCE(GBP/USD mid-rate, 0). Mid-rate from fact_currencypricewithsplit InstrumentID=2 ((Ask+Bid)/2). Missing rate -> 0.0. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.is_funded IS
'TRUE when total_balance_gbp > 0. Aligned with eToro DDR''s IsFunded semantic. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_aum.portfolio_count IS
'Distinct PortfolioID count for (date, GCID). One GCID can hold multiple MoneyFarm portfolios concurrently (e.g. Managed ISA + DIY ISA + Cash ISA). [view_def]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 13:01:38 UTC
-- Batch deploy resume: etoro_kpi_prep deploy batch 4
-- Statements: 8/8 succeeded
-- ====================
