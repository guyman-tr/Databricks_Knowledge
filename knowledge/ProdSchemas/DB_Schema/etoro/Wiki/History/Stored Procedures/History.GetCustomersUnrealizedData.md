# History.GetCustomersUnrealizedData

> Computes total unrealized P&L and commission across all non-demo customer positions (both open and historically closed-after-reference-time) at a specific historical point in time, using a cross-linked price snapshot from the AO-PRICE-LSN-ROR price server.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferenceTime (point-in-time); @ProviderID (price filtering); returns 0/SUCCESS or -1/ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes a **portfolio-wide point-in-time unrealized P&L** snapshot: the total hypothetical profit/loss and commission if all customer positions that were open at `@ReferenceTime` were closed at the prices available at that time. It excludes demo accounts (PlayerLevelID=4) and filters positions by instrument availability via `Trade.GetInstrument`.

The key use case is historical portfolio valuation for regulatory reporting, risk analysis, or drawdown calculations. It answers: "What was the total unrealized P&L of all real customer portfolios at time T?"

The procedure returns two aggregate values: `CustomersUnrealizedPNL` and `CustomersUnrealizedCommission`.

---

## 2. Business Logic

### 2.1 Point-in-Time Price Snapshot via XML

**What**: Builds an XML price document from `HistoryCurrencyPrice` (synonym for `dbo.HistoryCurrencyPrice` -> linked server `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice]`) as of @ReferenceTime.

**Rules**:
- Selects the MAX(CurrencyPriceID) per InstrumentID within the 7-day window ending at @ReferenceTime
- Time window: `Occurred <= @ReferenceTime AND Occurred >= DATEADD(dd,-7,@ReferenceTime)`
- Self-joins to get the Bid and Ask for those max-ID records
- Produces XML: `<Prices><Instrument ID="N" RateBid="X" RateAsk="Y" /></Prices>`
- This XML is passed to `History.GetNetProfit()` for per-position P&L calculation

**Why 7-day lookback**: Ensures that even if a price feed went silent for several days, the most recent price within a week is used rather than returning NULL.

### 2.2 Position Universe at Reference Time (UNION of History + Trade)

**What**: Identifies all positions that were open at exactly @ReferenceTime.

**Branch 1 - History.Position** (archived/closed positions): `CloseOccurred >= @ReferenceTime AND OpenOccurred <= @ReferenceTime`
- Returns positions that had already been archived but were still "open" at the reference moment (closed after @ReferenceTime)

**Branch 2 - Trade.Position** (live/open positions): `Occurred <= @ReferenceTime`
- Returns all currently open positions that opened on or before @ReferenceTime

**Both branches filter**:
- `Customer.Customer.PlayerLevelID <> 4` - excludes demo accounts
- `Trade.GetInstrument` JOIN - filters to instruments recognized by the trading engine

Result: `PositionID, Commission` pairs for all positions open at the reference time.

### 2.3 Per-Position P&L via History.GetNetProfit Scalar Function

**What**: For each position in the universe, calls `History.GetNetProfit(PositionID, @PriceXML, @ProviderID)` to compute unrealized PnL at reference prices.

**Returns MONEY**: The standard pip-based forex P&L formula: (current price - open price) in pips * lot count * one-pip USD value.

**SUM aggregation**: `ISNULL(SUM(History.GetNetProfit(...)), 0)` and `ISNULL(SUM(Commission), 0)` aggregate across all positions.

### 2.4 Return Codes

**What**: TRY/CATCH with numeric return codes.

**Rules**:
- Success: `RETURN (0)`
- Error caught: `RETURN (-1)`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceTime | DATETIME | NO | - | CODE-BACKED | The point in time for which to compute the portfolio snapshot. Used as the upper date bound for prices and the open/close boundary for positions. |
| 2 | @ProviderID | INT | NO | - | CODE-BACKED | Price provider ID passed through to History.GetNetProfit for instrument price lookup from the XML snapshot. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CustomersUnrealizedPNL | SUM(History.GetNetProfit()) | Total unrealized P&L in USD for all real customer positions open at @ReferenceTime, at reference-time prices. |
| CustomersUnrealizedCommission | SUM(History.Position.Commission + Trade.Position.Commission) | Total commission accrued on all open positions at reference time. |

