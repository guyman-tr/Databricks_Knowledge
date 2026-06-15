---
name: domain-spaceship
version: 1
owner: dataplatform
description: "The three production prep views under main.etoro_kpi_prep that sit between raw Spaceship bronzes and the dashboard / reporting layer — their column shape, CTE architecture, dedup strategy, and recent fixes. v_spaceship_aum: one row per date × user_id with super_balance_aud + voyager_balance_aud + nova_balance_aud + total_balance_aud + USD-converted variants + is_funded boolean; uses member_canonical for Super dedup and user_id_map for Voyager/Nova dedup; applies weekend fill-forward for Super and Voyager; does NOT include Money balances (v2 will). v_spaceship_mimo: one row per date × product × is_internal_transfer × user_id with total_deposits_aud / total_withdrawals_aud (stored positive — dashboard negates) / net_flow_aud / count_deposits / count_withdrawals / is_ftd; 11-CTE architecture (user_accounts dedup → contact_mapping → super_mimo / money_mimo / voyager_mimo / nova_mimo → UNION → first_deposit_dates from user_beta with ftd_product column → mimo_final UNION with orphan-FTD rows → user_gcid bridge → aud_usd_rates). Five fixes applied 2026-04-13: (1) Super uses negation not ABS (aud_amount is SIGNED — ABS inflated outflows ~39%); (2) Money classifies by transaction_type not transaction_direction; (3) Money status filter (NOT IN cancelled/failed/rejected); (4) FTD uses user_beta product dates with LEAST() and excludes Money; (5) orphan-FTD rows added in mimo_final CTE to fix the ~17% T+2 backdating gap. v_spaceship_fees: one row per date × product × user_id with total_fees_aud / total_fees_usd; products are Super / Voyager (account) / Voyager (mgmt) / Nova (platform) / Nova (FX). Voyager mgmt fee is pro-rated by balance share of portfolio NAV (NAV=0 portfolios EARTH/EXPLORER/GALAXY fall back to SUM(user_balance) denominator); three fixes applied 2026-04-13: weekend fill-forward to Friday balances, window partition by fee date (not balance date — fixes ~968 AUD/day allocation loss on NAV=0 portfolios when fill-forward maps N dates to 1 balance row), Nova FX timezone conversion (Sydney) to fix the systematic 1-day offset. Pipeline: all 53 Spaceship tables full-overwrite from BigQuery daily ~07:30 UTC; no incremental/CDC. Deprecated staging views dropped 2026-04-01: v_spaceship_funded_products_daily (→ v_spaceship_aum + inline Money CTE), v_spaceship_user_profile (→ inline from user_beta), v_spaceship_f30dd (broken, never used). Use for any 'what does v_spaceship_X return' / 'which CTE does v_spaceship_mimo use' / 'why did v_spaceship_fees change on 2026-04-13' / 'is there a Money FUM view' / 'where is v_spaceship_user_profile' question."
triggers:
  - v_spaceship_aum
  - v_spaceship_mimo
  - v_spaceship_fees
  - spaceship aum view
  - spaceship mimo view
  - spaceship fees view
  - is_funded
  - total_balance_aud
  - total_deposits_aud
  - total_withdrawals_aud
  - net_flow_aud
  - is_ftd
  - is_internal_transfer
  - ftd_product
  - mimo_final orphan FTD
  - 5 fixes 2026-04-13
  - Super negation not ABS
  - Voyager mgmt fee pro-rating
  - portfolio NAV pro-rating
  - NAV=0 EARTH EXPLORER GALAXY
  - fill-forward Friday balance
  - window partition by fee date
  - Nova FX timezone Sydney
  - v_spaceship_user_profile deprecated
  - v_spaceship_funded_products_daily deprecated
  - v_spaceship_f30dd broken
  - 53 tables overwrite 07:30 UTC
  - Spaceship ETL pipeline
sample_questions:
  - What columns does v_spaceship_aum expose and how is it deduplicated
  - What's the CTE architecture of v_spaceship_mimo
  - Which 5 fixes were applied to v_spaceship_mimo on 2026-04-13
  - How does Voyager mgmt fee pro-rating work in v_spaceship_fees (and why NAV=0 portfolios needed a fix)
  - Which staging views were deprecated 2026-04-01 and what replaced them
required_tables:
  - main.etoro_kpi_prep.v_spaceship_aum
  - main.etoro_kpi_prep.v_spaceship_mimo
  - main.etoro_kpi_prep.v_spaceship_fees
---

