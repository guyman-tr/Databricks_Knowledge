# Trade.HedgeCloseRequestAdd

> Queues a hedge close request in Trade.HedgeRequest (RequestType=2), displacing any existing pending close request with a failure log entry, so the hedge server can process the latest close instruction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID, @RequestedEndForexRate; Writes: Trade.HedgeRequest (RequestType=2); Logs: History.HedgeFail on displacement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeCloseRequestAdd inserts a close request for a hedge into Trade.HedgeRequest, so the hedge server knows to close this hedge at the specified rate. If a previous close request already exists for this hedge (i.e., a prior close instruction was not yet processed), the old request is archived to History.HedgeFail (as a duplicate/displaced request), deleted, and replaced with the new one. This ensures only one pending close request exists per hedge at any time.

This procedure exists because hedge close operations are asynchronous: the application submits a close instruction by inserting a RequestType=2 row into HedgeRequest, and the hedge server polls or processes this queue to execute the close at the liquidity provider. If a second close request arrives before the first is processed (e.g., due to retry logic or overlapping signals), the old request must be displaced to avoid duplicate execution.

The SP was enhanced from its original version (Trade.HedgeCloseRequestAdd_Original) to add FailReasonID=17 to the History.HedgeFail log, improving traceability of displaced requests. The header comment confirms: "changing SP Trade.HedgeCloseRequestAdd to write corresponding FailReasonID."

---

## 2. Business Logic

### 2.1 Duplicate Request Displacement

**What**: If a pending close request already exists for @HedgeID, archive it to HedgeFail and replace it with the new request.

**Columns/Parameters Involved**: `@HedgeID`, `Trade.HedgeRequest.RequestType`, `History.HedgeFail.FailTypeID`, `History.HedgeFail.FailReasonID`

**Rules**:
- Step 1: SELECT from Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=2; if any rows exist, INSERT them into History.HedgeFail (FailTypeID=2, FailReasonID=17, FailReason='New request to close arrived till previous one is not processed yet.')
- Step 2: IF @@ROWCOUNT > 0: DELETE old RequestType=2 rows from Trade.HedgeRequest
- Step 3: INSERT new row into Trade.HedgeRequest (HedgeID=@HedgeID, RequestType=2, RequestedEndForexRate=@RequestedEndForexRate)
- Difference from _Original: always attempts the HedgeFail INSERT via SELECT (SELECT will return 0 rows if nothing to displace, so INSERT is a no-op); _Original uses IF EXISTS guard

**Diagram**:
```
Trade.HedgeCloseRequestAdd(@HedgeID, @RequestedEndForexRate)
    |
    +-- (1) INSERT History.HedgeFail
    |         SELECT from Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=2
    |         FailTypeID=2, FailReasonID=17, 'New request to close...'
    |         (no-op if no pending close request exists)
    |
    +-- (2) IF @@ROWCOUNT > 0: DELETE FROM Trade.HedgeRequest (displaced old request)
    |
    +-- (3) INSERT Trade.HedgeRequest (HedgeID, RequestType=2, RequestedEndForexRate)
    |         (the new close instruction for the hedge server)
    |
    +-- COMMIT (or ROLLBACK in CATCH)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge for which a close request is being submitted. Must correspond to a live hedge in Trade.Hedge that is being requested to close. |
| 2 | @RequestedEndForexRate | dtPrice | NO | - | CODE-BACKED | The requested closing rate for the hedge. Stored in Trade.HedgeRequest.RequestedEndForexRate and later read by Trade.HedgeClose to populate History.Hedge.RequestedEndForexRate. dtPrice is a user-defined decimal type for price values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Trade.HedgeRequest | INSERT / DELETE (conditional) | Displaces existing RequestType=2 rows; inserts new close request |
| @HedgeID | History.HedgeFail | INSERT (conditional) | Archives displaced close requests with FailTypeID=2, FailReasonID=17 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server / Trading API (external) | - | Called by external system | The trading system calls this to submit close instructions to the hedge server queue |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeCloseRequestAdd (procedure)
+-- Trade.HedgeRequest (table) [leaf - SELECT + DELETE + INSERT]
+-- History.HedgeFail (table) [x-schema, leaf - displacement log INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | SELECT (check for existing), DELETE (displace), INSERT (new close request) |
| History.HedgeFail | Table | INSERT (archive displaced close requests) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeClose | Procedure | Reads and deletes the RequestType=2 row that this SP creates |
| Hedge Server (external) | External caller | Calls this SP to submit hedge close instructions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Error handling: TRY/CATCH with ROLLBACK on @@TRANCOUNT=1, or COMMIT for nested transactions. Returns 0 on success, 60000 on error.

---

## 8. Sample Queries

### 8.1 Submit a close request for a hedge

```sql
EXEC Trade.HedgeCloseRequestAdd
    @HedgeID = 12345,
    @RequestedEndForexRate = 1.08520;
```

### 8.2 Check pending close requests for a hedge

```sql
SELECT HedgeID, RequestType, RequestedEndForexRate, Occurred
FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = 12345 AND RequestType = 2;
```

### 8.3 Check for displaced close requests in failure log

```sql
SELECT HedgeID, FailTypeID, FailReasonID, FailReason, RequestedEndForexRate, RequestCloseOccurred
FROM History.HedgeFail WITH (NOLOCK)
WHERE HedgeID = 12345 AND FailTypeID = 2
ORDER BY RequestCloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 11 - Phase 10: no results)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.HedgeRequest, History.HedgeFail dependency docs) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeCloseRequestAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeCloseRequestAdd.sql*
