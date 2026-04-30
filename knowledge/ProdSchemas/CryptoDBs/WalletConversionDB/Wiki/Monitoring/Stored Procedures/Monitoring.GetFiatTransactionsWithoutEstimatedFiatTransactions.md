# Monitoring.GetFiatTransactionsWithoutEstimatedFiatTransactions

> Data integrity check that finds FiatTransactions with no corresponding EstimatedFiatTransactions record, indicating the estimate was missing when fiat was credited.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: FiatTransactions missing estimates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFiatTransactionsWithoutEstimatedFiatTransactions detects fiat transactions that don't have a corresponding estimated fiat transaction. Since InsertConversion creates both atomically, this should not happen. Presence indicates a data integrity issue - either the conversion was created through an alternative path, or the estimated record was deleted.

---

## 2. Business Logic

### 2.1 Missing Estimate Detection

**What**: LEFT JOIN + IS NULL pattern to find FiatTransactions without matching estimates.

**Columns/Parameters Involved**: `@TimeFrameInMinutes`

**Rules**:
- LEFT JOIN FiatTransactions to EstimatedFiatTransactions ON ConversionId
- WHERE eft.UsdAmount IS NULL (no estimate exists)
- Time filter on ft.Occurred within @TimeFrameInMinutes (default 60)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | NO | 60 | VERIFIED | Time window. Default 60 minutes. |

**Return Columns:** ConversionId, UsdAmount, Occurred (from FiatTransactions).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.FiatTransactions | SELECT (FROM) | Source records |
| - | C2F.EstimatedFiatTransactions | LEFT JOIN | Missing record detection |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetFiatTransactionsWithoutEstimatedFiatTransactions (procedure)
├── C2F.FiatTransactions (table)
└── C2F.EstimatedFiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.FiatTransactions | Table | FROM - source records |
| C2F.EstimatedFiatTransactions | Table | LEFT JOIN - existence check |

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

### 8.1 Check for missing estimates
```sql
EXEC Monitoring.GetFiatTransactionsWithoutEstimatedFiatTransactions
```

### 8.2 Direct check
```sql
SELECT ft.ConversionId, ft.UsdAmount FROM C2F.FiatTransactions ft WITH (NOLOCK)
LEFT JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON ft.ConversionId = eft.ConversionId
WHERE eft.Id IS NULL
```

### 8.3 Count missing
```sql
SELECT COUNT(*) FROM C2F.FiatTransactions ft WITH (NOLOCK)
LEFT JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON ft.ConversionId = eft.ConversionId
WHERE eft.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetFiatTransactionsWithoutEstimatedFiatTransactions | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetFiatTransactionsWithoutEstimatedFiatTransactions.sql*
