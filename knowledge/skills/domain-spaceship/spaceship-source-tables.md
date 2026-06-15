---
description: "Complete inventory of the main.spaceship schema — every bronze and analytics table on the Spaceship side, with column types, identity-key conventions, gotchas, and weekend/timezone coverage. The four product families have DIFFERENT identity keys: Super uses member_id (FK on user_beta), Voyager and Nova use user_id directly, Money uses account_id (bridged to user_id via bronze_spaceship_metabase_contact). The master user table is bronze_spaceship_metabase_user_beta — one row per user_id but 1:MANY member_id↔user_id collisions (~529K users have NULL member_id meaning no Super account); see spaceship-data-patterns.md for the canonical dedup. Per-product anchor tables: Super — bronze_spaceship_metabase_super_user_balances (weekday-only, 42M rows since 2017-01-11) + bronze_spaceship_metabase_super_transactions (paid_date, exclude 2024-05-18 SFT day, aud_amount is SIGNED — do NOT ABS or you inflate outflows ~39%; Premium type = insurance ~-$371K lifetime; Contributions / Benefit Payment / Fees / Tax / Premium families with per-description sign rules). Voyager — spaceship_metabase_voyager_user_balances (weekday-only, 429M rows since 2018-04-19, aud_balance + aud_balance_prev + net_aud_transacted + inflow_aud_amount + outflow_aud_amount) + spaceship_metabase_voyager_product_balances (portfolio = UNIVERSE/EARTH/ORIGIN/EXPLORER/GALAXY) + bronze_spaceship_metabase_voyager_transactions (order_direction BUY/SELL, unit_aud_amount). Nova — bronze_spaceship_metabase_nova_transactions (order_filled_at UTC, order_aud_amount, order_fx_aud_fee, order_status filter to FINALISED/EXECUTED/PAYMENT_INITIATED) + bronze_spaceship_metabase_nova_user_balances (7-day rolling window only, 9.6M rows). Money — bronze_spaceship_analytics_fct_money_transactions with 19 transaction_types split into 9 External (USER_DEPOSIT family + NOVA_DIVIDEND + NOVA_*_FEE) and 10 Internal (VOYAGER_PURCHASE / VOYAGER_SALE / NOVA_PURCHASE etc.) — filter is_completed=true AND is_reversed=false (or status NOT IN cancelled/failed/rejected). Plus KYC / screening / club balances (bronze_spaceship_analytics_rpt_etoro_user_screening, greenid, club_balances), 53 tables total, full overwrite from Spaceship BigQuery daily ~07:30 UTC. Use for any 'which table holds X' / 'what's the FK between member_id and user_id' / 'what gotchas does Super aud_amount have' question."
triggers:
  - main.spaceship schema
  - bronze_spaceship
  - bronze_spaceship_metabase
  - bronze_spaceship_analytics
  - spaceship_metabase
  - bronze_spaceship_metabase_user_beta
  - bronze_spaceship_metabase_contact
  - bronze_spaceship_metabase_super_user_balances
  - bronze_spaceship_metabase_super_transactions
  - spaceship_metabase_voyager_user_balances
  - spaceship_metabase_voyager_product_balances
  - bronze_spaceship_metabase_voyager_transactions
  - bronze_spaceship_metabase_nova_transactions
  - bronze_spaceship_metabase_nova_user_balances
  - bronze_spaceship_analytics_fct_money_transactions
  - "member_id user_id 1:many"
  - 529K NULL member_id
  - Super aud_amount signed
  - do not ABS Super aud_amount
  - Premium insurance
  - SFT 2024-05-18
  - paid_date Super
  - Voyager portfolio UNIVERSE
  - EARTH ORIGIN EXPLORER GALAXY
  - aud_balance_prev cohort
  - 19 transaction_types Money
  - USER_DEPOSIT
  - VOYAGER_PURCHASE
  - NOVA_PURCHASE
  - NOVA_DIVIDEND
  - is_completed is_reversed
  - bronze_spaceship_analytics_rpt_etoro_user_screening
  - bronze_spaceship_metabase_greenid
  - bronze_spaceship_analytics_rpt_etoro_club_balances
  - 53 tables Spaceship
  - daily 07:30 UTC overwrite BigQuery
sample_questions:
  - Which Spaceship table holds the master user record (and what are the identity-key collisions)
  - What does aud_amount sign represent in bronze_spaceship_metabase_super_transactions
  - Which Spaceship tables are weekday-only vs 7-day vs derived
  - What are the 19 Money transaction_types and which are external vs internal
  - Where are the Spaceship KYC / fraud-screening flags stored
required_tables:
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_contact
  - main.spaceship.bronze_spaceship_metabase_super_transactions
  - main.spaceship.bronze_spaceship_metabase_super_user_balances
  - main.spaceship.spaceship_metabase_voyager_user_balances
  - main.spaceship.spaceship_metabase_voyager_product_balances
  - main.spaceship.bronze_spaceship_metabase_voyager_transactions
  - main.spaceship.bronze_spaceship_metabase_nova_transactions
  - main.spaceship.bronze_spaceship_metabase_nova_user_balances
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.spaceship.bronze_spaceship_analytics_rpt_etoro_user_screening
  - main.spaceship.bronze_spaceship_analytics_rpt_etoro_club_balances
---

# Spaceship Source Tables

All tables in `main.spaceship` schema. Data sourced from Spaceship's BigQuery via API.
All monetary values are in **AUD**.

## User Identity & Contacts

### bronze_spaceship_metabase_user_beta
**The master user table.** One row per user_id (but 1:MANY member_id→user_id — see spaceship-data-patterns.md).

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | STRING | Primary key for Voyager/Nova/Money |
| `member_id` | STRING | Foreign key for Super tables. NULL if no Super account (~529K NULLs) |
| `signed_up_at_date` | DATE | Registration date (local, no TZ conversion needed) |
| `super_first_became_financial_date` | DATE | Super FTD date (local). Can backdate T+2 |
| `voyager_first_became_financial_date` | DATE | Voyager FTD date (local) |
| `nova_first_transaction_at` | TIMESTAMP | Nova FTD timestamp (**UTC — convert to Sydney**) |
| `nova_signed_up_at` | TIMESTAMP | Nova signup (**UTC**) |
| `last_logged_in_at` | TIMESTAMP | Last login (**UTC**) |
| `has_active_investment_plan` | BOOLEAN | Active recurring plan flag |
| `has_ever_setup_investment_plan` | BOOLEAN | Historical plan flag |
| `has_ever_setup_boost` | BOOLEAN | Boost feature flag |
| `spaceship_account_status` | STRING | Account status |

### bronze_spaceship_metabase_contact
**Maps account_id → user_id** (critical for Money transactions).

| Column | Type | Notes |
|--------|------|-------|
| `account_id` | STRING | Money wallet account ID |
| `user_id` | STRING | Maps to user_beta.user_id |

⚠️ Filter: `WHERE account_id IS NOT NULL AND user_id IS NOT NULL`

## Super (Retirement) — Keyed by `member_id`

### bronze_spaceship_metabase_super_transactions
| Column | Type | Notes |
|--------|------|-------|
| `member_id` | STRING | FK to user_beta.member_id |
| `paid_date` | DATE | Transaction date (local). **Exclude '2024-05-18' (SFT rollover)** |
| `type` | STRING | 'Contributions', 'Benefit Payment', 'Fees', 'Tax', 'Premium' |
| `description` | STRING | 'Contributions Tax' classifies as inflow despite type='Tax' |
| `aud_amount` | STRING | Cast to DECIMAL. **SIGNED** — see sign convention below |

**Super aud_amount sign convention** (verified 2026-04-13):

`aud_amount` is **NOT always positive**. It carries the correct sign:
- **Contributions**: mostly positive (inflows). Exception: `description='Notice of Intent'` can have negative rows (cancellations).
- **Benefit Payment**: mostly negative (outflows). ~11% of rows are positive (refunds/reversals).
- **Fees**: mixed signs. `description='Fee Rebate'` is positive; `description='Other'` has ~36% positive, ~64% negative.
- **Tax**: all negative. `description='Contributions Tax'` is negative (classified as inflow despite sign).
- **Premium**: all negative (insurance premiums deducted from Super balance). ~25K transactions, ~-$371K AUD lifetime. Classified as withdrawal in v_spaceship_mimo (added 2026-04-20).

⚠️ **Do NOT use ABS()** on Super `aud_amount` — it inflates outflows by ~39% due to mixed signs.
Use `-CAST(aud_amount AS DOUBLE)` for withdrawal amounts (negation correctly nets refunds).
The dashboard uses `SUM(aud_amount)` directly, relying on the built-in signs.

### bronze_spaceship_metabase_super_user_balances
| Column | Type | Notes |
|--------|------|-------|
| `member_id` | STRING | FK to user_beta.member_id |
| `date` | DATE | **Weekday-only (Mon-Fri)**. Needs weekend fill-forward |
| `balance_aud` | DECIMAL | Account balance |

**Data range:** 2017-01-11 to present, 42M+ rows.

### Other Super Tables
- `bronze_spaceship_metabase_super_fund` — Fund details
- `bronze_spaceship_metabase_super_product` — Product accounts
- `bronze_spaceship_metabase_super_product_history` — Historical changes
- `bronze_spaceship_metabase_super_users` / `super_users_beta` — User accounts
- `bronze_spaceship_metabase_super_portfolios` — Portfolio allocations
- `bronze_spaceship_metabase_super_transaction_types` — Type dictionary
- `bronze_spaceship_metabase_super_tmd_latest_submissions` — Regulatory

