# Wallet.WalletPoolStatuses

> Event-sourced status history for pool wallets, recording each lifecycle transition from creation through verification, funding, and assignment to a customer.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 7 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the lifecycle of each pool wallet from `Wallet.WalletPool`. Similar to `Wallet.RequestStatuses`, it uses an event-sourced pattern where each status transition is appended as a new row. With ~3.24M rows tracking 2.47M pool wallets, each wallet averages ~1.3 status events (many go directly from Pending to Verified).

The lifecycle tracked is: Pending -> Verified -> FundingInitiated -> FundingSent -> FundingVerified -> VerifiedForAssign. See [Wallet Pool Status](../../_glossary.md#wallet-pool-status). Failed/timeout states exist for error paths. The `Processed` flag indicates whether downstream systems have acted on this status change.

Rows are created by pool management procedures during wallet creation, verification, and funding operations.

---

## 2. Business Logic

### 2.1 Pool Wallet Lifecycle

**What**: Pool wallets progress through a defined lifecycle tracked by status events.

**Columns/Parameters Involved**: `WalletPoolId`, `WalletPoolStatusId`, `Processed`

**Rules**:
- WalletPoolStatusId follows the lifecycle: 1=Pending -> 2=Verified -> 4=FundingInitiated -> 5=FundingSent -> 6=FundingVerified -> 11=VerifiedForAssign
- Error states: 3=Failed, 7=FundingFailed, 10=Timeout
- Processed=0 (default): Status event not yet consumed by downstream systems
- Processed=1: Status event has been consumed (e.g., wallet assigned to customer)
- CryptoId denormalized from WalletPool for efficient filtering

### 2.2 Promotion Integration

**What**: Pool wallets can be associated with promotional campaigns.

**Columns/Parameters Involved**: `PromotionTagId`, `WalletPoolId`

**Rules**:
- PromotionTagId links to Wallet.PromotionTags when the wallet is assigned as part of a promotion
- NULL for standard (non-promotional) wallet assignments
- FK to Wallet.PromotionTags.Id

---

## 3. Data Overview

| Id | WalletPoolId | WalletPoolStatusId | Processed | CryptoId | Meaning |
|---|---|---|---|---|---|
| 3621772 | 2469129 | 2 (Verified) | false | 64 (SOL) | SOL pool wallet verified on blockchain, not yet processed by downstream assignment system |
| 3621771 | 2469128 | 2 (Verified) | false | 64 (SOL) | Another SOL wallet in verified state, part of a batch creation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | WalletPoolId | bigint | NO | - | VERIFIED | The pool wallet this status event belongs to. FK to Wallet.WalletPool.Id. Multiple status rows per wallet (event-sourced). |
| 3 | WalletPoolStatusId | tinyint | NO | - | VERIFIED | The lifecycle status: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. See [Wallet Pool Status](../../_glossary.md#wallet-pool-status). FK to Dictionary.WalletPoolStatuses. |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this status transition. |
| 5 | PromotionTagId | int | YES | - | CODE-BACKED | Links to a promotional campaign if this wallet is part of a promotion. NULL for standard wallets. FK to Wallet.PromotionTags.Id. |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links this status event to the parent request that triggered the transition. |
| 7 | Processed | bit | NO | 0 | CODE-BACKED | Whether downstream systems have consumed this status event: 0=pending processing, 1=processed. Used by the assignment system to find wallets ready for customer assignment. |
| 8 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this pool wallet is for. FK to Wallet.CryptoTypes.CryptoID. Denormalized from WalletPool for efficient status-based filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletPoolId | Wallet.WalletPool | FK | Links to the pool wallet |
| WalletPoolStatusId | Dictionary.WalletPoolStatuses | FK | Identifies the lifecycle status |
| CryptoId | Wallet.CryptoTypes | FK | Identifies the cryptocurrency |
| PromotionTagId | Wallet.PromotionTags | FK | Links to promotional campaign |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddWalletsStatus | - | Writer | Appends status events |
| Wallet.GetPendingWalletsInPool | - | Reader | Reads unprocessed verified statuses |
| Wallet.SyncFundedWalletStatusesAsync | - | Reader/Writer | Syncs funding statuses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletPoolStatuses (table)
├── Wallet.WalletPool (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.CryptoTypes (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.PromotionTags (table)
│     └── Wallet.CryptoTypes (table)
└── Dictionary.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletPoolId |
| Dictionary.WalletPoolStatuses | Table | FK target for WalletPoolStatusId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.PromotionTags | Table | FK target for PromotionTagId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddWalletsStatus | Stored Procedure | Inserts status events |
| Wallet.GetPendingWalletsInPool | Stored Procedure | Reads pending wallets |
| Wallet.SyncFundedWalletStatusesAsync | Stored Procedure | Syncs funding statuses |
| Wallet.GetFreeWalletFromPool | Stored Procedure | Finds available wallets |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletPoolStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...PromotionTagId_WalletPoolStatusId_WalletPoolId | NC | PromotionTagId, WalletPoolStatusId, WalletPoolId | - | - | Active |
| IX_...WalletPoolStatusId_WalletPoolId | NC | WalletPoolStatusId, WalletPoolId | - | - | Active |
| IX_...WalletPoolId | NC | WalletPoolId | - | - | Active |
| IX_...WalletPoolId_Inc | NC | WalletPoolId | WalletPoolStatusId, Id | - | Active |
| ix_...Processed_WalletPoolStatusId | NC | Processed, WalletPoolStatusId | CryptoId, PromotionTagId, WalletPoolId | - | Active |
| IX_...WalletPoolId_Id_Inc | NC | WalletPoolId, Id DESC | WalletPoolStatusId | - | Active |
| IX_...WalletPoolStatusId_Processed | NC | WalletPoolStatusId, Processed | CorrelationId, Occurred, PromotionTagId, WalletPoolId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| DF (Processed) | DEFAULT | 0 |
| FK_...WalletPoolId | FK | WalletPoolId -> Wallet.WalletPool.Id |
| FK_...WalletPoolStatusId | FK | WalletPoolStatusId -> Dictionary.WalletPoolStatuses.Id |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_...PromotionTagId | FK | PromotionTagId -> Wallet.PromotionTags.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a pool wallet
```sql
SELECT wps.Id, dwps.Name AS Status, wps.Occurred, wps.Processed
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON wps.WalletPoolStatusId = dwps.Id
WHERE wps.WalletPoolId = 2469129
ORDER BY wps.Id
```

### 8.2 Find unprocessed verified wallets ready for assignment
```sql
SELECT wps.WalletPoolId, ct.Name AS Crypto, wps.Occurred
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wps.CryptoId = ct.CryptoID
WHERE wps.WalletPoolStatusId = 2 AND wps.Processed = 0
ORDER BY wps.Occurred
```

### 8.3 Pool wallet status distribution
```sql
SELECT dwps.Name AS Status, COUNT(*) AS EventCount
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON wps.WalletPoolStatusId = dwps.Id
GROUP BY dwps.Name
ORDER BY EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletPoolStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletPoolStatuses.sql*
