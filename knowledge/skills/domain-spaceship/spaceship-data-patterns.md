---
name: domain-spaceship
version: 1
owner: dataplatform
description: "Reusable CTEs, join patterns, and conventions for writing Spaceship SQL. Covers: (1) canonical user deduplication — user_beta has 1:MANY member_id↔user_id (257 collisions); pick one canonical user_id per member_id and map secondaries via user_id_map (failing to dedupe inflates Voyager AUM by 188K rows and Nova by 13K rows on 139 + 22 affected user_ids); (2) Money contact_mapping — Money transactions key on account_id, not user_id, so always join via bronze_spaceship_metabase_contact; (3) Money running balance — no Money balance table exists, derive via running SUM of fct_money_transactions per user partitioned by date (the CTE the dashboard reuses); (4) weekend fill-forward — Super and Voyager balance tables are weekday-only (Mon-Fri); fill Sat/Sun from Friday via NEXT_DAY + priority-column UNION (Nova has 7-day coverage and skips this); (5) AUD→USD conversion via fact_currencypricewithsplit InstrumentID=7 (rates lag 1 day, COALESCE to 0); (6) timezone reference — Money completed_at, Nova order_filled_at and nova_first_transaction_at are UTC and must be converted to Australia/Sydney; Super paid_date, Voyager effective_date, signed_up_at_date are local DATE and need no shift; (7) week-ending convention — Spaceship uses Sunday end-of-week (DAYOFWEEK = 1 for snapshots, DATE_TRUNC('week', date) + 6 days for aggregations, 84-day rolling window); (8) Spaceship-to-eToro GCID join via bronze_sub_accounts_accounts where providerName = 'Spaceship'; (9) overall_ftd_date inline pattern using LEAST(super, voyager, nova) with 9999-12-31 sentinel for NULLs (replaces the deprecated v_spaceship_user_profile.overall_ftd_date view). Use for any 'how do I write a Spaceship query' / 'why is my count doubled' / 'fill-forward weekend' / 'AUD to USD' / 'GCID join' question."
triggers:
  - canonical user_id
  - member_canonical
  - user_id_map
  - 1 to many member_id
  - duplicate AUM
  - secondary user_id
  - contact_mapping
  - Money account_id
  - account_id to user_id
  - Money running balance
  - money_daily
  - money_running
  - weekend fill-forward
  - Sat Sun fill
  - NEXT_DAY SA
  - weekday only
  - DAYOFWEEK Mon Fri
  - aud_usd_rates
  - InstrumentID 7
  - AUD USD conversion
  - Australia/Sydney
  - FROM_UTC_TIMESTAMP
  - timezone reference
  - week-ending Sunday
  - DAYOFWEEK = 1
  - DATE_TRUNC week + 6 days
  - 84 days rolling
  - GCID join Spaceship
  - bronze_sub_accounts_accounts providerName Spaceship
  - overall_ftd_date inline
  - LEAST super voyager nova
  - "9999-12-31 sentinel"
  - v_spaceship_user_profile deprecated
sample_questions:
  - Show the canonical user dedup pattern for Spaceship Voyager joins
  - How do I derive a Money running balance per user on Sundays
  - What's the fill-forward pattern for Super and Voyager weekend balances
  - How is overall_ftd_date computed inline (no staging view)
  - Which Spaceship fields need UTC to Sydney timezone conversion
required_tables:
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_contact
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  - main.bi_db.bronze_sub_accounts_accounts
---

# Spaceship Data Patterns

Reusable CTEs, join patterns, and conventions for writing Spaceship SQL queries.

## Canonical User Deduplication

**Problem**: `user_beta` has 1:MANY `member_id` to `user_id` (257 member_ids map to 2 user_ids, 2 map to 3). This causes balance/fee/transaction duplication.

**Solution**: Two CTEs — pick one canonical user_id per member_id:

