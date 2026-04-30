# Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders

> Returns pending entry (open) orders from Trade.OrdersEntry for a batch of instruments - one of the OME order matching data providers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates temp #instrumentsTable(InstrumentID) as primary key |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_EntryOrders` retrieves all pending entry (open) orders from `Trade.OrdersEntry` for a given set of instrument IDs. Entry orders are customer requests to open a new position that have not yet been matched and executed.

**WHY:** The Order Matching Engine (OME) processes orders in batches by instrument. This SP provides the OME with the pending entry order load for its assigned instruments, enabling the engine to find price matches and execute opens.

**HOW:** The caller passes a TVP of instrument IDs (`Trade.InstrumentIDsTbl`). The SP loads these into a temp table (with primary key on InstrumentID for join efficiency), then JOINs directly to `Trade.OrdersEntry` - no status filter is applied, returning all pending entry orders for the instruments.

---

## 2. Business Logic

### 2.1 Entry Order Data for OME Matching

**What:** Entry orders are pre-filled with all the data the OME needs to determine if a match is possible and to execute the open: instrument, customer, direction, amount, stop/take-profit percentages, and settings flags.

**Columns/Parameters Involved:** `OrderTypeID`, `IsTslEnabled`, `AmountInUnitsDecimal`, `OpenOpenOperationTypeID`, `SettlementTypeID`, `IsNoStopLoss`, `IsNoTakeProfit`

**Rules:**
- `IsTslEnabled`: ISNULL defaulted to 0 - Trailing Stop Loss enabled flag
- `AmountInUnitsDecimal`: ISNULL defaulted to 0 - order size in instrument units (vs. Amount in base currency)
- `OpenOpenOperationTypeID`: ISNULL defaulted to 0 - operation type for open-on-open scenarios
- `SettlementTypeID`: directly from Trade.OrdersEntry - determines Real vs. CFD settlement for this order
- `IsNoStopLoss`, `IsNoTakeProfit`: flags for no SL/TP protection orders

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with one column (InstrumentID INT). The SP returns entry orders for all instruments in this set. See Trade.InstrumentIDsTbl for full type documentation. |

**Output columns (from Trade.OrdersEntry):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique entry order ID. Primary key of Trade.OrdersEntry. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed this entry order. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument (asset) being ordered. Joined from #instrumentsTable - only instruments in the input TVP are returned. |
| 4 | Leverage | INT | NO | - | CODE-BACKED | Requested leverage multiplier for this position (e.g., 1, 2, 5, 10, 50). 1 for real stock orders. |
| 5 | Amount | DECIMAL | NO | - | CODE-BACKED | Order amount in base currency (dollars). |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long open, 0=Sell/Short open. |
| 7 | StopLosPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss threshold as a percentage of the invested amount. NULL if IsNoStopLoss=1. |
| 8 | TakeProfitPercentage | DECIMAL | YES | - | CODE-BACKED | Take-profit threshold as a percentage of the invested amount. NULL if IsNoTakeProfit=1. |
| 9 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this entry order was placed. |
| 10 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade orders: the leader's position ID being copied. NULL for manually placed orders. |
| 11 | MirrorID | BIGINT | YES | - | CODE-BACKED | For copy-trade orders: the mirror/copy relationship ID. NULL for manual orders. |
| 12 | InitialMirrorAmountInCents | INT | YES | - | CODE-BACKED | Initial amount in cents for mirror/copy-trade orders. Used for proportional copy calculation. |
| 13 | IsTslEnabled | BIT | NO | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled for this order. ISNULL defaulted to 0. |
| 14 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type classification. Distinguishes market orders from limit orders and other types. |
| 15 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size expressed in instrument units (e.g., shares for stocks). ISNULL defaulted to 0. For real stock orders this is the share count; for CFDs this may be contract units. |
| 16 | OpenOpenOperationTypeID | INT | NO | - | CODE-BACKED | Operation type for open-on-open scenarios (where a position is opened while another is already open). ISNULL defaulted to 0. |
| 17 | SettlementTypeID | TINYINT | YES | - | CODE-BACKED | Settlement type: 1=Real stock (actual share ownership), 0=CFD. Determines execution path and fee structure. |
| 18 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if this order was placed without a stop-loss (customer opted out of automatic loss protection). |
| 19 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if this order was placed without a take-profit level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Table-valued parameter type defining the input batch of instrument IDs |
| INNER JOIN | Trade.OrdersEntry | Lookup | Source of all pending entry orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument ID batch
|- Trade.OrdersEntry (view) - source of pending entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentsTable parameter |
| Trade.OrdersEntry | View | INNER JOIN - all pending entry orders filtered by instrument set |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application code (not visible in repo) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Temp table #instrumentsTable has primary key on InstrumentID)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row count messages for performance in OME batch scenarios |

---

## 8. Sample Queries

### 8.1 Execute for a set of instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2), (6)  -- Bitcoin, Ethereum, Gold

EXEC Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders
    @instrumentsTable = @instruments
```

### 8.2 Count pending entry orders by instrument

```sql
SELECT InstrumentID, COUNT(*) as PendingOrders
FROM Trade.OrdersEntry WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY PendingOrders DESC
```

### 8.3 View recent entry orders for a specific instrument

```sql
SELECT TOP 10
    OrderID, CID, InstrumentID, Amount, IsBuy, Occurred, SettlementTypeID
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE InstrumentID = 1  -- Bitcoin
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders.sql*
