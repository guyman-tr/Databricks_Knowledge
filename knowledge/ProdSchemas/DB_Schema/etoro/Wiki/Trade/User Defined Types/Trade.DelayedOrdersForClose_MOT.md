# Trade.DelayedOrdersForClose_MOT

> Memory-optimized table-valued parameter (TVP) for passing delayed close orders to mirror/copy-trade data API procedures when market is closed or conditions are not met for immediate execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID (bigint) |
| **Partition** | N/A |
| **Indexes** | 1 nonclustered (IX_OrderID on OrderID) |

---

## 1. Business Meaning

Trade.DelayedOrdersForClose_MOT is a memory-optimized table type (MOT) used as a table-valued parameter for batch processing of delayed close orders in mirror and copy-trade data API procedures. When the market is closed or other conditions prevent immediate execution, close orders are queued for later processing. This type carries the order details needed for that batch processing.

The type enables efficient bulk handling of delayed close orders without row-by-row round-trips. Procedures like GetMirrorDataWithCIDAndMirrorIdForAPI and GetMirrorDataWithCIDForAPI receive this TVP, JOIN against it, and process all delayed close orders in one pass.

Application services and jobs populate this type with OrderID, CID, PositionID, RequestOccurred, and InstrumentID for each delayed close order. The index on OrderID supports fast lookups during the JOIN operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a parameter container for delayed close order batch processing.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Order identifier. Used for lookups during mirror data API processing. Index on this column supports fast JOINs. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - the account that owns the close order. Used to scope mirror data retrieval. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Position being closed. Links the delayed order to the open position. |
| 4 | RequestOccurred | datetime | NO | - | CODE-BACKED | When the close request was made. Used for ordering and audit. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | Instrument (symbol) of the position. References the traded asset. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderTbl | Implicit | Order identifier |
| CID | Customer.CustomerTbl | Implicit | Customer account |
| PositionID | Trade.PositionTbl | Implicit | Position being closed |
| InstrumentID | Dictionary.Instrument | Implicit | Traded instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Parameter (TVP) | Parameter | Receives delayed close orders for mirror data retrieval |
| Trade.GetMirrorDataWithCIDForAPI | Parameter (TVP) | Parameter | Receives delayed close orders for mirror data retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Stored Procedure | READONLY parameter for mirror data with mirror ID |
| Trade.GetMirrorDataWithCIDForAPI | Stored Procedure | READONLY parameter for mirror data by CID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_OrderID | NONCLUSTERED | OrderID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Populate and pass delayed close orders to mirror API

```sql
DECLARE @DelayedOrders Trade.DelayedOrdersForClose_MOT;
INSERT INTO @DelayedOrders (OrderID, CID, PositionID, RequestOccurred, InstrumentID)
SELECT OrderID, CID, PositionID, RequestOccurred, InstrumentID
FROM   Trade.OrderTbl WITH (NOLOCK)
WHERE  OrderStatusID = 5;

EXEC Trade.GetMirrorDataWithCIDForAPI @DelayedOrdersForClose = @DelayedOrders;
```

### 8.2 Pass single delayed close order for API processing

```sql
DECLARE @Orders Trade.DelayedOrdersForClose_MOT;
INSERT INTO @Orders (OrderID, CID, PositionID, RequestOccurred, InstrumentID)
VALUES (12345678, 50001, 98765432, GETUTCDATE(), 1);

EXEC Trade.GetMirrorDataWithCIDAndMirrorIdForAPI @DelayedOrdersForClose = @Orders;
```

### 8.3 Build TVP from multiple rows and pass to mirror API with MirrorID

```sql
DECLARE @Delayed Trade.DelayedOrdersForClose_MOT;
INSERT INTO @Delayed (OrderID, CID, PositionID, RequestOccurred, InstrumentID)
VALUES (100001, 50001, 200001, GETUTCDATE(), 1),
       (100002, 50001, 200002, GETUTCDATE(), 2);

EXEC Trade.GetMirrorDataWithCIDAndMirrorIdForAPI @DelayedOrdersForClose = @Delayed, @MirrorID = @MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DelayedOrdersForClose_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DelayedOrdersForClose_MOT.sql*
