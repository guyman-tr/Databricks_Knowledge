# Market.SetMergedDailySchedulesBulk

> Atomically replaces merged daily schedule data for specified dates using delete-then-insert in a transaction. Legacy minutes-precision variant.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk WRITER for MergedDailySchedules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the legacy minutes-precision bulk upsert procedure for `Market.MergedDailySchedules`. It accepts a TVP of type `Market.MergedCalendarTable` containing merged schedule entries, atomically deletes all existing rows for the affected dates, and inserts the new entries - all within a transaction.

This is the older variant that writes `DeltaOpenMins`/`DeltaCloseMins` (integer minutes). The current primary path uses `SetMergedDailySchedulesDeltaSecondsBulk` which writes `DeltaOpenSecs`/`DeltaCloseSecs` (decimal seconds). This procedure may still be called by older code paths or during fallback scenarios.

The atomic delete-and-insert pattern ensures no partial updates: either all dates are fully refreshed or nothing changes (on error, the transaction rolls back).

---

## 2. Business Logic

### 2.1 Atomic Date-Based Replacement

**What**: All existing rows for the affected dates are deleted before new rows are inserted.

**Columns/Parameters Involved**: `@SchedulesToUpdate` (TVP), `Date`

**Rules**:
- DELETE FROM MergedDailySchedules WHERE Date IN (SELECT Date FROM @SchedulesToUpdate)
- INSERT all rows from @SchedulesToUpdate with LogTime = GETDATE()
- Wrapped in BEGIN TRAN / COMMIT with TRY/CATCH for ROLLBACK on error
- This means ALL instruments/exchanges for the affected dates are replaced, not just the ones in the TVP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SchedulesToUpdate | Market.MergedCalendarTable | NO | - | CODE-BACKED | READONLY TVP containing the new merged schedule entries. Contains: SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenMins, DeltaCloseMins, IsManual, HasDailyBreak. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SchedulesToUpdate | Market.MergedCalendarTable | UDT dependency | TVP type definition |
| N/A | Market.MergedDailySchedules | WRITER | DELETE + INSERT target |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MarketCalendar Azure Function | N/A | Caller | Legacy code path for merged schedule updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.SetMergedDailySchedulesBulk (procedure)
├── Market.MergedCalendarTable (type)
└── Market.MergedDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.MergedCalendarTable | User Defined Type | TVP parameter type |
| Market.MergedDailySchedules | Table | DELETE + INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Transaction handles atomicity.

---

## 8. Sample Queries

### 8.1 Call the bulk upsert

```sql
DECLARE @schedules Market.MergedCalendarTable;
INSERT INTO @schedules (SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenMins, DeltaCloseMins, IsManual, HasDailyBreak)
VALUES ('eToro-Defaults', 4, NULL, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', 0, 0, 0, 1);

EXEC Market.SetMergedDailySchedulesBulk @SchedulesToUpdate = @schedules;
```

### 8.2 Verify the replacement worked

```sql
SELECT COUNT(*) AS RowsForDate
FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE Date = '2026-04-14';
```

### 8.3 Check what dates would be affected (dry run)

```sql
DECLARE @schedules Market.MergedCalendarTable;
-- ... populate ...
SELECT DISTINCT Date FROM @schedules ORDER BY Date;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | Legacy variant; the current primary SP is SetMergedDailySchedulesDeltaSecondsBulk which "will check which dates has been passed, remove ALL data for these dates and insert the list." |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.SetMergedDailySchedulesBulk | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.SetMergedDailySchedulesBulk.sql*
