# Wallet.GetWalletBalanceReport

> Legacy procedure that inserts wallet balances below the discrepancy threshold into FinanceReportsBalances and returns above-threshold records for downstream verification.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReportID + @Threshold parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetWalletBalanceReport is a legacy split-processing procedure for the original reconciliation system. It reads all wallet balances from the external table (Wallet.vu_GetWalletBalanceReport), applies the threshold check, and then splits the results: wallets BELOW the threshold are INSERT-ed directly into Wallet.FinanceReportsBalances (they're considered clean), while wallets ABOVE the threshold are returned as a result set for the application to process further (API verification against BitGo/Blox).

This procedure exists as an alternative ingestion path in the legacy pipeline. While Wallet.CreateNewReports inserts ALL records and classifies them with LevelId, this procedure performs the split at INSERT time -- only persisting clean records and leaving discrepant ones for the application to handle. It represents an older design pattern where the threshold check determined whether a record was even stored.

Key differences from Wallet.CreateNewReports: (1) applies ABS(TotalAmount) to TotalAmount (absolute value), (2) splits INSERT vs result-set by threshold rather than inserting all with LevelId classification, (3) does not create a run row or use transactions. The procedure also has an empty CATCH block, silently swallowing errors -- a legacy anti-pattern.

---

## 2. Business Logic

### 2.1 Split-Processing by Threshold

**What**: Separates wallet balances into "clean" (persisted) and "discrepant" (returned for processing) based on the threshold.

**Columns/Parameters Involved**: `@ReportID`, `@Threshold`, `TotalAmount`, `TotalBalance`

**Rules**:
- Reads all wallets from vu_GetWalletBalanceReport into #WalletBalanceReport with ABS(TotalAmount) applied
- **Below threshold**: `ABS(TotalAmount - TotalBalance) <= @Threshold` -- INSERT into FinanceReportsBalances with FindDiscrepancy=0, BitgoValue=0, BloxValue=0, no LevelId
- **Above threshold**: `ABS(TotalAmount - TotalBalance) > @Threshold` -- returned as a result set for the application to call BitGo/Blox APIs
- The ABS() on TotalAmount during the SELECT INTO means negative computed amounts are treated as positive for the threshold comparison
- No LevelId assignment for persisted records (unlike CreateNewReports which assigns LevelId=100)
- Empty CATCH block -- errors are silently swallowed, making debugging difficult

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReportID | bigint | NO | - | CODE-BACKED | The FinanceReports.Id for the current legacy run. All INSERT-ed records are tagged with this ReportId to link them to their parent run. |
| 2 | @Threshold | decimal(38,18) | NO | - | CODE-BACKED | Balance difference tolerance for the split decision. Wallets with ABS(TotalAmount - TotalBalance) <= @Threshold are persisted as clean; above @Threshold are returned for verification. |

**Output columns (above-threshold records only):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | WalletID (output) | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Global Customer ID -- wallet owner. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. |
| 6 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. |
| 7 | BitgoWalletId (output) | nvarchar(100) | YES | - | CODE-BACKED | BitGo custody wallet identifier. |
| 8 | TotalRecive (output) | decimal(38,18) | NO | - | CODE-BACKED | Total received amount (preserves the legacy typo from the external table). |
| 9 | TotalSend (output) | decimal(38,18) | NO | - | CODE-BACKED | Total sent amount. |
| 10 | TotalBalance (output) | decimal(38,18) | NO | - | CODE-BACKED | Blockchain net balance. |
| 11 | TotalAmount (output) | numeric(38,18) | YES | - | CODE-BACKED | eToro ledger's computed balance (ABS applied -- always non-negative). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT INTO) | Wallet.vu_GetWalletBalanceReport | READ | Reads all wallet balances from the external table |
| (INSERT) | Wallet.FinanceReportsBalances | WRITER | Inserts below-threshold records as clean |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Was called by the application layer in the legacy pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletBalanceReport (procedure)
+-- Wallet.vu_GetWalletBalanceReport (external table)
|   +-- RemoteReferenceData (external data source)
+-- Wallet.FinanceReportsBalances (table)
    +-- Wallet.FinanceReports (table) [implicit ref on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.vu_GetWalletBalanceReport | External Table | SELECT INTO #temp - reads all wallet balances |
| Wallet.FinanceReportsBalances | Table | INSERT - persists below-threshold clean records |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the legacy split-processing (historical reference)
```sql
EXEC Wallet.GetWalletBalanceReport @ReportID = 2141, @Threshold = 0;
-- Below-threshold records are INSERT-ed into FinanceReportsBalances
-- Above-threshold records are returned as a result set
```

### 8.2 Verify what was persisted vs returned
```sql
-- Count persisted records for a run
SELECT COUNT(*) AS PersistedCleanRecords
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = 2141 AND LevelId IS NULL;
```

### 8.3 Simulate the threshold split without executing
```sql
SELECT COUNT(*) AS TotalWallets,
       SUM(CASE WHEN ABS(ABS(TotalAmount) - TotalBalance) <= 0 THEN 1 ELSE 0 END) AS BelowThreshold,
       SUM(CASE WHEN ABS(ABS(TotalAmount) - TotalBalance) > 0 THEN 1 ELSE 0 END) AS AboveThreshold
INTO #ThresholdSplit
FROM Wallet.vu_GetWalletBalanceReport;
SELECT * FROM #ThresholdSplit;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletBalanceReport | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetWalletBalanceReport.sql*
