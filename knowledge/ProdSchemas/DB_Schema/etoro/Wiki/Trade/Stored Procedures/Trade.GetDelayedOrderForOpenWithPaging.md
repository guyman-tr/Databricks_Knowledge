# Trade.GetDelayedOrderForOpenWithPaging

> Natively compiled procedure that reads delayed open orders with cursor-based paging from the memory-optimized DelayedOrderForOpen table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure (Natively Compiled) |
| **Key Identifier** | @RequestIdentifier + @LastUpdate + @StatusID (paging cursor) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDelayedOrderForOpenWithPaging is a natively compiled procedure that reads delayed open orders from the memory-optimized Trade.DelayedOrderForOpen table using cursor-based pagination. It is the open-order counterpart to Trade.GetDelayedOrderForCloseWithPaging. The Dreq (Delayed Request) service polls this procedure to consume pending position-open requests.

This procedure exists because in the CopyTrader and delayed execution flows, position opens are queued for asynchronous processing. The procedure returns a batch of pending open orders sorted by RequestIdentifier, enabling the service to process them in order without missing or duplicating entries.

Data flows directly from Trade.DelayedOrderForOpen, filtered by StatusID and paged by RequestIdentifier/LastUpdate cursor.

---

## 2. Business Logic

### 2.1 Cursor-Based Paging

**What**: Uses RequestIdentifier and LastUpdate as a compound cursor for resumable batch reads.

**Columns/Parameters Involved**: `@RequestIdentifier`, `@LastUpdate`, `@MaxRead`, `@StatusID`

**Rules**:
- When @LastUpdate IS NULL or equals the current row's LastUpdate: advance by RequestIdentifier > @RequestIdentifier
- When LastUpdate > @LastUpdate: all rows with later LastUpdate qualify
- TOP(@MaxRead) limits the batch size
- ORDER BY LastUpdate (when @LastUpdate IS NOT NULL), then RequestIdentifier

### 2.2 Copy-Trade Open Order Data

**What**: Returns all fields needed to process a delayed position open, including copy-trade context.

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`, `TreeID`, `RootSettlementType`, `SettlementType`, `IsCopyFund`, `OpenActionType`

**Rules**:
- MirrorID > 0 indicates a CopyTrader-initiated open
- ParentPositionID links to the parent position being copied
- TreeID groups the position into its copy-trade tree
- RootSettlementType and SettlementType determine real stock vs CFD handling
- IsCopyFund indicates whether this is a Smart Portfolio (fund) copy open

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestIdentifier | bigint | NO | - | CODE-BACKED | Cursor position: last processed RequestIdentifier. Pass 0 on first call. |
| 2 | @LastUpdate | datetime | YES | NULL | CODE-BACKED | Cursor position: last processed LastUpdate. NULL on first call. |
| 3 | @MaxRead | int | NO | - | CODE-BACKED | Maximum number of rows to return per batch. |
| 4 | @StatusID | int | NO | - | CODE-BACKED | Filter to specific order status (typically 1=pending). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestIdentifier | bigint | NO | - | CODE-BACKED | Unique identifier for this delayed request row. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Order ID grouping this delayed open request. |
| 3 | OriginalOrderID | int | YES | - | CODE-BACKED | Original order ID if this is a resubmission. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 5 | ParentCID | int | YES | - | CODE-BACKED | Parent customer being copied (for CopyTrader opens). |
| 6 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the open request was created. |
| 7 | LastUpdate | datetime | YES | - | CODE-BACKED | Last update timestamp for paging cursor. |
| 8 | InstrumentID | int | NO | - | CODE-BACKED | Instrument to open a position in. |
| 9 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 10 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. |
| 11 | Amount | money | NO | - | CODE-BACKED | Position amount in denomination currency. |
| 12 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0 = manual. |
| 13 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position being copied. |
| 14 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree identifier. |
| 15 | RootSettlementType | tinyint | YES | - | CODE-BACKED | Settlement type of the tree root position. |
| 16 | SettlementType | tinyint | YES | - | CODE-BACKED | Settlement type for this specific position. |
| 17 | IsCopyFund | bit | YES | - | CODE-BACKED | Whether this is a Smart Portfolio (fund) copy open. |
| 18 | OpenActionType | int | YES | - | CODE-BACKED | Type of open action (1=manual, 16=copy, etc.). |
| 19 | CorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID for distributed tracing. |
| 20 | StatusID | int | NO | - | CODE-BACKED | Current status of this delayed order row. |
| 21 | RootHedgeServerID | int | YES | - | CODE-BACKED | Hedge server of the tree root position. |
| 22 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Unique GUID for request deduplication. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.DelayedOrderForOpen | FROM | Memory-optimized delayed open orders table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDelayedOrderForOpenWithPaging (procedure)
+-- Trade.DelayedOrderForOpen (table, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForOpen | Table (memory-optimized) | FROM for paged reads |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by Dreq service (application layer) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- **Natively compiled** with SCHEMABINDING
- ATOMIC with SNAPSHOT isolation
- Language: us_english

---

## 8. Sample Queries

### 8.1 First batch read of pending open orders

```sql
EXEC Trade.GetDelayedOrderForOpenWithPaging
    @RequestIdentifier = 0,
    @LastUpdate = NULL,
    @MaxRead = 100,
    @StatusID = 1;
```

### 8.2 Resume from a previous batch

```sql
EXEC Trade.GetDelayedOrderForOpenWithPaging
    @RequestIdentifier = 80123,
    @LastUpdate = '2026-03-16 10:00:00',
    @MaxRead = 100,
    @StatusID = 1;
```

### 8.3 Direct query for pending delayed opens

```sql
SELECT  TOP 100 RequestIdentifier, OrderID, CID, InstrumentID, IsBuy, Amount, MirrorID
FROM    Trade.DelayedOrderForOpen WITH (NOLOCK)
WHERE   StatusID = 1
ORDER BY RequestIdentifier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDelayedOrderForOpenWithPaging | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDelayedOrderForOpenWithPaging.sql*
