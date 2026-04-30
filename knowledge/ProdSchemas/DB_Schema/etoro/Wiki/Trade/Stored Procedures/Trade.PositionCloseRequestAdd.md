# Trade.PositionCloseRequestAdd

> Enqueues a close request for a position, archiving any duplicate pending request to the fail-write log before inserting the new one.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.PositionRequest (PositionID + RequestType=2) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionCloseRequestAdd is the write entry-point for enqueuing a position close request in the trading system's request-queue architecture. When a client (user or system) requests to close a position, this SP inserts a row into Trade.PositionRequest with RequestType=2 so that downstream execution jobs can pick it up and call Trade.PositionClose.

A critical responsibility of this SP is idempotency enforcement: only one active close request per PositionID is allowed at any time. If a prior close request already exists in Trade.PositionRequest for the same position, the SP archives it to History.PositionFailWrite (FailTypeID=2, FailReason='New request to close arrived till previous one is not processed yet.') before deleting it from the queue and inserting the new request. This prevents silent duplicate-execution bugs in the downstream close job.

The SP forms a pair with Trade.PositionOpenRequestAdd: together they cover the two lifecycle transitions of a position request (open and close) through the Trade.PositionRequest queue table. The AdditionalParam value 'DB_Direct' in the archived failure record signals that the replacement originated from a direct database operation rather than via an application-layer retry.

---

## 2. Business Logic

### 2.1 Duplicate Close Request Detection and Archival

**What**: Before inserting the new close request, the SP checks for an existing pending close request (RequestType=2) for the same PositionID. If found, it archives the old request to History.PositionFailWrite and removes it.

**Columns/Parameters Involved**: Trade.PositionRequest.RequestType=2, @PositionID, History.PositionFailWrite.FailTypeID, FailReason, AdditionalParam

**Rules**:
- IF EXISTS checks Trade.PositionRequest WHERE PositionID = @PositionID AND RequestType = 2
- When duplicate found: reads position context from Trade.Position (CID, RequestOccurred as RequestOpenOccurred, TradeRange, InitForexPriceRateID, OrderPriceRateID, OrderPriceRate)
- Archives duplicate row from Trade.PositionRequest to History.PositionFailWrite with FailTypeID=2, FailReason='New request to close arrived till previous one is not processed yet.', AdditionalParam='DB_Direct'
- OrigParentPositionID is set to ParentPositionID (comment notes PositionRequest has no OrigParentPositionID column - they are the same value)
- Captures @ParentPositionID from the archived duplicate for use in the new insert
- DELETEs the duplicate from Trade.PositionRequest

**Diagram**:
```
IF duplicate close request exists:
    READ Trade.Position (context: CID, TradeRange, rates)
    INSERT History.PositionFailWrite (FailTypeID=2, FailReason='New request...')
    SELECT @ParentPositionID from duplicate
    DELETE from Trade.PositionRequest

INSERT Trade.PositionRequest (RequestType=2, @RequestedEndForexRate, @TradeRange, @ParentPositionID)
```

### 2.2 Close Request Insertion

**What**: The new close request is inserted into Trade.PositionRequest with RequestType=2.

**Columns/Parameters Involved**: Trade.PositionRequest (PositionID, RequestType, RequestedEndForexRate, TradeRange, ParentPositionID)

**Rules**:
- RequestType is always 2 (close) - hardcoded
- RequestedEndForexRate is the rate at which the client requested the close (from @RequestedEndForexRate)
- TradeRange is populated from Trade.Position only when a duplicate was found; otherwise NULL (variable declared but never assigned)
- ParentPositionID is populated from the duplicate's ParentPositionID when present; otherwise NULL
- EndForexPriceRateID is an input parameter but is only used in the fail-write archive (not inserted into PositionRequest)

### 2.3 Transaction and Error Handling

**What**: All operations run inside a single transaction. Any failure rolls back entirely.

**Rules**:
- BEGIN TRY/BEGIN TRANSACTION wraps all logic
- COMMIT on success, ROLLBACK on any exception
- CATCH raises error 60000 with procedure name 'Trade.PositionCloseRequestAdd' as context
- Returns 0 on success, 60000 on error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to close. Identifies which row in Trade.PositionTbl and Trade.PositionRequest to target. Partition key in Trade.PositionTbl (@PositionID%50 pattern). |
| 2 | @RequestedEndForexRate | dtPrice | NO | - | CODE-BACKED | The forex rate at which the close was requested by the client. Stored in Trade.PositionRequest.RequestedEndForexRate. dtPrice is a user-defined type (decimal precision). |
| 3 | @EndForexPriceRateID | BIGINT | NO | - | CODE-BACKED | The rate table row ID for the close rate. Used only in the History.PositionFailWrite archive row (EndForexPriceRateID column) when a duplicate close request is displaced. Not stored in Trade.PositionRequest. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT context | Trade.Position | DML read | Reads CID, TradeRange, rates for the position when archiving a duplicate close request |
| EXISTS / DELETE / INSERT target | Trade.PositionRequest | DML read+write | Checks for duplicate, archives and deletes old request, inserts new close request |
| INSERT target | History.PositionFailWrite | DML write | Archives displaced duplicate close request with FailTypeID=2 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo or application repos. Called by external order-management or request-routing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionCloseRequestAdd (procedure)
+-- Trade.Position (view/table) - READ for position context
+-- Trade.PositionRequest (table) - queue: check duplicate, archive, insert
+-- History.PositionFailWrite (table) - archive displaced duplicate
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View/Table | SELECT CID, RequestOccurred, TradeRange, InitForexPriceRateID, OrderPriceRateID, OrderPriceRate for the given PositionID |
| Trade.PositionRequest | Table | EXISTS check; SELECT ParentPositionID; DELETE duplicate; INSERT new close request |
| History.PositionFailWrite | Table | INSERT displaced close request with FailTypeID=2 |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by external request-handling services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Only one close request (RequestType=2) allowed per PositionID in Trade.PositionRequest at any time; enforced by archive-then-replace logic
- TradeRange and ParentPositionID are NULL in the new request when no duplicate existed (declared but unassigned variables default to NULL in T-SQL)

---

## 8. Sample Queries

### 8.1 Enqueue a position close request

```sql
EXEC Trade.PositionCloseRequestAdd
    @PositionID          = 123456789,
    @RequestedEndForexRate = 1.08523,
    @EndForexPriceRateID = 987654321;
```

### 8.2 Check pending close requests

```sql
SELECT PositionID, RequestType, RequestedEndForexRate, TradeRange, Occurred
FROM Trade.PositionRequest WITH (NOLOCK)
WHERE RequestType = 2
ORDER BY Occurred DESC;
```

### 8.3 Review displaced close requests (duplicate archive log)

```sql
SELECT PositionID, CID, FailTypeID, FailReason, RequestCloseOccurred, AdditionalParam
FROM History.PositionFailWrite WITH (NOLOCK)
WHERE FailTypeID = 2
  AND AdditionalParam = 'DB_Direct'
ORDER BY RequestCloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionCloseRequestAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionCloseRequestAdd.sql*
