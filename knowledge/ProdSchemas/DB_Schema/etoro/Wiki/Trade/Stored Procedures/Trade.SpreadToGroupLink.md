# Trade.SpreadToGroupLink

> Creates a membership link between a spread and a spread group by inserting a row into Trade.SpreadToGroup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadGroupID, @SpreadID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Spreads and spread groups have a many-to-many relationship managed through `Trade.SpreadToGroup`. This procedure creates the association between a specific spread and a specific group. Once linked, the spread's bid/ask configuration becomes part of that group's definition, and any instrument or customer assigned to that group will use these spreads for pricing.

The typical workflow is:
1. Create a spread group via `Trade.SpreadGroupAdd`
2. Create individual spreads via `Trade.SpreadAdd`
3. Link spreads to the group via this procedure (`Trade.SpreadToGroupLink`)

---

## 2. Business Logic

No complex business logic. Simple junction table INSERT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadGroupID | INTEGER | NO | - | CODE-BACKED | The spread group to add the spread to. FK to Trade.SpreadGroup. |
| 2 | @SpreadID | INTEGER | NO | - | CODE-BACKED | The spread to add to the group. FK to Trade.Spread. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadGroupID, SpreadID | Trade.SpreadToGroup | Writer | Inserts junction row linking spread to group |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadToGroupLink (procedure)
+-- Trade.SpreadToGroup (table) [insert (SpreadGroupID, SpreadID)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadToGroup | Table | Target for INSERT to create spread-group membership |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by admin/configuration tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None (FK constraints on Trade.SpreadToGroup enforce referential integrity).

---

## 8. Sample Queries

### 8.1 Link a spread to a group

```sql
EXEC Trade.SpreadToGroupLink @SpreadGroupID = 10, @SpreadID = 42;
```

### 8.2 View all spreads in a group

```sql
SELECT stg.SpreadGroupID, stg.SpreadID, s.ProviderID, s.InstrumentID, s.Bid, s.Ask
FROM Trade.SpreadToGroup stg WITH (NOLOCK)
INNER JOIN Trade.Spread s WITH (NOLOCK) ON s.SpreadID = stg.SpreadID
WHERE stg.SpreadGroupID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadToGroupLink | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadToGroupLink.sql*
