# Trade.ReopenOperationSendApprovalRequest

> Sends an HTML approval request email to back-office approvers containing the aggregated instrument/position summary and calculated compensation amount for a pending reopen operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperationSendApprovalRequest triggers the approval step in the reopen operation workflow by sending a detailed HTML email to the designated approvers. The email contains two sections: (1) a summary table of instruments/positions grouped by InstrumentID and HedgeServerID (from Trade.ReopenOperation.AggregatedData XML), and (2) a full list of individual positions to be reopened with their CID and PositionID. It also calculates and displays the total compensation amount if stop rates changed.

This procedure exists to automate the approval communication step that is required before a reopen operation can be executed. Approvers receive all the information they need to make a decision without querying the database directly: which instruments and positions are involved, how many, what amounts, and what compensation cost the company will bear.

Data flow: Called after Trade.ReopenOperationAdd creates the operation and Trade.ReopenOperationValidation populates AggregatedData XML. The email recipient list comes from Maintenance.Feature FeatureID=107 (a configurable feature flag storing a comma-separated email list). Email is sent via msdb.dbo.sp_send_dbmail on the current SQL Server instance. The subject includes @@SERVERNAME and the current date for server identification.

Modification history:
- FB 53631 (25/02/2019, Mor): Created
- TRAD 628 (08/01/2020, Mor): Added CompensatedAmount calculation and moved position list from email body to attached file
- 09/12/2021 (Bonnie): Changed to inner HTML table for position list

---

## 2. Business Logic

### 2.1 XML-to-HTML Conversion for Summary Table

**What**: Trade.ReopenOperation.AggregatedData stores a pre-built XML summary. This procedure converts it to HTML by replacing XML element names with HTML tag names.

**Columns/Parameters Involved**: `AggregatedData` (from Trade.ReopenOperation)

**Rules**:
- AggregatedData is cast to NVARCHAR(MAX).
- XML-to-HTML replacements: AggregatedDataList->tbody, AggregatedData->tr, InstrumentID->td, HedgeServerID->td, Units->td, Amount->td, NumberOfPositions->td.
- The resulting HTML fragment is embedded in an HTML table with headers: InstrumentID, HedgeServerID, Units, Amount, NumberOfPositions.
- If AggregatedData is NULL, the body shows 'ReOpenOperationID has no records'.

### 2.2 Compensation Amount Calculation

**What**: Calculates total compensation by summing the stop-loss delta times position units for all positions in the reopen batch.

**Columns/Parameters Involved**: `@CompensatedAmount`, `RequestedStopRate`, `StopRate`, `AmountInUnitsDecimal`

**Rules**:
- Formula: SUM(Round((History.Position_Active.StopRate - Trade.ReopenOperation.RequestedStopRate) * History.Position_Active.AmountInUnitsDecimal, 2))
- JOIN path: ReopenOperation -> PositionToReopen (on ReopenOperationID) -> History.Position_Active (on CID + ClosedPositionID = PositionID).
- Represents the cost/credit from applying a new stop rate vs. the position's original stop rate.
- Displayed in the email as "CompensatedAmount: {value}".

### 2.3 Email Recipient Configuration

**What**: Recipients are dynamically fetched from a feature flag rather than hardcoded, allowing the list to be updated without code changes.

**Columns/Parameters Involved**: `Maintenance.Feature FeatureID=107`

**Rules**:
- SELECT Value FROM Maintenance.Feature WHERE FeatureID=107 returns a comma-separated email list.
- Passed directly to msdb.dbo.sp_send_dbmail @recipients.
- Subject line format: "Reopen Operation approval request ({@@SERVERNAME}): {date formatted as DD Mon YYYY}".

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | The reopen operation ID to send approval for. Used to query AggregatedData XML, PositionToReopen list, and compensation amount calculation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReopenOperationID | Trade.ReopenOperation | Reader (SELECT) | Reads AggregatedData XML and RequestedStopRate for the email content. |
| @ReopenOperationID | Trade.PositionToReopen | Reader (SELECT) | Reads CID and ClosedPositionID list for the position table in the email. |
| @ReopenOperationID | History.Position_Active | Reader (SELECT JOIN) | Reads StopRate and AmountInUnitsDecimal to calculate CompensatedAmount. |
| FeatureID=107 | Maintenance.Feature | Lookup | Retrieves email recipient list (comma-separated). |
| (call) | msdb.dbo.sp_send_dbmail | External system call | Sends the HTML email via SQL Server Database Mail. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office tools after reopen operation validation to trigger the approval workflow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperationSendApprovalRequest (procedure)
├── Trade.ReopenOperation (table)
├── Trade.PositionToReopen (table)
├── History.Position_Active (table)
├── Maintenance.Feature (table)
└── msdb.dbo.sp_send_dbmail (external system proc)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | SELECT AggregatedData (XML summary) and RequestedStopRate. |
| Trade.PositionToReopen | Table | SELECT CID and ClosedPositionID for position list table in email. |
| History.Position_Active | Table | JOIN to get StopRate and AmountInUnitsDecimal for compensation calculation. |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=107 for recipient email list. |
| msdb.dbo.sp_send_dbmail | System procedure | Sends the HTML email to approvers. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by back-office workflow tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Requires Database Mail to be configured on the SQL Server instance.

---

## 8. Sample Queries

### 8.1 Trigger approval request email for a pending reopen operation

```sql
EXEC Trade.ReopenOperationSendApprovalRequest @ReopenOperationID = 42;
-- Sends HTML email to recipients in Maintenance.Feature FeatureID=107
```

### 8.2 Preview AggregatedData XML before email

```sql
SELECT ReopenOperationID, CAST(AggregatedData AS NVARCHAR(MAX)) AS AggregatedDataXML
FROM Trade.ReopenOperation WITH (NOLOCK)
WHERE ReopenOperationID = 42;
```

### 8.3 Calculate compensation amount independently

```sql
SELECT SUM(ROUND((hp.StopRate - ro.RequestedStopRate) * hp.AmountInUnitsDecimal, 2)) AS CompensatedAmount
FROM Trade.ReopenOperation ro WITH (NOLOCK)
JOIN Trade.PositionToReopen ptr WITH (NOLOCK) ON ro.ReopenOperationID = ptr.ReopenOperationID
JOIN History.Position_Active hp WITH (NOLOCK) ON hp.CID = ptr.CID AND ptr.ClosedPositionID = hp.PositionID
WHERE ro.ReopenOperationID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationSendApprovalRequest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperationSendApprovalRequest.sql*
