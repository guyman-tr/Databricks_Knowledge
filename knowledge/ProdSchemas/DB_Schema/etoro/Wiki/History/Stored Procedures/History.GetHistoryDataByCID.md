# History.GetHistoryDataByCID

> Returns the most recent N closed positions for a single customer in the legacy HistoryData format, ordered by close date descending, without credit join enrichment.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (single customer) + @numberOfRecords (TOP N limit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **single-customer variant** of the `GetHistoryData*` family. It returns a customer's most recently closed positions up to a specified count (`@numberOfRecords`), sorted newest-first by `EndDateTime`. Unlike `GetHistoryDataForAll` and its time-range variants, this procedure takes a single CID (not a date range) and does NOT join to credit data (no credit enrichment columns).

The header comment `// public List<HistoryData> getHistory(string db, int cid, string numberOfRecords)` is a Java/.NET method stub identifying its role as a web service endpoint for the legacy HistoryData API.

This procedure notably uses `EndDateTime` (the archiving timestamp) for `CloseDate`, while the `GetHistoryDataForAll*` family uses `CloseOccurred` (the actual trade close timestamp). It also joins `Game.ForexResult` alongside `History.ForexResult` for game type lookup, supporting both real and in-game positions.

---

## 2. Business Logic

### 2.1 TOP N by EndDateTime

**What**: Returns the @numberOfRecords most recently closed positions for the customer.

**Rules**: `SELECT TOP (@numberOfRecords) ... FROM History.Position WHERE CID = @CID ORDER BY EndDateTime DESC`

**Note**: Uses `EndDateTime` (archiving close date) rather than `CloseOccurred`. For archived positions these are usually identical, but minor differences may exist due to batch archival timing.

### 2.2 Game.ForexResult UNION for Game Type

**What**: Resolves GameTypeID from both History and Game schemas.

**Rules**: `UNION` of `History.ForexResult` and `Game.ForexResult`, joined by ForexResultID. Enables GameName for both real (History) and championship/game (Game) positions.

### 2.3 Profit and Gain Calculation

**Profit**: `CAST(NetProfit + Commission AS FLOAT)` - P&L net of commission.

**Gain**: Integer-cast arithmetic to avoid floating point drift:
`ISNULL(CAST(CAST(NetProfit*100+Commission*100 AS INT) AS FLOAT)/NULLIF(CAST(CAST(Amount*100 AS INT) AS FLOAT),0)*100,0)`
- Multiplies amounts by 100, casts to INT for rounding, then divides for percentage.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve history for. Filters History.Position WHERE CID = @CID. |
| 2 | @numberOfRecords | INT | NO | - | CODE-BACKED | Maximum number of positions to return (TOP N). |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| PositionID | History.Position | Unique position identifier |
| GameName | Dictionary.GameType.Name | Game type (e.g., Real, Demo, Championship) |
| IsBuy | History.Position.IsBuy | 1=Long/Buy, 0=Short/Sell |
| CurrencyBuy | Trade.Instrument.BuyCurrencyID | Buy currency ID |
| CurrencySell | Trade.Instrument.SellCurrencyID | Sell currency ID |
| BuyCurAbbreviation | Dictionary.Currency.Abbreviation | Buy currency code (e.g., EUR) |
| SellCurAbbreviation | Dictionary.Currency.Abbreviation | Sell currency code (e.g., USD) |
| BuyCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Buy currency type |
| SellCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Sell currency type |
| OpenDate | History.Position.OpenOccurred | Position open timestamp |
| CloseDate | History.Position.EndDateTime | Position close timestamp (archival date) |
| Amount | History.Position.Amount (FLOAT) | Invested amount |
| Units | History.Position.AmountInUnitsDecimal | Position size in units |
| OpenRate | History.Position.InitForexRate (DOUBLE) | Opening exchange rate |
| CloseRate | History.Position.EndForexRate (DOUBLE) | Closing exchange rate |
| Spread | History.Position.Commission*100 (INT) | Commission in basis points (multiplied by 100) |
| Profit | NetProfit+Commission (FLOAT) | Net P&L including commission |
| Gain | (NetProfit+Commission)/Amount*100 | Percentage return on invested amount |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source, filtered by CID, ordered by EndDateTime DESC, TOP N. |
| JOIN | History.ForexResult UNION Game.ForexResult | Read | Game type ID lookup (supports both real and championship positions). |
| JOIN | Dictionary.GameType | Lookup | Game name from GameTypeID. |
| JOIN | Trade.Instrument | Lookup | Buy/sell currency IDs for the instrument. |
| JOIN | Dictionary.Currency (x2) | Lookup | Buy and sell currency abbreviations and type IDs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy HistoryData API | EXEC | Direct call | Per-customer position history endpoint (Java/.NET service method getHistory). |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataByCID (procedure)
├── History.Position (table)
├── History.ForexResult (table) [game type - history]
├── Game.ForexResult (table) [game type - game/championship]
├── Dictionary.GameType (table) [cross-schema]
├── Trade.Instrument (table) [cross-schema]
└── Dictionary.Currency (table) [cross-schema - x2]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source: closed positions filtered by CID, ordered by EndDateTime DESC. |
| History.ForexResult | Table | UNION branch for real-position GameTypeID. |
| Game.ForexResult | Table | UNION branch for championship/game-position GameTypeID. |
| Dictionary.GameType | Table | Game name lookup. |
| Trade.Instrument | Table | Buy/sell currency IDs. |
| Dictionary.Currency | Table | Currency abbreviations and type IDs (joined twice). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy HistoryData API (application) | External | Single-customer closed position history for the getHistory web service method. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EndDateTime vs CloseOccurred | Date field difference | Uses EndDateTime for CloseDate; GetHistoryDataForAll* use CloseOccurred. Results may differ slightly for recently archived positions. |
| No credit join | Scope | Unlike GetHistoryDataForAll*, this procedure does not join History.Credit, so CreditTypeID=4-enriched columns (LimitRate, StopRate, Leverage, Credit, CopyTrader IDs) are absent. |
| Integer gain calculation | Precision | Uses INT casting (NetProfit*100 as int) to avoid floating point rounding errors. |

---

## 8. Sample Queries

### 8.1 Get last 10 positions for a customer

```sql
EXEC History.GetHistoryDataByCID @CID = 12345, @numberOfRecords = 10;
```

### 8.2 Verify underlying positions

```sql
SELECT TOP 10 PositionID, OpenOccurred, EndDateTime, NetProfit, Commission
FROM History.Position WITH (NOLOCK)
WHERE CID = 12345
ORDER BY EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataByCID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataByCID.sql*
