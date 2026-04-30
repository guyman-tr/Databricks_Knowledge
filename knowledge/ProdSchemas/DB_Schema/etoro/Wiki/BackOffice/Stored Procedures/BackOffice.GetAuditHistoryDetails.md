# BackOffice.GetAuditHistoryDetails

> Returns field-level change detail records (FieldName, OldValue, NewValue) for a specific back-office audit action from the DB_Logs cross-database audit store, used alongside GetAuditHistory when HasDetails=1.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ActionID - specific audit action; returns one row per changed field |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAuditHistoryDetails` is the companion procedure to `BackOffice.GetAuditHistory`. While GetAuditHistory returns the summary audit trail (what action, who performed it, when, on which customer), GetAuditHistoryDetails returns the granular field-level changes for a single action: which field was modified, what was the old value, and what is the new value.

The data lives in `DB_Logs.BackOffice.AuditActionDetail` - a separate audit database on the same server - to segregate the high-volume, append-only audit detail log from the operational etoro database. Not every audit action generates detail records; only operations that modify specific fields populate AuditActionDetail. The `HasDetails` flag in GetAuditHistory (BIT, 0 or 1) indicates whether calling GetAuditHistoryDetails will return any rows.

**Typical use flow in the BackOffice UI**:
1. Agent calls GetAuditHistory for a customer to see the action timeline.
2. Agent clicks on a row where HasDetails=1 to expand details.
3. UI calls GetAuditHistoryDetails with that ActionID to show the before/after field changes.

This two-procedure design keeps the audit timeline fast (GetAuditHistory reads a summary table) while allowing deep-dive on demand (GetAuditHistoryDetails reads detail only when needed).

---

## 2. Business Logic

### 2.1 Direct Cross-Database Read - No Transformation

**What**: The procedure is a minimal passthrough SELECT from DB_Logs, with no joins, no filtering beyond ActionID, no aggregation.

**Columns/Parameters Involved**: `@ActionID`, `DB_Logs.BackOffice.AuditActionDetail.*`

**Rules**:
- Returns one row per changed field for the given ActionID.
- Three-column output: FieldName (which field changed), NewValue (value after the action), OldValue (value before the action).
- Both OldValue and NewValue are stored as NVARCHAR - type conversion is the caller's responsibility.
- Returns zero rows if ActionID has no detail records (HasDetails=0 case, or stale ActionID).
- No NOLOCK specified on this procedure - reads DB_Logs which is append-only in practice.

### 2.2 Cross-Database Reference (DB_Logs)

**What**: The source table is in a different database on the same SQL Server instance.

**Columns/Parameters Involved**: `DB_Logs.BackOffice.AuditActionDetail`

**Rules**:
- DB_Logs is a dedicated audit log database on the same server as etoro.
- Three-part name (`DB_Logs.BackOffice.AuditActionDetail`) - no linked server overhead.
- The BackOffice schema in DB_Logs mirrors the BackOffice schema in etoro for audit table naming consistency.
- AuditActionId in DB_Logs corresponds to ActionID in BackOffice.AuditAction (foreign key by convention, not enforced cross-database).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionID | INT | NO | - | CODE-BACKED | Audit action identifier from BackOffice.AuditAction.ActionID. Used to retrieve all field-level change records for that specific action from DB_Logs.BackOffice.AuditActionDetail. |
| 2 | FieldName | NVARCHAR | NO | - | CODE-BACKED | Name of the field/column that was modified by this audit action (e.g., "AMLComment", "AccountStatus", "DocumentTypeID"). The set of possible field names depends on AuditActionTypeID of the parent action. |
| 3 | NewValue | NVARCHAR | YES | - | CODE-BACKED | Value of the field after the action was performed. Stored as NVARCHAR regardless of underlying data type. NULL if the field was cleared. |
| 4 | OldValue | NVARCHAR | YES | - | CODE-BACKED | Value of the field before the action was performed. Stored as NVARCHAR. NULL if the field was previously empty or not tracked. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ActionID | DB_Logs.BackOffice.AuditActionDetail | Primary source (cross-database) | Retrieves all field-level change rows for the given action ID. |
| @ActionID | BackOffice.AuditAction | Logical FK (not enforced) | ActionID corresponds to AuditAction.ActionID in the etoro database. Callers must obtain a valid ActionID from GetAuditHistory first. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by BOUser, BOSegSpecial, BOFacade service accounts. Companion to BackOffice.GetAuditHistory (called for rows where HasDetails=1).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAuditHistoryDetails (procedure)
└── DB_Logs.BackOffice.AuditActionDetail (table) [cross-database]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.BackOffice.AuditActionDetail | Table (cross-database) | Only source - returns all FieldName/NewValue/OldValue rows for the given AuditActionId. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BOUser, BOSegSpecial, BOFacade. Companion to BackOffice.GetAuditHistory. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. DB_Logs.BackOffice.AuditActionDetail should have an index on AuditActionId for the point-lookup pattern used here.

### 7.2 Constraints

No SET NOCOUNT ON. No NOLOCK. No JOINs. Single three-part cross-database table reference. Extremely simple procedure - complexity is in GetAuditHistory (summary) not here (detail fetch). ActionID must be obtained from GetAuditHistory; there is no validation that the ActionID exists.

---

## 8. Sample Queries

### 8.1 Get field-level details for a specific audit action
```sql
EXEC BackOffice.GetAuditHistoryDetails @ActionID = 99887766;
```

### 8.2 Typical usage pattern - first get history, then details
```sql
-- Step 1: Get audit history for customer
EXEC BackOffice.GetAuditHistory @CID = 10848122;

-- Step 2: For a row where HasDetails=1 (e.g., ActionID=99887766):
EXEC BackOffice.GetAuditHistoryDetails @ActionID = 99887766;
-- Returns: FieldName='AMLComment', OldValue='[2025-01-01 10:00: JohnD] note1', NewValue='[2025-03-01 14:30: JaneS] new note[2025-01-01 10:00: JohnD] note1'
```

### 8.3 Inline equivalent
```sql
SELECT FieldName, NewValue, OldValue
FROM DB_Logs.BackOffice.AuditActionDetail
WHERE AuditActionId = 99887766;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Audit tables](https://etoro-confluence.atlassian.net/wiki/spaces/DROD/pages/audit-tables) | Confluence (DROD space) | Documents the AuditAction + AuditActionDetail split design, DB_Logs separation rationale, and HasDetails pattern. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAuditHistoryDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAuditHistoryDetails.sql*
