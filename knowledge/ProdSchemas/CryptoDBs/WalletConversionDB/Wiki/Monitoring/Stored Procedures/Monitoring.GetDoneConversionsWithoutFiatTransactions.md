# Monitoring.GetDoneConversionsWithoutFiatTransactions

> Pipeline integrity check that finds conversions marked as Completed but missing their fiat transaction record, indicating the fiat credit step may have failed silently.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Completed conversions missing FiatTransactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetDoneConversionsWithoutFiatTransactions detects a critical data inconsistency: conversions that are marked as Completed (StatusId=3) but don't have a corresponding FiatTransactions record. For IbanAccount and EtoroPlatform targets (TargetPlatformId IN 1,2), a completed conversion MUST have a fiat transaction - its absence means fiat was never credited despite the status saying "done."

This is a critical alert - customers may believe their conversion succeeded while fiat was never delivered.

---

## 2. Business Logic

### 2.1 Missing Fiat Transaction Detection

**What**: Finds completed C2F conversions (not C2P) with no FiatTransactions row.

**Columns/Parameters Involved**: `@TimeFrameInMinutes`

**Rules**:
- INNER JOIN ConversionStatuses WHERE StatusId=3 (Completed)
- Filter: TargetPlatformId IN (1, 2) - only IbanAccount and EtoroPlatform (C2P/position conversions don't necessarily need a fiat tx)
- LEFT JOIN FiatTransactions WHERE ft.Id IS NULL (missing)
- Time window: DATEDIFF(minute, cs.Occurred, GETUTCDATE()) < @TimeFrameInMinutes
- Default: 60 minutes

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | NO | 60 | VERIFIED | Time window for detection. Only conversions completed within this window are checked. Default 60 minutes. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | ConversionId | bigint | VERIFIED | Conversion ID that is Completed but missing fiat tx |
| 2 | StatusId | int | VERIFIED | Always 3 (Completed) due to the filter |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.ConversionStatuses | INNER JOIN | Status filter (Completed) |
| - | C2F.Conversions | INNER JOIN | Platform filter |
| - | C2F.FiatTransactions | LEFT JOIN | Missing record detection |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetDoneConversionsWithoutFiatTransactions (procedure)
├── C2F.ConversionStatuses (table)
├── C2F.Conversions (table)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.ConversionStatuses | Table | INNER JOIN - Completed status filter |
| C2F.Conversions | Table | INNER JOIN - platform filter |
| C2F.FiatTransactions | Table | LEFT JOIN - missing detection |

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

### 8.1 Check for missing fiat transactions (last hour)
```sql
EXEC Monitoring.GetDoneConversionsWithoutFiatTransactions
```

### 8.2 Check wider window
```sql
EXEC Monitoring.GetDoneConversionsWithoutFiatTransactions @TimeFrameInMinutes = 1440
```

### 8.3 Direct check query
```sql
SELECT cs.ConversionId, c.CorrelationId, cs.Occurred AS CompletedAt
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN C2F.Conversions c WITH (NOLOCK) ON cs.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON cs.ConversionId = ft.ConversionId
WHERE cs.StatusId = 3 AND c.TargetPlatformId IN (1, 2) AND ft.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetDoneConversionsWithoutFiatTransactions | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetDoneConversionsWithoutFiatTransactions.sql*
