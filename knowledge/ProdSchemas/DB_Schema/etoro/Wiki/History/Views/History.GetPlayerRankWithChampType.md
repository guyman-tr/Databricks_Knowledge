# History.GetPlayerRankWithChampType

> Championship player ranking view extended with championship type, start date, and end date - uses a CTE to RANK() players within each championship by ChampProfit DESC, then joins History.ChampionshipPlayer with Customer.Customer, Dictionary.Country, and History.Championship to provide the complete ranked leaderboard with tournament metadata.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ChampionshipID + CID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetPlayerRankWithChampType extends `History.GetPlayerRank` by adding three championship metadata columns: `ChampionshipTypeID`, `StartDateTime`, and `EndDateTime`. These allow consumers to filter or group rankings by championship type or identify which tournament was active during a date range.

The view uses a CTE to compute player ranks using `RANK() OVER (PARTITION BY ChampionshipID ORDER BY ChampProfit DESC)`, then joins the ranked players with customer details (username, country) and championship configuration (type, dates). The `TOP 100 PERCENT` with no ORDER BY is a historical SQL Server pattern used to allow ORDER BY in a non-top view (though it has no practical effect in modern SQL Server).

**Key difference from History.GetPlayerRank**: ChampionshipTypeID, StartDateTime, EndDateTime are added. These allow consumers to distinguish between different championship formats (regular vs. special tournaments) and to show tournament dates alongside the leaderboard.

---

## 2. Business Logic

### 2.1 CTE-Based Ranking

**What**: RANK() function assigns sequential rank within each championship, with ties getting the same rank.

**Columns/Parameters Involved**: `Rank`, `ChampionshipID`, `ChampProfit`

**Rules**:
```sql
WITH CTE_ChampionshipPlayer AS (
  SELECT RANK() OVER (PARTITION BY ChampionshipID ORDER BY ChampProfit DESC) AS Rank,
         ChampionshipID, ChampionshipSetupID, CID, ChampProfit, PayOff
  FROM History.ChampionshipPlayer
)
```
- RANK() (not DENSE_RANK): tied ChampProfit values receive the same rank; the next rank is skipped
- Partitioned by ChampionshipID: ranking resets for each championship
- Ordered by ChampProfit DESC: highest profit = rank 1

### 2.2 Championship Metadata (Type + Dates)

**What**: History.Championship provides ChampionshipTypeID, StartDateTime, EndDateTime per championship.

**Columns/Parameters Involved**: `ChampionshipTypeID`, `StartDateTime`, `EndDateTime`

**Rules**:
- JOIN History.Championship on ChampionshipID
- ChampionshipTypeID: classifies the championship format (regular tournament, special event, etc.) - FK to a championship type lookup
- StartDateTime/EndDateTime: the official tournament window

### 2.3 Comparison with History.GetPlayerRank

| Aspect | History.GetPlayerRank | History.GetPlayerRankWithChampType |
|--------|----------------------|------------------------------------|
| Ranking | RANK() by ChampProfit | RANK() by ChampProfit (same) |
| ChampionshipTypeID | No | Yes |
| StartDateTime | No | Yes |
| EndDateTime | No | Yes |
| Column count | 7 | 10 |
| Use case | Basic leaderboard | Leaderboard with tournament context |

---

## 3. Data Overview

One row per (ChampionshipID, CID) pair with rank. Same data as History.GetPlayerRank plus three additional columns.

| ChampionshipID | CID | CountryName | UserName | Rank | ChampProfit | PayOff | ChampionshipTypeID | StartDateTime | EndDateTime |
|--------------|-----|------------|---------|------|------------|--------|-------------------|--------------|------------|
| (varies) | (varies) | (varies) | (varies) | 1 | (highest) | (varies) | (varies) | (varies) | (varies) |

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ChampionshipID | int | NO | CODE-BACKED | Championship identifier. Partition key for RANK(). |
| 2 | ChampionshipSetupID | int | YES | CODE-BACKED | Championship setup/configuration ID from History.ChampionshipPlayer. |
| 3 | CID | int | NO | CODE-BACKED | Customer ID. |
| 4 | CountryName | varchar | YES | CODE-BACKED | Dictionary.Country.Name resolved from Customer.Customer.CountryID. |
| 5 | UserName | varchar | YES | CODE-BACKED | Customer.Customer.UserName - player's display name. |
| 6 | Rank | bigint | NO | CODE-BACKED | RANK() OVER (PARTITION BY ChampionshipID ORDER BY ChampProfit DESC). 1 = highest scorer. Tied scores receive the same rank. |
| 7 | ChampProfit | int | YES | CODE-BACKED | CAST(ChampProfit*100 AS INTEGER) - championship profit in cents. The ranking key. |
| 8 | PayOff | money | YES | CODE-BACKED | Tournament prize payout for this player's rank. |
| 9 | ChampionshipTypeID | int | YES | CODE-BACKED | History.Championship.ChampionshipTypeID - classifies the tournament format. |
| 10 | StartDateTime | datetime | YES | CODE-BACKED | History.Championship.StartDateTime - tournament start. |
| 11 | EndDateTime | datetime | YES | CODE-BACKED | History.Championship.EndDateTime - tournament end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (player data) | History.ChampionshipPlayer | CTE source | Player results per championship |
| CID | Customer.Customer | JOIN | Username and country |
| CountryID | Dictionary.Country | JOIN | Country name |
| ChampionshipID | History.Championship | JOIN (subquery) | Championship type and dates |

### 5.2 Referenced By (other objects point to this)

No SQL procedure consumers found in SSDT codebase. The view is likely consumed directly by SSRS reports or BI tools for championship leaderboard displays.

---

## 6. Dependencies

```
History.GetPlayerRankWithChampType (view)
|- History.ChampionshipPlayer (table - player results)
|- Customer.Customer (table - cross-schema)
|- Dictionary.Country (table - cross-schema)
+- History.Championship (table - tournament configuration)
```

---

## 8. Sample Queries

### 8.1 Get top 10 players for a championship with tournament context
```sql
SELECT TOP 10
    gpwct.Rank,
    gpwct.UserName,
    gpwct.CountryName,
    gpwct.ChampProfit,
    gpwct.PayOff,
    gpwct.ChampionshipTypeID,
    gpwct.StartDateTime,
    gpwct.EndDateTime
FROM History.GetPlayerRankWithChampType gpwct WITH (NOLOCK)
WHERE gpwct.ChampionshipID = @ChampionshipID
ORDER BY gpwct.Rank;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.GetPlayerRankWithChampType.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPlayerRankWithChampType | Type: View | Source: etoro/etoro/History/Views/History.GetPlayerRankWithChampType.sql*
