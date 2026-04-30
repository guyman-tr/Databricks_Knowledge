# AffiliateAdmin.DeleteAffiliateType

> Soft-deletes (deactivates) one or more affiliate types that have no assigned affiliates, and returns both deactivated and skipped types with reasons.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deactivated type IDs + skipped types with blocking affiliates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.DeleteAffiliateType performs soft deletion of affiliate types by setting their `IsActive` flag to 0 rather than physically removing them. Affiliate types define commission structures (CPA, revenue share, hybrid), and deleting them would break the commission calculation chain. Types that still have affiliates assigned cannot be deactivated.

This procedure exists because affiliate types are referenced by active affiliates and their historical commission records. Hard deletion would violate referential integrity with `dbo.tblaff_Affiliates.AffiliateTypeID`. The soft-delete approach preserves historical data while hiding inactive types from the admin UI.

Data flow: The admin portal sends a list of AffiliateTypeIDs via `dbo.IDTableType`. The procedure identifies types with assigned affiliates (not deactivatable), then updates the remaining types to IsActive=0 using an OUTPUT clause. Audit entries are created with ChangedSectionID=2 (AffiliateTypes) and ActionID=3 (Delete). Two result sets are returned: deactivated type IDs and blocked types with their affiliate IDs.

---

## 2. Business Logic

### 2.1 Soft Delete Pattern (IsActive Flag)

**What**: Instead of DELETE, the procedure sets IsActive=0, preserving the record for historical reference.

**Columns/Parameters Involved**: `@AffiliateTypeIDsToDelete`, tblaff_AffiliateTypes.IsActive

**Rules**:
- UPDATE sets IsActive = 0 (not a physical DELETE)
- Only types without assigned affiliates are deactivated
- Types with affiliates are returned in the second result set
- Deactivated types are hidden from listings: `WHERE IsActive <> 0 OR IsActive IS NULL`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user. Written to AuditLog.UserEmail. |
| 2 | @AffiliateTypeIDsToDelete | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing AffiliateTypeIDs to deactivate. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | dbo.tblaff_AffiliateTypes | Write | Sets IsActive=0 for soft deletion |
| SELECT | dbo.tblaff_Affiliates | Read | Checks for assigned affiliates (deletion guard) |
| INSERT INTO | dbo.AuditLog | Write | Logs deactivation with SectionID=2, ActionID=3 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.DeleteAffiliateType (procedure)
+-- dbo.tblaff_AffiliateTypes (table)
+-- dbo.tblaff_Affiliates (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | UPDATE target for soft deletion |
| dbo.tblaff_Affiliates | Table | JOIN to check for assigned affiliates |
| dbo.AuditLog | Table | INSERT for audit trail |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Deactivate affiliate types
```sql
DECLARE @Types dbo.IDTableType;
INSERT INTO @Types (ID) VALUES (50), (51);
EXEC AffiliateAdmin.DeleteAffiliateType @UserEmail = 'admin@company.com', @AffiliateTypeIDsToDelete = @Types;
```

### 8.2 Find types safe to deactivate (no affiliates)
```sql
SELECT at.AffiliateTypeID, at.[Description]
FROM dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateTypeID = at.AffiliateTypeID
WHERE a.AffiliateID IS NULL AND (at.IsActive = 1 OR at.IsActive IS NULL);
```

### 8.3 View deactivation audit trail
```sql
SELECT ChangedOnDate, UserEmail, ReasonOfChange, ReferencedChangedID
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 2 AND ActionID = 3
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4262, PART-3147, PART-2440.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.DeleteAffiliateType | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.DeleteAffiliateType.sql*
