# History.LogErrorGeneral

> General-purpose SQL error logging table where stored procedures across all schemas capture TRY/CATCH exception details, including the calling procedure name, its parameters at time of failure, and full SQL Server error context.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

History.LogErrorGeneral is the central error log for stored procedure exceptions across the etoro database. When a procedure catches an error in its TRY/CATCH block and needs to record it for later investigation, it calls History.InsertLogErrorGeneral, which writes one row here. The table captures both the SQL Server system error details (number, message, severity, state, procedure, line) and the business context (which outer procedure called the error, and what parameters it was running with).

Without this table, failed operations would either silently disappear or only surface as application-level exceptions with no server-side detail. The Param_XML column is particularly valuable - it stores the exact parameters passed to the failing procedure, enabling developers and support teams to reproduce the exact failure scenario by replaying those parameters.

Rows are written by calling History.InsertLogErrorGeneral (a dedicated write wrapper). Multiple procedures across Broker, Customer, Trade, BackOffice, Stocks, and History schemas use this table. The table is not a temporal history table - it is a permanent log that accumulates over time.

---

## 2. Business Logic

### 2.1 NameSP vs ErrorProcedure - Two Levels of Context

**What**: Two separate procedure name columns capture the "outer" caller (NameSP) and the "inner" failure point (ErrorProcedure), which may differ when errors bubble up through nested procedure calls.

**Columns/Parameters Involved**: `NameSP`, `ErrorProcedure`, `ErrorLine`, `Param_XML`

**Rules**:
- `NameSP` = the SP that called History.InsertLogErrorGeneral (the outer SP handling the TRY/CATCH)
- `ErrorProcedure` = SQL Server's ERROR_PROCEDURE() - the SP where the exception actually originated (may be an inner SP called by NameSP)
- `Param_XML` = the parameters of NameSP, not the inner SP - this is the business-level input that caused the failure
- When NameSP = ErrorProcedure, the error originated directly in the calling procedure (most common case)
- When NameSP != ErrorProcedure, an inner SP threw the error and the outer SP caught and logged it

**Diagram**:
```
Customer.RegisterReal (NameSP="Customer.RegisterReal")
  EXEC Customer.InsertRealCustomer(@params) ---> Error 547 at line 91
    CATCH: EXEC History.InsertLogErrorGeneral
      NameSP       = "Customer.InsertRealCustomer"   <- the SP that caught
      ErrorProcedure = "Customer.InsertRealCustomer" <- where error occurred
      Param_XML    = <RegisterReal>...</RegisterReal> <- full params at time of error
```

### 2.2 Error Classification by ErrorNumber

**What**: SQL Server error numbers (ErrorNumber) classify the type of system failure, guiding investigation priority.

**Columns/Parameters Involved**: `ErrorNumber`, `ErrorSeverity`, `ErrorMessage`

**Rules**:
- Error 547: FK constraint violation - indicates data integrity failure (missing lookup value, race condition)
- Error 1105: Filegroup/disk full - indicates infrastructure capacity issue, not code error
- ErrorSeverity levels: 16=user-correctable errors (FKs, constraints), 17=resource errors (disk full, memory), 25=fatal
- ErrorState provides further sub-classification within the error number
- ErrorMessage is the full SQL Server error text including the specific table/column/constraint name

---

## 3. Data Overview

| ID | NameSP | ErrorNumber | ErrorProcedure | ErrorLine | Meaning |
|---|---|---|---|---|---|
| 16 | Customer.InsertRealCustomer | 1105 | Customer.InsertRealCustomer | 91 | Customer registration failure: filegroup PRIMARY was full at time of INSERT into Customer.CustomerStatic. Infrastructure capacity incident - not a code defect. All registrations at that moment failed simultaneously. |
| 21 | Customer.InsertRealCustomer | 1105 | Customer.InsertRealCustomer | 91 | Same filegroup full incident as above - this was a short-lived disk capacity event that generated ~15 consecutive failures before resolution. |
| 35364 | Customer.InsertRealCustomer | 547 | Customer.InsertRealCustomer | 91 | FK violation during customer registration: Param_XML shows DesignatedRegulationID referenced a PrivacyPolicyID that did not exist in Dictionary.PrivacyPolicy. Likely caused by a new regulation value deployed without the corresponding dictionary entry. |
| 35367 | Customer.InsertRealCustomer | 547 | Customer.InsertRealCustomer | 91 | FK violation burst: a batch of registration attempts with DesignatedRegulationID pointing to a missing PrivacyPolicyID. Param_XML captures the exact registration payload for each failed attempt, enabling replay. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key for each error event. Sequential within a session but not guaranteed contiguous (identity gaps may occur on rollbacks). PK clustered - queries filtering by ID range efficiently retrieve error bursts. |
| 2 | DateAt | datetime | NO | getdate() | CODE-BACKED | Local server timestamp when the INSERT to this table occurred (i.e., when the error was caught and logged). Note: getdate() is local server time, not UTC - this differs from temporal history tables which use datetime2(7) UTC. Use this to correlate with application logs and incident timelines. |
| 3 | NameSP | varchar(50) | YES | - | CODE-BACKED | Name of the stored procedure that caught the error and called History.InsertLogErrorGeneral. This is the "business entry point" - the outer SP that was executing a user-requested operation. Examples: "Customer.InsertRealCustomer", "Trade.DetachFromParentPosition". Maximum 50 characters - longer SP names may be truncated (compare to ErrorProcedure which allows 100 chars). NULL if logged outside a named procedure context. |
| 4 | Param_XML | xml | YES | - | CODE-BACKED | The full input parameters that were passed to NameSP at the time of the error, serialized as XML. The XML root element and structure match the calling procedure's parameter set (e.g., `<RegisterReal><ProviderID>1</ProviderID>...</RegisterReal>` for Customer.InsertRealCustomer). This is the most valuable debugging column - it enables exact replay of the failed call. NULL when the calling procedure did not provide this context. |
| 5 | ErrorNumber | int | YES | - | CODE-BACKED | SQL Server error number from ERROR_NUMBER() at time of catch. Common values observed: 547=FK constraint violation, 1105=filegroup full, 60000=custom eToro error codes raised via RAISERROR. NULL is unexpected but possible if the catch block itself had issues. |
| 6 | ErrorMessage | varchar(max) | YES | - | CODE-BACKED | Full error message text from ERROR_MESSAGE(). For FK violations (547), includes the constraint name, table, and column involved. For disk/resource errors (1105), includes the object, database, and filegroup name. For custom errors (RAISERROR), contains the developer-specified message. Unbounded length (varchar(max)) to accommodate long constraint names and complex error text. |
| 7 | ErrorSeverity | int | YES | - | CODE-BACKED | SQL Server error severity level from ERROR_SEVERITY(). Severity 16=user-correctable data errors (most common), 17=resource errors (disk, memory, connections), 20-25=fatal server errors. Severity < 10 are informational and rarely logged here. Use to triage: 17+ requires infrastructure attention; 16 is typically a code or data issue. |
| 8 | ErrorState | int | YES | - | CODE-BACKED | SQL Server error state from ERROR_STATE(). Provides sub-classification within the error number. For example, error 547 (FK violation) uses state to distinguish INSERT vs UPDATE vs DELETE violations. State 0 is common for errors raised by SQL Server internally. |
| 9 | ErrorProcedure | varchar(100) | YES | - | CODE-BACKED | The stored procedure name where the error actually occurred, from ERROR_PROCEDURE(). May differ from NameSP when errors propagate through nested SP calls. When NULL, the error occurred in an ad-hoc batch or the outermost procedure. 100-character limit (wider than NameSP's 50 chars) to accommodate longer fully-qualified SP names. |
| 10 | ErrorLine | int | YES | - | CODE-BACKED | The line number within ErrorProcedure where the error was raised, from ERROR_LINE(). Used with ErrorProcedure to pinpoint the exact SQL statement that failed. Corresponds to the line number in the SSDT .sql file for that procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a free-standing log table with no FK constraints - error logging must never fail due to referential integrity issues.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.InsertLogErrorGeneral | (INSERT) | Writer procedure | Dedicated insert wrapper - all callers use this SP rather than writing directly |
| Customer.InsertRealCustomer | (via History.InsertLogErrorGeneral) | Error logger | Logs customer registration failures |
| Customer.RegisterDemo | (via History.InsertLogErrorGeneral) | Error logger | Logs demo account registration failures |
| Customer.RegisterReal | (via History.InsertLogErrorGeneral) | Error logger | Logs real account registration failures |
| Trade.DetachFromParentPosition | (via History.InsertLogErrorGeneral) | Error logger | Logs position tree detach failures |
| Trade.GetTreeNodesByParentCID_Inner | (via History.InsertLogErrorGeneral) | Error logger | Logs copy-trade tree traversal errors |
| BackOffice.KycAddILQ | (via History.InsertLogErrorGeneral) | Error logger | Logs KYC/compliance operation failures |
| BackOffice.usp_CloseZeroMirrors | (via History.InsertLogErrorGeneral) | Error logger | Logs zero-balance mirror close failures |
| Broker.actPayment | (via History.InsertLogErrorGeneral) | Error logger | Logs payment processing failures |
| Broker.actPiggyBank | (via History.InsertLogErrorGeneral) | Error logger | Logs piggy bank (savings/bonus) operation failures |
| Stocks.SetStockDailyPrice | (via History.InsertLogErrorGeneral) | Error logger | Logs stock price update failures |
| History.LogOutByLoginID | (via History.InsertLogErrorGeneral) | Error logger | Logs logout operation failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogErrorGeneral (table)
  - No code-level dependencies (leaf table)
```

### 6.1 Objects This Depends On

No dependencies. Free-standing log table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.InsertLogErrorGeneral | Stored Procedure | Writer - inserts all error log records |
| Customer.InsertRealCustomer | Stored Procedure | Error logger via InsertLogErrorGeneral |
| Customer.RegisterDemo | Stored Procedure | Error logger via InsertLogErrorGeneral |
| Customer.RegisterReal | Stored Procedure | Error logger via InsertLogErrorGeneral |
| Trade.DetachFromParentPosition | Stored Procedure | Error logger via InsertLogErrorGeneral |
| BackOffice.KycAddILQ | Stored Procedure | Error logger via InsertLogErrorGeneral |
| Broker.actPayment | Stored Procedure | Error logger via InsertLogErrorGeneral |
| Stocks.SetStockDailyPrice | Stored Procedure | Error logger via InsertLogErrorGeneral |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

Note: No secondary indexes on DateAt or NameSP. Range queries by date or procedure name will scan the clustered index. For operational use (finding recent errors for a specific procedure), consider: `WHERE NameSP = 'X' AND DateAt >= @from` will full-scan if table is large.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_LogErrorGeneral_DateAt | DEFAULT | DateAt = getdate() - automatically stamps local server time on insert |

Data compression: PAGE compression applied to reduce storage for repetitive XML content in Param_XML.

---

## 8. Sample Queries

### 8.1 Find recent errors for a specific stored procedure

```sql
SELECT TOP 50
    ID,
    DateAt,
    NameSP,
    ErrorNumber,
    ErrorMessage,
    ErrorProcedure,
    ErrorLine
FROM [History].[LogErrorGeneral] WITH (NOLOCK)
WHERE NameSP = 'Customer.InsertRealCustomer'
  AND DateAt >= DATEADD(DAY, -7, GETDATE())
ORDER BY DateAt DESC
```

### 8.2 Get error frequency by procedure and error type (last 30 days)

```sql
SELECT
    NameSP,
    ErrorNumber,
    LEFT(ErrorMessage, 200) AS ErrorSummary,
    COUNT(*) AS OccurrenceCount,
    MAX(DateAt) AS LastOccurrence
FROM [History].[LogErrorGeneral] WITH (NOLOCK)
WHERE DateAt >= DATEADD(DAY, -30, GETDATE())
GROUP BY NameSP, ErrorNumber, LEFT(ErrorMessage, 200)
ORDER BY OccurrenceCount DESC
```

### 8.3 Extract parameters from a specific error for replay debugging

```sql
SELECT
    ID,
    DateAt,
    NameSP,
    Param_XML,
    ErrorNumber,
    ErrorMessage,
    ErrorLine
FROM [History].[LogErrorGeneral] WITH (NOLOCK)
WHERE ID = 35367
-- Param_XML contains the exact input that caused the failure - use for replay
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.InsertLogErrorGeneral) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LogErrorGeneral | Type: Table | Source: etoro/etoro/History/Tables/History.LogErrorGeneral.sql*
