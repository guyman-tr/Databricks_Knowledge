# BackOffice.DeleteUsersFromClosedChamps

> Removes a player from a closed championship and recalculates win rankings for all remaining players based on profit.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ChampionshipID + @CID - identifies the player record to remove |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DeleteUsersFromClosedChamps manages post-closure adjustments to eToro's Championship feature. Championships are competitive trading events where participants are ranked by profit (ChampProfit). When a player needs to be removed from a closed championship - for example, due to a disqualification, data correction, or appeal resolution - this procedure handles both the deletion and the immediate re-ranking of remaining players so that win positions (WinPos) are consistent and gapless.

The procedure operates exclusively on `History.ChampionshipPlayer`, which is the completed/archived championship record table (as opposed to active championship data). The re-ranking step uses `ROW_NUMBER() OVER (ORDER BY ChampProfit DESC)` to assign sequential positions starting from 1 for the highest profit, ensuring that after a player is removed, the remaining players' positions are correctly renumbered.

---

## 2. Business Logic

### 2.1 Delete Player and Re-Rank Remaining Players

**What**: Two-step transactional operation: remove one player, then recalculate WinPos for all remaining players in the championship.

**Columns/Parameters Involved**: `@ChampionshipID`, `@CID`, `History.ChampionshipPlayer.WinPos`, `History.ChampionshipPlayer.ChampProfit`

**Rules**:
- Step 1: DELETE History.ChampionshipPlayer WHERE ChampionshipID = @ChampionshipID AND CID = @CID. Removes the specific player from the championship.
- On DELETE error (@@ERROR <> 0): ROLLBACK + RETURN @@ERROR immediately.
- Step 2: UPDATE History.ChampionshipPlayer.WinPos using ROW_NUMBER() OVER (ORDER BY ChampProfit DESC) for all remaining players in the championship. Assigns sequential ranks 1,2,3,... based on descending profit.
- On UPDATE error (@@ERROR <> 0): ROLLBACK + RETURN @@ERROR.
- Both steps run inside a single BEGIN TRAN / COMMIT. Returns 0 on success.

**Diagram**:
```
BEGIN TRAN
  DELETE History.ChampionshipPlayer WHERE ChampionshipID=@ChampionshipID AND CID=@CID
  -> If error: ROLLBACK, RETURN @@ERROR

  UPDATE WinPos = ROW_NUMBER() OVER (ORDER BY ChampProfit DESC)
  for all remaining players WHERE ChampionshipID = @ChampionshipID
  -> If error: ROLLBACK, RETURN @@ERROR
COMMIT
RETURN 0
```

### 2.2 Profit-Based Win Position Calculation

**What**: WinPos is computed dynamically after each deletion, not stored permanently.

**Columns/Parameters Involved**: `History.ChampionshipPlayer.WinPos`, `History.ChampionshipPlayer.ChampProfit`

**Rules**:
- WinPos = ROW_NUMBER() OVER (ORDER BY ChampProfit DESC) - rank by profit descending, no partitioning beyond WHERE ChampionshipID = @ChampionshipID.
- WinPos is always gapless (1,2,3,4...) after recalculation - no gaps from the removed player.
- Ties in ChampProfit: ROW_NUMBER() assigns arbitrary sequential ranks (no DENSE_RANK or RANK) - tied players get distinct sequential positions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChampionshipID | INT | NO | - | CODE-BACKED | Identifies which championship to modify. Used in both the DELETE and the re-ranking UPDATE to scope all operations to a single championship. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID of the player to remove. Combined with @ChampionshipID to uniquely identify the player's championship record in History.ChampionshipPlayer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ChampionshipID + @CID | History.ChampionshipPlayer | Deleter | DELETE - removes the specific player from the championship archive. |
| @ChampionshipID | History.ChampionshipPlayer | Modifier | UPDATE WinPos - recalculates rankings for all remaining players after deletion. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Championship management | EXEC | Caller | Called when a player must be removed from a closed championship for disqualification, data correction, or appeal. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DeleteUsersFromClosedChamps (procedure)
└── History.ChampionshipPlayer (table) - DELETE + UPDATE WinPos
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ChampionshipPlayer | Table | DELETE (player removal) + UPDATE (win position recalculation via ROW_NUMBER) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Championship admin workflow | External | EXEC - administrative player removal from closed championships |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Atomic transaction | Safety | DELETE and re-ranking UPDATE are in one transaction. If re-ranking fails, deletion is rolled back - no orphaned gaps in WinPos. |
| @@ERROR check (legacy pattern) | Convention | Uses @@ERROR check + manual ROLLBACK rather than TRY/CATCH - an older error handling pattern. Error code is returned to the caller. |
| ROW_NUMBER (not DENSE_RANK) | Behavior | Tied profits get different sequential WinPos values. No tie-breaking logic in SQL - order between tied players is non-deterministic. |

---

## 8. Sample Queries

### 8.1 Remove a player from a closed championship
```sql
EXEC BackOffice.DeleteUsersFromClosedChamps @ChampionshipID = 12, @CID = 12345678
```

### 8.2 View championship rankings after removal
```sql
SELECT
    hcp.CID,
    cs.UserName,
    hcp.WinPos,
    hcp.ChampProfit
FROM History.ChampionshipPlayer hcp WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = hcp.CID
WHERE hcp.ChampionshipID = 12
ORDER BY hcp.WinPos ASC
```

### 8.3 Find all players in a closed championship with their ranks
```sql
SELECT
    hcp.ChampionshipID,
    COUNT(*) AS PlayerCount,
    MAX(hcp.WinPos) AS MaxRank,
    MAX(hcp.ChampProfit) AS TopProfit
FROM History.ChampionshipPlayer hcp WITH (NOLOCK)
WHERE hcp.ChampionshipID = 12
GROUP BY hcp.ChampionshipID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DeleteUsersFromClosedChamps | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DeleteUsersFromClosedChamps.sql*
