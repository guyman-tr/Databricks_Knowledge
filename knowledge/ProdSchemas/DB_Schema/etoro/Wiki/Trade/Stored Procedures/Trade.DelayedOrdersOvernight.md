# Trade.DelayedOrdersOvernight

> Operational support query that returns all delayed open and close orders placed overnight, with optional filtering by CID, symbol, position, date, and Apex account.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Combined result set from DelayedOrderForOpen UNION DelayedOrderForClose |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DelayedOrdersOvernight is an operational support procedure that retrieves delayed orders (both open and close) placed during overnight hours. It returns a unified view of pending limit/stop orders from Trade.DelayedOrderForOpen and Trade.DelayedOrderForClose, enriched with instrument symbol (from InstrumentMetaData) and Apex account ID (from Customer.CustomerStatic).

This procedure exists to support the US equity overnight delayed-order monitoring workflow. Because US market orders placed outside trading hours are queued as delayed orders, the operations team needs visibility into what orders are pending for the next market open. The default time window is the past 24 hours (in Eastern Standard Time), but all parameters are optional for flexible querying.

Data flows from two memory-optimized tables (DelayedOrderForOpen and DelayedOrderForClose) via UNION, with LEFT JOINs to InstrumentMetaData for the symbol name and Customer.CustomerStatic for the Apex brokerage account ID. When @positionID is NULL, both open and close orders are returned; when @positionID is provided, only close orders matching that position are returned (open orders have no PositionID).

---

## 2. Business Logic

### 2.1 Time Zone Conversion for Overnight Window

**What**: Requests are filtered by Eastern Standard Time to align with US market hours.

**Columns/Parameters Involved**: `@requestOccurred`, `RequestOccurred`

**Rules**:
- RequestOccurred is converted from UTC to Eastern Standard Time before comparison
- Default window (when @requestOccurred IS NULL): past 24 hours from current UTC time
- Explicit window (when @requestOccurred IS NOT NULL): the full day from @requestOccurred to @requestOccurred + 1 day
- This ensures the view aligns with US market overnight periods

### 2.2 Unified Open + Close Order View

**What**: UNION combines both order types into a single result set with a shared column layout.

**Columns/Parameters Involved**: All output columns

**Rules**:
- Open orders contribute: all order fields plus copy-trading context (ParentCID, IsBuy, Leverage, Amount, MirrorID, etc.)
- Close orders contribute: order fields plus ActionType and PositionID; copy-trading fields are NULL
- The UNION ensures both order types appear in a single sortable result

### 2.3 Position-Specific Close Order Lookup

**What**: When @positionID is provided, only close orders for that position are returned.

**Columns/Parameters Involved**: `@positionID`

**Rules**:
- If @positionID IS NULL: returns UNION of both open and close orders (full overnight view)
- If @positionID IS NOT NULL: returns only close orders from DelayedOrderForClose matching that PositionID
- This branch is used for targeted investigation of a specific position's pending close orders

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. When provided, restricts results to orders for this customer. |
| 2 | @lastUpdate | DATE | YES | NULL | CODE-BACKED | Optional last-update date filter. When provided, returns orders updated on this date (through midnight). |
| 3 | @symbol | INT | YES | NULL | CODE-BACKED | Optional instrument symbol filter. Compared case-insensitively against InstrumentMetaData.Symbol. |
| 4 | @requestOccurred | DATE | YES | NULL | CODE-BACKED | Optional request date filter. When NULL, defaults to past 24 hours in Eastern time. When provided, returns orders requested on that date. |
| 5 | @apexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Optional Apex brokerage account ID filter. Matched against Customer.CustomerStatic.ApexID. |
| 6 | @positionID | BIGINT | YES | NULL | CODE-BACKED | Optional position ID filter. When provided, switches to close-order-only mode for that specific position. When NULL, returns both open and close orders. |

