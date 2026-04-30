# Wallet.GetBalanceAccountsByWallet

> Returns the external balance system account IDs associated with a wallet's addresses, used for balance reconciliation with external custody/tracking systems.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BalanceAccountID list for a wallet |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the external balance tracking account IDs for a wallet. Wallet addresses can be linked to accounts in an external balance system for reconciliation. This procedure returns those account IDs for a given wallet, filtering out addresses that have no external account assignment.

Without this procedure, the reconciliation service could not identify which external accounts correspond to a wallet.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple filtered SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet to retrieve balance accounts for. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletAddresses | Reader | Source of balance account IDs |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetBalanceAccountsByWallet (procedure)
  └── Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- Filters WHERE BalanceAccountID IS NOT NULL

---

## 8. Sample Queries

### 8.1 Execute for a specific wallet
```sql
EXEC Wallet.GetBalanceAccountsByWallet @WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.2 Find wallets with balance accounts
```sql
SELECT DISTINCT WalletId
FROM Wallet.WalletAddresses WITH (NOLOCK)
WHERE BalanceAccountID IS NOT NULL
```

### 8.3 Count balance accounts per wallet
```sql
SELECT WalletId, COUNT(*) AS AccountCount
FROM Wallet.WalletAddresses WITH (NOLOCK)
WHERE BalanceAccountID IS NOT NULL
GROUP BY WalletId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetBalanceAccountsByWallet | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetBalanceAccountsByWallet.sql*
