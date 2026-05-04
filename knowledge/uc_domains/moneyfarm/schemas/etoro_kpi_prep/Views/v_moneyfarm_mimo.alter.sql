-- ============================================================================
-- main.etoro_kpi_prep.v_moneyfarm_mimo  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/moneyfarm/schemas/etoro_kpi_prep/Views/v_moneyfarm_mimo.md
-- Tier source:  T1 = view DDL ([view_def]). View-level COMMENT preserved
--               verbatim from existing analyst-authored UC text (165 chars).
-- ============================================================================

COMMENT ON VIEW main.etoro_kpi_prep.v_moneyfarm_mimo IS
'MoneyFarm MIMO (first deposit) style facts by date_id. Filter date_id. Example: SELECT * FROM main.etoro_kpi_prep.v_moneyfarm_mimo WHERE date_id = 20251231 LIMIT 50;';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.date IS
'Event date in UTC. From CAST(SUBSTRING(EventMetadata.CreatedAt, 1, 10) AS DATE). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.dateid IS
'Date in YYYYMMDD integer format. CAST(DATE_FORMAT(date,''yyyyMMdd'') AS INT). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.gcid IS
'eToro Global Customer ID from EventPayloadRowData.EventMetadata.Gcid (filtered NOT NULL upstream). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName=''Moneyfarm''). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.total_deposits_gbp IS
'Sum of PORTFOLIO_DEPOSIT amounts (positive) for (date, gcid) in GBP. From event_data_json $.data.amount when amount > 0 AND event_type = ''PORTFOLIO_DEPOSIT''. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.total_withdrawals_gbp IS
'Sum of PORTFOLIO_WITHDRAW amounts (ABS, positive) for (date, gcid) in GBP. Source amounts are negative; the view stores them as positive. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.net_flow_gbp IS
'total_deposits_gbp - total_withdrawals_gbp. Negative when withdrawals exceed deposits. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.total_deposits_usd IS
'total_deposits_gbp x COALESCE(GBP/USD mid-rate, 0). Mid-rate from fact_currencypricewithsplit InstrumentID=2 ((Ask+Bid)/2). Missing rate -> 0.0. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.total_withdrawals_usd IS
'total_withdrawals_gbp x COALESCE(GBP/USD mid-rate, 0). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.net_flow_usd IS
'net_flow_gbp x COALESCE(GBP/USD mid-rate, 0). Sign-preserving USD net flow. [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.count_deposits IS
'Count of PORTFOLIO_DEPOSIT events for (date, gcid). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.count_withdrawals IS
'Count of PORTFOLIO_WITHDRAW events for (date, gcid). [view_def]';

COMMENT ON COLUMN main.etoro_kpi_prep.v_moneyfarm_mimo.is_ftd IS
'TRUE on a GCID''s first-deposit date (MIN(date) where total_deposits > 0). Computed via the first_deposit_dates CTE. [view_def]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 13:01:46 UTC
-- Batch deploy resume: etoro_kpi_prep deploy batch 4
-- Statements: 13/13 succeeded
-- ====================
