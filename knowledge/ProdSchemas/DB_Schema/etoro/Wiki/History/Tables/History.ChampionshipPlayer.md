# History.ChampionshipPlayer

> Participation and performance record for every player in every trading championship - one row per (customer, championship), recording profit, volume, game count, winning position, and prize payout.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CID, ChampionshipID) - composite PK CLUSTERED |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | 3 (1 PK clustered + 2 nonclustered), FILLFACTOR=90, on [HISTORY] filegroup |

---

## 1. Business Meaning

History.ChampionshipPlayer is the player participation and results table for eToro's trading championship feature. Each row records one customer's final performance in one championship. When a customer registers for a championship and competes, their metrics (profit, lot count, volume, game count, winning positions, payout) accumulate here.

The table links to History.Championship (the championship definition) and to Customer.CustomerStatic (the player identity). ChampionshipSetupID provides an additional link to Championship.Championship - the setup template from which the championship was launched, enabling queries against setup configuration even without going through History.Championship.

1,026,326 rows across 250 distinct championships and 444,802 distinct players. Average ~4,100 players per championship. This is legacy data from eToro's gaming era (pre-2013); the championship/game feature has been inactive for many years.

---

## 2. Business Logic

### 2.1 Player Performance Accumulation

**What**: Records the cumulative performance of one player in one championship.

**Columns/Parameters Involved**: `ChampProfit`, `LotCountDecimal`, `Volume`, `GameCount`, `WinPos`, `PayOff`

**Rules**:
- One row per (CID, ChampionshipID) - unique by PK
- ChampProfit = total profit earned in championship play (money type, in USD or game credits)
- LotCountDecimal = total lots traded (decimal precision up to 6 decimal places)
- Volume = LotCountDecimal * 1000 (bigint); represents volume in micro-lots or a scaled base unit
- GameCount = number of game rounds played (0 for many players - may be 0 for direct trading game types that don't count discrete "games")
- WinPos = the player's winning rank position (1=1st place, 2=2nd place, etc.)
- PayOff = prize amount awarded (money); derived from the championship's WinPayoff prize tier list at WinPos rank

### 2.2 Prize Payout

**What**: PayOff records the prize paid to the player based on their ranking position.

**Rules**:
- PayOff corresponds to the prize at the player's WinPos rank in the championship's WinPayoff prize list (comma-separated in History.Championship.WinPayoff)
- PayOff=0 or NULL for players who did not place in prize ranks
- Observed top payoffs: 3000, 1000, 750, 500 (in game credits/USD depending on championship)

### 2.3 ChampionshipSetupID Redundancy

ChampionshipSetupID is denormalized here from History.Championship.ChampionshipSetupID. It enables joining directly to Championship.Championship setup configuration without an intermediate join to History.Championship. DEFAULT=0 (used when no specific setup template).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 1,026,326 |
| **Distinct Championships** | 250 (ChampionshipID 1-270) |
| **Distinct Players** | 444,802 |
| **Avg Players/Championship** | ~4,100 |

Sample (top ChampProfit):

| CID | ChampionshipID | ChampionshipSetupID | ChampProfit | LotCountDecimal | Volume | GameCount | PayOff | WinPos |
|-----|---------------|--------------------|-----------:|----------------:|-------:|----------:|-------:|-------:|
| 616181 | 204 | 9 | 273,121.14 | 13,000 | 13,000,000 | 0 | 3,000 | 1 |
| 616181 | 246 | 9 | 208,383.94 | 37,500 | 37,500,000 | 0 | 1,000 | 1 |
| 759378 | 246 | 9 | 187,943.00 | 320,430 | 320,430,000 | 0 | 750 | 2 |
| 142704 | 27 | 9 | 182,121.20 | 97,600 | 97,600,000 | 245 | 500 | 1 |

Note: GameCount=0 for many top players - this is expected for game types where individual "game count" is not tracked (direct trading championships vs discrete game rounds).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. FK to Customer.CustomerStatic(CID). The player who participated in the championship. PK component. |
| 2 | ChampionshipID | int | NO | - | VERIFIED | Identifies which championship the player participated in. FK to History.Championship(ChampionshipID). PK component. Range: 1-270. |
| 3 | ChampionshipSetupID | int | NO | 0 | VERIFIED | ID of the championship setup template used. FK to Championship.Championship(ChampionshipSetupID). Denormalized from History.Championship for direct query access. DEFAULT=0 (no template). |
| 4 | ChampProfit | money | NO | - | VERIFIED | Total profit earned by the player during this championship. In game credits or USD depending on championship type. Top observed value: 273,121 (CID 616181, championship 204). |
| 5 | LotCountDecimal | decimal(16,6) | YES | - | VERIFIED | Total lots traded by the player during the championship. High precision (6 decimal places) to handle fractional lot sizes. Volume = LotCountDecimal * 1000. |
| 6 | Volume | bigint | NO | - | VERIFIED | Total trading volume in scaled units (LotCountDecimal * 1000). Stored as bigint to accommodate large values (up to 320 billion observed). Used for leaderboard and ranking calculations. |
| 7 | GameCount | int | NO | - | CODE-BACKED | Number of individual game rounds played. Value is 0 for direct-trading championship types that do not use discrete game rounds (most top players). Non-zero for game types like Horse Race, Poker, etc. |
| 8 | PayOff | money | NO | - | VERIFIED | Prize amount awarded to this player. Derived from History.Championship.WinPayoff at WinPos rank. 0 for non-prize-winning players. Observed top values: 3000, 1000, 750, 500. |
| 9 | WinPos | int | NO | - | VERIFIED | The player's final ranking position in the championship. 1=1st place, 2=2nd place, etc. Used to look up PayOff from WinPayoff prize list. 0 for unranked players. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_HCPL) | Player identity. Each player must be a registered customer. |
| ChampionshipSetupID | Championship.Championship | FK (FK_CCMP_HCPL) | Championship setup template. Denormalized for direct access. |
| ChampionshipID | History.Championship | Implicit (no FK constraint) | The championship this player participated in. Links via shared ChampionshipID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetChampionshipInfo | View | Reader | Queries player performance and rankings for championship display. |
| History.GetChampionshipInfoWithChampType | View | Reader | Extended championship info with ChampionshipType dimension. |
| History.GetPlayerRank | View | Reader | Derives per-player ranking from this table. |
| History.GetPlayerRankWithChampType | View | Reader | Extended player ranking with championship type dimension. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ChampionshipPlayer (table)
  -> Customer.CustomerStatic (FK, external)
  -> Championship.Championship (FK, external)
  -> History.Championship (implicit, same ChampionshipID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table (external) | FK_CCST_HCPL - validates player CID |
| Championship.Championship | Table (external) | FK_CCMP_HCPL - validates ChampionshipSetupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetChampionshipInfo | View | Reads player performance for championship display |
| History.GetChampionshipInfoWithChampType | View | Extended championship info |
| History.GetPlayerRank | View | Derives player rankings |
| History.GetPlayerRankWithChampType | View | Extended player rankings with type |
| History.GuruCopiers | Table | May reference championship player data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Options |
|-----------|------|-------------|-----------------|--------|---------|
| PK_HCHP | CLUSTERED PK | CID ASC, ChampionshipID ASC | - | - | FILLFACTOR=90, on [HISTORY] |
| HCHP_CHAMPIONSHIP | NONCLUSTERED | ChampionshipSetupID ASC | - | - | FILLFACTOR=90, on [HISTORY] |
| HCPL_CHAMPIONSHIP | NONCLUSTERED | ChampionshipID ASC, ChampProfit DESC | ChampionshipSetupID, PayOff | - | FILLFACTOR=90, on [HISTORY] |

The HCPL_CHAMPIONSHIP index is designed for leaderboard queries: given a ChampionshipID, fetch top players by ChampProfit descending, returning ChampionshipSetupID and PayOff from the covering INCLUDE columns without a lookup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCHP | PRIMARY KEY CLUSTERED | (CID, ChampionshipID), FILLFACTOR=90 |
| FK_CCMP_HCPL | FOREIGN KEY | ChampionshipSetupID -> Championship.Championship(ChampionshipSetupID) |
| FK_CCST_HCPL | FOREIGN KEY | CID -> Customer.CustomerStatic(CID) |
| HCHP_NULLCHAMPIONSHIPSETUP | DEFAULT | ChampionshipSetupID = 0 |

---

## 8. Sample Queries

### 8.1 Get leaderboard for a championship
```sql
SELECT cp.CID, cp.ChampProfit, cp.WinPos, cp.PayOff, cp.LotCountDecimal, cp.GameCount
FROM History.ChampionshipPlayer cp WITH (NOLOCK)
WHERE cp.ChampionshipID = 270
ORDER BY cp.ChampProfit DESC;
```

### 8.2 Get all championships a player participated in with results
```sql
SELECT cp.ChampionshipID, ch.StartDateTime, ch.EndDateTime,
       cp.ChampProfit, cp.WinPos, cp.PayOff
FROM History.ChampionshipPlayer cp WITH (NOLOCK)
INNER JOIN History.Championship ch WITH (NOLOCK) ON cp.ChampionshipID = ch.ChampionshipID
WHERE cp.CID = 616181
ORDER BY ch.StartDateTime DESC;
```

### 8.3 Top earners across all championships
```sql
SELECT TOP 20 cp.CID, SUM(cp.PayOff) AS TotalPayOff, SUM(cp.ChampProfit) AS TotalChampProfit,
              COUNT(*) AS ChampionshipsEntered, COUNT(CASE WHEN cp.WinPos = 1 THEN 1 END) AS FirstPlaceWins
FROM History.ChampionshipPlayer cp WITH (NOLOCK)
GROUP BY cp.CID
ORDER BY TotalPayOff DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object. For championship system context, see History.Championship documentation.

---

*Generated: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence (relevant) | Procedures: 0 + 4 views identified | App Code: not scanned*
*Object: History.ChampionshipPlayer | Type: Table | Source: etoro/etoro/History/Tables/History.ChampionshipPlayer.sql*
