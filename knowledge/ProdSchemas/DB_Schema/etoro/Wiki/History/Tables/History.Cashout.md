# History.Cashout

> Legacy audit log recording every status transition for cashout (withdrawal) requests, capturing the before and after CashoutStatusID for each state change event in eToro's early 2008 platform.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CashoutUpdateID (int IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 (1 PK + 3 NC) |

---

## 1. Business Meaning

This table is the historical audit trail for withdrawal (cashout) request lifecycle transitions. Each row represents a single state-change event: a cashout moved from one status to another, stamped with the date and an optional free-text remark explaining why the change occurred. The before/after pattern (PreviousCashoutStatusID -> NewCashoutStatusID) creates a complete event log from which the full lifecycle of any cashout request can be reconstructed.

Without this table, it would be impossible to answer audit questions such as "when was this withdrawal canceled and by whom?" or "how many times did this cashout bounce between Pending and InProcess?" The Remark column captures the human reason behind manual status changes, providing compliance and operations context that the structured fields alone cannot express.

Data flows into this table at each key cashout lifecycle event: when a new request is submitted (CashoutRequestAdd), when it is processed (CashoutProcess), and when it is reversed (CashoutReverse). **Note**: Based on live data analysis, this table contains only 11,646 rows spanning 2008-03-16 to 2008-10-26 - it is a legacy artifact from eToro's earliest platform era. Modern withdrawal audit logging uses `History.WithdrawLog` and `History.WithdrawAction`.

---

## 2. Business Logic

### 2.1 Cashout Status Transition Audit Trail

**What**: A per-event journal of every withdrawal request lifecycle transition.

**Columns/Parameters Involved**: `CashoutID`, `PreviousCashoutStatusID`, `NewCashoutStatusID`, `UpdateDate`, `Remark`

**Rules**:
- One row is inserted per status change, not one row per cashout - a single cashout may have multiple rows in this table
- The combination of (CashoutID, UpdateDate) provides a chronological timeline for any given withdrawal request
- PreviousCashoutStatusID and NewCashoutStatusID reference the same `Dictionary.CashoutStatus` lookup, enabling before/after comparison
- A transition from PreviousCashoutStatusID = NewCashoutStatusID (same status) is valid and indicates a re-confirmation or no-op event (observed in live data: row 11658 has 1->1)
- The Remark captures human decisions: compliance holds ("Chinese fraud"), policy reasons ("bonus"), or system actions ("Initiated by user request")

**Diagram**:
```
Cashout Request lifecycle (sample from live data):
  CashoutID 6029: 1(Pending) -> 1(Pending) [status re-confirmed, no remark]
  CashoutID 6029: 1(Pending) -> 4(Canceled) [Remark: "Initiated by user request"]
  CashoutID 5833: 2(InProcess) -> 4(Canceled) [Remark: "Chinese fraud" - compliance block]
  CashoutID 5840: 2(InProcess) -> 4(Canceled) [Remark: "bonus" - bonus clawback]
```

### 2.2 Legacy Status Set (2008 Platform)

**What**: The status values in this table reflect eToro's 2008 cashout workflow, which predates the full Dictionary.CashoutStatus value set (17 statuses).

**Columns/Parameters Involved**: `PreviousCashoutStatusID`, `NewCashoutStatusID`

**Rules**:
- Live data shows only status IDs 1 (Pending), 2 (InProcess), 3 (Processed), 4 (Canceled) used in this table
- The expanded status set (5-17 added later) does not appear in this legacy dataset
- Modern equivalent system: `History.WithdrawLog` / `History.WithdrawAction` contain the current withdrawal audit log

---

## 3. Data Overview

