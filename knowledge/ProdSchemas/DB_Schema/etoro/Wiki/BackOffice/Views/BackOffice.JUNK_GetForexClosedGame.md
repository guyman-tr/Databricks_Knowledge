# BackOffice.JUNK_GetForexClosedGame

> **DEPRECATED (JUNK prefix)** - Returns closed game results from History with game type name, profit totals, amount, and bet size per game session.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | ForexResultID - one row per closed game session |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_GetForexClosedGame` is a legacy view (JUNK prefix = deprecated) that joins closed `History.ForexResult` game sessions with their associated positions and game type metadata to produce a game-level profit/loss report. For each completed game session (`EndDateTime IS NOT NULL`), it sums position profits, carries the bet amount, and resolves the game name.

The view was designed to give BackOffice staff visibility into closed game performance - which game types completed, when, how much was bet and won/lost. It relies on `History.Position` and `History.ForexResult`, both in EtoroArchive, which are inaccessible via the current MCP connection. No active consumers reference this view.

---

## 2. Business Logic

### 2.1 Closed Game Filter and Profit Aggregation

**What**: Filters to completed game sessions (EndDateTime IS NOT NULL) and aggregates position profits per game.

**Columns/Parameters Involved**: `ForexResultID`, `GameProfit`, `StartDateTime`, `EndDateTime`

**Rules**:
- `WHERE EndDateTime IS NOT NULL` - only completed/closed game sessions are included
- `GameProfit = SUM(CAST(NetProfit*100 AS INTEGER))` - sum of all position net profits in cents (multiplied by 100 for integer precision), aggregated across all positions in the game via LEFT OUTER JOIN
- `Amount = CAST(HPOS.Amount*100 AS INTEGER)` - wager amount in cents; in GROUP BY so must be consistent within a game
- `Bet = Internal.GetGameBetInCents(ForexResultID)` - calls a cross-schema function for the calculated bet size in cents
- LEFT OUTER JOIN to History.Position means games with no positions still appear (GameProfit would be NULL)

---

## 3. Data Overview

*Live data not available - History.ForexResult and History.Position reference EtoroArchive database.*

| ForexResultID | Name | StartDateTime | EndDateTime | GameProfit | Amount | Bet |
|---------------|------|---------------|-------------|------------|--------|-----|
| (example) | eToro Trading | 2021-01-05 09:00 | 2021-01-05 10:00 | 5000 | 10000 | 500 |

*GameProfit and Amount are in cents (value * 100). A GameProfit of 5000 = $50.00 net profit.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexResultID | INT | NO | - | CODE-BACKED | Unique identifier of the game session (round). PK of `History.ForexResult`. Groups all positions played within the same game session. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Human-readable game type name resolved from `Dictionary.GameType.Name` via `History.ForexResult.GameTypeID`. Values include "eToro Trading", "Horse Race", "Globe Trader", etc. See Dictionary.GameType values in BackOffice.GetMostPopularGamePerCustomer. |
| 3 | StartDateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the game session started. From `History.ForexResult.StartDateTime`. |
| 4 | EndDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the game session ended. From `History.ForexResult.EndDateTime`. Always non-NULL (filter condition). |
| 5 | GameProfit | INT (computed) | YES | - | CODE-BACKED | Total net profit for this game session in cents. Computed as `SUM(CAST(NetProfit*100 AS INTEGER))` across all positions linked via ForexResultID. NULL if no positions are linked (LEFT OUTER JOIN). Divide by 100 for dollar value. |
| 6 | Amount | INT (computed) | YES | - | CODE-BACKED | Wager/bet amount for this game in cents. From `CAST(History.Position.Amount*100 AS INTEGER)`. In GROUP BY, so expected to be consistent per game. NULL if no positions linked. Divide by 100 for dollar value. |
| 7 | Bet | INT | YES | - | CODE-BACKED | Calculated bet size for this game session in cents. Computed by `Internal.GetGameBetInCents(ForexResultID)` - a cross-schema scalar function that derives the bet from the game result. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ForexResultID, GameTypeID, StartDateTime, EndDateTime | History.ForexResult | Source (cross-schema, NOLOCK) | Game session records - filtered to completed sessions (EndDateTime IS NOT NULL). |
| NetProfit, Amount | History.Position | Source (cross-schema, NOLOCK, LEFT OUTER) | Position records linked by ForexResultID - profits aggregated per game. |
| Name | Dictionary.GameType | Lookup (implicit INNER JOIN) | Resolves GameTypeID to game name. |
| Bet | Internal.GetGameBetInCents | Function call (cross-schema) | Calculates bet size in cents for each game session. |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetForexClosedGame (view) [DEPRECATED]
├── History.ForexResult (cross-schema table - EtoroArchive)
├── History.Position (cross-schema table - EtoroArchive)
├── Dictionary.GameType (table)
└── Internal.GetGameBetInCents (cross-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Cross-schema Table | FROM clause (alias HFXR, NOLOCK) - game sessions filtered to closed (EndDateTime IS NOT NULL) |
| History.Position | Cross-schema Table | LEFT OUTER JOIN (alias HPOS, NOLOCK) on ForexResultID - position profits per game |
| Dictionary.GameType | Table | Implicit INNER JOIN (alias DGMT) on GameTypeID - game name resolution |
| Internal.GetGameBetInCents | Cross-schema Function | Called in SELECT - bet size in cents per game session |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get recent closed games with profit

```sql
SELECT ForexResultID, Name, StartDateTime, EndDateTime,
       GameProfit / 100.0 AS GameProfitUSD,
       Amount / 100.0 AS AmountUSD
FROM BackOffice.JUNK_GetForexClosedGame WITH (NOLOCK)
ORDER BY EndDateTime DESC
```

### 8.2 Find most profitable game sessions by type

```sql
SELECT Name, SUM(GameProfit) / 100.0 AS TotalProfitUSD, COUNT(*) AS GameCount
FROM BackOffice.JUNK_GetForexClosedGame WITH (NOLOCK)
GROUP BY Name
ORDER BY TotalProfitUSD DESC
```

### 8.3 Get games where profit exceeded the bet

```sql
SELECT ForexResultID, Name, GameProfit / 100.0 AS ProfitUSD, Bet / 100.0 AS BetUSD
FROM BackOffice.JUNK_GetForexClosedGame WITH (NOLOCK)
WHERE GameProfit > Bet
ORDER BY GameProfit DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetForexClosedGame | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_GetForexClosedGame.sql*
