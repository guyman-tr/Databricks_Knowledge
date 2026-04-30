# BackOffice.UpsertIntoAggregationTables

> Scheduled-job orchestrator that loops over History.ActiveCredit in 8,000-row batches, calling UpsertIntoAggregationTablesAction for each slice until the aggregation high-water mark is fully caught up.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - reads and advances state from Dictionary.AggregationLastValue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpsertIntoAggregationTables` is the **scheduled-job entry point** for eToro's customer financial aggregation pipeline. It runs as a top-level job (no parameters, no caller SP) and is responsible for driving incremental aggregation of all financial and login activity into three customer summary tables that power back-office reporting, Salesforce triggers, and the eToro Club/VIP customer segmentation system.

This procedure is purely an **orchestrator**: it reads the current high-water mark (last processed CreditID, last processed login timestamp) from `Dictionary.AggregationLastValue`, determines how many new credit events exist in `History.ActiveCredit`, and then calls `BackOffice.UpsertIntoAggregationTablesAction` in a batched loop - processing at most 8,000 CreditIDs per iteration - until all new events are consumed.

Without this procedure, the three aggregation tables (`CustomerAllTimeAggregatedData_1`, `CustomerDTDAggregatedData_1`, `CustomerMTDAggregatedData_1`) would go stale. Every back-office KPI, Salesforce customer update, and Club status evaluation depends on these tables being kept near-real-time.

**Historical evolution (from DDL comments)**:
- 2018 (ticket 50280): Moved to secondary DB; introduced synonyms for cross-DB access to primary DB objects
- 2018 (ticket 51935): Performance improvements to the aggregation logic
- 2019 (Yitzchak): Added `AND CreditID >= @LastCreditID` guard in the batch upper-bound query for performance
- 2021 (Shay O.): Changed `@MaxLoggedInOn` query due to performance issues; source switched to `History.ActiveCreditRecentMemoryBucket` + `History.ActiveCreditView` at that point
- 2022 (KateM, PAYT-15): Stopped using `dbo.UserLastLogin` and `dbo.STS_Audit_LoginHistory` for login tracking
- 2023 (DorIz, MIMOPSA-9932): Changed source from `History.ActiveCreditView` back to `History.ActiveCredit` (the inner procedure `UpsertIntoAggregationTablesAction` did not reference the bucket, causing data inconsistency in `CustomerMIMOAllTimeAggregatedData`)

---

## 2. Business Logic

### 2.1 Batch Window Calculation

**What**: Determines the CreditID range for each call to `UpsertIntoAggregationTablesAction`.

**Columns/Parameters Involved**: `@LastCreditID`, `@MaxCreditID`, `@MaxCreditIDToUse`, `@MaxCreditOccurred`

**Rules**:
- If remaining credits fit in one batch (`@LastCreditID + 8000 >= @MaxCreditID`): set `@MaxCreditIDToUse = @MaxCreditID` (process everything)
- Otherwise: find the minimum CreditID above `@LastCreditID` in `History.ActiveCredit` (`OPTION MAXDOP 1` for plan stability), add 8000, then find the MAX CreditID in that window (`OPTION MAXDOP 1`)
- The 8,000-row batch cap (originally 4,000, later 6,000) balances throughput against transaction duration and locking
- `@MaxCreditOccurred` is the `Occurred` timestamp of the batch end credit - passed to the inner SP as the login activity cutoff

**Diagram**:
```
Dictionary.AggregationLastValue
  LastSampleID (CreditID) = @LastCreditID
  LastSampleDateTime (Login) = @LastLogin
         |
         v
History.ActiveCredit
  MAX(CreditID) = @MaxCreditID
         |
         v
  WHILE @LastCreditID < @MaxCreditID
    |
    +--> Batch fits? (@LastCreditID+8000 >= @MaxCreditID)
    |         YES: @MaxCreditIDToUse = @MaxCreditID
    |         NO:  @MaxCreditIDToUse = MIN(CreditID > @LastCreditID) + 8000
    |
    +--> EXEC UpsertIntoAggregationTablesAction(@LastCreditID, @MaxCreditIDToUse, @MaxCreditOccurred, @LastLogin)
    |
    +--> Break if @MaxCreditIDToUse = @MaxCreditID
    |
    +--> @LastCreditID = @MaxCreditIDToUse (advance for next iteration)
