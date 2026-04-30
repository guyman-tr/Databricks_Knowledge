# Market.SetProviderExchangeCalendarBulk

> Atomically replaces provider-sourced exchange daily schedule data for a specific provider and date range, used by the ProvideCalendar Azure Function to persist Xignite data and by CM for overrides.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk WRITER for ProvidersExchangeDailySchedules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure bulk-inserts exchange-level daily schedule data into `Market.ProvidersExchangeDailySchedules`. It is called by the ProvideCalendar Azure Function after querying Xignite's API, and by Configuration Manager when dealers save exchange-level overrides.

The procedure atomically deletes existing rows for the given provider and affected dates, then inserts the new data. This ensures clean replacement without duplicates. Per Confluence: "Write to MarketHoursDB (using SP Market.SetProviderExchangeCalendarBulk that writes to table Market.ProvidersExchangeDailySchedules)."

---

## 2. Business Logic

### 2.1 Provider-Scoped Date Replacement

**What**: Deletes only rows matching the provider AND the affected dates, preserving other providers' data.

**Columns/Parameters Involved**: `@ProviderID`, `@SchedulesToUpdate` (TVP), `Date`

**Rules**:
- DELETE FROM ProvidersExchangeDailySchedules WHERE ProviderID=@ProviderID AND Date IN (dates from TVP)
- INSERT all rows from TVP with LogTime = GETDATE() and @ProviderID
- Scoped to one provider: Xignite data (ProviderID=1) does not delete eToro overrides (ProviderID=0) and vice versa
- Transaction-wrapped for atomicity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SchedulesToUpdate | Market.ProviderExchangeCalendarTable | NO | - | CODE-BACKED | READONLY TVP containing exchange schedule entries: ExchangeID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC. |
| 2 | @ProviderID | int | NO | - | VERIFIED | Provider identifier. 0 = eToro override from CM, 1 = Xignite from ProvideCalendar function. Applied to all inserted rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SchedulesToUpdate | Market.ProviderExchangeCalendarTable | UDT dependency | TVP type |
| N/A | Market.ProvidersExchangeDailySchedules | WRITER | DELETE + INSERT target |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ProvideCalendar Azure Function | TimeTriggeredCalendar | Caller | Writes Xignite data daily |
| Configuration Manager | Edit Overrides | Caller | Writes eToro exchange overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.SetProviderExchangeCalendarBulk (procedure)
├── Market.ProviderExchangeCalendarTable (type)
└── Market.ProvidersExchangeDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.ProviderExchangeCalendarTable | User Defined Type | TVP parameter type |
| Market.ProvidersExchangeDailySchedules | Table | DELETE + INSERT target |

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

### 8.1 Insert Xignite exchange data

```sql
DECLARE @schedules Market.ProviderExchangeCalendarTable;
INSERT INTO @schedules (ExchangeID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC)
VALUES (4, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00');

EXEC Market.SetProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ProviderID = 1;
```

### 8.2 Insert eToro exchange override

```sql
DECLARE @schedules Market.ProviderExchangeCalendarTable;
INSERT INTO @schedules (ExchangeID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC)
VALUES (4, '2026-12-24', 1, '2026-12-24 09:30:00', '2026-12-24 13:00:00', '2026-12-24 14:30:00', '2026-12-24 18:00:00');

EXEC Market.SetProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ProviderID = 0;
```

### 8.3 Verify inserted data

```sql
SELECT ProviderID, ExchangeID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4 AND Date = '2026-04-14'
ORDER BY ProviderID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | ProvideCalendar function "Write to MarketHoursDB using SP Market.SetProviderExchangeCalendarBulk." |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "Written by Provider Calendar function (through SetProviderExchangeCalendarBulk Stored procedure)." |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.SetProviderExchangeCalendarBulk | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.SetProviderExchangeCalendarBulk.sql*
