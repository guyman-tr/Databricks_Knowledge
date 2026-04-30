# dbo.BackupSweepBatch1_JUNK

> Backup copy of sweep batch data, preserved as a safety net before a sweep operation or cleanup - marked as JUNK for eventual deletion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

This table is a backup snapshot of the `dbo.SweepBatch` table's data (Batch 1), created before executing a sweep operation or data cleanup. The `_JUNK` suffix indicates it was intended for eventual deletion after confirming the sweep completed successfully. It preserves the original wallet IDs, addresses, crypto IDs, customer GCIDs, amounts, and batch assignments at the time of backup.

Without this table, there would be no rollback reference if the sweep operation encountered issues. However, as a JUNK-suffixed table with no code references, it has no ongoing operational role and exists purely as a historical safety net.

No stored procedures, views, or functions reference this table. Data was inserted via ad-hoc backup script.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Id | WalletID | CryptoID | GCID | Amount | AmountUSD | Status | BatchNumber | Meaning |
|---|----------|----------|------|--------|-----------|--------|-------------|---------|
| (sample from SweepBatch structure) | GUID | 2 | 8238549 | 0.1 | 223.78 | Processed | 5 | Backup of a processed ETH sweep for a customer, recording the amount swept and its USD equivalent |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletID | nvarchar(50) | NO | - | CODE-BACKED | Internal wallet identifier (GUID format). Identifies which customer wallet was included in the sweep batch. |
| 2 | PublicAddress | nvarchar(100) | NO | - | CODE-BACKED | Blockchain public address of the wallet being swept. The on-chain address from which funds are consolidated. |
| 3 | CryptoID | nvarchar(50) | NO | - | CODE-BACKED | Cryptocurrency identifier (stored as string in this backup). Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, etc. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The eToro customer who owns the wallet being swept. |
| 5 | Amount | decimal(18,10) | NO | - | CODE-BACKED | Amount of cryptocurrency swept from the wallet, in native crypto units. |
| 6 | AmountUSD | decimal(18,10) | NO | - | CODE-BACKED | USD equivalent of the swept amount at the time of the sweep. Used for threshold checks and reporting. |
| 7 | Status | nvarchar(100) | YES | - | CODE-BACKED | Processing status of this sweep entry (e.g., "Processed"). Tracks whether the sweep transaction has been executed on-chain. |
| 8 | BatchNumber | int | YES | - | CODE-BACKED | Sweep batch group number. Multiple wallets are grouped into numbered batches for sequential processing. |
| 9 | Id | int | NO | IDENTITY | CODE-BACKED | Auto-incrementing row identifier. Surrogate key for the backup record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Count records by status
```sql
SELECT Status, COUNT(*) AS Cnt
FROM dbo.BackupSweepBatch1_JUNK WITH (NOLOCK)
GROUP BY Status
```

### 8.2 Total swept amount per crypto
```sql
SELECT CryptoID, SUM(Amount) AS TotalSwept, SUM(AmountUSD) AS TotalUSD
FROM dbo.BackupSweepBatch1_JUNK WITH (NOLOCK)
GROUP BY CryptoID
ORDER BY TotalUSD DESC
```

### 8.3 Compare backup against current SweepBatch
```sql
SELECT b.Id, b.WalletID, b.Amount AS BackupAmount, s.Amount AS CurrentAmount
FROM dbo.BackupSweepBatch1_JUNK b WITH (NOLOCK)
LEFT JOIN dbo.SweepBatch s WITH (NOLOCK) ON b.WalletID = s.WalletID AND b.CryptoID = s.CryptoID
WHERE b.Amount <> ISNULL(s.Amount, 0)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.BackupSweepBatch1_JUNK | Type: Table | Source: WalletDB/dbo/Tables/dbo.BackupSweepBatch1_JUNK.sql*
