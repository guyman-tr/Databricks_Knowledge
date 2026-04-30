# Billing.GetCashflowBrakedown

> Returns a customer's all-time financial summary — total deposits, withdrawals, compensations, bonuses, and withdrawal fees — by joining the pre-aggregated BackOffice summary with the detailed withdrawal table. (Note: "Brakedown" is a legacy typo for "Breakdown".)

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCashflowBrakedown` (note: legacy typo in the name - should be "Breakdown") provides a financial summary dashboard for a single customer: total lifetime deposits, total withdrawals, total compensations, total bonuses, and the aggregate fee paid on withdrawals. This is the primary API endpoint for the Payment History API's cashflow summary feature, created in July 2014 by idanfe.

The procedure uses a hybrid approach: aggregated deposit/withdrawal/compensation/bonus totals come from `BackOffice.CustomerAllTimeAggregatedData` (a pre-computed summary table), while withdrawal fees are computed on-the-fly by summing `Billing.Withdraw.Fee` across all the customer's withdrawal records. This avoids storing a redundant FeeTotal in the aggregated table while keeping the main aggregations fast.

The GROUP BY is necessary because the JOIN with Billing.Withdraw produces multiple rows (one per withdrawal record), and SUM(Fee) aggregates them all back into a single row per customer. The result is always one row per CID when the customer has any withdrawals.

---

## 2. Business Logic

### 2.1 Hybrid Aggregation Pattern

**What**: Combines a pre-computed all-time summary table with an on-demand fee aggregation from the raw withdrawal table.

**Columns/Parameters Involved**: `TotalDeposit`, `TotalCashout`, `TotalCompensation`, `TotalBonus`, `Billing.Withdraw.Fee`

**Rules**:
- `TotalDeposit`, `TotalCashout`, `TotalCompensation`, `TotalBonus` come from `BackOffice.CustomerAllTimeAggregatedData` - these are pre-computed and updated asynchronously, not recalculated here
- `PaymentsTotalFee = SUM(BWIT.Fee)` is the only live aggregation - sums all withdrawal fees from Billing.Withdraw
- The JOIN on `CATA.CID = BWIT.CID` with GROUP BY means: if a customer has 0 withdrawal records in Billing.Withdraw, the query returns 0 rows (the INNER JOIN eliminates them)
- `TotalCashout` is aliased as `TotalWithdrawals` in the output - business terminology prefers "Withdrawals" over "Cashout"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to retrieve the financial summary for. Filters both BackOffice.CustomerAllTimeAggregatedData and Billing.Withdraw. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalDeposit | (money/decimal) | YES | - | CODE-BACKED | All-time total deposit amount for the customer. Sourced from BackOffice.CustomerAllTimeAggregatedData.TotalDeposit (pre-aggregated). |
| 2 | TotalWithdrawals | (money/decimal) | YES | - | CODE-BACKED | All-time total withdrawal (cashout) amount. Sourced from BackOffice.CustomerAllTimeAggregatedData.TotalCashout, aliased as TotalWithdrawals. |
| 3 | TotalCompensation | (money/decimal) | YES | - | CODE-BACKED | All-time total compensation credits received. Sourced from BackOffice.CustomerAllTimeAggregatedData.TotalCompensation (pre-aggregated). |
| 4 | TotalBonus | (money/decimal) | YES | - | CODE-BACKED | All-time total bonus credits received. Sourced from BackOffice.CustomerAllTimeAggregatedData.TotalBonus (pre-aggregated). |
| 5 | PaymentsTotalFee | money | YES | - | VERIFIED | Sum of all withdrawal fees from Billing.Withdraw.Fee for this customer. The only live-computed aggregate - summed across all withdrawal records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TotalDeposit/TotalCashout/TotalCompensation/TotalBonus | BackOffice.CustomerAllTimeAggregatedData | Read (cross-schema) | Pre-aggregated all-time financial summary per customer. INNER JOIN with Billing.Withdraw on CID. |
| PaymentsTotalFee | Billing.Withdraw | Read | Joins to aggregate total withdrawal fees (SUM(Fee)) across all customer withdrawals. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (role) | EXECUTE permission | Permission | BI admin users call this as part of the Payment History API cashflow summary. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCashflowBrakedown (procedure)
├── BackOffice.CustomerAllTimeAggregatedData (table, cross-schema)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | Pre-aggregated financial totals. INNER JOIN with Billing.Withdraw. Provides TotalDeposit, TotalCashout, TotalCompensation, TotalBonus. |
| Billing.Withdraw | Table | SUM(Fee) to compute total withdrawal fees. INNER JOIN with BackOffice table on CID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (role) | Permission | Payment History API cashflow summary |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get financial summary for a customer
```sql
EXEC Billing.GetCashflowBrakedown @CID = 12345
-- Returns: TotalDeposit, TotalWithdrawals, TotalCompensation, TotalBonus, PaymentsTotalFee
```

### 8.2 Direct query replicating the SP logic
```sql
SELECT CATA.TotalDeposit,
       CATA.TotalCashout AS TotalWithdrawals,
       CATA.TotalCompensation,
       CATA.TotalBonus,
       SUM(BWIT.Fee) AS PaymentsTotalFee
FROM BackOffice.CustomerAllTimeAggregatedData CATA WITH (NOLOCK)
JOIN Billing.Withdraw BWIT WITH (NOLOCK) ON CATA.CID = BWIT.CID
WHERE BWIT.CID = 12345
GROUP BY CATA.TotalDeposit, CATA.TotalCashout, CATA.TotalCompensation, CATA.TotalBonus
```

### 8.3 Get deposit and withdrawal comparison for a customer
```sql
SELECT CATA.TotalDeposit,
       CATA.TotalCashout AS TotalWithdrawals,
       CATA.TotalDeposit - CATA.TotalCashout AS NetFundingBalance,
       SUM(BWIT.Fee) AS TotalWithdrawalFees
FROM BackOffice.CustomerAllTimeAggregatedData CATA WITH (NOLOCK)
JOIN Billing.Withdraw BWIT WITH (NOLOCK) ON CATA.CID = BWIT.CID
WHERE BWIT.CID = 12345
GROUP BY CATA.TotalDeposit, CATA.TotalCashout
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCashflowBrakedown | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCashflowBrakedown.sql*
