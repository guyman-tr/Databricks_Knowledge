# BackOffice.V_CustomerAllTimeAggregatedDat

> Filters the all-time customer aggregation view to only customers with non-zero deposits or significant compensation (>=100), returning their CIDs as a qualifying customer set.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID - one row per qualifying customer |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.V_CustomerAllTimeAggregatedDat` (truncated name - max 128 chars in SQL Server, but the view name was truncated at definition) is a filter view over `BackOffice.CustomerAllTimeAggregatedData` that returns only the CIDs of customers who have meaningful financial activity: those who have made at least one deposit (`TotalDeposit <> 0`) or have received compensation of 100 or more in absolute value (`ABS(TotalCompensation) >= 100`).

This view was created in August 2015 (Case 28653) and serves as a pre-filter to exclude purely synthetic or bonus-only accounts from aggregation processing. The commented-out `INNER JOIN BackOffice.BonusOnlyCustomers` shows an original intent to also exclude bonus-only customers via a separate list, but this was left commented out. The active filter (`TotalDeposit <> 0 OR ABS(TotalCompensation) >= 100`) is the implemented business rule.

The view is consumed by `BackOffice.UpsertIntoAggregationTablesAction` (a stored procedure that refreshes aggregation tables), which uses it to scope which customers need their aggregations updated. With 4.6 million qualifying rows, this is a large population representing the active customer base.

---

## 2. Business Logic

### 2.1 Qualifying Customer Filter

**What**: Identifies customers with real financial activity by filtering out zero-deposit, zero-compensation accounts (e.g., demo-only users, test accounts).

**Columns/Parameters Involved**: `CID`, `TotalDeposit`, `TotalCompensation`

**Rules**:
- `TotalDeposit <> 0`: includes customers who have made any deposit (positive) or received a deposit reversal/refund (negative)
- `ABS(TotalCompensation) >= 100`: includes customers who received or owe significant compensation regardless of whether they deposited
- OR logic: either condition alone qualifies the customer
- Customers with TotalDeposit=0 AND ABS(TotalCompensation) < 100 are excluded (no real financial engagement)
- Commented-out code: original design also filtered to `BackOffice.BonusOnlyCustomers` but this join was never activated

**Diagram**:
```
BackOffice.CustomerAllTimeAggregatedData (all customers)
         |
    WHERE TotalDeposit <> 0
       OR ABS(TotalCompensation) >= 100
         |
         v
BackOffice.V_CustomerAllTimeAggregatedDat
  ~4.6 million qualifying customers
  (excludes demo-only / zero-activity accounts)
```

---

## 3. Data Overview

| CID | Meaning |
|-----|---------|
| (sample values) | Each CID represents a customer who has either made at least one deposit or received/owed >= $100 in compensation. With 4,645,550 rows, this covers the vast majority of financially active eToro accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | VERIFIED | Customer identifier. The only output column - this view returns a set of qualifying CIDs, not full customer details. Used by consuming procedures as a scoping list to identify which customers need aggregation processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, TotalDeposit, TotalCompensation | BackOffice.CustomerAllTimeAggregatedData | Source (filter view) | Base view providing all-time customer financials. Filtered to customers with real financial activity. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertIntoAggregationTablesAction | BackOffice.V_CustomerAllTimeAggregatedDat | READER | Uses this view to scope which customers need aggregation table updates. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.V_CustomerAllTimeAggregatedDat (view)
└── BackOffice.CustomerAllTimeAggregatedData (view)
      └── BackOffice.CustomerAllTimeAggregatedData_1 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | View | FROM clause (alias C) - filtered to qualifying customers (TotalDeposit <> 0 OR ABS(TotalCompensation) >= 100) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTablesAction | Stored Procedure | READER - uses this view as a scoping set for aggregation updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: view name is truncated (`V_CustomerAllTimeAggregatedDat` instead of `V_CustomerAllTimeAggregatedData`) - this is the actual object name in the database. The commented-out INNER JOIN and commented-out `WITH SCHEMABINDING` suggest this view was modified without full refactoring.

---

## 8. Sample Queries

### 8.1 Count qualifying customers

```sql
SELECT COUNT(*) AS QualifyingCustomers
FROM BackOffice.V_CustomerAllTimeAggregatedDat WITH (NOLOCK)
```

### 8.2 Use as a scoping filter for aggregation queries

```sql
SELECT a.CID, a.TotalDeposit, a.TotalProfit
FROM BackOffice.CustomerAllTimeAggregatedData a WITH (NOLOCK)
WHERE a.CID IN (
    SELECT CID FROM BackOffice.V_CustomerAllTimeAggregatedDat WITH (NOLOCK)
)
ORDER BY a.TotalDeposit DESC
```

### 8.3 Check whether a specific customer qualifies

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM BackOffice.V_CustomerAllTimeAggregatedDat WITH (NOLOCK)
    WHERE CID = 123456
) THEN 'Qualifies' ELSE 'Does not qualify' END AS Status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.V_CustomerAllTimeAggregatedDat | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.V_CustomerAllTimeAggregatedDat.sql*
