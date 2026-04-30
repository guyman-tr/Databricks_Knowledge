# History.GetForexResult

> Legacy aggregation view for completed forex game sessions (2009-2014) - joins game result, game configuration, position PnL, and customer provider context to produce one row per completed game with aggregated net profit and lot count across all positions in that game.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ForexResultID (game session, from History.ForexResult) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

`History.GetForexResult` is a read-only aggregation view for eToro's early forex game platform (active 2009-2014). It enriches each completed game session record from `History.ForexResult` with its game configuration (Game.ForexGame), aggregated position PnL and lot count from positions (via History.GetPositionWithPrimaryCurrency), the customer's liquidity provider unit (Trade.ProviderToInstrument), and two scalar function results: the game's bet in cents and the full list of instruments traded in the game.

The view only shows completed games: the WHERE clause filters `EndDateTime IS NOT NULL`, which in History.ForexResult means the game was closed via `Game.GameClose`. The underlying data covers 1,285 game sessions from 2009-09-16 to 2014-11-23 (see History.ForexResult documentation for the full dataset analysis).

This is a legacy reporting view. No stored procedures in the etoro database were found referencing it directly - it was likely consumed by external reporting tools or application code. The underlying tables (Game.ForexGame, History.ForexResult) and functions (Internal.GetGameBetInCents, Internal.GetInstrumentList) belong to eToro's original gamified trading platform, which was discontinued. Modern trading does not use this game framework.

---

## 2. Business Logic

### 2.1 Game Session Aggregation

**What**: Each output row represents one completed game session with its positions aggregated.

**Columns/Parameters Involved**: `ForexResultID`, `NetProfit`, `LotCountDecimal`

**Rules**:
- GROUP BY ForexResultID (plus other non-aggregated columns) produces one row per game session
- `SUM(PWPC.NetProfit)` - total net profit across all positions in the game session
- `AVG(PWPC.LotCountDecimal)` - average lot count across positions
- Only rows with `EndDateTime IS NOT NULL` are included - game sessions that were properly closed
- The aggregation assumes one game session can have multiple positions linked to it (via History.GetPositionWithPrimaryCurrency.ForexResultID)

**Diagram**:
```
History.ForexResult (one row per game session)
    |
    +--> Game.ForexGame (1:1 - game config)
    +--> History.GetPositionWithPrimaryCurrency (1:many - positions in the game)
    |         Aggregated: SUM(NetProfit), AVG(LotCountDecimal)
    +--> Trade.ProviderToInstrument (via Customer.Customer.ProviderID + PWPC.InstrumentID)
    +--> Customer.Customer (via HFXR.CID)
Output: one row per ForexResultID with aggregated PnL
```

### 2.2 Bet-in-Cents Function Call

**What**: The game bet amount is retrieved via a scalar UDF rather than directly from Game.ForexGame.

**Columns/Parameters Involved**: `Bet` (output), `ForexResultID` (input to function)

**Rules**:
- `Internal.GetGameBetInCents(HFXR.ForexResultID)` returns the game bet amount in cents for this specific game session
- This is distinct from `GFXG.GameBet` (the configured game-level bet): GetGameBetInCents may compute the actual bet for this specific session (potentially adjusted per-player or per-event)
- Both columns are exposed: `Bet` (session-specific, in cents) and `GameBet` (game configuration default)

### 2.3 Instrument List Function Call

**What**: A comma-separated list of instruments traded in the game session is computed via a scalar UDF.

**Columns/Parameters Involved**: `Transactions` (output), `ForexGameID` (input to function)

**Rules**:
- `Internal.GetInstrumentList(HFXR.ForexGameID)` returns the instrument set for this game
- Also appears in GROUP BY clause, confirming it returns a stable (deterministic for the same ForexGameID) result
- Represents the "currency set" in instrument-ID form (complements `CurrencySet` from Game.ForexGame which is the human-readable label)

---

## 3. Data Overview

Direct query blocked (cross-database access required for History.Position archive branches and Game schema). Based on History.ForexResult documentation: the underlying dataset covers 1,285 game sessions from 2009-2014. A representative aggregated row would look like:

