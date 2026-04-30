# Wallet.GetRequestStatusDetails

> Scalar function that retrieves the most recent DetailsJson for a specific named status from a request's status history.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) - status details JSON payload |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetRequestStatusDetails is a general-purpose status detail retriever that extracts the `DetailsJson` payload from the most recent occurrence of any named status in a request's lifecycle. Unlike `Wallet.GetRequestLastError` which is hardcoded to the `'Error'` status, this function accepts any status name as a parameter, making it suitable for retrieving details from any point in the request lifecycle (e.g., `'Done'`, `'ExecuterEnqueued'`, `'TransactionSentToBlockChain'`, `'FiatAccountFunded'`).

This function exists because each status transition in the wallet request pipeline can carry a JSON payload with contextual details specific to that transition. For example, the `'TransactionSentToBlockChain'` status entry contains the blockchain transaction ID, while `'ExecuterEnqueued'` contains the saga key for orchestration tracking. This function provides a clean interface to retrieve those details by name.

The function has EXECUTE permission granted to `ConversionUser`, indicating it is called from the Conversion application service. No stored procedure consumers were found in the SSDT repo, suggesting its primary use is in application-level code for retrieving status context during request processing.

---

## 2. Business Logic

### 2.1 Named Status Detail Retrieval

**What**: Retrieves the JSON details payload from the most recent occurrence of a specific named status in a request's history.

**Columns/Parameters Involved**: `@RequestId`, `@StatusName`

**Rules**:
- Joins `Wallet.RequestStatuses` (NOLOCK) with `Dictionary.RequestStatuses` (NOLOCK) on `RequestStatusId = Id`
- Filters on `RequestId = @RequestId` and `drs.Name = @StatusName`
- Orders by `rs.Id DESC` and takes `TOP 1` to get the most recent matching entry
- Wrapped in `ISNULL(..., NULL)` - returns NULL if no matching status exists
- Unlike `GetRequestLastError`, does NOT filter on `ISJSON()` or non-empty - returns whatever DetailsJson is stored, even if NULL or non-JSON
- A request may have multiple entries for the same status name (e.g., retries); only the latest is returned

**Diagram**:
```
@RequestId = 4990718, @StatusName = 'TransactionSentToBlockChain'
  |
  v
Wallet.RequestStatuses (history for request 4990718):
  Id=100: Pending             (DetailsJson: null)
  Id=101: ExecuterEnqueued    (DetailsJson: '{"SagaKey":"abc-123"}')
  Id=102: TransactionSentToBlockChain (DetailsJson: '{"TxId":"0xabc..."}')  <-- SELECTED
  Id=103: Done                (DetailsJson: null)
  |
  v
Return: '{"TxId":"0xabc..."}'
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | bigint | NO | - | CODE-BACKED | The ID of the request whose status details to retrieve (FK to Wallet.Requests.Id). |
| 2 | @StatusName | varchar(50) | NO | - | CODE-BACKED | The human-readable name of the status to look up in `Dictionary.RequestStatuses.Name`. Any valid status name can be used: `'Done'`, `'Error'`, `'ExecuterEnqueued'`, `'TransactionSentToBlockChain'`, `'FiatAccountFunded'`, `'TransactionVerified'`, `'TransactionConfirmed'`, `'AmlEnqueued'`, etc. |
| 3 | RETURN | varchar(max) | YES | - | CODE-BACKED | The `DetailsJson` from the most recent status entry matching the given name, or NULL if the status was never recorded for this request. The JSON structure varies by status type - each status transition stores its own context-specific payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestId | Wallet.RequestStatuses | FROM/JOIN | Searches request status history for entries matching the named status |
| @StatusName | Dictionary.RequestStatuses | JOIN | Resolves human-readable status name to numeric ID for filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser (app service) | - | EXECUTE permission | Called from the Conversion application service to retrieve status-specific JSON details during request processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRequestStatusDetails (function)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | Reads status history entries (FROM with NOLOCK) |
| Dictionary.RequestStatuses | Table | JOINed to resolve status name to numeric ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser (app) | Application Service | Has EXECUTE permission - calls for status detail retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get blockchain transaction details from a sent-to-chain status
```sql
SELECT Wallet.GetRequestStatusDetails(4990718, 'TransactionSentToBlockChain') AS TxDetails
-- Returns: '{"TxId":"0xabc...","BlockNumber":12345}'
```

### 8.2 Extract saga orchestration key from enqueue status
```sql
SELECT Wallet.GetValueFromJson(
    Wallet.GetRequestStatusDetails(4990718, 'ExecuterEnqueued'),
    'SagaKey'
) AS SagaKey
```

### 8.3 Get fiat funding details for crypto-to-fiat transactions
```sql
SELECT
    r.Id,
    r.CorrelationId,
    Wallet.GetRequestStatusDetails(r.Id, 'FiatAccountFunded') AS FiatDetails
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.RequestTypeId = 7  -- CryptoToFiat
  AND r.Gcid = 123456
ORDER BY r.Timestamp DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRequestStatusDetails | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.GetRequestStatusDetails.sql*
