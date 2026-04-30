# Wallet.GetNonAssignedBalanceAddresseses

> Returns wallet addresses that have no balance account assigned, indicating they need to be registered with the balance tracking system.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns addresses where BalanceAccountID IS NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies wallet addresses that have not yet been assigned a balance account. In eToro's crypto infrastructure, each wallet address needs a corresponding balance account for tracking purposes. A NULL BalanceAccountID means the address was created but its balance tracking registration was not completed, which could lead to missing balance updates for that address.

This is a data completeness health check used by operational services to find and remediate addresses that slipped through the balance account registration process.

Data comes from `Wallet.WalletAddresses` joined to `Wallet.CustomerWalletsView` for wallet context and `Wallet.BlockchainCryptos` for crypto validation, filtered to BalanceAccountID IS NULL.

---

## 2. Business Logic

### 2.1 Missing Balance Account Detection

**What**: Finds addresses without balance tracking registration.

**Columns/Parameters Involved**: `BalanceAccountID`, `WalletId`, `Address`

**Rules**:
- BalanceAccountID IS NULL indicates the address has no balance account assigned
- Every address should have a balance account for proper balance tracking
- Results include wallet context (CryptoId, Gcid) for the remediation service to process

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
| 1 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The wallet GUID that owns this address. FK to Wallet.Wallets. |
| 2 | Address | NVARCHAR | NO | - | CODE-BACKED | The blockchain address missing a balance account assignment. This address needs to be registered with the balance tracking system. |
| 3 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier from CustomerWalletsView. FK to Wallet.CryptoTypes. Determines which blockchain this address belongs to. |
| 4 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID owning this wallet. 0 for internal wallets, >0 for customer wallets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletAddresses | FROM | Source of address records filtered by NULL BalanceAccountID |
| WalletId | Wallet.CustomerWalletsView | JOIN | Wallet context (CryptoId, Gcid) |
| CryptoId | Wallet.BlockchainCryptos | JOIN | Validates crypto exists |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by balance account registration services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetNonAssignedBalanceAddresseses (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | FROM - addresses with NULL BalanceAccountID |
| Wallet.CustomerWalletsView | View | JOIN - wallet context |
| Wallet.BlockchainCryptos | Table | JOIN - crypto validation |

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
EXEC Wallet.GetNonAssignedBalanceAddresseses;
```

### 8.2 Count unassigned addresses by crypto
```sql
SELECT cw.CryptoId, ct.Name, COUNT(*) AS UnassignedCount
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON cw.Id = wa.WalletId
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = cw.CryptoId
WHERE wa.BalanceAccountID IS NULL
GROUP BY cw.CryptoId, ct.Name
ORDER BY UnassignedCount DESC;
```

### 8.3 Compare assigned vs unassigned address counts
```sql
SELECT
    SUM(CASE WHEN BalanceAccountID IS NOT NULL THEN 1 ELSE 0 END) AS Assigned,
    SUM(CASE WHEN BalanceAccountID IS NULL THEN 1 ELSE 0 END) AS Unassigned
FROM Wallet.WalletAddresses WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetNonAssignedBalanceAddresseses | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetNonAssignedBalanceAddresseses.sql*
