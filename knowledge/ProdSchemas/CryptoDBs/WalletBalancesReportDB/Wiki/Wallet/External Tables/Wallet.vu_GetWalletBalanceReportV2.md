# Wallet.vu_GetWalletBalanceReportV2

> Version 2 external table providing a live read-through to WalletDB's wallet balance view. Structurally identical to vu_GetWalletBalanceReport but not yet consumed by any stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | External Table |
| **Key Identifier** | Composite: WalletId + CryptoId (logical key) |
| **Partition** | N/A |
| **Indexes** | N/A (external tables do not support indexes) |

---

## 1. Business Meaning

Wallet.vu_GetWalletBalanceReportV2 is a version 2 external table that mirrors the exact same structure and remote data source as Wallet.vu_GetWalletBalanceReport. Both point to DATA_SOURCE = [RemoteReferenceData] on wallet-server-west and expose the same 11 columns representing wallet-crypto balance data from WalletDB.

This V2 table was likely created as a staging artifact for a planned migration or version upgrade of the remote view on WalletDB. The remote view may have been updated (e.g., bug fixes, additional logic) and the V2 external table was provisioned to point to the new version while the original remained in use. Alternatively, it may be reserved for a future procedure migration.

Currently, no stored procedures, views, or functions in the WalletBalancesReportDB codebase reference this table. All four reconciliation procedures continue to use the original Wallet.vu_GetWalletBalanceReport.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is an unused V2 copy of Wallet.vu_GetWalletBalanceReport. See that object's documentation for full business logic details.

---

## 3. Data Overview

N/A -- external table is not queryable from this environment (remote server wallet-server-west requires firewall access). Would return the same data as Wallet.vu_GetWalletBalanceReport if accessible.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Unique identifier for the crypto wallet. Same as vu_GetWalletBalanceReport.WalletId. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies the wallet owner. Same as vu_GetWalletBalanceReport.Gcid. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. Together with WalletId, forms the logical composite key. Same as vu_GetWalletBalanceReport.CryptoId. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. Same as vu_GetWalletBalanceReport.Address. |
| 5 | BitgoWalletId | nvarchar(100) | YES | - | CODE-BACKED | BitGo custody platform's wallet identifier. Same as vu_GetWalletBalanceReport.BitgoWalletId. |
| 6 | TotalRecive | decimal(38,18) | NO | - | CODE-BACKED | Total received amount (legacy typo preserved). Same as vu_GetWalletBalanceReport.TotalRecive. |
| 7 | TotalSend | decimal(38,18) | NO | - | CODE-BACKED | Total sent amount. Same as vu_GetWalletBalanceReport.TotalSend. |
| 8 | TotalBalance | decimal(38,18) | NO | - | CODE-BACKED | Blockchain-reported net balance. Same as vu_GetWalletBalanceReport.TotalBalance. |
| 9 | TotalAmount | numeric(38,18) | YES | - | CODE-BACKED | Internally computed expected balance from eToro ledger. Same as vu_GetWalletBalanceReport.TotalAmount. |
| 10 | LastSentOccurred | datetime2(7) | YES | - | NAME-INFERRED | Timestamp of most recent send transaction. Same as vu_GetWalletBalanceReport.LastSentOccurred. |
| 11 | LastReceivedOccurred | datetime2(7) | YES | - | NAME-INFERRED | Timestamp of most recent receive transaction. Same as vu_GetWalletBalanceReport.LastReceivedOccurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | RemoteReferenceData (external data source) | External Data Source | Points to wallet-server-west Azure SQL server hosting WalletDB |

### 5.2 Referenced By (other objects point to this)

No objects in the current codebase reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no local dependencies. It connects to a remote data source.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RemoteReferenceData | External Data Source | Connection to wallet-server-west for cross-server queries |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for External Table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOT NULL on WalletId, Gcid, CryptoId, TotalRecive, TotalSend, TotalBalance | Column constraint | Core identification and balance columns are mandatory from the remote source |

---

## 8. Sample Queries

### 8.1 Basic read (no table hints allowed)
```sql
SELECT TOP 5 WalletId, Gcid, CryptoId, TotalBalance, TotalAmount
FROM Wallet.vu_GetWalletBalanceReportV2;
```

### 8.2 Compare V1 and V2 row counts
```sql
SELECT 'V1' AS Version, COUNT(*) AS RowCount
INTO #Comparison
FROM Wallet.vu_GetWalletBalanceReport;

INSERT INTO #Comparison
SELECT 'V2', COUNT(*) FROM Wallet.vu_GetWalletBalanceReportV2;

SELECT * FROM #Comparison;
```

### 8.3 Check for differences between V1 and V2
```sql
SELECT v1.WalletId, v1.CryptoId, v1.TotalBalance AS V1Balance, v2.TotalBalance AS V2Balance
INTO #Diffs
FROM Wallet.vu_GetWalletBalanceReport v1
FULL OUTER JOIN Wallet.vu_GetWalletBalanceReportV2 v2
    ON v1.WalletId = v2.WalletId AND v1.CryptoId = v2.CryptoId
WHERE v1.TotalBalance <> v2.TotalBalance OR v1.WalletId IS NULL OR v2.WalletId IS NULL;

SELECT * FROM #Diffs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.0/10 (Elements: 8.2/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReportV2 | Type: External Table | Source: WalletBalancesReportDB/Wallet/External Tables/Wallet.vu_GetWalletBalanceReportV2.sql*
