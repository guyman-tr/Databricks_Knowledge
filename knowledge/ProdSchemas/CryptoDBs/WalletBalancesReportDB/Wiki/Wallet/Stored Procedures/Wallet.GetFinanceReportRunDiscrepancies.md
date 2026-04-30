# Wallet.GetFinanceReportRunDiscrepancies

> Retrieves wallet-crypto pairs flagged as initial discrepancies (LevelId=100) from a specific current-system reconciliation run for downstream API verification.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReportId + @Limit parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetFinanceReportRunDiscrepancies retrieves wallet-crypto pairs that need verification from a specific reconciliation run in the current system. It reads from Wallet.FinanceReportRecords and returns only records where LevelId = 100 (InitialDiscrepancy) -- wallets whose balance difference exceeded the threshold during preliminary classification in Wallet.CreateNewReportRun. The application then uses this list to call BitGo and Blox APIs for each wallet to determine the actual discrepancy classification.

This procedure exists as the "work queue" retrieval step in the current reconciliation pipeline. After Wallet.CreateNewReportRun inserts records with preliminary classification, this procedure extracts the subset requiring API verification. It is the current-system counterpart to Wallet.GetFinanceReportDiscrepancies (which reads from the legacy Wallet.FinanceReportsBalances instead).

The output schema is nearly identical to its legacy counterpart, including the aliased columns (BloxBalance as TotalBalance, BitgoWalletId as ProviderWalletId). The results are ordered by CryptoId for deterministic processing order. The @Limit parameter (default 100,000) caps the result set.

---

## 2. Business Logic

### 2.1 Current-System Discrepancy Work Queue

**What**: Filters current reconciliation records to only those requiring API verification.

**Columns/Parameters Involved**: `@ReportId`, `@Limit`, `LevelId`

**Rules**:
- Reads from Wallet.FinanceReportRecords WHERE LevelId = 100 (InitialDiscrepancy)
- Stages data into #FinanceReportRecords temp table first, then selects with OPTION (RECOMPILE)
- Results are ORDER BY CryptoId (vs no explicit ordering in the legacy counterpart) for consistent processing
- Returns the same aliased columns as GetFinanceReportDiscrepancies for API compatibility
- The OPTION (RECOMPILE) hint avoids parameter sniffing issues with the variable @Limit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReportId | bigint | NO | - | CODE-BACKED | The FinanceReportRuns.Id identifying which run's discrepancies to retrieve. Must reference an existing run created by Wallet.CreateNewReportRun. |
| 2 | @Limit | int | YES | 100000 | CODE-BACKED | Maximum number of discrepancy records to return. Default 100,000. Used as TOP (@Limit) in the final SELECT. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet GUID aliased as "Id" for backward compatibility. Same value as WalletID. |
| 4 | WalletID (output) | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier. |
| 5 | Gcid (output) | bigint | NO | - | CODE-BACKED | Global Customer ID -- wallet owner. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. Results ordered by this column. |
| 7 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. |
| 8 | BitgoWalletId (output) | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody wallet identifier. |
| 9 | ProviderWalletId (output) | nvarchar(100) | NO | - | CODE-BACKED | Alias of BitgoWalletId -- generic custody provider wallet ID. |
| 10 | TotalReceive (output) | decimal(38,18) | YES | - | CODE-BACKED | Total received amount from blockchain data. |
| 11 | TotalSend (output) | decimal(38,18) | YES | - | CODE-BACKED | Total sent amount from blockchain data. |
| 12 | TotalBalance (output) | decimal(38,18) | YES | - | CODE-BACKED | Blockchain net balance (alias of BloxBalance column). |
| 13 | ComputedAmount (output) | decimal(38,18) | YES | - | CODE-BACKED | eToro ledger's expected balance. |
| 14 | Retries (output) | tinyint | YES | - | CODE-BACKED | Number of re-verification attempts for this wallet-crypto pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReportId | Wallet.FinanceReportRecords | SELECT | Reads discrepancy records for the specified current-system run |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer to retrieve the work queue for API verification.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFinanceReportRunDiscrepancies (procedure)
+-- Wallet.FinanceReportRecords (table)
    +-- Wallet.FinanceReportRuns (table) [FK on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRecords | Table | SELECT WHERE LevelId = 100 - reads initial discrepancies for API verification |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called directly by the application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get discrepancies for the latest run
```sql
DECLARE @LatestRun BIGINT = (SELECT MAX(Id) FROM Wallet.FinanceReportRuns WITH (NOLOCK));
EXEC Wallet.GetFinanceReportRunDiscrepancies @ReportId = @LatestRun;
```

### 8.2 Get a limited batch
```sql
EXEC Wallet.GetFinanceReportRunDiscrepancies @ReportId = 622, @Limit = 500;
```

### 8.3 Count current discrepancies by run
```sql
SELECT TOP 10 ReportId, COUNT(*) AS DiscrepancyCount
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE LevelId = 100
GROUP BY ReportId
ORDER BY ReportId DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFinanceReportRunDiscrepancies | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetFinanceReportRunDiscrepancies.sql*
