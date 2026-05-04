-- ============================================================================
-- main.etoro_kpi.v_spaceship_aum  —  P6 UC ALTER stub (PRESERVATION)
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/spaceship/schemas/etoro_kpi/Views/v_spaceship_aum.md
-- Tier policy:  Existing UC comment preservation — every comment below is
--               byte-for-byte identical to the live UC text as of generation.
--               No citation tags are appended to the deployed text (that would
--               mutate live UC and break idempotent re-deploy semantics).
-- Failure mode: Re-deploying this file against current UC must be a no-op.
--               If it changes any comment, the upstream UC was modified by a
--               concurrent author — investigate before deploying.
-- ============================================================================

COMMENT ON VIEW main.etoro_kpi.v_spaceship_aum IS
'Daily per-user Assets Under Management (FUM) across Spaceship, an Australian investment platform acquired by eToro. Spaceship has four products: (1) Super — superannuation/retirement accounts, identified by member_id mapped to user_id via user_beta; (2) Voyager — ETF managed funds with 5 portfolios (EARTH, EXPLORER, GALAXY have NAV=0; ORIGIN and UNIVERSE have NAV>0); (3) Nova — stock trading, timestamps in UTC (must convert to Australia/Sydney); (4) Money — cash wallet used as the gateway for Voyager/Nova purchases (NOT included in this AUM view). GOTCHAS: (a) All source amounts are in AUD; USD columns use the AUD/USD mid-rate from fact_currencypricewithsplit (InstrumentID=7). (b) Super and Voyager balance tables are weekday-only — Sat/Sun are fill-forwarded from Friday. Nova is 7-day. (c) user_id deduplication is critical — user_beta has 1:many member_id to user_id; this view uses the canonical (lowest) user_id per member. (d) Cross-sell linkage to eToro is via main.bi_db.bronze_sub_accounts_accounts (providerName=Spaceship), joining on contact.user_id = accountId to gcid. Granularity: one row per date x user_id.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.date IS
'Calendar date including weekends. Super and Voyager balances are fill-forwarded from Friday for Sat/Sun since source tables are weekday-only.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.date_id IS
'Date in YYYYMMDD integer format for partition-friendly filtering.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.user_id IS
'Canonical Spaceship user_id, deduplicated via member_canonical (Super) and user_id_map (Voyager/Nova) to resolve 1:many member_id mappings.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.gcid IS
'eToro Global Customer ID from the sub_accounts bridge table (providerName=Spaceship). NULL if the user has no eToro cross-sell linkage.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.super_balance_aud IS
'Superannuation closing balance in AUD. Weekend values are fill-forwarded from last weekday (Friday).';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.voyager_balance_aud IS
'Voyager managed fund balance in AUD (sum across all portfolios: EARTH, EXPLORER, GALAXY, ORIGIN, UNIVERSE). Weekend fill-forwarded.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.nova_balance_aud IS
'Nova stock trading balance in AUD. Available 7 days/week from source — no fill-forward needed.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.total_balance_aud IS
'Sum of super_balance_aud + voyager_balance_aud + nova_balance_aud. Does NOT include Money wallet balances.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.super_balance_usd IS
'Super balance converted to USD using AUD/USD mid-rate ((Ask+Bid)/2) from fact_currencypricewithsplit (InstrumentID=7).';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.voyager_balance_usd IS
'Voyager balance converted to USD using same AUD/USD mid-rate.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.nova_balance_usd IS
'Nova balance converted to USD using same AUD/USD mid-rate.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.total_balance_usd IS
'Total balance (Super+Voyager+Nova) in USD. Excludes Money wallet.';

COMMENT ON COLUMN main.etoro_kpi.v_spaceship_aum.is_funded IS
'TRUE when total_balance_aud > 0, indicating the user holds a positive balance across any product.';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 13:01:14 UTC
-- Batch deploy resume: etoro_kpi deploy batch 4
-- Statements: 14/14 succeeded
-- ====================
