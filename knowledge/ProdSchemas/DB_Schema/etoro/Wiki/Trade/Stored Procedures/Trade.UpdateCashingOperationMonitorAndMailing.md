# Trade.UpdateCashingOperationMonitorAndMailing

> Finalizes all in-progress cash corporate action runs by checking payment completion status and transitioning each CashingOperationMonitor record to EndedSuccessfully (3) or EndedWithError (-1) once all payment rows are resolved.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @recipients (legacy, unused) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateCashingOperationMonitorAndMailing is the completion-handler for the cash corporate action pipeline. After cash dividends or airdrops are queued and executed (via `Trade.ExecuteCashPayment`), this procedure scans all monitor records still in `InProcess` (StatusID=1) state and promotes each one to a terminal state - either `EndedSuccessfully` (StatusID=3) or `EndedWithError` (StatusID=-1) - once it confirms that no payment rows remain in an unresolved state (StatusID=0, UnPaid).

Without this procedure, `CashingOperationMonitor` records would remain stuck in `InProcess` indefinitely after their payment rows finish, blocking retry logic (which checks for non-InProcess status before allowing new runs) and preventing operations teams from knowing whether a dividend run completed or failed.

The procedure name includes "AndMailing" because the original design called for sending email notifications to `@recipients` upon completion. This functionality is no longer active - `@recipients` is declared but flagged in the code as "No longer in use." The cash dividend process is part of the Apex US integration for US stock positions (documented in the "Cash Dividend Process (Trading CM)" Confluence page in the EMM space).

---

## 2. Business Logic

### 2.1 Completion Gate - Wait for All Payments to Resolve

**What**: The procedure only finalizes a monitor record after confirming that all `CashPaymentStatus` rows linked to that monitor have exited the UnPaid state (StatusID=0). This prevents premature finalization while payments are still being executed.

**Columns/Parameters Involved**: `Trade.CashPaymentStatus.StatusID`, `Trade.CashPaymentStatus.MonitorID`, `Trade.CashingOperationMonitor.StatusID`

**Rules**:
- A monitor is eligible for finalization ONLY if there are no CashPaymentStatus rows with StatusID=0 (UnPaid) for that MonitorID
- `IF NOT EXISTS (SELECT ... FROM Trade.CashPaymentStatus WHERE MonitorID=@CurrentMonitorID AND StatusID=0)` is the gate condition
- If UnPaid rows still exist (payment still running), the monitor is skipped in this pass
- This makes the procedure safe to call repeatedly - it only acts when the payment executor has finished its batch

### 2.2 Terminal Status Assignment - Success vs. Error

**What**: Once the completion gate passes, the procedure determines whether the run ended cleanly or with failures, and assigns the appropriate terminal status.

**Columns/Parameters Involved**: `Trade.CashingOperationMonitor.StatusID`, `Trade.CashingOperationMonitor.StatusDescription`, `Trade.CashingOperationMonitor.EndDate`, `Trade.CashPaymentStatus.StatusID`

**Rules**:
- Builds `#Failed` temp table: CashPaymentStatus rows for the monitor with StatusID=-1 (Failed)
- If `#Failed` has any rows -> StatusID = -1 (EndedWithError), StatusDescription = 'EndedWithError'
- If `#Failed` is empty -> StatusID = 3 (EndedSuccessfully), StatusDescription = 'EndedSuccessfully'
- In both cases: EndDate = GETDATE() (wall-clock local time)
- Logic uses CASE/EXISTS pattern for single-pass update

**Diagram**:
```
For each InProcess monitor (StatusID=1):
    |
    v
    Any CashPaymentStatus rows with StatusID=0 (UnPaid)?
    YES --> skip (still processing)
    NO  --> check for failures
           |
           +-- Any StatusID=-1 (Failed) rows?
               YES --> StatusID=-1 (EndedWithError)
               NO  --> StatusID=3 (EndedSuccessfully)
           |
           v
    UPDATE CashingOperationMonitor:
      SET EndDate = GETDATE(),
          StatusID = (computed above),
          StatusDescription = (computed above)
    WHERE ID = @CurrentMonitorID
```

### 2.3 Iteration Pattern - Row-by-Row WHILE Loop

