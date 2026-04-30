# Wallet.GetPendingWalletsInPool

> Retrieves wallet pool entries in pending status (status 1) with pagination, optional crypto ID filtering, and optional restriction to specific wallet IDs - an enhanced version of GetPendingWallets for large-scale batch processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated pending wallet pool entries |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves wallet pool entries that are in pending status (WalletPoolStatusId = 1), with support for pagination, crypto-specific filtering, and targeted wallet lookups. It is an enhanced version of `Wallet.GetPendingWallets` designed for large-scale batch processing scenarios where the caller needs to page through large result sets or focus on a specific blockchain.

The wallet pool holds pre-generated blockchain addresses that progress through a provisioning lifecycle. "Pending" (status 1) wallets are those that have been created in the pool but have not yet been funded or activated. This procedure enables the provisioning pipeline to efficiently work through pending wallets in controlled batches.

Called by the `ExecuterUser` service account as part of the automated wallet provisioning pipeline. The pagination support (@FromId + @MaxRecords) allows the caller to process pending wallets in chunks without re-reading already-processed records, improving throughput for large-scale operations.

---

## 2. Business Logic

### 2.1 Hardcoded Pending Status Filter

**What**: Unlike GetPendingWallets which accepts any status ID, this procedure is hardcoded to status 1 (Pending).

**Columns/Parameters Involved**: `WalletPoolStatusId`

**Rules**:
- WHERE clause filters to WalletPoolStatusId = 1 (hardcoded, not parameterized)
- Still uses the ROW_NUMBER() latest-status pattern from GetPendingWallets
- Designed specifically for the "pending -> fund" transition in the provisioning pipeline

### 2.2 Cursor-Based Pagination

**What**: Supports efficient pagination through large result sets using ID-based cursoring.

**Columns/Parameters Involved**: `@FromId`, `@MaxRecords`, `WalletPool.Id`

**Rules**:
- @FromId filters to wp.Id > @FromId (keyset pagination - no offset scanning)
- @MaxRecords limits the result set via TOP
- Results ordered by WalletPoolId for deterministic pagination
- Caller passes the last WalletPoolId from previous batch as the next @FromId

**Diagram**:
```
Page 1: @FromId=0, @MaxRecords=1000
  Returns WalletPoolId 1..1000
                                    |
Page 2: @FromId=1000, @MaxRecords=1000
  Returns WalletPoolId 1001..2000
                                    |
Page 3: @FromId=2000, @MaxRecords=1000
  Returns WalletPoolId 2001..2500 (last page)
```

### 2.3 Optional Wallet ID Restriction

**What**: Supports both full-scan and targeted modes via the @WalletIds parameter.

**Columns/Parameters Involved**: `@WalletIds`, `@SpecificWallets`

**Rules**:
- @WalletIds is deduplicated into a temp table with a unique index for performance
- @SpecificWallets BIT flag is computed: 1 if wallet IDs were provided, 0 otherwise
- When @SpecificWallets = 0: all pending wallets matching other filters are returned
- When @SpecificWallets = 1: LEFT JOIN to #WalletIds, only rows with matching Item are returned (via AND Item IS NOT NULL)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | int | YES | - | CODE-BACKED | Optional blockchain crypto ID filter. When NULL, returns wallets for all cryptocurrencies. When specified, only returns wallets matching that blockchain. FK to Wallet.BlockchainCryptos. |
| 2 | @StartDate | date | YES | NULL | CODE-BACKED | Optional lower bound on wallet pool creation date. When NULL, defaults to '2000-01-01' (no filter). |
| 3 | @WalletIds | Wallet.GuidListType | NO | READONLY | CODE-BACKED | Optional table-valued parameter of specific wallet IDs. When empty, returns all matching wallets. When populated, restricts to those specific wallets. |
| 4 | @FromId | bigint | YES | 0 | CODE-BACKED | Pagination cursor - only returns wallet pool entries with Id greater than this value. Pass the last WalletPoolId from previous page. Default 0 starts from the beginning. |
| 5 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum number of records to return per page. Controls batch size for pagination. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletPoolId | bigint | NO | - | CODE-BACKED | Identity ID of the wallet pool entry. Used as pagination cursor for subsequent calls. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Unique wallet identifier. FK to Wallet.Wallets. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Blockchain crypto ID (aliased from BlockchainCryptoId). FK to Wallet.BlockchainCryptos. |
| 4 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Raw blockchain crypto ID. Same value as CryptoId - included for backward compatibility. |
| 5 | ProviderWalletId | nvarchar | NO | - | CODE-BACKED | Provider-assigned wallet identifier (e.g., Fireblocks vault ID). |
| 6 | PublicAddress | nvarchar | NO | - | CODE-BACKED | Blockchain public address of this wallet pool entry. |
| 7 | WalletPoolStatusId | int | NO | - | CODE-BACKED | Current status - always 1 (Pending) due to hardcoded filter. |
| 8 | WalletProviderId | int | NO | - | CODE-BACKED | Blockchain infrastructure provider ID. |
| 9 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent (pending) status entry for this wallet pool record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.WalletPool | FROM | Main data source - pool of pre-generated wallets |
| JOIN | Wallet.WalletPoolStatuses | JOIN | Status history for latest-status resolution |
| @WalletIds | Wallet.GuidListType | UDT | Table-valued parameter type for wallet ID filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | GRANT EXECUTE | Permission | Wallet provisioning service for batch processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingWalletsInPool (procedure)
├── Wallet.WalletPool (table)
├── Wallet.WalletPoolStatuses (table)
└── Wallet.GuidListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Main data source - FROM with NOLOCK |
| Wallet.WalletPoolStatuses | Table | JOIN to resolve latest status |
| Wallet.GuidListType | User Defined Type | Parameter type for @WalletIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (ExecuterUser service) | External | Calls for paginated batch processing of pending wallets |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table with unique index | Performance | #WalletIds temp table created with UNIQUE INDEX for efficient JOIN lookups |
| NOLOCK hints | Read isolation | All table reads use NOLOCK to avoid blocking |
| Keyset pagination | Performance | Uses wp.Id > @FromId instead of OFFSET for efficient paging on large datasets |

---

## 8. Sample Queries

### 8.1 Get first page of pending wallets for Bitcoin
```sql
DECLARE @WalletIds Wallet.GuidListType;
EXEC Wallet.GetPendingWalletsInPool @CryptoId = 1, @StartDate = NULL,
    @WalletIds = @WalletIds, @FromId = 0, @MaxRecords = 500;
```

### 8.2 Get next page using cursor from previous result
```sql
DECLARE @WalletIds Wallet.GuidListType;
EXEC Wallet.GetPendingWalletsInPool @CryptoId = NULL, @StartDate = '2025-01-01',
    @WalletIds = @WalletIds, @FromId = 5000, @MaxRecords = 1000;
```

### 8.3 Count pending wallets per crypto
```sql
SELECT wp.BlockchainCryptoId, COUNT(*) AS PendingCount
FROM Wallet.WalletPool wp WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 wps.WalletPoolStatusId
        FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
        WHERE wps.WalletPoolId = wp.Id
        ORDER BY wps.Occurred DESC
    ) latest
WHERE latest.WalletPoolStatusId = 1
GROUP BY wp.BlockchainCryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingWalletsInPool | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingWalletsInPool.sql*
