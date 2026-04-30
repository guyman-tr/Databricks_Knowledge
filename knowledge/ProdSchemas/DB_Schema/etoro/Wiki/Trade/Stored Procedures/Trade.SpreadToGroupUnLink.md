# Trade.SpreadToGroupUnLink

> Removes the membership link between a specific spread and a spread group by deleting the row from Trade.SpreadToGroup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadGroupID, @SpreadID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the inverse of `Trade.SpreadToGroupLink`. It removes a spread from a spread group's membership by deleting the junction row from `Trade.SpreadToGroup`. After this call, the spread continues to exist in `Trade.Spread` but is no longer associated with the specified group.

This operation is used when reconfiguring group membership - e.g., removing an obsolete spread from a group before replacing it with a new definition.

---

## 2. Business Logic

No complex business logic. Simple junction table DELETE on composite key.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadGroupID | INTEGER | NO | - | CODE-BACKED | The spread group to remove the spread from. Part of the composite key in Trade.SpreadToGroup. |
| 2 | @SpreadID | INTEGER | NO | - | CODE-BACKED | The spread to remove from the group. Part of the composite key in Trade.SpreadToGroup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadGroupID, SpreadID | Trade.SpreadToGroup | Writer (DELETE) | Removes the spread-group membership record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadToGroupUnLink (procedure)
+-- Trade.SpreadToGroup (table) [delete WHERE SpreadGroupID=@SpreadGroupID AND SpreadID=@SpreadID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadToGroup | Table | Target for DELETE to remove spread-group membership |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by admin/configuration tooling; complement to Trade.SpreadToGroupLink |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a spread from a group

```sql
EXEC Trade.SpreadToGroupUnLink @SpreadGroupID = 10, @SpreadID = 42;
```

### 8.2 Verify removal

```sql
SELECT COUNT(*) AS StillLinked
FROM Trade.SpreadToGroup WITH (NOLOCK)
WHERE SpreadGroupID = 10 AND SpreadID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadToGroupUnLink | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadToGroupUnLink.sql*
