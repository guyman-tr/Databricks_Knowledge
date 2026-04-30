# Trade.GetPositionInfo

> Consolidated position information view that joins open positions with customer details, instrument names, and live PnL for quick position lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.GetPosition) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Active |

---

## 1. Business Meaning

Trade.GetPositionInfo is a convenience view that provides a single-row summary for any open position, combining:
- **Customer identity**: UserName from Customer.Customer
- **Instrument details**: InstrumentName from Trade.GetInstrument
- **Position parameters**: lot count, direction, open rate, stop rate, commission
- **Live PnL**: NetProfit (PnLInCents) from Trade.PnL

This view uses the legacy comma-join syntax (implicit INNER JOINs in the WHERE clause) and is primarily consumed by `Trade.GetHedgedCustomerPosition` and `Trade.GetPositionInfoFromAnyTable`.

---

## 2. Business Logic

### 2.1 Live PnL Integration

**What**: NetProfit is sourced from Trade.PnL, which provides real-time unrealized PnL.

**Rules**:
- NetProfit = PnL.PnLInCents (not PnLInDollars)
- Joins on PositionID only (no partition alignment -- may have performance implications)
- Only open positions are visible (Trade.PnL filters StatusID=1)

---

## 3. Data Overview

Returns one row per open position with human-readable customer and instrument information.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | Unique position identifier. |
| 2 | UserName | nvarchar | NO | - | VERIFIED | Customer username from Customer.Customer. |
| 3 | InstrumentName | nvarchar | YES | - | CODE-BACKED | Instrument display name from Trade.GetInstrument. |
| 4 | LotCountDecimal | decimal | YES | - | VERIFIED | Position size in lots. |
| 5 | IsBuy | bit | NO | - | VERIFIED | Direction: 1=Buy (long), 0=Sell (short). |
| 6 | InitForexRate | decimal | NO | - | VERIFIED | Opening execution rate. |
| 7 | StopRate | decimal | YES | - | VERIFIED | Stop-loss rate. |
| 8 | NetProfit | bigint | YES | - | CODE-BACKED | Live unrealized PnL in cents (from Trade.PnL). |
| 9 | CurrencyID | int | NO | - | VERIFIED | Position's reporting currency. |
| 10 | ProviderID | int | NO | - | VERIFIED | Liquidity provider ID. |
| 11 | Commission | money | YES | - | VERIFIED | Open commission paid. |
| 12 | InitDateTime | datetime | NO | - | VERIFIED | Position open timestamp. |
| 13 | TradeID | bigint | YES | - | VERIFIED | Trade execution ID. |
| 14 | AccountID | int | YES | - | VERIFIED | Customer account ID. |
| 15 | InitForexPriceRateID | bigint | YES | - | VERIFIED | PriceRateID at position open. |
| 16 | OrderPriceRateID | bigint | YES | - | VERIFIED | PriceRateID from the order. |
| 17 | MirrorID | bigint | YES | - | VERIFIED | Copy trading mirror ID (NULL if not a copy). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, UserName | Customer.Customer | INNER JOIN (NOLOCK) | Customer identity |
| PositionID, TFPO.* | Trade.GetPosition | INNER JOIN (NOLOCK) | Position details |
| InstrumentName | Trade.GetInstrument | INNER JOIN | Instrument display name |
| NetProfit | Trade.PnL | INNER JOIN (NOLOCK) | Live unrealized PnL |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgedCustomerPosition | Stored Procedure | Position lookup |
| Trade.GetPositionInfoFromAnyTable | Function | Position info retrieval |
| BackOffice.JUNK_CashierHistory | View | Position detail enrichment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionInfo (view)
+-- Customer.Customer (table) [cross-schema]
+-- Trade.GetPosition (view)
+-- Trade.GetInstrument (view)
+-- Trade.PnL (view)
    +-- Trade.PositionTbl (table)
    +-- Trade.FnCalculatePnLWrapper (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | INNER JOIN - username |
| Trade.GetPosition | View | INNER JOIN - position details |
| Trade.GetInstrument | View | INNER JOIN - instrument name |
| Trade.PnL | View | INNER JOIN - live PnL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgedCustomerPosition | Stored Procedure | Position lookup |
| Trade.GetPositionInfoFromAnyTable | Function | Position info |
| BackOffice.JUNK_CashierHistory | View | Position enrichment |

---

## 7. Technical Details

### 7.1 Legacy Join Syntax

Uses comma-separated FROM clause with WHERE-based join conditions instead of explicit INNER JOIN ON syntax. Functionally equivalent but less maintainable.

### 7.2 Performance Note

The join to Trade.PnL does not include PartitionCol, missing partition elimination optimization. For high-volume lookups, consider joining Trade.PnL with PartitionCol.

---

## 8. Sample Queries

### 8.1 Look up a specific position
```sql
SELECT  * FROM Trade.GetPositionInfo WITH (NOLOCK) WHERE PositionID = 123456789;
```

### 8.2 Find customer's open positions with PnL
```sql
SELECT  PositionID, InstrumentName, IsBuy, NetProfit, InitDateTime
FROM    Trade.GetPositionInfo WITH (NOLOCK)
WHERE   UserName = 'someuser'
ORDER BY InitDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 referencing | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionInfo | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionInfo.sql*
