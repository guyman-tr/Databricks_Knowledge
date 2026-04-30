# C2F.GetConversionsUsdSum

> Calculates the total USD value of active conversions for a customer within a time window, using actual fiat amounts when available and falling back to estimates for in-progress conversions.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: UsdSum (decimal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetConversionsUsdSum calculates the total USD value of a customer's active (Pending or Completed) conversions within a time window. This is a regulatory limit calculation procedure - used to determine if a customer has exceeded their conversion threshold. It uses the "best available" amount pattern: actual FiatTransactions.UsdAmount for completed conversions, falling back to EstimatedFiatTransactions.UsdAmount for in-progress ones.

Called before new conversions to validate against customer limits.

---

## 2. Business Logic

### 2.1 Best-Available USD Amount Aggregation

**What**: SUMs USD amounts using actual when available, estimated as fallback.

**Columns/Parameters Involved**: `@Gcid`, `@FromDateTime`, FiatTransactions.UsdAmount, EstimatedFiatTransactions.UsdAmount

**Rules**:
- CASE WHEN ft.UsdAmount IS NULL THEN eft.UsdAmount ELSE ft.UsdAmount END
- Filters: Gcid = @Gcid AND Occurred > @FromDateTime
- Status filter: StatusId IN (1, 3) - Pending or Completed (same as GetConversionAmounts)
- Uses most-recent-status correlated subquery pattern
- Returns single scalar: UsdSum

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID. Filters conversions for this customer. |
| 2 | @FromDateTime | datetime2 | NO | - | VERIFIED | Time window start. Only conversions after this timestamp are included in the sum. Typically set to the rolling limit window (e.g., last 24 hours, last 30 days). |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | UsdSum | decimal | VERIFIED | Total USD value of active conversions. Uses actual amounts when available, estimated otherwise. NULL if no conversions in window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Filtered by Gcid and time |
| - | C2F.ConversionStatuses | SELECT (INNER JOIN) | Status filter for active conversions |
| - | C2F.EstimatedFiatTransactions | SELECT (INNER JOIN) | Fallback USD amounts |
| - | C2F.FiatTransactions | SELECT (LEFT JOIN) | Preferred actual USD amounts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.GetConversionsUsdSum (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
├── C2F.EstimatedFiatTransactions (table)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - filtered by Gcid and time |
| C2F.ConversionStatuses | Table | INNER JOIN - status filter |
| C2F.EstimatedFiatTransactions | Table | INNER JOIN - estimated amounts |
| C2F.FiatTransactions | Table | LEFT JOIN - actual amounts |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get USD sum for a customer (last 30 days)
```sql
EXEC C2F.GetConversionsUsdSum @Gcid = 31036842, @FromDateTime = DATEADD(DAY, -30, GETUTCDATE())
```

### 8.2 Get USD sum for a customer (last 24 hours)
```sql
EXEC C2F.GetConversionsUsdSum @Gcid = 31036842, @FromDateTime = DATEADD(HOUR, -24, GETUTCDATE())
```

### 8.3 Equivalent direct query
```sql
SELECT SUM(CASE WHEN ft.UsdAmount IS NULL THEN eft.UsdAmount ELSE ft.UsdAmount END) AS UsdSum
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON cs.ConversionId = c.Id
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON eft.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
WHERE c.Gcid = 31036842 AND c.Occurred > DATEADD(DAY, -30, GETUTCDATE())
AND cs.StatusId IN (1, 3)
AND cs.Id = (SELECT TOP 1 cs2.Id FROM C2F.ConversionStatuses cs2 WITH (NOLOCK) WHERE cs.ConversionId = cs2.ConversionId ORDER BY cs2.Id DESC)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.GetConversionsUsdSum | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.GetConversionsUsdSum.sql*
