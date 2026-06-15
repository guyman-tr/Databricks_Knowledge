---
description: "Spaceship Weekly KPI Dashboard — production-tested SQL for all 6 datasets that drive the live exec dashboard (Funded Accounts b45ed899, FUM 3b55071e, Registrations 01338105, FTDs & F30DD b9e3c92e, Net Deposits 5ce11b5a, Voyager Net Deposits 31cb2609). Anchored on the v_spaceship_aum + v_spaceship_mimo prep views plus the shared Money-balance CTE (running SUM over fct_money_transactions joined via contact mapping) that the dashboard datasets reuse. Covers the dataset-to-view migration status as of 2026-04-13 — Net Deposits is migrated to v_spaceship_mimo (exact match verified); Funded Accounts, FUM, Registrations, FTDs & F30DD, and Voyager Net Deposits stay on raw tables because they need balance snapshots, per-product FTD dates, 30-day windowed F30DD sums, portfolio splits (Universe vs Other), or cohort splits (25k+ vs <25k) that the MIMO view does not expose. Use for any 'reproduce a dashboard widget' / 'how is metric X computed on the SPS dashboard' / 'why does Funded Accounts differ between view and raw' question. Cross-references: spaceship-metric-definitions.md (definitions and PDF validation), spaceship-views-architecture.md (v_spaceship_aum / v_spaceship_mimo column shape and CTE design), spaceship-data-patterns.md (the shared CTEs)."
triggers:
  - Spaceship Weekly KPI Dashboard
  - Spaceship dashboard
  - dashboard query
  - FUM
  - F30DD
  - FTD 30dd
  - dataset b45ed899
  - dataset 3b55071e
  - dataset 5ce11b5a
  - dataset 01338105
  - dataset b9e3c92e
  - dataset 31cb2609
  - week_ending
  - Sunday snapshot
  - DAYOFWEEK = 1
  - Spaceship FTD
  - per-product FTD
  - super_first_became_financial_date
  - voyager_first_became_financial_date
  - nova_first_transaction_at
  - overall_ftd_date
  - 84 days
  - rolling 12 weeks
  - v_spaceship_aum
  - v_spaceship_mimo
  - super_balance_aud
  - voyager_balance_aud
  - nova_balance_aud
  - money_balance_aud
  - is_funded_incl_money
  - Voyager UNIVERSE portfolio
  - 25k cohort
sample_questions:
  - How is Funded Accounts computed for the SPS dashboard (week-ending Sunday)?
  - Show the SQL for the dashboard Net Deposits widget (v_spaceship_mimo version)
  - Reproduce the F30DD per-product weekly chart for the last 84 days
  - Which dataset on the dashboard still uses raw bronze tables and why
  - Why does the Voyager Net Deposits widget have Portfolio and Cohort splits
required_tables:
  - main.spaceship.bronze_spaceship_metabase_contact
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_super_transactions
  - main.spaceship.bronze_spaceship_metabase_voyager_transactions
  - main.spaceship.bronze_spaceship_metabase_nova_transactions
  - main.spaceship.spaceship_metabase_voyager_user_balances
  - main.spaceship.spaceship_metabase_voyager_product_balances
  - main.etoro_kpi_prep.v_spaceship_aum
  - main.etoro_kpi_prep.v_spaceship_mimo
---

# Spaceship Dashboard Queries

**Dashboard**: Spaceship Weekly KPI Dashboard
**Dashboard ID**: `01f12d17075f19c7bcd920286696e32c`
**Tree Node ID**: `3302260643916982`
**6 Pages**: Funded Accounts, MIMO, FUM, Registrations, 30dd FTDs, Voyager Net Deposits

## Dashboard-to-View Migration Status (2026-04-13)

| Dataset | Status | Source | Why |
|---------|--------|--------|-----|
| Net Deposits (`5ce11b5a`) | **Migrating to view** | `v_spaceship_mimo` | Flow aggregation — exact match verified |
| Funded Accounts (`b45ed899`) | Stays on raw tables | `v_spaceship_aum` + Money CTE | Balance snapshots; MIMO has no balance data |
| FUM (`3b55071e`) | Stays on raw tables | `v_spaceship_aum` + Money CTE | Balance snapshots; needs running Money balance |
| Registrations (`01338105`) | Stays on raw tables | `user_beta` direct | Simple signup count; no MIMO involvement |
| FTD 30dd (`b9e3c92e`) | Stays on raw tables | `user_beta` + raw txns | Per-product FTD dates + 30-day windowed F30DD |
| Voyager Net Deposits (`31cb2609`) | Stays on raw tables | Portfolio + user balances | Portfolio-level splits + cohort (25k+) splits |

---

## Shared Money Balance CTE

Used by **Funded Accounts** and **FUM** datasets. Computes running Money wallet balance per user:

```sql
WITH contact_mapping AS (
  SELECT DISTINCT account_id, user_id
  FROM main.spaceship.bronze_spaceship_metabase_contact
  WHERE account_id IS NOT NULL AND user_id IS NOT NULL
),
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
),
aum_sundays AS (
  SELECT CAST(date AS DATE) AS date, user_id, is_funded,
    super_balance_aud, voyager_balance_aud, nova_balance_aud
  FROM main.etoro_kpi_prep.v_spaceship_aum
  WHERE DAYOFWEEK(date) = 1
    AND date >= DATE_ADD(CURRENT_DATE(), -90) AND date <= CURRENT_DATE()
),
money_latest AS (
  SELECT a.date, a.user_id, mr.money_bal,
    ROW_NUMBER() OVER (PARTITION BY a.date, a.user_id ORDER BY mr.date DESC) AS rn
  FROM aum_sundays a
  LEFT JOIN money_running mr ON a.user_id = mr.user_id AND mr.date <= a.date
),
combined AS (
  SELECT a.date, a.user_id,
    a.super_balance_aud, a.voyager_balance_aud, a.nova_balance_aud,
    COALESCE(m.money_bal, 0) AS money_balance_aud,
    a.is_funded OR COALESCE(m.money_bal, 0) > 0 AS is_funded_incl_money
  FROM aum_sundays a
  LEFT JOIN money_latest m ON a.date = m.date AND a.user_id = m.user_id AND m.rn = 1
)
```

---

## Dataset 1: Funded Accounts

**Dataset name**: `b45ed899` (display: "funded accounts")
**Columns**: `week_ending` (DATE), `product` (STRING), `funded_k` (DECIMAL)
**Sources**: `v_spaceship_aum` + inline Money CTE

Uses the shared Money CTE above, then:

```sql
SELECT date AS week_ending, 'Spaceship' AS product,
  ROUND(SUM(CASE WHEN is_funded_incl_money THEN 1 ELSE 0 END) / 1000.0, 1) AS funded_k
FROM combined GROUP BY date

UNION ALL

SELECT date AS week_ending, 'Super' AS product,
  ROUND(SUM(CASE WHEN super_balance_aud > 0 THEN 1 ELSE 0 END) / 1000.0, 1) AS funded_k
FROM combined GROUP BY date

UNION ALL

SELECT date AS week_ending, 'Voyager' AS product,
  ROUND(SUM(CASE WHEN voyager_balance_aud > 0 THEN 1 ELSE 0 END) / 1000.0, 1) AS funded_k
FROM combined GROUP BY date

ORDER BY week_ending, product
```

---

## Dataset 2: FUM

**Dataset name**: `3b55071e` (display: "FUM")
**Columns**: `week_ending` (DATE), `product` (STRING), `fum_m` (DOUBLE)
**Sources**: `v_spaceship_aum` + inline Money CTE

Uses the shared Money CTE above (without `is_funded` in aum_sundays), then:

