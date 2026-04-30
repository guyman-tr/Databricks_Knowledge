# BackOffice.GetGamePopularityPerCustomer

> Ranks each game type by play count per customer, returning total games played and a popularity rank (1=most played) for each (CID, GameTypeID) combination.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, GameTypeID) - composite from GROUP BY |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetGamePopularityPerCustomer` aggregates `History.ForexResult` to show which game types each customer has played most frequently. For each (CID, GameTypeID) pair, it counts the total number of games played and assigns a `RANK()` where Rank=1 indicates the customer's most-played game type.

This view enables personalization and analysis:
- **Most popular game per customer** (Place=1): Used for recommendations or segment analysis ("Which game does this customer play most?")
- **Full game type distribution**: All ranked rows reveal a customer's gaming breadth and engagement by game type.
- **Game type popularity** (aggregate across customers): Summing TotalGames by GameTypeID reveals platform-wide game type popularity.

---

## 2. Business Logic

### 2.1 Per-Customer Game Type Popularity Ranking

**What**: Counts game plays per (CID, GameTypeID), ranks by count descending within each customer.

**Columns Involved**: CID, GameTypeID

**Rules**:
- `GROUP BY CID, GameTypeID` computes `COUNT(*)` = total games played by this customer in this game type.
- `RANK() OVER (PARTITION BY CID ORDER BY COUNT(*) DESC)` - ranks game types from most-played (1) to least-played per customer.
- Tie handling: `RANK()` assigns the same rank to ties (e.g., if two game types both have 5 plays, both get Rank=1 and there is no Rank=2).
- All rows from History.ForexResult are included (no filter on status, date, or result).

---

## 3. Data Overview

Row count = number of distinct (CID, GameTypeID) pairs in History.ForexResult. Customers who played only one game type have one row (Place=1). Customers who played multiple types have multiple rows ranked 1 through N.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Customer ID. From History.ForexResult.CID. |
| 2 | GameTypeID | int | CODE-BACKED | Game type identifier. FK to Dictionary.GameType.GameTypeID. Identifies which type of forex game/contest this customer played. |
| 3 | Place | bigint | CODE-BACKED | Popularity rank for this game type within this customer's portfolio. 1 = most played game type. Ties share the same rank (RANK(), not DENSE_RANK()). |
| 4 | TotalGames | int | CODE-BACKED | Total number of games played by this customer in this game type (COUNT(*) from History.ForexResult). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, GameTypeID, COUNT(*) | History.ForexResult | Base Table | Source of all game result records aggregated by (CID, GameTypeID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Consumed by application layer for customer game engagement analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetGamePopularityPerCustomer (view)
+-- History.ForexResult (cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Table (cross-schema) | Sole data source - grouped and ranked |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on a `History.ForexResult` index on (CID, GameTypeID).

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get most popular game type for a customer

```sql
SELECT CID, GameTypeID, TotalGames
FROM BackOffice.GetGamePopularityPerCustomer WITH (NOLOCK)
WHERE CID = 12345
  AND Place = 1;
```

### 8.2 Get full game type breakdown for a customer

```sql
SELECT CID, GameTypeID, Place, TotalGames
FROM BackOffice.GetGamePopularityPerCustomer WITH (NOLOCK)
WHERE CID = 12345
ORDER BY Place;
```

### 8.3 Find most popular game types across all customers

```sql
SELECT GameTypeID, SUM(TotalGames) AS TotalPlays
FROM BackOffice.GetGamePopularityPerCustomer WITH (NOLOCK)
GROUP BY GameTypeID
ORDER BY TotalPlays DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetGamePopularityPerCustomer | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetGamePopularityPerCustomer.sql*
