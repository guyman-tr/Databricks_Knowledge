# AffiliateAdmin.DeleteAffiliateGroups

> Deletes one or more affiliate groups that have no assigned affiliates, cascades viewer permission removal, and returns both deleted and skipped groups with reasons.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deleted group IDs + skipped groups with blocking affiliates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.DeleteAffiliateGroups provides safe batch deletion of affiliate groups from the admin portal. It implements a "delete-if-empty" pattern: groups that still contain affiliates are skipped (returned to the caller for display), while empty groups are deleted along with their associated viewer permissions. This prevents orphaning affiliates by refusing to delete their containing group.

This procedure exists because affiliate groups form the organizational backbone of the affiliate management system. Deleting a group that still has affiliates assigned would break the FK relationship in `dbo.tblaff_Affiliates.AffiliatesGroupsID`, leaving those affiliates without a group assignment. The procedure's split-result pattern (deleted vs. not-deleted) allows the admin UI to show the user exactly which groups were successfully removed and which were blocked.

Data flow: The admin portal sends a list of GroupIDs via `dbo.IDTableType`. The procedure joins against `dbo.tblaff_Affiliates` to identify groups with active affiliates (not deletable), then deletes the remaining groups from `AffiliateAdmin.AffiliatesGroups` using an OUTPUT clause to capture deleted IDs. It creates audit log entries for each deletion, cascade-deletes viewer permissions from `AffiliateAdmin.AffiliateGroups_Viewers`, and returns two result sets: deleted group IDs and blocked groups with their blocking affiliate IDs.

---

## 2. Business Logic

### 2.1 Delete-If-Empty Pattern

**What**: Only groups with no assigned affiliates can be deleted. Groups with active affiliates are protected.

**Columns/Parameters Involved**: `@GroupIDsToDelete`, AffiliatesGroups.AffiliatesGroupsID, tblaff_Affiliates.AffiliatesGroupsID

**Rules**:
- @NotDeletedGroups captures groups that have at least one affiliate via INNER JOIN to tblaff_Affiliates
- DELETE only processes groups whose ID is NOT IN the @NotDeletedGroups set
- OUTPUT clause captures the successfully deleted AffiliatesGroupsID values
- Both result sets are returned to the caller: deleted IDs and not-deleted (GroupID, AffiliateID) pairs

**Diagram**:
```
@GroupIDsToDelete
    |
    +-- JOIN tblaff_Affiliates
    |     |
    |     +-- Has affiliates? --> @NotDeletedGroups (blocked)
    |     +-- No affiliates?  --> DELETE from AffiliatesGroups
    |                               |
    |                          OUTPUT deleted IDs
    |                               |
    +-- AuditLog (Section=3, Action=3 per deleted group)
    +-- DELETE AffiliateGroups_Viewers for deleted groups
    |
    RETURN: Result 1 = deleted IDs
            Result 2 = blocked (GroupID, AffiliateID)
```

### 2.2 Cascade Viewer Cleanup

**What**: When a group is deleted, its viewer permissions in AffiliateGroups_Viewers are also removed.

**Columns/Parameters Involved**: AffiliateGroups_Viewers.AffiliatesGroupsID

**Rules**:
- After the main group DELETE, a separate DELETE removes all AffiliateGroups_Viewers rows for the deleted group IDs
- This prevents orphaned viewer permission records
- The viewer cleanup happens within the same transaction (XACT_ABORT ON)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user performing the deletion. Written to AuditLog.UserEmail. |
| 2 | @GroupIDsToDelete | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing the IDs of groups to delete. Each row's ID value is an AffiliatesGroupsID from AffiliateAdmin.AffiliatesGroups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | AffiliateAdmin.AffiliatesGroups | Write | Deletes groups that have no assigned affiliates |
| DELETE | AffiliateAdmin.AffiliateGroups_Viewers | Write | Cascade-deletes viewer permissions for deleted groups |
| SELECT | dbo.tblaff_Affiliates | Read | Checks which groups still have assigned affiliates |
| SELECT | Dictionary.ChangedSections | Read | Looks up SectionID for 'Affiliate Group' audit entries |
| INSERT INTO | dbo.AuditLog | Write | Creates audit trail entries for each deletion |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.DeleteAffiliateGroups (procedure)
+-- AffiliateAdmin.AffiliatesGroups (table)
+-- AffiliateAdmin.AffiliateGroups_Viewers (table)
+-- dbo.tblaff_Affiliates (table)
+-- Dictionary.ChangedSections (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | DELETE target for group removal |
| AffiliateAdmin.AffiliateGroups_Viewers | Table | CASCADE DELETE for viewer permissions |
| dbo.tblaff_Affiliates | Table | JOIN to check for assigned affiliates (deletion guard) |
| Dictionary.ChangedSections | Table | Lookup SectionID for 'Affiliate Group'. See [Changed Sections](../../_glossary.md#changed-sections): ID=3. |
| dbo.AuditLog | Table | INSERT for audit trail (ActionID=3 Delete) |

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

### 8.1 Delete specific groups
```sql
DECLARE @Groups dbo.IDTableType;
INSERT INTO @Groups (ID) VALUES (100), (101), (102);

EXEC AffiliateAdmin.DeleteAffiliateGroups
    @UserEmail = 'admin@company.com',
    @GroupIDsToDelete = @Groups;
-- Returns: Result 1 = deleted IDs, Result 2 = blocked groups
```

### 8.2 Find empty groups safe to delete
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliatesGroupsID = ag.AffiliatesGroupsID
WHERE a.AffiliateID IS NULL AND ag.AffiliatesGroupsID > 1;
```

### 8.3 Review deletion audit trail
```sql
SELECT AuditID, ChangedOnDate, UserEmail, ReasonOfChange, ReferencedChangedID
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = (SELECT SectionID FROM Dictionary.ChangedSections WITH (NOLOCK) WHERE Name = 'Affiliate Group')
  AND ActionID = 3
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comments reference PART-4500 (Gil, 30/6/2025).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.DeleteAffiliateGroups | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.DeleteAffiliateGroups.sql*
