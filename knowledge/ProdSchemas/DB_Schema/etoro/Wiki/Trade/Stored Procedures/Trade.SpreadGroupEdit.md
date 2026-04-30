# Trade.SpreadGroupEdit

> Updates the display name of an existing spread group in Trade.SpreadGroup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure renames an existing spread group. The Name field is the only mutable attribute of a spread group - the SpreadGroupID is immutable once assigned, and the group's spread memberships are managed separately via `Trade.SpreadToGroupLink`/`Trade.SpreadToGroupUnLink`.

---

## 2. Business Logic

No complex business logic. Single-row update of Name only.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadGroupID | INTEGER | NO | - | CODE-BACKED | SpreadGroupID of the spread group to rename. Identifies the row in Trade.SpreadGroup. |
| 2 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | New display name for the spread group. Replaces the current Name value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadGroupID | Trade.SpreadGroup | Writer (UPDATE) | Updates Name for the matching SpreadGroupID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadGroupEdit (procedure)
+-- Trade.SpreadGroup (table) [update Name WHERE SpreadGroupID = @SpreadGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadGroup | Table | Target for UPDATE SET Name=@Name WHERE SpreadGroupID=@SpreadGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by admin/configuration tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Rename a spread group

```sql
EXEC Trade.SpreadGroupEdit @SpreadGroupID = 10, @Name = 'Premium Spreads';
```

### 8.2 Verify the rename

```sql
SELECT SpreadGroupID, Name
FROM Trade.SpreadGroup WITH (NOLOCK)
WHERE SpreadGroupID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadGroupEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadGroupEdit.sql*
