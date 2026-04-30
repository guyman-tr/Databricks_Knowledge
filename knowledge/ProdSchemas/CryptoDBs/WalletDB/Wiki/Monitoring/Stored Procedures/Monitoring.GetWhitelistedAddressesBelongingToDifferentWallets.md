# Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets

> Identifies blockchain addresses that appear in travel rule whitelists for multiple different customer/crypto combinations, detecting potential cross-contamination in address ownership.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns addresses whitelisted by multiple customer/crypto combos |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets detects addresses that appear in multiple customers' travel rule whitelists. A single blockchain address being claimed by different users (different Gcid+BlockchainCryptoId combinations) is unusual and may indicate shared addresses, address reuse across accounts, or data integrity issues. This is a compliance concern because travel rule verification assumes address-to-user mapping is unique.

Without this procedure, these shared-address scenarios would go undetected, potentially undermining the travel rule compliance framework.

The procedure uses HAVING COUNT(DISTINCT CONCAT(Gcid, '_', BlockchainCryptoId)) > 1 to find addresses with multiple owners, then aggregates wallet IDs, customer IDs, and crypto IDs using STRING_AGG.

---

## 2. Business Logic

### 2.1 Cross-Customer Address Detection

**What**: Finds addresses owned by multiple customer/crypto pairs.

**Columns/Parameters Involved**: `Address`, `Gcid`, `BlockchainCryptoId`

**Rules**:
- Groups by Address across all TravelRuleWhitelistedAddresses
- HAVING COUNT(DISTINCT CONCAT(Gcid, '_', BlockchainCryptoId)) > 1 finds shared addresses
- LEFT JOIN to Wallet.Wallets maps to actual wallet IDs (may not exist for all combinations)
- Results aggregated with STRING_AGG for WalletIds, Gcids, CryptoIds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Address | NVARCHAR | NO | - | CODE-BACKED | The blockchain address that is shared across multiple customer/crypto combinations. |
| 2 | WalletIds | NVARCHAR | YES | - | CODE-BACKED | Comma-separated list of wallet IDs claiming this address, or 'wallet not found' if no matching wallet exists. |
| 3 | Gcids | NVARCHAR | NO | - | CODE-BACKED | Comma-separated list of customer IDs who whitelisted this address. |
| 4 | CryptoIds | NVARCHAR | NO | - | CODE-BACKED | Comma-separated list of blockchain crypto IDs associated with this address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Eligibility.TravelRuleWhitelistedAddresses | FROM (read) | Source of whitelisted address records |
| Query body | Wallet.Wallets | LEFT JOIN | Maps Gcid+BlockchainCryptoId to wallet IDs |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets (procedure)
  ├── Eligibility.TravelRuleWhitelistedAddresses (table)
  └── Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.TravelRuleWhitelistedAddresses | Table | FROM - whitelist records |
| Wallet.Wallets | Table | LEFT JOIN - wallet lookup |

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

### 8.1 Run the check
```sql
EXEC Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets;
```

### 8.2 View all whitelists for a specific address
```sql
SELECT * FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = '0x1234...' ORDER BY Created DESC;
```

### 8.3 Count total shared addresses
```sql
SELECT COUNT(*) AS SharedAddresses FROM (
  SELECT Address FROM Eligibility.TravelRuleWhitelistedAddresses
  GROUP BY Address HAVING COUNT(DISTINCT CONCAT(Gcid, '_', BlockchainCryptoId)) > 1
) x;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetWhitelistedAddressesBelongingToDifferentWallets.sql*
