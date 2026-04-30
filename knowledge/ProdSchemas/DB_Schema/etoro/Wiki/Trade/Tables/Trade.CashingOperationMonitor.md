# Trade.CashingOperationMonitor

> Tracks the execution state and lifecycle of cash corporate action operations (e.g., cash dividends, airdrops) by payment date and terminal, enabling retry logic and completion monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, IDENTITY) |
| **Partition** | No |
| **Indexes** | 3 |

---

## 1. Business Meaning

**WHAT**: This table is an **operation monitor** for cash corporate actions—primarily cash dividends and airdrops. Each row represents one execution attempt of a cashing operation for a specific `PaymentDate` (and optionally `TerminalID`). The table records when the operation started, when it ended, who triggered it, what status it reached, and what type of corporate action it was.

**WHY**: Cash corporate actions (e.g., dividend payments) are multi-step, batch processes that pull data from external sources (e.g., Apex EXT922), create payment records in `Trade.CashPaymentStatus`, and then execute them via `Trade.ExecuteCashPayment`. Without this monitor, there would be no way to prevent duplicate runs for the same payment date, track in-progress operations, or support retries after failures. The `StatusID` state machine ensures idempotent, safe execution.

**HOW**: Data flows from `Trade.PayCashDividendByPayDate`, `Trade.PayCashAirdropByPayDateAndTerminalID`, and `Trade.PayCashTerminalIdByManualData` (INSERT), and from `Trade.UpdateCashingOperationMonitorAndMailing` (UPDATE). The monitor is queried before starting a new run; if the latest run for a given `PaymentDate`/`TerminalID`/`DataSource` is `InProcess` (1), the caller aborts. If it is `EndedWithError` (-1), the caller can retry by inserting a new monitor row and re-queuing failed `CashPaymentStatus` rows. When `ExecuteCashPayment` finishes, `UpdateCashingOperationMonitorAndMailing` marks the monitor as either `EndedSuccessfully` (3) or `EndedWithError` (-1).

---

## 2. Business Logic

### 2.1 Status State Machine

**What**: The lifecycle of a cashing operation is governed by `StatusID`. The latest monitor (by ID DESC) for a given `PaymentDate`/`TerminalID`/`DataSource` determines whether a new run is allowed.

**Columns/Parameters Involved**: `StatusID`, `StatusDescription`, `StartDate`, `EndDate`

**Rules**:
- `StatusID = 1` (InProcess): Operation is running; no concurrent run allowed
- `StatusID = 2` (ExecutedNone): No eligible data found (e.g., no dividend positions for that pay date); run completed with no work
- `StatusID = 3` (EndedSuccessfully): All `CashPaymentStatus` rows for this `MonitorID` were processed successfully
- `StatusID = -1` (EndedWithError): At least one `CashPaymentStatus` row failed; retry is allowed by inserting a new monitor row

**Diagram**:
```
[PayCashDividendByPayDate / PayCashAirdrop / PayCashTerminalIdByManualData]
       |
       | INSERT (StatusID=1 InProcess or 2 ExecutedNone)
       v
[Monitor row created]
       |
       | UpdateCashingOperationMonitorAndMailing (job)
       v
[StatusID = 3 EndedSuccessfully | -1 EndedWithError]
       | (if -1)
       | PayCash* retry path: INSERT new monitor + requeue CashPaymentStatus
       v
[New monitor row for retry]
```

### 2.2 Corporate Action Type and Data Source

**What**: Each monitor row is tied to a corporate action type (e.g., Cash Dividend = 3) and a data source (e.g., EXT922 for Apex). This enables operations to distinguish between dividend runs, airdrop runs, and manual terminal-specific runs.

**Columns/Parameters Involved**: `CorporateActionTypeID`, `DataSource`, `TerminalID`

**Rules**:
- `CorporateActionTypeID = 3`: Cash Dividend (references `Dictionary.CorporateAction` implicitly)
- `DataSource = 'EXT922'`: Apex dividend report
- `TerminalID` NULL: Bulk payment by pay date; non-NULL: terminal-specific (e.g., airdrop by terminal)

---

## 3. Data Overview

| ID | PaymentDate | TerminalID | StatusID | StatusDescription | DataSource | CorporateActionTypeID | Meaning |
|----|-------------|------------|----------|-------------------|------------|------------------------|---------|
| 4 | 2025-08-09 | NULL | 2 | ExecutedNone | EXT922 | 3 | Cash dividend run for 2025-08-09 – no eligible positions found |
| 3 | 2025-08-09 | NULL | 2 | ExecutedNone | EXT922 | 3 | Prior run same date – also no data |
| 2 | 2025-08-09 | NULL | 2 | ExecutedNone | EXT922 | 3 | Earliest run for 2025-08-09 |
| 1 | 2025-07-08 | NULL | 2 | ExecutedNone | EXT922 | 3 | Cash dividend run for 2025-07-08 – no eligible positions |

All current rows have `StatusID = 2` (ExecutedNone). In production, active runs would show `StatusID = 1` (InProcess) until the job completes.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Referenced by `Trade.CashPaymentStatus.MonitorID`. |
| 2 | PaymentDate | date | NO | - | CODE-BACKED | The pay date for which the cash corporate action is run. Used to scope dividend/airdrop data. |
| 3 | TerminalID | varchar(30) | YES | - | CODE-BACKED | Optional terminal identifier for terminal-specific runs (e.g., airdrops). NULL for bulk pay-by-date runs. |
| 4 | StartDate | datetime | NO | - | CODE-BACKED | UTC when the operation started. Set to `GETUTCDATE()` on INSERT. |
| 5 | EndDate | datetime | YES | - | CODE-BACKED | UTC when the operation completed. NULL while InProcess; set by `UpdateCashingOperationMonitorAndMailing` on completion. |
| 6 | StatusID | int | NO | - | CODE-BACKED | State: 1=InProcess, 2=ExecutedNone, 3=EndedSuccessfully, -1=EndedWithError. |
| 7 | StatusDescription | varchar(255) | YES | - | CODE-BACKED | Human-readable status label (e.g., 'InProcess', 'ExecutedNone', 'EndedWithError'). |
| 8 | UserName | varchar(255) | NO | - | CODE-BACKED | User or service account that triggered the operation (e.g., 'be-user'). |
| 9 | DataSource | varchar(50) | NO | - | CODE-BACKED | Source of the corporate action data (e.g., 'EXT922' for Apex dividend report). |
| 10 | CorporateActionTypeID | int | NO | - | CODE-BACKED | Type of corporate action. 3 = Cash Dividend. References `Dictionary.CorporateAction` (implicit). |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| CorporateActionTypeID | Dictionary.CorporateAction | Implicit FK | Corporate action type (e.g., Cash Dividend) |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|---------------|---------------|-------------------|-------------|
| Trade.CashPaymentStatus | MonitorID | FK (implicit) | Links payment rows to this monitor |
| Trade.PayCashDividendByPayDate | - | WRITER | INSERTs monitor, uses ID for CashPaymentStatus.MonitorID |
| Trade.PayCashAirdropByPayDateAndTerminalID | - | WRITER | INSERTs monitor for airdrop runs |
| Trade.PayCashTerminalIdByManualData | - | WRITER | INSERTs monitor for manual terminal runs |
| Trade.UpdateCashingOperationMonitorAndMailing | - | UPDATER | Updates StatusID/EndDate when payments complete |
| Trade.ExecuteCashPayment | - | READER | Joins via MonitorID to get CorporateActionTypeID, DataSource |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CashingOperationMonitor (table)
├── Dictionary.CorporateAction (table) [implicit via CorporateActionTypeID]
└── Trade.CashPaymentStatus (table) [referenced by - MonitorID points here]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CorporateAction | Table | Implicit lookup for CorporateActionTypeID (e.g., 3 = Cash Dividend) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashPaymentStatus | Table | MonitorID references CashingOperationMonitor.ID |
| Trade.PayCashDividendByPayDate | Stored Procedure | WRITER – INSERT, SELECT latest by PaymentDate/TerminalID/DataSource |
| Trade.PayCashAirdropByPayDateAndTerminalID | Stored Procedure | WRITER |
| Trade.PayCashTerminalIdByManualData | Stored Procedure | WRITER |
| Trade.UpdateCashingOperationMonitorAndMailing | Stored Procedure | UPDATER – sets EndDate, StatusID, StatusDescription |
| Trade.ExecuteCashPayment | Stored Procedure | READER – joins CashPaymentStatus to get monitor metadata |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_ID | CLUSTERED | ID ASC | - | - | FILLFACTOR=95 |
| IX_PaymentDate_TerminalID | NONCLUSTERED | PaymentDate ASC, TerminalID ASC, ID DESC | - | - | FILLFACTOR=95 |
| IX_StatusID | NONCLUSTERED | StatusID ASC | - | - | FILLFACTOR=95 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CIX_ID | Primary Key | ID – unique clustered |

---

## 8. Sample Queries

### 8.1 Get latest monitor for a payment date (dividend run check)

```sql
SELECT TOP 1 com.ID, com.PaymentDate, com.StatusID, com.StatusDescription, com.StartDate, com.EndDate
FROM   Trade.CashingOperationMonitor com WITH (NOLOCK)
WHERE  com.PaymentDate = @PaymentDate
       AND com.TerminalID IS NULL
       AND com.DataSource = 'EXT922'
ORDER BY com.ID DESC
```

### 8.2 Find in-progress cashing operations

```sql
SELECT com.ID, com.PaymentDate, com.TerminalID, com.StartDate, com.UserName, com.DataSource
FROM   Trade.CashingOperationMonitor com WITH (NOLOCK)
WHERE  com.StatusID = 1
ORDER BY com.ID DESC
```

### 8.3 Monitor run history by payment date

```sql
SELECT com.ID, com.PaymentDate, com.TerminalID, com.StatusID, com.StatusDescription,
       com.StartDate, com.EndDate, com.UserName
FROM   Trade.CashingOperationMonitor com WITH (NOLOCK)
WHERE  com.PaymentDate BETWEEN @DateFrom AND @DateTo
       AND com.DataSource = @DataSource
ORDER BY com.PaymentDate DESC, com.ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| Cash Dividend Process (Trading CM) | Confluence (EMM) | Cash Dividend process is a manual trigger for real cash dividend payments; CashingOperationMonitor supports the workflow |

---

*Generated: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: Atlassian: 1 Confluence | Procedures: 5 analyzed | MCP live data: sampled*
