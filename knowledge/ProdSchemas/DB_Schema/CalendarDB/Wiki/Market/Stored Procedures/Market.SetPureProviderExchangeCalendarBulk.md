# Market.SetPureProviderExchangeCalendarBulk

> Atomically replaces raw, unprocessed provider exchange schedule data for a specific exchange, archiving the original Xignite response with UTC offset for audit purposes.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk WRITER for PureProvidersExchangeDailySchedules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure bulk-inserts raw, unmodified provider exchange schedule data into `Market.PureProvidersExchangeDailySchedules`. It is called by the ProvideCalendar Azure Function to archive the exact data received from Xignite before any eToro-specific processing.

The procedure atomically deletes existing rows for the given exchange and affected dates, then inserts the new raw data with `OccurredAt = GETUTCDATE()`. This preserves the original provider response including the UTC offset for debugging and audit.

---

## 2. Business Logic

### 2.1 Exchange-Scoped Date Replacement

**What**: Deletes only rows matching the exchange AND affected dates.

**Columns/Parameters Involved**: `@ExchangeID`, `@SchedulesToUpdate` (TVP), `Date`

**Rules**:
- DELETE FROM PureProvidersExchangeDailySchedules WHERE ExchangeID=@ExchangeID AND Date IN (dates from TVP)
- INSERT all rows from TVP with OccurredAt = GETUTCDATE() and @ExchangeID
- Transaction-wrapped for atomicity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SchedulesToUpdate | Market.PureProviderExchangeCalendarTable | NO | - | CODE-BACKED | READONLY TVP containing raw provider data: Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, UTCOffset. |
| 2 | @ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. Applied to all inserted rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SchedulesToUpdate | Market.PureProviderExchangeCalendarTable | UDT dependency | TVP type |
| N/A | Market.PureProvidersExchangeDailySchedules | WRITER | DELETE + INSERT target |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ProvideCalendar Azure Function | TimeTriggeredCalendar | Caller | Archives raw Xignite response daily |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.SetPureProviderExchangeCalendarBulk (procedure)
├── Market.PureProviderExchangeCalendarTable (type)
└── Market.PureProvidersExchangeDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.PureProviderExchangeCalendarTable | User Defined Type | TVP parameter type |
| Market.PureProvidersExchangeDailySchedules | Table | DELETE + INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Transaction-based atomicity.

---

## 8. Sample Queries

### 8.1 Archive raw NASDAQ schedule data

```sql
DECLARE @schedules Market.PureProviderExchangeCalendarTable;
INSERT INTO @schedules (Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, UTCOffset)
VALUES ('2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', -4.000);

EXEC Market.SetPureProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ExchangeID = 4;
```

### 8.2 Verify archived data

```sql
SELECT ExchangeID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC, UTCOffset, OccurredAt
FROM Market.PureProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY Date DESC;
```

### 8.3 Compare with processed data for audit

```sql
SELECT p.Date, p.UTCOffset, p.OpenTimeUTC AS RawUTC, pe.OpenTimeUTC AS ProcessedUTC
FROM Market.PureProvidersExchangeDailySchedules p WITH (NOLOCK)
JOIN Market.ProvidersExchangeDailySchedules pe WITH (NOLOCK) ON p.ExchangeID = pe.ExchangeID AND p.Date = pe.Date
WHERE p.ExchangeID = 4 AND pe.ProviderID = 1
ORDER BY p.Date DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | ProvideCalendar function archives raw data to PureProvidersExchangeDailySchedules. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.SetPureProviderExchangeCalendarBulk | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.SetPureProviderExchangeCalendarBulk.sql*