| ForexResultID | ForexGameID | GameTypeID | CID | NetProfit | LotCountDecimal | CurrencySet | Meaning |
|---|---|---|---|---|---|---|---|
| 252581662 | 160 | 34 (eToro Trading) | 1652737 | (aggregated) | (aggregated) | (e.g., EUR/USD) | A completed eToro Trading game session for customer 1652737 in 2014 - shows aggregated P&L across all positions in that 12-minute game |
| (oldest) | - | 3 (Forex Marathon) | - | - | - | - | Oldest game type from 2009 - Forex Marathon format predating eToro Trading |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexResultID | bigint | NO | - | CODE-BACKED | Primary key of the game session. From History.ForexResult. Generated by Internal.GetActionID (shared global sequence, not IDENTITY). Values in the 200M+ range. Groups all positions for this game into one aggregated row. |
| 2 | ForexGameID | int | NO | - | CODE-BACKED | Game configuration identifier. FK to Game.ForexGame. Defines the currency set, leverage, bet size, stop-loss range, and take-profit range for the game. Passed to Internal.GetInstrumentList() to retrieve the instrument list. |
| 3 | GameTypeID | int | NO | - | CODE-BACKED | Game mode classification. FK to Dictionary.GameType. Observed values: 3=Forex Marathon, 4=Dollar Trend, 31=Globe Trader, 33=Trade Box, 34=eToro Trading (94% of records), 52=Forex Charts. (Inherited from History.ForexResult) |
| 4 | CID | int | NO | - | CODE-BACKED | Customer account ID of the game player. Joined to Customer.Customer to resolve their ProviderID for the Trade.ProviderToInstrument JOIN. (Inherited from History.ForexResult) |
| 5 | Bet | int (cents) | YES | - | CODE-BACKED | The actual game bet amount for this session in cents, computed by Internal.GetGameBetInCents(ForexResultID). May differ from GameBet (the game configuration default) for sessions with player-specific bet amounts. |
| 6 | PrimaryCurrencyDirection | int | NO | - | CODE-BACKED | The direction of the bet relative to the game's primary currency. Cast from BIT to INTEGER: 0 = short/opposite direction, 1 = long/primary direction. In the historical dataset all 1,285 records show direction=0. (Inherited from History.ForexResult.PrimaryCurrencyDirection) |
| 7 | StartDateTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the game session opened. Set by Game.GameOpen at game creation. (Inherited from History.ForexResult) |
| 8 | EndDateTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the game session closed. Only non-NULL rows appear here (WHERE EndDateTime IS NOT NULL filter). Set by Game.GameClose. Always populated in this view's output. (Inherited from History.ForexResult) |
| 9 | PrimaryCurrencyID | int | YES | - | CODE-BACKED | Settlement currency for P&L calculation. From History.GetPositionWithPrimaryCurrency: for MAP/ROPE game subtypes this is computed by Internal.GetPrimaryCurrencyForMapAndRope(InstrumentID, IsBuy, PrimaryCurrencyDirection); for all other subtypes it is Game.ForexGame.PrimaryCurrencyID. FK to Dictionary.Currency (implied). |
| 10 | CurrencySet | varchar (inferred) | YES | - | CODE-BACKED | Human-readable label for the game's currency pair or basket. From Game.ForexGame.CurrencySet. Describes which currencies are traded in this game (e.g., "EUR/USD"). |
| 11 | Transactions | varchar (inferred) | YES | - | CODE-BACKED | Comma-separated list of instrument IDs traded in this game session, computed by Internal.GetInstrumentList(ForexGameID). Also in the GROUP BY to ensure stable grouping. Represents the instrument set for this game. |
| 12 | Repeat | int (inferred) | YES | - | CODE-BACKED | Whether the game repeats (auto-repeat setting). From Game.ForexGame.Repeat. Game configuration property controlling automatic session continuation. |
| 13 | GameBet | money (inferred) | YES | - | CODE-BACKED | The configured default bet amount for the game, from Game.ForexGame.GameBet. Contrast with Bet column (actual session bet in cents, which may differ). |
| 14 | StopLostRange | decimal (inferred) | YES | - | CODE-BACKED | Stop-loss boundary from Game.ForexGame. The percentage or pip distance at which the game session auto-closes with a loss. |
| 15 | TakeProfitRange | decimal (inferred) | YES | - | CODE-BACKED | Take-profit boundary from Game.ForexGame. The percentage or pip distance at which the game session auto-closes with a win. |
| 16 | Leverage | int | YES | - | CODE-BACKED | Position leverage multiplier. From History.GetPositionWithPrimaryCurrency.Leverage. The leverage applied to positions in this game session. |
| 17 | Unit | decimal (inferred) | YES | - | CODE-BACKED | Trading unit size from Trade.ProviderToInstrument. Resolved via Customer.Customer.ProviderID JOIN to get the provider-specific unit for the instrument. |
| 18 | NetProfit | money | YES | - | CODE-BACKED | Aggregated total net profit across all positions in this game session: SUM(History.GetPositionWithPrimaryCurrency.NetProfit). Positive = net profit, negative = net loss for the game session. |
| 19 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Average lot count across positions in this game session: AVG(History.GetPositionWithPrimaryCurrency.LotCountDecimal). Represents the average position size within the game. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ForexResultID | History.ForexResult | JOIN (base table) | Game session records - the primary driver of this view's rows |
| ForexGameID | Game.ForexGame | JOIN (cross-schema) | Game configuration providing CurrencySet, Repeat, GameBet, StopLostRange, TakeProfitRange |
| (position data) | History.GetPositionWithPrimaryCurrency | JOIN | Provides PrimaryCurrencyID, NetProfit, Leverage, LotCountDecimal per position |
| CID + InstrumentID | Trade.ProviderToInstrument | JOIN (cross-schema) | Resolves the Unit value via Customer.Customer.ProviderID + instrument |
| CID | Customer.Customer | JOIN (cross-schema) | Resolves ProviderID for the Trade.ProviderToInstrument JOIN |
| ForexResultID | Internal.GetGameBetInCents | Function call | Computes Bet column (game bet in cents for this session) |
| ForexGameID | Internal.GetInstrumentList | Function call | Computes Transactions column (instrument list for this game) |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the etoro SSDT repo directly reference History.GetForexResult. It was likely consumed by external reporting tools or application code during the forex game platform era (2009-2014).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetForexResult (view)
|--> History.ForexResult (table - 1,285 rows, 2009-2014 forex game archive)
|--> Game.ForexGame (table, cross-schema)
|--> History.GetPositionWithPrimaryCurrency (view)
|       |--> History.Position (view, cross-schema/archive)
|       |--> History.ForexResult (table)
|       |--> Game.ForexGame (table)
|       +--> Internal.GetPrimaryCurrencyForMapAndRope (function, for MAP/ROPE subtypes)
|--> Trade.ProviderToInstrument (table, cross-schema)
|--> Customer.Customer (table, cross-schema)
|--> Internal.GetGameBetInCents (function)
+--> Internal.GetInstrumentList (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Table | Primary source - game session records; filters EndDateTime IS NOT NULL |
| Game.ForexGame | Table (cross-schema) | Game configuration: CurrencySet, Repeat, GameBet, StopLostRange, TakeProfitRange, GameSubTypeID |
| History.GetPositionWithPrimaryCurrency | View | Position PnL and primary currency resolution per game session |
| Trade.ProviderToInstrument | Table (cross-schema) | Resolves Unit via customer's ProviderID + instrument combination |
| Customer.Customer | Table (cross-schema) | Resolves ProviderID for Trade.ProviderToInstrument JOIN |
| Internal.GetGameBetInCents | Scalar Function (cross-schema) | Computes game bet in cents for each ForexResultID |
| Internal.GetInstrumentList | Scalar Function (cross-schema) | Computes instrument list string for each ForexGameID |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo. Legacy view with no active procedure consumers.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on History.ForexResult (CID NC index, CLUSTERED on ForexResultID), History.GetPositionWithPrimaryCurrency (base indexes on History.Position and History.ForexResult), and the cross-schema tables.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get all completed game results for a specific customer

```sql
SELECT
    gfr.ForexResultID,
    gfr.GameTypeID,
    gfr.StartDateTime,
    gfr.EndDateTime,
    gfr.NetProfit,
    gfr.LotCountDecimal,
    gfr.CurrencySet,
    gfr.Bet
FROM History.GetForexResult gfr WITH (NOLOCK)
WHERE gfr.CID = @CustomerID
ORDER BY gfr.StartDateTime DESC
```

### 8.2 Summarise total game P&L by game type

```sql
SELECT
    gfr.GameTypeID,
    COUNT(*) AS GameCount,
    SUM(gfr.NetProfit) AS TotalNetProfit,
    AVG(gfr.NetProfit) AS AvgNetProfit
FROM History.GetForexResult gfr WITH (NOLOCK)
GROUP BY gfr.GameTypeID
ORDER BY GameCount DESC
```

### 8.3 Find profitable vs. unprofitable game sessions in a date range

```sql
SELECT
    gfr.ForexResultID,
    gfr.CID,
    gfr.GameTypeID,
    gfr.StartDateTime,
    gfr.EndDateTime,
    gfr.NetProfit,
    gfr.CurrencySet,
    CASE WHEN gfr.NetProfit > 0 THEN 'Profit' WHEN gfr.NetProfit < 0 THEN 'Loss' ELSE 'Breakeven' END AS Outcome
FROM History.GetForexResult gfr WITH (NOLOCK)
WHERE gfr.StartDateTime >= '2014-01-01'
  AND gfr.StartDateTime < '2015-01-01'
ORDER BY gfr.NetProfit DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.9/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetForexResult | Type: View | Source: etoro/etoro/History/Views/History.GetForexResult.sql*
