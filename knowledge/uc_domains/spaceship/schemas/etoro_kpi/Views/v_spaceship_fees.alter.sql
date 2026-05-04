-- UC ALTER deploy stub for main.etoro_kpi.v_spaceship_fees
--
-- Source provenance (per .cursor/rules/uc-domain-doc/05-generate-doc.mdc):
--   * Object comment: Tier-1 UC comment authored 2026-04-16 by guyman@etoro.com
--     (re-deployment is idempotent; this file is the audit trail for redeploy after CTAS-style wipes).
--   * Column comments: Tier-1 UC comments + Confluence anchors
--     [BDP/12918358038], [CS/13335789570], [BG/13131186194].
--   * No Tier-4 or UNVERIFIED comments are emitted from this file.
--
-- VIEWs in UC require COMMENT ON COLUMN syntax (ALTER TABLE ... ALTER COLUMN COMMENT
-- raises EXPECT_TABLE_NOT_VIEW). Prefer COMMENT ON COLUMN here.

-- ===== Object-level =====
COMMENT ON VIEW main.etoro_kpi.v_spaceship_fees IS 'Fee revenue by product, user, and day across all Spaceship fee types. Spaceship is an Australian investment platform with five fee streams: (1) Super — admin/member fees from super_transactions (type=Fees). Excludes the one-off SFT event on 2024-05-18. (2) Voyager (account) — account-level fees from voyager_account_fees, keyed by account_fee_created_at_date. (3) Voyager (mgmt) — daily management fees pro-rated to each user by their balance share of portfolio NAV. For portfolios with NAV>0 (ORIGIN, UNIVERSE): user_fee = total_fee x (user_balance / NAV). For portfolios with NAV=0 (EARTH, EXPLORER, GALAXY): falls back to SUM(user_balance) as denominator. (4) Nova (platform) — platform fees from nova_fees, keyed by coverage_start_date. (5) Nova (FX) — foreign-exchange spread fees from nova_transactions (order_fx_aud_fee on finalised orders). GOTCHAS: (a) All source amounts are AUD; USD uses AUD/USD mid-rate from fact_currencypricewithsplit (InstrumentID=7). (b) Voyager mgmt fees accrue daily including weekends, but the balance table is weekday-only. Weekend fees use fill-forwarded Friday balances for the pro-rating denominator (~7-8K AUD/day would be lost without this). (c) The pro-rating window must partition by fee date, NOT balance lookup date. Since fill-forward maps Fri+Sat+Sun fees to the same Friday balance rows, partitioning by balance date triples the denominator for NAV=0 portfolios (~968 AUD/day error). (d) Nova FX order_filled_at is UTC — must convert to Australia/Sydney before DATE cast, otherwise trades after ~2pm UTC land one day early vs Metabase. Granularity: one row per date x product x user_id.';

-- ===== Column-level =====
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.date           IS 'Fee accrual date. Nova FX uses order_filled_at converted from UTC to Australia/Sydney. Voyager mgmt weekend fees retain the actual fee date even though the balance lookup falls back to Friday.';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.date_id        IS 'Date in YYYYMMDD integer format.';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.product        IS 'Fee category: Super (admin fees from super_transactions), Voyager (account) (from voyager_account_fees), Voyager (mgmt) (pro-rated management fees), Nova (platform) (from nova_fees), or Nova (FX) (from nova_transactions FX spread).';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.user_id        IS 'Canonical Spaceship user_id (deduplicated).';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.gcid           IS 'eToro Global Customer ID. NULL if no cross-sell linkage between the Spaceship and eToro accounts (i.e. user opened a Spaceship account without linking via the eToro Wallet flow).';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.total_fees_aud IS 'Absolute total fees in AUD. Voyager mgmt fees are pro-rated: user_fee = total_fee x (user_balance / portfolio_NAV). For zero-NAV portfolios (EARTH, EXPLORER, GALAXY), falls back to SUM(user_balance) as denominator. Excludes Super SFT event (2024-05-18).';
COMMENT ON COLUMN main.etoro_kpi.v_spaceship_fees.total_fees_usd IS 'Total fees converted to USD via AUD/USD mid-rate ((Ask+Bid)/2 from fact_currencypricewithsplit, InstrumentID=7).';
