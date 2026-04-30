# Wallet.InsertWalletToPool

> Adds a pre-created blockchain wallet to the pool reserve, optionally creating its address record and crypto-specific pool attributes (XRP reserve, NEAR creation fee) within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into WalletPool + conditional WalletAddresses + WalletPoolAttributes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers a new pre-created blockchain wallet into the pool reserve. When blockchain providers create wallets ahead of time (for instant customer assignment), the back-office API and executer service call this to add them to WalletPool. The procedure atomically creates the pool record, conditionally creates a WalletAddresses entry (skipped for 'wallet pending' addresses), and sets crypto-specific pool attributes:
- XRP (CryptoId=4): ReservedAmount = 1.2 XRP (network minimum balance)
- NEAR (CryptoId=27): ReservedAmount = 0, CreationFee = 100

Returns the generated pool record Id via OUTPUT clause.

---

## 2. Business Logic

### 2.1 Conditional Address Creation

**What**: Only creates WalletAddresses record if the wallet has a real address.

**Columns/Parameters Involved**: `@PublicAddress`

**Rules**:
- IF @PublicAddress <> 'wallet pending' -> INSERT WalletAddresses with IsMain=1, CustomerWalletStatusId=1
- 'wallet pending' wallets are created by provider but address not yet assigned - address record deferred

### 2.2 Crypto-Specific Pool Attributes

**What**: Different blockchains have different reserve requirements.

**Columns/Parameters Involved**: `@CryptoId`, `WalletPoolAttributes`

**Rules**:
- XRP (CryptoId=4): ReservedAmount=1.2 (network minimum account reserve)
- NEAR (CryptoId=27): ReservedAmount=0, CreationFee=100 (NEAR account creation cost)
- Other cryptos: no WalletPoolAttributes record created

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Pool wallet GUID. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Base-chain crypto. Determines pool attribute defaults. |
| 3 | @ProviderWalletId | nvarchar(100) | NO | - | VERIFIED | Provider's reference ID. |
| 4 | @PublicAddress | nvarchar(512) | NO | - | VERIFIED | Blockchain address. 'wallet pending' if not yet assigned. |
| 5 | @Created | datetime2(7) | NO | - | CODE-BACKED | Creation timestamp. |
| 6 | @WalletProviderId | int | YES | 1 | VERIFIED | Provider ID. Default 1 (BitGo). FK to Dictionary.WalletProvider. |
| 7 | Id (output) | bigint | NO | - | CODE-BACKED | Generated WalletPool record ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | INSERT (OUTPUT) | Pool wallet record |
| - | Wallet.WalletAddresses | Conditional INSERT | Address record (if not pending) |
| - | Wallet.WalletPoolAttributes | Conditional INSERT | XRP/NEAR attributes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Pool wallet registration |
| ExecuterUser | - | EXECUTE | Automated pool wallet creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertWalletToPool (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.WalletPoolAttributes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | INSERT target |
| Wallet.WalletAddresses | Table | Conditional INSERT |
| Wallet.WalletPoolAttributes | Table | Conditional INSERT (XRP/NEAR) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, ExecuterUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION + OUTPUT clause.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Add a BTC wallet to pool
```sql
EXEC Wallet.InsertWalletToPool @WalletId='NEW-GUID', @CryptoId=1, @ProviderWalletId='bitgo-wallet-123', @PublicAddress='1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa', @Created=GETUTCDATE();
```

### 8.2 Add an XRP wallet (gets ReservedAmount=1.2)
```sql
EXEC Wallet.InsertWalletToPool @WalletId='NEW-GUID', @CryptoId=4, @ProviderWalletId='bitgo-xrp-456', @PublicAddress='rN7..., @Created=GETUTCDATE();
```

### 8.3 Add a pending wallet (no address yet)
```sql
EXEC Wallet.InsertWalletToPool @WalletId='NEW-GUID', @CryptoId=1, @ProviderWalletId='bitgo-pending-789', @PublicAddress='wallet pending', @Created=GETUTCDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertWalletToPool | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertWalletToPool.sql*
