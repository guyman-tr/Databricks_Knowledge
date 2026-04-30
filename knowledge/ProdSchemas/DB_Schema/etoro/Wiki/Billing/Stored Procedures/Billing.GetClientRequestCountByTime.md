# Billing.GetClientRequestCountByTime

> Returns the count of client requests by a specific customer and request type within a time window via an OUTPUT parameter. Used for rate-limiting and abuse detection. Also called (with discarded output) as dead code inside Billing.AddClientRequestAndGetCountByTime.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @RequestType, @FromTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetClientRequestCountByTime` counts how many times a customer has made a specific type of request since a given point in time. The count is returned via the `@NumberOfAttempts OUTPUT` parameter. The deposit system uses this for sliding-window rate limiting: before allowing a new deposit or withdrawal attempt, the system checks how many recent attempts of the same type the customer has already made.

The procedure is a thin wrapper over a single `COUNT(*)` query on `Billing.ClientRequest`. It is also called internally by `Billing.AddClientRequestAndGetCountByTime` - but in that context its output is immediately overwritten by a subsequent SELECT, making that internal call effectively dead code (see Section 2.2).

Live data shows two RequestType values in use:
- **RequestType=2**: 2,973 records (most common - likely CC deposit attempts)
- **RequestType=1**: 254 records (less frequent - likely a different funding type)

---

## 2. Business Logic

### 2.1 Sliding-Window Rate Limit Count

**What**: Counts all ClientRequest records for a customer and request type since a given time.

**Columns/Parameters Involved**: `@CID`, `@RequestType`, `@FromTime`, `@NumberOfAttempts`

**Rules**:
- `SELECT @NumberOfAttempts = COUNT(*) FROM Billing.ClientRequest WHERE CID=@CID AND RequestType=@RequestType AND CreatedTime >= @FromTime`
- The `@FromTime` defines the start of the lookback window (e.g., last 24 hours, last hour)
- Caller sets @FromTime to current time minus the desired window (e.g., `DATEADD(HOUR, -1, GETUTCDATE())`)
- Returns 0 if the customer has no requests of this type in the window
- No result set returned - only the OUTPUT parameter

### 2.2 Dead Code Call from AddClientRequestAndGetCountByTime

**What**: This procedure is called internally by `AddClientRequestAndGetCountByTime`, but with its output discarded.

**Columns/Parameters Involved**: Called as `EXEC Billing.GetClientRequestCountByTime @CID, @RequestType, @FromTime, @NumberOfAttempts OUTPUT` inside a branch.

**Rules**:
- In `AddClientRequestAndGetCountByTime`, after calling `GetClientRequestCountByTime`, the procedure immediately executes its own `SELECT @NumberOfAttempts = COUNT(*)` which overwrites the OUTPUT value
- The `IF @FromTime IS NOT NULL EXEC Billing.GetClientRequestCountByTime ...` statement lacks a BEGIN/END block, so only the EXEC is conditional - the subsequent SELECT runs unconditionally
- Net result: `GetClientRequestCountByTime` is called but its output is always overwritten
- This is a known bug/redundancy documented in `Billing.AddClientRequestAndGetCountByTime` Section 2.2

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to count requests for. Filters Billing.ClientRequest by CID. |
| 2 | @RequestType | int | NO | - | VERIFIED | Type of client request to count. Live values: 1 (254 records) and 2 (2973 records). Likely maps to funding method or request category. |
| 3 | @FromTime | datetime | NO | - | VERIFIED | Start of the sliding time window (inclusive). Only requests with CreatedTime >= @FromTime are counted. Caller sets this to current time minus desired window size. |
| 4 | @NumberOfAttempts | int OUTPUT | NO | - | VERIFIED | OUTPUT parameter. Set to COUNT(*) of matching ClientRequest records. 0 if no matching records. Used by caller for rate-limit enforcement. |

No result set is returned - output is exclusively via the @NumberOfAttempts OUTPUT parameter.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, @RequestType, @FromTime filter | Billing.ClientRequest | Read | Counts request records for rate-limit enforcement. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddClientRequestAndGetCountByTime | EXEC (dead code) | CALLEE | Called when @FromTime IS NOT NULL, but output is immediately overwritten. Functionally a no-op in that context. |
| Application layer | Direct EXEC | CALLER | Direct rate-limit checks on Billing.ClientRequest outside AddClientRequestAndGetCountByTime. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetClientRequestCountByTime (procedure)
└── Billing.ClientRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ClientRequest | Table | COUNT(*) WHERE CID=@CID AND RequestType=@RequestType AND CreatedTime >= @FromTime. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddClientRequestAndGetCountByTime | Stored Procedure | Internal EXEC call (dead code - output overwritten) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check how many CC deposits a customer attempted in the last hour
```sql
DECLARE @Count INT
EXEC Billing.GetClientRequestCountByTime
  @CID = 12345,
  @RequestType = 2,
  @FromTime = DATEADD(HOUR, -1, GETUTCDATE()),
  @NumberOfAttempts = @Count OUTPUT
SELECT @Count AS AttemptsLastHour
-- 0 = no recent attempts; >N = rate-limit threshold exceeded
```

### 8.2 Direct equivalent query
```sql
SELECT COUNT(*) AS Attempts
FROM Billing.ClientRequest WITH (NOLOCK)
WHERE CID = 12345
  AND RequestType = 2
  AND CreatedTime >= DATEADD(HOUR, -1, GETUTCDATE())
```

### 8.3 Check request type distribution
```sql
SELECT RequestType, COUNT(*) AS TotalRequests,
       MIN(CreatedTime) AS FirstRequest,
       MAX(CreatedTime) AS LastRequest
FROM Billing.ClientRequest WITH (NOLOCK)
GROUP BY RequestType
-- RequestType 2: 2973 records | RequestType 1: 254 records
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callers analyzed (AddClientRequestAndGetCountByTime) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetClientRequestCountByTime | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetClientRequestCountByTime.sql*