```sql
SELECT date AS week_ending, 'Spaceship' AS product,
  ROUND(SUM(super_balance_aud + voyager_balance_aud + nova_balance_aud + money_balance_aud) / 1e6, 0) AS fum_m
FROM combined GROUP BY date

UNION ALL
SELECT date, 'Super', ROUND(SUM(super_balance_aud) / 1e6, 0) FROM combined GROUP BY date

UNION ALL
SELECT date, 'Voyager', ROUND(SUM(voyager_balance_aud) / 1e6, 0) FROM combined GROUP BY date

UNION ALL
SELECT date, 'Money', ROUND(SUM(money_balance_aud) / 1e6, 0) FROM combined GROUP BY date

ORDER BY week_ending, product
```

---

## Dataset 3: Registrations

**Dataset name**: `01338105` (display: "registrations")
**Columns**: `week_ending` (DATE), `registrations` (BIGINT)
**Sources**: `bronze_spaceship_metabase_user_beta` (direct)

```sql
SELECT
  CAST(DATE_TRUNC('week', signed_up_at_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
  COUNT(*) AS registrations
FROM main.spaceship.bronze_spaceship_metabase_user_beta
WHERE signed_up_at_date >= DATE_ADD(CURRENT_DATE(), -90)
  AND signed_up_at_date <= CURRENT_DATE()
GROUP BY DATE_TRUNC('week', signed_up_at_date)
ORDER BY 1
```

---

## Dataset 4: FTDs & F30DD

**Dataset name**: `b9e3c92e` (display: "FTD 30dd amounts")
**Columns**: `week_ending` (DATE), `product` (STRING), `ftds` (BIGINT), `f30dd_m` (DECIMAL)
**Sources**: `user_beta` + `super_transactions` + `voyager_transactions` + `nova_transactions`
**Why not MIMO**: Needs per-product FTD dates (not overall) + 30-day windowed F30DD sums.

