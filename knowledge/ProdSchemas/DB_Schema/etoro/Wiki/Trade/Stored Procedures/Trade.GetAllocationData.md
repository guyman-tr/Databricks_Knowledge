# Trade.GetAllocationData

> Retrieves allocation request data from the hedge provider (Apex) with ALE event status and instrument metadata, supporting multiple optional filters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched allocation request log with ALE event tracking and instrument details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure serves the operations dashboard for monitoring stock allocation requests between eToro and its hedge/clearing provider (Apex). When real stock positions are opened or closed, allocation requests are sent to Apex for share settlement. This procedure retrieves the complete allocation request log with enrichment from ALE (Allocation Lifecycle Events), providing operations teams with visibility into allocation status, errors, and instrument details.

The procedure exists because stock allocation is a critical settlement process that requires monitoring. Failed allocations mean shares were not properly settled, which has regulatory and financial implications. Operations teams use this to track allocation health, investigate failures, and reconcile positions.

Data flows from `dbo.SynAllocationGetRequestLog` (Azure synonym - allocation requests) enriched with `dbo.SynHedgeApexAleEvent` (ALE lifecycle events), `dbo.SynHedgeApexAleEventMessage` (ALE error messages), `dbo.SynHedgeAllocationRequests` (dealing requests), `dbo.SynHedgeAllocationSource` (allocation source type), and `Trade.InstrumentMetaData` (instrument display info). Uses a temp table for performance isolation between the Azure data read and the local join.

---

## 2. Business Logic

### 2.1 Multi-Filter Optional Queries

**What**: All filter parameters are optional using OR-NULL patterns.

**Columns/Parameters Involved**: `@date`, `@cid`, `@instrumentID`, `@isBuy`, `@apexAccountID`, `@ExternalID`, `@PositionID`

**Rules**:
- Each filter uses `(@param = column OR @param IS NULL)` pattern
- Date filter uses `CONVERT(date, RequestDateTime) = @date` for date-only comparison
- Symbol filter is case-insensitive: `LOWER(@symbol) = LOWER(tim.Symbol)`
- All filters are AND-combined (cumulative filtering)

### 2.2 Two-Stage Query Pattern

**What**: Separates Azure data retrieval from local enrichment for performance.

**Columns/Parameters Involved**: Temp table `#tbl_temp_ExternalOperations_Data`

**Rules**:
- Stage 1: Read and filter Azure synonym tables into a temp table with all filters applied
- Stage 2: JOIN the temp table to local Trade.InstrumentMetaData for symbol/name enrichment
- Symbol filter applies only in Stage 2 (requires InstrumentMetaData)
- This separation avoids cross-database JOIN performance issues

### 2.3 Account Direction Logic

**What**: FromAccount/ToAccount swap based on whether the allocation is an open or close.

**Columns/Parameters Involved**: `IsOpen`, `ProviderAccountID`

