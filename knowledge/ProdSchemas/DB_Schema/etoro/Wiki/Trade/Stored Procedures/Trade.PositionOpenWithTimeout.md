# Trade.PositionOpenWithTimeout

> Monitoring job that detects position open timeout failures since the last run, validates that the position was actually created, re-queues full position-open notification payloads for unresolved cases, and sends an HTML alert email.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.SynPositionTimeOuts.ID=3 (last-run timestamp for open timeouts) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionOpenWithTimeout is the third in the timeout-monitoring trio (alongside PositionCloseWithTimeout for closes and PositionEditSLWithTimeout for SL edits). It detects positions where the open operation failed with a database execution timeout (FailTypeID=3). For each such failure, it cross-validates via the change log and Trade.PositionTbl to identify positions that were indeed created (ChangeTypeID=0 with matching OrderID/OrderType), then checks if the position still exists in Trade.Position. Only positions that are open but whose open event timed out in the failure log generate recovery notifications.

The idempotency check here is positional: if Trade.Position no longer contains the PositionID (position was subsequently closed), no notification is sent. If it is still open, a full TradingDbPositionNotification XML payload is built from Trade.PositionTbl, Trade.PositionTreeInfo, and Customer.CustomerStatic and inserted into Trade.SynPositionEndedWithTOError with MessageType='OpenWithTimeout'.

The notification payload for open events is significantly richer than for close/SL events - it includes the full position snapshot needed to reconstruct the state in downstream services (TP/SL rates, leverage, lot count, rates, tree info, margin, etc.).

---

## 2. Business Logic

### 2.1 Watermark-Based Time Window

**Rules**:
- @startTime = SELECT LastExecute FROM Trade.SynPositionTimeOuts WHERE ID=3
- @CurrentDate = GETUTCDATE()
- After processing: UPDATE Trade.SynPositionTimeOuts SET LastExecute=@CurrentDate WHERE ID=3
- ID=3 = open-position timeout watermark (ID=1=close, ID=2=SL edit)

### 2.2 Open Timeout Failure Detection

**Columns/Parameters Involved**: History.PositionFail.FailTypeID=3, FailReason pattern, History.PositionChangeLog_Active.ChangeTypeID=0

**Rules**:
- Filter: FailTypeID=3 AND FailReason LIKE 'Error opening position - DB failure%Execution Timeout Expired%'
- Window: FailOccurred BETWEEN @startTime AND @CurrentDate (OPTION RECOMPILE)
- JOIN Trade.PositionTbl: tp.CID=pcl.CID AND pcl.PositionID=tp.PositionID (confirms position was created in DB)
- JOIN History.PositionChangeLog_Active: ChangeTypeID=0 (open event), ClientRequestGuid match, Occurred in window
- Additional: hpf.OrderID=tp.OrderID AND hpf.OrderType=tp.OrderType (confirms the failed order is the same position)
- Non-US only: CROSS APPLY Trade.IsUsUser WHERE IsUsUser=0
- pcl.MirrorID=0: non-mirror positions only
- Temp table index: CLUSTERED INDEX CIX on (ClientRequestGuid)

### 2.3 Idempotency Check - Suppress Closed Positions

**What**: Suppresses notification if the position no longer exists in Trade.Position (already closed since the timeout).

**Rules**:
- LEFT JOIN Trade.Position p on p.PositionID=cte.PositionID
- Notificationtosend = CASE WHEN p.PositionID IS NULL THEN NULL ELSE CAST(payload AS VARCHAR(8000)) END
- If position not in Trade.Position: already closed -> suppress notification
- INSERT WHERE Notificationtosend IS NOT NULL

### 2.4 XML Notification Payload (Full Open Snapshot)

**What**: Builds a rich TradingDbPositionNotification payload from PositionTbl, PositionTreeInfo, and CustomerStatic.

**Columns/Parameters Involved**: Trade.SynPositionEndedWithTOError.MessageType='OpenWithTimeout', OperationTypeId=2

**Payload columns**: PositionID, CID, InstrumentID, TreeID, LimitRate (TakeProfit), StopRate (StopLoss), IsBuy, InitDateTime, MirrorID, ParentPositionID, Leverage, LotCountDecimal, InitForexRate, InitForexPriceRateID, LastOpConversionRate, LastOpConversionRateID, Amount*100 (PositionAmountCents), OrderID, PositionRatio, SpreadedPipBid, SpreadedPipAsk, DirectAggLotCount, IsComputeForHedge, HedgeServerID (PositionHedgeServerID), AmountInUnitsDecimal, OrderType=0, IsTslEnabled, SLManualVer (StopLossVersion), SLManualVerTimestamp (StopLossVersionTimestamp), NextThresHold (TrailingStopLossThreshold), UnitMargin, IsSettled, ReopenForPositionID, GCID, CountryID, UnitsBaseValueCents, IsDiscounted, InitConversionRate

**Rules**:
- WHERE tbl.StatusID=1: only open positions in the payload query
- OperationTypeId=2 = position open (vs 1=close, 3=SL edit)
- Amount multiplied by 100 for cents

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PublishNotification | INT | YES | 1 | CODE-BACKED | 1=insert into SynPositionEndedWithTOError (default), 0=dry-run. Email still sent if records found. |
| 2 | @recipients | VARCHAR(255) | YES | 'tradingbackend@etoro.com;dealing-execution@etoro.com' | CODE-BACKED | Email recipients for HTML alert. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT / UPDATE | Trade.SynPositionTimeOuts | DML read+write | ID=3 watermark |
| SELECT INTO | History.PositionFail | DML read | Open timeout failures (FailTypeID=3) |
| JOIN | History.PositionChangeLog_Active | DML read | ChangeTypeID=0 (open events) |
| JOIN | Trade.PositionTbl | DML read | Confirms position exists; cross-validates OrderID/OrderType |
| CROSS APPLY | Trade.IsUsUser | Function call | Non-US user filter |
| LEFT JOIN | Trade.Position | DML read | Idempotency check (is position still open?) |
| JOIN (payload) | Trade.PositionTreeInfo | DML read | SLManualVer, NextThresHold for payload |
| JOIN (payload) | Customer.CustomerStatic | DML read | GCID, CountryID for payload |
| INSERT | Trade.SynPositionEndedWithTOError | DML write | OpenWithTimeout notification queue |
| EXEC | msdb.dbo.sp_send_dbmail | System SP call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job or external scheduler.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionOpenWithTimeout (procedure)
+-- Trade.SynPositionTimeOuts (table) - watermark ID=3
+-- History.PositionFail (table) - failure source
+-- History.PositionChangeLog_Active (table/view) - ChangeTypeID=0 cross-validation
+-- Trade.PositionTbl (table) - position existence + OrderID/OrderType match
+-- Trade.IsUsUser (function) - non-US filter
+-- Trade.Position (view/table) - idempotency check
+-- Trade.PositionTreeInfo (table) - TSL/SL version data for payload
+-- Customer.CustomerStatic (table) - GCID/CountryID for payload
+-- Trade.SynPositionEndedWithTOError (table) - notification queue
+-- msdb.dbo.sp_send_dbmail (system SP) - email dispatch
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynPositionTimeOuts | Table | ID=3 watermark read/write |
| History.PositionFail | Table | Open timeout failures (FailTypeID=3) |
| History.PositionChangeLog_Active | Table/View | ChangeTypeID=0 + ClientRequestGuid cross-validation |
| Trade.PositionTbl | Table | Position existence check; OrderID/OrderType validation; payload data source |
| Trade.IsUsUser | Function | Non-US user filter |
| Trade.Position | View/Table | Idempotency check - is position still open? |
| Trade.PositionTreeInfo | Table | SLManualVer, SLManualVerTimestamp, NextThresHold for payload |
| Customer.CustomerStatic | Table | GCID, CountryID for payload |
| Trade.SynPositionEndedWithTOError | Table | INSERT OpenWithTimeout notifications |
| msdb.dbo.sp_send_dbmail | System SP | HTML email dispatch |

### 6.2 Objects That Depend On This

No dependents in SSDT repo. Called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A. Temp table #PositionFailOpen uses CLUSTERED INDEX CIX on (ClientRequestGuid).

### 7.2 Constraints

- OPTION(RECOMPILE) on both PositionFail query and the OUTER APPLY query
- Requires StatusID=1 in PositionTbl payload query
- Non-US + non-mirror filters mandatory
- Open payload is the richest of the three timeout SPs (35+ columns)

---

## 8. Sample Queries

### 8.1 Check the open-timeout watermark

```sql
SELECT ID, LastExecute
FROM Trade.SynPositionTimeOuts WITH (NOLOCK)
WHERE ID = 3;
```

### 8.2 Review pending open-timeout notifications

```sql
SELECT TOP 20 MessageType, CAST(Notificationtosend AS VARCHAR(500)) AS Preview, InsertedAt
FROM Trade.SynPositionEndedWithTOError WITH (NOLOCK)
WHERE MessageType = 'OpenWithTimeout'
ORDER BY InsertedAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionOpenWithTimeout | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionOpenWithTimeout.sql*
