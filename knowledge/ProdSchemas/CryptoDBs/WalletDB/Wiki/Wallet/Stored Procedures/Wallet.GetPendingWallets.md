# Wallet.GetPendingWallets

> Retrieves wallets from the pool that are currently in a specified status, with optional filtering by creation date and specific wallet IDs, returning the latest status per wallet pool entry.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet pool entries filtered by current status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves wallets from the wallet pool that are currently in a specific operational status (e.g., pending funding, pending activation). It is used by the wallet lifecycle management system to find wallets at a particular stage so the next processing step can be applied - such as funding pending wallets, activating funded wallets, or retrying failed operations.

Without this procedure, the system would have no way to efficiently query which pool wallets are at a given lifecycle stage. The wallet pool contains pre-generated blockchain addresses that go through a multi-step provisioning pipeline (creation -> funding -> activation -> assignment to customer), and each step needs to find wallets ready for the next transition.

The procedure is called by the `ExecuterUser` service account, indicating it is part of the automated wallet provisioning pipeline. It determines the "current" status by using ROW_NUMBER() partitioned by wallet pool ID, ordered by status occurrence time descending - taking only the most recent status entry per wallet.

---

## 2. Business Logic

### 2.1 Latest-Status Resolution

**What**: Determines the current status of each wallet pool entry by selecting the most recent status record.

**Columns/Parameters Involved**: `WalletPoolStatuses.WalletPoolId`, `WalletPoolStatuses.Occurred`, `@WalletPoolStatusId`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY wp.Id ORDER BY wps.Occurred DESC) to identify the latest status per wallet pool entry
- Only rows with RowNum = 1 (most recent status) are retained
- The result is then filtered to match the requested @WalletPoolStatusId
- This pattern handles wallets that have gone through multiple status transitions

**Diagram**:
```
WalletPool entry (wp.Id = 100)
  Status 1: Created    (2024-01-01) -- RowNum = 3 (ignored)
  Status 2: Funded     (2024-01-02) -- RowNum = 2 (ignored)
  Status 3: Pending    (2024-01-03) -- RowNum = 1 (selected)
                                        |
                                        v
                              Matches @WalletPoolStatusId? --> Return
```

### 2.2 Optional Wallet ID Filtering

**What**: Allows callers to optionally restrict results to specific wallet IDs.

**Columns/Parameters Involved**: `@WalletIds`, `WalletPool.WalletId`

**Rules**:
- If @WalletIds is empty (COUNT = 0), all matching wallets are returned
- If @WalletIds contains entries, results are filtered via JOIN to only include those specific wallets
- Uses the Wallet.GuidListType UDT for passing multiple wallet IDs as a table-valued parameter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletPoolStatusId | int | NO | - | CODE-BACKED | The wallet pool status to filter by. Matches WalletPoolStatuses.WalletPoolStatusId. Common values: 1=Pending, 2=Funded, etc. (See Wallet.WalletPoolStatuses for full value map.) |
| 2 | @StartDate | date | YES | NULL | CODE-BACKED | Optional lower bound on wallet pool creation date. When NULL, defaults to '2000-01-01' (effectively no filter). Used to limit scope to recently created pool entries. |
| 3 | @WalletIds | Wallet.GuidListType | NO | READONLY | CODE-BACKED | Optional table-valued parameter of specific wallet IDs to filter to. When empty, all matching wallets are returned. When populated, only wallets with matching WalletId are included. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletPoolId | bigint | NO | - | CODE-BACKED | Identity ID of the wallet pool entry from Wallet.WalletPool. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Unique wallet identifier. FK to Wallet.Wallets. The wallet associated with this pool entry. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Blockchain crypto ID (aliased from BlockchainCryptoId). FK to Wallet.BlockchainCryptos. Identifies the blockchain network. |
| 4 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Raw blockchain crypto ID from WalletPool. Same value as CryptoId output - included for backward compatibility. |
| 5 | ProviderWalletId | nvarchar | NO | - | CODE-BACKED | The wallet identifier assigned by the blockchain provider (e.g., Fireblocks vault ID). |
| 6 | PublicAddress | nvarchar | NO | - | CODE-BACKED | The blockchain public address of this wallet pool entry. |
| 7 | WalletPoolStatusId | int | NO | - | CODE-BACKED | The current (most recent) status of this wallet pool entry. Always matches @WalletPoolStatusId input. |
| 8 | WalletProviderId | int | NO | - | CODE-BACKED | Blockchain infrastructure provider ID. Identifies which provider manages this wallet (e.g., Fireblocks). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletPool | Wallet.WalletPool | FROM | Main data source - pool of pre-generated wallets |
| WalletPoolStatuses | Wallet.WalletPoolStatuses | JOIN | Status history used to determine current status per pool entry |
| @WalletIds | Wallet.GuidListType | UDT | Table-valued parameter type for wallet ID filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | GRANT EXECUTE | Permission | Wallet provisioning service that queries pending wallets |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingWallets (procedure)
├── Wallet.WalletPool (table)
├── Wallet.WalletPoolStatuses (table)
└── Wallet.GuidListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Main data source - FROM with NOLOCK |
| Wallet.WalletPoolStatuses | Table | JOIN to get status history |
| Wallet.GuidListType | User Defined Type | Parameter type for @WalletIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (ExecuterUser service) | External | Calls to find wallets at a specific lifecycle stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hints | Read isolation | Both WalletPool and WalletPoolStatuses are read with NOLOCK to avoid blocking the provisioning pipeline |
| Temp table pattern | Performance | Results are materialized into #PendingWallets before the optional wallet ID filter is applied |

---

## 8. Sample Queries

### 8.1 Find all wallets currently in pending status (status 1)
```sql
DECLARE @EmptyWallets Wallet.GuidListType;
EXEC Wallet.GetPendingWallets @WalletPoolStatusId = 1, @StartDate = NULL, @WalletIds = @EmptyWallets;
```

### 8.2 Find specific wallets in funded status (status 2) created after a date
```sql
DECLARE @TargetWallets Wallet.GuidListType;
INSERT INTO @TargetWallets (Item) VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');
EXEC Wallet.GetPendingWallets @WalletPoolStatusId = 2, @StartDate = '2025-01-01', @WalletIds = @TargetWallets;
```

### 8.3 Manual check of latest status per wallet pool entry
```sql
SELECT wp.Id AS WalletPoolId, wp.WalletId, wp.BlockchainCryptoId,
    wps.WalletPoolStatusId, wps.Occurred AS StatusDate
FROM Wallet.WalletPool wp WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 wps.WalletPoolStatusId, wps.Occurred
        FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
        WHERE wps.WalletPoolId = wp.Id
        ORDER BY wps.Occurred DESC
    ) wps
WHERE wps.WalletPoolStatusId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingWallets.sql*