```sql
WITH ub AS (
  SELECT user_id, member_id,
    CAST(super_first_became_financial_date AS DATE) AS super_ftd_date,
    CAST(voyager_first_became_financial_date AS DATE) AS voyager_ftd_date,
    CAST(FROM_UTC_TIMESTAMP(nova_first_transaction_at, 'Australia/Sydney') AS DATE) AS nova_ftd_date
  FROM main.spaceship.bronze_spaceship_metabase_user_beta
),

-- Overall FTD = LEAST of product FTDs (Money excluded)
up AS (
  SELECT user_id,
    LEAST(
      COALESCE(super_ftd_date, DATE '9999-12-31'),
      COALESCE(voyager_ftd_date, DATE '9999-12-31'),
      COALESCE(nova_ftd_date, DATE '9999-12-31')
    ) AS overall_ftd_date
  FROM ub
  HAVING overall_ftd_date < DATE '9999-12-31'
    AND overall_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
),

-- SPACESHIP TOTAL F30DD (all products within 30d of overall_ftd_date)
t_super AS (
  SELECT b.user_id, SUM(CAST(st.aud_amount AS DECIMAL(20,2))) AS dep
  FROM up u JOIN ub b ON u.user_id = b.user_id
  JOIN main.spaceship.bronze_spaceship_metabase_super_transactions st ON b.member_id = st.member_id
  WHERE CAST(st.paid_date AS DATE) BETWEEN u.overall_ftd_date AND DATE_ADD(u.overall_ftd_date, 29)
    AND (UPPER(st.type) = 'CONTRIBUTIONS' OR UPPER(st.description) = 'CONTRIBUTIONS TAX')
  GROUP BY b.user_id
),
t_voy AS (
  SELECT u.user_id, SUM(vt.unit_aud_amount) AS dep
  FROM up u JOIN main.spaceship.bronze_spaceship_metabase_voyager_transactions vt ON u.user_id = vt.user_id
  WHERE CAST(vt.effective_date AS DATE) BETWEEN u.overall_ftd_date AND DATE_ADD(u.overall_ftd_date, 29)
    AND vt.order_direction = 'BUY'
  GROUP BY u.user_id
),
t_nova AS (
  SELECT u.user_id, SUM(nt.order_aud_amount) AS dep
  FROM up u JOIN main.spaceship.bronze_spaceship_metabase_nova_transactions nt ON u.user_id = nt.user_id
  WHERE CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE) BETWEEN u.overall_ftd_date AND DATE_ADD(u.overall_ftd_date, 29)
    AND nt.order_direction = 'BUY'
  GROUP BY u.user_id
),
spaceship AS (
  SELECT CAST(DATE_TRUNC('WEEK', u.overall_ftd_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    'Spaceship' AS product, COUNT(*) AS ftds,
    ROUND(SUM(COALESCE(s.dep,0) + COALESCE(v.dep,0) + COALESCE(n.dep,0)) / 1e6, 2) AS f30dd_m
  FROM up u
  LEFT JOIN t_super s ON u.user_id = s.user_id
  LEFT JOIN t_voy v ON u.user_id = v.user_id
  LEFT JOIN t_nova n ON u.user_id = n.user_id
  GROUP BY 1
),

-- SUPER FTDs + F30DD
s_first AS (
  SELECT st.member_id, MIN(CAST(st.paid_date AS DATE)) AS first_dt
  FROM main.spaceship.bronze_spaceship_metabase_super_transactions st
  JOIN (SELECT DISTINCT member_id FROM ub WHERE super_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS) r
    ON st.member_id = r.member_id
  WHERE st.member_id IS NOT NULL
  GROUP BY st.member_id
),
s_30d AS (
  SELECT st.member_id, SUM(CAST(st.aud_amount AS DECIMAL(20,2))) AS dep
  FROM main.spaceship.bronze_spaceship_metabase_super_transactions st
  JOIN s_first sf ON st.member_id = sf.member_id
  WHERE CAST(st.paid_date AS DATE) BETWEEN sf.first_dt AND DATE_ADD(sf.first_dt, 29)
    AND (UPPER(st.type) = 'CONTRIBUTIONS' OR UPPER(st.description) = 'CONTRIBUTIONS TAX')
  GROUP BY st.member_id
),
super AS (
  SELECT CAST(DATE_TRUNC('WEEK', b.super_ftd_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    'Super' AS product, COUNT(*) AS ftds,
    ROUND(SUM(COALESCE(s.dep, 0)) / 1e6, 2) AS f30dd_m
  FROM ub b LEFT JOIN s_30d s ON b.member_id = s.member_id
  WHERE b.super_ftd_date IS NOT NULL AND b.super_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
  GROUP BY 1
),

-- VOYAGER FTDs + F30DD
v_30d AS (
  SELECT vt.user_id, SUM(vt.unit_aud_amount) AS dep
  FROM main.spaceship.bronze_spaceship_metabase_voyager_transactions vt
  JOIN ub b ON vt.user_id = b.user_id
  WHERE b.voyager_ftd_date IS NOT NULL AND b.voyager_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
    AND CAST(vt.effective_date AS DATE) BETWEEN b.voyager_ftd_date AND DATE_ADD(b.voyager_ftd_date, 29)
    AND vt.order_direction = 'BUY'
  GROUP BY vt.user_id
),
voyager AS (
  SELECT CAST(DATE_TRUNC('WEEK', b.voyager_ftd_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    'Voyager' AS product, COUNT(*) AS ftds,
    ROUND(SUM(COALESCE(v.dep, 0)) / 1e6, 2) AS f30dd_m
  FROM ub b LEFT JOIN v_30d v ON b.user_id = v.user_id
  WHERE b.voyager_ftd_date IS NOT NULL AND b.voyager_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
  GROUP BY 1
),

-- NOVA FTDs + F30DD
n_30d AS (
  SELECT nt.user_id, SUM(nt.order_aud_amount) AS dep
  FROM main.spaceship.bronze_spaceship_metabase_nova_transactions nt
  JOIN ub b ON nt.user_id = b.user_id
  WHERE b.nova_ftd_date IS NOT NULL AND b.nova_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
    AND CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE) BETWEEN b.nova_ftd_date AND DATE_ADD(b.nova_ftd_date, 29)
    AND nt.order_direction = 'BUY'
  GROUP BY nt.user_id
),
nova AS (
  SELECT CAST(DATE_TRUNC('WEEK', b.nova_ftd_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    'Nova' AS product, COUNT(*) AS ftds,
    ROUND(SUM(COALESCE(n.dep, 0)) / 1e6, 2) AS f30dd_m
  FROM ub b LEFT JOIN n_30d n ON b.user_id = n.user_id
  WHERE b.nova_ftd_date IS NOT NULL AND b.nova_ftd_date >= CURRENT_DATE() - INTERVAL 84 DAYS
  GROUP BY 1
)

SELECT * FROM spaceship
UNION ALL SELECT * FROM super
UNION ALL SELECT * FROM voyager
UNION ALL SELECT * FROM nova
ORDER BY week_ending, product
```

