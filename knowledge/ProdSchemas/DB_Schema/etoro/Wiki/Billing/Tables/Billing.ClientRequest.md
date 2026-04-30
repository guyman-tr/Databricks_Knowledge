# Billing.ClientRequest

> Rate-limiting audit log for Billing domain client requests - tracks how many times a customer has performed a specific request type within a time window to enforce frequency limits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RequestID (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 90) |
| **Indexes** | 2 (PK clustered + NC on CID) |

---

## 1. Business Meaning

`Billing.ClientRequest` is a per-customer request frequency tracking table used to enforce rate limits on Billing operations. Each row records a single client request event: who made it (CID), what type (RequestType), and when (CreatedTime). Before processing a new request, the system counts how many requests the customer has made of that type within a configurable time window and returns the count to the caller - enabling application-level throttling.

This table exists to prevent abuse of sensitive billing operations (e.g., ACH account registration) by limiting how frequently a single customer can initiate them. The `NOT FOR REPLICATION` flag indicates it participates in SQL Server replication.

The table's data range is January 2023 to October 2023 with 3,227 rows total - it stopped receiving inserts after October 2023. This suggests the feature using this table was either deprecated or migrated to another tracking mechanism. Only RequestType=1 (AddACHAccount per Dictionary.ClientRequestType) and RequestType=2 (undefined in the lookup table, likely an undocumented second ACH-related operation) appear in the data. ResponseCode is NULL in all rows - the field was provisioned but never populated.

---

## 2. Business Logic

### 2.1 Rate Limiting Pattern (Check-then-Insert)

**What**: The table is written to atomically with a count check to enforce per-customer request frequency limits.

**Columns/Parameters Involved**: `CID`, `RequestType`, `CreatedTime`, `ResponseCode`

**Rules**:
- `Billing.AddClientRequestAndGetCountByTime` performs the full flow: count existing requests in window, INSERT new request, return count to caller.
- The caller decides whether to proceed based on the returned count - this table provides the state; enforcement happens in application code.
- `@FromTime` parameter defines the sliding window start. Typical usage: "how many AddACHAccount requests has this customer made in the last 24 hours?"
- `CorrelationID` enables linking the request to an external transaction ID (optional - NULL in all current data).
- `ResponseCode` was intended to store the outcome code but was never populated (NULL in all 3,227 rows).

**Diagram**:
```
Application calls AddClientRequestAndGetCountByTime(@CID, @RequestType, @FromTime)
        |
        v
1. COUNT requests WHERE CID = @CID AND RequestType = @RequestType AND CreatedTime >= @FromTime
        |
        v
2. INSERT new row: (RequestType, CorrelationID, CID, ResponseCode)
        |
        v
3. Return @NumberOfAttempts (count from step 1) to caller
        |
        v
Caller checks count:
  - Count < limit -> proceed with the operation
  - Count >= limit -> reject (rate limit exceeded)
```

---

## 3. Data Overview

| RequestID | RequestType | CID | CorrelationID | ResponseCode | CreatedTime | Meaning |
|-----------|------------|-----|---------------|-------------|-------------|---------|
| 3227 | 2 | 12563033 | NULL | NULL | 2023-10-26 | Last recorded request in the table. RequestType=2 (undocumented type). No correlation ID or response code tracked. |
| 3225 | 2 | 11558481 | NULL | NULL | 2023-07-24 | Customer 11558481 made RequestType=2 twice in rapid succession (3224 and 3225 within 2 minutes) - typical rate-limit scenario. |
| 1 | 1 (AddACHAccount) | - | - | NULL | 2023-01-04 | Earliest row - RequestType=1 corresponds to AddACHAccount (per Dictionary.ClientRequestType). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION prevents identity consumption on replication subscribers. |
| 2 | RequestType | int | NO | - | CODE-BACKED | Type of client request being tracked. Lookup: Dictionary.ClientRequestType (only ID=1="AddACHAccount" defined in lookup). Observed values: 1=AddACHAccount (254 rows, 8%), 2=undocumented type (2,973 rows, 92%). Used in the rate-limit count query: `WHERE RequestType = @RequestType`. |
| 3 | CorrelationID | varchar(50) | YES | - | CODE-BACKED | Optional external correlation identifier to link this request to an upstream transaction or request ID. NULL in all 3,227 current rows - the field was provisioned but the calling code passes NULL consistently. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer identifier making the request. Implicit FK to Customer.CustomerStatic.CID. Used as the primary filter in the rate-limit count query: `WHERE CID = @CID`. Indexed via IX_BillingClientRequest_CID for fast per-customer lookups. |
| 5 | ResponseCode | int | YES | - | CODE-BACKED | Intended to store the outcome/response code of the operation that followed this request. Never populated - NULL in all 3,227 rows. The parameter `@ResponseCode` in AddClientRequestAndGetCountByTime inserts it but callers always pass NULL. |
| 6 | CreatedTime | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the request was recorded. Auto-populated via DEFAULT (getutcdate()). Used as the time-window filter in rate-limit queries: `WHERE CreatedTime >= @FromTime`. Data range: 2023-01-04 to 2023-10-26 - table stopped receiving inserts after October 2023. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestType | Dictionary.ClientRequestType | Implicit FK | Classifies the request type. Only value 1=AddACHAccount defined in lookup; value 2 exists in data but not in the dictionary. |
| CID | Customer.CustomerStatic | Implicit FK | Customer making the request. No explicit FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddClientRequestAndGetCountByTime | @CID, @RequestType, @FromTime | WRITER + READER | Inserts new request AND counts existing requests in time window. Primary write path. |
| Billing.GetClientRequestCountByTime | @CID, @RequestType, @FromTime | READER | Returns count of requests by customer + type within a time window. Also called by AddClientRequestAndGetCountByTime. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddClientRequestAndGetCountByTime | Stored Procedure | WRITER + READER - inserts request records and counts existing ones for rate limiting |
| Billing.GetClientRequestCountByTime | Stored Procedure | READER - counts requests per customer/type in a sliding time window |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingRequest | CLUSTERED PK | RequestID ASC | - | - | Active |
| IX_BillingClientRequest_CID | NONCLUSTERED | CID ASC | - | - | Active |

Both indexes: FILLFACTOR=90. PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingRequest | PRIMARY KEY | RequestID - unique request identifier |
| DF_BillingClientRequest_CreatedTime | DEFAULT | getutcdate() - auto-stamps request time in UTC |

---

## 8. Sample Queries

### 8.1 Count a customer's requests of a given type in the last 24 hours

```sql
SELECT COUNT(*) AS RequestCount
FROM [Billing].[ClientRequest] WITH (NOLOCK)
WHERE CID = @CID
  AND RequestType = 1  -- AddACHAccount
  AND CreatedTime >= DATEADD(HOUR, -24, GETUTCDATE());
```

### 8.2 View all requests for a customer

```sql
SELECT RequestID, RequestType, CorrelationID, ResponseCode, CreatedTime
FROM [Billing].[ClientRequest] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY CreatedTime DESC;
```

### 8.3 Request volume by type and month

```sql
SELECT RequestType, YEAR(CreatedTime) AS Yr, MONTH(CreatedTime) AS Mo,
       COUNT(*) AS RequestCount
FROM [Billing].[ClientRequest] WITH (NOLOCK)
GROUP BY RequestType, YEAR(CreatedTime), MONTH(CreatedTime)
ORDER BY Yr DESC, Mo DESC, RequestType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ClientRequest | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ClientRequest.sql*
