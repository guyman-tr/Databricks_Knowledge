# Monitoring.GetNoReceivedAmlValidations

> Detects verified receive transactions from external senders that have no corresponding AML validation record, indicating a gap in the anti-money-laundering screening process.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns receive transactions missing AML validation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetNoReceivedAmlValidations is a critical compliance alert that finds receive transactions which were verified but never had an AML (anti-money-laundering) validation created. Every external receive transaction should be screened by the AML provider (Chainalysis) before being credited to the customer. Missing AML records indicate a gap in compliance coverage.

Without this procedure, transactions that bypassed AML screening would go undetected, creating regulatory exposure. This is one of the most important compliance monitoring alerts.

The procedure uses multiple LEFT JOINs to find receive transactions that: (1) are verified (StatusId=2), (2) occurred in the last 24 hours but more than 1 hour ago (allowing processing time), (3) are external receive type (ReceivedTransactionTypeId=1), (4) have a ReceiveRequestCorrelationId, (5) the sender address is NOT an internal wallet address, and (6) have NO matching AML validation record.

---

## 2. Business Logic

### 2.1 Missing AML Validation Detection

**What**: Identifies external receive transactions without AML screening.

**Columns/Parameters Involved**: `AmlValidations.Id`, `ReceivedTransactionTypeId`, `SenderAddress`, `ReceiveRequestCorrelationId`

**Rules**:
- Only external receives (ReceivedTransactionTypeId=1) are checked
- Must have a ReceiveRequestCorrelationId (links to the request flow)
- Sender address must NOT belong to an internal wallet (LEFT JOIN to WalletAddresses with IS NULL)
- No matching AML validation found (LEFT JOIN to AmlValidations with IsSend=0 and matching correlation + address, then IS NULL)
- Window: last 24 hours excluding last 1 hour (gives AML provider time to process)
- Uses Wallet.SagaRuns join to verify saga context exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransaction ID. |
| 2 | BlockchainTransactionId | NVARCHAR | NO | - | CODE-BACKED | On-chain transaction hash/ID. |
| 3 | WalletId | BIGINT | NO | - | CODE-BACKED | Receiving wallet identifier. |
| 4 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Transaction correlation ID. |
| 5 | ReceiveRequestCorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Request-level correlation linking to the saga. |
| 6 | SenderAddress | NVARCHAR | NO | - | CODE-BACKED | External blockchain address that sent the crypto. |
| 7 | ReceiverAddress | NVARCHAR | NO | - | CODE-BACKED | Internal wallet address that received the crypto. |
| 8 | Amount | DECIMAL | NO | - | CODE-BACKED | Amount of crypto received. |
| 9 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. |
| 10 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the receive transaction was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.ReceivedTransactions | FROM (read) | Source of receive transaction records |
| Query body | Wallet.ReceivedTransactionStatuses | JOIN | Filters to verified receives (StatusId=2) |
| Query body | Wallet.SagaRuns | JOIN | Verifies saga context exists for the correlation |
| Query body | Wallet.WalletAddresses | LEFT JOIN | Checks if sender is an internal address (excluded if so) |
| Query body | Wallet.CustomerWalletsView | JOIN | Wallet ownership for internal address check |
| Query body | Wallet.AmlValidations | LEFT JOIN | Detects missing AML records (IS NULL = gap) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetNoReceivedAmlValidations (procedure)
  ├── Wallet.ReceivedTransactions (table)
  ├── Wallet.ReceivedTransactionStatuses (table)
  ├── Wallet.SagaRuns (table)
  ├── Wallet.WalletAddresses (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | FROM - receive records |
| Wallet.ReceivedTransactionStatuses | Table | JOIN - verified status |
| Wallet.SagaRuns | Table | JOIN - saga context |
| Wallet.WalletAddresses | Table | LEFT JOIN - internal address exclusion |
| Wallet.CustomerWalletsView | View | JOIN - wallet ownership |
| Wallet.AmlValidations | Table | LEFT JOIN - missing AML detection |

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

### 8.1 Run the compliance check
```sql
EXEC Monitoring.GetNoReceivedAmlValidations;
```

### 8.2 Count AML validations for recent receives
```sql
SELECT COUNT(DISTINCT rt.Id) AS ReceivesWithAml
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Wallet.AmlValidations av WITH (NOLOCK) ON av.CorrelationId = rt.ReceiveRequestCorrelationId AND av.IsSend = 0
WHERE rt.Occurred >= DATEADD(HOUR, -24, GETUTCDATE());
```

### 8.3 Check AML validation coverage rate
```sql
SELECT
  COUNT(*) AS TotalVerifiedReceives,
  SUM(CASE WHEN av.Id IS NOT NULL THEN 1 ELSE 0 END) AS WithAml,
  SUM(CASE WHEN av.Id IS NULL THEN 1 ELSE 0 END) AS WithoutAml
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Wallet.ReceivedTransactionStatuses rts WITH (NOLOCK) ON rts.ReceivedTransactionId = rt.Id AND rts.StatusId = 2
LEFT JOIN Wallet.AmlValidations av WITH (NOLOCK) ON av.CorrelationId = rt.ReceiveRequestCorrelationId AND av.IsSend = 0
WHERE rt.Occurred >= DATEADD(HOUR, -24, GETUTCDATE()) AND rt.ReceivedTransactionTypeId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetNoReceivedAmlValidations | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetNoReceivedAmlValidations.sql*
