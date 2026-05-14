---
id: mimo
name: "MIMO (Money In / Money Out)"
description: "Deposit and withdrawal transactions across all platforms (Trading Platform, eMoney, Options, MoneyFarm). Covers transaction amounts in USD, FTD flags (global vs platform-level), net deposits, funding types, and C2USD crypto conversions. Single fact table with ~91.5M rows."
triggers:
  - deposits
  - withdrawals
  - money in
  - money out
  - FTD
  - first time deposit
  - net deposits
  - funding
  - cashout
  - MIMO
  - payment method
  - platform deposits
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-07"
---

# MIMO (Money In / Money Out)

## When to Use
- "how much was deposited?", "total deposits this quarter"
- "how many FTDs?", "first deposit count", "new depositors"
- "net deposits", "deposits minus withdrawals"
- "deposits by platform", "how much on eMoney?"
- Any question about deposit/withdrawal amounts, FTD flags, funding types, or platform-level money flow

## Scope
In scope: Deposit/withdrawal transactions, FTD flags (global + platform), net deposits, platform breakdown, funding types, C2USD conversions
Out of scope: Withdrawal/conversion *fees* (→ `revenue` skill), funnel analysis reg→FTD (→ `registration-to-ftd-funnel` skill)
Last verified: 2026-05-07

## Critical Warnings
1. SUM(AmountUSD) without filtering `MIMOAction` mixes deposits and withdrawals — produces meaningless total.
2. Using `IsPlatformFTD = 1` for global FTD count gives platform-level results — use `IsGlobalFTD = 1` instead.
3. Withdrawals can be negative — use `ABS()` when summing withdrawal amounts.
4. MoneyFarm rows have sentinel values: `AmountOrigCurrency = -1`, `FundingTypeID = -1` — filter or handle explicitly.
5. Table has ~91.5M rows — always filter by `etr_ymd` (or `etr_ym`/`etr_y`) for partition pruning.

---

## Table

`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`
- **Grain**: 1 row per transaction. ~91.5M rows. Partitions: `etr_y`, `etr_ym`, `etr_ymd`.

---

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **Deposit** | Real money a customer sends INTO eToro. `MIMOAction = 'Deposit'` | money in, funding, top-up |
| **Withdraw** | Real money a customer takes OUT. `MIMOAction = 'Withdraw'` | money out, cashout, withdrawal |
| **FTD** | The very first successful deposit ever. One-time lifecycle event. | first time deposit, first deposit |
| **Global FTD** | First deposit across ALL platforms. `IsGlobalFTD = 1` | cross-platform FTD |
| **Platform FTD** | First deposit on a SPECIFIC platform. `IsPlatformFTD = 1` | TP FTD, IBAN FTD |
| **Net Deposit** | Deposits minus Withdrawals. Positive = net inflow. | net funding, net money flow |
| **Funding Type** | Payment method identifier (`FundingTypeID`). | payment method, MOP |
| **C2USD** | Crypto-to-fiat conversion deposit (`FundingTypeID = 27`). Flagged via `IsCryptoToFiat = 1`. | crypto conversion |

Platforms: `TradingPlatform`, `eMoney`, `Options`, `MoneyFarm`

---

## Query Patterns

### Pattern 1 — Total deposits
```sql
SELECT SUM(AmountUSD) AS total_deposits
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE MIMOAction = 'Deposit' AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how much was deposited?", "total deposits this quarter", "money in"

### Pattern 2 — Global FTD count and amount
```sql
SELECT COUNT(DISTINCT RealCID) AS ftd_count, SUM(AmountUSD) AS ftd_amount
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE IsGlobalFTD = 1 AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how many FTDs?", "first deposit count", "new depositors"

### Pattern 3 — Net deposits
```sql
SELECT SUM(CASE WHEN MIMOAction='Deposit' THEN AmountUSD ELSE -ABS(AmountUSD) END) AS net
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "net deposits", "deposits minus withdrawals", "net money flow"

### Pattern 4 — Deposits by platform
```sql
SELECT MIMOPlatform, SUM(AmountUSD) AS deposits
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE MIMOAction = 'Deposit' AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY MIMOPlatform;
```
**Use when:** "deposits by platform", "how much on eMoney?", "TP vs IBAN deposits"