**Output Columns**:

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | RequestIdentifier | BIGINT | CODE-BACKED | Unique identifier for the delayed order request. |
| 2 | ApexAccountID | VARCHAR | CODE-BACKED | Apex brokerage account identifier from Customer.CustomerStatic. |
| 3 | OrderID | BIGINT | CODE-BACKED | Order identifier in the delayed order queue. |
| 4 | OriginalOrderID | BIGINT | CODE-BACKED | Original order ID before any modifications. |
| 5 | CID | INT | CODE-BACKED | Customer identifier. |
| 6 | PositionID | BIGINT | CODE-BACKED | Position ID (close orders only; NULL for open orders). |
| 7 | InstrumentID | INT | CODE-BACKED | Financial instrument identifier. |
| 8 | Symbol | VARCHAR | CODE-BACKED | Instrument symbol name from Trade.InstrumentMetaData. |
| 9 | RequestOccurred | DATETIME | CODE-BACKED | Timestamp when the delayed order was placed. |
| 10 | LastUpdate | DATETIME | CODE-BACKED | Timestamp of the last status change. |
| 11 | ActionType | INT | CODE-BACKED | Close action type (close orders only; NULL for open orders). |
| 12 | StatusID | INT | CODE-BACKED | Current order status: 1=PLACED, 2=FILLED, 3=REMOVED. |
| 13 | ParentCID | INT | CODE-BACKED | Parent customer for copy-traded open orders; NULL for close orders. |
| 14 | IsBuy | BIT | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short (open orders only; NULL for close orders). |
| 15 | Leverage | INT | CODE-BACKED | Leverage multiplier (open orders only; NULL for close orders). |
| 16 | Amount | MONEY | CODE-BACKED | Order amount (open orders only; NULL for close orders). |
| 17 | MirrorID | INT | CODE-BACKED | Copy-trading mirror identifier (open orders only; NULL for close orders). |
| 18 | ParentPositionID | BIGINT | CODE-BACKED | Parent position in copy-trading hierarchy (open orders only; NULL for close orders). |
| 19 | TreeID | BIGINT | CODE-BACKED | Copy-trade tree identifier (open orders only; NULL for close orders). |
| 20 | RootSettlementType | INT | CODE-BACKED | Settlement type of the root/leader position (open orders only; NULL for close orders). |
| 21 | SettlementType | INT | CODE-BACKED | Settlement type of this order: 0=CFD, 1=Real, etc. (open orders only; NULL for close orders). |
| 22 | IsCopyFund | BIT | CODE-BACKED | Whether order originates from a CopyFund (open orders only; NULL for close orders). |
| 23 | OpenActionType | INT | CODE-BACKED | Open action type classification (open orders only; NULL for close orders). |
| 24 | CorrelationID | UNIQUEIDENTIFIER | CODE-BACKED | Correlation ID linking related order events (open orders only; NULL for close orders). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Trade.DelayedOrderForOpen | READ | Source for pending open orders with NOLOCK |
| (FROM) | Trade.DelayedOrderForClose | READ | Source for pending close orders with NOLOCK |
| (JOIN) | Trade.InstrumentMetaData | READ | LEFT JOIN to resolve InstrumentID to Symbol |
| (JOIN) | Customer.CustomerStatic | READ | LEFT JOIN to resolve CID to ApexID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FunDelayedOrdersOvernight | Reference | Function Wrapper | Table-valued function wrapper for this procedure |
| BIReader role | GRANT | Permission | EXECUTE permission granted for BI reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelayedOrdersOvernight (procedure)
+-- Trade.DelayedOrderForOpen (table, memory-optimized)
+-- Trade.DelayedOrderForClose (table, memory-optimized)
+-- Trade.InstrumentMetaData (table)
+-- Customer.CustomerStatic (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForOpen | Table | Read for pending open orders |
| Trade.DelayedOrderForClose | Table | Read for pending close orders |
| Trade.InstrumentMetaData | Table | LEFT JOIN to resolve instrument symbol |
| Customer.CustomerStatic | Table | LEFT JOIN to resolve Apex account ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FunDelayedOrdersOvernight | Function | Table-valued function wrapper around this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all overnight delayed orders (default 24h window)

```sql
EXEC Trade.DelayedOrdersOvernight
```

### 8.2 Get overnight orders for a specific customer

```sql
EXEC Trade.DelayedOrdersOvernight @CID = 12345
```

### 8.3 Get overnight orders for a specific date and symbol

```sql
EXEC Trade.DelayedOrdersOvernight @requestOccurred = '2026-03-14', @symbol = 1001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 6.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DelayedOrdersOvernight | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DelayedOrdersOvernight.sql*
