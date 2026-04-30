# Dictionary.IndexDividenedStatus

> Lookup table defining six index dividend processing states — tracking the lifecycle of index dividend calculations from initial processing through snapshot creation to completion or invalidation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (TINYINT, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.IndexDividenedStatus defines the processing states for index dividend operations. When an index constituent pays a dividend, the index level adjusts, and eToro must compensate customers holding index CFD positions. The dividend processing workflow moves through several stages: initial queuing, active processing, snapshot capture, and final completion or invalidation.

This table exists because index dividend processing is a multi-step, time-sensitive operation. Unlike stock dividends (which are straightforward per-share payments), index dividends require calculating the index-level impact, snapshotting all affected positions, computing per-position adjustments, and applying them. Each stage must be tracked to handle failures, retries, and audit requirements.

The StatusID is consumed by Monitor.CheckDividendsStatus, a monitoring procedure that checks for stuck or failed dividend processing jobs. Note: the table name contains a legacy typo ("Dividened" instead of "Dividend").

---

## 2. Business Logic

### 2.1 Dividend Processing Lifecycle

**What**: Six states track the dividend processing workflow from queuing to completion.

**Columns/Parameters Involved**: `StatusID`, `Name`

**Rules**:
- **Not been processed yet (0)**: Initial state. The dividend event has been recorded but the processing job has not started. Could be queued for next processing cycle.
- **Started (1)**: The dividend processing job is actively running — calculating adjustments, identifying affected positions.
- **Completed (2)**: Terminal success. All dividend adjustments have been calculated and applied to customer accounts.
- **Snapshot Is Being Taken (3)**: The system is capturing a point-in-time snapshot of all affected positions. This snapshot is critical for accurate dividend calculation — positions must not change during this window.
- **Snapshot Is Ready (4)**: The snapshot has been captured successfully. The system can now calculate per-position dividend adjustments using the frozen snapshot data.
- **Invalid (5)**: Terminal failure. The dividend processing failed validation — the data is inconsistent and the job cannot continue. Requires manual investigation and potential re-trigger.

**Diagram**:
```
Index Dividend Processing:
  ┌─────────────────────────┐
  │ Not processed yet (0)   │ ← Queued
  └───────────┬─────────────┘
              │ start
              ▼
  ┌─────────────────────────┐
  │ Started (1)             │ ← Calculating
  └───────────┬─────────────┘
              │ take snapshot
              ▼
  ┌─────────────────────────┐
  │ Snapshot Being Taken (3)│ ← Freezing positions
  └───────────┬─────────────┘
              │ snapshot complete
              ▼
  ┌─────────────────────────┐
  │ Snapshot Is Ready (4)   │ ← Compute adjustments
  └───────────┬─────────────┘
         ┌────┴────┐
         ▼         ▼
  ┌───────────┐  ┌───────────┐
  │Complete(2)│  │Invalid(5) │
  └───────────┘  └───────────┘
   (success)     (failed validation)
```

---

## 3. Data Overview

| StatusID | Name | Meaning |
|---|---|---|
| 0 | Not been processed yet | The index dividend event is queued but no processing has begun. Waiting for the next scheduled dividend processing cycle to pick it up. |
| 1 | Started | Processing is actively running — the system is identifying affected positions and calculating index-level dividend adjustments. |
| 3 | Snapshot Is Being Taken | A point-in-time freeze of all affected positions is in progress. No position changes should occur during this window to ensure accurate dividend calculation. |
| 4 | Snapshot Is Ready | The position snapshot is complete and consistent. The system can now calculate per-position dividend adjustments against this frozen dataset. |
| 5 | Invalid | The processing failed validation checks. Data inconsistency detected — possibly stale prices, missing positions, or calculation errors. Requires manual investigation by the operations team. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | tinyint | NO | - | VERIFIED | Primary key identifying the dividend processing state. 0=Not processed, 1=Started, 2=Completed, 3=Snapshot in progress, 4=Snapshot ready, 5=Invalid. Referenced by dividend processing tables and Monitor.CheckDividendsStatus. |
| 2 | Name | varchar(100) | YES | - | VERIFIED | Human-readable description of the processing state. Displayed in dividend monitoring dashboards and operational alerts. Leading/trailing whitespace exists in some values (e.g., " Snapshot Is Being Taken"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitor.CheckDividendsStatus | StatusID | Lookup | Monitors for stuck or failed dividend processing by checking status values |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitor.CheckDividendsStatus | Stored Procedure | Reads — monitors dividend processing status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_IndexStatus | CLUSTERED PK | StatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_IndexStatus | PRIMARY KEY | Unique dividend processing status identifier |

---

## 8. Sample Queries

### 8.1 List all dividend statuses
```sql
SELECT  StatusID,
        LTRIM(RTRIM(Name)) AS Name
FROM    [Dictionary].[IndexDividenedStatus] WITH (NOLOCK)
ORDER BY StatusID;
```

### 8.2 Check for stuck dividend processing
```sql
SELECT  StatusID,
        Name
FROM    [Dictionary].[IndexDividenedStatus] WITH (NOLOCK)
WHERE   StatusID IN (1, 3)
ORDER BY StatusID;
```

### 8.3 Categorize statuses by terminal vs active
```sql
SELECT  StatusID,
        LTRIM(RTRIM(Name)) AS Name,
        CASE
            WHEN StatusID IN (0, 1, 3, 4) THEN 'Active/Pending'
            WHEN StatusID = 2              THEN 'Terminal Success'
            WHEN StatusID = 5              THEN 'Terminal Failure'
        END AS StateCategory
FROM    [Dictionary].[IndexDividenedStatus] WITH (NOLOCK)
ORDER BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.IndexDividenedStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.IndexDividenedStatus.sql*