**Return value**: 0 = SUCCESS, -1 = ERROR (from TRY/CATCH).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.HistoryCurrencyPrice | Read | Synonym for [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice] - linked server price history used to build the XML price snapshot. |
| CALL | History.GetNetProfit | Function call | Per-position P&L calculation using XML price snapshot and provider ID. |
| FROM | History.Position | Read | Archived positions: finds positions open at reference time (OpenOccurred<=@T, CloseOccurred>=@T). |
| FROM | Trade.Position | Read | Live positions: positions opened on or before @ReferenceTime. |
| JOIN | Customer.Customer | Lookup | Filters PlayerLevelID<>4 to exclude demo accounts. |
| JOIN | Trade.GetInstrument | Filter | Restricts to valid trading instruments only. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Historical valuation / reporting system | EXEC | Direct call | Point-in-time portfolio unrealized P&L for regulatory or risk reporting. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetCustomersUnrealizedData (procedure)
├── dbo.HistoryCurrencyPrice (synonym -> [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice])
├── History.GetNetProfit (scalar function) [per-position P&L engine]
├── History.Position (table) [archived positions]
├── Trade.Position (table) [live positions]
├── Customer.Customer (table) [demo account filter]
└── Trade.GetInstrument (view/table) [instrument filter]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.HistoryCurrencyPrice | Synonym | Linked-server price history for building the XML price snapshot. Points to [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice]. |
| History.GetNetProfit | Scalar Function | Called per-position to compute unrealized P&L from XML price snapshot. |
| History.Position | Table | Source of archived positions open at @ReferenceTime. |
| Trade.Position | Table | Source of live positions open at @ReferenceTime. |
| Customer.Customer | Table | JOIN to exclude demo accounts (PlayerLevelID=4). |
| Trade.GetInstrument | View | JOIN to restrict positions to recognized trading instruments. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Historical reporting / valuation system | External | Portfolio-wide unrealized P&L at reference time. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 7-day price lookback | Price freshness | If no price exists within 7 days of @ReferenceTime for an instrument, that instrument's positions return NULL PnL (ISNULL converts to 0 in the SUM). |
| PlayerLevelID <> 4 | Account filter | Demo accounts excluded from both History.Position and Trade.Position branches. |
| RETURN codes | Error protocol | Callers must check the return value: 0=OK, -1=failed. |
| Linked server dependency | Cross-server | dbo.HistoryCurrencyPrice is a linked-server synonym; if the AO-PRICE-LSN-ROR link is unavailable, the procedure fails in CATCH and returns -1. |
| Scalar function per row | Performance | History.GetNetProfit is called once per position in the result set; for large position universes this can be slow. |

---

## 8. Sample Queries

### 8.1 Get total unrealized P&L at a historical reference time

```sql
EXEC History.GetCustomersUnrealizedData
    @ReferenceTime = '2024-12-31 23:59:59',
    @ProviderID = 1;
```

### 8.2 Check the price snapshot for a given reference time

```sql
SELECT
    InstrumentID,
    MAX(CurrencyPriceID) AS MaxPriceID
FROM dbo.HistoryCurrencyPrice WITH (NOLOCK)
WHERE Occurred <= '2024-12-31 23:59:59'
  AND Occurred >= DATEADD(dd, -7, '2024-12-31 23:59:59')
GROUP BY InstrumentID;
```

### 8.3 Count positions open at a reference time

```sql
SELECT COUNT(*) AS HistoryPositions
FROM History.Position HP WITH (NOLOCK)
JOIN Customer.Customer CC WITH (NOLOCK) ON CC.CID = HP.CID AND CC.PlayerLevelID <> 4
WHERE HP.CloseOccurred >= '2024-12-31'
  AND HP.OpenOccurred <= '2024-12-31';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetCustomersUnrealizedData | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetCustomersUnrealizedData.sql*
