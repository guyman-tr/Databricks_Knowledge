# Wallet.GetRequestStatuses

> Retrieves request records with their latest status for a customer, supporting optional filtering by date range, request type, and result limiting - the primary request inquiry endpoint.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns requests with latest status, filtered by multiple criteria |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary inquiry endpoint for the wallet request pipeline. It returns request records enriched with their latest status, enabling the application to display request history, check processing progress, and troubleshoot issues. Each result row contains both the request details (what was asked for) and the most recent status (where it currently stands in the pipeline).

Without this procedure, there would be no efficient way to query the request pipeline's current state for a customer or across all customers. It supports both customer-specific inquiries (filtering by Gcid) and system-wide monitoring (when Gcid is NULL).

The procedure uses CROSS APPLY to efficiently retrieve only the latest status record per request, avoiding the overhead of returning the full status history. Results are limited by @RecordsLimit (default 1000) to prevent excessive result sets.

---

## 2. Business Logic

### 2.1 Latest Status Resolution via CROSS APPLY

**What**: Retrieves only the most recent status per request using an efficient CROSS APPLY pattern.

**Columns/Parameters Involved**: `Requests.Id`, `RequestStatuses.RequestId`, `RequestStatuses.Id`

**Rules**:
- CROSS APPLY with TOP 1 ordered by rs.id DESC selects the most recent status per request
- This is more efficient than ROW_NUMBER() for this pattern since it stops scanning after the first match
- Each result row contains both request fields and latest status fields in a single denormalized row

### 2.2 Flexible Filtering

**What**: All filter parameters are optional, enabling flexible query patterns.

**Columns/Parameters Involved**: `@Gcid`, `@FromDate`, `@ToDate`, `@RequestType`

**Rules**:
- All filters use ISNULL pattern: `r.Gcid = ISNULL(@Gcid, r.Gcid)` - when NULL, the filter is effectively disabled
- Date range filters on Requests.Timestamp
- Request type filters on RequestTypeId
- When all filters are NULL, returns the most recent 1000 requests system-wide

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | YES | NULL | CODE-BACKED | Optional Global Customer ID filter. When NULL, returns requests for all customers (system-wide view). |
| 2 | @RecordsLimit | int | YES | 1000 | CODE-BACKED | Maximum number of records to return. Default 1000 prevents excessive result sets. |
| 3 | @FromDate | datetime2 | YES | NULL | CODE-BACKED | Optional start of date range filter on Requests.Timestamp. |
| 4 | @ToDate | datetime2 | YES | NULL | CODE-BACKED | Optional end of date range filter on Requests.Timestamp. |
| 5 | @RequestType | tinyint | YES | NULL | CODE-BACKED | Optional request type filter. Common values: 1=SendTransaction, 2=InitiatePayment, 4=Conversion. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Request record identity. PK of Wallet.Requests. |
| 2 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique correlation ID linking the request across all wallet subsystems. |
| 3 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID who owns this request. |
| 4 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency involved in this request. FK to Wallet.CryptoTypes. |
| 5 | RequestTypeId | tinyint | NO | - | CODE-BACKED | Type of request: 1=SendTransaction, 2=InitiatePayment, 4=Conversion, etc. |
| 6 | Timestamp | datetime2(7) | NO | - | CODE-BACKED | When the request was created. |
| 7 | DetailsJson | nvarchar | YES | - | CODE-BACKED | JSON payload containing request-specific details (amount, destination, etc.). Structure varies by RequestTypeId. |
| 8 | RequestStatusRecordId | bigint | NO | - | CODE-BACKED | Identity of the latest status record from Wallet.RequestStatuses. |
| 9 | RequestStatusId | tinyint | NO | - | CODE-BACKED | Latest request status: 1=Done, 2=Error, and other in-progress values. |
| 10 | RequestStatusTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the latest status was recorded. |
| 11 | RequestStatusDetailsJson | nvarchar | YES | - | CODE-BACKED | JSON payload of the latest status entry (e.g., error details, completion info). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.Requests | FROM | Main data source for request records |
| CROSS APPLY | Wallet.RequestStatuses | CROSS APPLY | Latest status per request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from application API layer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRequestStatuses (procedure)
├── Wallet.Requests (table)
└── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | Main data source |
| Wallet.RequestStatuses | Table | CROSS APPLY for latest status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Primary request inquiry API endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP(@RecordsLimit) | Result limiting | Prevents runaway result sets, default 1000 |
| ISNULL pattern | Optional filters | All parameters use ISNULL for conditional filtering |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get latest 100 requests for a customer
```sql
EXEC Wallet.GetRequestStatuses @Gcid = 12345678, @RecordsLimit = 100;
```

### 8.2 Get all send requests in a date range
```sql
EXEC Wallet.GetRequestStatuses @Gcid = NULL, @RecordsLimit = 500,
    @FromDate = '2026-04-01', @ToDate = '2026-04-15', @RequestType = 1;
```

### 8.3 Manual query for stuck requests (not Done/Error)
```sql
SELECT TOP 100 r.Id, r.CorrelationId, r.Gcid, r.CryptoId, r.RequestTypeId,
    r.Timestamp, rs.RequestStatusId, rs.Timestamp AS StatusTime,
    DATEDIFF(MINUTE, rs.Timestamp, GETUTCDATE()) AS MinutesSinceLastStatus
FROM Wallet.Requests r WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 * FROM Wallet.RequestStatuses rs WITH (NOLOCK)
        WHERE rs.RequestId = r.Id ORDER BY rs.Id DESC
    ) rs
WHERE rs.RequestStatusId NOT IN (1, 2)
    AND DATEDIFF(HOUR, rs.Timestamp, GETUTCDATE()) > 1
ORDER BY r.Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRequestStatuses | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetRequestStatuses.sql*
