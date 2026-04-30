# Market.ProviderExchangeCalendarTable

> Table-valued parameter type used to pass provider-sourced exchange daily schedule data to the SetProviderExchangeCalendarBulk stored procedure for bulk upsert into ProvidersExchangeDailySchedules.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite: ExchangeID + Date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This UDT defines the shape of data passed to the `Market.SetProviderExchangeCalendarBulk` stored procedure. It carries raw exchange-level daily schedule data from an external calendar provider (currently Xignite) or from eToro manual overrides (ProviderID=0).

Without this type, the ProvideCalendar Azure Function could not efficiently bulk-insert exchange schedule data received from the Xignite API. It serves as the contract between the ProvideCalendar function and the database. The function queries Xignite's `IsExchangeOpenOnDate` REST API for each exchange for 7 upcoming days, collects the results, and sends them via this TVP.

Data flow: Xignite REST API -> ProvideCalendar Azure Function -> `Market.ProviderExchangeCalendarTable` TVP -> `Market.SetProviderExchangeCalendarBulk` SP -> `Market.ProvidersExchangeDailySchedules` table. The ProviderID is passed as a separate scalar parameter to the SP (not in the TVP), since all rows in a single batch come from the same provider.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a straightforward data-transfer type. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. Maps to the exchange whose schedule is being provided. The ProvideCalendar function reads exchange mappings from Market.CalendarProviderExchanges to know which exchanges to query from Xignite. |
| 2 | Date | date | NO | - | CODE-BACKED | The specific calendar date for this schedule entry. Xignite is queried for 7 upcoming days per exchange. |
| 3 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange is open on this date according to the provider. 0 = closed (holiday/weekend), 1 = open. |
| 4 | OpenTime | datetime | NO | - | CODE-BACKED | Exchange open time in local timezone as reported by the provider. |
| 5 | CloseTime | datetime | NO | - | CODE-BACKED | Exchange close time in local timezone as reported by the provider. |
| 6 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Exchange open time converted to UTC using the timezone from Market.ExchangeTimeZones. |
| 7 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Exchange close time converted to UTC using the timezone from Market.ExchangeTimeZones. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetProviderExchangeCalendarBulk | @SchedulesToUpdate parameter | TVP Parameter | This UDT defines the parameter shape for provider exchange calendar bulk upsert |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetProviderExchangeCalendarBulk | Stored Procedure | Accepts this type as @SchedulesToUpdate READONLY parameter |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for a provider exchange calendar

```sql
DECLARE @schedules Market.ProviderExchangeCalendarTable;

INSERT INTO @schedules (ExchangeID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC)
VALUES (4, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00');
```

### 8.2 Call the bulk upsert for Xignite (ProviderID=1)

```sql
DECLARE @schedules Market.ProviderExchangeCalendarTable;
-- ... populate @schedules with Xignite data ...
EXEC Market.SetProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ProviderID = 1;
```

### 8.3 Call the bulk upsert for eToro overrides (ProviderID=0)

```sql
DECLARE @schedules Market.ProviderExchangeCalendarTable;
-- ... populate @schedules with manual override data ...
EXEC Market.SetProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ProviderID = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | ProvideCalendar function reads from Xignite and writes to ProvidersExchangeDailySchedules via SetProviderExchangeCalendarBulk |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | ProvidersExchangeDailySchedules written by ProvideCalendar function and CM Overrides (ProviderID=0) |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.ProviderExchangeCalendarTable | Type: User Defined Type | Source: CalendarDB/CalendarDB/Market/User Defined Types/Market.ProviderExchangeCalendarTable.sql*
