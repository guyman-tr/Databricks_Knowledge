# Wallet.CreateNewReportRun

> Orchestrates a new reconciliation run in the current system: reads wallet balances from the external table, applies incremental filtering, creates a run record, inserts preliminary reconciliation records, and returns the run ID for downstream processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id, StartTime, EndTime of the newly created run |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.CreateNewReportRun is the primary orchestrator for the current crypto wallet balance reconciliation pipeline. When called (typically twice daily at ~02:00 UTC), it pulls all wallet-crypto balances from the external table (Wallet.vu_GetWalletBalanceReport, bridging to WalletDB), optionally filters out unchanged wallets (incremental mode), creates a parent run row in Wallet.FinanceReportRuns, and bulk-inserts one Wallet.FinanceReportRecords row per wallet-crypto pair with preliminary discrepancy classification.

This procedure exists as the entry point for the entire reconciliation pipeline. It creates the run context (FinanceReportRuns row) and the preliminary data (FinanceReportRecords rows) that the application then processes. After this procedure completes, the application calls external APIs (BitGo, Blox) to verify each discrepancy, then calls Wallet.UpdateReportRecords with the verified results, and finally calls Wallet.UpdateReportRun to stamp the EndTime.

This is the current-system replacement for the legacy Wallet.CreateNewReports. The key improvement is incremental processing: when @ProcessAllRecords = 0 (default), it compares each wallet's current balances against its most recent FinanceReportRecords entry and skips wallets where nothing changed (and the last check was within @RetryDays). This dramatically reduced run times from hours to seconds.

---

## 2. Business Logic

### 2.1 Incremental Processing (Smart Filtering)

**What**: Skips wallet-crypto pairs whose balances haven't changed since the last reconciliation check, reducing run times from hours to seconds.

**Columns/Parameters Involved**: `@ProcessAllRecords`, `@RetryDays`, `@Threshold`

**Rules**:
- When @ProcessAllRecords = 0 (default): for each wallet-crypto pair, finds the latest FinanceReportRecords row (via CROSS APPLY ORDER BY Created DESC) and compares TotalReceive, TotalSend, BloxBalance, and ComputedAmount
- If all four values match AND the record's LastChecked is within @RetryDays of now, the wallet is removed from the processing set (deleted from #WalletBalanceReport temp table)
- When @ProcessAllRecords = 1: no filtering -- all wallets are processed regardless of change status
- The @RetryDays parameter (default 2) controls how long to wait before rechecking an unchanged wallet, ensuring even stable wallets get periodic verification
- The comparison uses `DATEDIFF(DAY, ISNULL(LastChecked, '2000-01-01'), GETUTCDATE()) >= @RetryDays` -- the ISNULL fallback ensures records never checked (LastChecked = NULL) are always reprocessed

**Diagram**:
```
External Table (all wallets)
       |
       | SELECT INTO #WalletBalanceReport
       v
  Full wallet set
       |
       | @ProcessAllRecords = 0?
       |     YES: Keep all
       |     NO:  CROSS APPLY latest FinanceReportRecords
       |           |
       |           | All 4 balance values match?
       |           | AND LastChecked within @RetryDays?
       |           |     YES: DELETE from #temp (skip this wallet)
       |           |     NO:  Keep (reprocess)
       v
  Filtered wallet set --> INSERT into FinanceReportRecords
```

### 2.2 Preliminary Discrepancy Classification

**What**: Assigns an initial LevelId based on balance threshold comparison before the application performs API verification.

**Columns/Parameters Involved**: `@Threshold`, `LevelId`, `TotalAmount`, `TotalBalance`

**Rules**:
- LevelId = 100 (InitialDiscrepancy) if `ABS(TotalAmount - TotalBalance) > @Threshold` OR `TotalAmount < 0` OR `TotalBalance < 0`
- LevelId = NULL if balances are within threshold and both are non-negative
- @Threshold is currently always 0 in production, meaning ANY difference triggers classification
- FindDiscrepancy is always set to 0, BitgoValue to 0, BloxValue to 0 -- actual values come from Wallet.UpdateReportRecords after API verification
- Negative balances are always flagged regardless of threshold, as they indicate a data integrity issue

### 2.3 Transactional Run Creation

**What**: Creates the run row and all child records in a single transaction, ensuring atomicity.

