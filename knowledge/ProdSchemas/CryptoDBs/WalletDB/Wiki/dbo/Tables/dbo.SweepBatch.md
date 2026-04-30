# dbo.SweepBatch

> Operational table tracking cryptocurrency sweep operations that consolidate small customer wallet balances into omnibus wallets, organized in numbered batches.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY) |
| **Partition** | No |
| **Indexes** | 3 active (IX_AmountUSD, IX_SweepBatch_Gcid_CryptoId_WalletId_Amount, IX_SweepBatch_Status) |

---

## 1. Business Meaning

This table manages cryptocurrency "sweep" operations - the process of consolidating small balances from individual customer wallets into centralized omnibus wallets. Sweeping is a standard practice in crypto custody: when customer wallets hold small residual balances (dust), the platform periodically sweeps these into a pooled wallet to reduce on-chain management overhead and consolidate funds.

Without this table, operators would lack a way to track which wallets have been swept, in what amounts, and in which batch. The table enables batch-based processing where multiple wallets are grouped into numbered batches for sequential on-chain execution, with status tracking for each sweep entry.

The table has 29,315 rows with 99.99% in "Processed" status, indicating the sweep operations are mature and mostly completed. The dbo.BackupSweepBatch1_JUNK table is a backup copy of batch 1 data. A companion table dbo.tempSweepBatch appears to be a staging area for preparing new sweep batches.

---

## 2. Business Logic

### 2.1 Batch Processing Model

**What**: Wallets are grouped into numbered batches for sequential sweep processing.

**Columns/Parameters Involved**: `BatchNumber`, `Status`, `WalletID`, `Amount`

**Rules**:
- Wallets are assigned to a BatchNumber for grouped processing
- Each batch is processed sequentially on-chain to manage gas costs and transaction ordering
- Status tracks progress: NULL (not yet processed) -> "Processed" (sweep transaction confirmed)
- Indexed on GCID + CryptoID + WalletID + Amount for efficient deduplication and lookup

### 2.2 USD Valuation for Threshold Management

**What**: Each sweep entry records both the native crypto amount and USD equivalent for threshold-based decisions.

**Columns/Parameters Involved**: `Amount`, `AmountUSD`

**Rules**:
- Amount is the native cryptocurrency amount being swept
- AmountUSD is the USD equivalent at sweep time, used for minimum sweep thresholds
- Indexed on AmountUSD for efficient filtering of wallets above/below sweep thresholds

---

## 3. Data Overview

| Id | WalletID | CryptoID | GCID | Amount | AmountUSD | Status | BatchNumber | Meaning |
|---|----------|----------|------|--------|-----------|--------|-------------|---------|
| 567 | D0475977-... | 2 | 8238549 | 0.1 | 223.78 | Processed | 5 | ETH sweep of 0.1 ETH (~$224) from customer 8238549's wallet, completed in batch 5 |
| 568 | A83E7EEB-... | 2 | 14270979 | 0.1 | 223.78 | Processed | 5 | Another ETH sweep in the same batch - same amount suggests a batch threshold of 0.1 ETH |
| 569 | 0178CFFA-... | 2 | 10609111 | 0.1 | 223.78 | Processed | 5 | Third ETH sweep in batch 5 - identical amounts confirm systematic threshold-based sweeping |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletID | nvarchar(512) | YES | - | CODE-BACKED | Internal wallet identifier (GUID format). Identifies the customer wallet being swept. Larger nvarchar(512) accommodates various wallet ID formats. |
| 2 | PublicAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain public address of the wallet being swept. The on-chain address from which funds are consolidated to the omnibus wallet. |
| 3 | CryptoID | nvarchar(50) | NO | - | CODE-BACKED | Cryptocurrency identifier (stored as string). Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, etc. String type allows flexibility for identifiers. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The eToro customer whose wallet balance is being swept. |
| 5 | Amount | decimal(18,10) | NO | - | CODE-BACKED | Amount of cryptocurrency being swept from the customer wallet, in native crypto units. |
| 6 | AmountUSD | decimal(18,10) | NO | - | CODE-BACKED | USD equivalent of the swept amount at the time of sweep batch creation. Used for threshold decisions and reporting. Indexed for efficient filtering. |
| 7 | Status | nvarchar(100) | YES | - | CODE-BACKED | Processing status of this sweep entry. Values observed: "Processed" (sweep completed), NULL (pending processing). |
| 8 | BatchNumber | int | YES | - | CODE-BACKED | Batch group number for sequential processing. Multiple wallets are grouped into numbered batches to manage on-chain transaction ordering and gas optimization. |
| 9 | Id | int | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. Unique identifier for each sweep entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoID | Wallet.CryptoTypes | Implicit | Cryptocurrency being swept (1=BTC, 2=ETH, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.BackupSweepBatch1_JUNK | - | Backup | Backup copy of batch 1 data from this table |
| dbo.tempSweepBatch | - | Staging | Staging table for preparing new sweep batch entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT code. Sweep operations are likely managed by application code or ad-hoc scripts.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_AmountUSD | NONCLUSTERED | AmountUSD | - | - | Active |
| IX_SweepBatch_Gcid_CryptoId_WalletId_Amount | NONCLUSTERED | GCID, CryptoID, WalletID, Amount | - | - | Active (PAGE compressed) |
| IX_SweepBatch_Status | NONCLUSTERED | Status | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Sweep status summary
```sql
SELECT Status, COUNT(*) AS Cnt, SUM(AmountUSD) AS TotalUSD
FROM dbo.SweepBatch WITH (NOLOCK)
GROUP BY Status
```

### 8.2 Top sweeps by USD value for a specific crypto
```sql
SELECT TOP 10 Id, WalletID, GCID, Amount, AmountUSD, BatchNumber
FROM dbo.SweepBatch WITH (NOLOCK)
WHERE CryptoID = '2'
ORDER BY AmountUSD DESC
```

### 8.3 Batch summary with crypto names
```sql
SELECT sb.BatchNumber, ct.Name AS CryptoName,
       COUNT(*) AS WalletCount, SUM(sb.Amount) AS TotalCrypto, SUM(sb.AmountUSD) AS TotalUSD
FROM dbo.SweepBatch sb WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = CAST(sb.CryptoID AS INT)
GROUP BY sb.BatchNumber, ct.Name
ORDER BY sb.BatchNumber, TotalUSD DESC
```

---

## 9. Atlassian Knowledge Sources

Confluence search found a "Sweep Batch Queries" page but full content could not be retrieved. The page likely contains operational queries for monitoring sweep batch processing.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.SweepBatch | Type: Table | Source: WalletDB/dbo/Tables/dbo.SweepBatch.sql*
