# Wallet.SetWalletAddressBalanceAccount

> Updates the balance account ID for a specific wallet address, linking the blockchain address to its provider-side balance tracking account.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE WalletAddresses SET BalanceAccountID by WalletId + Address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure links a wallet address to its provider-side balance account. When the blockchain provider assigns a balance account identifier to a wallet address (for balance tracking and reconciliation), the back-office API or balance service calls this to persist that mapping. The BalanceAccountID is used by GetWalletsByBalanceAccounts for reverse lookups.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple UPDATE on WalletAddresses by WalletId + Address.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet containing the address. |
| 2 | @Address | nvarchar(512) | NO | - | VERIFIED | Blockchain address to update. |
| 3 | @BalanceAccountId | varchar(50) | NO | - | VERIFIED | Provider's balance account identifier to assign. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId + @Address | Wallet.WalletAddresses | UPDATE | Sets BalanceAccountID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser, BalanceUser | - | EXECUTE | Balance account linking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SetWalletAddressBalanceAccount (procedure)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | UPDATE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BalanceUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Set balance account
```sql
EXEC Wallet.SetWalletAddressBalanceAccount @WalletId='WALLET-GUID', @Address='1A1zP1eP5...', @BalanceAccountId='BA-12345';
```

### 8.2 Verify the update
```sql
SELECT BalanceAccountID FROM Wallet.WalletAddresses WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID' AND Address = '1A1zP1eP5...';
```

### 8.3 Find addresses without balance accounts
```sql
SELECT WalletId, Address FROM Wallet.WalletAddresses WITH (NOLOCK) WHERE BalanceAccountID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SetWalletAddressBalanceAccount | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.SetWalletAddressBalanceAccount.sql*
