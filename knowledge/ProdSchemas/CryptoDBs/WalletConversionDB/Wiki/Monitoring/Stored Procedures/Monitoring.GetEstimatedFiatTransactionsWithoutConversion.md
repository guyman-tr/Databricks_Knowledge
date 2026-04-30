# Monitoring.GetEstimatedFiatTransactionsWithoutConversion

> Data integrity check that finds orphaned EstimatedFiatTransactions records with no matching Conversions row.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Orphaned estimated fiat transaction ConversionIds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetEstimatedFiatTransactionsWithoutConversion detects orphaned records in EstimatedFiatTransactions - estimated amounts whose ConversionId doesn't match any Conversions row. Since InsertConversion creates both atomically in a transaction, orphans should be impossible. Their presence would indicate a data corruption issue.

---

## 2. Business Logic

### 2.1 Orphan Detection

**What**: LEFT JOIN + IS NULL pattern to find EstimatedFiatTransactions without parent Conversions.

**Columns/Parameters Involved**: `@TimeFrameInMinutes`

**Rules**:
- LEFT JOIN EstimatedFiatTransactions to Conversions ON ConversionId = Id
- WHERE c.Id IS NULL (orphaned)
- Same time filter caveat as GetConversionStatusesWithoutConversion (references NULL c.Occurred)
- Default: 60 minutes

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | NO | 60 | VERIFIED | Time window. Default 60 minutes. Same NULL-reference caveat as GetConversionStatusesWithoutConversion. |

**Return:** ConversionId (bigint) - orphaned conversion IDs.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.EstimatedFiatTransactions | SELECT (FROM) | Source records |
| - | C2F.Conversions | LEFT JOIN | Existence check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetEstimatedFiatTransactionsWithoutConversion (procedure)
├── C2F.EstimatedFiatTransactions (table)
└── C2F.Conversions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.EstimatedFiatTransactions | Table | FROM - source records |
| C2F.Conversions | Table | LEFT JOIN - existence check |

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

### 8.1 Check for orphaned estimates
```sql
EXEC Monitoring.GetEstimatedFiatTransactionsWithoutConversion
```

### 8.2 Direct orphan check
```sql
SELECT eft.ConversionId FROM C2F.EstimatedFiatTransactions eft WITH (NOLOCK)
LEFT JOIN C2F.Conversions c WITH (NOLOCK) ON eft.ConversionId = c.Id WHERE c.Id IS NULL
```

### 8.3 Count orphans
```sql
SELECT COUNT(*) FROM C2F.EstimatedFiatTransactions eft WITH (NOLOCK)
LEFT JOIN C2F.Conversions c WITH (NOLOCK) ON eft.ConversionId = c.Id WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetEstimatedFiatTransactionsWithoutConversion | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetEstimatedFiatTransactionsWithoutConversion.sql*
