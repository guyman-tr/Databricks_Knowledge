# Dictionary.Action

> Lookup table classifying the type of data modification recorded in audit/change logs - Insert, Update, or Delete.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Action defines the three fundamental data modification types tracked by the audit logging system. Every change to affiliate data (creation, update, deletion) is recorded in dbo.AuditLog with an ActionID that classifies what operation was performed.

Without this table, audit logs would contain raw integer action codes with no human-readable interpretation. Compliance reviews, admin investigations, and audit reports all depend on translating ActionID values into meaningful operation labels.

This is static reference data. Rows are never modified at runtime. The AffiliateAdmin.GetAuditLog procedure joins to this table to display audit trails with readable action names.

---

## 2. Business Logic

### 2.1 CRUD Audit Classification

**What**: Three standard DML operations classified for audit trail recording.

**Columns/Parameters Involved**: `ActionID`, `Name`

**Rules**:
- ID=1 (Insert) records the creation of a new entity (e.g., new affiliate registered)
- ID=2 (Update) records a modification to an existing entity (e.g., affiliate status changed)
- ID=3 (Delete) records the removal of an entity (e.g., affiliate deactivated/removed)
- Every row in dbo.AuditLog must have one of these three ActionIDs

---

## 3. Data Overview

| ActionID | Name | Meaning |
|---|---|---|
| 1 | Insert | A new record was created in the tracked entity. In the affiliate context, this typically means a new affiliate was registered, a new commission plan was created, or a new configuration was added |
| 2 | Update | An existing record was modified. Captures field-level changes such as affiliate status changes, commission rate adjustments, or configuration updates. The most frequent audit action |
| 3 | Delete | A record was removed from the tracked entity. Used when affiliates are deactivated, plans are removed, or configurations are deleted. May be logical (status change) rather than physical deletion |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionID | int | NO | - | VERIFIED | Primary key identifying the audit action type. Values: 1=Insert, 2=Update, 3=Delete. See [Action](../../_glossary.md#action) for full business definitions. Referenced by dbo.AuditLog.ActionID. |
| 2 | Name | nvarchar(50) | NO | - | VERIFIED | Human-readable label for the action type. Used in audit log displays and admin reports. Standard DML operation names: "Insert", "Update", "Delete". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AuditLog | ActionID | Implicit FK | Core audit log table records which DML operation was performed on the tracked entity |
| AffiliateAdmin.GetAuditLog | JOIN | Lookup | Joins to Dictionary.Action to display readable action names in audit log results |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AuditLog | Table | Stores ActionID as implicit FK for each audit record |
| AffiliateAdmin.GetAuditLog | Stored Procedure | READER - joins to decode ActionID to human-readable name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.Action | CLUSTERED PK | ActionID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all action types
```sql
SELECT ActionID, Name
FROM Dictionary.Action WITH (NOLOCK)
ORDER BY ActionID
```

### 8.2 View audit log with readable action names
```sql
SELECT TOP 10 al.*, a.Name AS ActionName
FROM dbo.AuditLog al WITH (NOLOCK)
JOIN Dictionary.Action a WITH (NOLOCK) ON al.ActionID = a.ActionID
ORDER BY al.AuditLogID DESC
```

### 8.3 Count audit entries by action type
```sql
SELECT a.ActionID, a.Name, COUNT(*) AS EntryCount
FROM dbo.AuditLog al WITH (NOLOCK)
JOIN Dictionary.Action a WITH (NOLOCK) ON al.ActionID = a.ActionID
GROUP BY a.ActionID, a.Name
ORDER BY EntryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Action | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.Action.sql*
