# Wallet.DeactivateWallet

> Soft-deletes a customer's wallet by setting its IsActive flag to 0, preventing further operations while preserving the historical record.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Wallet.Wallets.IsActive |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure deactivates a customer's wallet by setting IsActive = 0. Deactivation is a soft delete - the wallet record is preserved for audit and historical queries, but the wallet is no longer available for new transactions, address generation, or balance operations. This is used when a customer closes their account, when a wallet is compromised, or during wallet migration.

Without this procedure, there would be no way to disable a wallet while maintaining its history, forcing either hard deletion (losing data) or leaving compromised/closed wallets active.

The procedure is intentionally simple - a single UPDATE with no additional validation, as the business rules for when to deactivate are enforced at the application layer.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column UPDATE operation. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the wallet owner. Used with @WalletId for precise targeting (prevents cross-customer wallet deactivation). |
| 2 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet to deactivate. Both @Gcid and @WalletId must match for the UPDATE to affect any rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Wallet.Wallets | Modifier | Sets IsActive = 0 |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application wallet services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.DeactivateWallet (procedure)
  └── Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | UPDATE target |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- No error handling - relies on WHERE clause to prevent unintended updates
- Both Gcid AND WalletId must match (double safety)

---

## 8. Sample Queries

### 8.1 Check if a wallet is active
```sql
SELECT WalletId, Gcid, IsActive, BlockchainCryptoId, WalletTypeId
FROM Wallet.Wallets WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.2 Find deactivated wallets for a customer
```sql
SELECT WalletId, BlockchainCryptoId, WalletTypeId, IsActive
FROM Wallet.Wallets WITH (NOLOCK)
WHERE Gcid = 12345678 AND IsActive = 0
```

### 8.3 Count active vs inactive wallets
```sql
SELECT IsActive, COUNT(*) AS Cnt
FROM Wallet.Wallets WITH (NOLOCK)
GROUP BY IsActive
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.DeactivateWallet | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.DeactivateWallet.sql*
