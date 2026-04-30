# dbo.AuditLog

> Tracks all admin user changes to affiliate platform configuration, recording who changed what field, in which section, with old and new values plus reason for change.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AuditID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table provides a complete audit trail of all configuration changes made by admin users in the affiliate management platform. Every time an admin modifies an affiliate, affiliate type, group, banner, country, announcement, or other configurable entity, a row is created recording who made the change, what field was modified, the old and new values, and the reason for the change.

Without this table, there would be no accountability for configuration changes. Compliance and operations teams rely on this audit trail to investigate issues, verify commission plan changes, and track who modified sensitive settings. Admin users must have Audits_View permission in tblaff_User to access this data.

Rows are created by the application whenever a tracked entity is modified. The table references Dictionary.Action (Insert/Update/Delete), Dictionary.ChangedSections (which area was modified), and tblaff_User (who made the change) via explicit foreign keys.

---

## 2. Business Logic

### 2.1 Field-Level Change Tracking

**What**: Every change is recorded at the individual field level with before/after values and human-readable descriptions.

**Columns/Parameters Involved**: `ChangedFieldName`, `OldFieldValue`, `NewFieldValue`, `OldFieldDescription`, `NewFieldDescription`

**Rules**:
- ChangedFieldName identifies the specific column/property that was modified
- OldFieldValue/NewFieldValue store the raw values (may be IDs or codes)
- OldFieldDescription/NewFieldDescription store human-readable versions (e.g., resolved lookup names)
- ReasonOfChange captures the admin's stated reason for making the change
- All sensitive fields are masked (ChangedFieldName, OldFieldValue, NewFieldValue, UserEmail) via dynamic data masking

---

## 3. Data Overview

N/A - Audit log data is sensitive and masked. See element descriptions for field meanings.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AuditID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Sequential audit entry identifier. |
| 2 | ChangedOnDate | datetime | NO | - | CODE-BACKED | Timestamp when the change was made. |
| 3 | ChangedByUserID | int | YES | - | CODE-BACKED | FK to dbo.tblaff_User.UserID. The admin user who made the change. NULL if system-generated. |
| 4 | ChangedSectionID | int | YES | - | CODE-BACKED | FK to Dictionary.ChangedSections.SectionID. Identifies which business area was modified: 1=Affiliates, 2=AffiliateTypes, 3=Affiliate Group, 4=Announcements, etc. See [Changed Sections](../../_glossary.md#changed-sections). |
| 5 | ChangedFieldName | nvarchar(200) | YES | - | CODE-BACKED | Name of the field that was changed (e.g., "AffiliateTypeID", "AccountStatus"). MASKED. |
| 6 | OldFieldValue | nvarchar(max) | YES | - | CODE-BACKED | Previous value of the field before the change. MASKED. Stores raw values (IDs, codes). |
| 7 | NewFieldValue | nvarchar(max) | YES | - | CODE-BACKED | New value of the field after the change. MASKED. Stores raw values. |
| 8 | ReasonOfChange | nvarchar(1000) | NO | - | CODE-BACKED | Admin-provided reason for making this change. Required field - enforces accountability. |
| 9 | ReferencedChangedID | int | NO | - | CODE-BACKED | ID of the entity that was changed (e.g., AffiliateID, AffiliateTypeID). Combined with ChangedSectionID to identify the exact record modified. |
| 10 | ActionID | int | NO | - | CODE-BACKED | FK to Dictionary.Action. Type of operation: 1=Insert, 2=Update, 3=Delete. See [Action](../../_glossary.md#action). |
| 11 | OldFieldDescription | nvarchar(max) | YES | - | CODE-BACKED | Human-readable description of the old value (e.g., resolved lookup name instead of just the ID). |
| 12 | NewFieldDescription | nvarchar(max) | YES | - | CODE-BACKED | Human-readable description of the new value. |
| 13 | UserEmail | nvarchar(250) | YES | - | CODE-BACKED | Email of the admin user who made the change. MASKED. Denormalized from tblaff_User for quick display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActionID | Dictionary.Action | Explicit FK | Type of change: 1=Insert, 2=Update, 3=Delete |
| ChangedByUserID | dbo.tblaff_User | Explicit FK | Admin user who made the change |
| ChangedSectionID | Dictionary.ChangedSections | Explicit FK | Business area that was modified |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AuditLog (table)
+-- Dictionary.Action (table)
+-- dbo.tblaff_User (table)
+-- Dictionary.ChangedSections (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Action | Table | FK: ActionID |
| dbo.tblaff_User | Table | FK: ChangedByUserID |
| Dictionary.ChangedSections | Table | FK: ChangedSectionID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AuditLog | CLUSTERED PK | AuditID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ActionID | FOREIGN KEY | ActionID -> Dictionary.Action.ActionID (WITH NOCHECK) |
| FK_ChangedByUserID | FOREIGN KEY | ChangedByUserID -> dbo.tblaff_User.UserID |
| FK_ChangedSectionID | FOREIGN KEY | ChangedSectionID -> Dictionary.ChangedSections.SectionID |

---

## 8. Sample Queries

### 8.1 View recent changes by a specific admin user
```sql
SELECT a.AuditID, a.ChangedOnDate, cs.Name AS Section,
       a.ChangedFieldName, a.OldFieldValue, a.NewFieldValue, a.ReasonOfChange
FROM dbo.AuditLog a WITH (NOLOCK)
JOIN Dictionary.ChangedSections cs WITH (NOLOCK) ON a.ChangedSectionID = cs.SectionID
WHERE a.ChangedByUserID = 6
ORDER BY a.ChangedOnDate DESC
```

### 8.2 View all changes to a specific affiliate
```sql
SELECT a.ChangedOnDate, u.Name AS ChangedBy, act.Name AS ActionType,
       a.ChangedFieldName, a.OldFieldDescription, a.NewFieldDescription, a.ReasonOfChange
FROM dbo.AuditLog a WITH (NOLOCK)
JOIN Dictionary.Action act WITH (NOLOCK) ON a.ActionID = act.ActionID
LEFT JOIN dbo.tblaff_User u WITH (NOLOCK) ON a.ChangedByUserID = u.UserID
WHERE a.ChangedSectionID = 1 AND a.ReferencedChangedID = 100
ORDER BY a.ChangedOnDate DESC
```

### 8.3 Count changes by section
```sql
SELECT cs.Name AS Section, act.Name AS ActionType, COUNT(*) AS ChangeCount
FROM dbo.AuditLog a WITH (NOLOCK)
JOIN Dictionary.ChangedSections cs WITH (NOLOCK) ON a.ChangedSectionID = cs.SectionID
JOIN Dictionary.Action act WITH (NOLOCK) ON a.ActionID = act.ActionID
GROUP BY cs.Name, act.Name
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AuditLog | Type: Table | Source: fiktivo/dbo/Tables/dbo.AuditLog.sql*
