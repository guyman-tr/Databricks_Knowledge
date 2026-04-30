# Trade.SpreadDelete

> Deletes a spread record from Trade.Spread by SpreadID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the deletion entry point for `Trade.Spread` records. It removes a single spread definition by its SpreadID. The spread system defines bid/ask price differentials per instrument and provider; this procedure is called when a spread configuration is retired or replaced.

Note: No cascade logic is included - callers must ensure the SpreadID is not referenced in `Trade.SpreadToGroup` before deletion, or rely on database FK constraints to enforce this.

---

## 2. Business Logic

No complex business logic. Simple single-row delete with error code return.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadID | INTEGER | NO | - | CODE-BACKED | SpreadID of the spread record to delete from Trade.Spread. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadID | Trade.Spread | Writer (DELETE) | Deletes the spread record matching SpreadID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadDelete (procedure)
+-- Trade.Spread (table) [delete by SpreadID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Spread | Table | Target for DELETE WHERE SpreadID = @SpreadID |

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

### 8.1 Delete a spread

```sql
EXEC Trade.SpreadDelete @SpreadID = 42;
```

### 8.2 View spread before deletion

```sql
SELECT SpreadID, ProviderID, InstrumentID, Bid, Ask
FROM Trade.Spread WITH (NOLOCK)
WHERE SpreadID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadDelete.sql*
