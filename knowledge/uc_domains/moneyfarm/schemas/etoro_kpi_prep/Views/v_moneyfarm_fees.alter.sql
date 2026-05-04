-- ============================================================================
-- main.etoro_kpi_prep.v_moneyfarm_fees  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/moneyfarm/schemas/etoro_kpi_prep/Views/v_moneyfarm_fees.md
-- Status:       PLACEHOLDER. View body is `WHERE 1=0` — always 0 rows. The
--               column comments deployed below explicitly call out the
--               placeholder state so agents won't be confused.
-- Tier source:  T1 = view DDL ([view_def]). View-level COMMENT preserved
--               verbatim from existing analyst-authored UC text.
-- ============================================================================

COMMENT ON VIEW main.etoro_kpi_prep.v_moneyfarm_fees IS
'MoneyFarm fee facts by date_id. Filter date_id for one day. Example: SELECT SUM(fee_amount) FROM main.etoro_kpi_prep.v_moneyfarm_fees WHERE date_id = 20251231;';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_fees.date IS
'Activity date for the fee event. PLACEHOLDER (always NULL until fee logic is implemented). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_fees.dateid IS
'Date in YYYYMMDD integer format. PLACEHOLDER (always NULL). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_fees.gcid IS
'eToro Global Customer ID at fee-event time. PLACEHOLDER (always NULL). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName=''Moneyfarm'') once populated. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_fees.total_fees_gbp IS
'Sum of fee amounts in GBP for (date, gcid). PLACEHOLDER (always NULL). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_fees.total_fees_usd IS
'total_fees_gbp x GBP/USD mid-rate. PLACEHOLDER (always NULL). [view_def]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 13:01:40 UTC
-- Batch deploy resume: etoro_kpi_prep deploy batch 4
-- Statements: 6/6 succeeded
-- ====================
