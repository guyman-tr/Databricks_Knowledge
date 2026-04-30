# Monitoring.GetConversionStatusesWithoutConversion

> Data integrity check that finds orphaned ConversionStatuses records with no matching Conversions row, indicating potential data inconsistency in the conversion pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Orphaned status records (StatusId, ConversionId) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetConversionStatusesWithoutConversion is a data integrity monitoring procedure that detects orphaned records in ConversionStatuses - status entries whose ConversionId doesn't match any row in Conversions. This should never happen in normal operations (the FK constraint prevents it), but could occur from manual data corrections, failed migrations, or constraint violations.

Used by automated health checks to detect data consistency issues.

---

## 2. Business Logic

### 2.1 Orphan Detection via LEFT JOIN

**What**: Finds ConversionStatuses rows with no matching Conversions row.

**Columns/Parameters Involved**: `@TimeFrameInMinutes`

**Rules**:
- LEFT JOIN ConversionStatuses to Conversions ON ConversionId = Id
- WHERE c.Id IS NULL (orphaned) AND recent (within @TimeFrameInMinutes)
- Default time frame: 60 minutes
- Note: The WHERE clause references c.Occurred on a NULL join, which would always be NULL - this may be a bug (the time filter is ineffective for true orphans)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | NO | 60 | VERIFIED | Time window for recent orphan detection. Default 60 minutes. Note: the time filter references Conversions.Occurred which is NULL for orphans, making it potentially ineffective. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | StatusId | int | VERIFIED | Status of the orphaned record |
| 2 | ConversionId | bigint | VERIFIED | ConversionId that doesn't exist in Conversions |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.ConversionStatuses | SELECT (FROM) | Source of potentially orphaned records |
| - | C2F.Conversions | LEFT JOIN | Existence check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetConversionStatusesWithoutConversion (procedure)
├── C2F.ConversionStatuses (table)
└── C2F.Conversions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.ConversionStatuses | Table | FROM - source records |
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

### 8.1 Check for orphaned statuses (last hour)
```sql
EXEC Monitoring.GetConversionStatusesWithoutConversion
```

### 8.2 Check with wider window
```sql
EXEC Monitoring.GetConversionStatusesWithoutConversion @TimeFrameInMinutes = 1440
```

### 8.3 Direct orphan check
```sql
SELECT cs.ConversionId, cs.StatusId
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
LEFT JOIN C2F.Conversions c WITH (NOLOCK) ON cs.ConversionId = c.Id
WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetConversionStatusesWithoutConversion | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetConversionStatusesWithoutConversion.sql*
