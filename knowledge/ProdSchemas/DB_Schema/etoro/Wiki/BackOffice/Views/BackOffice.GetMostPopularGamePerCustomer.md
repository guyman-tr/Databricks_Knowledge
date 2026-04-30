# BackOffice.GetMostPopularGamePerCustomer

> Returns each customer's most-played game type(s) by name and total play count, surfacing the top-ranked game from the popularity ranking.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID - one row per customer (or one per tied top game) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetMostPopularGamePerCustomer` distills the full game popularity ranking (from `BackOffice.GetGamePopularityPerCustomer`) down to just the single most-played game type for each customer. It joins to `Dictionary.GameType` to resolve the game type name and uses `CLR.Concatenate` to handle tie cases where a customer has two game types equally at Place=1.

This view answers the question: "What game does this customer play the most, and how many times have they played it?" It is used by `BackOffice.JUNK_GetCustomerAggregations` as part of a broader legacy customer profile aggregation.

The data originates from `History.ForexResult` (via `BackOffice.GetGamePopularityPerCustomer`). The overwhelming majority of customers show `MostPopularGame = "eToro Trading"` (GameTypeID=34), reflecting that the platform's primary product - standard eToro trading - accounts for most game-type activity in the history tables.

---

## 2. Business Logic

### 2.1 Most Popular Game Selection (Place=1 Filter)

**What**: Filters the full popularity ranking to only the top-ranked game type per customer, then resolves the name.

**Columns/Parameters Involved**: `CID`, `MostPopularGame`, `TotalGames`

**Rules**:
- `WHERE BGPC.Place = 1` selects only the most-played game type(s) per customer from the base view
- `CLR.Concatenate(Name)` handles tie cases: if two game types share the same TotalGames count (both at Place=1), their names are concatenated (e.g., "eToro Trading,Horse Race")
- GROUP BY (CID, TotalGames) collapses tied game types into a single row per customer
- TotalGames is the play count for the top-ranked game (or tied games - they all share the same count since they're tied at Place=1)

**Diagram**:
```
BackOffice.GetGamePopularityPerCustomer (all game types ranked per customer)
         |
    WHERE Place = 1  (keep only top-ranked game type(s))
         |
         v
Join Dictionary.GameType on GameTypeID --> resolve Name
         |
    CLR.Concatenate(Name) + GROUP BY (CID, TotalGames)
         |  (handles ties: multiple game types at Place=1 get concatenated)
         v
BackOffice.GetMostPopularGamePerCustomer
  CID=500136 | MostPopularGame="eToro Trading" | TotalGames=1
```

---

## 3. Data Overview

| CID | MostPopularGame | TotalGames | Meaning |
|-----|-----------------|------------|---------|
| -1 | eToro Trading | 1 | System/test account with one eToro Trading game recorded |
| 500136 | eToro Trading | 1 | Customer whose only game activity is a single eToro Trading session |
| 1507456 | eToro Trading | 1 | Another customer with exactly one eToro Trading play recorded |
| 1131143 | eToro Trading | 2 | Customer who has played eToro Trading twice - their most frequent game type |
| 2575684 | eToro Trading | 2 | Customer with two eToro Trading plays as their peak game activity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | (from BackOffice.GetGamePopularityPerCustomer) | NO | - | CODE-BACKED | Customer identifier. One row per customer in the typical case (or one per tie group). Groups and partitions the popularity ranking from the base view. |
| 2 | MostPopularGame | NVARCHAR (CLR aggregate result) | YES | - | VERIFIED | Name(s) of the game type(s) the customer has played most frequently. Resolved from `Dictionary.GameType.Name` via GameTypeID join. In tie cases (multiple game types at the same max TotalGames), names are concatenated with `CLR.Concatenate`. Common values: "eToro Trading" (GameTypeID=34, the dominant game type), "Horse Race" (1), "Forex Marathon" (3), "Globe Trader" (31). See GameType values below. |
| 3 | TotalGames | INT (from BackOffice.GetGamePopularityPerCustomer) | NO | - | CODE-BACKED | Total number of games played for this customer's most popular game type. Carried forward from `BackOffice.GetGamePopularityPerCustomer.TotalGames` where Place=1. In tie cases all tied game types share the same TotalGames count (that is why they tied). |

**Dictionary.GameType values** (for MostPopularGame resolution):

| GameTypeID | Name | SubTypeID |
|------------|------|-----------|
| 0 | NULL | 0 |
| 1 | Horse Race | 1 |
| 2 | Car Race | 1 |
| 3 | Forex Marathon | 1 |
| 4 | Dollar Trend | 7 |
| 11 | Slot | 2 |
| 21 | Poker | 3 |
| 31 | Globe Trader | 4 |
| 32 | IB Trades | 8 |
| 33 | Trade Box | 5 |
| 34 | eToro Trading | 10 |
| 41 | Race Pro | 5 |
| 51 | Forex Charts | 6 |
| 52 | Forex Charts | 9 |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, TotalGames, Place | BackOffice.GetGamePopularityPerCustomer | Source (Filter: Place=1) | Provides the ranked game popularity per customer; this view keeps only the top-ranked row(s). |
| GameTypeID (implicit) | Dictionary.GameType | Lookup (INNER JOIN via implicit syntax) | Resolves GameTypeID to the human-readable game name for the MostPopularGame output column. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_GetCustomerAggregations | BackOffice.GetMostPopularGamePerCustomer | JOIN | Legacy customer aggregation view joins this to include most-popular-game data in the customer profile. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMostPopularGamePerCustomer (view)
├── BackOffice.GetGamePopularityPerCustomer (view)
│     └── History.ForexResult (cross-schema table)
└── Dictionary.GameType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetGamePopularityPerCustomer | View | FROM clause (alias BGPC) - filtered to Place=1 to get most-popular game type(s) per customer |
| Dictionary.GameType | Table | FROM clause (alias DGMT) - joined on GameTypeID to resolve game name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_GetCustomerAggregations | View | READER - includes most-popular-game data in legacy customer profile aggregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: implicit INNER JOIN via old-style comma syntax - managers with no matching GameType are excluded. WHERE Place=1 restricts to top-ranked game.

---

## 8. Sample Queries

### 8.1 Get the most popular game for a specific customer

```sql
SELECT CID, MostPopularGame, TotalGames
FROM BackOffice.GetMostPopularGamePerCustomer WITH (NOLOCK)
WHERE CID = 123456
```

### 8.2 Find all customers whose most popular game is eToro Trading

```sql
SELECT CID, TotalGames
FROM BackOffice.GetMostPopularGamePerCustomer WITH (NOLOCK)
WHERE MostPopularGame = 'eToro Trading'
ORDER BY TotalGames DESC
```

### 8.3 Count customers per most-popular game type

```sql
SELECT MostPopularGame, COUNT(*) AS CustomerCount, AVG(TotalGames) AS AvgPlays
FROM BackOffice.GetMostPopularGamePerCustomer WITH (NOLOCK)
GROUP BY MostPopularGame
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMostPopularGamePerCustomer | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetMostPopularGamePerCustomer.sql*
