# Wallet.GetTravelRuleTransactionHash

> Retrieves the blockchain transaction hash for a received transaction by its internal ID, used by the travel rule compliance service to correlate inbound transactions with their on-chain identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BlockchainTransactionId by ReceivedTransactions.Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the on-chain blockchain transaction hash for a specific received (inbound) transaction. Travel rule compliance requires tracking the blockchain hash of incoming transactions to verify the originator information provided by the sending institution. The back-office API uses this to look up the blockchain hash when processing travel rule verification workflows.

The procedure is a minimal single-column lookup on ReceivedTransactions, returning only the BlockchainTransactionId. This hash can then be checked on a blockchain explorer to verify the transaction's details.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct scalar lookup on ReceivedTransactions by Id.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionId | bigint | NO | - | VERIFIED | Internal received transaction ID. FK to Wallet.ReceivedTransactions.Id. |
| 2 | BlockchainTransactionId (output) | nvarchar(100) | YES | - | CODE-BACKED | On-chain transaction hash for the received transaction. Can be looked up on blockchain explorers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionId | Wallet.ReceivedTransactions.Id | Lookup | Received transaction hash resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Travel rule compliance workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTravelRuleTransactionHash (procedure)
+-- Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | Scalar lookup by Id |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get blockchain hash for a received transaction
```sql
EXEC Wallet.GetTravelRuleTransactionHash @TransactionId = 12345;
```

### 8.2 Direct query equivalent
```sql
SELECT BlockchainTransactionId FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE Id = 12345;
```

### 8.3 Full received transaction lookup by hash
```sql
-- First get the hash
DECLARE @Hash NVARCHAR(100);
SELECT @Hash = BlockchainTransactionId FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE Id = 12345;
-- Then look up the full record
SELECT * FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE BlockchainTransactionId = @Hash;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTravelRuleTransactionHash | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTravelRuleTransactionHash.sql*
