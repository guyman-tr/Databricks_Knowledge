-- ============================================================================
-- main.etoro_kpi.v_spaceship_mimo  —  P6 UC ALTER stub (mirror of prep)
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/spaceship/schemas/etoro_kpi/Views/v_spaceship_mimo.md
-- Mirror of:    knowledge/uc_domains/spaceship/schemas/etoro_kpi_prep/Views/v_spaceship_mimo.alter.sql
-- This view is `SELECT * FROM main.etoro_kpi_prep.v_spaceship_mimo`. The
-- column comments below are intentionally identical byte-for-byte to the prep
-- view's so both copies stay aligned when consumers DESCRIBE either schema.
-- ============================================================================

COMMENT ON VIEW main.etoro_kpi.v_spaceship_mimo IS
'Money-In / Money-Out (MIMO) daily fact view for Spaceship. SELECT * pass-through of main.etoro_kpi_prep.v_spaceship_mimo (which holds the actual CTE pipeline). Granularity: one row per (date, product, is_internal_transfer, user_id). Aggregates gross deposit/withdrawal flows in AUD across the four Spaceship products: Super, Money, Voyager, Nova. AUD/USD via fact_currencypricewithsplit InstrumentID=7. Includes orphan-FTD rows from user_beta. is_internal_transfer = FALSE only for true external wallet flows (Money DEPOSIT/WITHDRAWAL family); Voyager and Nova are always TRUE. See main.etoro_kpi_prep.v_spaceship_mimo for the full per-product transaction-type rules. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.date IS
'Activity date in Australia/Sydney. Money/Nova use FROM_UTC_TIMESTAMP from UTC. Super uses paid_date; Voyager uses effective_date. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.date_id IS
'Date in YYYYMMDD integer format for partition-friendly filtering. Equals CAST(DATE_FORMAT(date,''yyyyMMdd'') AS INT). [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.product IS
'Spaceship product. Values: Super, Money, Voyager, Nova. Each has distinct deposit/withdrawal rules in the source CTEs. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.is_internal_transfer IS
'TRUE for moves inside Spaceship (Voyager/Nova purchases, Super pension events, etc.); FALSE only for true external wallet inflow/outflow (Money: USER_DEPOSIT/USER_WITHDRAWAL/etc.). [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.user_id IS
'Canonical Spaceship user_id. UUID v4 from Spaceship Metabase. Resolved via member_canonical for Super and contact_mapping for Money. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.gcid IS
'eToro Global Customer ID from sub_accounts (providerName=''Spaceship''). NULL when the user is Spaceship-only (no eToro cross-sell). [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.total_deposits_aud IS
'Sum of deposit amounts in AUD for (date, product, user_id). Per-product rules: Super=Contributions/Tax; Money=USER_DEPOSIT family; Voyager=inflow_aud_amount; Nova=BUY trades. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.total_withdrawals_aud IS
'Sum of withdrawal amounts in AUD (positive). Per-product: Super=Benefit/Fees/Tax/Premium; Money=USER_WITHDRAWAL family; Voyager=outflow_aud_amount; Nova=SELL trades. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.net_flow_aud IS
'total_deposits_aud - total_withdrawals_aud for (date, product, user_id). Negative when withdrawals exceed deposits. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.total_deposits_usd IS
'total_deposits_aud x COALESCE(AUD/USD mid-rate, 0). Rate from fact_currencypricewithsplit InstrumentID=7. Missing rate -> 0.0. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.total_withdrawals_usd IS
'total_withdrawals_aud x COALESCE(AUD/USD mid-rate, 0). [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.net_flow_usd IS
'net_flow_aud x COALESCE(AUD/USD mid-rate, 0). Sign-preserving USD net flow. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.count_deposits IS
'Count of deposit events for (date, product, user_id). Per-product is_deposit flags rolled up via SUM. [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.count_withdrawals IS
'Count of withdrawal events for (date, product, user_id). [view_def]';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_mimo.is_ftd IS
'TRUE on a user''s first-deposit date (any product, MIN per user). Includes orphan-FTD rows synthesised from user_beta when no transaction row exists for the FTD date. [view_def]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 13:01:21 UTC
-- Batch deploy resume: etoro_kpi deploy batch 4
-- Statements: 16/16 succeeded
-- ====================
