# BackOffice.GetCustomerOpenOrders

> Returns all pending (open) entry orders for a customer from Trade.Orders, with instrument name, amount, leverage, and limit parameters.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

An "open order" in eToro is a pending entry order - the customer has set a target rate at which they want to open a position, but the market has not yet reached that rate. This procedure returns all such pending orders for a customer, used in the BackOffice customer profile to show the agent what orders are waiting to be filled.

Each row shows the order details: instrument, direction (buy/sell), the amount (stored in cents, displayed in dollars), the target open rate, the market range tolerance, and the stop-loss/take-profit levels configured at order creation.

Originally extracted from inline BackOffice code (October 2013, case 18846). Updated January 2016 (case 43111).

**Orphan JOIN**: `Trade.ProviderToInstrument` is JOINed but no columns from it are selected. This is the same orphan pattern as `GetCustomerClosedOrders` - likely a legacy remnant from an earlier version that needed provider data (e.g., spread group, pip value) but was later removed without cleaning up the JOIN.

**Amount encoding**: `TRO.Amount` is stored in cents (integer). Displayed as dollars via `Amount/100.0`.

**Market Range**: `ABS(RateFrom - RateTo) * Power(10, Precision)` - the acceptable execution deviation in pips. RateFrom is the target rate; RateTo is the outer boundary. `Precision` is the instrument's decimal precision from InstrumentMetaData.

---

## 2. Business Logic

### 2.1 Market Range Calculation

**What**: Converts the raw rate difference to pips using the instrument's precision.

**Rules**:
- `ABS(TRO.RateFrom - TRO.RateTo)` - absolute difference between target and boundary rates
- `* Power(10, Precision)` - multiplies by 10^Precision to express in pips (e.g., Precision=4 for EUR/USD -> * 10000)
- Result is the maximum pip deviation acceptable for order execution

### 2.2 Over Weekend Flag

**What**: Indicates whether the order should remain active over the weekend.

**Rules**:
- `CASE WHEN TRO.IsOverWeekend=1 THEN 'Yes' ELSE 'No' END`
- When 'No': order is automatically cancelled if market closes before it fills

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Matched against Trade.Orders.CID. |
| **Output Columns** | | | | | | |
| 2 | [Order ID] | INT | NO | - | CODE-BACKED | Unique order identifier. From Trade.Orders.OrderID. |
| 3 | [CID] | INT | NO | - | CODE-BACKED | Customer ID (echoed from the order record). Same as @CID. |
| 4 | [Buy/Sell] | VARCHAR | NO | - | CODE-BACKED | Trade direction. 'Buy' when IsBuy=1, 'Sell' when IsBuy=0. |
| 5 | [Instrument] | NVARCHAR | YES | - | CODE-BACKED | Display name of the instrument. From Trade.InstrumentMetaData.InstrumentDisplayName. |
| 6 | [Instrument ID] | INT | NO | - | CODE-BACKED | Numeric instrument identifier. From Trade.InstrumentMetaData.InstrumentID. |
| 7 | [Amount] | DECIMAL(16,2) | NO | - | CODE-BACKED | Order amount in dollars. Trade.Orders.Amount stores in cents; divided by 100.0 for display. |
| 8 | [Leverage] | INT | YES | - | CODE-BACKED | Leverage multiplier selected for this order. From Trade.Orders.Leverage. |
| 9 | [Date Opened] | DATETIME | NO | - | CODE-BACKED | Timestamp when the order was placed. From Trade.Orders.OccurredTime. |
| 10 | [Order Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Target rate at which the order will execute. From Trade.Orders.RateFrom. |
| 11 | [Market Range] | DECIMAL(16,4) | YES | - | CODE-BACKED | Acceptable execution deviation in pips. ABS(RateFrom - RateTo) * Power(10, InstrumentMetaData.Precision). |
| 12 | [Stop Loss] | DECIMAL(16,4) | YES | - | CODE-BACKED | Stop loss rate pre-set at order creation. From Trade.Orders.StopLosRate (note: column name has single 's'). |
| 13 | [Take Profit] | DECIMAL(16,4) | YES | - | CODE-BACKED | Take profit rate pre-set at order creation. From Trade.Orders.TakeProfitRate. |
| 14 | [Over Weekend] | VARCHAR | NO | - | CODE-BACKED | Whether the order persists over the weekend market close. 'Yes' if IsOverWeekend=1, 'No' otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / OrderID | Trade.Orders | Primary Source | All pending entry orders for the customer |
| InstrumentID | Trade.InstrumentMetaData | INNER JOIN | Instrument display name and precision |
| InstrumentID | Trade.ProviderToInstrument | INNER JOIN (orphan) | JOINed but no columns selected; legacy artifact |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Open Orders tab in customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerOpenOrders (procedure)
|- Trade.Orders (pending entry orders)
|- Trade.InstrumentMetaData (instrument name + precision)
+-- Trade.ProviderToInstrument (orphan JOIN - no columns used)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Primary source - pending entry orders with rates, leverage, SL/TP |
| Trade.InstrumentMetaData | Table | INNER JOINed for InstrumentDisplayName and Precision |
| Trade.ProviderToInstrument | Table | INNER JOINed on InstrumentID but no columns selected; orphan legacy JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Open Orders tab - pending entry order list in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `WITH(NOLOCK)` on all tables.
- `ORDER BY TRO.OccurredTime DESC` - most recently placed orders first.
- Orphan JOIN on `Trade.ProviderToInstrument`: no columns selected from it; its presence introduces an INNER JOIN filter (instruments must have a provider mapping). Orders for instruments without a ProviderToInstrument row would be excluded silently.

---

## 8. Sample Queries

### 8.1 Get open orders for a customer

```sql
EXEC BackOffice.GetCustomerOpenOrders @CID = 12345678;
```

### 8.2 Direct base-table query (without orphan JOIN)

```sql
SELECT
    TRO.OrderID AS [Order ID],
    CASE WHEN TRO.IsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS [Buy/Sell],
    TIMD.InstrumentDisplayName AS [Instrument],
    CAST(TRO.Amount / 100.0 AS DECIMAL(16,2)) AS [Amount],
    TRO.Leverage AS [Leverage],
    CAST(TRO.RateFrom AS DECIMAL(16,6)) AS [Order Rate]
FROM Trade.Orders TRO WITH(NOLOCK)
JOIN Trade.InstrumentMetaData TIMD WITH(NOLOCK) ON TIMD.InstrumentID = TRO.InstrumentID
WHERE TRO.CID = 12345678
ORDER BY TRO.OccurredTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerOpenOrders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerOpenOrders.sql*