**What**: Processes each InProcess monitor record sequentially using a MIN/MAX running ID loop rather than a set-based approach.

**Columns/Parameters Involved**: `RuningID` (temp column), `@MinRunningID`, `@MaxRunningID`

**Rules**:
- Assigns sequential `RuningID` via `ROW_NUMBER()` to the temp table at start
- WHILE @MinRunningID <= @MaxRunningID iterates one monitor at a time
- Each iteration processes one monitor and increments @MinRunningID
- Note: `WHERE StatusID=1` appears redundantly in both the SELECT INTO and the MIN/MAX declarations (the temp table was already filtered to StatusID=1)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @recipients | VARCHAR(500) | - | - | CODE-BACKED | Originally intended to receive a comma-separated list of email recipients for completion notification. Declared in the procedure signature but explicitly commented "No longer in use" in the code - no mailing logic references it. Preserved for backward compatibility with any callers that pass this argument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (gate check) | Trade.CashPaymentStatus | Read | Checks for UnPaid rows (StatusID=0) as the completion gate, and selects Failed rows (StatusID=-1) to determine terminal state |
| UPDATE target | Trade.CashingOperationMonitor | Modifier | Updates StatusID, StatusDescription, and EndDate for each finalized monitor row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - invoked as part of the cash dividend/airdrop batch process, likely by a SQL Agent job or manual execution.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateCashingOperationMonitorAndMailing (procedure)
+-- Trade.CashingOperationMonitor (table)
+-- Trade.CashPaymentStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashingOperationMonitor | Table | SELECT source (reads InProcess records); UPDATE target (sets terminal status and EndDate) |
| Trade.CashPaymentStatus | Table | Gate check (UnPaid rows) and failure detection (Failed rows) per MonitorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cash dividend pipeline | (External process) | Called after Trade.ExecuteCashPayment completes to finalize monitor status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check current InProcess monitors awaiting finalization
```sql
SELECT com.ID, com.PaymentDate, com.TerminalID, com.DataSource,
       com.StatusID, com.StartDate,
       COUNT(cps.ID) AS TotalPayments,
       SUM(CASE WHEN cps.StatusID = 0 THEN 1 ELSE 0 END) AS UnpaidCount,
       SUM(CASE WHEN cps.StatusID = -1 THEN 1 ELSE 0 END) AS FailedCount,
       SUM(CASE WHEN cps.StatusID = 1 THEN 1 ELSE 0 END) AS SuccessCount
FROM   Trade.CashingOperationMonitor com WITH (NOLOCK)
JOIN   Trade.CashPaymentStatus cps WITH (NOLOCK) ON cps.MonitorID = com.ID
WHERE  com.StatusID = 1
GROUP  BY com.ID, com.PaymentDate, com.TerminalID, com.DataSource, com.StatusID, com.StartDate;
```

### 8.2 View recently finalized monitor runs
```sql
SELECT TOP 20
       ID, PaymentDate, TerminalID, DataSource,
       StatusID, StatusDescription, StartDate, EndDate,
       DATEDIFF(MINUTE, StartDate, EndDate) AS DurationMinutes
FROM   Trade.CashingOperationMonitor WITH (NOLOCK)
WHERE  StatusID IN (3, -1)
ORDER  BY EndDate DESC;
```

### 8.3 Find failed payment details for a specific monitor run
```sql
SELECT cps.ID, cps.CID, cps.ApexID, cps.InstrumentID, cps.Amount,
       cps.StatusDescription, cps.PaymentDate, cps.MonitorID
FROM   Trade.CashPaymentStatus cps WITH (NOLOCK)
JOIN   Trade.CashingOperationMonitor com WITH (NOLOCK) ON com.ID = cps.MonitorID
WHERE  cps.StatusID = -1
  AND  com.PaymentDate = '2026-03-01'  -- replace with target payment date
ORDER  BY cps.ID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cash Dividend Process (Trading CM)](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/13994721289/Cash+Dividend+Process+Trading+CM) | Confluence (EMM space) | Business context: cash dividend process is a manual trigger mechanism for real cash payments to US stock customers based on dividend data from Apex (EXT922); this procedure finalizes each run |

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateCashingOperationMonitorAndMailing | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateCashingOperationMonitorAndMailing.sql*
