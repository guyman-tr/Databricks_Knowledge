# BackOffice.CampaignGroupEdit

> Renames a campaign group in BackOffice.CampaignGroup by updating its Name column.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the rename operation for campaign groups. Campaign groups are organizational containers that cluster BackOffice marketing campaigns by staff member, product segment, or marketing initiative. When a group's name needs to change - a staff handover renaming "Ryan" to "Alex", a tier rename, or a strategic rebrand - operators call this procedure.

It performs a single UPDATE setting the Name column for the specified group. The new name must be unique across all groups (enforced by the `BCMG_NAME` unique index on BackOffice.CampaignGroup) - attempting to rename to an already-existing group name will raise a SQL unique constraint violation. Returns `@@ERROR` so the caller can detect failures.

---

## 2. Business Logic

### 2.1 Group Rename with Uniqueness Enforcement

**What**: Updates the Name of an existing campaign group. The unique index prevents naming conflicts.

**Columns/Parameters Involved**: `@CampaignGroupID`, `@Name`, `BackOffice.CampaignGroup.Name`

**Rules**:
- UPDATE BackOffice.CampaignGroup SET Name = @Name WHERE CampaignGroupID = @CampaignGroupID
- New @Name must be unique (BCMG_NAME unique index) - duplicate name causes SQL error 2627
- If @CampaignGroupID does not exist: UPDATE runs silently (0 rows affected), @@ERROR = 0
- Returns @@ERROR: 0 on success or not-found; non-zero on unique violation or other failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignGroupID | INTEGER | NO | - | CODE-BACKED | The identifier of the campaign group to rename. PK of BackOffice.CampaignGroup. If not found, the UPDATE runs silently with 0 rows affected. |
| 2 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | The new display name for this campaign group. Must be unique across all campaign groups (BCMG_NAME unique index). Max 50 characters. Examples: "Silver Club", "FTD", "Affiliates". |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | @@ERROR after the UPDATE: 0 on success or not-found; 2627 (unique constraint violation) if @Name already exists; other non-zero codes for unexpected failures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignGroupID | BackOffice.CampaignGroup | MODIFIER | Updates Name WHERE CampaignGroupID=@CampaignGroupID |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from BackOffice campaign management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignGroupEdit (procedure)
+-- BackOffice.CampaignGroup (table) [UPDATE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignGroup | Table | UPDATE: sets Name WHERE CampaignGroupID=@CampaignGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice campaign management UI | External | Calls this to rename an existing campaign group |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Name uniqueness | DB Enforced | BCMG_NAME unique index on BackOffice.CampaignGroup.Name - duplicate @Name raises SQL error 2627 |
| Silent not-found | Design | If @CampaignGroupID does not exist, UPDATE runs silently with 0 rows affected; @@ERROR = 0 |
| Return value | Application | Returns @@ERROR not @@ROWCOUNT - caller must check for non-zero to detect unique violations |

---

## 8. Sample Queries

### 8.1 Rename a campaign group (staff handover)

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CampaignGroupEdit
    @CampaignGroupID = 45,
    @Name = 'Alex Trading Team'
IF @Result <> 0
    PRINT 'Rename failed - name may already exist'
```

### 8.2 Check if the new name is available before renaming

```sql
SELECT CampaignGroupID, Name
FROM BackOffice.CampaignGroup WITH (NOLOCK)
WHERE Name = 'Alex Trading Team'
-- Must return 0 rows before calling CampaignGroupEdit with this name
```

### 8.3 Verify the rename

```sql
SELECT CampaignGroupID, Name
FROM BackOffice.CampaignGroup WITH (NOLOCK)
WHERE CampaignGroupID = 45
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignGroupEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignGroupEdit.sql*
