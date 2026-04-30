# BackOffice.GetFirstGameInfoPerCustomer

> Identifies each customer's first game played per game type, returning the first play date, first bet amount, and game type name for the earliest ForexResult record per (CID, GameTypeID) combination.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, GameTypeID) - composite from derived subquery |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetFirstGameInfoPerCustomer` surfaces the "first time played" data for each customer per game type from the `History.ForexResult` table. ForexResult stores game outcomes (eToro's social trading game/contest system - referred to as "forex games" or simply "games"). For each unique (CID, GameTypeID) combination, the view finds the earliest `StartDateTime` and returns the corresponding game's bet amount and game type name.

The `ROW_NUMBER()` function assigns a sequential row number per CID. This enables callers to extract just "the very first game played overall" (row 1 per CID) when needed.

`Internal.GetGameBetInCents()` is a scalar function that retrieves the bet amount in cents for a given ForexResultID.

This view powers back-office customer activity analysis: when did this customer first play, what was their first game, and how much did they bet initially.

---

## 2. Business Logic

### 2.1 First Play Detection via Correlated Subquery

**What**: For each (CID, GameTypeID) pair in History.ForexResult, finds the row where StartDateTime equals the minimum StartDateTime for that pair.

**Columns Involved**: CID, GameTypeID, StartDateTime, ForexResultID

**Rules**:
- The derived table `FirstPlayedGame` groups `History.ForexResult` by (CID, GameTypeID) and computes `MIN(StartDateTime)` per group.
- The outer query joins back to `History.ForexResult HFXR` on (CID, GameTypeID, StartDateTime = MinDate) to get the actual ForexResultID of the first play.
- `Internal.GetGameBetInCents(HFXR.ForexResultID)` retrieves the bet amount for that specific game record.
- `Dictionary.GameType` resolves GameTypeID to a name.
- `ROW_NUMBER() OVER (PARTITION BY HFXR.CID ORDER BY HFXR.CID)` - note this assigns sequential numbers within each CID, but since the ORDER BY is CID (not a tie-breaker column), the ordering between rows for the same CID is non-deterministic for customers with multiple game types.
- If a customer played multiple game types, they will have multiple rows (one per game type). The ROW_NUMBER distinguishes them but the ordering is not meaningful (same ORDER BY column as the PARTITION key).

---

## 3. Data Overview

Row count = number of distinct (CID, GameTypeID) pairs in History.ForexResult with at least one game record. Each row represents a customer's first play in a given game type.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Customer ID. From History.ForexResult.CID. |
| 2 | OrderNumber | bigint | CODE-BACKED | ROW_NUMBER() per CID (partitioned by CID, ordered by CID). Assigns a sequential number to each (CID, GameTypeID) row. Note: ordering between game types for the same customer is non-deterministic. |
| 3 | FirstPlayDate | datetime | CODE-BACKED | Earliest StartDateTime for this (CID, GameTypeID) pair. The date the customer first played this game type. |
| 4 | FirstBetAmount | int | CODE-BACKED | Bet amount in cents for the first game record, retrieved via Internal.GetGameBetInCents(ForexResultID). |
| 5 | FirstGamePlayed | nvarchar | CODE-BACKED | Display name of the game type played. From Dictionary.GameType.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, GameTypeID, StartDateTime | History.ForexResult | Base Table | Game outcome records - both outer query and MIN subquery |
| FirstBetAmount | Internal.GetGameBetInCents | Scalar Function | Returns bet amount in cents for a ForexResultID |
| FirstGamePlayed | Dictionary.GameType | INNER JOIN | Resolves GameTypeID to game name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Consumed by application layer for customer activity reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetFirstGameInfoPerCustomer (view)
+-- History.ForexResult (cross-schema)
+-- Dictionary.GameType (cross-schema)
+-- Internal.GetGameBetInCents (cross-schema scalar function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Table (cross-schema) | Base game outcome data - both outer query (first play row) and MIN subquery (earliest StartDateTime) |
| Dictionary.GameType | Table (cross-schema) | INNER JOIN - resolves GameTypeID to game name |
| Internal.GetGameBetInCents | Scalar Function (cross-schema) | Called per row to get the bet amount in cents for the first game |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on `History.ForexResult` indexes on (CID, GameTypeID, StartDateTime).

### 7.2 Constraints

N/A for View.

### 7.3 Performance Note

The view performs two full scans of `History.ForexResult` (once in the outer query, once in the MIN subquery). For large ForexResult tables, this can be expensive. A covering index on (CID, GameTypeID, StartDateTime) would significantly improve performance.

---

## 8. Sample Queries

### 8.1 Get first game info for a specific customer

```sql
SELECT CID, OrderNumber, FirstPlayDate, FirstBetAmount, FirstGamePlayed
FROM BackOffice.GetFirstGameInfoPerCustomer WITH (NOLOCK)
WHERE CID = 12345
ORDER BY FirstPlayDate;
```

### 8.2 Get the very first game a customer ever played (earliest across all game types)

```sql
SELECT TOP 1 CID, FirstPlayDate, FirstBetAmount, FirstGamePlayed
FROM BackOffice.GetFirstGameInfoPerCustomer WITH (NOLOCK)
WHERE CID = 12345
ORDER BY FirstPlayDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetFirstGameInfoPerCustomer | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetFirstGameInfoPerCustomer.sql*
