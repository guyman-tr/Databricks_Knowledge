# Wallet.vu_GetWalletBalanceReport

> External table providing a live read-through to WalletDB's wallet balance view, serving as the primary data source for crypto balance reconciliation runs.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | External Table |
| **Key Identifier** | Composite: WalletId + CryptoId (logical key) |
| **Partition** | N/A |
| **Indexes** | N/A (external tables do not support indexes) |

---

## 1. Business Meaning

Wallet.vu_GetWalletBalanceReport is an external table that provides a live, read-only window into WalletDB's wallet balance data hosted on a remote Azure SQL server (wallet-server-west). It exposes each wallet-crypto pair's send/receive totals, computed balance, and blockchain amount -- the raw numbers that the reconciliation engine compares against BitGo (custody) and Blox (portfolio tracker) to detect discrepancies.

This external table exists because the reconciliation engine runs in WalletBalancesReportDB, while the source wallet data lives in a separate WalletDB on a different server. Rather than replicating data or using linked servers with ad-hoc queries, the external table pattern provides a clean schema-bound abstraction that the reconciliation stored procedures can query as if it were a local table.

Data flows FROM the remote WalletDB INTO this database through this external table. It is consumed by four stored procedures: Wallet.CreateNewReportRun (current reconciliation), Wallet.CreateNewReports (legacy reconciliation), Wallet.GetFinanceSnapshot (point-in-time snapshot), and Wallet.GetWalletBalanceReport (legacy discrepancy detection). Each reads the full result set from the remote view and stages it into a local temp table for processing.

---

## 2. Business Logic

### 2.1 Remote Data Bridge for Reconciliation

**What**: A federated query gateway that abstracts the cross-server data access pattern for the reconciliation pipeline.

**Columns/Parameters Involved**: All columns -- this is a pass-through from the remote WalletDB view.

**Rules**:
- The external table uses DATA_SOURCE = [RemoteReferenceData] to connect to wallet-server-west
- Consuming procedures always SELECT INTO a local temp table first (e.g., `SELECT ... INTO #WalletBalanceReport FROM Wallet.vu_GetWalletBalanceReport`) because external tables do not support table hints (NOLOCK), indexes, or JOINs with local tables efficiently
- TotalBalance represents the blockchain-reported balance; TotalAmount represents the internally computed expected balance; the reconciliation engine compares these: `ABS(TotalAmount - TotalBalance) > @Threshold`
- The column `TotalRecive` (sic) contains a legacy typo -- it should be "TotalReceive" but the misspelling is preserved for backward compatibility with the remote view

**Diagram**:
```
WalletDB (wallet-server-west)
  |
  | vu_GetWalletBalanceReport (remote view)
  |     - Aggregates wallet transactions
  |     - Computes TotalBalance, TotalAmount
  |
  v [External Table bridge via RemoteReferenceData]
WalletBalancesReportDB
  |
  | Wallet.vu_GetWalletBalanceReport (external table)
  |
  +-> Wallet.CreateNewReportRun    (SELECT INTO #temp -> process)
  +-> Wallet.CreateNewReports      (SELECT INTO #temp -> process)
  +-> Wallet.GetFinanceSnapshot    (SELECT INTO #temp -> cross apply)
  +-> Wallet.GetWalletBalanceReport (SELECT INTO #temp -> threshold check)
```

---

## 3. Data Overview

N/A -- external table is not queryable from this environment (remote server wallet-server-west requires firewall access). Data represents one row per wallet-crypto pair with balance totals from WalletDB.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Unique identifier for the crypto wallet. Used as a JOIN key (with CryptoId) in reconciliation procedures to match against existing FinanceReportRecords. Each wallet belongs to one customer (Gcid). |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies which customer owns this wallet. Carried through into FinanceReportRecords and FinanceReportsBalances for customer-level reporting. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Identifies the cryptocurrency asset held in this wallet (e.g., Bitcoin, Ethereum). Together with WalletId, forms the logical composite key -- one row per wallet-crypto combination. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address associated with this wallet-crypto pair. Passed through to FinanceReportRecords.Address for traceability. NULL for wallets without a dedicated on-chain address. |
| 5 | BitgoWalletId | nvarchar(100) | YES | - | CODE-BACKED | BitGo custody platform's wallet identifier. Stored in reconciliation records to enable cross-referencing with BitGo's API when investigating discrepancies. Note: NOT NULL in the external table DDL but NULL in the consuming FinanceReportRecords. |
| 6 | TotalRecive | decimal(38,18) | NO | - | CODE-BACKED | Total amount received into this wallet-crypto pair across all transactions. Note: column name contains a legacy typo ("Recive" instead of "Receive") inherited from the remote WalletDB view. Mapped to TotalReceive in FinanceReportRecords and FinanceReportsBalances. |
| 7 | TotalSend | decimal(38,18) | NO | - | CODE-BACKED | Total amount sent from this wallet-crypto pair across all transactions. Together with TotalRecive, these represent the transaction-level activity for the wallet. |
| 8 | TotalBalance | decimal(38,18) | NO | - | CODE-BACKED | Net balance computed from blockchain transaction history (TotalRecive - TotalSend). This is the "on-chain truth" that gets compared against TotalAmount during reconciliation. Mapped to BloxBalance in FinanceReportRecords (confusingly named -- it represents the blockchain balance, not necessarily Blox's value). |
| 9 | TotalAmount | numeric(38,18) | YES | - | CODE-BACKED | Internally computed expected balance from the eToro ledger system. Compared against TotalBalance during reconciliation: if `ABS(TotalAmount - TotalBalance) > @Threshold`, the record is flagged with LevelId=100 (InitialDiscrepancy). Mapped to ComputedAmount in FinanceReportRecords. |
| 10 | LastSentOccurred | datetime2(7) | YES | - | NAME-INFERRED | Timestamp of the most recent send transaction for this wallet-crypto pair. Not directly used by any reconciliation procedure in the current codebase -- likely available for operational monitoring or debugging. |
| 11 | LastReceivedOccurred | datetime2(7) | YES | - | NAME-INFERRED | Timestamp of the most recent receive transaction for this wallet-crypto pair. Not directly used by any reconciliation procedure in the current codebase -- likely available for operational monitoring or debugging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | RemoteReferenceData (external data source) | External Data Source | Points to wallet-server-west Azure SQL server hosting WalletDB |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CreateNewReportRun | FROM clause | Read | Reads all wallet balances to create reconciliation records for the current system |
| Wallet.CreateNewReports | FROM clause | Read | Reads all wallet balances for the legacy reconciliation system |
| Wallet.GetFinanceSnapshot | FROM clause | Read | Reads wallet balances for point-in-time snapshot comparisons |
| Wallet.GetWalletBalanceReport | FROM clause | Read | Reads wallet balances for legacy threshold-based discrepancy detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no local dependencies. It connects to a remote data source.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RemoteReferenceData | External Data Source | Connection to wallet-server-west for cross-server queries |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CreateNewReportRun | Stored Procedure | SELECT INTO #temp for current reconciliation processing |
| Wallet.CreateNewReports | Stored Procedure | SELECT INTO #temp for legacy reconciliation processing |
| Wallet.GetFinanceSnapshot | Stored Procedure | SELECT INTO #temp for snapshot generation |
| Wallet.GetWalletBalanceReport | Stored Procedure | SELECT INTO #temp for legacy discrepancy checking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for External Table. External tables do not support local indexes. Consuming procedures create indexes on temp tables after staging the data locally.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOT NULL on WalletId, Gcid, CryptoId, TotalRecive, TotalSend, TotalBalance | Column constraint | Core identification and balance columns are mandatory from the remote source |

---

## 8. Sample Queries

### 8.1 Read wallet balances into a temp table (as procedures do)
```sql
SELECT WalletId, Gcid, CryptoId, Address, BitgoWalletId,
       TotalRecive, TotalSend, TotalBalance, TotalAmount
INTO #WalletBalanceReport
FROM Wallet.vu_GetWalletBalanceReport;
-- Note: NOLOCK is not supported on external tables
```

### 8.2 Find wallets with balance discrepancies above a threshold
```sql
SELECT WalletId, Gcid, CryptoId, TotalBalance, TotalAmount,
       ABS(TotalAmount - TotalBalance) AS Discrepancy
INTO #Discrepancies
FROM Wallet.vu_GetWalletBalanceReport
WHERE ABS(TotalAmount - TotalBalance) > 0.00000001;

SELECT * FROM #Discrepancies ORDER BY Discrepancy DESC;
```

### 8.3 Count wallets by crypto asset
```sql
SELECT CryptoId, COUNT(*) AS WalletCount
INTO #CryptoCounts
FROM Wallet.vu_GetWalletBalanceReport
GROUP BY CryptoId;

SELECT * FROM #CryptoCounts ORDER BY WalletCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.8/10 (Elements: 8.2/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReport | Type: External Table | Source: WalletBalancesReportDB/Wallet/External Tables/Wallet.vu_GetWalletBalanceReport.sql*
