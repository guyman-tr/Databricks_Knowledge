# History.GetPlayerRank

> Championship leaderboard view - ranks prize-winning players within each trading championship by profit performance, enriched with country and username from the customer profile.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | (ChampionshipID, Rank) - window function rank per championship |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

History.GetPlayerRank is the trading championship leaderboard view. It filters to only players who received a prize payout (PayOff != 0) and ranks them within each championship by their total championship profit, highest first. It enriches the raw player data from `History.ChampionshipPlayer` with the player's username and country name by joining to `Customer.Customer` and `Dictionary.Country`.

The view provides a human-readable ranked leaderboard: "who won championship X, in what place, from which country, with what profit and prize?" This was the primary data source for displaying championship results to users and administrators during the gaming platform era (2012 data only; gaming feature is now inactive).

Two computed transformations are applied: `RANK()` assigns the competitive rank using window function logic (tied profits would receive the same rank, with username as tiebreaker), and `ChampProfit` is scaled by *100 and cast to INTEGER (converting the money-type profit to an integer representing 100ths of the original value - effectively game credits scaled for display without decimal points).

No procedures in the current codebase reference this view. It is used as a base by `History.GetPlayerRankWithChampType` which adds championship type and title metadata.

---

## 2. Business Logic

### 2.1 Prize Winners Filter

**What**: Only players who received a payout are included - non-placing participants are excluded.

**Columns/Parameters Involved**: `PayOff`

**Rules**:
- WHERE PayOff != 0 filters out players with no prize (the majority of ~4,100 average players per championship)
- PayOff values observed: 1000, 750, 500, 300 (top prize tiers from History.Championship.WinPayoff)
- The filter means this is a "winners podium" view, not a complete player participation view

### 2.2 Profit-Based Ranking (RANK Window Function)

**What**: RANK() partitions per championship and orders by profit descending.

**Columns/Parameters Involved**: `Rank`, `ChampProfit`, `UserName`

**Rules**:
- RANK() OVER (PARTITION BY ChampionshipID ORDER BY ChampProfit DESC, UserName ASC)
- Ties in ChampProfit are broken alphabetically by UserName (ensuring deterministic ranking)
- RANK() leaves gaps for ties (if two players tie for 1st, next is 3rd); dense rank is not used
- Rank 1 = highest profit winner; within the PayOff != 0 filter set, ranks correspond to prize tier positions

### 2.3 ChampProfit Scaling

**What**: ChampProfit is multiplied by 100 and cast to INTEGER, converting the money-type value to a scaled integer.

**Columns/Parameters Involved**: `ChampProfit`

**Rules**:
- Formula: CAST(HCPL.ChampProfit * 100 AS INTEGER)
- Live data example: Rank 1 shows ChampProfit = 2290000, meaning the base table value = 22,900.00 (money)
- The *100 scale converts to an integer representing "hundred-ths" (game credits in smallest unit), enabling display without decimal handling
- This is a presentation-layer transformation for UI/API consumption

**Diagram**:
```
History.ChampionshipPlayer.ChampProfit (money) = 22900.00
    |
    | CAST(ChampProfit * 100 AS INTEGER)
    v
History.GetPlayerRank.ChampProfit (int) = 2290000
    (= 22,900 game credits in 1/100 unit display)
```

---

## 3. Data Overview

