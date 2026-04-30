# C2F.InsertConversionStatus

> Transitions a conversion to a new status by CorrelationId, with deduplication to prevent duplicate status entries when the status hasn't changed.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: @@rowcount (1=inserted, -1=unchanged) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertConversionStatus transitions a conversion through its lifecycle (Pending -> Completed, Pending -> Failed, etc.). It looks up the conversion by CorrelationId, checks if the new status differs from the current (last) status, and only inserts if different. This prevents duplicate status entries from retry scenarios.

Called by the saga orchestrator when a conversion step completes or fails, to record the business-level outcome.

---

## 2. Business Logic

### 2.1 Dedup-Protected Status Transition

**What**: Only inserts if the new status differs from the last recorded status.

**Columns/Parameters Involved**: `@CorrelationId`, `@StatusId`, `@DetailsJson`

**Rules**:
- Looks up ConversionId from Conversions WHERE CorrelationId = @CorrelationId
- Gets last StatusId from ConversionStatuses ORDER BY Occurred DESC
- If @StatusId != @LastStatus: INSERT and return @@rowcount (1)
- If @StatusId == @LastStatus: return -1 (no insert, idempotent)
- Empty string @DetailsJson is converted to NULL

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Identifies the conversion to transition. Used to look up Conversions.Id. |
| 2 | @StatusId | tinyint | NO | - | VERIFIED | New status. 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). |
| 3 | @DetailsJson | varchar(max) | NO | - | VERIFIED | Optional JSON details (error messages for failures). Empty string converted to NULL before insert. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | C2F.Conversions | SELECT (lookup) | Finds ConversionId by CorrelationId |
| - | C2F.ConversionStatuses | SELECT + INSERT | Reads last status, inserts new if different |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.InsertConversionStatus (procedure)
├── C2F.Conversions (table)
└── C2F.ConversionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | SELECT - lookup by CorrelationId |
| C2F.ConversionStatuses | Table | SELECT + INSERT - read last status, write new |

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

### 8.1 Transition to Completed
```sql
EXEC C2F.InsertConversionStatus @CorrelationId = 'BD637018-99FC-40AD-A466-773D7274F16C', @StatusId = 3, @DetailsJson = ''
```

### 8.2 Transition to Failed with error details
```sql
EXEC C2F.InsertConversionStatus @CorrelationId = '844A7D04-0A19-496C-BC77-9ECA04795E66', @StatusId = 2, @DetailsJson = '{"ErrorMessage":"Crypto Transaction Failed"}'
```

### 8.3 Verify latest status
```sql
SELECT TOP 1 cs.StatusId, ds.Name, cs.DetailsJson, cs.Occurred
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK) ON ds.Id = cs.StatusId
INNER JOIN C2F.Conversions c WITH (NOLOCK) ON c.Id = cs.ConversionId
WHERE c.CorrelationId = @CorrelationId
ORDER BY cs.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.InsertConversionStatus | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.InsertConversionStatus.sql*
