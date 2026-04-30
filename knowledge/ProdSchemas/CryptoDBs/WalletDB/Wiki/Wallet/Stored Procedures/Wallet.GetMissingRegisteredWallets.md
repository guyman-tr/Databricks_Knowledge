# Wallet.GetMissingRegisteredWallets

> Health-check procedure that counts wallets existing in WalletPool or Wallets tables but missing from WalletAddresses, indicating incomplete wallet registration.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns two count rows: pool wallets and assigned wallets without address records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a data integrity health check that detects wallets in an inconsistent state. Every wallet - whether in the pre-assignment pool or already assigned to a customer - should have a corresponding record in `Wallet.WalletAddresses`. A wallet without an address record means it was created in one system but its registration in the address tracking system failed or was skipped, leaving an orphaned wallet that cannot send or receive crypto.

Operations and monitoring services use this to detect registration gaps that need manual or automated remediation. A non-zero count in either category indicates a data quality issue that should be investigated.

The procedure uses two CTEs to separately count: (1) pool wallets without addresses (excluding those still with 'wallet pending' placeholder), and (2) assigned wallets without addresses. Results are combined via UNION ALL with descriptive status labels.

---

## 2. Business Logic

### 2.1 Pool Wallet Registration Gap

**What**: Detects pool wallets that have a real address but no WalletAddresses record.

**Columns/Parameters Involved**: `WalletPool.WalletId`, `WalletPool.PublicAddress`, `WalletAddresses.WalletId`

**Rules**:
- LEFT JOIN WalletPool to WalletAddresses on WalletId - missing = NULL
- Excludes pool entries where PublicAddress = 'wallet pending' (these are still being created and intentionally lack addresses)
- Only counts entries where WalletAddresses.Id IS NULL
- Label: 'IN_POOL_AND_NOT_IN_ADDR'

### 2.2 Assigned Wallet Registration Gap

**What**: Detects assigned (customer) wallets with no WalletAddresses record.

**Columns/Parameters Involved**: `Wallets.WalletId`, `WalletAddresses.WalletId`

**Rules**:
- LEFT JOIN Wallets to WalletAddresses on WalletId - missing = NULL
- No address filter (all assigned wallets should have addresses)
- Only counts entries where WalletAddresses.Id IS NULL
- Label: 'IN_WALLET_AND_NOT_IN_ADDR'

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
| 1 | CountRows | INT | NO | - | CODE-BACKED | Number of wallets missing address records in this category. Zero = healthy, non-zero = data quality issue needing investigation. |
| 2 | WalletStatus | VARCHAR | NO | - | CODE-BACKED | Category label: 'IN_POOL_AND_NOT_IN_ADDR' (pool wallets without addresses) or 'IN_WALLET_AND_NOT_IN_ADDR' (assigned wallets without addresses). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.WalletPool | FROM | Pool wallets to check for missing addresses |
| WalletId | Wallet.Wallets | FROM | Assigned wallets to check for missing addresses |
| WalletId | Wallet.WalletAddresses | LEFT JOIN | Address records - NULL means missing |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by monitoring/alerting systems for data integrity checks.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetMissingRegisteredWallets (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.Wallets (table)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FROM - pool wallet check |
| Wallet.Wallets | Table | FROM - assigned wallet check |
| Wallet.WalletAddresses | Table | LEFT JOIN - address existence check |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the health check
```sql
EXEC Wallet.GetMissingRegisteredWallets;
```

### 8.2 Find specific pool wallets missing addresses
```sql
SELECT wp.Id, wp.WalletId, wp.PublicAddress, wp.BlockchainCryptoId
FROM Wallet.WalletPool wp WITH (NOLOCK)
LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.WalletId = wp.WalletId
WHERE wp.PublicAddress <> 'wallet pending' AND wa.Id IS NULL;
```

### 8.3 Find specific assigned wallets missing addresses
```sql
SELECT w.Id, w.WalletId, w.BlockchainCryptoId, w.Occurred
FROM Wallet.Wallets w WITH (NOLOCK)
LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.WalletId = w.WalletId
WHERE wa.Id IS NULL
ORDER BY w.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetMissingRegisteredWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetMissingRegisteredWallets.sql*
