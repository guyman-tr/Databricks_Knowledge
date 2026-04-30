# Trade.PositionCloseWithTimeout

> Monitoring job that detects position close timeout failures since the last run, re-queues XML notifications for downstream processing, and sends an HTML alert email to trading operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.SynPositionTimeOuts.ID=1 (last-run timestamp for close timeouts) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionCloseWithTimeout is a scheduled monitoring procedure that detects positions that failed to close due to database execution timeouts. It runs periodically (invoked by a SQL Agent job or external scheduler), queries History.PositionFail for close-timeout errors since the last execution, confirms they are genuine timeout failures by joining to the position change log, and takes two actions: (1) inserts XML notification payloads into Trade.SynPositionEndedWithTOError for downstream processing by notification services, and (2) sends an HTML email report to trading backend teams.

The procedure maintains a "watermark" in Trade.SynPositionTimeOuts (ID=1, LastExecute column) to track how far it has scanned. On each run, it processes the window from the previous LastExecute to the current UTC time, then advances the watermark. This ensures no event is missed or double-processed between runs.

Non-US users only are included (CROSS APPLY Trade.IsUsUser with IsUsUser=0 filter) - US brokerage positions follow a separate compliance path.

The commented-out block shows a prior architecture using OPENQUERY against a linked server (PositionFailReal_QA), which was replaced by the direct History.PositionFail query, likely after the data was centralized.

---

## 2. Business Logic

### 2.1 Watermark-Based Time Window

**What**: Uses Trade.SynPositionTimeOuts.LastExecute to bound the query window and advance the watermark after each run.

**Columns/Parameters Involved**: Trade.SynPositionTimeOuts.ID=1, LastExecute, @startTime, @CurrentDate

**Rules**:
- @startTime = Trade.SynPositionTimeOuts.LastExecute WHERE ID=1 (prior run end)
- @CurrentDate = GETUTCDATE() (current UTC time)
- After processing: UPDATE Trade.SynPositionTimeOuts SET LastExecute=@CurrentDate WHERE ID=1
- The update occurs whether or not any timeouts were found, advancing the watermark regardless

### 2.2 Timeout Failure Detection

**What**: Identifies close-timeout failure records from History.PositionFail and cross-validates with the change log to confirm actual position closure.

**Columns/Parameters Involved**: History.PositionFail.FailTypeID=4, FailReason LIKE pattern, History.PositionChangeLog_Active.ChangeTypeID=6

**Rules**:
- Filter: FailTypeID=4 AND FailReason LIKE 'Error closing position - DB failure%Execution Timeout Expired%'
- Window: FailOccurred BETWEEN @startTime AND @CurrentDate (uses OPTION RECOMPILE to avoid parameter-sniffing issues)
- Join to History.PositionChangeLog_Active: ChangeTypeID=6 AND ClientRequestGuid match AND PositionID match AND Occurred in window
- ChangeTypeID=6 represents a position-close change log entry
- CROSS APPLY Trade.IsUsUser(hpf.CID) filters to non-US users only (IsUsUser=0)
- ClientRequestGuid comparison handles NULLs via ISNULL(guid, CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER))

### 2.3 XML Notification Generation

**What**: For each detected timeout, builds a TradingDbPositionNotification XML payload from History.PositionSlim, Customer.CustomerStatic, and Trade.Mirror, then inserts into Trade.SynPositionEndedWithTOError.

**Columns/Parameters Involved**: Trade.SynPositionEndedWithTOError.MessageType='CloseWithTimeout', Notificationtosend (XML)

**Rules**:
- OUTER APPLY assembles FOR XML RAW / FOR XML PATH payload per position
- NetProfit is multiplied by 100 (converted to cents integer) for the notification
- Amount is multiplied by 100 (converted to cents integer) for the notification
- Payload includes: CID, PositionID, InstrumentID, HedgeServerID, Leverage, rates, ActionType, amounts, GCID, CountryID, SkewValue, IsSettled, MirrorID, IsMirrorActive, TreeID, ClosedOrdersExitID, PositionRatio, UnitMargin
- SkewValue sourced from Trade.CurrencyPrice: SkewValueBid (IsBuy=1) or SkewValueAsk (IsBuy=0)
- Insert is gated: only runs IF @PublishNotification=1 (default) AND Notificationtosend IS NOT NULL
- MessageType='CloseWithTimeout' distinguishes these from open-timeout notifications

### 2.4 HTML Email Alert

**What**: Sends an HTML-formatted email to trading operations with a table of all detected timeout failures.

**Columns/Parameters Involved**: @PublishNotification, @recipients, msdb.dbo.sp_send_dbmail

