# Customer.GetSessionWithTrade

> Game sessions that have at least one linked real trade: filters GetGameWithTrade to only include forex game results where a corresponding Trade.Position or Trade.Orders record exists.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | ForexResultID (from Game.ForexResult) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetSessionWithTrade is the filtered counterpart to Customer.GetGameWithTrade. It returns the same columns (game session details with duration and disabled credit) but adds an EXISTS filter that restricts results to only those game sessions where at least one real Trade.Position or Trade.Orders record references the same ForexResultID. This means only sessions that "crossed over" from the game system into real trading are included.

This view captures the historical concept of eToro's game-to-real-trading bridge: customers could start in the "game" mode and their game sessions could generate real trading activity via ForexResultID. The view is a legacy artifact - the game/trade hybrid model was decommissioned and GameCredit always returns 0 (Internal.GetGameBetInCents is disabled). The EXISTS filter against Trade.Position and Trade.Orders may produce empty results in environments where the game schema has been purged.

The two EXISTS clauses create an implicit OR condition: a session qualifies if it has Trade.Position rows OR Trade.Orders rows with the matching ForexResultID.

---

## 2. Business Logic

### 2.1 Trade-Linked Game Session Filter

**What**: The view uses EXISTS subqueries against Trade.Position and Trade.Orders to filter for sessions that generated real trading activity.

**Columns/Parameters Involved**: `ForexResultID`

**Rules**:
- EXISTS(SELECT * FROM Trade.Position WHERE TPOS.ForexResultID = GFRS.ForexResultID) -> includes session if any open position links to it
- OR EXISTS(SELECT 1 FROM Trade.Orders WHERE TORD.ForexResultID = GFRS.ForexResultID) -> includes if any order links to it
- Note: Trade.Orders uses no NOLOCK hint unlike Trade.Position in the same view - possible legacy inconsistency
- The ForexResultID in Trade.Position/Orders is the bridge column linking the real trade to its originating game session

---

## 3. Data Overview

N/A - Game schema tables are likely empty or minimal in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexResultID | bigint | NO | - | VERIFIED | Game session result ID that has at least one linked Trade.Position or Trade.Orders record. From Game.ForexResult. |
| 2 | CID | int | NO | - | VERIFIED | Customer who played the game session and has real trades. From Game.ForexResult. |
| 3 | GameServerID | int | NO | - | CODE-BACKED | Game server that hosted this session. From Game.ForexGame. |
| 4 | ForexGameID | int | NO | - | VERIFIED | Game configuration identifier. From Game.ForexResult. |
| 5 | GameTypeID | int | NO | - | CODE-BACKED | Type of game played. From Game.ForexResult. |
| 6 | GameCredit | int | YES | - | VERIFIED | Always 0 - Internal.GetGameBetInCents is disabled. See Customer.GetGameWithTrade for full explanation. |
| 7 | PrimaryCurrencyID | int | NO | - | CODE-BACKED | Primary currency direction for the game. From Game.ForexGame. FK to Dictionary.Currency. |
| 8 | CurrencySet | varchar | YES | - | CODE-BACKED | Currency set available in this game. From Game.ForexGame. |
| 9 | Interval | int | NO | - | CODE-BACKED | Duration interval from Dictionary.Duration. How long each session lasts. |
| 10 | IsFixDuration | bit | NO | - | CODE-BACKED | Whether session duration is fixed. From Dictionary.Duration. |
| 11 | PrimaryCurrencyDirection | int | NO | - | CODE-BACKED | CAST of primary currency direction to INTEGER. From Game.ForexResult. Buy/sell direction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Game.ForexResult | FROM (base table) | Game session results |
| - | Game.ForexGame | INNER JOIN via ForexGameID | Game configuration |
| - | Dictionary.Duration | INNER JOIN via DurationID | Duration metadata |
| - | Internal.GetGameBetInCents | Function call | Disabled credit calculator |
| ForexResultID | Trade.Position | EXISTS subquery | Filter: session must have at least one open position |
| ForexResultID | Trade.Orders | EXISTS subquery | Filter: session must have at least one order |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetSessionWithTrade (view)
├── Game.ForexResult (table)
├── Game.ForexGame (table)
├── Dictionary.Duration (table)
├── Internal.GetGameBetInCents (function) [disabled]
├── Trade.Position (table) [EXISTS filter only]
└── Trade.Orders (table) [EXISTS filter only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Game.ForexResult | Table | FROM - game session results |
| Game.ForexGame | Table | JOIN via ForexGameID |
| Dictionary.Duration | Table | JOIN via DurationID |
| Internal.GetGameBetInCents | Scalar Function | Called per row (always returns 0) |
| Trade.Position | Table | EXISTS subquery filter |
| Trade.Orders | Table | EXISTS subquery filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Get trade-linked game sessions for a customer
```sql
SELECT *
FROM Customer.GetSessionWithTrade WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Count game sessions with real trades vs all sessions
```sql
SELECT
    'All Game Sessions' AS ViewName,
    COUNT(*) AS RowCount
FROM Customer.GetGameWithTrade WITH (NOLOCK)
UNION ALL
SELECT
    'Sessions With Real Trades',
    COUNT(*)
FROM Customer.GetSessionWithTrade WITH (NOLOCK);
```

### 8.3 Sessions by game type with trade presence
```sql
SELECT
    gst.GameTypeID,
    COUNT(*) AS SessionsWithTrades,
    COUNT(DISTINCT gst.CID) AS UniqueCustomers
FROM Customer.GetSessionWithTrade gst WITH (NOLOCK)
GROUP BY gst.GameTypeID
ORDER BY SessionsWithTrades DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8.2/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetSessionWithTrade | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetSessionWithTrade.sql*