```

### 2.2 Login Timestamp Advancement

**What**: Passes the last-processed login timestamp to the inner SP and advances it after each batch.

**Columns/Parameters Involved**: `@LastLogin`, `@MaxLoggedOut`

**Rules**:
- `@LastLogin` is read from `Dictionary.AggregationLastValue` WHERE `TableName='History.Login' AND IncreasingColumnName='LoggedOut'`
- After each batch, the inner SP (`UpsertIntoAggregationTablesAction`) updates the high-water mark in `Dictionary.AggregationLastValue` internally
- `@LastLogin` is advanced to `@MaxLoggedOut` for the next iteration: `Select @LastCreditID=@MaxCreditIDToUse, @LastLogin=@MaxLoggedOut`
- Note: `@MaxLoggedOut` in this context is set by the inner SP's internal processing (the commented-out sp_executesql blocks in the DDL show the evolution - login tracking moved from `STS_Audit_LoginHistory` to `SYN_STS_Audit_MIMO_GetUsersLogin_V` in 2022)

### 2.3 Error Handling and Observability

**What**: Structured error reporting for DBA diagnostics when the aggregation job fails.

**Rules**:
- Wrapped in `BEGIN TRY / BEGIN CATCH ... THROW`
- On error: PRINT includes `@@ServerName`, `DB_Name()`, `Object_Name(@@ProcID)`, `Error_Procedure()`, `Error_Line()`, `Error_Message()`, `Error_Severity()`, `@@TranCount`
- THROW re-raises the error so the calling job agent registers the failure and stops the loop
- The inner SP (`UpsertIntoAggregationTablesAction`) has its own TRY/CATCH with ROLLBACK - errors propagate up to this level

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has **no input parameters**. It is designed to run as a scheduled job entry point, deriving all state from `Dictionary.AggregationLastValue`.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no parameters. All state (last CreditID, last login timestamp, current max CreditID) is read internally from Dictionary.AggregationLastValue and History.ActiveCredit at execution time. |

**Internal variables** (not parameters, listed for reference):

| Variable | Type | Purpose |
|----------|------|---------|
| @LastCreditID | BIGINT | High-water mark CreditID from Dictionary.AggregationLastValue - exclusive lower bound of the current batch |
| @MaxCreditID | BIGINT | Current maximum CreditID in History.ActiveCredit - the catch-up target for this execution |
| @MaxCreditIDToUse | BIGINT | Upper bound for the current batch iteration (min of @MaxCreditID and @LastCreditID+8000 window) |
| @MaxCreditOccurred | DATETIME | Occurred timestamp of the credit at @MaxCreditIDToUse - used as login cutoff in the inner SP |
| @LastLogin | DATETIME | Last login timestamp processed - sourced from Dictionary.AggregationLastValue, advanced per batch |
| @MaxLoggedOut | DATETIME | Most recent LoggedOut timestamp from the current batch's login activity - used to advance @LastLogin |
| @MaxCreditIDToUse_Temp | BIGINT | Intermediate scratch variable: MIN(CreditID > @LastCreditID) before adding 8000 batch window |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LastCreditID | Dictionary.AggregationLastValue | SELECT (read high-water mark) | Reads LastSampleID WHERE TableName='History.Credit' to know where last batch stopped |
| @LastLogin | Dictionary.AggregationLastValue | SELECT (read high-water mark) | Reads LastSampleDateTime WHERE TableName='History.Login' for login activity cutoff |
| @MaxCreditID | History.ActiveCredit | SELECT MAX(CreditID) | Determines the catch-up target - how many new credit events exist |
| @MaxCreditIDToUse | History.ActiveCredit | SELECT MIN/MAX (batch window) | Two OPTION(MAXDOP 1) queries to compute stable batch upper bound |
| @MaxCreditOccurred | History.ActiveCredit | SELECT WHERE CreditID=@MaxCreditIDToUse | Retrieves the Occurred timestamp for the batch endpoint |
| Batch params | BackOffice.UpsertIntoAggregationTablesAction | EXEC | Delegates all actual aggregation work for each batch |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server Agent Job | - | Scheduled execution | This SP is the top-level job step; no SP caller exists |
| PROD_BIadmins.sql | GRANT EXECUTE | Permission grant | BIadmins role has EXECUTE permission on this SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpsertIntoAggregationTables (procedure)
+-- Dictionary.AggregationLastValue (table) [SELECT: read high-water marks]
+-- History.ActiveCredit (table) [SELECT MAX/MIN/WHERE: batch window computation]
+-- BackOffice.UpsertIntoAggregationTablesAction (procedure) [EXEC: core aggregation per batch]
      +-- History.ActiveCredit (table) [SELECT financial events for CreditID range]
      +-- History.Credit (table) [SELECT: cashout full amount subquery]
      +-- History.Position (table) [LEFT JOIN: profit/volume/commission for CreditTypeID=4]
      +-- Trade.ProviderToInstrument (table) [LEFT JOIN: UnitMargin for volume]
      +-- dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V (view/synonym) [SELECT: login events]
      +-- Customer.CustomerStatic (table) [JOIN: GCID -> CID for login data]
      +-- Customer.CustomerMoney (table) [JOIN: RealizedEquity source]
      +-- Billing.Deposit (table) [SELECT: FTD milestone dates]
      +-- BackOffice.CustomerAllTimeAggregatedData_1 (table) [UPSERT: lifetime totals]
      +-- BackOffice.CustomerDTDAggregatedData_1 (table) [UPSERT: day-to-day totals]
      +-- BackOffice.CustomerMTDAggregatedData_1 (table) [UPSERT: month-to-date totals]
      +-- BackOffice.BonusOnlyCustomers (table) [DELETE: cleanup after upsert]
      +-- Dictionary.AggregationLastValue (table) [UPDATE: advance high-water marks]
      +-- Dictionary.AggregationLastValue_History (table) [INSERT: execution audit log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AggregationLastValue | Table | SELECT: reads @LastCreditID (CreditID high-water) and @LastLogin (Login timestamp high-water) at job start |
| History.ActiveCredit | Table | SELECT MAX(CreditID) for catch-up target; SELECT MIN/MAX for batch window with OPTION(MAXDOP 1) |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | EXEC: called once per batch iteration with (@LastCreditID, @MaxCreditIDToUse, @MaxCreditOccurred, @LastLogin) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server Agent Job | External | Scheduled job step - this is the entry point for the aggregation pipeline |
| BackOffice.UpsertIntoAggregationTables_Test | Procedure | Older test variant that mirrors the orchestration logic but uses History.Credit directly (not History.ActiveCredit) and calls UpsertIntoAggregationTablesAction with slightly different batch logic |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NoCount ON` - suppresses row-count messages for clean job output
- `OPTION(MaxDop 1)` on both batch window queries to ensure stable query plans and prevent parallel execution from skewing the batch bounds
- Batch cap: 8,000 CreditIDs per iteration (evolved from 4,000 -> 6,000 -> 8,000 across maintenance history)
- `BEGIN TRY / BEGIN CATCH ... THROW` with full diagnostic PRINT on error
- Login tracking: `@LastLogin` is seeded from `Dictionary.AggregationLastValue` and advanced per batch via `@MaxLoggedOut` (assigned inside the inner SP's processing and returned as a side effect via `@LastLogin = @MaxLoggedOut` after each batch)

**Architecture note**: The outer SP (`UpsertIntoAggregationTables`) reads the high-water mark ONCE at the start and passes it to the inner SP. The inner SP is responsible for updating `Dictionary.AggregationLastValue` after each batch (Part 005 in `UpsertIntoAggregationTablesAction`). If the job is interrupted mid-run, the high-water mark reflects the last successfully committed batch - the outer SP simply re-reads it and resumes from where it left off on the next job run.

---

## 8. Sample Queries

### 8.1 Check current aggregation lag (how far behind is the job)

```sql
SELECT
    alv.TableName,
    alv.IncreasingColumnName,
    alv.LastSampleID,
    alv.LastSampleDateTime,
    -- For CreditID: compare to current max
    MAX(ac.CreditID) AS CurrentMaxCreditID,
    MAX(ac.CreditID) - alv.LastSampleID AS CreditIDLag
FROM Dictionary.AggregationLastValue alv WITH (NOLOCK)
CROSS JOIN (SELECT MAX(CreditID) AS CreditID FROM History.ActiveCredit WITH (NOLOCK)) ac
WHERE alv.TableName = 'History.Credit'
  AND alv.IncreasingColumnName = 'CreditID'
GROUP BY alv.TableName, alv.IncreasingColumnName, alv.LastSampleID, alv.LastSampleDateTime;
```

### 8.2 Review recent batch execution history

```sql
SELECT TOP 20
    EXECUTION_TIME,
    LastCreditID,
    MaxCreditID,
    MaxCreditOccurred,
    LastLoggedOut,
    MaxCreditID - LastCreditID AS BatchSize
FROM Dictionary.AggregationLastValue_History WITH (NOLOCK)
ORDER BY EXECUTION_TIME DESC;
```

### 8.3 Manually trigger the aggregation job (DBA use - use with caution)

```sql
-- First check the current state
SELECT TableName, IncreasingColumnName, LastSampleID, LastSampleDateTime
FROM Dictionary.AggregationLastValue WITH (NOLOCK)
WHERE TableName IN ('History.Credit', 'History.Login');

-- Then execute (only on secondary DB where the job runs)
-- EXEC BackOffice.UpsertIntoAggregationTables;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 50280 (2018) | Internal | Moved job to secondary DB; created synonyms for cross-DB references to primary DB |
| Ticket 51935 (2018) | Internal | Performance improvements to aggregation batch processing |
| PAYT-15 (2022) | Jira | Stopped using dbo.UserLastLogin and dbo.STS_Audit_LoginHistory for login source |
| MIMOPSA-9932 (2023) | Jira | Bug fix: changed source from History.ActiveCreditView to History.ActiveCredit to fix data inconsistency between outer and inner SPs in CustomerMIMOAllTimeAggregatedData |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 4 Internal/Jira (from DDL comments) | Procedures: 1 callee analyzed (UpsertIntoAggregationTablesAction) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpsertIntoAggregationTables | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpsertIntoAggregationTables.sql*
