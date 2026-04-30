# BackOffice.GetCustomerClosedOrders

> Returns a combined history of completed and failed pending orders for a customer within a date range, with instrument details, market range calculated in pips, and failure reasons for failed orders.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @DateFrom / @DateTo on [Date Closed]; UNION of History.Orders + History.OrdersFail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Pending orders (also called limit/stop orders) are customer-placed instructions to open a position when the market reaches a specific price. They differ from instant-execution positions: an order may remain pending for days before being triggered or cancelled.

This procedure shows the BackOffice agent the full history of closed pending orders - both orders that were eventually executed (History.Orders) and orders that failed (History.OrdersFail). The date filter applies to the close/failure date, not when the order was originally placed.

The UNION result allows the BO agent to see a complete picture: successfully triggered orders alongside failed attempts, with the [Action] column distinguishing them and [Fail Reason] providing failure detail for failed rows.

---

## 2. Business Logic

### 2.1 UNION: Completed Orders + Failed Orders

**What**: Two tables are UNIONed to produce a single order history list.

**Columns/Parameters Involved**: `History.Orders`, `History.OrdersFail`

**Rules**:
- `History.Orders` (TRO): successfully completed orders - placed and later executed or cancelled. [Date Closed] = TRO.CloseOcurred (note: typo in column name, "Ocurred" missing second 'r'). [Fail Reason] = NULL. [Duration] = DATEDIFF(MI, OpenOccurred, CloseOcurred).
- `History.OrdersFail` (TRO): orders that failed. [Date Closed] = TRO.FailOccurred. [Action] = hardcoded 'Fail'. [Fail Reason] = TRO.FailReason. [Duration] = NULL.
- The outer WHERE then applies the date filter: `T.[Date Closed] BETWEEN @DateFrom AND @DateTo`
- This means failed orders appear with Action='Fail' and a populated [Fail Reason]; completed orders show the actual action type name from Dictionary.OrdersActionType

### 2.2 Market Range in Pips

**What**: [Market Range] represents the price tolerance band of the order, expressed in instrument-native pip units.

**Columns/Parameters Involved**: `[Market Range]`, `RateFrom`, `RateTo`, `Trade.ProviderToInstrument.Precision`

**Formula**: `ABS(RateFrom - RateTo) * Power(10, Precision)`

**Rules**:
- `RateFrom` = order target rate, `RateTo` = actual execution rate (for completed orders) or last known rate (for failed)
- `Precision` from Trade.ProviderToInstrument - the number of decimal places for the instrument
- Multiplying by 10^Precision converts the rate difference to integer pip units
- Example: for EURUSD with Precision=5, a 0.0001 difference = 10 pips

### 2.3 Orphan JOIN on Trade.ProviderToInstrument

**What**: Trade.ProviderToInstrument is joined but no column from it appears in the SELECT - it provides `Precision` only.

**Columns/Parameters Involved**: `TPI (Trade.ProviderToInstrument)`

**Rules**:
- `JOIN Trade.ProviderToInstrument TPI ON TPI.InstrumentID = TRO.InstrumentID`
- `Precision` from TPI is used in the Market Range formula
- No other TPI columns are selected
- Present in both UNION branches

### 2.4 Amount Stored as Integer * 100

**What**: The Amount column in History.Orders/OrdersFail is stored as an integer * 100 to avoid floating point.

**Columns/Parameters Involved**: `Amount`, `TRO.Amount`

**Rules**:
- `TRO.Amount / 100 AS Amount` - divides by 100 to restore the actual dollar amount
- CAST to DECIMAL(16,2) in the outer SELECT

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed order history to return. Applied in both UNION branches and outer WHERE. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the date window applied to [Date Closed] (close or failure date). |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the date window applied to [Date Closed]. |
| **Output Columns** | | | | | | |
| 4 | OrderID | INT | NO | - | CODE-BACKED | Unique identifier of the order. From History.Orders.OrderID or History.OrdersFail.OrderID. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID. From History.Orders/OrdersFail.CID. |
| 6 | PositionID | INT | YES | NULL | CODE-BACKED | Position that was opened when this order executed. From History.Position.PositionID via OrderID LEFT JOIN (completed orders only). NULL for failed orders (no position created). |
| 7 | Buy/Sell | VARCHAR(4) | NO | - | CODE-BACKED | Trade direction: 'Buy' when IsBuy=1, 'Sell' otherwise. |
| 8 | Instrument | NVARCHAR | NO | - | CODE-BACKED | Display name of the traded instrument. From Trade.InstrumentMetaData.InstrumentDisplayName. |
| 9 | Instrument ID | INT | NO | - | CODE-BACKED | Numeric instrument identifier. From Trade.InstrumentMetaData.InstrumentID. |
| 10 | Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Order amount in account currency. TRO.Amount / 100 (stored as integer*100 in source table). |
| 11 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier applied to the order. |
| 12 | Units | DECIMAL | YES | - | CODE-BACKED | Number of instrument units in the order. |
| 13 | Date Opened | DATETIME | YES | - | CODE-BACKED | When the order was originally placed. TRO.OpenOccurred (completed) or TRO.OpenOccurredTime (failed). |
| 14 | Date Closed | DATETIME | YES | - | CODE-BACKED | When the order was closed or failed. TRO.CloseOcurred (completed; typo in column name) or TRO.FailOccurred (failed). Date range filter applied to this column. |
| 15 | Order Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | The target price of the order. From TRO.RateFrom. |
| 16 | Market Range | DECIMAL(16,4) | YES | - | CODE-BACKED | Price tolerance band in pip units: ABS(RateFrom-RateTo) * Power(10, Precision). Represents how far the actual execution price can deviate from the order rate. |
| 17 | Stop Loss | DECIMAL(16,4) | YES | - | CODE-BACKED | Stop-loss rate set on the order. From TRO.StopLosRate (note: typo in source column name). |
| 18 | Take Profit | DECIMAL(16,4) | YES | - | CODE-BACKED | Take-profit rate set on the order. From TRO.TakeProfitRate. |
| 19 | Action | NVARCHAR | YES | - | CODE-BACKED | Action type name for completed orders (from Dictionary.OrdersActionType.ActionName via ActionTypeID). Hardcoded 'Fail' for failed orders from History.OrdersFail. |
| 20 | Fail Reason | NVARCHAR | YES | NULL | CODE-BACKED | Failure description for orders from History.OrdersFail. NULL for completed orders from History.Orders. |
| 21 | Duration | INT | YES | NULL | CODE-BACKED | Time the order was active in minutes: DATEDIFF(MI, DateOpened, DateClosed). NULL for failed orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / OrderID | History.Orders | Primary Source (branch 1) | Completed order history records |
| CID / OrderID | History.OrdersFail | Primary Source (branch 2) | Failed order records |
| InstrumentID | Trade.InstrumentMetaData | Lookup / JOIN | Resolves instrument ID to display name |
| InstrumentID | Trade.ProviderToInstrument | Lookup / JOIN | Provides Precision for Market Range pip calculation |
| ActionTypeID | Dictionary.OrdersActionType | Lookup / LEFT JOIN | Resolves action type to name (completed orders only) |
| OrderID | History.Position | Lookup / LEFT JOIN | Links completed orders to resulting positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called by BackOffice customer profile closed orders tab |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerClosedOrders (procedure)
|- History.Orders (completed orders)
|- History.OrdersFail (failed orders)
|- Trade.InstrumentMetaData (instrument display name)
|- Trade.ProviderToInstrument (precision for pip calculation)
|- Dictionary.OrdersActionType (action type name)
+-- History.Position (position ID from order)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Orders | Table | Primary source branch 1 - completed order records |
| History.OrdersFail | Table | Primary source branch 2 - failed order records |
| Trade.InstrumentMetaData | Table | JOINed to resolve InstrumentID to display name |
| Trade.ProviderToInstrument | Table | JOINed to get Precision for Market Range formula |
| Dictionary.OrdersActionType | Table | LEFT JOINed to resolve ActionTypeID to action name |
| History.Position | Table | LEFT JOINed to get PositionID for executed orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Customer closed orders history tab |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- The date filter is applied on the outer SELECT (not inside UNION branches): `WHERE T.CID = @CID AND T.[Date Closed] BETWEEN @DateFrom AND @DateTo`. This means both UNION branches are fully executed for the CID before the date filter narrows results - a potential performance inefficiency for customers with long order histories.
- `ORDER BY T.[Date Opened] DESC` - most recently placed orders appear first.

---

## 8. Sample Queries

### 8.1 Get all closed orders in a date range

```sql
EXEC BackOffice.GetCustomerClosedOrders
    @CID      = 12345678,
    @DateFrom = '2026-01-01',
    @DateTo   = '2026-03-17';
```

### 8.2 Get only failed orders

```sql
-- Run SP and filter client-side, or query directly:
SELECT TRO.OrderID, TRO.CID, TIMD.InstrumentDisplayName, TRO.FailReason, TRO.FailOccurred
FROM History.OrdersFail TRO WITH(NOLOCK)
JOIN Trade.InstrumentMetaData TIMD WITH(NOLOCK) ON TIMD.InstrumentID = TRO.InstrumentID
WHERE TRO.CID = 12345678
    AND TRO.FailOccurred BETWEEN '2026-01-01' AND '2026-03-17'
ORDER BY TRO.FailOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerClosedOrders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerClosedOrders.sql*