# Spaceship Views Architecture

## Production Prep Views (`main.etoro_kpi_prep`)

### v_spaceship_aum
**Purpose**: Assets Under Management - daily per-user balances across all products.
**Granularity**: One row per `date` x `user_id`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Calendar date (including filled weekends) |
| `date_id` | INT | YYYYMMDD format |
| `user_id` | STRING | Canonical user_id (deduplicated) |
| `gcid` | STRING | eToro GCID (NULL if not cross-sell) |
| `super_balance_aud` | DECIMAL | Super balance |
| `super_balance_usd` | DECIMAL | Super balance (USD converted) |
| `voyager_balance_aud` | DECIMAL | Voyager balance |
| `voyager_balance_usd` | DECIMAL | Voyager balance (USD converted) |
| `nova_balance_aud` | DECIMAL | Nova balance |
| `nova_balance_usd` | DECIMAL | Nova balance (USD converted) |
| `total_balance_aud` | DECIMAL | Super + Voyager + Nova |
| `total_balance_usd` | DECIMAL | Super + Voyager + Nova (USD) |
| `is_funded` | BOOLEAN | TRUE if total_balance > 0 |

**Key features:**
- Uses `member_canonical` for Super dedup + `user_id_map` for Voyager/Nova dedup
- Weekend fill-forward for Super and Voyager (see `spaceship-data-patterns.md`)
- Includes USD conversion via AUD/USD rates
- Does NOT include Money balances (see v2 below)

### v_spaceship_mimo
**Purpose**: Money In/Money Out - deposits and withdrawals by product with internal/external split.
**Granularity**: One row per `date` x `product` x `is_internal_transfer` x `user_id`
**Last updated**: 2026-04-13 (aligned with dashboard queries)
**Canonical script**: `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/v_spaceship_mimo.dbquery.ipynb`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Transaction date |
| `date_id` | INT | YYYYMMDD format |
| `product` | STRING | 'Super', 'Money', 'Voyager', 'Nova' |
| `is_internal_transfer` | BOOLEAN | FALSE=external (real money), TRUE=internal (between products) |
| `user_id` | STRING | Canonical user_id |
| `gcid` | STRING | eToro GCID |
| `total_deposits_aud/usd` | DECIMAL | Total deposits |
| `total_withdrawals_aud/usd` | DECIMAL | Total withdrawals (always positive) |
| `net_flow_aud/usd` | DECIMAL | Net flow (deposits - withdrawals) |
| `count_deposits` | INT | Number of deposits |
| `count_withdrawals` | INT | Number of withdrawals |
| `is_ftd` | BOOLEAN | Authoritative FTD flag (see below) |

**CTE architecture:**
1. `user_accounts` -- Super member_id to user_id dedup (ROW_NUMBER)
2. `contact_mapping` -- Money account_id to user_id
3. `super_mimo` -- Super flows (signed aud_amount, negation for withdrawals)
4. `money_mimo` -- Money flows (type-based classification)
5. `voyager_mimo` -- Voyager flows from balance table
6. `nova_mimo` -- Nova flows from transactions
7. `mimo_aggregated` -- UNION ALL + GROUP BY per user/date/product
8. `first_deposit_dates` -- FTD dates from user_beta with ftd_product column
9. `mimo_final` -- UNION of mimo_aggregated + orphan FTD rows
10. `user_gcid` -- eToro GCID bridge
11. `aud_usd_rates` -- AUD/USD conversion rates

**5 changes applied (2026-04-13):**
1. Super: negation instead of ABS (aud_amount is SIGNED, ABS inflated outflows ~39%)
2. Money: type-based classification (transaction_type not transaction_direction)
3. Money: status filter (status NOT IN cancelled/failed/rejected)
4. FTD: user_beta product dates (LEAST of super/voyager/nova, excludes Money)
5. FTD: orphan FTD rows (mimo_final CTE, fixes ~17% T+2 backdating gap)

**Sign convention:** total_withdrawals_aud stored positive. Dashboard shows negative.

### v_spaceship_fees
**Purpose**: Fee revenue analysis by product, per user per day.
**Granularity**: One row per `date` x `product` x `user_id`
**Last updated**: 2026-04-13 (3 fixes: weekend fill-forward, window partition, Nova FX timezone)
**Canonical script**: `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/v_spaceship_fees.dbquery.ipynb`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Fee date |
| `product` | STRING | 'Super', 'Voyager (account)', 'Voyager (mgmt)', 'Nova (platform)', 'Nova (FX)' |
| `user_id` | STRING | Canonical user_id |
| `total_fees_aud/usd` | DECIMAL | Total fees |

**Fee sources:**
- Super: `super_transactions` WHERE type='Fees', uses paid_date, excludes SFT 2024-05-18
- Voyager account: `voyager_account_fees`, uses account_fee_created_at_date
- Voyager mgmt: `voyager_management_fees` pro-rated by balance share of portfolio NAV
- Nova platform: `nova_fees`, uses coverage_start_date, aud_net_amount
- Nova FX: `nova_transactions` WHERE order_status='FINALISED', uses order_fx_aud_fee

**Voyager mgmt fee pro-rating:**
user_fee = total_fee * (user_balance / portfolio_NAV). Falls back to SUM(user_balance) when NAV is zero.
Portfolios with NAV=0: EARTH, EXPLORER, GALAXY. With NAV>0: ORIGIN, UNIVERSE.

**3 fixes applied (2026-04-13):**

1. **Weekend fill-forward for Voyager mgmt fees:**
   Balance table is weekday-only. Weekend fees were dropped entirely (~7-8K AUD/day).
   Fix: join fills forward to Friday balances:
   ```sql
   pb.effective_date = CASE
     WHEN DAYOFWEEK(fee_date) = 1 THEN DATE_ADD(fee_date, -2)  -- Sun->Fri
     WHEN DAYOFWEEK(fee_date) = 7 THEN DATE_ADD(fee_date, -1)  -- Sat->Fri
     ELSE fee_date END
   ```
   Fee output date stays as actual date (Sat/Sun). Only balance proportions from Friday.

2. **Window partition by fee date (not balance date) -- CRITICAL:**
   The fill-forward maps Fri/Sat/Sun fees to the SAME balance rows (pb.effective_date =
   Friday). The fallback denominator `SUM(pb.aud_balance) OVER (PARTITION BY pb.portfolio,
   pb.effective_date)` included ALL rows sharing that balance date -- tripling the
   denominator for NAV=0 portfolios (EARTH, EXPLORER, GALAXY). Each day only received
   1/3 of their fee allocation (~968 AUD/day lost, confirmed: Friday showed 7,543 instead
   of expected 8,189).
   Fix: partition by fee date instead of balance date:
   ```sql
   -- WRONG: triples denominator when fill-forward shares balance date
   SUM(pb.aud_balance) OVER (PARTITION BY pb.portfolio, pb.effective_date)
   -- CORRECT: each fee date gets its own partition
   SUM(pb.aud_balance) OVER (PARTITION BY pb.portfolio, CAST(mf.effective_date AS DATE))
   ```
   **Lesson:** When fill-forward maps N fee dates to 1 balance date, any window function
   partitioned by the balance date will see N x the expected rows. Always partition by
   the logical/business date (fee date), not the physical lookup date.

3. **Nova FX timezone conversion:**
   `order_filled_at` is UTC. Without conversion, trades after ~2 PM UTC appeared one day
   early vs Metabase (which uses Australian local time). Caused systematic 1-day offset
   in Nova (FX) fees confirmed by QA comparison with Jaclyn (SPS Finance).
   Fix: `CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE)`
   Same pattern already used in v_spaceship_mimo for Nova flows.

**Pending QA items (awaiting BigQuery originals from SPS):**
- Money: `USER_WITHDRAWAL_REVERSAL` classified as deposit (positive amount). Net flows
  correct but deposit/withdrawal split may differ from SPS definition. Parked until BQ
  queries received from Jaclyn's team.

## Pending Version 2 Views

### v_spaceship_aum_version2.sql
Adds Money FUM via running SUM from fct_money_transactions.
Located: `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/TBD/v_spaceship_aum_version2.sql`

### v_spaceship_mimo_version2.sql (SUPERSEDED)
All fixes applied to production v_spaceship_mimo (2026-04-13). This file is outdated.

## ETL Pipeline

All 53 Spaceship tables: full overwrite from BigQuery, daily ~07:30 UTC.
Entry point: [Spaceship- Main](#notebook-1353348094096079)
Worker: [Spaceship - process table](#notebook-1353348094099614)
No incremental/CDC.

## Deprecated Staging Views (DROPPED 2026-04-01)

| View | Replacement |
|------|-------------|
| v_spaceship_funded_products_daily | v_spaceship_aum + inline Money CTE |
| v_spaceship_user_profile | Inline from user_beta |
| v_spaceship_f30dd | BROKEN, never used by dashboard |