| CashoutUpdateID | CashoutID | PreviousCashoutStatusID | NewCashoutStatusID | UpdateDate | Remark |
|---|---|---|---|---|---|
| 11659 | 6029 | 1 (Pending) | 4 (Canceled) | 2008-10-26 | "Initiated by user request" - user canceled their own withdrawal |
| 11658 | 6029 | 1 (Pending) | 1 (Pending) | 2008-10-26 | NULL - status re-confirmed with no change, possibly a system re-save |
| 11657 | 5833 | 2 (InProcess) | 4 (Canceled) | 2008-10-26 | "Chinese fraud" - compliance canceled in-progress withdrawal after fraud detection |
| 11656 | 5840 | 2 (InProcess) | 4 (Canceled) | 2008-10-26 | "bonus" - withdrawal blocked due to unmet bonus conditions |
| 11655 | 6028 | 1 (Pending) | 4 (Canceled) | 2008-10-26 | "Initiated by user request" - user self-canceled at the pending stage |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutUpdateID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing unique identifier for each status-change audit entry. NOT FOR REPLICATION prevents identity gap during replication. NONCLUSTERED PK on HISTORY filegroup. |
| 2 | CashoutID | int | NO | - | VERIFIED | The withdrawal request being audited. FK to `Billing.Cashout.CashoutID` (WITH CHECK). Indexed via HCSH_CASHOUT for efficient cashout history lookups. Multiple rows in this table can share the same CashoutID, one per status transition. |
| 3 | PreviousCashoutStatusID | int | NO | - | VERIFIED | The cashout's status BEFORE this transition. FK to `Dictionary.CashoutStatus.CashoutStatusID` (WITH CHECK). Indexed via HCSH_PREVIOUSCASHOUTSTATUS. Combined with NewCashoutStatusID reveals the exact state change. See [Cashout Status](_glossary.md#cashout-status) for value definitions. |
| 4 | NewCashoutStatusID | int | NO | - | VERIFIED | The cashout's status AFTER this transition. FK to `Dictionary.CashoutStatus.CashoutStatusID` (WITH CHECK). Indexed via HCSH_NEWCASHOUTSTATUS. Live data shows values 1-4 used (Pending, InProcess, Processed, Canceled) - this is the 2008 legacy status set. See [Cashout Status](_glossary.md#cashout-status). |
| 5 | UpdateDate | datetime | NO | - | CODE-BACKED | Timestamp when the status change occurred (server UTC time at insert). The chronological ordering column for reconstructing a cashout's full lifecycle. No dedicated index - queries spanning date ranges should use CashoutID index first. |
| 6 | Remark | varchar(250) | YES | - | CODE-BACKED | Free-text explanation for the status change. Written by back-office managers for manual interventions (e.g., "Chinese fraud", "bonus") or by system processes (e.g., "Initiated by user request"). NULL for automated transitions with no human context. Approximately 40% of rows have a non-NULL remark based on live data sampling. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutID | Billing.Cashout | FK (WITH CHECK) | The withdrawal request being audited. Each status change entry belongs to exactly one cashout record. |
| PreviousCashoutStatusID | Dictionary.CashoutStatus | FK (WITH CHECK) | Lookup for the pre-transition status label. See [Cashout Status](_glossary.md#cashout-status). |
| NewCashoutStatusID | Dictionary.CashoutStatus | FK (WITH CHECK) | Lookup for the post-transition status label. See [Cashout Status](_glossary.md#cashout-status). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CashoutProcess | INSERT | WRITER | Logs status transition when a cashout is processed |
| Billing.CashoutRequestAdd | INSERT | WRITER | Logs initial status on cashout creation |
| Billing.CashoutReverse | INSERT | WRITER | Logs status transition when a cashout is reversed |
| Billing.CustomerRemove | SELECT/reference | READER | Reads cashout history during customer account removal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Cashout (table)
- no code-level dependencies (leaf table)
```

This object has no code-level dependencies (it is a target table, not a view or procedure with FROM/JOIN logic).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | FK target - CashoutID references Billing.Cashout.CashoutID |
| Dictionary.CashoutStatus | Table | FK target - PreviousCashoutStatusID and NewCashoutStatusID both reference Dictionary.CashoutStatus.CashoutStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | WRITER - INSERTs status-change rows during cashout processing |
| Billing.CashoutRequestAdd | Stored Procedure | WRITER - INSERTs initial status row when a new cashout is submitted |
| Billing.CashoutReverse | Stored Procedure | WRITER - INSERTs reversal status row when a cashout is reversed |
| Billing.CustomerRemove | Stored Procedure | READER - Reads cashout history as part of customer account removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HCSH | NC PK | CashoutUpdateID ASC | - | - | Active |
| HCSH_CASHOUT | NONCLUSTERED | CashoutID ASC | - | - | Active |
| HCSH_NEWCASHOUTSTATUS | NONCLUSTERED | NewCashoutStatusID ASC | - | - | Active |
| HCSH_PREVIOUSCASHOUTSTATUS | NONCLUSTERED | PreviousCashoutStatusID ASC | - | - | Active |

All indexes use FILLFACTOR=90 and are on the HISTORY filegroup. Note: NewCashoutStatusID and PreviousCashoutStatusID indexes on a 6-column table with only 4 distinct values are low-cardinality indexes, useful primarily for bulk status-reporting queries.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCSH | PRIMARY KEY | NONCLUSTERED on CashoutUpdateID - identity sequence guarantees uniqueness |
| FK_BCSH_HCSH | FOREIGN KEY (WITH CHECK) | CashoutID -> Billing.Cashout(CashoutID) - every audit entry must belong to a valid cashout |
| FK_DCSS_HCSN | FOREIGN KEY (WITH CHECK) | NewCashoutStatusID -> Dictionary.CashoutStatus(CashoutStatusID) |
| FK_DCSS_HCSP | FOREIGN KEY (WITH CHECK) | PreviousCashoutStatusID -> Dictionary.CashoutStatus(CashoutStatusID) |

---

## 8. Sample Queries

### 8.1 Reconstruct the full lifecycle of a cashout request

```sql
SELECT
    h.CashoutUpdateID,
    h.UpdateDate,
    prev.Name AS PreviousStatus,
    new.Name AS NewStatus,
    h.Remark
FROM History.Cashout h WITH (NOLOCK)
JOIN Dictionary.CashoutStatus prev WITH (NOLOCK) ON h.PreviousCashoutStatusID = prev.CashoutStatusID
JOIN Dictionary.CashoutStatus new WITH (NOLOCK) ON h.NewCashoutStatusID = new.CashoutStatusID
WHERE h.CashoutID = @CashoutID
ORDER BY h.UpdateDate ASC;
```

### 8.2 Find canceled cashouts with fraud-related remarks

```sql
SELECT
    h.CashoutID,
    h.UpdateDate,
    h.Remark,
    prev.Name AS PreviousStatus
FROM History.Cashout h WITH (NOLOCK)
JOIN Dictionary.CashoutStatus prev WITH (NOLOCK) ON h.PreviousCashoutStatusID = prev.CashoutStatusID
WHERE h.NewCashoutStatusID = 4  -- Canceled
  AND h.Remark IS NOT NULL
ORDER BY h.UpdateDate DESC;
```

### 8.3 Count status transitions by type (transition matrix)

```sql
SELECT
    prev.Name AS FromStatus,
    new.Name AS ToStatus,
    COUNT(*) AS TransitionCount
FROM History.Cashout h WITH (NOLOCK)
JOIN Dictionary.CashoutStatus prev WITH (NOLOCK) ON h.PreviousCashoutStatusID = prev.CashoutStatusID
JOIN Dictionary.CashoutStatus new WITH (NOLOCK) ON h.NewCashoutStatusID = new.CashoutStatusID
GROUP BY prev.Name, new.Name
ORDER BY TransitionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Cashout | Type: Table | Source: etoro/etoro/History/Tables/History.Cashout.sql*
