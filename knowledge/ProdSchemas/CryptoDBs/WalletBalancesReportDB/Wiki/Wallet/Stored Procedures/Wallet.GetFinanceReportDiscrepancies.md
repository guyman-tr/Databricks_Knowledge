# Wallet.GetFinanceReportDiscrepancies

> Retrieves wallet-crypto pairs flagged as initial discrepancies (LevelId=100) from a specific legacy reconciliation run for downstream verification processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReportId + @Limit parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetFinanceReportDiscrepancies retrieves wallet-crypto pairs that need verification from a specific legacy reconciliation run. It reads from Wallet.FinanceReportsBalances and returns only records where LevelId = 100 (InitialDiscrepancy) -- wallets whose balance difference exceeded the threshold during the preliminary classification in Wallet.CreateNewReports. The application then uses this list to call BitGo and Blox APIs for each wallet to determine the actual discrepancy classification.

This procedure exists as the "work queue" retrieval step in the legacy reconciliation pipeline. After Wallet.CreateNewReports inserts all records with preliminary classification, this procedure extracts the subset that needs API verification. Only records with LevelId=100 are returned -- records where balances matched (LevelId=NULL) are considered clean and skip verification.

This is the legacy-system counterpart to Wallet.GetFinanceReportRunDiscrepancies (which reads from Wallet.FinanceReportRecords instead). The output schema is nearly identical, including the aliased columns (BloxBalance as TotalBalance, BitgoWalletId as ProviderWalletId). The @Limit parameter (default 100,000) caps the result set for memory-safe batch processing.

---

## 2. Business Logic

### 2.1 Discrepancy Work Queue Extraction

**What**: Filters reconciliation records to only those requiring API verification (preliminary discrepancies).

**Columns/Parameters Involved**: `@ReportId`, `@Limit`, `LevelId`

**Rules**:
- Reads from Wallet.FinanceReportsBalances WHERE LevelId = 100 (InitialDiscrepancy)
- Stages data into a temp table #FinanceReportsBalances first, then selects from it with OPTION (RECOMPILE)
- Returns the WalletId aliased as both "WalletId" and "Id" for backward compatibility with different consumers
- Returns BitgoWalletId aliased as both itself and "ProviderWalletId" (generic alias for the custody provider)
- Returns BloxBalance aliased as "TotalBalance" (the blockchain-reported balance)
- The @Limit parameter (default 100,000) prevents excessive memory usage when processing very large runs
- The OPTION (RECOMPILE) hint forces a fresh execution plan based on the actual @Limit value, avoiding parameter sniffing issues

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReportId | bigint | NO | - | CODE-BACKED | The FinanceReports.Id identifying which legacy run's discrepancies to retrieve. Must reference an existing run created by Wallet.CreateNewReports. |
| 2 | @Limit | int | YES | 100000 | CODE-BACKED | Maximum number of discrepancy records to return. Default 100,000 provides a safety cap for memory-safe batch processing. Used as TOP (@Limit) in the final SELECT. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet GUID aliased as "Id" for backward compatibility. Same value as WalletID. |
| 4 | WalletID (output) | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier. |
| 5 | Gcid (output) | bigint | NO | - | CODE-BACKED | Global Customer ID -- wallet owner. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. |
| 7 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. |
| 8 | BitgoWalletId (output) | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody wallet identifier. |
| 9 | ProviderWalletId (output) | nvarchar(100) | NO | - | CODE-BACKED | Alias of BitgoWalletId -- generic name for the custody provider's wallet ID. |
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
| @ReportId | Wallet.FinanceReportsBalances | SELECT | Reads discrepancy records for the specified legacy run |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer to retrieve the work queue for API verification.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFinanceReportDiscrepancies (procedure)
+-- Wallet.FinanceReportsBalances (table)
    +-- Wallet.FinanceReports (table) [implicit ref on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportsBalances | Table | SELECT WHERE LevelId = 100 - reads initial discrepancies for API verification |

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

### 8.1 Get discrepancies for the last legacy run
```sql
EXEC Wallet.GetFinanceReportDiscrepancies @ReportId = 2141;
```

### 8.2 Get a limited batch of discrepancies
```sql
EXEC Wallet.GetFinanceReportDiscrepancies @ReportId = 2141, @Limit = 1000;
```

### 8.3 Count legacy discrepancies by run
```sql
SELECT ReportId, COUNT(*) AS DiscrepancyCount
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
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
*Object: Wallet.GetFinanceReportDiscrepancies | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetFinanceReportDiscrepancies.sql*
