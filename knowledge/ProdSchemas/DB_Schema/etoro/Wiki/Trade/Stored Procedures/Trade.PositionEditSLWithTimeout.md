# Trade.PositionEditSLWithTimeout

> Monitoring job that detects SL-edit timeout failures since the last run, validates whether the stop loss was ultimately applied, re-queues notifications for unresolved cases, and sends an HTML alert email.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.SynPositionTimeOuts.ID=2 (last-run timestamp for SL-edit timeouts) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditSLWithTimeout is the SL-edit counterpart to Trade.PositionCloseWithTimeout. It is a scheduled monitoring procedure that detects positions where a Stop Loss edit failed due to a database execution timeout (FailTypeID=5). For each such failure, it cross-validates with the position change log (ChangeTypeID=1 = SL edit) to identify genuine timeouts, then performs a critical idempotency check: if the position's current StopRate already matches the intended new StopRate (from the change log), the SL was eventually applied and no notification is needed. Only positions where the SL was NOT applied (still mismatched) generate a notification payload.

This two-stage approach (fail log + current-state comparison) prevents false-positive recovery notifications for SL edits that the system eventually committed despite the initial timeout.

Like Trade.PositionCloseWithTimeout, it uses Trade.SynPositionTimeOuts (ID=2 for SL edits) as a watermark, advances it after each run, inserts qualifying records into Trade.SynPositionEndedWithTOError with MessageType='EditSLWithTimeout', and sends an HTML email to trading operations.

---

## 2. Business Logic

### 2.1 Watermark-Based Time Window

**What**: Uses Trade.SynPositionTimeOuts.LastExecute (ID=2) to define the scan window and advance the watermark after each run.

**Rules**:
- @startTime = SELECT LastExecute WHERE ID=2
- @CurrentDate = GETUTCDATE()
- After processing: UPDATE Trade.SynPositionTimeOuts SET LastExecute=@CurrentDate WHERE ID=2
- ID=2 is the SL-edit watermark; ID=1 is used by PositionCloseWithTimeout

### 2.2 SL-Edit Timeout Detection

**What**: Finds SL edit timeout failures from History.PositionFail and cross-validates with PositionChangeLog_Active.

**Columns/Parameters Involved**: History.PositionFail.FailTypeID=5, HistoryPositionChangeLog_Active.ChangeTypeID=1

**Rules**:
- Filter: FailTypeID=5 AND FailReason LIKE 'Error editing Stop Loss - DB failure%Execution Timeout Expired%'
- Window: FailOccurred BETWEEN @startTime AND @CurrentDate (OPTION RECOMPILE)
- Join to History.PositionChangeLog_Active: ChangeTypeID=1 AND ClientRequestGuid match AND PositionID match AND Occurred in window
- ChangeTypeID=1 = SL edit change log entry
- Additional filter: pcl.MirrorID=0 (only non-mirror positions; mirror positions handled separately)
- Non-US users only: CROSS APPLY Trade.IsUsUser(pcl.CID) WHERE IsUsUser=0
- Captures pcl.StopRate AS NewStopRate and pcl.AmountChanged from the change log

### 2.3 Idempotency Check - Suppress Already-Applied SL

**What**: Compares the intended new StopRate (from change log) with the current StopRate in Trade.Position. If they match, the SL was applied and no notification is needed.

**Columns/Parameters Involved**: Trade.Position.StopRate, cte.NewStopRate (from PositionChangeLog_Active.StopRate)

**Rules**:
- LEFT JOIN Trade.Position on PositionID
- Notificationtosend = CASE WHEN ISNULL(p.StopRate,-1) <> ISNULL(cte.NewStopRate,-2) THEN NULL ELSE CAST(Notificationtosend AS VARCHAR(8000)) END
- If current StopRate != NewStopRate: SL was NOT applied -> keep notification payload
- If current StopRate = NewStopRate: SL was applied -> NULL the notification (suppress)
- ISNULL coercion with different defaults (-1 vs -2) handles the case where both are NULL (would have matched, setting to NULL correctly)
- Notification insert: WHERE Notificationtosend IS NOT NULL (only unresolved cases)

### 2.4 XML Notification Payload

**What**: Builds an EditSLWithTimeout notification payload per unresolved SL edit timeout.

**Columns/Parameters Involved**: Trade.SynPositionEndedWithTOError.MessageType='EditSLWithTimeout', Trade.Position, Trade.PositionTreeInfo

**Rules**:
- OperationTypeId=3 (Edit Position, vs 1 for PositionClose)
- AmountChanged*100 = PositionSLAmountDelta (cents conversion)
- Payload: PositionID, CID, InstrumentID, PositionSLAmountDelta, StopRate (current), SLManualVer, SLManualVerTimestamp, NextThresHold (TSL threshold), TreeID, IsDiscounted
- INSERT DISTINCT into Trade.SynPositionEndedWithTOError WHERE @PublishNotification=1 AND Notificationtosend IS NOT NULL

### 2.5 HTML Email Alert

**Rules**:
- Sends when records exist (IF EXISTS from #t), regardless of @PublishNotification
- Subject: '{ServerName} Positions Edit with time out error from {startTime} To: {currentDate}'
- Table: CID, FailOccurred, PositionFailID, PositionID, InstrumentID, FailReason (truncated at 400 chars, extracted between 'Message:' and next '.')

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PublishNotification | INT | YES | 1 | CODE-BACKED | 1=insert notifications into Trade.SynPositionEndedWithTOError (default), 0=dry-run (email still sent). |
| 2 | @recipients | VARCHAR(255) | YES | 'tradingbackend@etoro.com;dealing-execution@etoro.com' | CODE-BACKED | Semicolon-separated email recipients for HTML alert. Overridable for testing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT / UPDATE | Trade.SynPositionTimeOuts | DML read+write | Reads ID=2 watermark; updates it after run |
| SELECT INTO | History.PositionFail | DML read | SL-edit timeout failures (FailTypeID=5) |
| JOIN | History.PositionChangeLog_Active | DML read | Cross-validates via ChangeTypeID=1 (SL edit events) |
| CROSS APPLY | Trade.IsUsUser | Function call | Filters non-US users |
| LEFT JOIN | Trade.Position | DML read | Current StopRate for idempotency check; also payload data |
| INNER JOIN | Trade.PositionTreeInfo | DML read | SLManualVer, SLManualVerTimestamp, NextThresHold for payload |
| INSERT | Trade.SynPositionEndedWithTOError | DML write | Notification queue for EditSLWithTimeout events |
| EXEC | msdb.dbo.sp_send_dbmail | System SP call | HTML email to trading operations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job or external scheduler.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditSLWithTimeout (procedure)
+-- Trade.SynPositionTimeOuts (table) - watermark ID=2
+-- History.PositionFail (table) - failure source
+-- History.PositionChangeLog_Active (table/view) - SL edit change log
+-- Trade.IsUsUser (function) - US user filter
+-- Trade.Position (view/table) - current StopRate + payload data
+-- Trade.PositionTreeInfo (table) - SL version + TSL threshold for payload
+-- Trade.SynPositionEndedWithTOError (table) - notification queue
+-- msdb.dbo.sp_send_dbmail (system SP) - email dispatch
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynPositionTimeOuts | Table | Watermark: reads LastExecute WHERE ID=2; updates after run |
| History.PositionFail | Table | SL-edit timeout source (FailTypeID=5) |
| History.PositionChangeLog_Active | Table/View | Cross-validation via ChangeTypeID=1, ClientRequestGuid, PositionID |
| Trade.IsUsUser | Function | CROSS APPLY non-US filter |
| Trade.Position | View/Table | Current StopRate for idempotency; PositionID, CID, TreeID for payload |
| Trade.PositionTreeInfo | Table | SLManualVer, SLManualVerTimestamp, NextThresHold for notification payload |
| Trade.SynPositionEndedWithTOError | Table | INSERT EditSLWithTimeout notifications |
| msdb.dbo.sp_send_dbmail | System SP | HTML email dispatch |

### 6.2 Objects That Depend On This

No dependents in SSDT repo. Called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A. Temp table #PositionFailEdit uses CLUSTERED INDEX CIX on (PositionID, ClientRequestGuid).

### 7.2 Constraints

- OPTION(RECOMPILE) prevents parameter-sniffing issues on date-bounded queries
- MirrorID=0 filter ensures only non-mirror positions are processed
- Non-US filter is mandatory (US positions on separate compliance path)
- The ISNULL(-1) vs ISNULL(-2) pattern correctly handles NULL StopRate comparisons
- Email fires on any results, regardless of @PublishNotification value

---

## 8. Sample Queries

### 8.1 Check the SL-edit timeout watermark

```sql
SELECT ID, LastExecute
FROM Trade.SynPositionTimeOuts WITH (NOLOCK)
WHERE ID = 2;
```

### 8.2 Dry-run without publishing notifications

```sql
EXEC Trade.PositionEditSLWithTimeout
    @PublishNotification = 0,
    @recipients = 'your.email@etoro.com';
```

### 8.3 Review pending SL-edit timeout notifications

```sql
SELECT TOP 20 MessageType, CAST(Notificationtosend AS VARCHAR(500)) AS Preview, InsertedAt
FROM Trade.SynPositionEndedWithTOError WITH (NOLOCK)
WHERE MessageType = 'EditSLWithTimeout'
ORDER BY InsertedAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditSLWithTimeout | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditSLWithTimeout.sql*
