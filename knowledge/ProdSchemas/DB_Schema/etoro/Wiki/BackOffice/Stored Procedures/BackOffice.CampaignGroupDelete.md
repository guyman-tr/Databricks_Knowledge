# BackOffice.CampaignGroupDelete

> Deletes a campaign group from BackOffice.CampaignGroup by ID; the delete will fail if any campaign still references this group via the FK constraint.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes a campaign group from the system. Campaign groups are organizational containers used to cluster marketing campaigns by staff member, product segment, or initiative. When a group is no longer needed (e.g., a staff member leaves, a marketing initiative ends), operators call this procedure to clean up the registry.

The procedure relies on the database FK constraint between `BackOffice.Campaign.CampaignGroupID` and `BackOffice.CampaignGroup.CampaignGroupID` to prevent deletion of groups that still own active campaigns. The inline comment in the DDL explicitly acknowledges this: "if linked to campaign, attempt will fail". This is a safe-delete pattern - the caller must reassign or remove all campaigns in the group before deletion succeeds.

Returns `@@ERROR` so the caller can detect whether the delete succeeded or was blocked by the FK constraint.

---

## 2. Business Logic

### 2.1 FK-Guarded Delete

**What**: The delete is blocked by a foreign key constraint if any BackOffice.Campaign row still references the group.

**Columns/Parameters Involved**: `@CampaignGroupID`, `BackOffice.CampaignGroup.CampaignGroupID`, `BackOffice.Campaign.CampaignGroupID`

**Rules**:
- DELETE FROM BackOffice.CampaignGroup WHERE CampaignGroupID = @CampaignGroupID
- If any BackOffice.Campaign.CampaignGroupID = @CampaignGroupID: DELETE fails with FK violation (SQL error 547)
- If no campaigns reference the group: DELETE succeeds, @@ROWCOUNT = 1
- If @CampaignGroupID does not exist: DELETE succeeds silently (@@ROWCOUNT = 0), @@ERROR = 0
- Returns @@ERROR: 0 on success or not-found; non-zero error code on FK violation or other failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignGroupID | INTEGER | NO | - | CODE-BACKED | The identifier of the campaign group to delete. PK of BackOffice.CampaignGroup. Delete fails if any BackOffice.Campaign still references this CampaignGroupID. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 2 | RETURN | INT | @@ERROR after the DELETE: 0 on success or not-found; 547 (FK violation) if campaigns still reference this group; other non-zero SQL error codes for unexpected failures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignGroupID | BackOffice.CampaignGroup | DELETER | Removes the row with matching CampaignGroupID. Fails with FK violation if referenced by BackOffice.Campaign. |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from BackOffice campaign management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignGroupDelete (procedure)
+-- BackOffice.CampaignGroup (table) [DELETE target]
    <- BackOffice.Campaign (table) [FK guard - delete blocked if campaigns reference the group]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignGroup | Table | DELETE: removes row WHERE CampaignGroupID=@CampaignGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice campaign management UI | External | Calls this to remove a campaign group that is no longer needed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK guard | DB Enforced | BackOffice.Campaign.CampaignGroupID FK to BackOffice.CampaignGroup - prevents deleting a group that still owns campaigns; raises SQL error 547 |
| Silent not-found | Design | If @CampaignGroupID does not exist, DELETE runs silently with 0 rows affected; @@ERROR = 0 (no exception) |
| Return value | Application | Returns @@ERROR not @@ROWCOUNT - caller must check for non-zero return to detect FK violations |

---

## 8. Sample Queries

### 8.1 Delete an empty campaign group

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CampaignGroupDelete @CampaignGroupID = 99
IF @Result <> 0
    PRINT 'Delete failed - group may still have campaigns assigned'
```

### 8.2 Check if a group is safe to delete before calling

```sql
SELECT COUNT(*) AS ActiveCampaigns
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE CampaignGroupID = 99
-- Must return 0 before calling CampaignGroupDelete
```

### 8.3 Verify group was removed

```sql
SELECT CampaignGroupID, Name
FROM BackOffice.CampaignGroup WITH (NOLOCK)
WHERE CampaignGroupID = 99
-- Should return 0 rows after successful delete
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignGroupDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignGroupDelete.sql*
