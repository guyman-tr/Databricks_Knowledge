# Trade.SpreadGroupDelete

> Deletes a spread group record from Trade.SpreadGroup by SpreadGroupID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes a spread group definition by its SpreadGroupID. Spread groups are named collections of spreads assigned to instruments or customers for pricing configuration. This is the deletion entry point for `Trade.SpreadGroup`.

Callers should ensure all spread-to-group links (`Trade.SpreadToGroup`) are removed (via `Trade.SpreadToGroupUnLink`) before calling this procedure, or rely on FK constraint enforcement.

---

## 2. Business Logic

No complex business logic. Simple single-row delete.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadGroupID | INTEGER | NO | - | CODE-BACKED | SpreadGroupID of the spread group record to delete from Trade.SpreadGroup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadGroupID | Trade.SpreadGroup | Writer (DELETE) | Deletes the spread group matching SpreadGroupID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadGroupDelete (procedure)
+-- Trade.SpreadGroup (table) [delete by SpreadGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadGroup | Table | Target for DELETE WHERE SpreadGroupID = @SpreadGroupID |

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

### 8.1 Delete a spread group

```sql
EXEC Trade.SpreadGroupDelete @SpreadGroupID = 10;
```

### 8.2 Check group membership before deletion

```sql
SELECT SpreadGroupID, SpreadID
FROM Trade.SpreadToGroup WITH (NOLOCK)
WHERE SpreadGroupID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadGroupDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadGroupDelete.sql*
