# Proposed additions to data-patterns.md
# Generated: 2026-04-04T17:04:45.179156
# Findings: 7

### [PATTERN] New CTE pattern for calculating fees for different time ranges (Yesterday, This Week, This Month, This Quarter, This Year)
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Time Range Fee Calculation

To calculate fees for different time ranges, use the following CTE pattern:
```sql
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_fees
)
SELECT 'Yesterday' AS TimeRange, product, SUM(total_fees_usd) AS Value
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date = max_date GROUP BY 1, 2

UNION ALL
SELECT 'This Week' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('week', DATE_ADD(max_date, 1)) - INTERVAL '1 day' 
GROUP BY 1, 2

UNION ALL
SELECT 'This Month' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('month', max_date) GROUP BY 1, 2

UNION ALL
SELECT 'This Quarter' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('quarter', max_date) GROUP BY 1, 2

UNION ALL
SELECT 'This Year' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('year', max_date) GROUP BY 1, 2
```

### [PATTERN] New CTE pattern for calculating latest available balances for Super, Voyager, and Nova products
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Latest Available Balances

To get the latest available balances for Super, Voyager, and Nova products, use the following CTE pattern:
```sql
latest_balances AS (
  SELECT 'Latest Available' AS TimeRange,
    is_funded,
    SUM(super_balance_usd) as Super,
    SUM(voyager_balance_usd) as Voyager,
    SUM(nova_balance_usd) as Nova,
    SUM(COALESCE(super_balance_usd, 0) + COALESCE(voyager_balance_usd, 0) + COALESCE(nova_balance_usd, 0)) as Total
  FROM main.etoro_kpi_prep.v_spaceship_aum
  WHERE date_id = (
    SELECT MAX(date_id) 
    FROM (
      SELECT date_id, SUM(super_balance_usd) as daily_super
      FROM main.etoro_kpi_prep.v_spaceship_aum
      GROUP BY date_id
    ) t
    WHERE daily_super > 0
  )
  GROUP BY is_funded
)
```
This pattern can be used to get the latest available balances for each product, and can be modified to fit specific use cases.

### [PATTERN] New join pattern and table relationships involving main.spaceship.bronze_spaceship_analytics_rpt_etoro_user_screening and multiple dim tables
> Discovered 2026-04-04 from Tableau query by b8676b1b-f23f-4be7-8ad3-506ddeaef722

### eToro User Screening Join Pattern

To join eToro user screening data with other tables, use the following pattern:
```sql
JOIN main.bi_db.bronze_sub_accounts_accounts a ON a.accountId = sc.contact_id
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.GCID = a.gcid
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus dss ON dss.ScreeningStatusID = dc.ScreeningStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps ON ps.PlayerStatusID = dc.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr ON psr.PlayerStatusReasonID = dc.PlayerStatusReasonID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr ON pssr.PlayerStatusSubReasonID = dc.PlayerStatusSubReasonID
```
This pattern can be used to retrieve user screening data, including screening status, player status, and player status reason.

### [PATTERN] New CTE pattern for calculating time-range based metrics (Yesterday, This Week, This Month, This Quarter, This Year) using date truncation and subtraction
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Time-Range Based Metrics

To calculate metrics for different time ranges, you can use the following CTE pattern:
```sql
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_mimo
),
base_data AS (
  SELECT date, is_ftd, product, total_deposits_usd, total_withdrawals_usd, net_flow_usd
  FROM main.etoro_kpi_prep.v_spaceship_mimo
  WHERE is_internal_transfer = 'false'
)
SELECT 'Yesterday' AS TimeRange, is_ftd, product, SUM(total_deposits_usd) AS Total_Deposits, SUM(total_withdrawals_usd) AS Total_Withdrawals, SUM(net_flow_usd) AS Net_Flow
FROM base_data, max_date_val
WHERE date = DATE_SUB(max_date, 1)
GROUP BY 1, 2, 3

UNION ALL
...
```
This pattern uses date truncation and subtraction to calculate metrics for different time ranges, such as yesterday, this week, this month, this quarter, and this year.

### [PATTERN] New CTE pattern for calculating fees for different time ranges (Yesterday, This Week, This Month, This Quarter, This Year)
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

## Time Range Fees

To calculate fees for different time ranges, use the following CTE pattern:
```sql
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_fees
)
SELECT 'Yesterday' AS TimeRange, product, SUM(total_fees_usd) AS Value
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date = max_date GROUP BY 1, 2

UNION ALL
SELECT 'This Week' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('week', DATE_ADD(max_date, 1)) - INTERVAL '1 day' 
GROUP BY 1, 2

UNION ALL
SELECT 'This Month' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('month', max_date) GROUP BY 1, 2

UNION ALL
SELECT 'This Quarter' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('quarter', max_date) GROUP BY 1, 2

UNION ALL
SELECT 'This Year' AS TimeRange, product, SUM(total_fees_usd)
FROM main.etoro_kpi_prep.v_spaceship_fees, max_date_val
WHERE date >= DATE_TRUNC('year', max_date) GROUP BY 1, 2
```

### [PATTERN] New CTE pattern for calculating net flow, total deposits, and total withdrawals for different time ranges (yesterday, this week, this month, this quarter, this year)
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Time Range Calculations

To calculate net flow, total deposits, and total withdrawals for different time ranges, use the following CTE pattern:
```sql
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_mimo
),
base_data AS (
  SELECT date, is_ftd, product, total_deposits_usd, total_withdrawals_usd, net_flow_usd
  FROM main.etoro_kpi_prep.v_spaceship_mimo
  WHERE is_internal_transfer = 'false'
)
SELECT 'Yesterday' AS TimeRange, is_ftd, product, SUM(total_deposits_usd) AS Total_Deposits, SUM(total_withdrawals_usd) AS Total_Withdrawals, SUM(net_flow_usd) AS Net_Flow
FROM base_data, max_date_val
WHERE date = DATE_SUB(max_date, 1)
GROUP BY 1, 2, 3

UNION ALL
...
```
This pattern can be used to calculate metrics for different time ranges, such as yesterday, this week, this month, this quarter, and this year.

### [PATTERN] New join pattern and subquery to find the latest available date with non-zero Super balance
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Latest Available Date Pattern
To find the latest available date with non-zero Super balance, use the following subquery and join pattern:
```sql
SELECT MAX(date_id) 
FROM (
  SELECT date_id, SUM(super_balance_usd) as daily_super
  FROM main.etoro_kpi_prep.v_spaceship_aum
  GROUP BY date_id
) t
WHERE daily_super > 0
```
This pattern can be used to filter data to the latest available date with non-zero Super balance.
