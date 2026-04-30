# Trade.GetOrderEntry

> Returns the entry order details for a given OrderID from Trade.OrdersEntry - used to retrieve the original open order request parameters including mirror, TSL, and percentage-based stop/profit settings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderEntry` (note: the SQL object name has a trailing space - `[GetOrderEntry ]`) is a simple lookup SP that returns the entry order record from `Trade.OrdersEntry` by `@OrderID`. It returns the original open order request fields including percentage-based stop/take-profit settings, TSL flag, and mirror allocation data.

**WHY:** Used to retrieve the parameters of an open order as originally submitted by the customer or system. `Trade.OrdersEntry` captures the raw request before execution transforms the percentages into rates. Callers use this for order status display, copy-trade audit, and post-execution reconciliation.

**HOW:** Simple `SELECT ... FROM Trade.OrdersEntry WHERE OrderID = @OrderID` with `NOLOCK`. Returns at most one row.

---

## 2. Business Logic

### 2.1 Percentage vs Rate Parameters

**What:** Unlike `Trade.OrderForOpen` which stores absolute rates (StopRate, LimitRate), `Trade.OrdersEntry` stores percentage-based stop/take-profit values (`StopLosPercentage`, `TakeProfitPercentage`). These are the values the customer entered.

**Columns/Parameters Involved:** `StopLosPercentage`, `TakeProfitPercentage`

**Rules:**
- `StopLosPercentage`: percentage-based stop-loss (e.g., 50 = 50% loss triggers stop). 0 = no stop.
- `TakeProfitPercentage`: percentage-based take-profit. 0 = no take-profit.

### 2.2 Mirror Allocation at Entry

**What:** `InitialMirrorAmountInCents` captures how much of the mirror's allocated credit was used for this entry order.

**Columns/Parameters Involved:** `MirrorID`, `InitialMirrorAmountInCents`

**Rules:**
- `MirrorID > 0` -> this was a copy order placed as part of a mirror
- `InitialMirrorAmountInCents` -> the mirror amount allocated when this open order was created

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | int | NO | - | CODE-BACKED | The open order ID to retrieve. References Trade.OrdersEntry.OrderID. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | int | NO | CODE-BACKED | Primary key of the entry order. |
| R2 | CID | int | NO | CODE-BACKED | Customer who placed the open order. |
| R3 | InstrumentID | int | NO | CODE-BACKED | Financial instrument to open. |
| R4 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier requested. |
| R5 | Amount | money | NO | CODE-BACKED | Requested order amount in account currency. |
| R6 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=buy, 0=sell. |
| R7 | StopLosPercentage | decimal | YES | CODE-BACKED | Stop-loss as a percentage of position value. 0=no stop. |
| R8 | TakeProfitPercentage | decimal | YES | CODE-BACKED | Take-profit as a percentage of position value. 0=no take-profit. |
| R9 | Occurred | datetime | NO | CODE-BACKED | Timestamp when this entry order was created. |
| R10 | ParentPositionID | bigint | YES | CODE-BACKED | Parent position ID (for copy/reopen scenarios). |
| R11 | MirrorID | int | YES | CODE-BACKED | Mirror relationship this order belongs to. 0 if self-opened. |
| R12 | InitialMirrorAmountInCents | bigint | YES | CODE-BACKED | Mirror credit amount allocated at time of this entry order, in cents. |
| R13 | IsTslEnabled | bit | YES | CODE-BACKED | Whether trailing stop-loss was enabled for this order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrdersEntry | Direct query | SELECT entry order fields WHERE OrderID = @OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order entry display services | N/A | CALLER | Retrieves original open order request parameters |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderEntry (procedure)
└── Trade.OrdersEntry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | SELECT entry order fields WHERE OrderID = @OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order management services | External | Retrieves entry order record by ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** The SQL object name is `[GetOrderEntry ]` with a trailing space - this is a naming anomaly. The procedure is callable as `Trade.[GetOrderEntry ]` or using EXEC with the exact name. This may cause issues with some tools that strip trailing whitespace.

---

## 8. Sample Queries

### 8.1 Get entry order details
```sql
EXEC [Trade].[GetOrderEntry ] @OrderID = 123456789
```

### 8.2 Manual equivalent
```sql
SELECT OrderID, CID, InstrumentID, Leverage, Amount, IsBuy,
       StopLosPercentage, TakeProfitPercentage, Occurred,
       ParentPositionID, MirrorID, InitialMirrorAmountInCents, IsTslEnabled
FROM   Trade.OrdersEntry WITH (NOLOCK)
WHERE  OrderID = 123456789
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderEntry | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderEntry .sql*
