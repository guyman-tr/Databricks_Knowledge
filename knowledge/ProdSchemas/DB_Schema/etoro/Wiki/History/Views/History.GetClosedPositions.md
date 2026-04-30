# History.GetClosedPositions

> Enriched view of closed positions from the last 3 months - joins History.Position with game type, instrument currencies, buy/sell currency abbreviations, close action type, and parent position username - computing percentage gain and classifying each position as Regular/CopyPlus/Mirror. Used by account statement closed position reports and History stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetClosedPositions enriches closed position data with the instrument context, currency details, game type classification, close action reason, and copy-trading parent information that consumers need to present or analyze positions in context.

The view filters to positions closed within the last **3 months** (`CloseOccurred > DATEADD(m,-3, GETUTCDATE())`), making it a recent-data interface rather than a full-history view. This filtering improves query performance by limiting the massive History.Position UNION ALL to a recent time window.

**Copy-trading classification**: Each position is classified as one of three types based on MirrorID and ParentPositionID:
- `Regular`: no ParentPositionID (independent position)
- `CopyPlus`: has ParentPositionID but no MirrorID (copy-plus relationship without a mirror)
- `Mirror`: has both ParentPositionID and MirrorID (standard copy-trading)

The parent username (for copy trades) is resolved by joining `OpenAndClosePositionsFromReal` (a dbo view/table of popular investor positions) to find the parent position, then joining `RealCustomers` (a dbo view of popular investor customers) to get their username.

**Profit/Gain calculations**:
- `Profit = NetProfit + Commission` - includes the spread/commission in the gross profit calculation
- `Gain = (NetProfit + Commission) / Amount * 100` - percentage return on investment
- `Spread = Commission * 100` - commission expressed in cents

14 consumers across account statement reporting (multiple versions) and History procedures.

---

## 2. Business Logic

### 2.1 3-Month Rolling Window Filter

**What**: Only positions closed within the last 3 months are returned.

**Columns/Parameters Involved**: `CloseDate` (from hp.EndDateTime)

**Rules**:
- WHERE `hp.CloseOccurred > DATEADD(m,-3, GETUTCDATE())`
- This covers approximately 90 days of recent history
- Positions closed more than 3 months ago are not visible in this view
- For full history use History.Position directly

### 2.2 Position Type Classification (Regular / CopyPlus / Mirror)

**What**: Classifies each closed position into one of three copy-trading relationship types.

**Columns/Parameters Involved**: `PositionType`, `ParentPositionID`, `MirrorID`

**Rules**:
```
CASE
  WHEN ISNULL(ParentPositionID, 0) = 0 THEN 'Regular'
  WHEN ISNULL(ParentPositionID, 0) > 0 AND ISNULL(MirrorID, 0) = 0 THEN 'CopyPlus'
  WHEN ISNULL(ParentPositionID, 0) > 0 AND ISNULL(MirrorID, 0) > 0 THEN 'Mirror'
END AS PositionType
```
- Regular (most common): standalone position not attached to copy trading
- Mirror: copied position in a full mirror relationship (copier follows popular investor via mirror)
- CopyPlus: position linked to a parent position but without a mirror ID (older or alternate copy mechanism)

### 2.3 Game Type and Forex Result Enrichment

**What**: Resolves the GameName for each position via ForexResultID.

**Columns/Parameters Involved**: `GameName`, `ForexResultID`

**Rules**:
- Join path: History.Position.ForexResultID -> (History.ForexResult UNION Game.ForexResult) -> Dictionary.GameType
- The UNION of History.ForexResult and Game.ForexResult ensures both historical and current game results are covered
- GameType.Name provides the game name (e.g., forex trading game type)

### 2.4 Currency Information

**What**: Resolves buy and sell currency IDs and abbreviations from Trade.Instrument.

**Columns/Parameters Involved**: `CurrencyBuy`, `CurrencySell`, `BuyCurAbbreviation`, `SellCurAbbreviation`, `BuyCurrencyTypeID`, `SellCurrencyTypeID`

**Rules**:
- Trade.Instrument (aliased TISR) provides BuyCurrencyID and SellCurrencyID for the instrument
- Dictionary.Currency (aliased buyCur and sellCur) resolves Abbreviation and CurrencyTypeID for each
- CurrencyTypeID from Dictionary.Currency classifies the currency (fiat, crypto, etc.)

