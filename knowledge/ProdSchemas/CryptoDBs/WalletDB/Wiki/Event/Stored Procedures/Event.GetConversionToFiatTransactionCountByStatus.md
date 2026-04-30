# Event.GetConversionToFiatTransactionCountByStatus

> Returns the count of crypto-to-fiat conversion requests for a given user, filtered by a simplified transaction status (pending, error, or done).

| Property | Value |
|----------|-------|
| **Schema** | Event |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar COUNT(*) as Count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a count of crypto-to-fiat (C2F) conversion transactions for a specific user, categorized by a simplified three-state status model. It answers the question: "How many of this user's fiat conversion requests are pending, errored, or completed?" This is likely consumed by a UI component (the C2F popup tracked in Event.EventTypes) to display transaction status summaries to users.

The procedure exists because the underlying Wallet.RequestStatuses table uses a fine-grained event-sourced status model (40+ distinct statuses), but the front-end needs a simple three-state view: pending, error, or done. This procedure bridges that gap by mapping the complex request status lifecycle to a simplified consumer-friendly model.

Data flow: Called by the back-end API service (granted to BackApiUser). It reads from Wallet.Requests (to find ConversionToFiat requests by GCID) and Wallet.RequestStatuses (to determine the current status of each request). It does not write to any table. The procedure filters Wallet.Requests by RequestTypeId = 7 (ConversionToFiat - see [Request Type](../../_glossary.md#request-type)).

---

## 2. Business Logic

### 2.1 Simplified Transaction Status Mapping

**What**: Maps the complex request status lifecycle from Wallet.RequestStatuses into a three-state model for front-end consumption.

**Columns/Parameters Involved**: `@TransactionStatus`, `rs.RequestStatusId`, `rs.Id`

**Rules**:
- @TransactionStatus = 3 (Done): Matches requests where at least one RequestStatusId = 1 (Done) exists. This means the conversion completed successfully.
- @TransactionStatus = 2 (Error): Matches requests where at least one RequestStatusId = 2 (Error) exists. This means the conversion failed.
- @TransactionStatus = 1 (Pending/In Progress): Matches requests where NO Done (1) or Error (2) status exists AND the status row is the earliest for that request (TOP 1 by Id). These are requests still in the processing pipeline.

**Diagram**:
```
@TransactionStatus    Wallet.RequestStatuses mapping
     |
     3 (Done)    ---> RequestStatusId = 1 (Done)
     2 (Error)   ---> RequestStatusId = 2 (Error)
     1 (Pending) ---> NOT EXISTS(RequestStatusId IN (1, 2))
                      AND rs.Id = first status for this request
```

### 2.2 ConversionToFiat Request Filtering

**What**: Scopes the query exclusively to crypto-to-fiat conversion requests.

**Columns/Parameters Involved**: `r.RequestTypeId`, `r.Gcid`, `@Gcid`

**Rules**:
- Hard-coded filter: r.RequestTypeId = 7 (ConversionToFiat)
- User-scoped: r.Gcid = @Gcid
- Only ConversionToFiat requests are counted - other request types (SendTransaction, Redeem, etc.) are excluded

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID of the user whose C2F conversion transactions to count. Filters Wallet.Requests.Gcid. |
| 2 | @TransactionStatus | TINYINT (IN) | NO | - | CODE-BACKED | Simplified status filter. 1=Pending/In Progress (no terminal status exists), 2=Error (RequestStatusId=2 exists), 3=Done (RequestStatusId=1 exists). Maps to the complex Wallet.RequestStatuses lifecycle. |
| 3 | Count (output) | INT (result set) | NO | - | CODE-BACKED | Number of ConversionToFiat requests matching the given user and status. Returns 0 if no matching requests exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| r (alias) | Wallet.Requests | JOIN (FROM) | Base table for finding ConversionToFiat requests by GCID. Filtered by RequestTypeId = 7. |
| rs (alias) | Wallet.RequestStatuses | JOIN | Joined on rs.RequestId = r.Id to access request status history for determining the simplified transaction state. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | EXECUTE permission | Caller | The back-end API service account has EXECUTE permission, indicating this is called from the wallet API layer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Event.GetConversionToFiatTransactionCountByStatus (procedure)
├── Wallet.Requests (table)
└── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - base table for finding C2F requests by GCID and RequestTypeId = 7 |
| Wallet.RequestStatuses | Table | JOIN on RequestId - determines the status of each request |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Count completed C2F conversions for a user
```sql
EXEC Event.GetConversionToFiatTransactionCountByStatus @Gcid = 12345678, @TransactionStatus = 3
-- Returns count of Done (completed) conversions
```

### 8.2 Count pending C2F conversions for a user
```sql
EXEC Event.GetConversionToFiatTransactionCountByStatus @Gcid = 12345678, @TransactionStatus = 1
-- Returns count of in-progress conversions (no Done or Error status yet)
```

### 8.3 Equivalent manual query showing the status mapping logic
```sql
SELECT r.Id, r.Gcid, r.RequestTypeId,
       CASE 
           WHEN EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs2 WITH (NOLOCK) WHERE rs2.RequestId = r.Id AND rs2.RequestStatusId = 1) THEN 'Done'
           WHEN EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs2 WITH (NOLOCK) WHERE rs2.RequestId = r.Id AND rs2.RequestStatusId = 2) THEN 'Error'
           ELSE 'Pending'
       END AS SimplifiedStatus
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.Gcid = @Gcid AND r.RequestTypeId = 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. A "Crypto To Fiat Documentation" Confluence page exists (page ID 12028805398) but was inaccessible (404/permission denied).

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Event.GetConversionToFiatTransactionCountByStatus | Type: Stored Procedure | Source: WalletDB/Event/Stored Procedures/Event.GetConversionToFiatTransactionCountByStatus.sql*
