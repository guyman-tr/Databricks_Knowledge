# BackOffice.GetEntryOrders

> Returns all entry (position-open) orders for a customer - both completed synchronous orders from Trade.OrdersEntry and pending WAITING_FOR_MARKET async orders from Trade.OrderForOpen - with the IsAsync flag to distinguish source.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CID lookup; returns UNION of Trade.OrdersEntry + Trade.OrderForOpen (StatusID=11) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetEntryOrders provides BackOffice staff with a complete view of a customer's position-open (entry) order history. It combines two Trade schema tables: `Trade.OrdersEntry` (the archive of completed entry orders that were processed synchronously) and `Trade.OrderForOpen` (orders still WAITING_FOR_MARKET - limit/entry orders waiting for the right price before execution).

This UNION is necessary because an active "entry order" can exist in either table depending on its processing state: synchronously processed orders land in OrdersEntry, while orders waiting for a market price trigger remain in OrderForOpen until the price is reached. The `IsAsync` flag tells the caller which source each row came from.

---

## 2. Business Logic

### 2.1 UNION of Two Order Tables

**What**: The result combines completed entry orders and pending WAITING_FOR_MARKET orders into a single result set.

**Columns/Parameters Involved**: `Trade.OrdersEntry`, `Trade.OrderForOpen`, `IsAsync`, `StatusID=11`

**Rules**:
- **Set 1 (IsAsync=0)**: All rows from `Trade.OrdersEntry` for the customer - these are completed synchronous entry orders. No status filter (all rows for this CID).
- **Set 2 (IsAsync=1)**: Rows from `Trade.OrderForOpen` WHERE `StatusID = 11` (WAITING_FOR_MARKET) - limit/entry orders waiting for the market price to reach the target before execution. Only the 11 status is included; other statuses (PLACED=2, RECEIVED=1, etc.) are excluded.
- UNION (not UNION ALL) is not specified in the DDL - it's a regular UNION which deduplicates; however since OrdersEntry and OrderForOpen have different PKs (OrderID from different tables), deduplication is unlikely to occur in practice.
- `InitialMirrorAmountInCents`: For OrdersEntry, this is the column value directly. For OrderForOpen, it is `ISNULL(m.InitialInvestment * 100, 0)` - calculated from Trade.Mirror.InitialInvestment (converted to cents).

### 2.2 Column Name Discrepancy

**What**: The `StopLoss` column has a typo in Trade.OrdersEntry that is silently resolved by column position in the UNION.