---

## 3. Data Overview

3-month rolling window of closed positions with enriched context. Each row represents one closed position with computed gain and position type.

| PositionID | CID | GameName | IsBuy | BuyCurAbbreviation | SellCurAbbreviation | Amount | Profit | Gain | PositionType | CloseActionName |
|------------|-----|---------|-------|-------------------|-------------------|--------|--------|------|-------------|-----------------|
| (recent IDs) | 14952810 | (game type) | true | USD | BTC | $99.97 | varies | varies% | Regular | Normal |

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CID | int | NO | CODE-BACKED | Customer ID. From History.Position. |
| 2 | PositionID | bigint | NO | CODE-BACKED | Position identifier. |
| 3 | GameName | varchar | YES | CODE-BACKED | Dictionary.GameType.Name - the trading game type for this position. |
| 4 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=Buy (long), 0=Sell (short). |
| 5 | CurrencyBuy | int | NO | CODE-BACKED | Trade.Instrument.BuyCurrencyID - the instrument's buy currency. FK to Dictionary.Currency. |
| 6 | CurrencySell | int | NO | CODE-BACKED | Trade.Instrument.SellCurrencyID - the instrument's sell currency. FK to Dictionary.Currency. |
| 7 | BuyCurAbbreviation | varchar | YES | CODE-BACKED | Dictionary.Currency.Abbreviation for the buy currency (e.g., 'USD', 'BTC'). |
| 8 | SellCurAbbreviation | varchar | YES | CODE-BACKED | Dictionary.Currency.Abbreviation for the sell currency. |
| 9 | BuyCurrencyTypeID | int | YES | CODE-BACKED | Dictionary.Currency.CurrencyTypeID for the buy currency (fiat vs crypto classification). |
| 10 | SellCurrencyTypeID | int | YES | CODE-BACKED | Dictionary.Currency.CurrencyTypeID for the sell currency. |
| 11 | OpenDate | datetime | NO | CODE-BACKED | History.Position.OpenOccurred - position open timestamp. |
| 12 | CloseDate | datetime | NO | CODE-BACKED | History.Position.EndDateTime - position close timestamp. Only rows from last 3 months returned. |
| 13 | Amount | money | YES | CODE-BACKED | Position investment amount (USD). |
| 14 | Units | decimal(16,6) | YES | CODE-BACKED | History.Position.AmountInUnitsDecimal - position size in instrument units. |
| 15 | OpenRate | dbo.dtPrice | YES | CODE-BACKED | History.Position.InitForexRate - instrument rate at open. |
| 16 | CloseRate | dbo.dtPrice | YES | CODE-BACKED | History.Position.EndForexRate - instrument rate at close. |
| 17 | Spread | money | YES | CODE-BACKED | Commission*100 - commission in cents. Named "Spread" as commissions were historically spread-based. |
| 18 | Profit | money | YES | CODE-BACKED | NetProfit + Commission - gross profit including commission. |
| 19 | Gain | float | YES | CODE-BACKED | (NetProfit + Commission) / CAST(Amount AS FLOAT) * 100 - percentage return on investment. |
| 20 | MirrorID | int | YES | CODE-BACKED | Copy portfolio ID. NULL = not copy trading. |
| 21 | ParentPositionID | bigint | YES | CODE-BACKED | Parent (popular investor) position ID. NULL = not a copied position. |
| 22 | PositionType | varchar | YES | CODE-BACKED | 'Regular', 'CopyPlus', or 'Mirror' classification. See Section 2.2. |
| 23 | ParentUsername | varchar | YES | CODE-BACKED | Username of the popular investor whose position was copied (from RealCustomers via OpenAndClosePositionsFromReal). NULL for non-copy or if parent not found. |
| 24 | ClosePositionActionName | varchar | YES | CODE-BACKED | Dictionary.ClosePositionActionType.ClosePositionActionName - the reason for close (e.g., 'Normal', 'Stop Loss', 'Take Profit'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | History.Position | View (source, WHERE CloseOccurred > -3m) | Base position data |
| ForexResultID | History.ForexResult UNION Game.ForexResult | Subquery UNION | Historical + current game results |
| GameTypeID | Dictionary.GameType | JOIN | Game type name lookup |
| InstrumentID | Trade.Instrument | JOIN | Buy/sell currency IDs |
| BuyCurrencyID/SellCurrencyID | Dictionary.Currency | JOIN (x2) | Currency abbreviation and type |
| ActionType | Dictionary.ClosePositionActionType | JOIN | Close action reason name |
| ParentPositionID | OpenAndClosePositionsFromReal (dbo) | LEFT JOIN | Popular investor position lookup |
| ParentCID | RealCustomers (dbo) | LEFT JOIN | Popular investor username |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetClosedPositionsReport (all versions v1-v3) | PositionID/CID | Read | Account statement closed position reports |
| History.GetClosedPositionsPerPage | PositionID | Read | Paged closed positions for UI |
| History.GetClosedPositionsPerPageAndTimeFrame | PositionID | Read | Paged + time-filtered closed positions |
| History.GetClosedPositionsPerPageByParentCID | ParentPositionID | Read | Copy-trade positions by popular investor |
| History.GetTradingFlatViewClosedPositionsPerPageNew | PositionID | Read | Flat trading view paged query |
| History.ORG_GetClosedPositionsPerPage | PositionID | Read | Organization-level closed positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetClosedPositions (view)
|- History.Position (view - full history UNION ALL)
|- History.ForexResult (table - historical game results)
|- Game.ForexResult (table - cross-schema, current game results)
|- Dictionary.GameType (table - game type names)
|- Trade.Instrument (table - buy/sell currency IDs)
|- Dictionary.Currency (table - currency abbreviation/type, joined twice)
|- Dictionary.ClosePositionActionType (table - action type names)
|- OpenAndClosePositionsFromReal (dbo view/table - popular investor positions)
+- RealCustomers (dbo view/table - popular investor customer data)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | View | Source (last 3 months filter) |
| History.ForexResult | Table | Subquery UNION - historical game results |
| Game.ForexResult | Table | Subquery UNION - current game results |
| Dictionary.GameType | Table | Game type name |
| Trade.Instrument | Table | Instrument currency IDs |
| Dictionary.Currency | Table | Currency abbreviation/type (buyCur + sellCur) |
| Dictionary.ClosePositionActionType | Table | Close reason name |
| OpenAndClosePositionsFromReal | View/Table (dbo) | Popular investor position lookup |
| RealCustomers | View/Table (dbo) | Popular investor username |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetClosedPositionsReport | Stored Procedures (multiple versions) | Closed position account statement |
| History.GetClosedPositionsPerPage | Stored Procedure | Paged closed position results |
| History.GetClosedPositionsPerPageAndTimeFrame | Stored Procedure | Time-filtered paged results |
| History.GetClosedPositionsPerPageByParentCID | Stored Procedure | By popular investor |
| History.GetTradingFlatViewClosedPositionsPerPageNew | Stored Procedure | Flat trading view |
| History.ORG_GetClosedPositionsPerPage | Stored Procedure | Organization-level paged results |

---

## 7. Technical Details

### 7.1 Performance Notes

- The 3-month WHERE filter on CloseOccurred limits History.Position's 65-table UNION ALL to recent data
- The History.Position base view still scans all archive branches before the filter; for better performance, direct queries against History.PositionSlim (2021+) with date filter would be faster
- The LEFT JOINs to OpenAndClosePositionsFromReal and RealCustomers resolve parent usernames; these are NULL for most positions (non-copy trades)

---

## 8. Sample Queries

### 8.1 Get closed positions for a customer (last 3 months)
```sql
SELECT
    cp.PositionID,
    cp.GameName,
    cp.IsBuy,
    cp.BuyCurAbbreviation,
    cp.SellCurAbbreviation,
    cp.Amount,
    cp.Profit,
    cp.Gain,
    cp.PositionType,
    cp.ClosePositionActionName,
    cp.OpenDate,
    cp.CloseDate
FROM History.GetClosedPositions cp WITH (NOLOCK)
WHERE cp.CID = 14952810
ORDER BY cp.CloseDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.GetClosedPositions.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetClosedPositions | Type: View | Source: etoro/etoro/History/Views/History.GetClosedPositions.sql*
