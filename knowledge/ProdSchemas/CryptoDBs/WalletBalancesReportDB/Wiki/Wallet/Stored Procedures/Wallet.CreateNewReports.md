# Wallet.CreateNewReports

> Legacy orchestrator that creates a reconciliation run and bulk-inserts all wallet-crypto balance records into FinanceReportsBalances for discrepancy detection.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id, StartTime, EndTime of the newly created legacy run |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.CreateNewReports was the primary orchestrator for the legacy crypto wallet balance reconciliation pipeline. It reads all wallet balances from the external table (Wallet.vu_GetWalletBalanceReport), creates a parent run row in Wallet.FinanceReports, and bulk-inserts one Wallet.FinanceReportsBalances row per wallet-crypto pair with preliminary discrepancy classification.

This procedure existed as the legacy entry point for reconciliation before being replaced by Wallet.CreateNewReportRun in October 2024. The key differences from its successor are: it uses Wallet.FinanceReports (not FinanceReportRuns) as the run table, it writes to Wallet.FinanceReportsBalances (not FinanceReportRecords), it has NO incremental processing (always processes all wallets), and it does NOT record execution parameters.

Data was created by this procedure from April 2019 through December 2024. The procedure ran daily, producing runs that grew from ~18 minutes (2019) to ~2 hours (2024) as the wallet count increased -- a scalability problem that the incremental processing in Wallet.CreateNewReportRun solved.

---

## 2. Business Logic

### 2.1 Full-Scan Reconciliation (No Incremental Filtering)

**What**: Processes all wallet-crypto pairs on every run -- no change detection or skipping.

**Columns/Parameters Involved**: `@Threshold`

**Rules**:
- Every run reads ALL wallet balances from the external table into #WalletBalanceReport
- ALL wallets are inserted into FinanceReportsBalances regardless of whether balances changed since the last run
- This caused run times to grow linearly with wallet count, eventually reaching ~2 hours
- Replaced by Wallet.CreateNewReportRun's incremental processing which reduced run times to seconds

### 2.2 Preliminary Discrepancy Classification

**What**: Same threshold-based classification as the current system.

**Columns/Parameters Involved**: `@Threshold`, `LevelId`, `TotalAmount`, `TotalBalance`

**Rules**:
- LevelId = 100 (InitialDiscrepancy) if `ABS(TotalAmount - TotalBalance) > @Threshold` OR `TotalAmount < 0` OR `TotalBalance < 0`
- LevelId = NULL if balances are within threshold and both are non-negative
- FindDiscrepancy = 0, BitgoValue = 0, BloxValue = 0 for all records (actual values come from subsequent UpdateReportRecord calls)
- Identical logic to Wallet.CreateNewReportRun Section 2.2

### 2.3 Transactional Legacy Run Creation

**What**: Creates the legacy run row and all child records atomically.

**Columns/Parameters Involved**: `FinanceReports`, `FinanceReportsBalances`

**Rules**:
- Uses BEGIN TRAN / COMMIT for atomicity
- Inserts into Wallet.FinanceReports with StartTime = GETUTCDATE() (no Parameters column exists)
- Captures the new run Id via OUTPUT INTO @Report table variable
- On error, ROLLBACK and RAISERROR with full context
- Returns the @Report row to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Threshold | decimal(38,18) | NO | - | CODE-BACKED | Balance difference tolerance for preliminary discrepancy flagging. If ABS(TotalAmount - TotalBalance) > @Threshold, the record gets LevelId=100. Same threshold logic as Wallet.CreateNewReportRun. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT INTO) | Wallet.vu_GetWalletBalanceReport | READ | Reads all wallet balances from the external table (remote WalletDB) |
| (INSERT) | Wallet.FinanceReports | WRITER | Creates the parent legacy run row with StartTime |
| (INSERT) | Wallet.FinanceReportsBalances | WRITER | Bulk-inserts one record per wallet-crypto pair with preliminary classification |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Was called by the application layer. No longer actively used since December 2024.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CreateNewReports (procedure)
+-- Wallet.vu_GetWalletBalanceReport (external table)
|   +-- RemoteReferenceData (external data source)
+-- Wallet.FinanceReports (table)
+-- Wallet.FinanceReportsBalances (table)
    +-- Wallet.FinanceReports (table) [implicit ref on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.vu_GetWalletBalanceReport | External Table | SELECT INTO #temp - reads all wallet balances from remote WalletDB |
| Wallet.FinanceReports | Table | INSERT - creates parent legacy run row |
| Wallet.FinanceReportsBalances | Table | INSERT - bulk-inserts wallet-crypto reconciliation records |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. The application called Wallet.UpdateReportRecord and Wallet.UpdateReports after this procedure completed.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute a legacy reconciliation run (historical reference)
```sql
EXEC Wallet.CreateNewReports @Threshold = 0;
-- Returns: Id, StartTime, EndTime (NULL) of the new legacy run
```

### 8.2 Count records in the last legacy run
```sql
SELECT COUNT(*) AS TotalRecords,
       SUM(CASE WHEN LevelId = 100 THEN 1 ELSE 0 END) AS InitialDiscrepancies,
       SUM(CASE WHEN LevelId IS NULL THEN 1 ELSE 0 END) AS CleanRecords
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = (SELECT MAX(Id) FROM Wallet.FinanceReports WITH (NOLOCK));
```

### 8.3 Compare legacy vs current run record counts
```sql
SELECT 'Legacy' AS System, COUNT(*) AS RecordCount
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = (SELECT MAX(Id) FROM Wallet.FinanceReports WITH (NOLOCK))
UNION ALL
SELECT 'Current', COUNT(*)
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE ReportId = (SELECT MAX(Id) FROM Wallet.FinanceReportRuns WITH (NOLOCK));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CreateNewReports | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.CreateNewReports.sql*
