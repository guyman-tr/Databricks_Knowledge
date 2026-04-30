# History.TransferStepsLog

> Step-level audit log table designed to track individual processing steps within a money transfer lifecycle, recording step names, retry counts, and per-step statuses. Currently empty - no data has been written to this table.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | StepID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.TransferStepsLog is a granular audit table designed to record individual processing steps within the money transfer pipeline. While History.Transfers (the temporal history table) captures the overall state of a transfer at each modification, TransferStepsLog was designed to capture the individual steps within each state transition - such as validation, routing, provider communication, and confirmation.

The table exists to provide step-level observability into the transfer processing pipeline. Without it, debugging a failed transfer requires piecing together the timeline from the temporal history alone. With step logging, each micro-operation (and its retry count and status) would be individually recorded.

Currently, this table is **empty and has no stored procedure integration** in the SSDT repository. No stored procedures INSERT into, UPDATE, or SELECT from this table. The MIMO monitoring user has been granted SELECT access, indicating it was intended for monitoring/reporting consumption. Data may be written directly by the application layer (bypassing stored procedures), or this table represents a planned feature that has not yet been implemented.

---

## 2. Business Logic

### 2.1 Step-Level Transfer Audit Trail (Designed, Not Active)

**What**: Each row would represent a single processing step for a transfer, enabling fine-grained tracing of the transfer pipeline.

**Columns/Parameters Involved**: `TransferID`, `StepName`, `Retry`, `StatusID`, `CreateDate`

**Rules**:
- TransferID links each step to a transfer in Billing.Transfers / History.Transfers
- StepName (varchar 100) identifies the processing step (e.g., validation, routing, provider call)
- Retry tracks how many times a step was attempted (0 = first attempt, 1+ = retries)
- StatusID records the outcome of each step attempt (no lookup table identified in this DB)
- CreateDate defaults to getutcdate(), recording when each step was logged
- Multiple rows per TransferID would show the step-by-step processing timeline

**Diagram**:
```
Transfer (TransferID)
  |
  +-- Step 1: [StepName] Retry=0 StatusID=? CreateDate=T1
  +-- Step 2: [StepName] Retry=0 StatusID=? CreateDate=T2
  +-- Step 2: [StepName] Retry=1 StatusID=? CreateDate=T3  (retry)
  +-- Step 3: [StepName] Retry=0 StatusID=? CreateDate=T4
```

---

## 3. Data Overview

This table is currently empty (0 rows). No sample data is available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StepID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. Uniquely identifies each step log entry across all transfers. CLUSTERED PK ensures insertion order. |
| 2 | TransferID | int | NO | - | CODE-BACKED | References the transfer this step belongs to. Maps to Billing.Transfers.TransferID / History.Transfers.TransferID. Multiple step rows per TransferID would trace the processing pipeline for a single transfer. |
| 3 | StepName | varchar(100) | YES | - | NAME-INFERRED | Human-readable name of the processing step being logged (e.g., validation, routing, provider communication). No code evidence found for specific step name values - table is unused by stored procedures. |
| 4 | Retry | int | YES | - | NAME-INFERRED | Retry attempt counter for this step. Expected to be 0 for the first attempt and increment for each retry. No code evidence available - table is unused by stored procedures. |
| 5 | StatusID | int | YES | - | NAME-INFERRED | Outcome status of this step attempt. No explicit FK or lookup table identified within this database. May reference Dictionary.TransferStatus or an application-defined step status enum. No code evidence available. |
| 6 | CreateDate | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp when this step log entry was created. DEFAULT getutcdate() ensures automatic timestamping on INSERT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransferID | Billing.Transfers / History.Transfers | Implicit FK | Links each step to the parent transfer. No explicit FK constraint defined. |
| StatusID | Unknown lookup | Implicit Lookup | May reference Dictionary.TransferStatus or an application-defined status. No code evidence found. |

### 5.2 Referenced By (other objects point to this)

No objects reference History.TransferStepsLog. No views, procedures, or functions in the SSDT repository read from or write to this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. The MIMO user has SELECT access (monitoring/reporting) but no stored procedures or views reference this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | StepID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | CreateDate = getutcdate() - automatically timestamps each step log entry at creation |

---

## 8. Sample Queries

### 8.1 View all processing steps for a specific transfer
```sql
SELECT StepID, TransferID, StepName, Retry, StatusID, CreateDate
FROM History.TransferStepsLog WITH (NOLOCK)
WHERE TransferID = @TransferID
ORDER BY CreateDate ASC
```

### 8.2 Find steps that required retries
```sql
SELECT TransferID, StepName, MAX(Retry) AS MaxRetries, COUNT(*) AS Attempts
FROM History.TransferStepsLog WITH (NOLOCK)
WHERE Retry > 0
GROUP BY TransferID, StepName
ORDER BY MaxRetries DESC
```

### 8.3 Step timeline with transfer status context
```sql
SELECT sl.StepID, sl.TransferID, sl.StepName, sl.Retry, sl.StatusID,
       sl.CreateDate AS StepTime,
       ds.Name AS StepStatusName
FROM History.TransferStepsLog sl WITH (NOLOCK)
LEFT JOIN Dictionary.TransferStatus ds WITH (NOLOCK) ON ds.ID = sl.StatusID
WHERE sl.TransferID = @TransferID
ORDER BY sl.CreateDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 6.4/10 (Elements: 5/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 10/11 (9B skipped - no app repos)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no SP consumers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TransferStepsLog | Type: Table | Source: MoneyTransfer/History/Tables/History.TransferStepsLog.sql*
