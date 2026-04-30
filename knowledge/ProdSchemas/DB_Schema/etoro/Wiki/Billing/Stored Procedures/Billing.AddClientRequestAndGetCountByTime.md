# Billing.AddClientRequestAndGetCountByTime

> Inserts a new request record into `Billing.ClientRequest` and returns via OUTPUT parameter the count of prior requests of the same type from the same customer within a specified time window, enabling application-layer rate limiting of Billing operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @NumberOfAttempts OUTPUT (count of prior requests in window) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddClientRequestAndGetCountByTime` is the rate-limiting gate procedure for Billing domain operations. It atomically records a new client request and returns how many times the same customer has already made the same request type within a given time window. The calling application uses that count to decide whether to allow or reject the operation.

The procedure exists to prevent abuse of sensitive billing operations - for example, ACH account registration - by limiting how frequently a single customer can initiate them. The decision of whether to accept or reject (based on the returned count) is enforced by the application code calling this procedure, not in the database.

Data flows: a Billing service calls this proc with a customer ID, request type, and time window start. The proc records the request unconditionally and returns the pre-insert count. The service checks: if count >= threshold, reject the operation (though the request is already logged). No other callers were found in the Billing stored procedure files; this is designed as a point-of-entry gate called directly from application code.

---

## 2. Business Logic

### 2.1 Rate-Limit Check-then-Insert Flow

**What**: The procedure performs a count check and an unconditional INSERT in the same call, returning the prior request count to the caller.

**Parameters/Columns Involved**: `@CID`, `@RequestType`, `@FromTime`, `@NumberOfAttempts`, `Billing.ClientRequest`

**Rules**:
- INSERT into `Billing.ClientRequest` always executes regardless of `@FromTime` or count.
- The SELECT COUNT always executes (see Section 2.2 for the behavioral note about the dead-code EXEC path).
- When `@FromTime IS NULL`, the count query `WHERE CreatedTime >= NULL` returns 0 (NULL comparison yields UNKNOWN/FALSE), so `@NumberOfAttempts = 0`.
- The caller must check the returned `@NumberOfAttempts` BEFORE proceeding; the INSERT has already been committed by the time the count is returned.

**Diagram**:
```
Application calls:
  AddClientRequestAndGetCountByTime(@CID, @RequestType, @CorrelationID, @FromTime, @ResponseCode, @NumberOfAttempts OUTPUT)
                 |
                 v
  SELECT @NumberOfAttempts = COUNT(*)                    <- count of prior requests in window
    FROM Billing.ClientRequest
   WHERE CID = @CID AND RequestType = @RequestType AND CreatedTime >= @FromTime
                 |
                 v
  INSERT INTO Billing.ClientRequest (RequestType, CorrelationID, CID, ResponseCode)  <- always
                 |
                 v
  Return @NumberOfAttempts to caller
                 |
                 v
  Caller checks: count < limit -> allow | count >= limit -> reject (but request already logged)
```

### 2.2 Dead-Code EXEC Path (Behavioral Note)

**What**: The procedure contains an internal call to `Billing.GetClientRequestCountByTime` that is effectively unreachable in its intended purpose.

**Parameters/Columns Involved**: `@FromTime`, `@NumberOfAttempts`

**Rules**:
- The DDL uses `IF @FromTime IS NOT NULL EXEC Billing.GetClientRequestCountByTime ...` without BEGIN/END braces.
- In T-SQL, a bare IF without BEGIN/END applies only to the immediately next single statement (the EXEC).
- The following SELECT COUNT statement always runs, immediately overwriting whatever `@NumberOfAttempts` value was set by the EXEC.
- Result: `GetClientRequestCountByTime` is called (when @FromTime IS NOT NULL) but its output is discarded.
- The operative count logic is always the SELECT on `Billing.ClientRequest` directly.
- `GetClientRequestCountByTime` is a thin wrapper around the same SELECT logic - the end result is identical, just the EXEC call is redundant.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID whose requests are being tracked and counted. Used both in the rate-limit SELECT (WHERE CID = @CID) and inserted into Billing.ClientRequest.CID. Implicit FK to Customer.CustomerStatic.CID. |
| 2 | @RequestType | INT | NO | - | VERIFIED | Type of request being tracked. Used in the rate-limit SELECT (WHERE RequestType = @RequestType) and inserted into Billing.ClientRequest.RequestType. Lookup: Dictionary.ClientRequestType (1=AddACHAccount; type 2 is in the data but undocumented in the lookup table). |
| 3 | @CorrelationID | VARCHAR(50) | YES | NULL | CODE-BACKED | Optional external correlation identifier to link this request to an upstream transaction. Inserted into Billing.ClientRequest.CorrelationID. NULL in all current data (3,227 rows) - callers consistently pass NULL. |
| 4 | @FromTime | DATETIME | YES | NULL | VERIFIED | Start of the time window for the rate-limit count. `WHERE CreatedTime >= @FromTime` in the SELECT defines the lookback period. When NULL, the WHERE clause returns 0 rows (NULL comparison) so @NumberOfAttempts = 0 and rate limiting is effectively disabled. Also controls (but cannot affect the output of) the dead-code EXEC call to Billing.GetClientRequestCountByTime (see Section 2.2). |
| 5 | @ResponseCode | INT | YES | NULL | CODE-BACKED | Intended outcome code for the operation that follows this rate-limit check. Inserted into Billing.ClientRequest.ResponseCode but always NULL in current data - callers pass NULL consistently. The field was provisioned for future use. |
| 6 | @NumberOfAttempts | INT | NO | - OUTPUT | VERIFIED | OUTPUT parameter. Returns the count of prior requests matching @CID + @RequestType within the @FromTime window, computed BEFORE the INSERT. The caller uses this count to enforce the rate limit threshold. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.ClientRequest | WRITER | Inserts a new row every call |
| @CID, @RequestType, @FromTime | Billing.ClientRequest | READER | SELECT COUNT for rate-limit check |
| @FromTime | Billing.GetClientRequestCountByTime | CALLEE (dead code) | Called internally when @FromTime IS NOT NULL; output is overwritten by the subsequent SELECT. See Section 2.2. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing stored procedure files. This procedure is called directly from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddClientRequestAndGetCountByTime (procedure)
|- Billing.ClientRequest (table)              [SELECT COUNT + INSERT]
+- Billing.GetClientRequestCountByTime (procedure) [EXEC - dead code, output overwritten]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ClientRequest | Table | SELECT COUNT for rate-limit check + INSERT to record the new request |
| Billing.GetClientRequestCountByTime | Stored Procedure | EXEC called when @FromTime IS NOT NULL, but output is overwritten immediately - effectively dead code (see Section 2.2) |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called directly from application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check rate limit and log a request (ACH account registration)
```sql
DECLARE @AttemptCount INT;
EXEC Billing.AddClientRequestAndGetCountByTime
    @CID              = 12345678,
    @RequestType      = 1,                          -- AddACHAccount
    @CorrelationID    = NULL,
    @FromTime         = DATEADD(HOUR, -24, GETUTCDATE()),  -- 24-hour window
    @ResponseCode     = NULL,
    @NumberOfAttempts = @AttemptCount OUTPUT;

-- Caller checks: if @AttemptCount >= threshold, reject
SELECT @AttemptCount AS PriorAttemptsInWindow;
```

### 8.2 View all requests logged for a customer
```sql
SELECT  CR.RequestID,
        CR.RequestType,
        CR.CID,
        CR.CorrelationID,
        CR.ResponseCode,
        CR.CreatedTime
FROM    Billing.ClientRequest CR WITH (NOLOCK)
WHERE   CR.CID = 12345678
ORDER BY CR.CreatedTime DESC;
```

### 8.3 Rate limit analysis - requests per customer per type in last 24 hours
```sql
SELECT  CR.CID,
        CR.RequestType,
        COUNT(*)        AS RequestCount,
        MIN(CR.CreatedTime) AS FirstRequest,
        MAX(CR.CreatedTime) AS LastRequest
FROM    Billing.ClientRequest CR WITH (NOLOCK)
WHERE   CR.CreatedTime >= DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY CR.CID, CR.RequestType
HAVING  COUNT(*) > 1
ORDER BY RequestCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddClientRequestAndGetCountByTime | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddClientRequestAndGetCountByTime.sql*
