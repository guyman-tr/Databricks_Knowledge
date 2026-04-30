# Billing.DD_CheckPCIRotationOldFundings

> DataDog monitoring check that alerts when any PCI DSS encryption key rotation record has been pending (unprocessed) for more than 24 hours, indicating a stalled key rotation job.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_CheckPCIRotationOldFundings` is a DataDog synthetic monitor procedure. It checks whether any records in `Billing.KeyRotation` have been waiting to be processed for more than 24 hours. A "pending" `KeyRotation` record (`IsProcessed=0`) that is older than 24 hours indicates the PCI encryption key rotation job has stalled.

`Billing.KeyRotation` is a staging table used during PCI DSS compliance-driven encryption key rotations of credit card data in `Billing.Funding`. During a rotation, credit card records are staged here and processed (re-encrypted) in batches. Under normal operation, staged records are processed within minutes to hours. A record sitting unprocessed for more than 24 hours is a critical signal: either the rotation job has crashed, been interrupted, or has encountered an error that requires DBA intervention.

The `value=1` alert triggers immediate attention because a prolonged rotation has compliance and operational implications: the old encryption key remains in use, leaving a window of exposure, and the rotation cannot be completed or rolled back safely until the stall is resolved.

---

## 2. Business Logic

### 2.1 Stalled PCI Rotation Detection

**What**: Detects rotation records that have been in an unprocessed state beyond the expected processing SLA (24 hours).

**Columns/Parameters Involved**: `Billing.KeyRotation.IsProcessed`, `Billing.KeyRotation.Created`

**Rules**:
- No parameters - the 24-hour threshold is hardcoded
- Alert condition: at least 1 row with `IsProcessed=0` AND `Created < DATEADD(HH, -24, GETUTCDATE())`
- `value=1` fires on the first stalled record - any unprocessed record older than 24h is enough to alert
- This complements `DD_CheckPCIRotationUnProcessedFundings` (which monitors backlog SIZE >= 3000), not overlap: one detects TIME-based stalls, the other detects VOLUME-based backlog buildup

**Diagram**:
```
Billing.KeyRotation WHERE IsProcessed=0
          |
    CREATED > 24 hours ago?
          |
    +-----+-----+
    |             |
  COUNT = 0   COUNT >= 1
    |             |
  value=0      value=1  <-- Alert: rotation job stalled
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result: 1 = at least one KeyRotation record is unprocessed and was created more than 24 hours ago (rotation stalled); 0 = no stalled records. When alerting, the DBA team should investigate the PCI key rotation job status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsProcessed, Created filter | Billing.KeyRotation | Read | Reads KeyRotation to check for unprocessed records older than 24 hours. See [Billing.KeyRotation](../Tables/Billing.KeyRotation.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_CheckPCIRotationOldFundings (procedure)
└── Billing.KeyRotation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | Direct read with NOLOCK; counts unprocessed records older than 24 hours to detect stalled PCI rotation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to detect stalled PCI key rotation jobs |

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
EXEC Billing.DD_CheckPCIRotationOldFundings;
```

### 8.2 Investigate stalled rotation records if the monitor fires

```sql
SELECT FundingID,
       IsProcessed,
       Created,
       DATEDIFF(HOUR, Created, GETUTCDATE()) AS HoursOld
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 0
  AND Created < DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY Created ASC;
```

### 8.3 Check the full rotation backlog status (both stalled and recent)

```sql
SELECT IsProcessed,
       COUNT(*) AS RecordCount,
       MIN(Created) AS OldestRecord,
       MAX(Created) AS NewestRecord
FROM Billing.KeyRotation WITH (NOLOCK)
GROUP BY IsProcessed;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_CheckPCIRotationOldFundings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_CheckPCIRotationOldFundings.sql*
