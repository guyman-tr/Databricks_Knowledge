# Trade.ReopenOperationSendResult

> Sends the execution result of a completed reopen operation to back-office recipients as an email with an attached CSV/Excel file containing each position's result, CID, and manager ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperationSendResult delivers the execution results of a completed reopen operation to back-office staff. After Trade.PositionsReopen or Trade.MirrorsReopen execute the reopens and log results to History.PositionToReopen, this procedure sends an email with the full position-level outcome (success/failure, CID, ManagerID) as an attached file.

This procedure exists to close the notification loop in the reopen workflow. After approvers authorize a reopen (via Trade.ReopenOperationSendApprovalRequest) and execution completes, they need to know what succeeded, what failed, and why. The attachment format (CSV) allows recipients to work with the data in Excel for analysis and follow-up.

Note: This procedure uses a different recipient list (FeatureID=106) than the approval request (FeatureID=107), enabling different people to receive approval requests vs. execution results.

---

## 2. Business Logic

### 2.1 Dynamic Query Attached as File

**What**: Rather than embedding result data in the HTML body, the procedure passes a SQL query string to sp_send_dbmail which executes it and attaches the results as a file.

**Columns/Parameters Involved**: `@body` (dynamic SQL), `@FileName`

**Rules**:
- @body is constructed as a VARCHAR CONCAT of a SELECT statement: `SELECT R.CID, R.ClosedPositionID, R.Result, R.FailReason, C.ManagerID FROM History.PositionToReopen R WITH (NOLOCK) JOIN BackOffice.Customer C WITH (NOLOCK) ON R.CID = C.CID AND R.ReopenOperationID = {ID}`.
- @attach_query_result_as_file = 1: the query results are attached as a file, not in the email body.
- @query_result_separator = ',': results are comma-separated (CSV format).
- @query_attachment_filename = 'ReopenOperation_ExecutionResult_{date}.xlsx': filename includes the current date formatted as DD Mon YYYY.
- @execute_query_database = DB_NAME(): executes the query in the current database context.

### 2.2 Different Recipients from Approval Request

**What**: Execution results go to a different recipient list than approval requests.

**Columns/Parameters Involved**: `FeatureID=106`

**Rules**:
- Approval requests use Maintenance.Feature FeatureID=107.
- Execution results use Maintenance.Feature FeatureID=106.
- Both are comma-separated email lists configurable without code changes.
- Subject format: "Reopen Operation Result for ReopenOperationID: {ID} ({@@SERVERNAME})".

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | The reopen operation ID whose results to send. Embedded in the dynamic query and the email subject line. Identifies which History.PositionToReopen rows to include in the result file. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReopenOperationID | History.PositionToReopen | Reader (dynamic SQL) | Reads position results (CID, ClosedPositionID, Result, FailReason) for the given operation. |
| CID | BackOffice.Customer | JOIN (dynamic SQL) | Resolves CID to ManagerID for the result report. |
| FeatureID=106 | Maintenance.Feature | Lookup | Retrieves email recipient list for execution result notifications. |
| (call) | msdb.dbo.sp_send_dbmail | External system call | Sends email with attached CSV query result. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office tools after reopen execution to notify result recipients.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperationSendResult (procedure)
├── History.PositionToReopen (table, via dynamic SQL)
├── BackOffice.Customer (table, via dynamic SQL)
├── Maintenance.Feature (table)
└── msdb.dbo.sp_send_dbmail (external system proc)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionToReopen | Table | Dynamic SQL SELECT - reads per-position reopen results (CID, ClosedPositionID, Result, FailReason). |
| BackOffice.Customer | Table | Dynamic SQL JOIN - resolves CID to ManagerID. |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=106 for result email recipients. |
| msdb.dbo.sp_send_dbmail | System procedure | Sends email with CSV query attachment to result recipients. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by back-office workflow tools after reopen execution.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Requires Database Mail configured on the SQL Server instance.

---

## 8. Sample Queries

### 8.1 Trigger result notification email

```sql
EXEC Trade.ReopenOperationSendResult @ReopenOperationID = 42;
-- Sends CSV attachment to recipients in Maintenance.Feature FeatureID=106
```

### 8.2 Preview the result data without sending email

```sql
SELECT R.CID, R.ClosedPositionID, R.Result, R.FailReason, C.ManagerID
FROM History.PositionToReopen R WITH (NOLOCK)
JOIN BackOffice.Customer C WITH (NOLOCK) ON R.CID = C.CID
WHERE R.ReopenOperationID = 42;
```

### 8.3 Compare approval vs result recipients

```sql
SELECT FeatureID, CAST(Value AS VARCHAR(500)) AS Recipients
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID IN (106, 107);
-- FeatureID=106: result recipients; FeatureID=107: approval recipients
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationSendResult | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperationSendResult.sql*