---

## Dataset 5: Net Deposits

**Dataset name**: `5ce11b5a` (display: "Net Deposits")
**Columns**: `week_ending` (DATE), `product` (STRING), `flow_type` (STRING), `amount_m` (DECIMAL), `net_deposits_m` (DECIMAL)
**Migration**: Being replaced with `v_spaceship_mimo`-based query (2026-04-13)

### New query (MIMO view-based)

**Sources**: `v_spaceship_mimo` only
**Verified**: Exact match with legacy query for all weeks tested.
**Note**: Outflows are negated (`-SUM(total_withdrawals_aud)`) because the view stores
withdrawals as positive, but the dashboard charts expect negative outflow bars.

```sql
WITH cutoff AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY AS DATE) AS last_sunday,
    CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY - INTERVAL 84 DAYS AS DATE) AS first_sunday
),

super_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(total_deposits_aud) / 1e6, 1) AS inflow_m,
    ROUND(-SUM(total_withdrawals_aud) / 1e6, 1) AS outflow_m,
    ROUND(SUM(net_flow_aud) / 1e6, 1) AS net_m
  FROM main.etoro_kpi_prep.v_spaceship_mimo
  WHERE product = 'Super'
    AND date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND date <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),

money_cust_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(total_deposits_aud) / 1e6, 1) AS inflow_m,
    ROUND(-SUM(total_withdrawals_aud) / 1e6, 1) AS outflow_m,
    ROUND(SUM(net_flow_aud) / 1e6, 1) AS net_m
  FROM main.etoro_kpi_prep.v_spaceship_mimo
  WHERE product = 'Money' AND is_internal_transfer = FALSE
    AND date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND date <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),

voyager_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(total_deposits_aud) / 1e6, 1) AS inflow_m,
    ROUND(-SUM(total_withdrawals_aud) / 1e6, 1) AS outflow_m,
    ROUND(SUM(net_flow_aud) / 1e6, 1) AS net_m
  FROM main.etoro_kpi_prep.v_spaceship_mimo
  WHERE product = 'Voyager'
    AND date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND date <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),

spaceship_combined AS (
  SELECT COALESCE(s.week_ending, m.week_ending) AS week_ending,
    ROUND(COALESCE(s.inflow_m, 0) + COALESCE(m.inflow_m, 0), 1) AS inflow_m,
    ROUND(COALESCE(s.outflow_m, 0) + COALESCE(m.outflow_m, 0), 1) AS outflow_m,
    ROUND(COALESCE(s.net_m, 0) + COALESCE(m.net_m, 0), 1) AS net_m
  FROM super_flows s
  FULL OUTER JOIN money_cust_flows m ON s.week_ending = m.week_ending
)

SELECT week_ending, 'Spaceship' AS product, 'Inflow' AS flow_type, inflow_m AS amount_m, net_m AS net_deposits_m FROM spaceship_combined
UNION ALL
SELECT week_ending, 'Spaceship', 'Outflow', outflow_m, net_m FROM spaceship_combined
UNION ALL
SELECT week_ending, 'Super', 'Inflow', inflow_m, net_m FROM super_flows
UNION ALL
SELECT week_ending, 'Super', 'Outflow', outflow_m, net_m FROM super_flows
UNION ALL
SELECT week_ending, 'Voyager', 'Inflow', inflow_m, net_m FROM voyager_flows
UNION ALL
SELECT week_ending, 'Voyager', 'Outflow', outflow_m, net_m FROM voyager_flows
ORDER BY week_ending, product, flow_type
```

### Legacy query (raw tables, being replaced)

**Sources**: `super_transactions` + `voyager_user_balances` + `fct_money_transactions`
Kept here for reference until migration is confirmed in production.

```sql
WITH cutoff AS (
  SELECT CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY AS DATE) AS last_sunday,
         CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY - INTERVAL 84 DAYS AS DATE) AS first_sunday
),
super_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', CAST(paid_date AS DATE)) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(CASE WHEN type = 'Contributions' OR description = 'Contributions Tax'
                   THEN CAST(aud_amount AS DECIMAL(20,2)) ELSE 0 END) / 1e6, 1) AS inflow_m,
    ROUND(SUM(CASE WHEN type IN ('Benefit Payment','Fees','Tax') AND COALESCE(description,'') <> 'Contributions Tax'
                   THEN CAST(aud_amount AS DECIMAL(20,2)) ELSE 0 END) / 1e6, 1) AS outflow_m,
    ROUND(SUM(CASE WHEN type IN ('Benefit Payment','Contributions','Fees','Tax')
                   THEN CAST(aud_amount AS DECIMAL(20,2)) ELSE 0 END) / 1e6, 1) AS net_m
  FROM main.spaceship.bronze_spaceship_metabase_super_transactions
  WHERE (CAST(paid_date AS DATE) <> DATE '2024-05-18' OR paid_date IS NULL)
    AND CAST(paid_date AS DATE) >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND CAST(paid_date AS DATE) <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),
voyager_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', effective_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(inflow_aud_amount) / 1e6, 1) AS inflow_m,
    -ROUND(SUM(ABS(outflow_aud_amount)) / 1e6, 1) AS outflow_m,
    ROUND(SUM(net_aud_transacted) / 1e6, 1) AS net_m
  FROM main.spaceship.spaceship_metabase_voyager_user_balances
  WHERE effective_date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND effective_date <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),
money_cust_flows AS (
  SELECT
    CAST(DATE_TRUNC('WEEK', CAST(FROM_UTC_TIMESTAMP(completed_at, 'Australia/Sydney') AS DATE)) + INTERVAL 6 DAYS AS DATE) AS week_ending,
    ROUND(SUM(CASE WHEN transaction_type IN ('USER_DEPOSIT','USER_DEPOSIT_REVERSAL','NOVA_DIVIDEND','NOVA_MERGER_ACQUISITIONS')
                   THEN aud_amount ELSE 0 END) / 1e6, 1) AS inflow_m,
    ROUND(SUM(CASE WHEN transaction_type IN ('USER_WITHDRAWAL','USER_WITHDRAWAL_REVERSAL','NOVA_TAF_FEE','NOVA_REG_FEE','NOVA_MONTHLY_FEE')
                   THEN aud_amount ELSE 0 END) / 1e6, 1) AS outflow_m,
    ROUND(SUM(CASE WHEN transaction_type IN ('USER_DEPOSIT','USER_DEPOSIT_REVERSAL','USER_WITHDRAWAL','USER_WITHDRAWAL_REVERSAL',
                                              'NOVA_DIVIDEND','NOVA_TAF_FEE','NOVA_REG_FEE','NOVA_MERGER_ACQUISITIONS')
                   THEN aud_amount ELSE 0 END) / 1e6, 1) AS net_m
  FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  WHERE status NOT IN ('CANCELLED','FAILED','REJECTED')
    AND CAST(FROM_UTC_TIMESTAMP(completed_at, 'Australia/Sydney') AS DATE) >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
    AND CAST(FROM_UTC_TIMESTAMP(completed_at, 'Australia/Sydney') AS DATE) <= (SELECT last_sunday FROM cutoff)
  GROUP BY 1
),
spaceship_combined AS (
  SELECT COALESCE(s.week_ending, m.week_ending) AS week_ending,
    ROUND(COALESCE(s.inflow_m,0) + COALESCE(m.inflow_m,0), 1) AS inflow_m,
    ROUND(COALESCE(s.outflow_m,0) + COALESCE(m.outflow_m,0), 1) AS outflow_m,
    ROUND(COALESCE(s.net_m,0) + COALESCE(m.net_m,0), 1) AS net_m
  FROM super_flows s FULL OUTER JOIN money_cust_flows m ON s.week_ending = m.week_ending
)

SELECT week_ending, 'Spaceship' AS product, 'Inflow' AS flow_type, inflow_m AS amount_m, net_m AS net_deposits_m FROM spaceship_combined
UNION ALL
SELECT week_ending, 'Spaceship', 'Outflow', outflow_m, net_m FROM spaceship_combined
UNION ALL
SELECT week_ending, 'Super', 'Inflow', inflow_m, net_m FROM super_flows
UNION ALL
SELECT week_ending, 'Super', 'Outflow', outflow_m, net_m FROM super_flows
UNION ALL
SELECT week_ending, 'Voyager', 'Inflow', inflow_m, net_m FROM voyager_flows
UNION ALL
SELECT week_ending, 'Voyager', 'Outflow', outflow_m, net_m FROM voyager_flows
ORDER BY week_ending, product, flow_type
```

---

## Dataset 6: Voyager Net Deposits (Portfolio + Cohort)

**Dataset name**: `31cb2609` (display: "Voyager net deposits")
**Columns**: `chart` (STRING), `week_ending` (DATE), `category` (STRING), `amount_m` (DECIMAL)
**Sources**: `voyager_product_balances` + `voyager_user_balances`
**Why not MIMO**: Needs portfolio-level splits (Universe vs Other) and cohort splits (25k+ vs <25k)
that require `portfolio` and `aud_balance_prev` columns not available in MIMO.

Filter by `chart` column to separate widgets: 'Portfolio' or 'Cohort'.

```sql
WITH cutoff AS (
  SELECT CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY AS DATE) AS last_sunday,
         CAST(DATE_TRUNC('WEEK', CURRENT_DATE()) - INTERVAL 1 DAY - INTERVAL 84 DAYS AS DATE) AS first_sunday
)

SELECT
  'Portfolio' AS chart,
  CAST(DATE_TRUNC('WEEK', effective_date) + INTERVAL 6 DAYS AS DATE) AS week_ending,
  CASE WHEN portfolio = 'UNIVERSE' THEN 'Universe' ELSE 'Other Portfolios' END AS category,
  ROUND(SUM(net_aud_transacted) / 1e6, 1) AS amount_m
FROM main.spaceship.spaceship_metabase_voyager_product_balances
WHERE effective_date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
  AND effective_date <= (SELECT last_sunday FROM cutoff)
GROUP BY 1, 2, 3

UNION ALL

SELECT
  'Cohort',
  CAST(DATE_TRUNC('WEEK', effective_date) + INTERVAL 6 DAYS AS DATE),
  CASE WHEN aud_balance_prev >= 25000 THEN '25k+' ELSE '<25k' END,
  ROUND(SUM(net_aud_transacted) / 1e6, 1)
FROM main.spaceship.spaceship_metabase_voyager_user_balances
WHERE effective_date >= (SELECT first_sunday - INTERVAL 6 DAYS FROM cutoff)
  AND effective_date <= (SELECT last_sunday FROM cutoff)
GROUP BY 1, 2, 3

ORDER BY chart, week_ending, category
```
