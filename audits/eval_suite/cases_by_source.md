# Eval-Suite Cases — Question → SQL

_Total: 94 cases across 4 sources._


---
## `ddr` — 17 cases


### `ddr__ddr_aum_v__total_global_aum`

- **NL question:** What was eToro's total global AUM on 2026-06-08?
- **Skill hub:** `domain-aum-and-aua` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_aum_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `17,021,160,057.9562`

```sql
SELECT SUM(EquityGlobal) AS aum_global
FROM main.etoro_kpi.ddr_aum_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_aum_v__tp_aum`

- **NL question:** What was eToro's Trading Platform total equity on 2026-06-08?
- **Skill hub:** `domain-aum-and-aua` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_aum_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `16,802,809,570.8245`

```sql
SELECT SUM(EquityTradingPlatform) AS tp_equity
FROM main.etoro_kpi.ddr_aum_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_customer_current_flags__current_active`

- **NL question:** How many customers currently have IsActiveTrade=1?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_customer_current_flags`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `85,717.0000`
- **Notes:** Current-state view; asof is captured but the view always reflects latest.

```sql
SELECT COUNT(*) AS active_customers
FROM main.etoro_kpi.ddr_customer_current_flags
WHERE IsActiveTrade = 1
```

### `ddr__ddr_customer_current_flags__current_funded`

- **NL question:** How many customers currently have IsFunded=1?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_customer_current_flags`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `3,935,735.0000`

```sql
SELECT COUNT(*) AS funded_customers
FROM main.etoro_kpi.ddr_customer_current_flags
WHERE IsFunded = 1
```

### `ddr__ddr_customer_dailystatus__active_traders`

- **NL question:** How many customers were Active Traders on 2026-06-08?
- **Skill hub:** `domain-customer-and-identity` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_customer_dailystatus`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `85,717.0000`
- **Notes:** ddr_customer_dailystatus is SCD-style with FromDateID/ToDateID. Column is IsActiveTrade (no 'r'), not IsActiveTrader.

```sql
SELECT COUNT(DISTINCT RealCID) AS active_traders
FROM main.etoro_kpi.ddr_customer_dailystatus
WHERE FromDateID <= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND ToDateID >= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IsActiveTrade = 1
```

### `ddr__ddr_customer_dailystatus__funded_customers`

- **NL question:** How many funded customers did eToro have on 2026-06-08?
- **Skill hub:** `domain-customer-and-identity` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_customer_dailystatus`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `3,935,735.0000`

```sql
SELECT COUNT(DISTINCT RealCID) AS funded
FROM main.etoro_kpi.ddr_customer_dailystatus
WHERE FromDateID <= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND ToDateID >= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IsFunded = 1
```

### `ddr__ddr_customer_snapshot_scd_v__customer_count`

- **NL question:** How many customers were on the platform as of 2026-06-08?
- **Skill hub:** `domain-customer-and-identity` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_customer_snapshot_scd_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `47,260,120.0000`

```sql
SELECT COUNT(*) AS customers
FROM main.etoro_kpi.ddr_customer_snapshot_scd_v
WHERE FromDateID <= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND ToDateID >= CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_customer_snapshot_scd_v__valid_customer_count`

- **NL question:** How many valid customers (IsValidCustomer=1) were on the platform as of 2026-06-08?
- **Skill hub:** `domain-customer-and-identity` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_customer_snapshot_scd_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `47,260,120.0000`

```sql
SELECT COUNT(*) AS valid_customers
FROM main.etoro_kpi.ddr_customer_snapshot_scd_v
WHERE FromDateID <= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND ToDateID >= CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IsValidCustomer = 1
```

### `ddr__ddr_mimo_v__deposits_count`

- **NL question:** How many deposits landed on 2026-06-08 across all platforms?
- **Skill hub:** `domain-payments` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_mimo_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `96,359.0000`

```sql
SELECT COUNT(*) AS deposit_events
FROM main.etoro_kpi.ddr_mimo_v
WHERE Date = DATE'2026-06-08'
  AND MIMOAction = 'Deposit'
```

### `ddr__ddr_mimo_v__total_deposits_usd`

- **NL question:** What was eToro's total deposit amount in USD on 2026-06-08?
- **Skill hub:** `domain-payments` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_mimo_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `78,368,403.6600`

```sql
SELECT SUM(AmountUSD) AS total_deposits_usd
FROM main.etoro_kpi.ddr_mimo_v
WHERE Date = DATE'2026-06-08'
  AND MIMOAction = 'Deposit'
```

### `ddr__ddr_pnl_v__realized_net_profit`

- **NL question:** What was the total realized net profit on closed positions on 2026-06-08?
- **Skill hub:** `domain-trading` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_pnl_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `-1,146,488.9600`

```sql
SELECT SUM(NetProfit) AS net_profit
FROM main.etoro_kpi.ddr_pnl_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_pnl_v__unrealized_pnl_change`

- **NL question:** What was the total unrealized P&L change for eToro customers on 2026-06-08?
- **Skill hub:** `domain-trading` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_pnl_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `106,583,275.5300`

```sql
SELECT SUM(UnrealizedPnLChange) AS pnl_change
FROM main.etoro_kpi.ddr_pnl_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_revenue_v__commissions_amount`

- **NL question:** How much commission revenue did eToro book on 2026-06-08?
- **Skill hub:** `domain-revenue-and-fees` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_revenue_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `1,235,730.8681`

```sql
SELECT SUM(RevenueAmount) AS commissions
FROM main.etoro_kpi.ddr_revenue_v
WHERE Date = DATE'2026-06-08'
  AND Metric = 'FullCommission'
```

### `ddr__ddr_revenue_v__total_revenue_by_category`

- **NL question:** Break down eToro's total revenue on 2026-06-08 by RevenueMetricCategory.
- **Skill hub:** `domain-revenue-and-fees` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_revenue_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular=NULL`

```sql
SELECT RevenueMetricCategory, SUM(RevenueAmount) AS revenue
FROM main.etoro_kpi.ddr_revenue_v
WHERE Date = DATE'2026-06-08'
  AND IncludedInTotalRevenue = 1
GROUP BY RevenueMetricCategory ORDER BY revenue DESC
```

### `ddr__ddr_revenue_v__total_revenue_total`

- **NL question:** What was eToro's total revenue on 2026-06-08?
- **Skill hub:** `domain-revenue-and-fees` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_revenue_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,895,451.3087`

```sql
SELECT SUM(RevenueAmount) AS total_revenue
FROM main.etoro_kpi.ddr_revenue_v
WHERE Date = DATE'2026-06-08'
  AND IncludedInTotalRevenue = 1
```

### `ddr__ddr_trading_volumes_and_amounts_v__trading_volume_total`

- **NL question:** What was eToro's total trading volume on 2026-06-08?
- **Skill hub:** `domain-trading` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `4,446,105,002.0000`

```sql
SELECT SUM(TotalVolume) AS volume
FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

### `ddr__ddr_trading_volumes_and_amounts_v__volume_open`

- **NL question:** What was the total notional volume of positions opened on 2026-06-08?
- **Skill hub:** `domain-trading` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,272,267,005.0000`

```sql
SELECT SUM(VolumeOpen) AS volume_open
FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
```

---
## `genie_benchmark` — 51 cases


### `genie__clone_ddr_dor__calculate_the_total_revenue_deposits_wit__1`

- **NL question:** Calculate the total revenue, deposits, withdrawals for 2026-04-18
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_mimo_v`, `main.etoro_kpi.ddr_revenue_v`
- **asof:** 2026-06-08
- **Expected:** `PENDING` = `PENDING`
- **Notes:** Seeded from Genie space 'Clone DDR - dor' (01f14e992c7a13d8baad26551003f878) benchmark question.
[pin error] SQL FAILED: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `GlobalDepositsAmount` cannot be resolved. Did you mean one

```sql
SELECT
  (
    SELECT
      SUM(`RevenueAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_revenue_v`
    WHERE
      `DateID` = 20260418 and IncludedInTotalRevenue = 1
  ) AS TotalRevenue,
  (
    SELECT
      SUM(`GlobalDepositsAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_mimo_v`
    WHERE
      `DateID` = 20260418
  ) AS TotalDeposits,
  (
    SELECT
      SUM(`GlobalWithdrawsAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_mimo_v`
    WHERE
      `DateID` = 20260418
  ) AS TotalWithdrawals
```

### `genie__clone_ddr_dor__what_was_the_number_of_registrations_in___0`

- **NL question:** What was the number of registrations in the Arabic region from Affiliate ID 72493 in February 2026?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`, `main.etoro_kpi.vg_customer_customer_first_dates`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `1,670.0000`
- **Notes:** Seeded from Genie space 'Clone DDR - dor' (01f14e992c7a13d8baad26551003f878) benchmark question.

```sql
WITH reg AS (
  SELECT
    f.RealCID,
    f.RegistrationDate
  FROM
    `main`.`etoro_kpi`.`vg_customer_customer_first_dates` f
  WHERE
    f.RegistrationDate >= '2026-02-01'
    AND f.RegistrationDate < '2026-03-01'
)
SELECT
  COUNT(DISTINCT reg.RealCID) AS num_registrations
FROM
  reg
    JOIN `main`.`etoro_kpi`.`customer_snapshot_v` s
      ON reg.RealCID = s.RealCID
WHERE
  s.Region = 'Arabic'
  AND s.AffiliateID = 72493
  AND s.DateID = 20260228;
```

### `genie__dev_compliance_genie__cfd_issettled_0__1`

- **NL question:** CFD - IsSettled = 0!
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`, `main.etoro_kpi_stg.bi_output_vg_revenue_slim`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `10,185,559.4965`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT SUM(r.RevenueAmount) AS CFD_Fullcommission_Revenue_2025_ASIC
FROM `main`.`etoro_kpi_stg`.`bi_output_vg_revenue_slim` r
INNER JOIN `main`.`etoro_kpi`.`customer_snapshot_v` c
  ON r.RealCID = c.RealCID AND r.DateID = c.DateID
WHERE r.CalendarYear = 2025
  AND r.Metric = 'FullCommission'
  AND r.IncludedInTotalRevenue = 1
  AND r.IsSettled = 0
  AND c.Regulation IN ('ASIC', 'ASIC & GAML')
```

### `genie__dev_compliance_genie__give_me_a_count_of_clients_that_were_in___8`

- **NL question:** Give me a count of clients that were in FCA for the entire of Jan-2026,
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `33,376.0000`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
WITH fca_jan_clients AS (
  SELECT `RealCID`
  FROM `main`.`etoro_kpi`.`customer_snapshot_v`
  WHERE `Regulation` = 'FCA'
    AND `Date` >= '2026-01-01' AND `Date` < '2026-02-01'
  GROUP BY `RealCID`
  HAVING COUNT(DISTINCT `Date`) = 31
)
SELECT COUNT(DISTINCT cs.`RealCID`) AS client_count
FROM `main`.`etoro_kpi`.`customer_snapshot_v` cs
JOIN fca_jan_clients fca ON cs.`RealCID` = fca.`RealCID`
WHERE cs.`IsLastDayMonth` = 1
  AND cs.`CalendarYearMonth` = '2026-01'
  AND cs.`VerificationLevelID` = 3
  AND cs.`ClubTier` = 'Platinum'
```

### `genie__dev_compliance_genie__give_me_clients_in_the_end_of_2025_that___9`

- **NL question:** give me Clients in the end of 2025  that were in Cysec , was not blocked during this time, had V3, and only clubs clients
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[10000r x 6c]: cols=['RealCID', 'GCID', 'ClubTier', 'Regulation', 'VerificationLevelID', 'PlayerLevelID'] head=[[16558295, 16847326, 'Platinum', 'CySEC', 3, 2]]`

  | RealCID | GCID | ClubTier | Regulation | VerificationLevelID | PlayerLevelID |
  | --- | --- | --- | --- | --- | --- |
  | 16558295 | 16847326 | Platinum | CySEC | 3 | 2 |
  | 13204789 | 13493794 | Silver | CySEC | 3 | 5 |
  | 9449182 | 9735981 | Silver | CySEC | 3 | 5 |
  | 20004103 | 20291691 | Gold | CySEC | 3 | 3 |
  | 13245948 | 13534903 | Gold | CySEC | 3 | 3 |
  _...9995 more rows_
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT
  `RealCID`,
  `GCID`,
  `ClubTier`,
  `Regulation`,
  `VerificationLevelID`,
  `PlayerLevelID`
FROM
  `main`.`etoro_kpi`.`customer_snapshot_v`
WHERE
  `IsLastDayYear` = 1
  AND `CalendarYear` = 2025
  AND `Regulation` = 'CySEC'
  AND `PlayerStatusID` NOT IN (2, 4)
  AND `VerificationLevelID` = 3
  AND `PlayerLevelID` IN (2, 5, 6, 7, 3);
```

### `genie__dev_compliance_genie__how_many_trades_openned_on_february_2026__5`

- **NL question:** how many trades openned on february 2026
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `33,912,728.0000`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT SUM(CASE WHEN coalesce(`IsPartialCloseChild`,0) = 0 THEN 1 ELSE 0 END) AS trades_opened_feb_2026
FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
WHERE `opendateid` BETWEEN 20260201 AND 20260229
  AND `opendateid` IS NOT NULL
```

### `genie__dev_compliance_genie__please_give_a_count_of_users_that_are_cu__3`

- **NL question:** please give a count of users that are currently blocked for CFD and answered q9 = '5% / -3%' and didn't answer q10 = 'Up to $10K'
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cfd_statusinfo_v`, `main.etoro_kpi.kyc_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `702,669.0000`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
WITH blocked_cfd_users AS (
  SELECT DISTINCT `RealCID`
  FROM `main`.`etoro_kpi`.`cfd_statusinfo_v`
  WHERE `CFD_Status` != 'CFD_Allowed'
),
q9_users AS (
  SELECT DISTINCT `CID`
  FROM `main`.`etoro_kpi`.`kyc_for_compliance_v`
  WHERE `QuestionId` = 9 AND `AnswerText` = '5% / -3%' AND `Is_Current` = 1
),
q10_users AS (
  SELECT DISTINCT `CID`
  FROM `main`.`etoro_kpi`.`kyc_for_compliance_v`
  WHERE `QuestionId` = 10 AND `AnswerText` = 'Up to $10K' AND `Is_Current` = 1
)
SELECT COUNT(DISTINCT bcu.RealCID) AS blocked_cfd_q9_no_q10_count
FROM blocked_cfd_users bcu
JOIN q9_users q9u ON CAST(bcu.RealCID AS STRING) = CAST(q9u.CID AS STRING)
LEFT JOIN q10_users q10u ON CAST(bcu.RealCID AS STRING) = CAST(q10u.CID AS STRING)
WHERE q10u.CID IS NULL
```

### `genie__dev_compliance_genie__please_give_a_sum_of_lifetime_revenue_fo__0`

- **NL question:** please give a sum of Lifetime revenue for CFD Fullcommission for asic clients during 2025
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`, `main.etoro_kpi_stg.bi_output_vg_revenue_slim`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `10,185,559.4965`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT SUM(bi_output_vg_revenue_slim.RevenueAmount) AS LifetimeCFDFullCommissionRevenue
FROM `main`.`etoro_kpi`.`customer_snapshot_v` AS customer_snapshot_v
JOIN `main`.`etoro_kpi_stg`.`bi_output_vg_revenue_slim` AS bi_output_vg_revenue_slim
  ON customer_snapshot_v.RealCID = bi_output_vg_revenue_slim.RealCID
  AND customer_snapshot_v.DateID = bi_output_vg_revenue_slim.DateID
WHERE customer_snapshot_v.Regulation IN ('ASIC', 'ASIC & GAML')
  AND customer_snapshot_v.CalendarYear = 2025
  AND bi_output_vg_revenue_slim.Metric = 'FullCommission'
  AND bi_output_vg_revenue_slim.IsSettled = 0
```

### `genie__dev_compliance_genie__please_give_a_sum_of_revenue_for_cfd_ful__2`

- **NL question:** please give a sum of revenue for CFD Fullcomission for asic clients during 2025
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`, `main.etoro_kpi_stg.bi_output_vg_revenue_slim`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `123,694.2761`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT
  SUM(bi_output_vg_revenue_slim.RevenueAmount) AS lifetime_revenue_cfd_fullcommission_asic_2025
FROM
  `main`.`etoro_kpi`.`customer_snapshot_v` AS customer_snapshot_v
    JOIN `main`.`etoro_kpi_stg`.`bi_output_vg_revenue_slim` AS bi_output_vg_revenue_slim
      ON customer_snapshot_v.RealCID = bi_output_vg_revenue_slim.RealCID
      AND customer_snapshot_v.DateID = bi_output_vg_revenue_slim.DateID
WHERE
  customer_snapshot_v.Regulation = 'ASIC'
  AND bi_output_vg_revenue_slim.IsSettled = 0
  AND bi_output_vg_revenue_slim.IncludedInTotalRevenue = 1
  AND bi_output_vg_revenue_slim.Metric = 'FullCommission'
  AND bi_output_vg_revenue_slim.DateID BETWEEN 20250101 AND 20251231
  AND bi_output_vg_revenue_slim.RevenueAmount IS NOT NULL;
```

### `genie__dev_compliance_genie__please_give_me_the_number_of_client_that__6`

- **NL question:** please give me the number of client that are allowed for CFD but didn't trade CFD
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cfd_statusinfo_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `11,226,822.0000`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
WITH cfd_allowed_clients AS (
  SELECT DISTINCT `RealCID`
  FROM `main`.`etoro_kpi`.`cfd_statusinfo_v`
  WHERE `CFD_Status` = 'CFD_Allowed'
),
clients_with_cfd_trades AS (
  SELECT DISTINCT `cid` AS RealCID
  FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
  WHERE `issettled` = 0
)
SELECT COUNT(*) AS num_clients_allowed_no_cfd_trade
FROM cfd_allowed_clients cac
LEFT JOIN clients_with_cfd_trades cwt ON cac.RealCID = cwt.RealCID
WHERE cwt.RealCID IS NULL
```

### `genie__dev_compliance_genie__please_give_me_the_number_of_client_that__7`

- **NL question:** please give me the number of client that are allowed for CFD but didn't trade CFD
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cfd_statusinfo_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `11,226,822.0000`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
WITH cfd_allowed_clients AS (
  SELECT DISTINCT
    RealCID
  FROM
    `main`.`etoro_kpi`.`cfd_statusinfo_v`
  WHERE
    CFD_Status IN ('CFD_Allowed')
),
open_cfd_traders AS (
  SELECT DISTINCT
    cid
  FROM
    `main`.`etoro_kpi`.`positions_for_compliance_v`
  WHERE
    issettled = 0
)
SELECT
  COUNT(*) AS num_clients_allowed_no_trade
FROM
  cfd_allowed_clients cac
    LEFT JOIN open_cfd_traders oct
      ON cac.RealCID = oct.cid
WHERE
  oct.cid IS NULL
```

### `genie__dev_compliance_genie__show_future_volume_of_positions_openned___4`

- **NL question:** Show Future volume of positions openned on february 2026 and the volume of position closed on february 2026
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[1]: [[187717646, 188167555]]`
- **Notes:** Seeded from Genie space 'DEV - Compliance Genie' (01f158ec1e0e1bb0852910e06d28c582) benchmark question.

```sql
SELECT
  SUM(CASE WHEN `isfuture` = 1 AND `opendateid` BETWEEN 20260201 AND 20260229 AND `volume` IS NOT NULL THEN `volume` ELSE 0 END) AS future_volume_opened_feb_2026,
  SUM(CASE WHEN `isfuture` = 1 AND `closedateid` BETWEEN 20260201 AND 20260229 AND `volumeonclose` IS NOT NULL THEN `volumeonclose` ELSE 0 END) AS future_volume_closed_feb_2026
FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
```

### `genie__dev_mimo__3ds_impact_on_approval_rate_last_6_month__5`

- **NL question:** 3DS impact on approval rate, last 6 months
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[1r x 3c]: cols=['three_ds_used', 'attempts', 'approval_rate'] head=[['3DS', 1843575, 0.7152169019432353]]`

  | three_ds_used | attempts | approval_rate |
  | --- | --- | --- |
  | 3DS | 1843575 | 0.7152169019432353 |
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
SELECT
    CASE WHEN ThreeDsResponseType IS NULL THEN 'No 3DS' ELSE '3DS' END                    AS three_ds_used,
    COUNT(*)                                                                              AS attempts,
    SUM(CASE WHEN PaymentStatus IN ('Approved','Confirmed','Settled') THEN 1.0 END)
      / NULLIF(COUNT(*), 0)                                                               AS approval_rate
FROM main.etoro_kpi.mimo_tp_deposits_v
WHERE TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -6)
  AND CardType IS NOT NULL
GROUP BY 1
ORDER BY three_ds_used;
```

### `genie__dev_mimo__aft_supported_vs_non_aft_approval_rate_l__4`

- **NL question:** AFT-supported vs non-AFT approval rate, last 6 months
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[2]: [['AFT-Supported', 0.7549259845529367], ['Non-AFT', 0.6405602162128384]]`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
SELECT
    CASE WHEN AFT = 1 THEN 'AFT-Supported' WHEN AFT = 0 THEN 'Non-AFT' ELSE 'Unknown' END  AS aft_bucket,
    SUM(CASE WHEN PaymentStatus IN ('Approved','Confirmed','Settled') THEN 1.0 END)
      / NULLIF(COUNT(*), 0)                                                               AS approval_rate
FROM main.etoro_kpi.mimo_tp_deposits_v
WHERE TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -6)
  AND CardType IS NOT NULL
GROUP BY 1
ORDER BY 1;
```

### `genie__dev_mimo__net_flow_by_region_last_quarter__3`

- **NL question:** Net flow by Region, last quarter
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_emoney_transactions_v`, `main.etoro_kpi.mimo_tp_deposits_v`, `main.etoro_kpi.mimo_tp_withdraws_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[14]: [['UK', 710547639.1], ['Arabic', 513955018.5], ['German', 427718004.93]]`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
WITH mimo AS (
    SELECT MIMOAction, AmountUSD, Region, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_tp_deposits_v
    UNION ALL
    SELECT MIMOAction, AmountUSD, Region, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_tp_withdraws_v
    UNION ALL
    SELECT MIMOAction, AmountUSD, Region, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_emoney_transactions_v
)
SELECT
    Region,
    SUM(CASE WHEN MIMOAction = 'Deposit' THEN AmountUSD ELSE -AmountUSD END) AS net_flow_usd
FROM mimo
WHERE TransactionDate >= ADD_MONTHS(DATE_TRUNC('QUARTER', CURRENT_DATE()), -3)
  AND TransactionDate <  DATE_TRUNC('QUARTER', CURRENT_DATE())
  AND COALESCE(IsInternalTransfer, 0) = 0
GROUP BY Region
ORDER BY net_flow_usd DESC NULLS LAST;
```

### `genie__dev_mimo__rre_share_of_declines_monthly_last_12_mo__6`

- **NL question:** RRE share of declines, monthly, last 12 months
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[13]: [['2025-06-01T00:00:00.000Z', 0.2615376673435], ['2025-07-01T00:00:00.000Z', 0.26962077763482], ['2025-08-01T00:00:00.000Z', 0.27620473727198]]`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
SELECT
    DATE_TRUNC('MONTH', TransactionDate)                                                              AS txn_month,
    SUM(CASE WHEN PaymentStatus = 'DeclineByRRE' THEN 1.0 END)
      / NULLIF(SUM(CASE WHEN PaymentStatus IN ('Decline','Failed','Rejected','DeclineByRRE') THEN 1.0 END), 0) AS rre_share_of_declines
FROM main.etoro_kpi.mimo_tp_deposits_v
WHERE TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -12)
GROUP BY 1
ORDER BY 1;
```

### `genie__dev_mimo__top_10_payment_methods_by_money_in_last___2`

- **NL question:** Top 10 payment methods by Money In, last 3 months
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_emoney_transactions_v`, `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[10]: [['WireTransfer', 911352069.28], ['CreditCard', 864223917.34], ['SEPAinstantTransfer', 269556126.94]]`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
WITH mimo AS (
    SELECT MIMOAction, AmountUSD, MeanOfPayment, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_tp_deposits_v
    UNION ALL
    SELECT MIMOAction, AmountUSD, MeanOfPayment, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_emoney_transactions_v
)
SELECT
    MeanOfPayment,
    SUM(AmountUSD) AS money_in_usd
FROM mimo
WHERE MIMOAction = 'Deposit'
  AND TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -3)
  AND COALESCE(IsInternalTransfer, 0) = 0
GROUP BY MeanOfPayment
ORDER BY money_in_usd DESC NULLS LAST
LIMIT 10;
```

### `genie__dev_mimo__total_fees_and_fx_fees_last_quarter_tp_o__1`

- **NL question:** Total fees and FX fees, last quarter (TP only — eMoney fees are separate rows)
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_deposits_v`, `main.etoro_kpi.mimo_tp_withdraws_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[1]: [[544982114.71, 9020165438.0]]`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
WITH mimo AS (
    SELECT FeeUSD, FXFeeAmount, TransactionDate
    FROM main.etoro_kpi.mimo_tp_deposits_v
    UNION ALL
    SELECT FeeUSD, FXFeeAmount, TransactionDate
    FROM main.etoro_kpi.mimo_tp_withdraws_v
)
SELECT
    SUM(FeeUSD)      AS total_fees_usd,
    SUM(FXFeeAmount) AS total_fx_fees
FROM mimo
WHERE TransactionDate >= ADD_MONTHS(DATE_TRUNC('QUARTER', CURRENT_DATE()), -3)
  AND TransactionDate <  DATE_TRUNC('QUARTER', CURRENT_DATE());
```

### `genie__dev_mimo__tp_deposit_approval_rate_by_psp_last_12___7`

- **NL question:** TP-deposit approval rate by PSP, last 12 months
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[32r x 3c]: cols=['psp', 'attempts', 'approval_rate'] head=[['Tribe', 5653092, 0.9987964108845212]]`

  | psp | attempts | approval_rate |
  | --- | --- | --- |
  | Tribe | 5653092 | 0.9987964108845212 |
  | IXOPAY-Nuvei | 1627636 | 0.6982722181126493 |
  | Checkout | 1469938 | 0.7601361417964567 |
  | WorldPay | 731793 | 0.6749422309314246 |
  | PayPal | 570660 | 0.7501314267690044 |
  _...27 more rows_
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
SELECT
    Provider                                                                              AS psp,
    COUNT(*)                                                                              AS attempts,
    SUM(CASE WHEN PaymentStatus IN ('Approved','Confirmed','Settled') THEN 1.0 END)
      / NULLIF(COUNT(*), 0)                                                               AS approval_rate
FROM main.etoro_kpi.mimo_tp_deposits_v
WHERE TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -12)
GROUP BY Provider
ORDER BY attempts DESC;
```

### `genie__dev_mimo__what_is_the_tp_withdrawal_approval_rate___0`

- **NL question:** What is the TP withdrawal approval rate over the last month?
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_tp_withdraws_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[1r x 3c]: cols=['attempts', 'approved_attempts', 'approval_rate'] head=[[1027265, 999509, 0.9729806817130925]]`

  | attempts | approved_attempts | approval_rate |
  | --- | --- | --- |
  | 1027265 | 999509 | 0.9729806817130925 |
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
SELECT
    COUNT(*)                                                                                            AS attempts,
    SUM(CASE WHEN PaymentStatus = 'Processed' THEN 1 ELSE 0 END)                                         AS approved_attempts,
    SUM(CASE WHEN PaymentStatus IN ('Approved','Confirmed','Settled','Processed') THEN 1.0 END)
      / NULLIF(COUNT(*), 0)                                                                              AS approval_rate
FROM main.etoro_kpi.mimo_tp_withdraws_v
WHERE TransactionDate >= ADD_MONTHS(CURRENT_DATE(), -1);
```

### `genie__dev_mimo__what_was_total_money_in_in_the_last_30_d__8`

- **NL question:** What was total Money In in the last 30 days?
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.etoro_kpi.mimo_emoney_transactions_v`, `main.etoro_kpi.mimo_tp_deposits_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `876,240,314.8300`
- **Notes:** Seeded from Genie space 'DEV - MIMO' (01f15e792ce1140bbf6af2f8f7c6b54c) benchmark question.

```sql
WITH mimo AS (
    SELECT MIMOAction, AmountUSD, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_tp_deposits_v
    UNION ALL
    SELECT MIMOAction, AmountUSD, TransactionDate, IsInternalTransfer
    FROM main.etoro_kpi.mimo_emoney_transactions_v
)
SELECT SUM(AmountUSD) AS money_in_usd
FROM mimo
WHERE MIMOAction = 'Deposit'
  AND TransactionDate >= DATE_SUB(CURRENT_DATE(), 30)
  AND COALESCE(IsInternalTransfer, 0) = 0;
```

### `genie__emoney_adoption_trading__for_the_united_kingdom_consider_only_cus__2`

- **NL question:** For the United Kingdom, consider only customers whose club is NOT Bronze.
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.bi_output.vg_acquisitionfunnel_em1`
- **asof:** 2026-06-08
- **Expected:** `PENDING` = `PENDING`
- **Notes:** Seeded from Genie space 'eMoney Adoption & Trading' (01f0c51e5a4a1506bb34d4751918b4d2) benchmark question.
[pin error] SQL FAILED: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `Country` cannot be resolved. Did you mean one of the follow

```sql
WITH active_tp_mimo AS ( SELECT `CID` FROM `main`.`bi_output`.`vg_acquisitionfunnel_em1` WHERE `Country` = 'United Kingdom' AND `Club` != 'Bronze' AND `IsActiveMIMO` = 1 ), emoney AS ( SELECT `CID` FROM active_tp_mimo WHERE `CID` IN (SELECT `CID` FROM `main`.`bi_output`.`vg_acquisitionfunnel_em1` WHERE `IseMoneyAccount` = 1) ), fmi AS ( SELECT `CID` FROM emoney WHERE `CID` IN (SELECT `CID` FROM `main`.`bi_output`.`vg_acquisitionfunnel_em1` WHERE `IsFMI` = 1) ) SELECT (SELECT COUNT(*) FROM active_tp_mimo) AS active_tp_mimo_customers, (SELECT COUNT(*) FROM emoney) AS emoney_customers, try_divide(100.0 * (SELECT COUNT(*) FROM emoney),NULLIF((SELECT COUNT(*) FROM active_tp_mimo),0)) AS emoney_pct_of_prev, (SELECT COUNT(*) FROM fmi) AS fmi_customers, try_divide(100.0 * (SELECT COUNT(*) FROM fmi),NULLIF((SELECT COUNT(*) FROM emoney),0)) AS fmi_pct_of_prev
```

### `genie__emoney_adoption_trading__in_france_customers_as_of_today__0`

- **NL question:** In France customers (as of today):
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.bi_output.vg_acquisitionfunnel_em1`, `main.bi_output.vg_emoney_panel_firstdates_em1`, `main.bi_output.vg_positionsvolumeandattributes_lc4_source`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[1r x 7c]: cols=['active_mimo_france', 'emoney_opened', 'fmi_done', 'lc_position_opened', 'pct_emoney_opened', 'pct_fmi_done', 'pct_lc_position_opened'] head=[[36176, 29386, 26404, 18583, 81.23, 89.85, 70.38]]`

  | active_mimo_france | emoney_opened | fmi_done | lc_position_opened | pct_emoney_opened | pct_fmi_done | pct_lc_position_opened |
  | --- | --- | --- | --- | --- | --- | --- |
  | 36176 | 29386 | 26404 | 18583 | 81.23 | 89.85 | 70.38 |
- **Notes:** Seeded from Genie space 'eMoney Adoption & Trading' (01f0c51e5a4a1506bb34d4751918b4d2) benchmark question.

```sql
WITH base AS (
  SELECT em1.CID,
         em1.HasEMoneyAccount_as_of_yesterday,
         panel.emoney_fmi_date
  FROM main.bi_output.vg_acquisitionfunnel_em1 em1
  LEFT JOIN main.bi_output.vg_emoney_panel_firstdates_em1 panel ON em1.CID = panel.CID
  WHERE em1.Country_as_of_yesterday = 'France'
    AND em1.IsActiveMIMO_as_of_yesterday = 1
),
open_lc_customers AS (
  SELECT DISTINCT lc4.CID
  FROM main.bi_output.vg_positionsvolumeandattributes_lc4_source lc4
  WHERE lc4.position_event_flag = 'OpenDataFlag'
    AND lc4.num_positions_lc > 0
)
SELECT 
  COUNT(DISTINCT base.CID) AS active_mimo_france,
  COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 THEN base.CID END) AS emoney_opened,
  COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 AND base.emoney_fmi_date IS NOT NULL THEN base.CID END) AS fmi_done,
  COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 AND base.emoney_fmi_date IS NOT NULL AND base.CID IN (SELECT CID FROM open_lc_customers) THEN base.CID END) AS lc_position_opened,
  ROUND(try_divide(100.0 * COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 THEN base.CID END),NULLIF(COUNT(DISTINCT base.CID), 0)), 2) AS pct_emoney_opened,
  ROUND(try_divide(100.0 * COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 AND base.emoney_fmi_date IS NOT NULL THEN base.CID END),NULLIF(COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 THEN base.CID END), 0)), 2) AS pct_fmi_done,
  ROUND(try_divide(100.0 * COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 AND base.emoney_fmi_date IS NOT NULL AND base.CID IN (SELECT CID FROM open_lc_customers) THEN base.CID END),NULLIF(COUNT(DISTINCT CASE WHEN base.HasEMoneyAccount_as_of_yesterday = 1 AND base.emoney_fmi_date IS NOT NULL THEN base.CID END), 0)), 2) AS pct_lc_position_opened
FROM base;
```

### `genie__emoney_adoption_trading__please_show_per_week_monday_start_show_w__1`

- **NL question:** Please show, per week (Monday start, show week start date):
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.bi_output.vg_emoney_panel_firstdates_em1`, `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie`, `main.bi_output.vg_positionsvolumeandattributes_lc4_source`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[45r x 4c]: cols=['cohort_week', 'num_new_fmi_customers', 'total_open_positions_7d_after_fmi', 'avg_open_positions_per_fmi_customer_7d'] head=[['2025-08-04T00:00:00.000Z', 995, 2932, 2.9467336683417087]]`

  | cohort_week | num_new_fmi_customers | total_open_positions_7d_after_fmi | avg_open_positions_per_fmi_customer_7d |
  | --- | --- | --- | --- |
  | 2025-08-04T00:00:00.000Z | 995 | 2932 | 2.9467336683417087 |
  | 2025-08-11T00:00:00.000Z | 1140 | 3314 | 2.907017543859649 |
  | 2025-08-18T00:00:00.000Z | 995 | 2517 | 2.52964824120603 |
  | 2025-08-25T00:00:00.000Z | 1032 | 2833 | 2.74515503875969 |
  | 2025-09-01T00:00:00.000Z | 933 | 2529 | 2.710610932475884 |
  _...40 more rows_
- **Notes:** Seeded from Genie space 'eMoney Adoption & Trading' (01f0c51e5a4a1506bb34d4751918b4d2) benchmark question.

```sql
WITH fmi_fr_customers AS ( SELECT fmi.CID, date_trunc('WEEK', fmi.emoney_fmi_date) AS cohort_week, fmi.emoney_fmi_date FROM main.bi_output.vg_emoney_panel_firstdates_em1 AS fmi INNER JOIN main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie AS snap ON fmi.CID = snap.CID AND CAST(date_format(fmi.emoney_fmi_date, 'yyyyMMdd') AS INT) BETWEEN snap.FromDateID AND snap.ToDateID WHERE snap.Country_FromDate_ToDate = 'France' AND fmi.emoney_fmi_date >= '2025-08-04' AND fmi.emoney_fmi_date IS NOT NULL ), open_positions_7d_after_fmi AS ( SELECT fmi.CID, fmi.cohort_week, SUM(COALESCE(lc4.num_positions_total,0)) AS open_positions_7d FROM fmi_fr_customers AS fmi LEFT JOIN main.bi_output.vg_positionsvolumeandattributes_lc4_source AS lc4 ON fmi.CID = lc4.CID AND lc4.position_event_date BETWEEN CAST(fmi.emoney_fmi_date AS DATE) AND date_add(CAST(fmi.emoney_fmi_date AS DATE), 6) AND lc4.position_event_flag = 'OpenDataFlag' GROUP BY fmi.CID, fmi.cohort_week ) SELECT cohort_week, COUNT(DISTINCT CID) AS num_new_fmi_customers, SUM(open_positions_7d) AS total_open_positions_7d_after_fmi, TRY_DIVIDE(SUM(open_positions_7d), COUNT(DISTINCT CID)) AS avg_open_positions_per_fmi_customer_7d FROM open_positions_7d_after_fmi GROUP BY cohort_week ORDER BY cohort_week ASC
```

### `genie__emoney_adoption_trading__same_for_8_december_2025__3`

- **NL question:** same for 8 december 2025
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.bi_output.vg_positionsvolumeandattributes_lc4_source`
- **asof:** 2026-06-08
- **Expected:** `PENDING` = `PENDING`
- **Notes:** Seeded from Genie space 'eMoney Adoption & Trading' (01f0c51e5a4a1506bb34d4751918b4d2) benchmark question.
[pin error] SQL FAILED: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `Date_` cannot be resolved. Did you mean one of the followin

```sql
SELECT 
  SUM(`num_positions_total`) - SUM(`num_positions_lc`) AS tp_positions_opened, 
  SUM(`num_positions_lc`) AS lc_positions_opened
FROM `main`.`bi_output`.`vg_positionsvolumeandattributes_lc4_source`
WHERE `Date_` = DATE('2025-12-08')
  AND `CountryName` ILIKE '%france%'
  AND `position_event_flag` ILIKE '%OpenDataFlag%'
  AND `Club` ILIKE '%silver%';
```

### `genie__feed_analytics_genie__return_all_know_information_about_the_po__2`

- **NL question:** return all know information about the post 298e5b70-05de-11f1-8080-8000188ddd3b, when was created, how many likes, comments and share it have, who is the post Author, how many read have post?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.experience.bronze_event_hub_prod_event_streaming_we_streams_post`, `main.mixpanel.silver`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[1r x 7c]: cols=['post_id', 'created_at', 'author', 'likes', 'comments', 'shares', 'read_count'] head=[['298e5b70-05de-11f1-8080-8000188ddd3b', '2026-02-09T17:38:36.327Z', 'KubasterG', None, None, None, 14]]`

  | post_id | created_at | author | likes | comments | shares | read_count |
  | --- | --- | --- | --- | --- | --- | --- |
  | 298e5b70-05de-11f1-8080-8000188ddd3b | 2026-02-09T17:38:36.327Z | KubasterG |  |  |  | 14 |
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
WITH post_info AS (
  SELECT
    EventPayloadRowData_Entity_Id AS post_id,
    EventPayloadRowData_Entity_Created AS created_at,
    EventPayloadRowData_Entity_Owner_Username AS author
  FROM
    `main`.`experience`.`bronze_event_hub_prod_event_streaming_we_streams_post`
  WHERE
    EventPayloadRowData_Entity_Id = '298e5b70-05de-11f1-8080-8000188ddd3b'
  LIMIT 1
),
engagement AS (
  SELECT
    post_id_1_2 AS post_id,
    MAX(item_number_of_likes) AS likes,
    MAX(item_number_of_comments) AS comments,
    MAX(item_number_of_shares) AS shares
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    post_id_1_2 = '298e5b70-05de-11f1-8080-8000188ddd3b'
    AND to_date(etr_ymd) >= date_add(DAY, -365, CURRENT_DATE)
  GROUP BY
    post_id_1_2
),
reads AS (
  SELECT
    post_id_1_2 AS post_id,
    COUNT(*) AS read_count
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    post_id_1_2 = '298e5b70-05de-11f1-8080-8000188ddd3b'
    AND mp_event_name = 'Feed - Post Read'
    AND to_date(etr_ymd) >= date_add(DAY, -365, CURRENT_DATE)
  GROUP BY
    post_id_1_2
)
SELECT
  p.post_id,
  p.created_at,
  p.author,
  e.likes,
  e.comments,
  e.shares,
  r.read_count
FROM
  post_info p
    LEFT JOIN engagement e
      ON p.post_id = e.post_id
    LEFT JOIN reads r
      ON p.post_id = r.post_id
```

### `genie__feed_analytics_genie__what_are_the_most_frequently_tagged_asse__3`

- **NL question:** What are the most frequently tagged assets in the feed for created posts?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.experience.bronze_event_hub_prod_event_streaming_we_streams_post`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[50r x 6c]: cols=['symbol', 'asset_id', 'display_name', 'asset_type', 'tag_count', 'unique_posts'] head=[['BTC', 100000, None, 0, 117203, 116807]]`

  | symbol | asset_id | display_name | asset_type | tag_count | unique_posts |
  | --- | --- | --- | --- | --- | --- |
  | BTC | 100000 |  | 0 | 117203 | 116807 |
  | SPX500 | 27 |  | 0 | 112845 | 112389 |
  | NSDQ100 | 28 |  | 0 | 109238 | 108736 |
  | NVDA | 1137 |  | 0 | 59146 | 58839 |
  | ETH | 100001 |  | 0 | 50556 | 50407 |
  _...45 more rows_
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
WITH exploded_tags AS (
  SELECT
    EventPayloadRowData_Entity_Id AS post_id,
    tag.Market.SymbolName AS symbol,
    tag.Market.Id AS asset_id,
    tag.Market.DisplayName AS display_name,
    tag.Market.AssetType AS asset_type
  FROM
    `main`.`experience`.`bronze_event_hub_prod_event_streaming_we_streams_post`
    LATERAL VIEW explode(EventPayloadRowData_Entity_Tags) AS tag
  WHERE
    EventPayloadRowData_OperationType = 'Create'
)
SELECT
  symbol,
  asset_id,
  display_name,
  asset_type,
  COUNT(*) AS tag_count,
  COUNT(DISTINCT post_id) AS unique_posts
FROM
  exploded_tags
WHERE
  symbol IS NOT NULL
GROUP BY
  symbol,
  asset_id,
  display_name,
  asset_type
ORDER BY
  tag_count DESC
LIMIT 50
```

### `genie__feed_analytics_genie__what_is_the_feed_mau_in_the_last_three_m__0`

- **NL question:** What is the Feed MAU in the last three months?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.mixpanel.silver`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[3]: [['2026-06-01T00:00:00.000Z', 438956], ['2026-05-01T00:00:00.000Z', 820536], ['2026-04-01T00:00:00.000Z', 854884]]`
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
SELECT
  date_trunc('MONTH', to_date(`etr_ymd`)) AS month,
  COUNT(DISTINCT `mp_user_id`) AS feed_mau
FROM
  `main`.`mixpanel`.`silver`
WHERE
  `mp_event_name` = 'Feed - View Default Feed'
  AND to_date(`etr_ymd`) >= date_trunc('MONTH', date_add(MONTH, -2, CURRENT_DATE))
  AND to_date(`etr_ymd`) <= CURRENT_DATE
GROUP BY
  date_trunc('MONTH', to_date(`etr_ymd`))
ORDER BY
  month DESC
```

### `genie__feed_analytics_genie__what_tags_are_associated_with_the_post_i__1`

- **NL question:** What tags are associated with the post id '298e5b70-05de-11f1-8080-8000188ddd3b'?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.experience.bronze_event_hub_prod_event_streaming_we_streams_post`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `numeric=NULL`
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
SELECT
  EventPayloadRowData_Entity_Id AS post_id,
  EventPayloadRowData_OperationType AS operation_type,
  tag.Market.SymbolName AS tag_symbol,
  tag.Market.Id AS asset_id,
  tag.Market.DisplayName AS display_name,
  tag.Market.AssetType AS asset_type,
  EventPayloadRowData_Entity_Owner_Username AS username,
  EventPayloadRowData_Entity_Message_Text AS post_text
FROM
  `main`.`experience`.`bronze_event_hub_prod_event_streaming_we_streams_post`
  LATERAL VIEW explode(EventPayloadRowData_Entity_Tags) AS tag
WHERE
  EventPayloadRowData_Entity_Id = '298e5b70-05de-11f1-8080-8000188ddd3b'
```

### `genie__feed_analytics_genie__which_5_posts_among_the_top_200_most_rea__5`

- **NL question:** Which 5 posts among the top 200 most read posts in the last week had the highest conversion rate to trades, including their post owner names?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.mixpanel.silver`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[5r x 5c]: cols=['post_id_1_2', 'post_owner', 'users_read', 'users_traded', 'conversion_rate'] head=[['3bdab0b0-603f-11f1-8080-800120ad4585', 'Suriyasinbox', 3331, 1965, 0.5899129390573401]]`

  | post_id_1_2 | post_owner | users_read | users_traded | conversion_rate |
  | --- | --- | --- | --- | --- |
  | 3bdab0b0-603f-11f1-8080-800120ad4585 | Suriyasinbox | 3331 | 1965 | 0.5899129390573401 |
  | 3a039400-5e00-11f1-8080-80001c9b3715 | Siswfc8101 | 2619 | 1537 | 0.5868652157311951 |
  | 4e691260-60d7-11f1-8080-80011c29d673 | enriqueih | 2815 | 1648 | 0.5854351687388988 |
  | 074b2b40-5ebe-11f1-8080-800176643b61 | anonimus1burn | 2741 | 1599 | 0.5833637358628238 |
  | 59b431f0-6324-11f1-8080-800062e6088a | Kevin_Pando | 2630 | 1532 | 0.5825095057034221 |
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
WITH top_posts AS (
  SELECT
    post_id_1_2,
    post_owner,
    COUNT(DISTINCT mp_user_id) AS users_read
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    mp_event_name = 'Feed - Post Read'
    AND etr_ymd >= CAST(date_add(CURRENT_DATE, -7) AS STRING)
    AND etr_ymd <= CAST(CURRENT_DATE AS STRING)
    AND post_id_1_2 IS NOT NULL
    AND post_owner IS NOT NULL
  GROUP BY
    post_id_1_2,
    post_owner
  ORDER BY
    users_read DESC
  LIMIT 200
),
reads AS (
  SELECT
    post_id_1_2,
    post_owner,
    mp_user_id
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    mp_event_name = 'Feed - Post Read'
    AND etr_ymd >= CAST(date_add(CURRENT_DATE, -7) AS STRING)
    AND etr_ymd <= CAST(CURRENT_DATE AS STRING)
    AND post_id_1_2 IS NOT NULL
    AND post_owner IS NOT NULL
),
trades AS (
  SELECT
    mp_user_id
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    mp_event_name = 'Open Order - Success'
    AND etr_ymd >= CAST(date_add(CURRENT_DATE, -7) AS STRING)
    AND etr_ymd <= CAST(CURRENT_DATE AS STRING)
    AND category_1 = 'Success'
    AND portfolio = 'Real'
    AND mp_user_id IS NOT NULL
)
SELECT
  t.post_id_1_2,
  t.post_owner,
  t.users_read,
  COUNT(DISTINCT r.mp_user_id) AS users_traded,
  (try_divide(COUNT(DISTINCT r.mp_user_id) * 1.0, t.users_read)) AS conversion_rate
FROM
  top_posts t
    JOIN reads r
      ON t.post_id_1_2 = r.post_id_1_2
      AND t.post_owner = r.post_owner
WHERE
  EXISTS (
    SELECT
      1
    FROM
      trades tr
    WHERE
      tr.mp_user_id = r.mp_user_id
  )
GROUP BY
  t.post_id_1_2,
  t.post_owner,
  t.users_read
ORDER BY
  conversion_rate DESC,
  t.users_read DESC
LIMIT 5
```

### `genie__feed_analytics_genie__which_feed_type_has_the_highest_conversi__4`

- **NL question:** Which feed type has the highest conversion rate from feed reads to trades in the last week?
- **Skill hub:** `domain-product-analytics` (coverage: `covered`)
- **Tables:** `main.mixpanel.silver`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[10r x 4c]: cols=['feed_type', 'users_read', 'users_traded', 'conversion_rate'] head=[['language', 12, 8, 0.6666666666666667]]`

  | feed_type | users_read | users_traded | conversion_rate |
  | --- | --- | --- | --- |
  | language | 12 | 8 | 0.6666666666666667 |
  | marketAll | 4561 | 2771 | 0.6075422056566542 |
  | saved | 70 | 40 | 0.5714285714285714 |
  | marketTop | 98008 | 45992 | 0.4692678148722553 |
  | userAll | 1351 | 604 | 0.4470762398223538 |
  _...5 more rows_
- **Notes:** Seeded from Genie space 'Feed Analytics Genie' (01f105b421e7187baa5e81595599f7f3) benchmark question.

```sql
WITH feed_reads AS (
  SELECT
    feed_type,
    mp_user_id
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    mp_event_name = 'Feed - Post Read'
    AND etr_ymd >= CAST(date_add(CURRENT_DATE, -7) AS STRING)
    AND etr_ymd <= CAST(CURRENT_DATE AS STRING)
    AND feed_type IS NOT NULL
    AND mp_user_id IS NOT NULL
),
trades AS (
  SELECT
    mp_user_id
  FROM
    `main`.`mixpanel`.`silver`
  WHERE
    mp_event_name = 'Open Order - Success'
    AND etr_ymd >= CAST(date_add(CURRENT_DATE, -7) AS STRING)
    AND etr_ymd <= CAST(CURRENT_DATE AS STRING)
    AND category_1 = 'Success'
    AND portfolio = 'Real'
    AND mp_user_id IS NOT NULL
)
SELECT
  fr.feed_type,
  COUNT(DISTINCT fr.mp_user_id) AS users_read,
  COUNT(DISTINCT
    CASE
      WHEN t.mp_user_id IS NOT NULL THEN fr.mp_user_id
    END
  ) AS users_traded,
  (
    try_divide(
      COUNT(DISTINCT
        CASE
          WHEN t.mp_user_id IS NOT NULL THEN fr.mp_user_id
        END
      )
        * 1.0,
      COUNT(DISTINCT fr.mp_user_id)
    )
  ) AS conversion_rate
FROM
  feed_reads fr
    LEFT JOIN trades t
      ON fr.mp_user_id = t.mp_user_id
GROUP BY
  fr.feed_type
ORDER BY
  conversion_rate DESC,
  users_read DESC
```

### `genie__ops_documents_verification__are_there_any_documents_with_duplicate_d__7`

- **NL question:** Are there any documents with duplicate document_id values in the bi_output_operations_documentanalysis table?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `numeric=NULL`
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  document_id,
  COUNT(document_id)
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
GROUP BY
  document_id
HAVING
  COUNT(document_id) > 1
```

### `genie__ops_documents_verification__how_many_documents_were_sent_to_vendors___5`

- **NL question:** How many documents were sent to vendors vs not sent in the last 30 days?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[2r x 3c]: cols=['vendor_routing', 'document_count', 'percentage'] head=[['Sent to Vendor', 171835, 50.61]]`

  | vendor_routing | document_count | percentage |
  | --- | --- | --- |
  | Sent to Vendor | 171835 | 50.61 |
  | Not Sent to Vendor | 167704 | 49.39 |
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  CASE
    WHEN vendor IS NOT NULL THEN 'Sent to Vendor'
    ELSE 'Not Sent to Vendor'
  END as vendor_routing,
  COUNT(*) as document_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  upload_date >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY
  vendor_routing
ORDER BY
  document_count DESC
```

### `genie__ops_documents_verification__how_many_poi_and_poa_documents_were_uplo__2`

- **NL question:** How many POI and POA documents were uploaded by EV Verified clients in the last 30 days?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[2r x 3c]: cols=['suggested_document_type', 'document_count', 'unique_clients'] head=[['Proof of Identity', 16366, 7892]]`

  | suggested_document_type | document_count | unique_clients |
  | --- | --- | --- |
  | Proof of Identity | 16366 | 7892 |
  | Proof of address | 3799 | 2475 |
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  suggested_document_type,
  COUNT(*) as document_count,
  COUNT(DISTINCT cid) as unique_clients
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  client_category = 'EVVerifiedUpload'
  AND suggested_document_type IN ('Proof of Identity', 'Proof of address')
  AND upload_date >= CURRENT_DATE - INTERVAL 30 DAYS
GROUP BY
  suggested_document_type
ORDER BY
  document_count DESC
```

### `genie__ops_documents_verification__what_are_the_acceptance_rates_per_docume__1`

- **NL question:** What are the acceptance rates per document type from clients in the United Kingdom between 01-01-2026 and 15-01-2026?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[15r x 4c]: cols=['suggested_document_type', 'total_documents', 'accepted_documents', 'acceptance_rate'] head=[['TaxReport', 1249, 1249, 1.0]]`

  | suggested_document_type | total_documents | accepted_documents | acceptance_rate |
  | --- | --- | --- | --- |
  | TaxReport | 1249 | 1249 | 1.0 |
  | Client Forms | 9 | 9 | 1.0 |
  | Proof of Relation | 8 | 8 | 1.0 |
  | Professional Customer Document | 3 | 3 | 1.0 |
  | W-8BEN Form | 18052 | 18050 | 0.9998892089519167 |
  _...10 more rows_
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  suggested_document_type,
  COUNT(*) AS total_documents,
  SUM(
    CASE
      WHEN is_rejected = 0 THEN 1
      ELSE 0
    END
  ) AS accepted_documents,
  try_divide(
    1.0
    * SUM(
      CASE
        WHEN is_rejected = 0 THEN 1
        ELSE 0
      END
    ),
    COUNT(*)
  ) AS acceptance_rate
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  country = 'United Kingdom'
  AND upload_date >= '2026-01-01'
  AND upload_date < '2026-01-16'
  AND suggested_document_type IS NOT NULL
GROUP BY
  suggested_document_type
ORDER BY
  acceptance_rate DESC
```

### `genie__ops_documents_verification__what_is_the_processing_sla_bucket_distri__4`

- **NL question:** What is the processing SLA bucket distribution for documents in the last 30 days?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[6r x 3c]: cols=['definition_sla_bucket', 'document_count', 'percentage'] head=[['≤ 1 hour', 316596, 93.24]]`

  | definition_sla_bucket | document_count | percentage |
  | --- | --- | --- |
  | ≤ 1 hour | 316596 | 93.24 |
  | 1–4 hours | 9384 | 2.76 |
  | 4–24 hours | 9014 | 2.65 |
  | 1–3 days | 2483 | 0.73 |
  | 4–7 days | 1440 | 0.42 |
  _...1 more rows_
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  definition_sla_bucket,
  COUNT(*) as document_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  upload_date >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY
  definition_sla_bucket
ORDER BY
  document_count DESC
```

### `genie__ops_documents_verification__what_percentage_of_customers_who_submitt__3`

- **NL question:** What percentage of customers who submitted documents from the United Kingdom between 01-01-2026 and 15-01-2026 were EV Verified?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[4r x 4c]: cols=['ev_match_status_name', 'unique_clients', 'total_documents', 'pct_of_clients'] head=[['Verified', 18418, 23765, 87.78]]`

  | ev_match_status_name | unique_clients | total_documents | pct_of_clients |
  | --- | --- | --- | --- |
  | Verified | 18418 | 23765 | 87.78 |
  | NotVerified | 1251 | 3088 | 5.96 |
  | PartiallyVerified | 781 | 2052 | 3.72 |
  | None | 531 | 1230 | 2.53 |
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  ev_match_status_name,
  COUNT(DISTINCT cid) as unique_clients,
  COUNT(*) as total_documents,
  ROUND(COUNT(DISTINCT cid) * 100.0 / SUM(COUNT(DISTINCT cid)) OVER (), 2) as pct_of_clients
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  country = 'United Kingdom'
  AND upload_date >= '2026-01-01 00:00:00'
  AND upload_date < '2026-01-16 00:00:00'
GROUP BY
  ev_match_status_name
ORDER BY
  unique_clients DESC
```

### `genie__ops_documents_verification__what_percentage_of_documents_were_proces__0`

- **NL question:** What percentage of documents were processed automatically vs manually in the last 30 days?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[2r x 3c]: cols=['processing_mode', 'document_count', 'percentage'] head=[['Automatic', 272680, 80.31]]`

  | processing_mode | document_count | percentage |
  | --- | --- | --- |
  | Automatic | 272680 | 80.31 |
  | Manual | 66859 | 19.69 |
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  CASE
    WHEN ManagerID = 0 THEN 'Automatic'
    WHEN ManagerID != 0 THEN 'Manual'
    ELSE 'Unknown'
  END as processing_mode,
  COUNT(*) as document_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  upload_date >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY
  processing_mode
ORDER BY
  document_count DESC
```

### `genie__ops_documents_verification__what_percentage_of_documents_were_proces__6`

- **NL question:** What percentage of documents were processed automatically vs manually?
- **Skill hub:** `domain-ops-and-onboarding` (coverage: `covered`)
- **Tables:** `main.bi_output_stg.bi_output_operations_documentanalysis`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[2r x 3c]: cols=['processing_mode', 'document_count', 'percentage'] head=[['Automatic', 4113543, 78.02]]`

  | processing_mode | document_count | percentage |
  | --- | --- | --- |
  | Automatic | 4113543 | 78.02 |
  | Manual | 1158631 | 21.98 |
- **Notes:** Seeded from Genie space 'OPS  - Documents & Verification' (01f0f77496571e68a9f115149bcc48d9) benchmark question.

```sql
SELECT
  CASE
    WHEN managerid = 0 THEN 'Automatic'
    WHEN managerid != 0 THEN 'Manual'
    ELSE 'Unknown'
  END AS processing_mode,
  COUNT(*) AS document_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM
  main.bi_output_stg.bi_output_operations_documentanalysis
WHERE
  managerid IS NOT NULL
GROUP BY
  processing_mode
ORDER BY
  document_count DESC
```

### `genie__prod_compliance_genie__give_me_a_count_of_all_current_cysec_cli__3`

- **NL question:** give me a count of all current CySEC Clients (RegulationID = 1) that Became VerificationLevel3 during Q4-2025 and openned a CFD Position after Q4-2025
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cidfirstdates_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `10,538.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
SELECT COUNT(DISTINCT c.CID) AS cysec_clients_count
FROM `main`.`etoro_kpi`.`cidfirstdates_v` c
JOIN `main`.`etoro_kpi`.`positions_for_compliance_v` p
  ON c.CID = p.cid
WHERE c.RegulationID = 1
  AND c.VerificationLevel3Date >= '2025-10-01' AND c.VerificationLevel3Date < '2026-01-01'
  AND p.issettled = 0
  AND p.opendateid > 20251231
```

### `genie__prod_compliance_genie__give_me_a_count_of_clients_that_were_in___5`

- **NL question:** Give me a count of clients that were in FCA for the entire of Jan-2026,
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `33,376.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH fca_jan_clients AS (
  SELECT `RealCID`
  FROM `main`.`etoro_kpi`.`customer_snapshot_v`
  WHERE `Regulation` = 'FCA'
    AND `Date` >= '2026-01-01' AND `Date` < '2026-02-01'
  GROUP BY `RealCID`
  HAVING COUNT(DISTINCT `Date`) = 31
)
SELECT COUNT(DISTINCT cs.`RealCID`) AS client_count
FROM `main`.`etoro_kpi`.`customer_snapshot_v` cs
JOIN fca_jan_clients fca ON cs.`RealCID` = fca.`RealCID`
WHERE cs.`IsLastDayMonth` = 1
  AND cs.`CalendarYearMonth` = '2026-01'
  AND cs.`VerificationLevelID` = 3
  AND cs.`ClubTier` = 'Platinum'
```

### `genie__prod_compliance_genie__give_me_clients_in_the_end_of_2025_that___4`

- **NL question:** give me Clients in the end of 2025  that were in Cysec , was not blocked during this time, had V3, and only clubs clients
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`
- **asof:** 2026-06-08
- **Expected:** `tabular` = `tabular[10000r x 6c]: cols=['RealCID', 'GCID', 'ClubTier', 'Regulation', 'VerificationLevelID', 'PlayerLevelID'] head=[[13841101, 14130004, 'Platinum Plus', 'CySEC', 3, 6]]`

  | RealCID | GCID | ClubTier | Regulation | VerificationLevelID | PlayerLevelID |
  | --- | --- | --- | --- | --- | --- |
  | 13841101 | 14130004 | Platinum Plus | CySEC | 3 | 6 |
  | 13831484 | 14120387 | Platinum Plus | CySEC | 3 | 6 |
  | 18071869 | 18360814 | Platinum Plus | CySEC | 3 | 6 |
  | 39738736 | 39914156 | Gold | CySEC | 3 | 3 |
  | 1736252 | 1269048 | Silver | CySEC | 3 | 5 |
  _...9995 more rows_
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
SELECT
  `RealCID`,
  `GCID`,
  `ClubTier`,
  `Regulation`,
  `VerificationLevelID`,
  `PlayerLevelID`
FROM
  `main`.`etoro_kpi`.`customer_snapshot_v`
WHERE
  `IsLastDayYear` = 1
  AND `CalendarYear` = 2025
  AND `Regulation` = 'CySEC'
  AND `PlayerStatusID` NOT IN (2, 4)
  AND `VerificationLevelID` = 3
  AND `PlayerLevelID` IN (2, 5, 6, 7, 3);
```

### `genie__prod_compliance_genie__how_many_trades_openned_on_february_2026__8`

- **NL question:** how many trades openned on february 2026
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `33,912,728.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
SELECT SUM(CASE WHEN coalesce(`IsPartialCloseChild`,0) = 0 THEN 1 ELSE 0 END) AS trades_opened_feb_2026
FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
WHERE `opendateid` BETWEEN 20260201 AND 20260229
  AND `opendateid` IS NOT NULL
```

### `genie__prod_compliance_genie__please_give_me_the_number_of_client_that__6`

- **NL question:** please give me the number of client that are allowed for CFD but didn't trade CFD
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cfd_statusinfo_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `11,226,822.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH cfd_allowed_clients AS (
  SELECT DISTINCT
    RealCID
  FROM
    `main`.`etoro_kpi`.`cfd_statusinfo_v`
  WHERE
    CFD_Status IN ('CFD_Allowed')
),
open_cfd_traders AS (
  SELECT DISTINCT
    cid
  FROM
    `main`.`etoro_kpi`.`positions_for_compliance_v`
  WHERE
    issettled = 0
)
SELECT
  COUNT(*) AS num_clients_allowed_no_trade
FROM
  cfd_allowed_clients cac
    LEFT JOIN open_cfd_traders oct
      ON cac.RealCID = oct.cid
WHERE
  oct.cid IS NULL
```

### `genie__prod_compliance_genie__please_give_me_the_number_of_client_that__7`

- **NL question:** please give me the number of client that are allowed for CFD but didn't trade CFD
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cfd_statusinfo_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `11,226,822.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH cfd_allowed_clients AS (
  SELECT DISTINCT `RealCID`
  FROM `main`.`etoro_kpi`.`cfd_statusinfo_v`
  WHERE `CFD_Status` = 'CFD_Allowed'
),
clients_with_cfd_trades AS (
  SELECT DISTINCT `cid` AS RealCID
  FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
  WHERE `issettled` = 0
)
SELECT COUNT(*) AS num_clients_allowed_no_cfd_trade
FROM cfd_allowed_clients cac
LEFT JOIN clients_with_cfd_trades cwt ON cac.RealCID = cwt.RealCID
WHERE cwt.RealCID IS NULL
```

### `genie__prod_compliance_genie__show_future_volume_of_positions_openned___9`

- **NL question:** Show Future volume of positions openned on february 2026 and the volume of position closed on february 2026
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric_series` = `series[1]: [[187717646, 188167555]]`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
SELECT
  SUM(CASE WHEN `isfuture` = 1 AND `opendateid` BETWEEN 20260201 AND 20260229 AND `volume` IS NOT NULL THEN `volume` ELSE 0 END) AS future_volume_opened_feb_2026,
  SUM(CASE WHEN `isfuture` = 1 AND `closedateid` BETWEEN 20260201 AND 20260229 AND `volumeonclose` IS NOT NULL THEN `volumeonclose` ELSE 0 END) AS future_volume_closed_feb_2026
FROM `main`.`etoro_kpi`.`positions_for_compliance_v`
```

### `genie__prod_compliance_genie__use_opendateid_instead_of_openocurred_yo__1`

- **NL question:** Use OpenDateID instead of openocurred. you are still showing Q4-2025 positions on 2025-12-31
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cidfirstdates_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `10,538.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH cysec_v3_q4_2025 AS (
  SELECT CID
  FROM `main`.`etoro_kpi`.`cidfirstdates_v`
  WHERE RegulationID = 1
    AND VerificationLevel3Date >= '2025-10-01'
    AND VerificationLevel3Date <= '2025-12-31'
),
first_cfd_after_q4_2025 AS (
  SELECT c.CID, MIN(p.opendateid) AS first_cfd_opendateid
  FROM cysec_v3_q4_2025 c
  JOIN `main`.`etoro_kpi`.`positions_for_compliance_v` p
    ON c.CID = p.cid
  WHERE p.issettled = 0
    AND p.opendateid > 20251231
    AND p.opendateid IS NOT NULL
  GROUP BY c.CID
)
SELECT COUNT(*) AS cysec_clients_count
FROM first_cfd_after_q4_2025;
```

### `genie__prod_compliance_genie__whats_the_number_of_cysec_client_that_pr__0`

- **NL question:** whats the number of cysec client that previously answer to Q9 answer '5% / -3%' and than changed the answer to a diffrent one
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cidfirstdates_v`, `main.etoro_kpi.kyc_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `103,750.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH cysec_clients AS (
  SELECT CID
  FROM `main`.`etoro_kpi`.`cidfirstdates_v`
  WHERE RegulationName = 'CySEC'
),
prev_answered AS (
  SELECT DISTINCT k.CID
  FROM `main`.`etoro_kpi`.`kyc_for_compliance_v` k
  INNER JOIN cysec_clients c ON k.CID = c.CID
  WHERE k.QuestionId = 9 AND k.AnswerText = '5% / -3%'
),
changed_answer AS (
  SELECT k.CID
  FROM `main`.`etoro_kpi`.`kyc_for_compliance_v` k
  INNER JOIN prev_answered p ON k.CID = p.CID
  WHERE k.QuestionId = 9 AND k.Is_Current = 1 AND k.AnswerText != '5% / -3%'
)
SELECT COUNT(DISTINCT CID) AS num_cysec_clients_changed_answer
FROM changed_answer;
```

### `genie__prod_compliance_genie__you_are_missing_a_filter_to_find_only_cf__2`

- **NL question:** You are missing a filter to find only CFD position opened after Q4-2025
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.cidfirstdates_v`, `main.etoro_kpi.positions_for_compliance_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `10,538.0000`
- **Notes:** Seeded from Genie space 'PROD - Compliance Genie' (01f137f76a75126fb15b03341732911f) benchmark question.

```sql
WITH cysec_v3_clients AS (
  SELECT CID
  FROM `main`.`etoro_kpi`.`cidfirstdates_v`
  WHERE RegulationID = 1
    AND VerificationLevel3Date >= '2025-10-01'
    AND VerificationLevel3Date < '2026-01-01'
),
clients_with_cfd_after_q4_2025 AS (
  SELECT DISTINCT p.cid
  FROM `main`.`etoro_kpi`.`positions_for_compliance_v` p
  INNER JOIN cysec_v3_clients c ON p.cid = c.CID
  WHERE p.issettled = 0
    AND p.opendateid > 20251231
)
SELECT COUNT(*) AS cysec_v3_clients_with_cfd_after_q4_2025
FROM clients_with_cfd_after_q4_2025;
```

### `genie__prod_ddr__calculate_the_total_revenue_deposits_wit__0`

- **NL question:** Calculate the total revenue, deposits, withdrawals for 2026-04-18
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_mimo_v`, `main.etoro_kpi.ddr_revenue_v`
- **asof:** 2026-06-08
- **Expected:** `PENDING` = `PENDING`
- **Notes:** Seeded from Genie space 'PROD - DDR' (01f13712cf8516878dbc9663f5f73eb7) benchmark question.
[pin error] SQL FAILED: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `GlobalDepositsAmount` cannot be resolved. Did you mean one

```sql
SELECT
  (
    SELECT
      SUM(`RevenueAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_revenue_v`
    WHERE
      `DateID` = 20260418 and IncludedInTotalRevenue = 1
  ) AS TotalRevenue,
  (
    SELECT
      SUM(`GlobalDepositsAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_mimo_v`
    WHERE
      `DateID` = 20260418
  ) AS TotalDeposits,
  (
    SELECT
      SUM(`GlobalWithdrawsAmount`)
    FROM
      `main`.`etoro_kpi`.`ddr_mimo_v`
    WHERE
      `DateID` = 20260418
  ) AS TotalWithdrawals
```

### `genie__prod_ddr__what_was_the_number_of_registrations_in___1`

- **NL question:** What was the number of registrations in the Arabic region from Affiliate ID 72493 in February 2026?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.customer_snapshot_v`, `main.etoro_kpi.vg_customer_customer_first_dates`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `1,670.0000`
- **Notes:** Seeded from Genie space 'PROD - DDR' (01f13712cf8516878dbc9663f5f73eb7) benchmark question.

```sql
WITH reg AS (
  SELECT
    f.RealCID,
    f.RegistrationDate
  FROM
    `main`.`etoro_kpi`.`vg_customer_customer_first_dates` f
  WHERE
    f.RegistrationDate >= '2026-02-01'
    AND f.RegistrationDate < '2026-03-01'
)
SELECT
  COUNT(DISTINCT reg.RealCID) AS num_registrations
FROM
  reg
    JOIN `main`.`etoro_kpi`.`customer_snapshot_v` s
      ON reg.RealCID = s.RealCID
WHERE
  s.Region = 'Arabic'
  AND s.AffiliateID = 72493
  AND s.DateID = 20260228;
```

---
## `known_failure` — 3 cases


### `known_failure__cfd_open_volume_2026_05`

- **NL question:** What was the CFD open volume yesterday?
- **Skill hub:** `domain-trading` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,077,129,043.0000`
- **Notes:** 2026-06-08 routing-failure case. MCP relevance floor (~0.55) silenced the correct domain-trading match (scored 0.514, ranked 3rd). The answer was found and then discarded. CFD = IsSettled=0 across all instrument types (not a specific InstrumentTypeID).

```sql
SELECT SUM(VolumeOpen) AS cfd_open_volume
FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IsSettled = 0
```

### `known_failure__conversion_fee_rollup_2026_05`

- **NL question:** How much conversion fee revenue did eToro book yesterday?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `414,246.3292`
- **Notes:** 2026-06-08 routing-failure case. MCP previously routed to v_revenue_* instead of the DDR fact for rollups. See decisions.md 2026-06-08 'Sub-skill primary anchor contradicts hub fast-path rule'.

```sql
SELECT SUM(Amount) AS conversion_fee
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IncludedInTotalRevenue = 1
  AND Metric = 'ConversionFee'
```

### `known_failure__iban_trading_volume_2026_05`

- **NL question:** What was the total trading volume opened from IBAN yesterday?
- **Skill hub:** `domain-trading` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `83,761,474.0000`
- **Notes:** 2026-06-08 routing-failure case. Embedder name-bias scored the 3-column ETL lookup tables high; correct source is the DDR volume fact filtered on IsOpenedFromIBAN='1' (note: STRING not int per DDL).

```sql
SELECT SUM(VolumeOpen) AS iban_volume_open
FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v
WHERE DateID = CAST(REPLACE('2026-06-08','-','') AS INT)
  AND IsOpenedFromIBAN = '1'
```

---
## `tableau` — 23 cases


### `tableau__194f173d__us_stocks_operations_reports__0`

- **NL question:** Open the 'US Stocks Operations Reports' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=439.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: US Stocks Operations Reports (luid 194f173d-c7df-4741-a087-7e86044808bf) views=439
```

### `tableau__253c9078__us_weekly_operational_insight__0`

- **NL question:** Open the 'US Weekly - Operational Insight' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=268.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: US Weekly - Operational Insight (luid 253c9078-7616-4047-8cc5-b8033375b774) views=268
```

### `tableau__271c3aac__assignment_tool_volumes_outcomes_and_sla__0`

- **NL question:** Open the 'Assignment Tool - Volumes, Outcomes and SLAs' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `251.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=4240.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
-- workbook: Assignment Tool - Volumes, Outcomes and SLAs (luid 271c3aac-bc16-4b44-a700-eb1229cbd5b4) views=4240
```

### `tableau__271c3aac__assignment_tool_volumes_outcomes_and_sla__1`

- **NL question:** Open the 'Assignment Tool - Volumes, Outcomes and SLAs' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=4240.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: Assignment Tool - Volumes, Outcomes and SLAs (luid 271c3aac-bc16-4b44-a700-eb1229cbd5b4) views=4240
```

### `tableau__2df65a2f__capital_guarantee_tactical_edge_cg_2024__0`

- **NL question:** Open the 'Capital Guarantee - Tactical Edge CG 2024 ' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `_none_` (coverage: `missing`)
- **Tables:** `main.bi_db.bronze_fivetran_google_sheets_manually_approved_tactical_edge`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `283.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=571.

```sql
SELECT COUNT(*) AS row_count
FROM main.bi_db.bronze_fivetran_google_sheets_manually_approved_tactical_edge
-- workbook: Capital Guarantee - Tactical Edge CG 2024  (luid 2df65a2f-bb2c-4206-95e2-432220b5666c) views=571
```

### `tableau__2df65a2f__capital_guarantee_tactical_edge_cg_2024__1`

- **NL question:** Open the 'Capital Guarantee - Tactical Edge CG 2024 ' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `_uc_object_map` (coverage: `covered`)
- **Tables:** `main.dwh.dim_position`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,842,943,651.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=571.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.dim_position
-- workbook: Capital Guarantee - Tactical Edge CG 2024  (luid 2df65a2f-bb2c-4206-95e2-432220b5666c) views=571
```

### `tableau__2df65a2f__capital_guarantee_tactical_edge_cg_2024__2`

- **NL question:** Open the 'Capital Guarantee - Tactical Edge CG 2024 ' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-trading` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `11,346,142.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=571.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
-- workbook: Capital Guarantee - Tactical Edge CG 2024  (luid 2df65a2f-bb2c-4206-95e2-432220b5666c) views=571
```

### `tableau__3b6fd241__kyc_dashboard_screening__0`

- **NL question:** Open the 'KYC Dashboard - Screening' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `251.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=436.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
-- workbook: KYC Dashboard - Screening (luid 3b6fd241-82ef-46ef-bcfc-9ab6069028fc) views=436
```

### `tableau__3b6fd241__kyc_dashboard_screening__1`

- **NL question:** Open the 'KYC Dashboard - Screening' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=436.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: KYC Dashboard - Screening (luid 3b6fd241-82ef-46ef-bcfc-9ab6069028fc) views=436
```

### `tableau__5eea8fea__us_msb_regulatory_reports_revenue__0`

- **NL question:** Open the 'US MSB Regulatory Reports (+Revenue)' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `_uc_object_map` (coverage: `covered`)
- **Tables:** `main.dwh.dim_position`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,842,943,651.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=1038.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.dim_position
-- workbook: US MSB Regulatory Reports (+Revenue) (luid 5eea8fea-d486-4fb5-b834-b44e04aebbdd) views=1038
```

### `tableau__78ad56c3__etoro_s_daily_data_report_new_ddr_2026_s__0`

- **NL question:** Open the "eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-moneyfarm` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `18,611,769.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=7.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
-- workbook: eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes) (luid 78ad56c3-ac46-4475-a98c-e867b87479fc) views=7
```

### `tableau__78ad56c3__etoro_s_daily_data_report_new_ddr_2026_s__1`

- **NL question:** Open the "eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `data-latency-and-rollforward` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.v_spaceship_aum`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `756,120,699.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=7.

```sql
SELECT COUNT(*) AS row_count
FROM main.etoro_kpi.v_spaceship_aum
-- workbook: eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes) (luid 78ad56c3-ac46-4475-a98c-e867b87479fc) views=7
```

### `tableau__78ad56c3__etoro_s_daily_data_report_new_ddr_2026_s__2`

- **NL question:** Open the "eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-aum-and-aua` (coverage: `covered`)
- **Tables:** `main.spaceship.bronze_spaceship_analytics_fct_money_transactions`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `7,458,133.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=7.

```sql
SELECT COUNT(*) AS row_count
FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions
-- workbook: eToro's Daily Data Report (New DDR 2026) - Spaceship (Guy Changes) (luid 78ad56c3-ac46-4475-a98c-e867b87479fc) views=7
```

### `tableau__7e942e07__ir_dashboard__0`

- **NL question:** Open the 'IR Dashboard' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=910.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: IR Dashboard (luid 7e942e07-d798-4a43-bcb6-b2dee6f6f5e5) views=910
```

### `tableau__9d8e103d__etoro_s_daily_data_report_ddr__0`

- **NL question:** Open the "eToro's Daily Data Report (DDR)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-moneyfarm` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `18,611,769.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=962.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
-- workbook: eToro's Daily Data Report (DDR) (luid 9d8e103d-c4c7-41ac-9c6f-8b72a81c4e25) views=962
```

### `tableau__9d8e103d__etoro_s_daily_data_report_ddr__1`

- **NL question:** Open the "eToro's Daily Data Report (DDR)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `data-latency-and-rollforward` (coverage: `covered`)
- **Tables:** `main.etoro_kpi.v_spaceship_aum`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `756,120,699.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=962.

```sql
SELECT COUNT(*) AS row_count
FROM main.etoro_kpi.v_spaceship_aum
-- workbook: eToro's Daily Data Report (DDR) (luid 9d8e103d-c4c7-41ac-9c6f-8b72a81c4e25) views=962
```

### `tableau__9d8e103d__etoro_s_daily_data_report_ddr__2`

- **NL question:** Open the "eToro's Daily Data Report (DDR)" dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-aum-and-aua` (coverage: `covered`)
- **Tables:** `main.spaceship.bronze_spaceship_analytics_fct_money_transactions`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `7,458,133.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=962.

```sql
SELECT COUNT(*) AS row_count
FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions
-- workbook: eToro's Daily Data Report (DDR) (luid 9d8e103d-c4c7-41ac-9c6f-8b72a81c4e25) views=962
```

### `tableau__a518016b__capital_guarantee_report__0`

- **NL question:** Open the 'Capital Guarantee Report' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `_uc_object_map` (coverage: `covered`)
- **Tables:** `main.dwh.dim_position`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `2,842,943,651.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=6181.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.dim_position
-- workbook: Capital Guarantee Report (luid a518016b-c5e1-40c6-87cc-babf230a5374) views=6181
```

### `tableau__a518016b__capital_guarantee_report__1`

- **NL question:** Open the 'Capital Guarantee Report' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `251.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=6181.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
-- workbook: Capital Guarantee Report (luid a518016b-c5e1-40c6-87cc-babf230a5374) views=6181
```

### `tableau__a518016b__capital_guarantee_report__2`

- **NL question:** Open the 'Capital Guarantee Report' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=6181.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: Capital Guarantee Report (luid a518016b-c5e1-40c6-87cc-babf230a5374) views=6181
```

### `tableau__e88c5122__kyc_dashboard__0`

- **NL question:** Open the 'KYC Dashboard' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `domain-customer-and-identity` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `251.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=284.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
-- workbook: KYC Dashboard (luid e88c5122-09a6-4011-a257-9c8a3e26b12c) views=284
```

### `tableau__e88c5122__kyc_dashboard__1`

- **NL question:** Open the 'KYC Dashboard' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=284.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: KYC Dashboard (luid e88c5122-09a6-4011-a257-9c8a3e26b12c) views=284
```

### `tableau__ff7e03d3__pi_dashboard__0`

- **NL question:** Open the 'PI Dashboard' dashboard. What does the headline figure (row 1 of the primary view) for 2026-06-08 show?
- **Skill hub:** `valid-users-filter-contract` (coverage: `covered`)
- **Tables:** `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- **asof:** 2026-06-08
- **Expected:** `numeric` = `48,017,773.0000`
- **Notes:** Auto-generated Tableau probe. Rewrite the SQL to match the specific KPI the dashboard renders before pinning. Workbook total_views=1958.

```sql
SELECT COUNT(*) AS row_count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- workbook: PI Dashboard (luid ff7e03d3-965f-4314-bc4c-a9691b013ac7) views=1958
```