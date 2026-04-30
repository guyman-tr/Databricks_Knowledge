# Trade.ReportWrongDataInHistoryCredit_NewElad

> Enhanced version of the History.Credit consistency monitor that uses three snapshots (2-minute intervals), persists all failures to DBA.dbo.ReportWrongDataInHistoryCredit for trend analysis, and reports how long each customer has been failing continuously.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - investigation/diagnostic tool |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an enhanced investigative tool for tracking persistent financial inconsistencies between `History.Credit` and `Customer.CustomerMoney`. Unlike its predecessor (`Trade.ReportWrongDataInHistoryCredit`) which uses a single 5-minute delay and discards results, this version takes three snapshots at 1-minute intervals, records every occurrence in `DBA.dbo.ReportWrongDataInHistoryCredit`, and enriches the alert with two key metrics: how many consecutive job executions a CID has been failing (`CIDFailsContinuously`), and when it first started failing (`CIDFailsSince`).

This procedure was written by Elad as a personal investigation tool - the email currently goes only to eladav@etoro.com (not the full team), and was designed to help distinguish one-off anomalies from systematic financial data corruption that requires DBA intervention.

The three-snapshot approach (T=0, T+1min, T+2min) with intersection logic ensures that a CID must be failing in snapshot #1 AND #3 to be considered persistent. The incremental ID system (`@ID`) links all runs of the same job batch, enabling trend detection across executions.

---

## 2. Business Logic

### 2.1 Three-Snapshot Persistent Failure Detection

**What**: Three-pass verification using 1-minute gaps, requiring the CID to appear in snapshots #1 AND #3 to be reported.

**Columns/Parameters Involved**: `#a`, `#b`, `#c` (temp tables), `DBA.dbo.ReportWrongDataInHistoryCredit`

**Rules**:
- Snapshot #a: T=0 (at execution start)
- Snapshot #b: T+1 minute (first WAITFOR '00:01:00')
- Snapshot #c: T+2 minutes (second WAITFOR '00:01:00')
- First filter: CIDs in BOTH #a and #b must intersect (else RETURN - no persistent issue)
- Second filter: Only CIDs in BOTH #a and #c are inserted to the persistence table
- This 3-check design is more rigorous than the 2-check OLD version

### 2.2 Failure Persistence Tracking

**What**: Tracks how long each CID has been failing by analyzing sequences in DBA.dbo.ReportWrongDataInHistoryCredit.

**Columns/Parameters Involved**: `DBA.dbo.ReportWrongDataInHistoryCredit.ID`, `CIDFailsContinuously`, `CIDFailsSince`

**Rules**:
- Each run gets a new @ID = MAX(ID)+1 from DBA.dbo.ReportWrongDataInHistoryCredit
- For each CID in the current run, uses LAG() to find gaps in the ID sequence
- `StartID` = the ID where the current continuous failure streak began
- `CIDFailsContinuously` = currentID - StartID + 1 (number of consecutive executions failing)
- `CIDFailsSince` = the Occurred timestamp of the StartID row (when the streak started)

**Diagram**:
```
DBA.dbo.ReportWrongDataInHistoryCredit IDs for CID 12345:
  ID=5 (Occurred=08:00)
  ID=7 (Occurred=08:10)   <- gap at 6 means restart
  ID=8 (Occurred=08:20)
  ID=9 (Occurred=08:30)   <- current run (@ID=9)

  StartID = 7 (first ID in current streak)
  CIDFailsContinuously = 9-7+1 = 3
  CIDFailsSince = 08:10
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Investigation/diagnostic tool currently emailing only eladav@etoro.com. Takes ~2+ minutes per execution due to WAITFOR delays. |

**Output columns (in #mail / email):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | BIGINT | NO | - | CODE-BACKED | Customer with persistent financial inconsistency persisting across all three snapshots. |
| 3 | AC_RealizedEquity | DECIMAL | NO | - | CODE-BACKED | RealizedEquity value from History.ActiveCreditView (most recent credit record). |
| 4 | CM_RealizedEquity | DECIMAL | NO | - | CODE-BACKED | RealizedEquity value from Customer.CustomerMoney. Discrepancy with AC_RealizedEquity signals a problem. |
| 5 | AC_Credit | DECIMAL | NO | - | CODE-BACKED | Credit value from History.ActiveCreditView (most recent credit record). |
| 6 | CM_Credit | DECIMAL | NO | - | CODE-BACKED | Credit value from Customer.CustomerMoney. Discrepancy with AC_Credit signals a problem. |
| 7 | Remark | VARCHAR | NO | - | CODE-BACKED | Space-delimited list of mismatched columns: 'RealizedEquity ' and/or 'Credit '. |
| 8 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this discrepancy was recorded (GETDATE() at execution time). |
| 9 | CIDFailsContinuously | BIGINT | NO | - | CODE-BACKED | Number of consecutive job executions this CID has been failing. Derived from ID sequence gaps in DBA.dbo.ReportWrongDataInHistoryCredit. Higher = more serious issue. |
| 10 | CIDFailsSince | DATETIME | NO | - | CODE-BACKED | Timestamp when the current continuous failure streak began for this CID. Looked up from the StartID row in DBA.dbo.ReportWrongDataInHistoryCredit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Main JOIN | Customer.CustomerMoney | Lookup | Provides live financial values for comparison |
| Main JOIN | History.ActiveCreditView | Lookup | Most recent credit ledger entries for validation |
| INSERT/SELECT | DBA.dbo.ReportWrongDataInHistoryCredit | Writer | Persists each failure occurrence for trend analysis |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInHistoryCredit_NewElad (procedure)
|- Customer.CustomerMoney (table)
|- History.ActiveCreditView (view)
|- DBA.dbo.ReportWrongDataInHistoryCredit (external DB table - persistence store)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Source of live Credit and RealizedEquity values |
| History.ActiveCreditView | View | Source of most recent credit ledger entries (last 24 hours) |
| DBA.dbo.ReportWrongDataInHistoryCredit | External Table | Persistence store for failure history; read for MAX(ID) and trend analysis; written for each new failure batch |

### 6.2 Objects That Depend On This

No dependents found - personal investigation tool.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Time window | Logic | Occurred > DATEADD(dd, -1, getdate()) - only last 24 hours of credit records |
| Three-snapshot filter | Logic | CID must appear in snapshot #a AND #c (2 minutes apart) to be recorded |
| Early exit | Logic | If #a INTERSECT #b is empty, RETURN immediately without proceeding to snapshot #c |

---

## 8. Sample Queries

### 8.1 Execute the enhanced History.Credit consistency check

```sql
EXEC Trade.ReportWrongDataInHistoryCredit_NewElad
-- Note: takes ~2+ minutes due to WAITFOR delays
```

### 8.2 View historical failure trends from the persistence table

```sql
SELECT CID, COUNT(*) AS TotalFailures, MIN(Occurred) AS FirstSeen, MAX(Occurred) AS LastSeen
FROM DBA.dbo.ReportWrongDataInHistoryCredit WITH (NOLOCK)
GROUP BY CID
ORDER BY TotalFailures DESC
```

### 8.3 Find customers with long-running continuous failures

```sql
SELECT TOP 20 CID, AC_RealizedEquity, CM_RealizedEquity, AC_Credit, CM_Credit, Remark, Occurred
FROM DBA.dbo.ReportWrongDataInHistoryCredit WITH (NOLOCK)
WHERE ID = (SELECT MAX(ID) FROM DBA.dbo.ReportWrongDataInHistoryCredit WITH (NOLOCK))
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInHistoryCredit_NewElad | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInHistoryCredit_NewElad.sql*
