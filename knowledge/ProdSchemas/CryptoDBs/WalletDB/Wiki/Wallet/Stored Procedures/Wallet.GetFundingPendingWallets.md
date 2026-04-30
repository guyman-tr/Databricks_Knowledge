# Wallet.GetFundingPendingWallets

> Claims and returns pool wallets that are pending funding (FundingInitiated but not yet FundingSent), marking them as processed to prevent duplicate pickup.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet details for funding; updates Processed flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements a "claim and return" pattern for the wallet funding pipeline. When promotional wallets need to be funded with cryptocurrency, their pool status transitions to FundingInitiated. This procedure atomically marks those wallets as processed (Processed=1) and returns their details so the funding service can execute the on-chain funding transactions. The atomic UPDATE+OUTPUT pattern prevents multiple service instances from picking up the same wallet.

Without this procedure, the funding service would have no reliable way to claim pending-funding wallets without risking double-funding. The atomicity of the UPDATE with OUTPUT ensures exactly-once processing semantics in a concurrent environment.

The procedure reads from `Wallet.WalletPoolStatuses` (filtered to FundingInitiated, Processed=0), joins to `Wallet.WalletPool` for wallet details and `Wallet.PromotionTags` for the funding amount. It uses ROW_NUMBER to limit processing to @MaxWalletsPerCrypto per cryptocurrency, preventing any single crypto from monopolizing a funding batch.

---

## 2. Business Logic

### 2.1 Claim-and-Return Funding Pattern

**What**: Atomically claims pending-funding wallets and returns them for processing.

**Columns/Parameters Involved**: `WalletPoolStatusId`, `Processed`, `@MaxWalletsPerCrypto`

**Rules**:
- Targets wallets where latest status is 'FundingInitiated' (4) AND Processed=0
- Excludes wallets that already have a 'FundingSent' (5) status for the same pool/promotion combination (prevents re-processing)
- UPDATE sets Processed=1, OUTPUT returns the DELETED (pre-update) values
- ROW_NUMBER partitioned by CryptoId limits to @MaxWalletsPerCrypto per crypto per batch
- The NOT EXISTS clause is the safety check: if FundingSent already exists for this pool+promotion, skip it

**Diagram**:
```
WalletPoolStatuses (FundingInitiated, Processed=0)
    |
    +-- NOT EXISTS: same WalletPoolId+PromotionTagId with FundingSent status
    |
    +-- JOIN WalletPool -> wallet details (Address, ProviderWalletId)
    +-- JOIN PromotionTags -> funding Amount
    |
    +-- ROW_NUMBER() PARTITION BY CryptoId <= @MaxWalletsPerCrypto
    |
    v
UPDATE Processed = 1
OUTPUT: WalletPoolStatusId, WalletPoolId, WalletId, CryptoId, Amount, Address, ProviderWalletId
```

### 2.2 Per-Crypto Batch Limiting

**What**: Prevents one cryptocurrency from consuming the entire funding batch.

**Columns/Parameters Involved**: `CryptoId`, `@MaxWalletsPerCrypto`

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY CryptoId ORDER BY wps.Id) assigns sequential numbers per crypto
- WHERE RowNum <= @MaxWalletsPerCrypto caps each crypto's contribution
- Oldest entries (lowest Id) are processed first within each crypto (FIFO)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxWalletsPerCrypto | INT | NO | - | CODE-BACKED | Maximum number of wallets to claim per cryptocurrency in this batch. Controls throughput to prevent one crypto from dominating the funding pipeline. |

### Return Columns (via OUTPUT)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | WalletPoolStatusId | BIGINT | NO | - | CODE-BACKED | The ID of the WalletPoolStatuses row that was claimed (marked Processed=1). From DELETED.Id. |
| 3 | WalletPoolId | BIGINT | NO | - | CODE-BACKED | The pool entry ID from Wallet.WalletPool. Identifies which pool wallet needs funding. |
| 4 | WalletId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | The wallet GUID from WalletPool. Used by the funding service to identify the target wallet. |
| 5 | CryptoId | INT | NO | - | CODE-BACKED | The cryptocurrency ID for this wallet. Determines which blockchain network to send the funding transaction on. |
| 6 | Amount | DECIMAL | NO | - | CODE-BACKED | The funding amount from Wallet.PromotionTags. This is the crypto amount to send to the wallet as part of the promotional funding. |
| 7 | Address | NVARCHAR | YES | - | CODE-BACKED | The public blockchain address of the pool wallet (from WalletPool.PublicAddress). The funding transaction sends crypto to this address. |
| 8 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | The custody provider's wallet identifier (e.g., BitGo wallet ID). Used by the funding service to construct the funding transaction via the provider API. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletPoolId | Wallet.WalletPool | JOIN | Retrieves wallet details (address, provider ID) for funding |
| WalletPoolStatusId | Wallet.WalletPoolStatuses | FROM + UPDATE | Claims FundingInitiated statuses by setting Processed=1 |
| PromotionTagId | Wallet.PromotionTags | JOIN | Gets the funding amount for the promotional wallet |
| StatusName | Dictionary.WalletPoolStatuses | JOIN | Resolves 'FundingInitiated' and 'FundingSent' status names to IDs |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers in SSDT. Called by the wallet funding service to process promotional wallet funding batches.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFundingPendingWallets (procedure)
+-- Wallet.WalletPoolStatuses (table)
+-- Wallet.WalletPool (table)
+-- Wallet.PromotionTags (table)
+-- Dictionary.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPoolStatuses | Table | FROM + UPDATE - claims pending funding entries |
| Wallet.WalletPool | Table | JOIN - wallet address and provider details |
| Wallet.PromotionTags | Table | JOIN - funding amount |
| Dictionary.WalletPoolStatuses | Table | JOIN x2 - resolves FundingInitiated and FundingSent status names |

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

### 8.1 Process up to 10 wallets per crypto for funding
```sql
EXEC Wallet.GetFundingPendingWallets @MaxWalletsPerCrypto = 10;
```

### 8.2 Check how many wallets are pending funding (without claiming)
```sql
SELECT wps.CryptoId, COUNT(*) AS PendingFunding
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE dwps.Name = 'FundingInitiated' AND wps.Processed = 0
GROUP BY wps.CryptoId
ORDER BY wps.CryptoId;
```

### 8.3 Check wallets stuck in FundingInitiated without FundingSent
```sql
SELECT wps.WalletPoolId, wps.CryptoId, wps.PromotionTagId, wps.Occurred
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE dwps.Name = 'FundingInitiated'
    AND wps.Processed = 1
    AND NOT EXISTS (
        SELECT 1 FROM Wallet.WalletPoolStatuses fs WITH (NOLOCK)
        JOIN Dictionary.WalletPoolStatuses dfs WITH (NOLOCK) ON dfs.Id = fs.WalletPoolStatusId
        WHERE fs.WalletPoolId = wps.WalletPoolId AND dfs.Name = 'FundingSent'
    )
ORDER BY wps.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFundingPendingWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetFundingPendingWallets.sql*
