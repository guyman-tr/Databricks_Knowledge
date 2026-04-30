# Wallet.GetNonActivatedWallets

> Finds non-activated wallets for CryptoId=27 that have received enough funds to cover the creation fee, indicating they are ready for activation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallets eligible for activation based on received amounts vs creation fee |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports a specific blockchain (CryptoId=27) that requires an activation fee before a wallet becomes operational. Some blockchains (e.g., XRP, Stellar, certain L1 chains) require a minimum reserve or creation fee to activate an address on-chain. This procedure identifies wallets that have received sufficient crypto to cover the creation fee but have not yet been activated, so the activation service can process them.

Without this procedure, wallets would remain in a non-activated state indefinitely even after receiving sufficient funds. The customer would see their balance but be unable to transact until the on-chain activation is triggered.

Data comes from `Wallet.CustomerWalletsView` (IsActivated=0, CryptoId=27), joined to `Wallet.WalletPool` and `Wallet.WalletPoolAttributes` for the creation fee threshold, with a correlated subquery to `Wallet.ReceivedTransactions` to calculate total received amount.

---

## 2. Business Logic

### 2.1 Activation Eligibility

**What**: Determines if a non-activated wallet has received enough to cover the creation fee.

**Columns/Parameters Involved**: `IsActivated`, `CryptoId`, `Amount`, `CreationFee`

**Rules**:
- Only CryptoId=27 (hardcoded - a specific blockchain requiring activation)
- IsActivated=0 (wallet not yet activated on-chain)
- SUM(ReceivedTransactions.Amount) >= WalletPoolAttributes.CreationFee (sufficient funds received)
- The correlated subquery sums ALL received transaction amounts for the wallet
- WalletPoolAttributes.CreationFee defines the minimum reserve/activation amount for this crypto

**Diagram**:
```
CustomerWalletsView (IsActivated=0, CryptoId=27)
    |
    +-- JOIN WalletPool -> pool record for this wallet
    +-- JOIN WalletPoolAttributes -> CreationFee threshold
    |
    +-- Correlated subquery: SUM(ReceivedTransactions.Amount) for this wallet
    |
    v
Filter: received amount >= creation fee -> eligible for activation
```

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
| 1 | Id | BIGINT | NO | - | CODE-BACKED | Wallet record ID from CustomerWalletsView. Identifies the wallet ready for activation. |
| 2 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. Always 27 for this procedure. FK to Wallet.CryptoTypes. |
| 3 | BlockchainProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider's wallet ID. Backward-compatible column name. Used by the activation service to trigger on-chain activation via the provider API. |
| 4 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Same as BlockchainProviderWalletId (alias). Used by newer code. |
| 5 | WalletProviderId | INT | NO | - | CODE-BACKED | Custody provider ID. FK to Dictionary.WalletProvider (1=Bitgo, 2=CUG, 3=None). Determines which provider API to call for activation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | FROM | Source of non-activated wallet records |
| WalletId/Id | Wallet.WalletPool | JOIN | Links wallet to its pool entry |
| WalletPoolId | Wallet.WalletPoolAttributes | JOIN | Gets creation fee threshold |
| WalletId | Wallet.ReceivedTransactions | Correlated subquery | Sums received amounts to check against creation fee |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the wallet activation service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetNonActivatedWallets (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolAttributes (table)
+-- Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | FROM - non-activated wallet discovery |
| Wallet.WalletPool | Table | JOIN - pool entry for the wallet |
| Wallet.WalletPoolAttributes | Table | JOIN - creation fee threshold |
| Wallet.ReceivedTransactions | Table | Correlated subquery - total received amount |

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
EXEC Wallet.GetNonActivatedWallets;
```

### 8.2 Check non-activated wallets with their received totals
```sql
SELECT cwv.Id, cwv.Address, wpa.CreationFee,
       (SELECT SUM(rt.Amount) FROM Wallet.ReceivedTransactions rt WITH (NOLOCK) WHERE rt.WalletId = cwv.Id) AS TotalReceived
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wp.WalletId = cwv.Id
JOIN Wallet.WalletPoolAttributes wpa WITH (NOLOCK) ON wpa.WalletPoolId = wp.Id
WHERE cwv.IsActivated = 0 AND cwv.CryptoId = 27;
```

### 8.3 Check creation fees for CryptoId=27
```sql
SELECT wp.Id AS WalletPoolId, wpa.CreationFee
FROM Wallet.WalletPool wp WITH (NOLOCK)
JOIN Wallet.WalletPoolAttributes wpa WITH (NOLOCK) ON wpa.WalletPoolId = wp.Id
WHERE wp.BlockchainCryptoId = 27;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetNonActivatedWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetNonActivatedWallets.sql*
