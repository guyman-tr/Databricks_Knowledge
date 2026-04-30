# BackOffice.JUNK_GetForexClosedPosition

> **DEPRECATED (JUNK prefix)** - Returns all historical closed positions from History.Position with instrument name, amounts in cents, entry/exit prices, and open/close timestamps.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | PositionID - one row per historical position |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_GetForexClosedPosition` is a legacy view (JUNK prefix = deprecated) that exposes `History.Position` records enriched with the instrument name from `Trade.GetInstrument`. It provides a simple position-level report of closed trading positions including entry/exit prices, profit, and timestamps.

The view was likely used by the BackOffice cashier or analytics module to display a customer's closed position history. It expresses monetary amounts (Amount, NetProfit) in cents (multiplied by 100, cast to INTEGER) which was a convention in the early eToro platform architecture. No active consumers reference this view. History.Position is in EtoroArchive and not accessible via the current MCP connection.

---

## 2. Business Logic

### 2.1 Position Data in Cents Convention

**What**: Monetary amounts are multiplied by 100 and cast to INTEGER - a legacy convention from early eToro platform where amounts were stored or transmitted as integer cents.

**Columns/Parameters Involved**: `Amount`, `Profit`

**Rules**:
- `Amount = CAST(HPOS.Amount*100 AS INTEGER)` - divide by 100 to get dollar value
- `Profit = CAST(HPOS.NetProfit*100 AS INTEGER)` - divide by 100 to get dollar value
- `InitForexRate` and `EndForexRate` are NOT converted - kept as original decimal values

---

## 3. Data Overview

*Live data not available - History.Position references EtoroArchive database.*

| PositionID | Quote | Amount | Profit | InitForexRate | EndForexRate | StartDateTime | EndDateTime |
|------------|-------|--------|--------|---------------|--------------|---------------|-------------|
| (example) | EUR/USD | 100000 | 5000 | 1.1050 | 1.1100 | 2021-01-05 09:00 | 2021-01-05 14:00 |

*Amount=100000 means $1,000.00. Profit=5000 means $50.00 net profit.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | INT | NO | - | CODE-BACKED | Unique identifier of the trading position. PK from `History.Position`. |
| 2 | Quote | NVARCHAR | NO | - | CODE-BACKED | Instrument/asset name for this position. Resolved from `Trade.GetInstrument.Name` via InstrumentID JOIN. Examples: "EUR/USD", "BTC/USD", "AAPL". INNER JOIN - positions with unresolvable InstrumentID are excluded. |
| 3 | Amount | INT (computed) | YES | - | CODE-BACKED | Position wager/stake amount in cents. Computed as `CAST(History.Position.Amount*100 AS INTEGER)`. Divide by 100 for dollar value. Legacy integer-cents convention from early platform. |
| 4 | Profit | INT (computed) | YES | - | CODE-BACKED | Net profit/loss of the position in cents. Computed as `CAST(History.Position.NetProfit*100 AS INTEGER)`. Positive = profitable position, negative = losing position. Divide by 100 for dollar value. |
| 5 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Entry (opening) forex rate for this position. From `History.Position.InitForexRate`. The price at which the position was opened. |
| 6 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Exit (closing) forex rate for this position. From `History.Position.EndForexRate`. The price at which the position was closed. |
| 7 | StartDateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the position was opened. Aliased from `History.Position.OpenOccurred`. |
| 8 | EndDateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the position was closed. From `History.Position.EndDateTime`. May be NULL for positions not yet closed (though History.Position typically contains only closed/historical positions). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID, Amount, NetProfit, InitForexRate, EndForexRate, OpenOccurred, EndDateTime, InstrumentID | History.Position | Source (cross-schema, NOLOCK) | All historical closed positions in EtoroArchive. |
| Quote | Trade.GetInstrument | Lookup (cross-schema, implicit INNER JOIN) | Resolves InstrumentID to instrument name. |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetForexClosedPosition (view) [DEPRECATED]
├── History.Position (cross-schema table - EtoroArchive)
└── Trade.GetInstrument (cross-schema view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Cross-schema Table | FROM clause (alias HPOS, NOLOCK) - all historical positions |
| Trade.GetInstrument | Cross-schema View | FROM clause (alias TISR) - instrument name resolution via implicit INNER JOIN on InstrumentID |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: implicit INNER JOIN - positions with no matching instrument in Trade.GetInstrument are excluded.

---

## 8. Sample Queries

### 8.1 Get closed positions for a customer (requires joining to History.Position for CID)

```sql
SELECT p.PositionID, p.Quote, p.Amount / 100.0 AS AmountUSD,
       p.Profit / 100.0 AS ProfitUSD, p.InitForexRate, p.EndForexRate,
       p.StartDateTime, p.EndDateTime
FROM BackOffice.JUNK_GetForexClosedPosition p WITH (NOLOCK)
ORDER BY p.StartDateTime DESC
```

### 8.2 Find profitable positions with amount converted to dollars

```sql
SELECT PositionID, Quote, Amount / 100.0 AS AmountUSD, Profit / 100.0 AS ProfitUSD
FROM BackOffice.JUNK_GetForexClosedPosition WITH (NOLOCK)
WHERE Profit > 0
ORDER BY Profit DESC
```

### 8.3 Summarize profit/loss by instrument

```sql
SELECT Quote, COUNT(*) AS Positions,
       SUM(Profit) / 100.0 AS TotalProfitUSD,
       AVG(Profit) / 100.0 AS AvgProfitUSD
FROM BackOffice.JUNK_GetForexClosedPosition WITH (NOLOCK)
GROUP BY Quote
ORDER BY TotalProfitUSD DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetForexClosedPosition | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_GetForexClosedPosition.sql*
