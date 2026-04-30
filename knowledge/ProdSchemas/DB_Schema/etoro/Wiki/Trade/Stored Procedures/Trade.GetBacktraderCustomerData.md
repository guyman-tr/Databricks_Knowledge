# Trade.GetBacktraderCustomerData

> Retrieves a complete portfolio view for the Back Trader feature - combining open positions, pending rate orders, copy trading mirrors, and market orders for a customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unified portfolio data (positions + orders + mirrors + pending orders) for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the "Back Trader" feature by providing a unified portfolio view for a customer. Back Trader allows users to simulate or review their current portfolio composition. The procedure returns four data sets UNIONed together: open positions (manual trades), pending rate orders (limit/stop orders), copy trading mirrors (CopyTrader investments), and market orders awaiting execution.

The procedure exists because a customer's portfolio is spread across multiple tables (positions, orders, mirrors, pending orders) and the Back Trader feature needs a single consolidated view with standardized columns across all trade types.

Data flows from four sources via UNION ALL: `Trade.Position` (open manual positions with MirrorID=0), `Trade.Orders` (pending rate orders), `Trade.Mirror` (copy trading investments), and `Trade.OrderForOpen` (market orders awaiting execution). Each source JOINs to `Trade.InstrumentMetaData` for display info (except mirrors which use the parent's username).

---

## 2. Business Logic

### 2.1 Trade Type Classification

**What**: Each portfolio item is tagged with a TradeType to distinguish positions, orders, and copies.

**Columns/Parameters Involved**: `TradeType`

**Rules**:
- TradeType = 1: Open position (from Trade.Position)
- TradeType = 2: Pending rate order (from Trade.Orders) OR market order (from Trade.OrderForOpen)
- TradeType = 3: Copy trading mirror (from Trade.Mirror)

### 2.2 Manual Positions Only (MirrorID Filter)

**What**: Only manual (non-copied) positions and orders are shown individually.

**Columns/Parameters Involved**: `MirrorID`

**Rules**:
- Positions: `WHERE MirrorID = 0` - excludes copied positions (they appear under the mirror entry)
- Market orders: `WHERE MirrorID = 0` - excludes mirror-initiated orders
- Mirrors are shown as their own TradeType=3 entries with aggregate investment amounts

### 2.3 Mirror Investment Calculation

**What**: Copy trading investment is calculated as the current active investment amount.

**Columns/Parameters Involved**: `InitialInvestment`, `DepositSummary`, `WithdrawalSummary`

**Rules**:
- `CAST(InitialInvestment + ISNULL(DepositSummary, 0) - ISNULL(WithdrawalSummary, 0) AS decimal(16, 2))`
- Represents: initial investment + any additional deposits - any withdrawals from the copy relationship
- ParentUserName is used as the Symbol field for mirrors (the "instrument" being copied is another user)

### 2.4 Order Amount Conversion

**What**: Rate order amounts are converted from cents to dollars.

**Columns/Parameters Involved**: `Amount`

**Rules**:
- Rate orders (Trade.Orders): `TRO.Amount/100.0 AS Amount` - stored in cents, displayed in dollars
- Market orders (Trade.OrderForOpen): `TRO.Amount AS Amount` - already in dollars
- Position amounts (Trade.Position): `CAST(Amount AS Decimal(16,2))` - direct cast

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve portfolio for. |
| 2 | Id | BIGINT | NO | - | CODE-BACKED | Unified identifier: PositionID for positions, OrderID for orders, MirrorID for mirrors. |
| 3 | TradeType | INT | NO | - | CODE-BACKED | Type classification: 1=Open position, 2=Pending order, 3=Copy mirror. |
| 4 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Instrument name. NULL for mirrors (mirrors use ParentUserName as Symbol instead). |
| 5 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Instrument symbol for positions/orders. For mirrors: the ParentUserName (copied user's name). |
| 6 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID for positions/orders. For mirrors: the ParentCID (copied user's customer ID). |
| 7 | Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Investment amount in dollars. For rate orders: converted from cents (Amount/100). For mirrors: calculated as InitialInvestment + Deposits - Withdrawals. |
| 8 | Direction | VARCHAR | YES | - | CODE-BACKED | Trade direction: 'Buy'/'Sell' for positions and orders. 'Copy' for mirrors. 'Unknown' for invalid IsBuy values. |
| 9 | StopLoss | DECIMAL(16,4) | YES | - | CODE-BACKED | Stop loss rate. From StopRate for positions, StopLosRate for rate orders. NULL for mirrors and market orders. |
| 10 | TakeProfit | DECIMAL(16,4) | YES | - | CODE-BACKED | Take profit rate. From LimitRate for positions, TakeProfitRate for rate orders. NULL for mirrors and market orders. |
| 11 | Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Entry rate. InitForexRate for positions, RateFrom for rate orders. NULL for mirrors and market orders. |
| 12 | Units | DECIMAL | YES | - | CODE-BACKED | Position units. AmountInUnitsDecimal for positions, calculated (Amount/100/Rate) for rate orders. NULL for mirrors and market orders. |
| 13 | OpenTime | DATETIME | YES | - | CODE-BACKED | When the trade was opened. InitDateTime for positions, OccurredTime for rate orders, Occurred for mirrors. NULL for market orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.Position | SELECT FROM | Open manual positions (view over PositionTbl) |
| (body) | Trade.InstrumentMetaData | INNER JOIN | Instrument display info for positions and orders |
| (body) | Trade.Orders | SELECT FROM | Pending rate orders (limit/stop orders) |
| (body) | Trade.Mirror | SELECT FROM | Copy trading relationships |
| (body) | Trade.OrderForOpen | SELECT FROM | Market orders awaiting execution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetBacktraderCustomerData (procedure)
+-- Trade.Position (view)
+-- Trade.InstrumentMetaData (table)
+-- Trade.Orders (table)
+-- Trade.Mirror (table)
+-- Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT FROM - open positions |
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument display info (3 times) |
| Trade.Orders | Table | SELECT FROM - pending rate orders |
| Trade.Mirror | Table | SELECT FROM - copy trading mirrors |
| Trade.OrderForOpen | Table | SELECT FROM - market orders awaiting execution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get portfolio for a customer
```sql
EXEC Trade.GetBacktraderCustomerData @CID = 12345;
```

### 8.2 Count portfolio items by trade type
```sql
-- After executing procedure, application groups by TradeType:
-- TradeType 1 = positions, 2 = orders, 3 = mirrors
```

### 8.3 Direct query for open manual positions only
```sql
SELECT  p.PositionID, imd.InstrumentDisplayName, imd.Symbol, p.Amount, p.IsBuy, p.InitForexRate, p.AmountInUnitsDecimal
FROM    Trade.Position p WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON imd.InstrumentID = p.InstrumentID
WHERE   p.CID = 12345 AND p.MirrorID = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Back Trader](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/) | Confluence | Feature documentation for the Back Trader portfolio view tool |

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetBacktraderCustomerData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetBacktraderCustomerData.sql*
