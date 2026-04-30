# Customer.GetGameWithTrade

> Legacy game session view: joins the Game.ForexGame and Game.ForexResult tables with Dictionary.Duration to present forex game sessions with their duration settings and the (now-always-zero) game credit value.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | ForexResultID (from Game.ForexResult) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetGameWithTrade joins three cross-schema objects to present a denormalized view of forex game sessions: Game.ForexResult (one row per game result/session), Game.ForexGame (game configuration - server, currency, duration), and Dictionary.Duration (duration interval metadata). The result gives consumers the complete game session context - which game, how long it runs, the currency, and the bet value - in a single row.

The name "WithTrade" suggests this was intended to correlate game sessions with real trading activity, but in practice the view returns ALL game sessions regardless of whether they have corresponding Trade.Position records. Customer.GetSessionWithTrade is the variant that actually filters for sessions linked to real trades.

The GameCredit column (calculated by Internal.GetGameBetInCents) always returns 0 - the function body was stubbed out, commenting out the actual Trade.Position/History.Position sum logic. This means the credit calculation is effectively disabled; the view is a legacy artifact of the early eToro game-trading hybrid model.

---

## 2. Business Logic

### 2.1 Disabled Game Credit Calculation

**What**: Internal.GetGameBetInCents is called per row but always returns 0 - the actual calculation (SUM of Position.Amount * 100) is commented out.

**Columns/Parameters Involved**: `GameCredit`

**Rules**:
- Internal.GetGameBetInCents(@ForexResultID) RETURN(0) - the body is a stub returning 0
- Original logic (commented out): SUM(Amount*100) from Trade.Position + History.Position WHERE ForexResultID = @ForexResultID
- The calculation was disabled (presumably performance concern or decommission) by replacing the body with RETURN(0)
- All rows will have GameCredit=0 regardless of actual position amounts

---

## 3. Data Overview

N/A - Game.ForexGame and Game.ForexResult tables are likely empty or have minimal data in this environment. The view structure is more meaningful than the data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexResultID | bigint | NO | - | VERIFIED | Unique identifier for this game session/result. From Game.ForexResult. PK of the result set. |
| 2 | CID | int | NO | - | VERIFIED | Customer identifier who played this game session. From Game.ForexResult. Links to Customer.CustomerStatic. |
| 3 | GameServerID | int | NO | - | CODE-BACKED | Game server that ran this session. From Game.ForexGame. Identifies which trading game server hosted the game. |
| 4 | ForexGameID | int | NO | - | VERIFIED | Game configuration identifier. From Game.ForexGame. Determines the currency pair, duration, and rules for this session. |
| 5 | GameTypeID | int | NO | - | CODE-BACKED | Type of game played. From Game.ForexResult. Implicit FK to a game type dictionary. |
| 6 | GameCredit | int | YES | - | VERIFIED | Bet value in cents for this game session. Always 0 - Internal.GetGameBetInCents is disabled (RETURN(0)). Originally computed as SUM(Position.Amount*100) from Trade.Position + History.Position. |
| 7 | PrimaryCurrencyID | int | NO | - | CODE-BACKED | Primary currency for the game (e.g., EUR/USD direction). From Game.ForexGame. FK to Dictionary.Currency. |
| 8 | CurrencySet | varchar | YES | - | CODE-BACKED | Set of currencies available in this game configuration. From Game.ForexGame. |
| 9 | Interval | int | NO | - | CODE-BACKED | Duration interval in minutes (or seconds). From Dictionary.Duration. Specifies how long each game session lasts. |
| 10 | IsFixDuration | bit | NO | - | CODE-BACKED | Whether the duration is fixed or variable. From Dictionary.Duration. 1=fixed-length sessions; 0=variable. |
| 11 | PrimaryCurrencyDirection | int | NO | - | CODE-BACKED | CAST(ForexResult.PrimaryCurrencyDirection AS INTEGER). Direction of the primary currency (buy/sell: 1=buy, -1 or 2=sell). From Game.ForexResult. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Game.ForexResult | FROM (base table) | Core game session results |
| - | Game.ForexGame | INNER JOIN via ForexGameID | Game configuration (server, currency, duration) |
| - | Dictionary.Duration | INNER JOIN via DurationID | Duration interval and type metadata |
| - | Internal.GetGameBetInCents | Function call | Disabled bet-in-cents calculator (always returns 0) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetGameWithTrade (view)
├── Game.ForexResult (table)
├── Game.ForexGame (table)
├── Dictionary.Duration (table)
└── Internal.GetGameBetInCents (function) [disabled - returns 0]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Game.ForexResult | Table | FROM - game session results |
| Game.ForexGame | Table | JOIN via ForexGameID - game config |
| Dictionary.Duration | Table | JOIN via DurationID - interval metadata |
| Internal.GetGameBetInCents | Scalar Function | Called per row for GameCredit (always returns 0) |

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

### 8.1 Get all game sessions with duration details
```sql
SELECT
    g.ForexResultID,
    g.CID,
    g.ForexGameID,
    g.GameTypeID,
    g.PrimaryCurrencyID,
    g.Interval,
    g.IsFixDuration,
    g.PrimaryCurrencyDirection
FROM Customer.GetGameWithTrade g WITH (NOLOCK)
ORDER BY g.ForexResultID DESC;
```

### 8.2 Get game sessions for a specific customer
```sql
SELECT *
FROM Customer.GetGameWithTrade WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Difference between GetGameWithTrade and GetSessionWithTrade
```sql
-- GetGameWithTrade: all game sessions
-- GetSessionWithTrade: only game sessions with linked Trade.Position or Trade.Orders
-- Compare counts to understand how many sessions also generated real trades
SELECT 'GetGameWithTrade' AS ViewName, COUNT(*) AS RowCount FROM Customer.GetGameWithTrade WITH (NOLOCK)
UNION ALL
SELECT 'GetSessionWithTrade', COUNT(*) FROM Customer.GetSessionWithTrade WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8.2/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetGameWithTrade | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetGameWithTrade.sql*
