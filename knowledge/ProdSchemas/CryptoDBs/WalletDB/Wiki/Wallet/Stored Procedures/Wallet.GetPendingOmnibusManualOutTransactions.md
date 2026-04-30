# Wallet.GetPendingOmnibusManualOutTransactions

> Retrieves omnibus (system-level, Gcid=0) manual out transactions that have not yet been converted into formal requests, indicating they are ready for processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unprocessed omnibus manual out transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds manual outbound crypto transactions from omnibus (system) wallets that have been submitted but not yet processed into the formal request pipeline. Manual out transactions are operator-initiated transfers (not customer-initiated) used for operations like consolidation sweeps, fee collection, cold storage transfers, or manual corrections.

"Omnibus" transactions (Gcid=0) are system-level operations not tied to any customer. The absence of a corresponding Request record (r.Id IS NULL via LEFT JOIN) indicates the transaction has been submitted but not yet picked up by the automation pipeline.

Data comes from `Wallet.ManualOutTransactions` LEFT JOINed to `Wallet.Requests` on CorrelationId. Unprocessed transactions are identified by Gcid=0 AND no matching request record.

---

## 2. Business Logic

### 2.1 Unprocessed Detection

**What**: Finds omnibus manual out transactions not yet converted to requests.

**Columns/Parameters Involved**: `Gcid`, `CorrelationId`, `Requests.Id`

**Rules**:
- Gcid=0: System/omnibus transactions only (not customer-initiated)
- LEFT JOIN Requests ON CorrelationId: If no matching request exists (r.Id IS NULL), the transaction is unprocessed
- Ordered by Occurred (oldest first) for FIFO processing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | ManualOutTransactions record ID. Primary identifier. |
| 2 | Gcid | BIGINT | NO | - | CODE-BACKED | Always 0 for omnibus transactions (system-level, no customer). |
| 3 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency for the outbound transaction. FK to Wallet.CryptoTypes. |
| 4 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Source wallet ID for the outbound transfer. |
| 5 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID for tracking. Will be used to create the formal Request record. |
| 6 | EtoroExternalAddressId | BIGINT | YES | - | CODE-BACKED | FK to Wallet.EtoroExternalAddresses. Identifies the verified destination address. |
| 7 | Amount | DECIMAL | NO | - | CODE-BACKED | Crypto amount to send in the outbound transaction. |
| 8 | Comment | NVARCHAR | YES | - | CODE-BACKED | Operator-provided comment explaining the reason for the manual transfer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualOutTransactions | FROM | Source of manual outbound transactions |
| CorrelationId | Wallet.Requests | LEFT JOIN | Checks if transaction has been processed into a request |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the omnibus transaction processing service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingOmnibusManualOutTransactions (procedure)
+-- Wallet.ManualOutTransactions (table)
+-- Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualOutTransactions | Table | FROM - manual out transaction records |
| Wallet.Requests | Table | LEFT JOIN - processed state check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetPendingOmnibusManualOutTransactions;
```

### 8.2 Check all manual out transactions by Gcid type
```sql
SELECT CASE WHEN Gcid = 0 THEN 'Omnibus' ELSE 'Customer' END AS TxType, COUNT(*) AS TxCount
FROM Wallet.ManualOutTransactions WITH (NOLOCK)
GROUP BY CASE WHEN Gcid = 0 THEN 'Omnibus' ELSE 'Customer' END;
```

### 8.3 View recent omnibus transactions with request status
```sql
SELECT TOP 10 omot.Id, omot.CryptoId, omot.Amount, omot.Occurred, omot.Comment,
       CASE WHEN r.Id IS NULL THEN 'Pending' ELSE 'Processed' END AS Status
FROM Wallet.ManualOutTransactions omot WITH (NOLOCK)
LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = omot.CorrelationId
WHERE omot.Gcid = 0
ORDER BY omot.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingOmnibusManualOutTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingOmnibusManualOutTransactions.sql*
