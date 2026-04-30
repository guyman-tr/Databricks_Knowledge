# Wallet.GetWalletPoolReservedAmount

> Retrieves the reserved (locked) amount for a specific pool wallet by WalletId and CryptoId, used by the back-office API to check how much of a pool wallet's balance is reserved for pending operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar ReservedAmount from WalletPoolAttributes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the reserved amount for a pool wallet - the portion of its balance that has been locked for pending operations (e.g., customer assignments, pending sends). The back-office API uses this to display available vs reserved balance for pool wallets during operations review.

The procedure joins WalletPoolAttributes (which holds the reserved amount) with WalletPool (to resolve WalletId + BlockchainCryptoId to the pool record). Returns a scalar value or empty result if no attributes record exists.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct JOIN between WalletPoolAttributes and WalletPool for attribute lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Pool wallet GUID to check. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency to filter by. Matched against WalletPool.BlockchainCryptoId. |
| 3 | ReservedAmount (output) | decimal | YES | - | CODE-BACKED | Amount of crypto reserved/locked in this pool wallet for pending operations. NULL if no attributes record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId + @CryptoId | Wallet.WalletPool | JOIN | Resolves pool record |
| WalletPoolId | Wallet.WalletPoolAttributes | JOIN | Reserved amount lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Pool wallet reserved balance check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolReservedAmount (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolAttributes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | JOINed for WalletId + CryptoId resolution |
| Wallet.WalletPoolAttributes | Table | ReservedAmount value |

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

### 8.1 Check reserved amount for a pool wallet
```sql
EXEC Wallet.GetWalletPoolReservedAmount @WalletId = 'C0D5EF83-...', @CryptoId = 1;
```

### 8.2 Direct equivalent
```sql
SELECT wpa.ReservedAmount
FROM Wallet.WalletPoolAttributes wpa WITH (NOLOCK)
    JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wp.Id = wpa.WalletPoolId
WHERE wp.WalletId = 'C0D5EF83-...' AND wp.BlockchainCryptoId = 1;
```

### 8.3 Check all pool wallet reserved amounts
```sql
SELECT wp.WalletId, wp.BlockchainCryptoId, wpa.ReservedAmount
FROM Wallet.WalletPoolAttributes wpa WITH (NOLOCK)
    JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wp.Id = wpa.WalletPoolId
WHERE wpa.ReservedAmount > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolReservedAmount | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolReservedAmount.sql*
