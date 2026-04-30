# Wallet.DoesRequestStatusExist

> Scalar function that checks whether a specific named status exists in the history of a request, returning 1 (true) or 0 (false).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns bit - status existence flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.DoesRequestStatusExist checks whether a given wallet request has ever reached a specific named status in its lifecycle. It joins `Wallet.RequestStatuses` (the request status history table) with `Dictionary.RequestStatuses` (the status name lookup) to perform a name-based status check rather than relying on numeric status IDs.

This function exists to provide a reusable, human-readable status check for conditional logic in request processing. Instead of hardcoding status IDs (which are fragile and opaque), callers pass a status name string like `'Done'`, `'Error'`, or `'AmlEnqueued'`. The function abstracts the name-to-ID resolution.

The function has EXECUTE permission granted to `ConversionUser`, indicating it is called from the Conversion application service. No stored procedure consumers were found in the SSDT repo, suggesting its primary consumer is application-level code rather than other database objects.

---

## 2. Business Logic

### 2.1 Status History Existence Check

**What**: Determines if a request has ever transitioned through a specific named status in its lifecycle history.

**Columns/Parameters Involved**: `@RequestId`, `@StatusName`

**Rules**:
- Joins `Wallet.RequestStatuses` (NOLOCK) with `Dictionary.RequestStatuses` (NOLOCK) on `RequestStatusId = Id`
- Filters on the request's history (`RequestId = @RequestId`) and matches the dictionary name (`drs.Name = @StatusName`)
- Uses `SELECT TOP 1 1` for efficient existence check - only needs to find one matching row
- Wrapped in `ISNULL(..., 0)` to return 0 (false) when no match exists
- Returns 1 (true) if ANY status record matches, regardless of whether it is the most recent status - this checks "has ever been" not "currently is"

**Diagram**:
```
@RequestId = 4990718, @StatusName = 'Done'
  |
  v
Wallet.RequestStatuses (history for request 4990718)
  |  StatusId=1 (Pending)     -- created
  |  StatusId=3 (Processing)  -- in progress
  |  StatusId=5 (Done)        -- completed   <-- MATCH FOUND
  |
  v
JOIN Dictionary.RequestStatuses WHERE Name = 'Done'
  --> returns 1 (true)
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | bigint | NO | - | CODE-BACKED | The ID of the request to check (FK to Wallet.Requests.Id). Identifies which request's status history to search. |
| 2 | @StatusName | varchar(50) | NO | - | CODE-BACKED | The human-readable status name to search for in the request's history. Matched against `Dictionary.RequestStatuses.Name`. Common values include `'Done'`, `'Error'`, `'AmlEnqueued'`, `'TransactionVerified'`, `'TransactionConfirmed'`, `'FiatAccountFunded'`. |
| 3 | RETURN | bit | NO | - | CODE-BACKED | 1 if the request has ever had a status record matching the given name, 0 otherwise. This is an "ever existed" check, not a "current status" check - once a request has been through a status, this returns 1 permanently. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestId | Wallet.RequestStatuses | FROM/JOIN | Reads status history records for the given request |
| @StatusName | Dictionary.RequestStatuses | JOIN | Resolves human-readable status name to numeric ID for matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser (app service) | - | EXECUTE permission | Called from the Conversion application service to check request status in business logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.DoesRequestStatusExist (function)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | Reads request status history records (FROM with NOLOCK) |
| Dictionary.RequestStatuses | Table | JOINed to resolve status name to numeric ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser (app) | Application Service | Has EXECUTE permission - calls this function for status checks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a request has completed successfully
```sql
SELECT Wallet.DoesRequestStatusExist(4990718, 'Done')
-- Returns: 1 if request ever reached 'Done' status, 0 otherwise
```

### 8.2 Check if a request encountered an error
```sql
SELECT Wallet.DoesRequestStatusExist(4990718, 'Error')
-- Returns: 1 if any error status was recorded for this request
```

### 8.3 Filter requests that have completed
```sql
SELECT r.Id, r.CorrelationId, r.RequestTypeId, r.Timestamp
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.Gcid = 123456
  AND Wallet.DoesRequestStatusExist(r.Id, 'Done') = 1
ORDER BY r.Timestamp DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.DoesRequestStatusExist | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.DoesRequestStatusExist.sql*