## Voyager (ETFs) — Keyed by `user_id`

### spaceship_metabase_voyager_user_balances
| Column | Type | Notes |
|--------|------|-------|
| `user_id` | STRING | Direct user_id |
| `effective_date` | DATE | **Weekday-only (Mon-Fri)**. Needs weekend fill-forward |
| `aud_balance` | DECIMAL | Total balance |
| `aud_balance_prev` | DECIMAL | Previous day balance (used for cohort splits: <25k vs 25k+) |
| `net_aud_transacted` | DECIMAL | Daily net flow |
| `inflow_aud_amount` | DECIMAL | Daily inflow |
| `outflow_aud_amount` | DECIMAL | Daily outflow (negative) |

**Data range:** 2018-04-19 to present, 429M+ rows.

### spaceship_metabase_voyager_product_balances
| Column | Type | Notes |
|--------|------|-------|
| `portfolio` | STRING | 'UNIVERSE', 'EARTH', 'ORIGIN', 'EXPLORER', 'GALAXY' |
| `effective_date` | DATE | Weekday-only |
| `net_aud_transacted` | DECIMAL | Net flow per portfolio |
| `aud_balance` | DECIMAL | Portfolio balance |

Used for Voyager Portfolio split (Universe vs Other).

### bronze_spaceship_metabase_voyager_transactions
| Column | Type | Notes |
|--------|------|-------|
| `user_id` | STRING | Direct user_id |
| `effective_date` | DATE | Transaction date (local) |
| `order_direction` | STRING | 'BUY' or 'SELL' |
| `unit_aud_amount` | DECIMAL | Transaction amount in AUD |

### Other Voyager Tables
- `bronze_spaceship_metabase_voyager_fund` — Fund information
- `bronze_spaceship_metabase_voyager_unit_prices` — NAV prices
- `bronze_spaceship_metabase_voyager_management_fees` — Mgmt fees (portfolio-level, pro-rated to users)
- `bronze_spaceship_metabase_voyager_account_fees` — Account fees
- `bronze_spaceship_metabase_voyager_goals` — Investment goals
- `bronze_spaceship_metabase_voyager_applications` — Applications
- `bronze_spaceship_metabase_voyager_boost_recipes` / `voyager_boost_transactions` — Boost promos
- `bronze_spaceship_metabase_voyager_transactions_agg` — Aggregated transactions
- `bronze_spaceship_metabase_voyager_daily_metrics_report` — Daily metrics
- `bronze_spaceship_metabase_voyager_effective_dates` — Date tracking
- `bronze_spaceship_metabase_voyager_tmd_*` — Target Market Determination (regulatory)

## Nova (Stocks) — Keyed by `user_id`

### bronze_spaceship_metabase_nova_transactions
| Column | Type | Notes |
|--------|------|-------|
| `user_id` | STRING | Direct user_id |
| `order_filled_at` | TIMESTAMP | **UTC — convert to Sydney** |
| `order_direction` | STRING | 'BUY' or 'SELL' |
| `order_aud_amount` | DECIMAL | Trade amount |
| `order_fx_aud_fee` | DECIMAL | FX fee (used in fees view) |
| `order_status` | STRING | Filter: IN ('FINALISED', 'EXECUTED', 'PAYMENT_INITIATED') |

### bronze_spaceship_metabase_nova_user_balances
| Column | Type | Notes |
|--------|------|-------|
| `user_id` | STRING | Direct user_id |
| `date` | DATE | **7-day coverage** (unlike Super/Voyager) |
| `aud_balance` | DECIMAL | Account balance |

**Data range:** Rolling 7-day window only, 9.6M+ rows.

### Other Nova Tables
- `bronze_spaceship_metabase_nova_product` — Product accounts and status
- `bronze_spaceship_metabase_nova_account_positions` — Current holdings
- `bronze_spaceship_metabase_nova_fees` — Fee charges (`coverage_start_date`, `aud_net_amount`)
- `bronze_spaceship_metabase_nova_investment_plans` — Recurring plans
- `bronze_spaceship_metabase_nova_applications` — Applications
- `bronze_spaceship_metabase_nova_assets` — Available assets
- `bronze_spaceship_metabase_nova_daily_metrics_report` — Daily metrics
- `bronze_spaceship_metabase_nova_jit_daily_limits` — Trading limits
- `bronze_spaceship_metabase_nova_non_trade_activities` — Non-trading events

## Money (Cash Wallet) — Keyed by `account_id`

### bronze_spaceship_analytics_fct_money_transactions
| Column | Type | Notes |
|--------|------|-------|
| `account_id` | STRING | FK to contact.account_id → user_id |
| `transaction_type` | STRING | 19 distinct types (see below) |
| `transaction_direction` | STRING | 'CREDIT' or 'DEBIT' |
| `aud_amount` | STRING | Cast to DOUBLE. Always positive |
| `completed_at` | TIMESTAMP | **UTC — convert to Sydney** |
| `is_completed` | BOOLEAN | Filter: `= true` |
| `is_reversed` | BOOLEAN | Filter: `= false` |
| `status` | STRING | Alt filter: `NOT IN ('CANCELLED','FAILED','REJECTED')` |

**19 Transaction Types:**

| Type | Internal/External | Direction |
|------|-------------------|-----------|
| USER_DEPOSIT | External | CREDIT (inflow) |
| USER_WITHDRAWAL | External | DEBIT (outflow) |
| USER_DEPOSIT_REVERSAL | External | DEBIT (inflow reversal) |
| USER_WITHDRAWAL_REVERSAL | External | CREDIT (outflow reversal) |
| NOVA_DIVIDEND | External | CREDIT (inflow) |
| NOVA_MERGER_ACQUISITIONS | External | CREDIT (inflow) |
| NOVA_TAF_FEE | External | DEBIT (outflow/fee) |
| NOVA_REG_FEE | External | DEBIT (outflow/fee) |
| NOVA_MONTHLY_FEE | External | DEBIT (outflow/fee) |
| VOYAGER_PURCHASE | Internal | DEBIT |
| VOYAGER_SALE | Internal | CREDIT |
| VOYAGER_BOOST | Internal | DEBIT |
| VOYAGER_DISTRIBUTION | Internal | CREDIT |
| VOYAGER_BONUS | Internal | CREDIT |
| VOYAGER_DISTRIBUTION_REVERSAL | Internal | DEBIT |
| VOYAGER_PURCHASE_REVERSAL | Internal | CREDIT |
| NOVA_PURCHASE | Internal | DEBIT |
| NOVA_SALE | Internal | CREDIT |
| S8_DEPOSIT | Internal | CREDIT |

## KYC, Screening & Other

- `bronze_spaceship_analytics_rpt_etoro_user_screening` — Fraud flags, KYC mismatches (`is_fraudulent`, `has_true_positive_screening`, `kyc_data_mismatched`)
- `bronze_spaceship_metabase_greenid` / `greenid_results` — ID verification
- `bronze_spaceship_analytics_rpt_etoro_club_balances` — Daily balances by product with product flags (`has_active_nova_account`, etc.)
- `bronze_spaceship_analytics_ref_etoro_tables` — ETL config
- `spaceship_metabase_daily_active_investment_plans` — Active recurring plans
- `bronze_spaceship_metabase_experiment_enrolments` — A/B test enrollments
- `bronze_spaceship_metabase_leads` — Lead tracking

## Known Data Quirks

1. **Super SFT date**: Exclude `paid_date = '2024-05-18'` — bad data from Super Fund Transfer migration
2. **Super T+2 backdating**: `first_became_financial_date` can shift retroactively. Expect ~10-20% FTD variance for recent weeks
3. **Super/Voyager weekday-only**: Balance tables skip Sat/Sun. Use fill-forward pattern (see `spaceship-data-patterns.md`)
4. **Nova 7-day window**: `nova_user_balances` only retains ~7 days of history
5. **user_beta NULL member_ids**: ~529K user_ids have NULL member_id (no Super account)
6. **Money amount type**: `aud_amount` is STRING, must cast to DOUBLE
7. **Money completion filters**: Two equivalent filters — `is_completed=true AND is_reversed=false` OR `status NOT IN ('CANCELLED','FAILED','REJECTED')`. Dashboard uses the latter.
8. **Nova fees via Money**: Nova fees (TAF, REG, MONTHLY) flow through Money wallet as DEBIT, not via nova_fees table
9. **Super aud_amount is SIGNED**: Despite being STRING type, values carry signs (negative for outflows). Do NOT use ABS() — use negation (-) for withdrawal amounts. See Super section above for full sign patterns.
10. **Super FTD-to-transaction gap**: ~17% of Super FTD dates (from `user_beta.super_first_became_financial_date`) have no matching `paid_date` in `super_transactions`, due to T+2 settlement backdating. This means transaction-based FTD detection undercounts. Use `user_beta` directly for authoritative FTD counts.
11. **Super Premium type**: Insurance premiums (`type='Premium'`) exist in `super_transactions` — always negative (~-$371K AUD lifetime, ~25K rows). Classified as withdrawal in `v_spaceship_mimo` (added 2026-04-20). The `type='Other'` category (~+$434M AUD net, 2.4M rows) is NOT included in MIMO — it has mixed signs and unclear classification.
