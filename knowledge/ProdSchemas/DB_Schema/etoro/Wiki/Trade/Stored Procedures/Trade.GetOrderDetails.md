# Trade.GetOrderDetails

> Returns the full details of a single order record from Trade.Orders by OrderID - used to retrieve order configuration including settlement type, leverage, and spread settings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderDetails` is a simple single-row lookup SP that returns the full set of order parameters for a given `OrderID` from `Trade.Orders`. It returns all fields needed to understand what was ordered: instrument, leverage, stop/take-profit rates, amounts, units, margin, settlement type, and spread rates.

**WHY:** Used by services that need to retrieve the original order configuration after an order has been placed - for example, to validate execution parameters, display order details in the UI, or audit what was requested.

**HOW:** Simple `SELECT ... FROM Trade.Orders WHERE OrderID = @OrderID` with `NOLOCK`. Returns at most one row.

---

## 2. Business Logic

### 2.1 Order Record Lookup

**What:** Fetches the complete order record. `Trade.Orders` stores the final order parameters at submission time.

**Columns/Parameters Involved:** `OrderID`

**Rules:**
- Returns 0 or 1 rows (OrderID is unique in Trade.Orders)
- Uses `NOLOCK` for read performance

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The order ID to retrieve. References Trade.Orders.OrderID. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | Primary key of the order. |
| R2 | CID | int | NO | CODE-BACKED | Customer who placed the order. |
| R3 | CurrencyID | int | NO | CODE-BACKED | Account currency denomination (1=USD). |
| R4 | OrderTypeID | int | NO | CODE-BACKED | Type of the order. References Dictionary.OrderType. |
| R5 | ProviderID | int | YES | CODE-BACKED | Liquidity provider for execution. |
| R6 | InstrumentID | int | NO | CODE-BACKED | Financial instrument being ordered. |
| R7 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier. |
| R8 | StopLosRate | money | YES | CODE-BACKED | Stop-loss rate at order time. |
| R9 | TakeProfitRate | money | YES | CODE-BACKED | Take-profit rate at order time. |
| R10 | Amount | money | NO | CODE-BACKED | Order amount in account currency. |
| R11 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=buy, 0=sell. |
| R12 | Units | decimal | YES | CODE-BACKED | Order size in instrument units. |
| R13 | LotCountDecimal | decimal | YES | CODE-BACKED | Order size in lots. |
| R14 | UnitMargin | money | YES | CODE-BACKED | Margin per unit at order time. |
| R15 | RateFrom | money | YES | CODE-BACKED | Lower bound of acceptable execution rate range. |
| R16 | RateTo | money | YES | CODE-BACKED | Upper bound of acceptable execution rate range. |
| R17 | TradeRange | money | YES | CODE-BACKED | Allowed slippage/range for execution. |
| R18 | IsSettled | bit | YES | CODE-BACKED | Whether this is a stock settlement order. |
| R19 | SettlementTypeID | tinyint | YES | CODE-BACKED | Settlement type: 0=not set, 1=Real, 2=Virtual. |
| R20 | IsDiscounted | bit | YES | CODE-BACKED | Whether commission discount applies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.Orders | Direct query | SELECT full row WHERE OrderID = @OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order display / audit services | N/A | CALLER | Retrieves order configuration by ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderDetails (procedure)
└── Trade.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | SELECT all order fields WHERE OrderID = @OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application order services | External | Retrieves order parameters by ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `WITH (NOLOCK)`. Simple point-lookup by primary key.

---

## 8. Sample Queries

### 8.1 Get order details
```sql
EXEC Trade.GetOrderDetails @OrderID = 987654321
```

### 8.2 Manual equivalent
```sql
SELECT OrderID, CID, CurrencyID, OrderTypeID, ProviderID, InstrumentID,
       Leverage, StopLosRate, TakeProfitRate, Amount, IsBuy, Units,
       LotCountDecimal, UnitMargin, RateFrom, RateTo, TradeRange,
       IsSettled, SettlementTypeID, IsDiscounted
FROM   Trade.Orders WITH (NOLOCK)
WHERE  OrderID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderDetails | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderDetails.sql*