**Rules**:
- Open (IsOpen=1): FromAccount = ProviderAccountID (Apex), ToAccount = 'Etoro_BD' (eToro's business desk)
- Close (IsOpen=0): FromAccount = 'Etoro_BD', ToAccount = ProviderAccountID
- This tracks the direction of share movement between eToro and the clearing provider

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | DATE | YES | NULL | CODE-BACKED | Optional date filter. Matches against CONVERT(date, RequestDateTime). NULL returns all dates. |
| 2 | @symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional instrument symbol filter (case-insensitive). Matched against InstrumentMetaData.Symbol. |
| 3 | @instrumentID | INT | YES | NULL | CODE-BACKED | Optional instrument ID filter. |
| 4 | @cid | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Optional direction filter. Matched against IsOpen field (1=buy/open, 0=sell/close). |
| 6 | @apexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional Apex clearing account ID filter. |
| 7 | @ExternalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional external allocation request ID filter. Matches AllocationRequestID. |
| 8 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Optional position ID filter for tracing a specific position's allocation. |
| 9 | RequestDateTime | DATETIME | - | - | CODE-BACKED | When the allocation request was created. |
| 10 | CID | INT | - | - | CODE-BACKED | Customer ID who owns the position being allocated. |
| 11 | ApexAccountID | VARCHAR | - | - | CODE-BACKED | Apex clearing provider account identifier (aliased from ProviderAccountID). |
| 12 | PositionID | BIGINT | - | - | CODE-BACKED | eToro position ID associated with this allocation. |
| 13 | FromAccount | VARCHAR | - | - | CODE-BACKED | Source account for share transfer. On open: Apex account. On close: 'Etoro_BD'. |
| 14 | ToAccount | VARCHAR | - | - | CODE-BACKED | Destination account for share transfer. On open: 'Etoro_BD'. On close: Apex account. |
| 15 | InstrumentID | INT | - | - | CODE-BACKED | Instrument being allocated. FK to Trade.Instrument. |
| 16 | IsBuy | INT | - | - | CODE-BACKED | Aliased from IsOpen. 1 = open/buy allocation, 0 = close/sell allocation. |
| 17 | Quantity | DECIMAL | - | - | CODE-BACKED | Number of shares/units being allocated (from TaxLotQuantity). |
| 18 | AllocationPrice | DECIMAL | - | - | CODE-BACKED | Price at which the allocation was executed. |
| 19 | ExternalID | VARCHAR | - | - | CODE-BACKED | External allocation request identifier (aliased from AllocationRequestID). Used to correlate with ALE events. |
| 20 | DealingRequestSendTime | DATETIME | - | - | CODE-BACKED | When the dealing request was sent to the clearing provider. From SynHedgeAllocationRequests. |
| 21 | AllocationSource | VARCHAR | - | - | CODE-BACKED | Name of the allocation source (resolved from SynHedgeAllocationSource). |
| 22 | AlePayloadStatus | VARCHAR | - | - | CODE-BACKED | ALE event payload status - tracks the lifecycle state of the allocation. |
| 23 | AleError | VARCHAR | - | - | CODE-BACKED | ALE error message text if the allocation encountered an error. |
| 24 | AlePayloadMessageCode | VARCHAR | - | - | CODE-BACKED | ALE message code for error classification. |
| 25 | AleOccurredAt | DATETIME | - | - | CODE-BACKED | When the ALE event occurred. |
| 26 | AleTopic | VARCHAR | - | - | CODE-BACKED | ALE event topic/category. |
| 27 | AlePayloadId | VARCHAR | - | - | CODE-BACKED | ALE event payload identifier. |
| 28 | Symbol | NVARCHAR | - | - | CODE-BACKED | Instrument ticker symbol from InstrumentMetaData. |
| 29 | InstrumentDisplayName | NVARCHAR | - | - | CODE-BACKED | Human-readable instrument name from InstrumentMetaData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.SynAllocationGetRequestLog | SELECT FROM | Allocation request log (Azure synonym) |
| (body) | dbo.SynHedgeApexAleEvent | LEFT JOIN | ALE lifecycle event tracking |
| (body) | dbo.SynHedgeApexAleEventMessage | LEFT JOIN | ALE error message lookup |
| (body) | dbo.SynHedgeAllocationRequests | LEFT JOIN | Dealing request details |
| (body) | dbo.SynHedgeAllocationSource | LEFT JOIN | Allocation source name lookup |
| (body) | Trade.InstrumentMetaData | INNER JOIN | Instrument symbol and display name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllocationData (procedure)
+-- dbo.SynAllocationGetRequestLog (synonym)
+-- dbo.SynHedgeApexAleEvent (synonym)
+-- dbo.SynHedgeApexAleEventMessage (synonym)
+-- dbo.SynHedgeAllocationRequests (synonym)
+-- dbo.SynHedgeAllocationSource (synonym)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SynAllocationGetRequestLog | Synonym | SELECT FROM - allocation request data |
| dbo.SynHedgeApexAleEvent | Synonym | LEFT JOIN - ALE event tracking |
| dbo.SynHedgeApexAleEventMessage | Synonym | LEFT JOIN - error message resolution |
| dbo.SynHedgeAllocationRequests | Synonym | LEFT JOIN - dealing request info |
| dbo.SynHedgeAllocationSource | Synonym | LEFT JOIN - allocation source names |
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument display data |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all allocations for a specific date and instrument
```sql
EXEC Trade.GetAllocationData @date = '2026-03-15', @symbol = 'AAPL';
```

### 8.2 Get allocations for a specific customer and position
```sql
EXEC Trade.GetAllocationData @cid = 12345, @PositionID = 987654321;
```

### 8.3 Get all failed allocations for a date
```sql
EXEC Trade.GetAllocationData @date = '2026-03-15';
-- Then filter results where AleError IS NOT NULL in the application layer
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllocationData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllocationData.sql*
