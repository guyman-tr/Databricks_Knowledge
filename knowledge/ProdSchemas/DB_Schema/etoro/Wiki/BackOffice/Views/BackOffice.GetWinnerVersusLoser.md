# BackOffice.GetWinnerVersusLoser

> Returns a two-row platform-wide split of customers into "Winner" (positive all-time profit) vs "Loser" (zero or negative all-time profit) with percentage share.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | Profitability - always exactly 2 rows |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetWinnerVersusLoser` is a platform-level profitability summary that classifies all customers in `BackOffice.CustomerAllTimeAggregatedData` into two groups: **Winners** (customers whose all-time `TotalProfit > 0`) and **Losers** (customers whose all-time `TotalProfit <= 0`). It returns the percentage of all customers in each group.

This view answers a key business and regulatory question: "What proportion of eToro customers are profitable over their entire trading history?" The live data reveals that only 0.1% of customers show positive all-time profit (Winners) while 99.9% show zero or negative profit (Losers). This type of statistic is often required for regulatory disclosures about CFD trading risk.

The view always returns exactly 2 rows. It reads `BackOffice.CustomerAllTimeAggregatedData` (the view that aggregates cumulative trading performance per customer) and applies `SIGN(TotalProfit)` to classify each customer.

---

## 2. Business Logic

### 2.1 Winner vs Loser Classification

**What**: Classifies every customer with an all-time performance record into profitable (Winner) or unprofitable/break-even (Loser).

**Columns/Parameters Involved**: `Profitability`, `Percentage`

**Rules**:
- `SIGN(TotalProfit) = 1` -> `'Winner'` (TotalProfit is strictly positive)
- `SIGN(TotalProfit) = 0 or -1` -> `'Loser'` (TotalProfit is zero or negative; break-even is classified as Loser)
- Percentage = `COUNT(*) in group / total CustomerAllTimeAggregatedData rows * 100`, rounded to 2 decimal places
- Result is always 2 rows (one per category)
- Live data: Winner=0.10%, Loser=99.90% - consistent with industry-wide CFD trading profitability statistics

**Diagram**:
```
BackOffice.CustomerAllTimeAggregatedData (one row per customer)
         |
    SIGN(TotalProfit)
      = 1  ->  'Winner'   (TotalProfit > 0)
      = 0  ->  'Loser'    (TotalProfit = 0, break-even)
      = -1 ->  'Loser'    (TotalProfit < 0)
         |
    GROUP BY category
    COUNT(*) / total * 100

Result (live data):
  Winner:  0.10%
  Loser:  99.90%
```

---

## 3. Data Overview

| Profitability | Percentage | Meaning |
|---------------|------------|---------|
| Winner | 0.10 | Only 0.10% of all customers in the all-time aggregation have a positive total profit - a strikingly small fraction, consistent with the well-documented difficulty of profitable retail CFD trading |
| Loser | 99.90 | 99.90% of customers show zero or negative all-time profit. This includes break-even customers (TotalProfit=0) who are classified as Losers by the SIGN() function |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Profitability | VARCHAR (computed) | NO | - | VERIFIED | Customer profitability classification. Always one of two values: `'Winner'` (SIGN(TotalProfit)=1, meaning TotalProfit is strictly positive) or `'Loser'` (SIGN(TotalProfit)=0 or -1, meaning TotalProfit is zero or negative). Break-even customers are classified as Loser. |
| 2 | Percentage | FLOAT (computed) | YES | - | VERIFIED | Percentage of all customers in `BackOffice.CustomerAllTimeAggregatedData` that fall into this Profitability category. Formula: `ROUND(COUNT(*) / total_count * 100, 2)`. Rounded to 2 decimal places. The two rows sum to 100%. Live values: Winner=0.10%, Loser=99.90%. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TotalProfit | BackOffice.CustomerAllTimeAggregatedData | Source (same schema) | All customers' all-time profit aggregation. TotalProfit is used both for the Winner/Loser classification and as the denominator for percentage calculation. |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWinnerVersusLoser (view)
└── BackOffice.CustomerAllTimeAggregatedData (view)
      └── BackOffice.CustomerAllTimeAggregatedData_1 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | View | FROM clause (no alias) - both as source for the GROUP BY classification and as subquery for the total count denominator |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: `SIGN()` returns 1 (positive), 0 (zero), or -1 (negative). The CASE only matches `WHEN 1`, so both 0 and -1 fall into 'Loser' - break-even customers are classified as losing.

---

## 8. Sample Queries

### 8.1 Get the current winner/loser split

```sql
SELECT Profitability, Percentage
FROM BackOffice.GetWinnerVersusLoser WITH (NOLOCK)
ORDER BY Percentage DESC
```

### 8.2 Check whether winner percentage exceeds 1%

```sql
SELECT Profitability, Percentage
FROM BackOffice.GetWinnerVersusLoser WITH (NOLOCK)
WHERE Profitability = 'Winner'
  AND Percentage > 1.0
```

### 8.3 Compare winner count to total customer count

```sql
SELECT w.Profitability, w.Percentage,
       CAST(w.Percentage / 100.0 * (SELECT COUNT(*) FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)) AS INT) AS EstimatedCount
FROM BackOffice.GetWinnerVersusLoser w WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWinnerVersusLoser | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetWinnerVersusLoser.sql*
