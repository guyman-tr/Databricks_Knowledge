# Wallet.UpdateWalletPoolAddress

> Updates a pool wallet's public address and atomically creates a WalletAddresses record if one doesn't exist, used by the executer service when a pending pool wallet receives its blockchain address from the provider.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE WalletPool + conditional INSERT WalletAddresses (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure assigns a real blockchain address to a pool wallet that was created with 'wallet pending' status. When the blockchain provider finishes creating the wallet and reports the actual address, the executer service calls this to update the pool record and create the address record. Transactional: both the UPDATE and conditional INSERT succeed or both roll back.

---

## 2. Business Logic

### 2.1 Address Assignment with Conditional Address Record

**What**: Updates pool address and creates WalletAddresses record if missing.

**Rules**:
- UPDATE WalletPool SET PublicAddress = @PublicAddress WHERE Id = @WalletPoolId
- INSERT WalletAddresses only if no record exists (LEFT JOIN wa IS NULL)
- Sets IsMain=1, CustomerWalletStatusId=1 for the new address

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletPoolId | bigint | NO | - | VERIFIED | Pool wallet to update. |
| 2 | @PublicAddress | nvarchar(512) | NO | - | VERIFIED | New blockchain address from the provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletPoolId | Wallet.WalletPool | UPDATE | Address assignment |
| - | Wallet.WalletAddresses | Conditional INSERT | Address record creation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Pending wallet address resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateWalletPoolAddress (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | UPDATE target |
| Wallet.WalletAddresses | Table | Conditional INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Assign address to a pending pool wallet
```sql
EXEC Wallet.UpdateWalletPoolAddress @WalletPoolId = 12345, @PublicAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
```

### 8.2 Check pool wallet before/after
```sql
SELECT Id, WalletId, PublicAddress FROM Wallet.WalletPool WITH (NOLOCK) WHERE Id = 12345;
```

### 8.3 Lifecycle: pending -> address assigned
```sql
-- 1. InsertWalletToPool with 'wallet pending' address
-- 2. Provider creates wallet, reports address
-- 3. UpdateWalletPoolAddress (this SP) assigns the real address
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateWalletPoolAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateWalletPoolAddress.sql*