**Rules**:
- Email is sent unconditionally when records exist (IF EXISTS select top 1 1 from #t), regardless of @PublishNotification value
- @recipients defaults to 'tradingbackend@etoro.com;dealing-execution@etoro.com'
- Subject includes server name and time window: '{ServerName} Positions Close with time out error from {startTime} To: {currentDate}'
- Table columns: CID, FailOccurred, PositionFailID, PositionID, InstrumentID, FailReason (truncated to 400 chars)
- FailReason is extracted as the substring between 'Message:' and the next '.' for readability

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PublishNotification | INT | YES | 1 | CODE-BACKED | Controls whether XML notifications are inserted into Trade.SynPositionEndedWithTOError. 1=publish (default), 0=dry-run (email still sent if records found). |
| 2 | @recipients | VARCHAR(255) | YES | 'tradingbackend@etoro.com;dealing-execution@etoro.com' | CODE-BACKED | Semicolon-separated email recipients for the HTML alert. Overridable for testing or routing to different teams. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT LastExecute | Trade.SynPositionTimeOuts | DML read | Reads ID=1 watermark to define the scan window start |
| UPDATE LastExecute | Trade.SynPositionTimeOuts | DML write | Advances ID=1 watermark to current UTC after each run |
| SELECT INTO #PositionFailClose | History.PositionFail | DML read | Finds close-timeout failures (FailTypeID=4) in the window |
| JOIN | History.PositionChangeLog_Active | DML read | Confirms position-close events (ChangeTypeID=6) matching the failures |
| CROSS APPLY | Trade.IsUsUser | Function call | Filters out US brokerage users |
| INSERT | Trade.SynPositionEndedWithTOError | DML write | Enqueues XML notification payloads for downstream services |
| FOR XML / JOIN | History.PositionSlim | DML read | Builds notification payload with position close details |
| JOIN | Customer.CustomerStatic | DML read | Adds GCID and CountryID to notification payload |
| LEFT JOIN | Trade.Mirror | DML read | Adds IsMirrorActive to notification payload |
| JOIN | Trade.CurrencyPrice | DML read | Adds SkewValue to notification payload |
| EXEC | msdb.dbo.sp_send_dbmail | System SP call | Sends HTML email alert to trading operations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Invoked by SQL Agent job or external scheduler. Trade.FunPositionCloseWithTimeout (function) shares the naming pattern but is a separate object.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionCloseWithTimeout (procedure)
+-- Trade.SynPositionTimeOuts (table) - watermark read/write
+-- History.PositionFail (table) - failure event source
+-- History.PositionChangeLog_Active (table/view) - change log cross-validation
+-- Trade.IsUsUser (function) - US user filter
+-- Trade.SynPositionEndedWithTOError (table) - notification queue
+-- History.PositionSlim (table/view) - position close details for XML payload
+-- Customer.CustomerStatic (table) - GCID/CountryID for payload
+-- Trade.Mirror (table) - IsMirrorActive for payload
+-- Trade.CurrencyPrice (table) - SkewValue for payload
+-- msdb.dbo.sp_send_dbmail (system SP) - email dispatch
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynPositionTimeOuts | Table | Watermark table: reads LastExecute for ID=1 (window start), updates it after run |
| History.PositionFail | Table | Source of close-timeout failure events (FailTypeID=4) |
| History.PositionChangeLog_Active | Table/View | Cross-validates failures via ChangeTypeID=6 entries |
| Trade.IsUsUser | Function | CROSS APPLY to filter non-US users |
| Trade.SynPositionEndedWithTOError | Table | Notification queue: receives CloseWithTimeout XML payloads |
| History.PositionSlim | Table/View | Detailed position close data for XML notification payload |
| Customer.CustomerStatic | Table | GCID, CountryID for notification payload |
| Trade.Mirror | Table | IsMirrorActive flag for notification payload |
| Trade.CurrencyPrice | Table | SkewValueBid/SkewValueAsk for notification payload |
| msdb.dbo.sp_send_dbmail | System SP | Sends HTML email to trading operations |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table #PositionFailClose with CLUSTERED INDEX CIX on (PositionID, ClientRequestGuid) for efficient join to PositionChangeLog_Active.

### 7.2 Constraints

- OPTION(RECOMPILE) on History.PositionFail query prevents plan reuse issues with variable date bounds
- Non-US filter via Trade.IsUsUser is REQUIRED - US positions are handled by separate compliance workflow
- Email fires whenever records exist, even if @PublishNotification=0 (notification insert is skipped, but email is not)

---

## 8. Sample Queries

### 8.1 Check the current close-timeout watermark

```sql
SELECT ID, LastExecute
FROM Trade.SynPositionTimeOuts WITH (NOLOCK)
WHERE ID = 1;
```

### 8.2 Manually run without publishing notifications (dry-run)

```sql
EXEC Trade.PositionCloseWithTimeout
    @PublishNotification = 0,
    @recipients = 'your.email@etoro.com';
```

### 8.3 Check pending close-timeout notifications

```sql
SELECT TOP 20 MessageType, CAST(Notificationtosend AS VARCHAR(500)) AS PayloadPreview, InsertedAt
FROM Trade.SynPositionEndedWithTOError WITH (NOLOCK)
WHERE MessageType = 'CloseWithTimeout'
ORDER BY InsertedAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionCloseWithTimeout | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionCloseWithTimeout.sql*
