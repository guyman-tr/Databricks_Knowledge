# Wallet.GetTransactionOutputsByTransactionId

> Retrieves the individual output details (destination addresses, amounts, fees, source entity) for a specific sent blockchain transaction, supporting multi-output UTXO transactions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns SentTransactionOutputs rows by SentTransactionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all output records for a given sent transaction. A single blockchain transaction can have multiple outputs (especially on UTXO chains like Bitcoin where the recipient and change addresses are separate outputs). Each output row includes the destination address, amount, eToro fees, blockchain fees, and the optional source entity (e.g., a PositionId for redemption outputs).

Four services consume this: the AML service (analyzing destination addresses), the balance service (reconciling output amounts), the billing notification service (fee accounting), and the redeem scheduler (verifying redemption output details). The @MaxEntriesToReturn parameter limits the result set with a default of 1000, which accommodates even the most complex multi-output transactions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct single-table read from SentTransactionOutputs filtered by SentTransactionId with configurable row limit.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionId | bigint | NO | - | VERIFIED | The sent transaction whose outputs to retrieve. Matched against SentTransactionOutputs.SentTransactionId. FK to Wallet.SentTransactions.Id. |
| 2 | @MaxEntriesToReturn | int | YES | 1000 | CODE-BACKED | Maximum number of output records to return. Default 1000. |
| 3 | Id (output) | bigint | NO | - | CODE-BACKED | Auto-incrementing output record ID. |
| 4 | TransactionId (output) | bigint | NO | - | CODE-BACKED | Echo of the parent sent transaction ID. Aliased from SentTransactionId. |
| 5 | ToAddress (output) | nvarchar(512) | NO | - | CODE-BACKED | Destination blockchain address for this output. |
| 6 | Amount (output) | decimal(36,18) | NO | - | CODE-BACKED | Crypto amount sent to this output address. |
| 7 | EtoroFees (output) | decimal(36,18) | NO | - | CODE-BACKED | eToro service fee allocated to this output. |
| 8 | BlockchainFees (output) | decimal(36,18) | YES | - | CODE-BACKED | Network fee allocated to this output. NULL when fee is at transaction level. |
| 9 | SourceId (output) | bigint | YES | - | CODE-BACKED | Business entity ID this output originated from. For redemptions: PositionId. NULL for non-redemption outputs. |
| 10 | SourceIdType (output) | tinyint | YES | - | CODE-BACKED | Type of SourceId: 0=PositionId. See [Transaction Output Source ID Type](../../_glossary.md#transaction-output-source-id-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionId | Wallet.SentTransactionOutputs.SentTransactionId | Lookup | Primary search key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | Analyzes destination addresses |
| BalanceUser | - | EXECUTE | Reconciles output amounts |
| BillingNotificationUser | - | EXECUTE | Fee accounting |
| RedeemSchedulerUser | - | EXECUTE | Verifies redemption output details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionOutputsByTransactionId (procedure)
+-- Wallet.SentTransactionOutputs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactionOutputs | Table | Single-table read by SentTransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |
| BalanceUser | Service Account | EXECUTE grant |
| BillingNotificationUser | Service Account | EXECUTE grant |
| RedeemSchedulerUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get outputs for a specific transaction
```sql
EXEC Wallet.GetTransactionOutputsByTransactionId @TransactionId = 1907239;
```

### 8.2 Get outputs with a lower limit
```sql
EXEC Wallet.GetTransactionOutputsByTransactionId @TransactionId = 1907239, @MaxEntriesToReturn = 10;
```

### 8.3 Direct query equivalent
```sql
SELECT TOP 1000 Id, SentTransactionId AS TransactionId, ToAddress, Amount, EtoroFees, BlockchainFees, SourceId, SourceIdType
FROM Wallet.SentTransactionOutputs WITH (NOLOCK)
WHERE SentTransactionId = 1907239;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionOutputsByTransactionId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionOutputsByTransactionId.sql*
