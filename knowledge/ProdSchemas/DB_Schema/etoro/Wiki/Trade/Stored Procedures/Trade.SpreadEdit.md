# Trade.SpreadEdit

> Updates the Bid and Ask values of an existing spread record in Trade.Spread.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure modifies the bid/ask prices for an existing spread definition. Spreads define the price differential applied to a specific instrument by a specific provider. When market conditions or configuration requirements change, this procedure updates only the price components (Bid and Ask) while leaving the spread's provider and instrument associations unchanged.

---

## 2. Business Logic

No complex business logic. Single-row update of Bid + Ask only; ProviderID and InstrumentID are immutable via this procedure.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadID | INTEGER | NO | - | CODE-BACKED | SpreadID of the spread record to update. Identifies the row in Trade.Spread. |
| 2 | @Bid | INTEGER | NO | - | CODE-BACKED | New bid price component (pips or basis points). Replaces the current Bid value. |
| 3 | @Ask | INTEGER | NO | - | CODE-BACKED | New ask price component (pips or basis points). Replaces the current Ask value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadID | Trade.Spread | Writer (UPDATE) | Updates Bid and Ask for the matching SpreadID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadEdit (procedure)
+-- Trade.Spread (table) [update Bid, Ask WHERE SpreadID = @SpreadID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Spread | Table | Target for UPDATE SET Bid=@Bid, Ask=@Ask WHERE SpreadID=@SpreadID |

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

### 8.1 Update spread prices

```sql
EXEC Trade.SpreadEdit @SpreadID = 42, @Bid = 3, @Ask = 3;
```

### 8.2 Verify update

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
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadEdit.sql*