**Columns/Parameters Involved**: `FinanceReportRuns`, `FinanceReportRecords`, `@Report table variable`

**Rules**:
- Uses BEGIN TRAN / COMMIT to ensure the run row and all child records are created atomically
- The run's Parameters are serialized as JSON using FOR JSON PATH: {"Threshold": X, "ProcessAllRecords": Y, "RetryDays": Z}
- The new run Id is captured via OUTPUT INTO @Report table variable
- On error, ROLLBACK TRANSACTION undoes all inserts and RAISERROR propagates the error with full context (message, number, severity, state, procedure, line)
- The procedure returns the @Report row (Id, StartTime, EndTime=NULL) to the caller for use in subsequent processing steps

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Threshold | decimal(38,18) | NO | - | CODE-BACKED | Balance difference tolerance for preliminary discrepancy flagging. If ABS(TotalAmount - TotalBalance) > @Threshold, the record gets LevelId=100 (InitialDiscrepancy). Production value is always 0, meaning any non-zero difference is flagged. |
| 2 | @ProcessAllRecords | bit | YES | 0 | CODE-BACKED | Controls incremental vs full processing mode. 0 (default) = skip unchanged wallets (incremental mode, ~22 seconds); 1 = reprocess all wallets regardless of change status (full mode, could take minutes). The JSON-serialized value is stored in FinanceReportRuns.Parameters for Wallet.UpdateReportRecords to read at runtime. |
| 3 | @RetryDays | int | YES | 2 | CODE-BACKED | Number of days to wait before rechecking an unchanged wallet-crypto pair. Used in the incremental filter: DATEDIFF(DAY, LastChecked, GETUTCDATE()) >= @RetryDays. Default of 2 means even stable wallets are reverified every other day. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT INTO) | Wallet.vu_GetWalletBalanceReport | READ | Reads all wallet balances from the external table (remote WalletDB) |
| (CROSS APPLY) | Wallet.FinanceReportRecords | READ | Reads latest record per wallet for incremental comparison |
| (INSERT) | Wallet.FinanceReportRuns | WRITER | Creates the parent run row with StartTime and Parameters |
| (INSERT) | Wallet.FinanceReportRecords | WRITER | Bulk-inserts one record per wallet-crypto pair with preliminary discrepancy classification |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer to initiate reconciliation runs (typically twice daily at ~02:00 UTC).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CreateNewReportRun (procedure)
+-- Wallet.vu_GetWalletBalanceReport (external table)
|   +-- RemoteReferenceData (external data source)
+-- Wallet.FinanceReportRuns (table)
+-- Wallet.FinanceReportRecords (table)
    +-- Wallet.FinanceReportRuns (table) [FK on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.vu_GetWalletBalanceReport | External Table | SELECT INTO #temp - reads all wallet balances from remote WalletDB |
| Wallet.FinanceReportRuns | Table | INSERT - creates parent run row; also implicitly referenced via FK on child records |
| Wallet.FinanceReportRecords | Table | CROSS APPLY (read latest) + INSERT (create new records) |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. The application calls Wallet.UpdateReportRecords and Wallet.UpdateReportRun after this procedure completes.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute a standard incremental reconciliation run
```sql
EXEC Wallet.CreateNewReportRun @Threshold = 0, @ProcessAllRecords = 0, @RetryDays = 2;
-- Returns: Id, StartTime, EndTime (NULL) of the new run
```

### 8.2 Execute a full reprocessing run
```sql
EXEC Wallet.CreateNewReportRun @Threshold = 0, @ProcessAllRecords = 1, @RetryDays = 1;
-- All wallets will be included regardless of change status
```

### 8.3 Verify the records created by the latest run
```sql
DECLARE @LatestRun BIGINT = (SELECT MAX(Id) FROM Wallet.FinanceReportRuns WITH (NOLOCK));

SELECT COUNT(*) AS TotalRecords,
       SUM(CASE WHEN LevelId = 100 THEN 1 ELSE 0 END) AS InitialDiscrepancies,
       SUM(CASE WHEN LevelId IS NULL THEN 1 ELSE 0 END) AS CleanRecords
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE ReportId = @LatestRun;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CreateNewReportRun | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.CreateNewReportRun.sql*