```sql
-- Step 1: One canonical user_id per member_id (alphabetically first)
member_canonical AS (
  SELECT member_id, user_id AS canonical_user_id
  FROM (
    SELECT member_id, user_id,
      ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY user_id) AS rn
    FROM main.spaceship.bronze_spaceship_metabase_user_beta
    WHERE member_id IS NOT NULL
  )
  WHERE rn = 1
),

-- Step 2: Map EVERY user_id to its canonical (for Voyager/Nova joins)
user_id_map AS (
  SELECT DISTINCT ub.user_id, mc.canonical_user_id
  FROM main.spaceship.bronze_spaceship_metabase_user_beta ub
  INNER JOIN member_canonical mc ON ub.member_id = mc.member_id
  WHERE ub.member_id IS NOT NULL
)
```

**When to use which:**
- `member_canonical` — for **Super** joins (Super tables use `member_id`)
- `user_id_map` — for **Voyager/Nova** joins (their tables use `user_id`, but secondary user_ids must map to canonical)

**Impact of not deduplicating**: 139 secondary user_ids with 188K Voyager rows and 22 with 13K Nova rows create duplicate AUM. 28 member_ids had BOTH primary and secondary user_ids with Voyager balances.

## Money Contact Mapping

**Problem**: Money transactions use `account_id`, not `user_id`.

```sql
contact_mapping AS (
  SELECT DISTINCT account_id, user_id
  FROM main.spaceship.bronze_spaceship_metabase_contact
  WHERE account_id IS NOT NULL AND user_id IS NOT NULL
)
-- Then: JOIN contact_mapping cm ON mt.account_id = cm.account_id
```

## Money Running Balance

**Problem**: No Money balance table exists. Must derive from transaction history.

```sql
money_daily AS (
  SELECT CAST(FROM_UTC_TIMESTAMP(mt.completed_at, 'Australia/Sydney') AS DATE) AS date,
    cm.user_id,
    SUM(CASE WHEN mt.transaction_direction = 'CREDIT' THEN CAST(mt.aud_amount AS DOUBLE)
             ELSE -ABS(CAST(mt.aud_amount AS DOUBLE)) END) AS daily_net
  FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions mt
  JOIN contact_mapping cm ON mt.account_id = cm.account_id
  WHERE mt.is_completed = true AND mt.is_reversed = false
  GROUP BY 1, 2
),
money_running AS (
  SELECT date, user_id,
    SUM(daily_net) OVER (PARTITION BY user_id ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS money_bal
  FROM money_daily
)
```

**To get Money balance on a specific date** (e.g., Sundays for dashboard):
```sql
money_latest AS (
  SELECT a.date, a.user_id, mr.money_bal,
    ROW_NUMBER() OVER (PARTITION BY a.date, a.user_id ORDER BY mr.date DESC) AS rn
  FROM target_dates a
  LEFT JOIN money_running mr ON a.user_id = mr.user_id AND mr.date <= a.date
)
-- Then filter: WHERE rn = 1
```

## Weekend Fill-Forward (Super & Voyager)

**Problem**: Super and Voyager balance tables are weekday-only (Mon-Fri). No rows on Sat/Sun.

```sql
-- Find last weekday per user per week
super_last_weekday AS (
  SELECT date, user_id, balance_aud,
    NEXT_DAY(date, 'SA')              AS fill_sat,
    DATE_ADD(NEXT_DAY(date, 'SA'), 1) AS fill_sun
  FROM (
    SELECT date, user_id, balance_aud,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, DATE_TRUNC('week', date)
        ORDER BY date DESC
      ) AS rn
    FROM super_bal_raw
    WHERE DAYOFWEEK(date) BETWEEN 2 AND 6  -- Mon-Fri only
  ) WHERE rn = 1
),

-- Union original + filled weekends with priority
super_bal AS (
  SELECT date, user_id, balance_aud
  FROM (
    SELECT date, user_id, balance_aud, 1 AS priority FROM super_bal_raw
    UNION ALL
    SELECT fill_sat,  user_id, balance_aud, 2 FROM super_last_weekday
    UNION ALL
    SELECT fill_sun,  user_id, balance_aud, 2 FROM super_last_weekday
  )
  QUALIFY ROW_NUMBER() OVER (PARTITION BY date, user_id ORDER BY priority) = 1
)
```

**Priority column**: Ensures original data (1) beats fill-forward (2) if both exist. Same pattern for Voyager.

**Note**: Nova has 7-day coverage and does NOT need fill-forward.

## AUD to USD Currency Conversion

```sql
aud_usd_rates AS (
  SELECT
    CAST(OccurredDate AS DATE) AS rate_date,
    (Ask + Bid) / 2 AS aud_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 7  -- AUD/USD pair
)

-- Usage:
LEFT JOIN aud_usd_rates r ON your_date_column = r.rate_date
SELECT amount_aud * COALESCE(r.aud_to_usd_rate, 0) AS amount_usd
```

**Note**: Rates lag by 1 day (today's rate available tomorrow). Use `COALESCE` for missing rates.

## Timezone Conversion Reference

| Table/Field | Stored As | Conversion |
|-------------|-----------|------------|
| Money `completed_at` | UTC timestamp | `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` |
| Nova `order_filled_at` | UTC timestamp | `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` |
| Nova `nova_first_transaction_at` (user_beta) | UTC timestamp | `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` |
| Nova `nova_signed_up_at` (user_beta) | UTC timestamp | `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` |
| User `last_logged_in_at` (user_beta) | UTC timestamp | `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` |
| Super `paid_date` | Local date | No conversion |
| Voyager `effective_date` | Local date | No conversion |
| User `signed_up_at_date` | Local date | No conversion |
| Super `first_became_financial_date` | Local date | No conversion |
| Voyager `first_became_financial_date` | Local date | No conversion |
| Nova AUM `date` | Midnight UTC | No shift needed (midnight = same date) |

## Week-Ending Convention

Spaceship uses **Sunday** as end-of-week.

### For Sunday Snapshots (Funded Accounts, FUM)
```sql
WHERE DAYOFWEEK(date) = 1  -- 1 = Sunday in Spark
  AND date >= DATE_ADD(CURRENT_DATE(), -90)  -- Rolling ~12 weeks
  AND date <= CURRENT_DATE()
```

### For Weekly Aggregation (Registrations, FTDs, Flows)
```sql
CAST(DATE_TRUNC('WEEK', date) + INTERVAL 6 DAYS AS DATE) AS week_ending
-- DATE_TRUNC('WEEK', ...) gives Monday; +6 days = Sunday
GROUP BY DATE_TRUNC('WEEK', date)
```

### Rolling 12 Weeks
Standard window: `DATE_ADD(report_date, -84)` to `report_date` (84 days = 12 weeks).

## Spaceship to eToro GCID Join

```sql
user_gcid AS (
  SELECT DISTINCT c.user_id, sa.gcid
  FROM main.bi_db.bronze_sub_accounts_accounts sa
  INNER JOIN main.spaceship.bronze_spaceship_metabase_contact c
    ON sa.accountId = c.user_id
  WHERE sa.providerName = 'Spaceship' AND sa.gcid IS NOT NULL
)
```

## Overall FTD Date (Inline, No Staging View)

Replaces the deprecated `v_spaceship_user_profile.overall_ftd_date`:

```sql
up AS (
  SELECT user_id,
    LEAST(
      COALESCE(CAST(super_first_became_financial_date AS DATE), DATE '9999-12-31'),
      COALESCE(CAST(voyager_first_became_financial_date AS DATE), DATE '9999-12-31'),
      COALESCE(CAST(FROM_UTC_TIMESTAMP(nova_first_transaction_at, 'Australia/Sydney') AS DATE), DATE '9999-12-31')
    ) AS overall_ftd_date
  FROM main.spaceship.bronze_spaceship_metabase_user_beta
  HAVING overall_ftd_date < DATE '9999-12-31'
    AND overall_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
)
```

Uses `DATE '9999-12-31'` as sentinel for NULL dates so `LEAST()` ignores products with no FTD.
