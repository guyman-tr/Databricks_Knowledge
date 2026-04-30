# Trade.FunPositionEditSLWithTimeout

> Returns Stop Loss (SL) edit operations that failed due to database execution timeout, for recovery and notification to the trading backend.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns table with CID, PositionID, FailOccurred, Notificationtosend |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunPositionEditSLWithTimeout identifies position Stop Loss edits that failed because the database operation exceeded its execution timeout. It joins History.PositionFail (FailTypeID=5 for SL edit failures) with History.PositionChangeLog_Active (ChangeTypeID=1 for Stop Rate edits) and filters for "Error editing Stop Loss - DB failure" and "Execution Timeout Expired" in FailReason. Non-mirror positions only (MirrorID=0).

This function exists to support the recovery pipeline: when a user edits their Stop Loss and the DB times out, the change may be recorded in PositionChangeLog but the trade engine did not receive confirmation. Operations need to identify these cases to re-send notifications or retry. Without it, positions could have stale or missing SL levels after timeout events.

Data flows: Trade.PositionEditSLWithTimeout procedure queries this function to find affected positions and publishes notifications via Trade.SynPositionEndedWithTOError. The function returns a Notificationtosend column containing XML for the trade backend; it is NULL when the position's current StopRate already differs from the logged NewStopRate (recovery already applied).

---

## 2. Business Logic

### 2.1 Fail–Change Correlation

**What**: Match position failures to the corresponding change log entries using ClientRequestGuid or time proximity.

**Columns/Parameters Involved**: `ClientRequestGuid`, `FailOccurred`, `Occurred`, `PositionID`, `CID`

**Rules**:
- JOIN on CID, ClientRequestGuid, PositionID when ClientRequestGuid != all-zeros
- When ClientRequestGuid = 00000000-0000-0000-0000-000000000000: match if FailOccurred is within ±1 minute of Occurred
- MirrorID=0 excludes CopyTrading positions from this recovery path

**Diagram**:
```
History.PositionFail (FailTypeID=5, SL edit)  ←→  History.PositionChangeLog_Active (ChangeTypeID=1)
         ↑                                                      ↑
    FailOccurred                                           Occurred
    FailReason like 'Error editing Stop Loss...'           StopRate, AmountChanged
```

### 2.2 Notificationtosend Suppression

**What**: Only send notification when the position's current StopRate still matches the logged NewStopRate.

**Columns/Parameters Involved**: `Notificationtosend`, `StopRate`, `NewStopRate`

**Rules**:
- LEFT JOIN Trade.Position to get current StopRate
- Notificationtosend = NULL when ISNULL(p.StopRate,-1) <> ISNULL(cte.NewStopRate,-2) — position was already updated, no retry needed
- Otherwise Notificationtosend holds XML for TradingDbPositionNotification (OperationTypeId=3 = Edit Position)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @startTime | datetime | NO | - | CODE-BACKED | Start of the time window. FailOccurred and Occurred must be >= this value. |
| 2 | @Endtime | datetime | NO | - | CODE-BACKED | End of the time window. FailOccurred and Occurred must be <= this value. |
| 3 | Notificationtosend | varchar(8000) | YES | - | CODE-BACKED | XML payload for TradingDbPositionNotification (OperationTypeId=3). NULL when p.StopRate <> cte.NewStopRate (already recovered). |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. Customer whose position SL edit failed. |
| 5 | FailOccurred | datetime2(7) | YES | - | CODE-BACKED | When the failure was recorded in History.PositionFail. |
| 6 | PositionFailID | bigint | YES | - | CODE-BACKED | Primary key of the History.PositionFail row. |
| 7 | PositionID | bigint | YES | - | CODE-BACKED | The position whose SL edit timed out. References Trade.Position. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | Instrument of the position. References Trade.Instrument. |
| 9 | FailReason | varchar | YES | - | CODE-BACKED | Extracted substring from FailReason containing "Message:" content. Used for reporting. |
| 10 | Status | int | NO | 0 | CODE-BACKED | Placeholder; always 0. |
| 11 | NewStopRate | float | YES | - | CODE-BACKED | The requested new Stop Loss rate from PositionChangeLog. Used to compare with current StopRate. |
| 12 | AmountChanged | float | YES | - | CODE-BACKED | Amount change from the SL edit (from PositionChangeLog). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | JOIN | Current position to check StopRate |
| CID | Customer.CustomerStatic | Implicit | Customer owning the position |
| InstrumentID | Trade.Instrument | Implicit | Instrument of the position |
| History.PositionFail | History.PositionFail | FROM/JOIN | Source of timeout failures (FailTypeID=5) |
| History.PositionChangeLog_Active | History.PositionChangeLog_Active | JOIN | Source of SL edit change records (ChangeTypeID=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionEditSLWithTimeout | - | Procedure | Procedure embeds similar logic; references function in DROP comment. Not a direct CROSS APPLY caller in current code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunPositionEditSLWithTimeout (function)
├── History.PositionFail (table)
├── History.PositionChangeLog_Active (view)
├── Trade.Position (table)
└── Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFail | Table | FROM/JOIN — FailTypeID=5, FailReason filter |
| History.PositionChangeLog_Active | View | JOIN — ChangeTypeID=1, StopRate, AmountChanged |
| Trade.Position | Table | LEFT JOIN — current StopRate comparison |
| Trade.PositionTreeInfo | Table | INNER JOIN in OUTER APPLY — SL version, TrailingStopLossThreshold |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionEditSLWithTimeout | Stored Procedure | Inline logic mirrors function; DROP comment references function |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 SL edit timeouts in the last hour
```sql
SELECT *
FROM Trade.FunPositionEditSLWithTimeout(
    DATEADD(HOUR, -1, GETUTCDATE()),
    GETUTCDATE()
) WITH (NOLOCK);
```

### 8.2 Count SL edit timeouts by day
```sql
SELECT CONVERT(DATE, FailOccurred) AS FailDate, COUNT(*) AS TimeoutCount
FROM Trade.FunPositionEditSLWithTimeout(
    CAST(GETUTCDATE() - 7 AS DATE),
    GETUTCDATE()
) f
GROUP BY CONVERT(DATE, FailOccurred)
ORDER BY FailDate DESC;
```

### 8.3 Rows needing notification (non-NULL Notificationtosend)
```sql
SELECT CID, PositionID, InstrumentID, FailOccurred, FailReason
FROM Trade.FunPositionEditSLWithTimeout(
    DATEADD(HOUR, -2, GETUTCDATE()),
    GETUTCDATE()
) f
WHERE Notificationtosend IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.FunPositionEditSLWithTimeout | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunPositionEditSLWithTimeout.sql*
