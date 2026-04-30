# C2F.GetConversionAmounts

> Retrieves conversion amounts (actual and estimated USD) for a customer's active/completed conversions within a time window, supporting limit calculations and conversion history display.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Conversion IDs with actual and estimated USD amounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetConversionAmounts retrieves conversion amounts for a specific customer within a time window, filtering for active conversions (Pending or Completed status only). It returns both the actual USD amount (from FiatTransactions, if available) and the estimated USD amount (from EstimatedFiatTransactions), enabling the caller to use whichever is more appropriate - actual for completed conversions, estimated for in-progress ones.

Used for regulatory limit enforcement and conversion history display.

---

## 2. Business Logic

### 2.1 Active Conversion Filter with Paginated Results

**What**: Returns TOP @MaxConversions active conversions for a customer, with time window and ID-based pagination.

**Columns/Parameters Involved**: `@Gcid`, `@FromDateTime`, `@FromId`, `@MaxConversions`

**Rules**:
- Filters: Gcid = @Gcid AND Occurred > @FromDateTime AND Id >= @FromId
- Status filter: StatusId IN (1, 3) - Pending or Completed only (excludes Failed/Rejected)
- Uses most-recent-status pattern: `cs.Id = (SELECT TOP 1 cs2.Id ... ORDER BY cs2.Id DESC)`
- INNER JOINs ConversionStatuses and EstimatedFiatTransactions (required)
- LEFT JOINs FiatTransactions (NULL if not yet completed)
- Returns ft.UsdAmount (actual) and eft.UsdAmount (estimated) separately
- Ordered by c.Id ASC with TOP (@MaxConversions) for pagination

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID to filter conversions for. |
| 2 | @FromDateTime | datetime2 | NO | - | VERIFIED | Time window start. Only conversions after this timestamp are returned. |
| 3 | @FromId | bigint | NO | - | VERIFIED | ID-based pagination cursor. Only conversions with Id >= this value are returned. |
| 4 | @MaxConversions | int | NO | - | VERIFIED | Maximum number of conversions to return. Caps the result set. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | Conversion ID |
| 2 | UsdAmount | decimal | VERIFIED | Actual USD amount from FiatTransactions (NULL if not yet completed) |
| 3 | EstimatedUsdAmount | decimal | VERIFIED | Estimated USD amount from EstimatedFiatTransactions (always present) |
| 4 | StatusId | int | VERIFIED | Current conversion status (1=Pending or 3=Completed) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Primary table, filtered by Gcid and time |
| - | C2F.ConversionStatuses | SELECT (INNER JOIN) | Status filter for active conversions |
| - | C2F.EstimatedFiatTransactions | SELECT (INNER JOIN) | Estimated USD amounts |
| - | C2F.FiatTransactions | SELECT (LEFT JOIN) | Actual USD amounts (when available) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.GetConversionAmounts (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
├── C2F.EstimatedFiatTransactions (table)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - filtered by Gcid, time, Id |
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

### 8.1 Get conversion amounts for a customer
```sql
EXEC C2F.GetConversionAmounts @Gcid = 31036842, @FromDateTime = '2026-01-01', @FromId = 0, @MaxConversions = 100
```

### 8.2 Equivalent direct query
```sql
SELECT TOP 100 c.Id, ft.UsdAmount, eft.UsdAmount AS EstimatedUsdAmount, cs.StatusId
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON cs.ConversionId = c.Id
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON eft.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
WHERE c.Gcid = 31036842 AND c.Occurred > '2026-01-01'
AND cs.StatusId IN (1, 3)
AND cs.Id = (SELECT TOP 1 cs2.Id FROM C2F.ConversionStatuses cs2 WITH (NOLOCK) WHERE cs.ConversionId = cs2.ConversionId ORDER BY cs2.Id DESC)
ORDER BY c.Id ASC
```

### 8.3 Customer conversion total
```sql
SELECT COUNT(*) AS TotalConversions
FROM C2F.Conversions WITH (NOLOCK)
WHERE Gcid = 31036842
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.GetConversionAmounts | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.GetConversionAmounts.sql*
