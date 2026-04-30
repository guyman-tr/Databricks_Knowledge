# Trade.FunPositionOpenWithTimeout

> Returns position open operations that failed due to database execution timeout ( FailTypeID 3 ) for a given time window, with recovery notification payload for the trade backend.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns table (CID, FailOccurred, PositionID, InstrumentID, FailReason, Status, Notificationtosend) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunPositionOpenWithTimeout identifies position open attempts that failed due to SQL Server execution timeout. When a position open request encounters "Error opening position - DB failure" with "Execution Timeout Expired", the failure is logged in History.PositionFail with FailTypeID=3 (open failure) and a corresponding change log entry in History.PositionChangeLog_Active with ChangeTypeID=0 (position open). This function correlates those failures with the intended position data and produces an XML notification payload so the trade backend can retry or reconcile the open.

The function exists to support recovery procedures (e.g., Trade.PositionOpenWithTimeout) that run on a schedule to detect and re-process timed-out open attempts. Without it, positions that failed due to transient DB load would remain in an inconsistent state — the user may believe the order succeeded while the system did not complete the open.

Data flow: History.PositionFail (FailTypeID=3) is JOINed with History.PositionChangeLog_Active (ChangeTypeID=0) on CID, ClientRequestGuid, and optionally matched by time and amount when ClientRequestGuid is empty. Only non-mirror positions (MirrorID=0) are included. The function returns rows with a TradingDbPositionNotification XML payload for positions that still exist in Trade.PositionTbl (StatusID=1).

---

## 2. Business Logic

### 2.1 Timeout Failure Correlation

**What**: Failures are matched to change log entries by ClientRequestGuid or, when absent, by temporal proximity (±1 minute) and matching amount/ParentPositionID/InitForexPriceRateID.

**Columns/Parameters Involved**: `@startTime`, `@endTime`, `ClientRequestGuid`, `FailOccurred`, `Occurred`, `UnitsBaseValueCents`, `Amount`, `ParentPositionID`, `LastOpPriceRateID`, `InitForexPriceRateID`

**Rules**:
- FailOccurred and Occurred must fall within the parameter window
- FailReason must match: "Error opening position - DB failure%" AND "%Execution Timeout Expired%"
- MirrorID=0 (no CopyTrading positions)
- When ClientRequestGuid is all-zero: match FailOccurred within ±1 minute of Occurred, UnitsBaseValueCents/100 = Amount, ParentPositionID = hpf.ParentPositionID, InitForexPriceRateID = pcl.LastOpPriceRateID

**Diagram**:
```
History.PositionFail (FailTypeID=3)
       │
       ├─ JOIN History.PositionChangeLog_Active (ChangeTypeID=0)
       │         ON CID, ClientRequestGuid [or time+amount match]
       │
       └─ LEFT JOIN Trade.PositionTbl — if PositionID exists and StatusID=1 → include Notificationtosend
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @startTime | datetime | NO | - | CODE-BACKED | Start of the time window. Failures and change log entries must have FailOccurred/Occurred within [startTime, endTime]. |
| 2 | @endTime | datetime | NO | - | CODE-BACKED | End of the time window. Inclusive upper bound for the query filter. |
| 3 | Notificationtosend | varchar(8000) | YES | - | CODE-BACKED | XML notification payload for the trade backend. NULL when PositionID does not exist or is not open (StatusID≠1). OperationTypeId=2 (PositionOpen). Contains TradingData with PositionID, CID, InstrumentID, TreeID, LimitRate, StopRate, IsBuy, InitDateTime, MirrorID, Leverage, LotCountDecimal, etc. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. The user whose position open timed out. |
| 5 | FailOccurred | datetime2(7) | NO | - | CODE-BACKED | When the failure was logged. Used for correlation and reporting. |
| 6 | PositionFailID | bigint | NO | - | CODE-BACKED | Surrogate key of History.PositionFail row. |
| 7 | PositionID | bigint | NO | - | CODE-BACKED | The position (or intended position) that failed to open. From PositionChangeLog. |
| 8 | InstrumentID | int | NO | - | CODE-BACKED | Instrument that was being opened. FK to Trade.Instrument. |
| 9 | FailReason | varchar(max) | YES | - | CODE-BACKED | Extracted substring from hpf.FailReason between "Message:" and the next "." — human-readable error snippet. |
| 10 | Status | int | NO | 0 | CODE-BACKED | Hard-coded 0. Placeholder for status flag (e.g., recovery state). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer whose open timed out |
| PositionID | Trade.Position / History.PositionChangeLog | Implicit | Position or intended position |
| InstrumentID | Trade.Instrument | Implicit | Instrument being traded |
| History.PositionFail | - | JOIN | Failures with FailTypeID=3 |
| History.PositionChangeLog_Active | - | JOIN | Change log entries with ChangeTypeID=0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpenWithTimeout | - | FROM/CROSS APPLY | Recovery procedure calls this function and processes results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunPositionOpenWithTimeout (function)
├── History.PositionFail (table)
├── History.PositionChangeLog_Active (view)
│     └── History.PositionChangeLog_Active_BIGINT (table)
├── Trade.PositionTbl (table)
├── Trade.PositionTreeInfo (table)
├── Customer.CustomerStatic (table)
└── Trade.Position (synonym/view of PositionTbl)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFail | Table | JOIN — FailTypeID=3, FailReason filter |
| History.PositionChangeLog_Active | View | JOIN — ChangeTypeID=0, correlation |
| Trade.PositionTbl | Table | LEFT JOIN — current position data for notification |
| Trade.PositionTreeInfo | Table | JOIN — TreeID for notification XML |
| Customer.CustomerStatic | Table | JOIN — CID for notification XML |
| Trade.Position | Synonym/View | LEFT JOIN — StopRate check for open positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpenWithTimeout | Stored Procedure | Calls function in FROM/CROSS APPLY for recovery flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find timed-out opens for the last 2 hours

```sql
DECLARE @Start DATETIME = DATEADD(HOUR, -2, GETUTCDATE()),
        @End   DATETIME = GETUTCDATE();

SELECT CID, FailOccurred, PositionFailID, PositionID, InstrumentID, FailReason, Status,
       CASE WHEN Notificationtosend IS NOT NULL THEN 'Has payload' ELSE 'No payload' END AS PayloadStatus
FROM Trade.FunPositionOpenWithTimeout(@Start, @End) WITH (NOLOCK)
ORDER BY FailOccurred DESC;
```

### 8.2 Count failures by instrument

```sql
SELECT InstrumentID, COUNT(*) AS FailCount
FROM Trade.FunPositionOpenWithTimeout(
    DATEADD(HOUR, -24, GETUTCDATE()),
    GETUTCDATE()
) WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY FailCount DESC;
```

### 8.3 Recover notification payloads for open positions only

```sql
SELECT CID, PositionID, FailOccurred, Notificationtosend
FROM Trade.FunPositionOpenWithTimeout(
    CAST(GETUTCDATE() AS DATE),
    GETUTCDATE()
) WITH (NOLOCK)
WHERE Notificationtosend IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FunPositionOpenWithTimeout | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunPositionOpenWithTimeout.sql*
