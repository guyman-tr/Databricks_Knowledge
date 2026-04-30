# Billing.DD_CheckPCIRotationUnProcessedFundings

> DataDog monitoring check that alerts when the PCI DSS encryption key rotation backlog (unprocessed records in Billing.KeyRotation) reaches or exceeds 3,000 records, indicating the rotation job is falling behind.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_CheckPCIRotationUnProcessedFundings` is a DataDog synthetic monitor procedure. It counts ALL unprocessed records (`IsProcessed=0`) in `Billing.KeyRotation` regardless of age, and fires an alert if the count reaches 3,000. This is a volume-based backlog monitor - it detects when the PCI encryption key rotation job is processing records more slowly than they are being staged.

`Billing.KeyRotation` is populated by `Billing.GetKeyRotationFundings`, which stages credit card records for re-encryption in batches. That procedure itself enforces a hard-coded safety limit of 3,000 unprocessed records: it will refuse to stage more batches if the backlog already exceeds 3,000. This monitor checks the same threshold from the opposite direction - alerting DataDog when the backlog has reached the safety limit, meaning the staging job has been paused or the processing job is not keeping up.

Unlike `DD_CheckPCIRotationOldFundings` (which checks if any individual record is time-stalled), this procedure is about overall volume: even if no individual record is old, a growing backlog of 3,000+ means the system is at capacity and the rotation may be indefinitely paused until the processor catches up.

---

## 2. Business Logic

### 2.1 Rotation Backlog Volume Check

**What**: Compares total unprocessed KeyRotation record count against the 3,000-record safety ceiling defined in the rotation infrastructure.

**Columns/Parameters Involved**: `Billing.KeyRotation.IsProcessed`

**Rules**:
- No parameters - the 3,000 threshold is hardcoded to match `GetKeyRotationFundings` safety limit
- Alert condition: COUNT of all IsProcessed=0 rows >= 3,000
- When firing, the rotation staging job has been paused (will not add more records until backlog clears)
- Complementary to `DD_CheckPCIRotationOldFundings`: together they provide both TIME-based (stall) and VOLUME-based (backlog) visibility
- Under normal rotation conditions the table is empty (0 rows) - any non-zero count indicates an active rotation

**Diagram**:
```
COUNT * FROM Billing.KeyRotation WHERE IsProcessed=0
          |
    COUNT >= 3000?
          |
    +-----+-----+
    |             |
  value=0      value=1  <-- Alert: backlog at capacity
                         Staging paused. Processing job
                         must clear records before staging resumes.
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result: 1 = the PCI rotation backlog has reached or exceeded 3,000 unprocessed records (staging paused); 0 = backlog is below threshold or the table is empty (no active rotation). Alert signals that processing must catch up before new batches can be staged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsProcessed filter | Billing.KeyRotation | Read | Reads KeyRotation to count total unprocessed records. See [Billing.KeyRotation](../Tables/Billing.KeyRotation.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_CheckPCIRotationUnProcessedFundings (procedure)
└── Billing.KeyRotation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | Direct count with NOLOCK; counts all IsProcessed=0 rows to measure rotation backlog size |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to monitor PCI rotation backlog volume |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the DataDog check

```sql
EXEC Billing.DD_CheckPCIRotationUnProcessedFundings;
```

### 8.2 Check current backlog size and oldest record

```sql
SELECT COUNT(*) AS TotalUnprocessed,
       MIN(Created) AS OldestUnprocessed,
       MAX(Created) AS NewestUnprocessed
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 0;
```

### 8.3 Monitor rotation progress (processed vs. unprocessed split)

```sql
SELECT IsProcessed,
       COUNT(*) AS RecordCount,
       MIN(Created) AS OldestRecord,
       MAX(Created) AS NewestRecord,
       DATEDIFF(HOUR, MIN(Created), GETUTCDATE()) AS OldestAgeHours
FROM Billing.KeyRotation WITH (NOLOCK)
GROUP BY IsProcessed
ORDER BY IsProcessed;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_CheckPCIRotationUnProcessedFundings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_CheckPCIRotationUnProcessedFundings.sql*