**Rules**:
- `Trade.OrdersEntry.StopLosPercentage` (missing 's', typo) is returned as the same output column position as `Trade.OrderForOpen.StopLossPercentage` (correct spelling)
- The UNION uses column position for matching, so the output column name is determined by the first SELECT (= `StopLosPercentage`)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID whose entry orders are to be retrieved. Filters both Trade.OrdersEntry and Trade.OrderForOpen. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | OrderID | bigint | NO | - | CODE-BACKED | Unique order identifier. From Trade.OrdersEntry.OrderID or Trade.OrderForOpen.OrderID. Note: IDs from different tables, no overlap expected. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID. Always equals @CID. |
| R3 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument (asset) for the order. FK to Dictionary/Trade instrument tables. |
| R4 | InstrumentDisplayName | nvarchar | YES | - | CODE-BACKED | Human-readable instrument name (e.g., "Apple", "EUR/USD"). From Trade.InstrumentMetaData.InstrumentDisplayName via INNER JOIN. |
| R5 | Amount | money | YES | - | CODE-BACKED | Order size in USD. The notional value of the position to be opened. |
| R6 | IsBuy | bit | NO | - | CODE-BACKED | Order direction. 1=Buy (long position), 0=Sell (short/CFD position). |
| R7 | StopLosPercentage | decimal | YES | - | CODE-BACKED | Stop-loss threshold as a percentage of the position. Note: column name has a typo ("StopLos" missing 's') - inherited from Trade.OrdersEntry.StopLosPercentage. NULL if no stop-loss set. |
| R8 | TakeProfitPercentage | decimal | YES | - | CODE-BACKED | Take-profit threshold as a percentage of the position. NULL if no take-profit set. |
| R9 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp of the order event. From Trade.OrdersEntry.Occurred or Trade.OrderForOpen.OpenOccurred. |
| R10 | ParentPositionID | bigint | YES | - | CODE-BACKED | For copy-trading orders: the position ID of the original trader's position that triggered this copy. NULL for manually placed orders. |
| R11 | MirrorID | int | YES | - | CODE-BACKED | For CopyTrader orders: the mirror relationship ID linking this order to the copy (social trading) session. NULL for non-copy orders. FK to Trade.Mirror. |
| R12 | InitialMirrorAmountInCents | bigint | NO | - | CODE-BACKED | For CopyTrader orders: the initial investment amount for the copy session in cents. From Trade.OrdersEntry directly or calculated as Trade.Mirror.InitialInvestment * 100 (ISNULL -> 0). 0 for non-copy orders. |
| R13 | IsAsync | bit | NO | - | CODE-BACKED | Source indicator. 0 = order came from Trade.OrdersEntry (synchronous/completed order). 1 = order came from Trade.OrderForOpen with StatusID=11 (WAITING_FOR_MARKET - async pending order). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TOEnt (first) | Trade.OrdersEntry | SELECT | Completed synchronous entry orders for the customer |
| TOEnt (second) | Trade.OrderForOpen | SELECT | Pending WAITING_FOR_MARKET async orders (StatusID=11) |
| TIMD | Trade.InstrumentMetaData | INNER JOIN | Provides InstrumentDisplayName for both sets |
| m | Trade.Mirror | LEFT JOIN | Provides InitialInvestment for CopyTrader orders in the async set |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from BackOffice UI to display a customer's entry order history for operations staff.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetEntryOrders (procedure)
├── Trade.OrdersEntry (table - cross-schema)
├── Trade.OrderForOpen (table - cross-schema)
├── Trade.InstrumentMetaData (table - cross-schema)
└── Trade.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | SET 1 of UNION - completed synchronous entry orders for @CID |
| Trade.OrderForOpen | Table | SET 2 of UNION - pending WAITING_FOR_MARKET orders (StatusID=11) for @CID |
| Trade.InstrumentMetaData | Table | INNER JOIN on InstrumentID to get InstrumentDisplayName (both sets) |
| Trade.Mirror | Table | LEFT JOIN on MirrorID to get InitialInvestment for CopyTrader orders (second set only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice UI | External | READER - displays entry order history for a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Both Trade.OrdersEntry and Trade.OrderForOpen have CID-based indexes. Trade.OrderForOpen has `ix_CID NONCLUSTERED (CID, InstrumentID, StatusID, SettlementTypeID)` which efficiently supports the StatusID=11 + CID filter.

### 7.2 Constraints

N/A for Stored Procedure. SET NOCOUNT ON is present. The UNION (not UNION ALL) performs deduplication, though in practice no overlap between OrdersEntry and OrderForOpen PKs is expected.

---

## 8. Sample Queries

### 8.1 Get all entry orders for a customer
```sql
EXEC BackOffice.GetEntryOrders @CID = 12345
-- Returns: OrderID, CID, InstrumentID, InstrumentDisplayName, Amount, IsBuy,
--          StopLosPercentage, TakeProfitPercentage, Occurred, ParentPositionID,
--          MirrorID, InitialMirrorAmountInCents, IsAsync
```

### 8.2 Filter by IsAsync to see only pending WAITING_FOR_MARKET orders
```sql
-- Ad-hoc equivalent for pending async orders only
SELECT
    tof.OrderID, tof.CID, tof.InstrumentID, timd.InstrumentDisplayName,
    tof.Amount, tof.IsBuy, tof.StopLossPercentage, tof.TakeProfitPercentage,
    tof.OpenOccurred AS Occurred, tof.MirrorID,
    1 AS IsAsync
FROM Trade.OrderForOpen tof WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData timd WITH (NOLOCK) ON timd.InstrumentID = tof.InstrumentID
WHERE tof.CID = 12345
  AND tof.StatusID = 11  -- WAITING_FOR_MARKET
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetEntryOrders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetEntryOrders.sql*
