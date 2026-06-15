---
description: "Source-of-truth metric definitions for the Spaceship Weekly KPI Dashboard — validated against Matt's Excel master and the weekly PDF reports. Covers: (1) FTD definition — Money EXCLUDED (Money is a cash wallet, not an investment); overall Spaceship FTD = LEAST(super_first_became_financial_date, voyager_first_became_financial_date, nova_first_transaction_at converted to Sydney); per-product FTDs use the product-specific date column. Three FTD gotchas: Super T+2 backdating shifts first_became_financial_date retroactively (10-20% overcount for last 1-2 weeks); v_spaceship_mimo.is_ftd derives from first external deposit and INCLUDES Money, so it overcounts vs the definition; transaction-derived FTD runs 5-15% higher than user_beta fields. (2) F30DD — sum of deposits within 30 days of FTD date; total Spaceship F30DD sums across ALL products within 30d of overall_ftd_date; per-product F30DD uses each product's OWN FTD date with type='Contributions' OR description='Contributions Tax' for Super, order_direction='BUY' for Voyager/Nova. (3) Funded Accounts — unique users with balance>0 in ANY product (Super, Voyager, Nova, OR Money); Sunday snapshot (DAYOFWEEK=1); per-product uses balance_aud > 0; result in thousands (funded_k). (4) FUM — sum of all balances across Super + Voyager + Nova + Money, Sunday snapshot, expressed in $m; Money is a separate filterable product line. (5) Net Deposits — post 2025-03-10 = Super + Customer Money (excludes internal product transfers); pre 2025-03-10 = Super + Voyager + Nova. Super: type='Contributions' OR description='Contributions Tax' for inflows; type IN ('Benefit Payment','Fees','Tax') AND description<>'Contributions Tax' for outflows. Money: USER_DEPOSIT family for inflows; USER_WITHDRAWAL + NOVA fees for outflows (Customer Money EXCLUDES VOYAGER_PURCHASE etc. internal transfers). Voyager Net Deposits: net_aud_transacted with Portfolio split (UNIVERSE vs Other) and Cohort split (aud_balance_prev >= 25000 vs <25k). (6) Registrations — COUNT(*) on signed_up_at_date grouped by week; week-ending Sunday. Validation results for week 2026-03-22: Funded Accounts ±1.1%, FUM exact match, Registrations exact, FTDs exact for stable weeks (20-30% high for backdating weeks Feb 1/8/15)."
triggers:
  - FTD definition
  - Spaceship FTD
  - F30DD definition
  - first 30 day deposits
  - overall_ftd_date
  - Money excluded FTD
  - T+2 backdating
  - super_first_became_financial_date backdating
  - v_spaceship_mimo is_ftd overcounts
  - Funded Accounts definition
  - FUM definition
  - Net Deposits definition
  - Spaceship Net Deposits Super + Money
  - Customer Money net
  - VOYAGER_PURCHASE excluded
  - Voyager UNIVERSE portfolio
  - 25k cohort threshold
  - Spaceship Registrations
  - signed_up_at_date
  - SPS PDF report
  - Matt's Excel
  - weekly Spaceship reporting
  - validation week 2026-03-22
sample_questions:
  - What is the canonical definition of a Spaceship FTD
  - How is Customer Money Net Deposits defined (which transaction_types qualify)
  - Why does v_spaceship_mimo.is_ftd overcount vs the dashboard
  - How are per-product F30DD computed differently from total Spaceship F30DD
  - What's the Voyager Net Deposits cohort split threshold
required_tables:
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_super_transactions
  - main.spaceship.bronze_spaceship_metabase_voyager_transactions
  - main.spaceship.bronze_spaceship_metabase_nova_transactions
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.spaceship.spaceship_metabase_voyager_user_balances
  - main.spaceship.spaceship_metabase_voyager_product_balances
  - main.etoro_kpi_prep.v_spaceship_mimo
---

# Spaceship Metric Definitions

Source of truth: **Matt's Excel file** at `/Workspace/Users/guyman@etoro.com/spaceship/sps reports from matt.xlsx`
Validated against: Weekly "Spaceship Reporting Metrics" PDF reports.

## FTDs (First-Time Deposits)

**PDF Glossary**: "A customer who makes a first investment into Spaceship (**Money excluded**). Does NOT include Repeat."

### Total Spaceship FTDs
Earliest date across Super/Voyager/Nova (Money excluded):
```
overall_ftd_date = LEAST(
  super_first_became_financial_date,
  voyager_first_became_financial_date,
  nova_first_transaction_at  -- converted to Sydney timezone
)
```
Count unique users grouped by `overall_ftd_date` week.

### Per-Product FTDs (from user_beta)
- **Super**: `COUNT(*) GROUP BY super_first_became_financial_date`
- **Voyager**: `COUNT(*) GROUP BY voyager_first_became_financial_date`
- **Nova**: `COUNT(*) GROUP BY CAST(FROM_UTC_TIMESTAMP(nova_first_transaction_at, 'Australia/Sydney') AS DATE)`

### FTD Gotchas
- **Money excluded** from FTD definition (it's a cash wallet, not an investment product)
- **Super backdating**: T+2 settlement causes `first_became_financial_date` to shift retroactively. Expect 10-20% overcounting for the most recent 1-2 weeks vs a PDF snapshot
- **Do NOT use MIMO-based FTD**: The `v_spaceship_mimo.is_ftd` field derives from first external deposit (includes Money) → overcounts
- **Do NOT use transaction-derived FTD**: Computing first transaction date from raw tables runs 5-15% higher than user_beta fields

## F30DD (First 30-Day Deposits)

Sum of deposits within 30 days of the user's FTD date.

### Total Spaceship F30DD
Sum deposits across **ALL products** (Super + Voyager + Nova) within 30 days of `overall_ftd_date`:
- Super: `SUM(aud_amount)` WHERE `type='Contributions' OR description='Contributions Tax'`
- Voyager: `SUM(unit_aud_amount)` WHERE `order_direction='BUY'`
- Nova: `SUM(order_aud_amount)` WHERE `order_direction='BUY'`

### Per-Product F30DD
Each product uses its OWN FTD date (not the overall):
- **Super F30DD**: `SUM(super_transactions.aud_amount)` WHERE `(type='Contributions' OR description='Contributions Tax')` AND `paid_date BETWEEN super_ftd_date AND super_ftd_date + 29`
- **Voyager F30DD**: `SUM(voyager_transactions.unit_aud_amount)` WHERE `order_direction='BUY'` AND `effective_date BETWEEN voyager_ftd_date AND voyager_ftd_date + 29`
- **Nova F30DD**: `SUM(nova_transactions.order_aud_amount)` WHERE `order_direction='BUY'` AND `order_filled_at (Sydney) BETWEEN nova_ftd_date AND nova_ftd_date + 29`

## Funded Accounts

**Definition**: Count of unique users with balance > 0 in ANY product (Super, Voyager, Nova, or Money).

- Snapshot on **Sundays** (`DAYOFWEEK(date) = 1`)
- Per-product: `SUM(CASE WHEN {product}_balance_aud > 0 THEN 1 ELSE 0 END)`
- Spaceship total: Any user with balance > 0 in any product (including Money)
- Result expressed in thousands (funded_k)

## FUM (Funds Under Management)

**Definition**: Sum of all balances across Super + Voyager + Nova + Money.

- Snapshot on **Sundays**
- Per-product: `ROUND(SUM({product}_balance_aud) / 1e6, 0)` → expressed in $m
- Spaceship total: Super + Voyager + Nova + Money
- Money shown as separate product line (can be filtered in/out on dashboard)

### AUM Data Sources
| Product | Balance Table | Weekend Coverage |
|---------|--------------|-----------------|
| Super | `super_user_balances.balance_aud` | Weekday-only (fill-forward needed) |
| Voyager | `voyager_user_balances.aud_balance` | Weekday-only (fill-forward needed) |
| Nova | `nova_user_balances.aud_balance` | 7-day (but only ~7 days retained) |
| Money | Running SUM from `fct_money_transactions` | Derived (any day) |

## Net Deposits

### Spaceship Total Net Deposits
**Post March 10, 2025**: Super Net Deposits + **Customer** Money Net Deposits
**Pre March 10, 2025**: Super Net Deposits + Voyager + Nova

### Super Net Deposits
Source: `bronze_spaceship_metabase_super_transactions` (use `paid_date`, exclude '2024-05-18')

| Flow | Filter |
|------|--------|
| **Inflows** | `type = 'Contributions'` OR `description = 'Contributions Tax'` |
| **Outflows** | `type IN ('Benefit Payment', 'Fees', 'Tax')` AND `description <> 'Contributions Tax'` |
| **Net** | `type IN ('Benefit Payment', 'Contributions', 'Fees', 'Tax')` → SUM(aud_amount) |

### Voyager Net Deposits
Source: `spaceship_metabase_voyager_user_balances`

| Column | Meaning |
|--------|---------|
| `inflow_aud_amount` | Inflows |
| `outflow_aud_amount` | Outflows (negative values) |
| `net_aud_transacted` | Net deposits |

### Money Customer Net Deposits
Source: `bronze_spaceship_analytics_fct_money_transactions`
Filter: `status NOT IN ('CANCELLED','FAILED','REJECTED')`

**Customer** transactions only (excludes internal product transfers):

| Flow | Transaction Types |
|------|-------------------|
| **Inflows** | `USER_DEPOSIT`, `USER_DEPOSIT_REVERSAL`, `NOVA_DIVIDEND`, `NOVA_MERGER_ACQUISITIONS` |
| **Outflows** | `USER_WITHDRAWAL`, `USER_WITHDRAWAL_REVERSAL`, `NOVA_TAF_FEE`, `NOVA_REG_FEE`, `NOVA_MONTHLY_FEE` |
| **Net** | All 8 above + `USER_WITHDRAWAL` + `USER_WITHDRAWAL_REVERSAL` |

⚠️ "Customer" Money ≠ all Money. Internal types (VOYAGER_PURCHASE, NOVA_PURCHASE, etc.) are excluded from Net Deposits.

## Registrations

Source: `bronze_spaceship_metabase_user_beta.signed_up_at_date`
- Weekly count: `COUNT(*) GROUP BY DATE_TRUNC('WEEK', signed_up_at_date)`
- Week-ending = Sunday: `DATE_TRUNC('WEEK', signed_up_at_date) + INTERVAL 6 DAYS`
- Rolling 90 days: `WHERE signed_up_at_date >= DATE_ADD(CURRENT_DATE(), -90)`

## Voyager Net Deposits Breakdowns

### Portfolio Split
Source: `spaceship_metabase_voyager_product_balances`
- **Universe**: `WHERE portfolio = 'UNIVERSE'`
- **Other Portfolios**: All other portfolios combined
- Metric: `SUM(net_aud_transacted)`

### Cohort Split
Source: `spaceship_metabase_voyager_user_balances`
- **25k+**: `WHERE aud_balance_prev >= 25000`
- **<25k**: `WHERE aud_balance_prev < 25000`
- Metric: `SUM(net_aud_transacted)`

## Validation Results (Week Ending 22 March 2026)

| Metric | PDF | Ours | Delta | Notes |
|--------|-----|------|-------|-------|
| Funded Accounts | 180.8k | 182.8k | +1.1% | Includes 13K recovered Super users |
| FUM Total | $1,723m | $1,723.1m | +0.006% | Exact match |
| Registrations | 917 | 917 | 0% | Perfect match |
| Spaceship FTDs | 242 | 242 | 0% | Exact for stable weeks |
| Spaceship F30DD | $0.1m | $0.09m | ~0% | Rounding |
| Super FTDs | 124 | 124 | 0% | Exact |
| Voyager FTDs | 118 | 118 | 0% | Exact |

### Backdating Weeks (Feb 1, Feb 8, Feb 15)
FTDs run 20-30% high due to Super T+2 settlement retroactively updating FTD dates. The PDF itself notes: "*Super data may change over the preceding weeks with some transaction backdating.*"

### Stable Weeks (Jan 4, Jan 18, Jan 25, Mar 8, Mar 15, Mar 22)
FTDs match within 0-5%. These weeks are far enough in the past that backdating has settled.
