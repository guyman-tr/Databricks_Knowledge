# Proposed additions to metric-definitions.md
# Generated: 2026-04-04T17:04:45.180712
# Findings: 4

### [METRIC] New FTDs (First-Time Deposits) metric calculations for various time periods (yesterday, this week, this month, this quarter, this year)
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### FTDs Calculations

The following calculations are used to determine FTDs for different time periods:

* FTDs Yesterday: `SUM(CASE WHEN date = DATE_SUB(max_date, 1) AND is_ftd = 1 THEN 1 ELSE 0 END)`
* FTDs This Week: `SUM(CASE WHEN date >= DATE_TRUNC('week', DATE_ADD(DATE_SUB(max_date, 1), 1)) - INTERVAL 1 DAY AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END)`
* FTDs This Month: `SUM(CASE WHEN date >= DATE_TRUNC('month', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END)`
* FTDs This Quarter: `SUM(CASE WHEN date >= DATE_TRUNC('quarter', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END)`
* FTDs This Year: `SUM(CASE WHEN date >= DATE_TRUNC('year', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END)`

### [METRIC] New FTDs (First-Time Deposits) metric calculations for different time periods (yesterday, this week, this month, this quarter, this year)
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### FTDs Time Periods

The following FTDs metrics are calculated based on different time periods:
* FTDs Yesterday: The number of first-time deposits made yesterday.
* FTDs This Week: The number of first-time deposits made this week, starting from the Sunday before yesterday.
* FTDs This Month: The number of first-time deposits made this month, starting from the first day of the month of yesterday.
* FTDs This Quarter: The number of first-time deposits made this quarter, starting from the first day of the quarter of yesterday.
* FTDs This Year: The number of first-time deposits made this year, starting from the first day of the year of yesterday.

These metrics can be calculated using the following SQL query:
```sql
SUM(CASE WHEN date = DATE_SUB(max_date, 1) AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_yesterday,
SUM(CASE WHEN date >= DATE_TRUNC('week', DATE_ADD(DATE_SUB(max_date, 1), 1)) - INTERVAL 1 DAY AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_week,
SUM(CASE WHEN date >= DATE_TRUNC('month', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_month,
SUM(CASE WHEN date >= DATE_TRUNC('quarter', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_quarter,
SUM(CASE WHEN date >= DATE_TRUNC('year', DATE_SUB(max_date, 1)) AND date < max_date AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_year
```
Note: `max_date` is the maximum date in the `v_spaceship_mimo` table.

### [METRIC] New metric calculation: total funded users as of the latest date with non-zero total balance
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Total Funded Users
The total number of distinct users with a funded account as of the latest date with a non-zero total balance.
```sql
SELECT COUNT(DISTINCT user_id) AS total_funded_users
FROM main.etoro_kpi_prep.v_spaceship_aum
WHERE date = (SELECT MAX(date) FROM main.etoro_kpi_prep.v_spaceship_aum WHERE total_balance_usd > 0)
AND is_funded = TRUE
AND total_balance_usd > 0
```

### [METRIC] New metric calculation for total funded users
> Discovered 2026-04-04 from Tableau query by 079a992a-c990-4a3a-b901-af1042066afa

### Total Funded Users
The total number of funded users is calculated by counting the distinct user_ids in the v_spaceship_aum table where is_funded = TRUE and total_balance_usd > 0. The data is filtered to only include the most recent date available in the table.
