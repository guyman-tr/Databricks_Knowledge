# Wallet.GetRequestLastError

> Scalar function that retrieves the most recent error details JSON from a request's status history, returning the DetailsJson of the latest "Error" status entry.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) - error JSON payload |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetRequestLastError extracts the most recent error information for a wallet request by searching the request's status history for the latest entry with status name `'Error'` that contains valid JSON in its `DetailsJson` column. The returned JSON payload typically contains structured error details such as error codes, messages, and stack traces.

This function exists because error information in the wallet system is stored as JSON within status history records rather than in dedicated error columns. When a request fails, the error details are captured in the `DetailsJson` of the corresponding `'Error'` status entry. This function provides a clean, reusable way to retrieve that error payload.

The function is called by `Wallet.GetPaymentTransactionList` and `Wallet.GetPaymentTransactionListV2` to populate the `TransactionError` column in payment transaction results when the request status is `'Error'`. It is also used by `Wallet.ForDelete_GetTransactionRequests` for error reporting in legacy transaction request queries (only when status = 3, i.e., Error).

---

## 2. Business Logic

### 2.1 Most Recent Valid Error Extraction

**What**: Retrieves the JSON error details from the most recent error status entry for a request, with validity filtering.

**Columns/Parameters Involved**: `@RequestId`

**Rules**:
- Joins `Wallet.RequestStatuses` with `Dictionary.RequestStatuses` filtered to `Name = 'Error'`
- Filters on `ISNULL(rs.DetailsJson, '') <> ''` to skip entries with empty/null details
- Filters on `ISJSON(rs.DetailsJson) = 1` to skip entries with invalid JSON
- Orders by `rs.Id DESC` and takes `TOP 1` to get the most recent valid error
- Returns NULL if no valid error entry exists (request never errored, or error entries have no valid JSON)
- A request can have multiple error status entries (retries), but only the latest valid one is returned

**Diagram**:
```
Request 4990718 status history:
  Id=100: Pending    (DetailsJson: null)
  Id=101: Processing (DetailsJson: null)
  Id=102: Error      (DetailsJson: '{"Code":"WL.0102"}')   <-- candidate
  Id=103: Processing (DetailsJson: null)                     -- retry
  Id=104: Error      (DetailsJson: '{"Code":"WL.0105"}')   <-- SELECTED (most recent)
                                                              |
                                                              v
                                                  Return: '{"Code":"WL.0105"}'
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | bigint | NO | - | CODE-BACKED | The ID of the request to retrieve the last error for (FK to Wallet.Requests.Id). Identifies which request's status history to search for error entries. |
| 2 | RETURN | varchar(max) | YES | - | CODE-BACKED | The JSON error details payload from the most recent valid error status entry, or NULL if no error with valid JSON exists. Typically contains fields like `Code` (error code, e.g., `'WL.0102'`, `'WL.0105'`), `ErrorMessage`, and other error-specific context. Consumed by `GetPaymentTransactionList` to populate the `TransactionError` output column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestId | Wallet.RequestStatuses | FROM/JOIN | Searches request status history for error entries with valid JSON details |
| - | Dictionary.RequestStatuses | JOIN | Resolves status name `'Error'` to numeric ID for filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetPaymentTransactionList | TransactionError output | Function Call | Calls `GetRequestLastError(r.Id)` to populate error details for payment transactions |
| Wallet.GetPaymentTransactionListV2 | TransactionError output | Function Call | Same usage as V1 |
| Wallet.ForDelete_GetTransactionRequests | TransactionError output | Function Call | Conditionally calls when `base.Status = 3` (Error) for legacy transaction request reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRequestLastError (function)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | Reads error status entries (FROM with NOLOCK, filtered to 'Error' name and valid JSON) |
| Dictionary.RequestStatuses | Table | JOINed to resolve status name `'Error'` to numeric ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetPaymentTransactionList | Function | Calls to populate TransactionError column |
| Wallet.GetPaymentTransactionListV2 | Function | Same usage |
| Wallet.ForDelete_GetTransactionRequests | Stored Procedure | Conditionally calls for error reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the last error for a specific request
```sql
SELECT Wallet.GetRequestLastError(4990718) AS LastErrorJson
-- Returns: '{"Code":"WL.0102","ErrorMessage":"Wallet not found"}' or NULL
```

### 8.2 Find recent requests with errors and their details
```sql
SELECT TOP 20
    r.Id,
    r.CorrelationId,
    r.RequestTypeId,
    Wallet.GetRequestLastError(r.Id) AS ErrorJson
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.Timestamp > DATEADD(HOUR, -24, GETUTCDATE())
  AND Wallet.GetRequestLastError(r.Id) IS NOT NULL
ORDER BY r.Timestamp DESC
```

### 8.3 Extract specific error code from the error JSON
```sql
SELECT
    r.Id,
    Wallet.GetValueFromJson(Wallet.GetRequestLastError(r.Id), 'Code') AS ErrorCode,
    Wallet.GetValueFromJson(Wallet.GetRequestLastError(r.Id), 'ErrorMessage') AS ErrorMsg
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.Id = 4990718
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRequestLastError | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.GetRequestLastError.sql*
