# Wallet.AddPromotionToWallets

> Assigns a promotion tag to eligible unassigned wallets from the pool by initiating funding for the specified count of wallets matching the promotion's cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New rows in Wallet.WalletPoolStatuses; returns WalletsAdded and TotalWalletsWithPromotion |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports promotional campaigns where eToro pre-funds wallets with cryptocurrency for new customers or marketing events. Given a promotion tag and a count, it selects eligible wallets from the pool (unassigned to any customer, in "Verified" status, matching the promotion's blockchain), sets them to "FundingInitiated" status with the promotion tag, and returns the count of wallets added plus the total wallets already tagged with this promotion.

Without this procedure, the operations team could not batch-assign promotion wallets ahead of promotional campaigns. Pre-funding wallets is important for customer onboarding speed - when a promoted customer opens an account, an already-funded wallet can be assigned instantly.

The procedure joins PromotionTags to determine the cryptocurrency, resolves the blockchain via CryptoTypes, finds eligible wallets in the pool (not yet assigned to a customer, in Verified status, not already tagged), and inserts FundingInitiated status records.

---

## 2. Business Logic

### 2.1 Wallet Eligibility for Promotion

**What**: Only unassigned, verified wallets without an existing promotion tag qualify.

**Columns/Parameters Involved**: `@PromotionId`, `@Count`, WalletPool, WalletPoolStatuses, CustomerWalletsView

**Rules**:
- Wallet must have matching BlockchainCryptoId (via CryptoTypes from PromotionTags.CryptoId)
- Wallet must NOT be assigned to any customer (LEFT JOIN CustomerWalletsView cwv WHERE cwv.Id IS NULL)
- Wallet must NOT already have this promotion tag (NOT EXISTS on WalletPoolStatuses with same PromotionTagId)
- Wallet must be in "Verified" status (EXISTS on WalletPoolStatuses with status matching Dictionary.WalletPoolStatuses "Verified")
- Ordered by Created date (FIFO - oldest eligible wallets first)
- Limited to TOP(@Count) wallets

### 2.2 Return Values

**What**: Reports how many wallets were tagged in this call and the total count.

**Columns/Parameters Involved**: Return resultset

**Rules**:
- WalletsAdded = @@ROWCOUNT from the INSERT (actual wallets tagged this call)
- TotalWalletsWithPromotion = COUNT of all distinct WalletPoolIds with this PromotionTagId
- If fewer than @Count eligible wallets exist, WalletsAdded < @Count

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PromotionId | int | NO | - | CODE-BACKED | The promotion tag ID to assign. References Wallet.PromotionTags.Id. Determines which cryptocurrency's wallets to target based on the promotion's CryptoId. |
| 2 | @Count | int | NO | - | CODE-BACKED | Maximum number of wallets to tag with this promotion. Actual count may be lower if fewer eligible wallets exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PromotionId | Wallet.PromotionTags | JOIN | Gets CryptoId for the promotion |
| - | Wallet.CryptoTypes | JOIN | Resolves CryptoId to BlockchainCryptoId |
| - | Wallet.WalletPool | JOIN | Source of eligible wallets |
| - | Dictionary.WalletPoolStatuses | JOIN | Resolves "FundingInitiated" and "Verified" status names to IDs |
| - | Wallet.WalletPoolStatuses | Writer + Reader | Inserts new FundingInitiated status; reads existing statuses for eligibility |
| - | Wallet.CustomerWalletsView | LEFT JOIN | Checks wallet is unassigned |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application operations/marketing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddPromotionToWallets (procedure)
  ├── Wallet.PromotionTags (table)
  ├── Wallet.CryptoTypes (table)
  ├── Wallet.WalletPool (table)
  ├── Wallet.WalletPoolStatuses (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Dictionary.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.PromotionTags | Table | JOIN to get promotion's CryptoId |
| Wallet.CryptoTypes | Table | JOIN to resolve BlockchainCryptoId |
| Wallet.WalletPool | Table | Source of eligible wallets |
| Wallet.WalletPoolStatuses | Table | INSERT target + eligibility check |
| Wallet.CustomerWalletsView | View | LEFT JOIN to verify wallet is unassigned |
| Dictionary.WalletPoolStatuses | Table | JOIN to resolve status names |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses NOLOCK hints on all reads for performance
- No explicit transaction wrapping
- TOP(@Count) limits the batch size
- ORDER BY Created ensures FIFO wallet assignment

---

## 8. Sample Queries

### 8.1 Check how many wallets have a given promotion
```sql
SELECT COUNT(DISTINCT WalletPoolId) AS WalletsWithPromotion
FROM Wallet.WalletPoolStatuses WITH (NOLOCK)
WHERE PromotionTagId = 1
```

### 8.2 View promotion tags with their crypto
```sql
SELECT pt.Id, pt.Name, ct.CryptoName, pt.CryptoId
FROM Wallet.PromotionTags pt WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = pt.CryptoId
```

### 8.3 Find wallets with FundingInitiated status for a promotion
```sql
SELECT wp.Id, wp.WalletId, wp.ProviderWalletId, wps.Created AS FundingInitiatedDate
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wp.Id = wps.WalletPoolId
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE wps.PromotionTagId = 1 AND dwps.Name = 'FundingInitiated'
ORDER BY wps.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddPromotionToWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddPromotionToWallets.sql*
