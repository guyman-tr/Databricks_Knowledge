# Trade.GetPendingOrders

> Returns all live pending (entry) orders from Trade.Orders with the current market price deviation from the trigger rate - used for pending order monitoring and order-book management.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all pending orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPendingOrders` returns all active pending (entry) orders from Trade.Orders along with a computed `Price` field showing the difference between the order's trigger rate and the current market bid/ask. It excludes demo accounts (PlayerLevelID=4).

**WHY:** Pending orders in eToro are orders that execute when price reaches a specific level (e.g., buy at 150 if current price is 155). Monitoring services need to see all live pending orders and how far the current market price is from the trigger. A negative Price value means the order is "in the money" (trigger level already reached), which may indicate an execution delay.

**HOW:** Joins Trade.Orders to Customer.Customer (for SpreadGroupID and PlayerLevelID), then to Trade.SpreadToGroup and Trade.Spread to resolve the current bid/ask for the instrument. Joins Trade.ProviderToInstrument for the Precision (decimal places). Computes Price as `ROUND(RateFrom, Precision) - (Ask or Bid / 10^Precision)` depending on direction.

---

## 2. Business Logic

### 2.1 Price Deviation Calculation

**What:** `Price` measures the gap between the pending order's trigger rate and the current market price, scaled by instrument precision.

**Columns/Parameters Involved:** `RateFrom`, `Precision`, `Ask`, `Bid`, `IsBuy`

**Rules:**
- Buy order (IsBuy=1): `Price = ROUND(RateFrom, Precision) - CAST(d.Ask AS MONEY) / POWER(10, Precision)`
- Sell order (IsBuy=0): `Price = ROUND(RateFrom, Precision) - CAST(d.Bid AS MONEY) / POWER(10, Precision)`
- Negative Price = current market has crossed the trigger level (order should have fired)
- Zero Price = order is exactly at market
- Positive Price = order trigger not yet reached

### 2.2 Demo Account Exclusion

**What:** Only real-money accounts are included; demo accounts are excluded.

**Columns/Parameters Involved:** `PlayerLevelID`

**Rules:**
- `WHERE b.PlayerLevelID <> 4` - excludes demo/paper trading accounts
- PlayerLevelID=4 = demo account in eToro's customer level system

### 2.3 Spread Resolution

**What:** The current market price is resolved via the customer's spread group.

**Columns/Parameters Involved:** `SpreadGroupID`, `SpreadID`, `Ask`, `Bid`

**Rules:**
- Customer -> SpreadGroup (via Customer.SpreadGroupID -> Trade.SpreadToGroup.SpreadGroupID)
- SpreadGroup -> Spread (via SpreadToGroup.SpreadID -> Trade.Spread.SpreadID + InstrumentID match)
- Spread.Ask / Spread.Bid are the current market prices for that spread group

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:** None.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Pending order ID from Trade.Orders. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. FK to Trade.Instrument. |
| 3 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Order size in lots. From Trade.Orders. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy pending, 0=Sell pending. Determines whether Ask or Bid is used in price calculation. |
| 5 | Price | MONEY | YES | - | CODE-BACKED | Deviation of order trigger rate from current market price. Negative=trigger passed, positive=trigger not yet reached. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Orders | Lookup | All pending orders |
| CID | Customer.Customer | Lookup | SpreadGroupID and PlayerLevelID (demo filter) |
| SpreadGroupID | Trade.SpreadToGroup | Lookup | Maps customer spread group to specific spread |
| SpreadID + InstrumentID | Trade.Spread | Lookup | Current Ask/Bid prices for the instrument |
| InstrumentID | Trade.ProviderToInstrument | Lookup | Precision for price rounding |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by pending order monitoring services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPendingOrders (procedure)
|- Trade.Orders (table) - all pending orders
|- Customer.Customer (table) - spread group and player level
|- Trade.SpreadToGroup (table) - spread group to spread mapping
|- Trade.Spread (table) - current bid/ask prices
|- Trade.ProviderToInstrument (table) - precision
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Source of all active pending orders |
| Customer.Customer | Table | SpreadGroupID for price resolution; PlayerLevelID for demo filter |
| Trade.SpreadToGroup | Table | Maps customer's spread group to a specific spread |
| Trade.Spread | Table | Current market Ask/Bid prices per instrument per spread |
| Trade.ProviderToInstrument | Table | Instrument decimal precision for price rounding |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by order monitoring services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PlayerLevelID <> 4 | Filter | Excludes demo accounts |
| NOLOCK on all tables | Performance | Dirty read acceptable for order monitoring |
| No parameters | Scope | Returns ALL pending orders - caller must handle large result sets |

---

## 8. Sample Queries

### 8.1 Get all pending orders with price deviation

```sql
EXEC Trade.GetPendingOrders
```

### 8.2 Find orders near trigger (Price between -0.01 and 0.01)

```sql
DECLARE @t TABLE (OrderID INT, InstrumentID INT, LotCountDecimal DECIMAL(18,8), IsBuy BIT, Price MONEY)
INSERT @t EXEC Trade.GetPendingOrders
SELECT * FROM @t WHERE ABS(Price) < 0.01
ORDER BY ABS(Price)
```

### 8.3 Count pending orders by direction

```sql
DECLARE @t TABLE (OrderID INT, InstrumentID INT, LotCountDecimal DECIMAL(18,8), IsBuy BIT, Price MONEY)
INSERT @t EXEC Trade.GetPendingOrders
SELECT IsBuy, COUNT(*) AS OrderCount FROM @t GROUP BY IsBuy
```

---

## 9. Atlassian Knowledge Sources

No directly relevant Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPendingOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPendingOrders.sql*