| ChampionshipID | CID | CountryName | UserName | Rank | ChampProfit | PayOff |
|---|---|---|---|---|---|---|
| 270 | 1097028 | Australia | Streetr | 1 | 2290000 | 1000 | First place in championship 270 (Feb-Mar 2012). Australian player "Streetr" achieved the highest profit (22,900 scaled game credits). Prize: $1,000. Rank 1 by highest ChampProfit. |
| 270 | 322082 | Belgium | karimderras | 2 | 1715000 | 750 | Second place, Belgian player. ChampProfit=17,150 (scaled). $750 prize. ~25% lower profit than first place. |
| 270 | 1505068 | India | muthubinil | 3 | 1649000 | 500 | Third place, Indian player. $500 prize. Global player base across Australia, Belgium, India, Italy, Kuwait in just the top 5 rows - confirming the international reach of the championship feature. |
| 270 | 1674813 | Italy | Nucchia | 4 | 1542888 | 300 | Fourth place, Italian player. $300 prize (shared prize tier - see rank 5 also has $300). |
| 270 | 1297094 | Kuwait | magedomar | 5 | 1418840 | 300 | Fifth place, Kuwaiti player. $300 prize at same tier as Rank 4 - confirms prize structure has two players on the $300 tier. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipID | int | NO | - | VERIFIED | The championship this player ranked in. Partition key for the RANK() window function. FK to History.Championship (implicit). From History.ChampionshipPlayer. |
| 2 | ChampionshipSetupID | int | NO | 0 | VERIFIED | ID of the setup template (Championship.Championship) used for this championship. Denormalized from History.Championship for direct setup lookups. From History.ChampionshipPlayer. |
| 3 | CID | int | NO | - | VERIFIED | Customer ID of the player. JOIN key to Customer.Customer for username and country. |
| 4 | CountryName | nvarchar (from Dictionary.Country) | YES | - | VERIFIED | Player's registered country name, joined from Dictionary.Country via Customer.Customer.CountryID. Provides geographic context for leaderboards. |
| 5 | UserName | nvarchar (from Customer.Customer) | YES | - | VERIFIED | Player's eToro username from Customer.Customer. Used as tiebreaker in RANK() ordering (alphabetical ascending when ChampProfit is tied) and for display purposes. |
| 6 | Rank | bigint (RANK() result) | NO | - | VERIFIED | Competitive rank within the championship (1=1st place/highest profit). Computed by RANK() OVER (PARTITION BY ChampionshipID ORDER BY ChampProfit DESC, UserName ASC). RANK() leaves gaps for ties. Only prize-winning players (PayOff != 0) are ranked here. |
| 7 | ChampProfit | int (computed) | NO | - | VERIFIED | Player's total championship profit scaled by 100 and cast to integer: CAST(ChampProfit * 100 AS INTEGER). Converts the money-type base value to an integer for display. Live data: 2290000 = 22,900.00 original game credits. |
| 8 | PayOff | money | NO | - | VERIFIED | Prize amount awarded to the player based on their ranking. Derived from History.Championship.WinPayoff at the player's WinPos rank. Filtered: only non-zero values appear in this view (winners only). Live data: 1000, 750, 500, 300 as prize tiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | JOIN | Cross-schema join for UserName and CountryID |
| CID / ChampionshipID | History.ChampionshipPlayer | View (source) | Championship participation and profit data, filtered to PayOff != 0 |
| CountryID | Dictionary.Country | JOIN | Via Customer.Customer.CountryID for country name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetPlayerRankWithChampType | ChampionshipID | View (extends) | Adds championship type and title to this view's ranked player data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetPlayerRank (view)
├── History.ChampionshipPlayer (table - leaf)
├── Customer.Customer (table - cross-schema leaf)
└── Dictionary.Country (table - cross-schema leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ChampionshipPlayer | Table | Primary source - ChampionshipID, ChampionshipSetupID, CID, ChampProfit, PayOff; WHERE PayOff != 0 |
| Customer.Customer | Table | Cross-schema JOIN on CID for UserName and CountryID |
| Dictionary.Country | Table | Cross-schema JOIN on CountryID for CountryName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetPlayerRankWithChampType | View | Extends the ranked player list with championship type and title |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. History.ChampionshipPlayer CLUSTERED PK (CID, ChampionshipID) and NC indexes on ChampionshipID serve the PARTITION BY and JOIN. Customer.Customer and Dictionary.Country indexes handle the JOIN conditions.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get the full winners leaderboard for a specific championship
```sql
SELECT
    pr.Rank,
    pr.UserName,
    pr.CountryName,
    pr.ChampProfit / 100.0 AS ChampProfitOriginal,
    pr.ChampProfit AS ChampProfitScaled,
    pr.PayOff
FROM History.GetPlayerRank pr WITH (NOLOCK)
WHERE pr.ChampionshipID = 270
ORDER BY pr.Rank;
```

### 8.2 Find all championships a specific player won prizes in
```sql
SELECT
    pr.ChampionshipID,
    pr.ChampionshipSetupID,
    pr.Rank,
    pr.ChampProfit / 100.0 AS ChampProfitOriginal,
    pr.PayOff
FROM History.GetPlayerRank pr WITH (NOLOCK)
WHERE pr.CID = 1097028
ORDER BY pr.ChampionshipID DESC;
```

### 8.3 Top prize earners across all championships
```sql
SELECT TOP 20
    pr.CID,
    pr.UserName,
    pr.CountryName,
    COUNT(*) AS TimesOnPodium,
    SUM(pr.PayOff) AS TotalPrizeEarned,
    MIN(pr.Rank) AS BestRank
FROM History.GetPlayerRank pr WITH (NOLOCK)
GROUP BY pr.CID, pr.UserName, pr.CountryName
ORDER BY TotalPrizeEarned DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.GetPlayerRank. Business context inherited from History.ChampionshipPlayer documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPlayerRank | Type: View | Source: etoro/etoro/History/Views/History.GetPlayerRank.sql*
