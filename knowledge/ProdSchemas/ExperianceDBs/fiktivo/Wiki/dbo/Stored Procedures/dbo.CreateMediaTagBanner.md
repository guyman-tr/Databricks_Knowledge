# dbo.CreateMediaTagBanner

> Replaces the full set of media tags associated with a banner inside a transaction, with full audit logging of both the removal and the new assignment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | BannerID (banner being re-tagged) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the authoritative write path for assigning media tags to a creative banner in the affiliate platform. When a user changes the tags on a banner in the admin UI, this SP deletes all existing tag assignments and inserts the new set atomically. Both the deletion and the insertion are recorded in the AuditLog table so that the history of tag changes is preserved for compliance and debugging. It was introduced as part of Jira ticket PART-210 (Gil Haba, March 2022) and later enhanced to improve the ReasonOfChange audit field.

---

## 2. Business Logic

- Runs inside a BEGIN TRY / BEGIN CATCH block with an explicit transaction.
- Step 1: Captures the existing tag list from dbo.MediaTagBanner using STRING_AGG into @OldTagList.
- Step 2: Deletes all rows from dbo.MediaTagBanner for the given BannerID.
- Step 3: If rows were deleted (@@ROWCOUNT > 0), writes a deletion audit entry to AuditLog (ChangedSectionID = 10, ActionID = 1, NewFieldValue = NULL).
- Step 4: If the incoming @IdTable contains rows, inserts all new tag rows into dbo.MediaTagBanner, then writes a second audit entry with the new tag list as NewFieldValue.
- If the @IdTable is empty the banner ends up with no tags (full clear with no re-assignment).
- On error: rolls back if this is the outermost transaction (@@TRANCOUNT = 1), or commits if nested (@@TRANCOUNT > 1), then re-throws.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @BannerID | INT | IN | (required) | High | Primary key of the banner being updated |
| 2 | @IdTable | dbo.IDTableType (READONLY) | IN | (required) | High | Table-valued parameter containing the new set of TagIDs to assign |
| 3 | @ChangedByUserID | INT | IN | (required) | High | User ID recorded in the audit log for accountability |
| 4 | @ReasonOfChange | NVARCHAR(1000) | IN | (required) | High | Free-text reason stored in the audit log |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE / INSERT | dbo.MediaTagBanner | Write | Clears and repopulates tag assignments for the banner |
| INSERT | dbo.AuditLog | Write | Records old and new tag lists for audit trail |
| SELECT | dbo.MediaTagBanner | Read | Reads existing tags before deletion for audit purposes |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CreateMediaTagBanner
  ├── dbo.MediaTagBanner      (READ + WRITE)
  ├── dbo.AuditLog            (WRITE)
  └── dbo.IDTableType         (User-Defined Table Type, parameter)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.MediaTagBanner | Table | Source of existing tags (DELETE + INSERT) |
| dbo.AuditLog | Table | Audit trail destination |
| dbo.IDTableType | User-Defined Table Type | Table-valued parameter type for new tag IDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Assign tags 5 and 12 to banner 1001
DECLARE @Tags dbo.IDTableType;
INSERT INTO @Tags (ID) VALUES (5), (12);
EXEC dbo.CreateMediaTagBanner
    @BannerID       = 1001,
    @IdTable        = @Tags,
    @ChangedByUserID = 99,
    @ReasonOfChange  = N'Updating tags per campaign brief';

-- Clear all tags from banner 2050
DECLARE @EmptyTags dbo.IDTableType;
EXEC dbo.CreateMediaTagBanner
    @BannerID       = 2050,
    @IdTable        = @EmptyTags,
    @ChangedByUserID = 99,
    @ReasonOfChange  = N'Removing deprecated tags';

-- Audit check after update
SELECT * FROM dbo.AuditLog
WHERE ReferencedChangedID = 1001 AND ChangedSectionID = 10
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

- PART-210 (etoro-jira.atlassian.net) - Gil Haba, 3/7/2022: Original ticket driving the creation of this procedure.
- Comment (03-JAN-22): Improve AuditLog values as better ReasonOfChange, approved by Noga.

---

*Generated: 2026-04-12 | Quality: 8.4/10*
*Object: dbo.CreateMediaTagBanner | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CreateMediaTagBanner.sql*
