# Market.SetMergedDailySchedulesDeltaSecondsBulk

> Primary procedure for atomically replacing merged daily schedule data using seconds-precision delta offsets. Called by the MarketCalendar Azure Function after each merge calculation.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk WRITER for MergedDailySchedules (primary path) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the **current primary** bulk upsert procedure for `Market.MergedDailySchedules`. It accepts a TVP of type `Market.MergedCalendarDeltaSecondsTable` containing merged schedule entries with seconds-precision delta offsets, atomically deletes all existing rows for the affected dates, and inserts the new entries within a transaction.

Per Confluence: "After the list of the MergedDailyCalendars is calculated we update the Market.MergedDailySchedules table with the following SP: [Market].[SetMergedDailySchedulesDeltaSecondsBulk]." This is the SP that the MarketCalendar Azure Function calls after every merge calculation. After the insert completes, a `Market.Calendar.Update` notification is published to RabbitMQ.

---

## 2. Business Logic

### 2.1 Atomic Date-Based Replacement

**What**: All existing rows for affected dates are replaced atomically.

**Columns/Parameters Involved**: `@SchedulesToUpdate` (TVP), `Date`

**Rules**:
- DELETE FROM MergedDailySchedules WHERE Date IN (SELECT Date FROM @SchedulesToUpdate)
- INSERT all rows with LogTime = GETDATE(), writing to DeltaOpenSecs/DeltaCloseSecs columns
- Transaction ensures atomicity: ROLLBACK on any error
- The delete scope is date-based: ALL instruments/exchanges for those dates are removed and replaced

### 2.2 Post-Update Notification

**What**: After successful insert, the MarketCalendar function publishes a RabbitMQ message.

**Rules**:
- SP itself does not publish the message - the application does after SP completes
- RMQ Exchange: MarketHoursExchange, Routing Key: Market.Calendar.Update
- MarketHours Service subscribes and reloads affected dates from MergedDailySchedules

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SchedulesToUpdate | Market.MergedCalendarDeltaSecondsTable | NO | - | VERIFIED | READONLY TVP containing the new merged schedule entries with seconds-precision deltas. Contains: SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenSecs, DeltaCloseSecs, IsManual, HasDailyBreak. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SchedulesToUpdate | Market.MergedCalendarDeltaSecondsTable | UDT dependency | TVP type definition |
| N/A | Market.MergedDailySchedules | WRITER | DELETE + INSERT target |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MarketCalendar Azure Function | ConfigurationCalendarUpdateTrigger | Caller | Primary caller after every merge calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.SetMergedDailySchedulesDeltaSecondsBulk (procedure)
├── Market.MergedCalendarDeltaSecondsTable (type)
└── Market.MergedDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.MergedCalendarDeltaSecondsTable | User Defined Type | TVP parameter type |
| Market.MergedDailySchedules | Table | DELETE + INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Transaction-based atomicity via BEGIN TRAN/COMMIT/ROLLBACK.

---

## 8. Sample Queries

### 8.1 Call the primary bulk upsert

```sql
DECLARE @schedules Market.MergedCalendarDeltaSecondsTable;
INSERT INTO @schedules (SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenSecs, DeltaCloseSecs, IsManual, HasDailyBreak)
VALUES ('eToro-Defaults', 4, NULL, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', 0, 60.000, 0, 1);

EXEC Market.SetMergedDailySchedulesDeltaSecondsBulk @SchedulesToUpdate = @schedules;
```

### 8.2 Verify update succeeded

```sql
SELECT TOP 5 * FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE Date = '2026-04-14' ORDER BY ExchangeID, InstrumentID;
```

### 8.3 Check temporal history for replaced rows

```sql
SELECT ID, Date, ExchangeID, InstrumentID, ValidFrom, ValidTo
FROM Market.MergedDailySchedules
FOR SYSTEM_TIME ALL
WHERE Date = '2026-04-14'
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "After the list of MergedDailyCalendars is calculated we update Market.MergedDailySchedules table with SP [Market].[SetMergedDailySchedulesDeltaSecondsBulk]. The SP will check which dates has been passed. It will remove ALL data existing in the table for these dates and insert the list." Post-update notification published to RabbitMQ. |
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | MarketCalendar function calls this SP. Post-update: RMQ Price/MarketHoursExchange, routing key Market.Calendar.Update. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.SetMergedDailySchedulesDeltaSecondsBulk | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.SetMergedDailySchedulesDeltaSecondsBulk.sql*
