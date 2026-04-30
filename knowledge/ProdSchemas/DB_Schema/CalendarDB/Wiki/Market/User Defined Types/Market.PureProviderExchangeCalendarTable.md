# Market.PureProviderExchangeCalendarTable

> Table-valued parameter type used to pass raw, unprocessed provider exchange schedule data to the SetPureProviderExchangeCalendarBulk stored procedure for archival into PureProvidersExchangeDailySchedules.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite: Date + IsOpen |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This UDT defines the shape of data passed to the `Market.SetPureProviderExchangeCalendarBulk` stored procedure. It carries the raw, unmodified exchange schedule data exactly as received from an external provider (Xignite), before any eToro-specific processing, timezone conversion, or merging.

This type exists for audit and debugging purposes. While `ProviderExchangeCalendarTable` carries processed data (with eToro exchange IDs and UTC conversions), this type preserves the original provider response including the raw UTC offset. If schedule discrepancies arise, the PureProviders data can be compared against the processed data to identify where the issue occurred.

Data flow: Xignite REST API -> ProvideCalendar Azure Function -> `Market.PureProviderExchangeCalendarTable` TVP -> `Market.SetPureProviderExchangeCalendarBulk` SP -> `Market.PureProvidersExchangeDailySchedules` table. The ExchangeID is passed as a separate scalar parameter since all rows in a batch are for the same exchange.

---

## 2. Business Logic

### 2.1 UTC Offset Preservation

**What**: Unlike other schedule types, this TVP captures the raw UTC offset from the provider, preserving the original timezone context.

**Columns/Parameters Involved**: `UTCOffset`, `OpenTime`, `CloseTime`, `OpenTimeUTC`, `CloseTimeUTC`

**Rules**:
- UTCOffset captures the exact offset used by the provider at query time, accounting for DST
- Local times and UTC times are both stored, with UTCOffset documenting the conversion factor
- This allows verification that the ProvideCalendar function's timezone conversions were correct

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | date | NO | - | CODE-BACKED | The specific calendar date for this schedule entry. |
| 2 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange is open on this date according to the provider. 0 = closed, 1 = open. |
| 3 | OpenTime | datetime | NO | - | CODE-BACKED | Exchange open time in local timezone as reported by the provider. Raw, unprocessed value. |
| 4 | CloseTime | datetime | NO | - | CODE-BACKED | Exchange close time in local timezone as reported by the provider. Raw, unprocessed value. |
| 5 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Exchange open time in UTC as reported or converted by the provider. |
| 6 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Exchange close time in UTC as reported or converted by the provider. |
| 7 | UTCOffset | decimal(5,3) | NO | - | CODE-BACKED | The UTC offset in hours used for the timezone conversion at the time of the provider query. Captures DST state. For example, -5.000 for EST, -4.000 for EDT, +1.000 for CET. Preserved for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetPureProviderExchangeCalendarBulk | @SchedulesToUpdate parameter | TVP Parameter | This UDT defines the parameter shape for raw provider data archival |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetPureProviderExchangeCalendarBulk | Stored Procedure | Accepts this type as @SchedulesToUpdate READONLY parameter |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for raw provider data

```sql
DECLARE @schedules Market.PureProviderExchangeCalendarTable;

INSERT INTO @schedules (Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, UTCOffset)
VALUES ('2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', -4.000);
```

### 8.2 Call the bulk upsert for NASDAQ exchange (ExchangeID=4)

```sql
DECLARE @schedules Market.PureProviderExchangeCalendarTable;
-- ... populate with Xignite XNAS response data ...
EXEC Market.SetPureProviderExchangeCalendarBulk @SchedulesToUpdate = @schedules, @ExchangeID = 4;
```

### 8.3 Audit: compare pure vs processed provider data

```sql
SELECT p.Date, p.OpenTimeUTC AS PureOpenUTC, p.UTCOffset,
       pe.OpenTimeUTC AS ProcessedOpenUTC
FROM Market.PureProvidersExchangeDailySchedules p WITH (NOLOCK)
JOIN Market.ProvidersExchangeDailySchedules pe WITH (NOLOCK)
    ON p.ExchangeID = pe.ExchangeID AND p.Date = pe.Date AND pe.ProviderID = 1
WHERE p.ExchangeID = 4
ORDER BY p.Date DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | PureProvidersExchangeDailySchedules holds market hours information received from providers (raw data) |
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | ProvideCalendar function reads from Xignite and archives raw data |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.PureProviderExchangeCalendarTable | Type: User Defined Type | Source: CalendarDB/CalendarDB/Market/User Defined Types/Market.PureProviderExchangeCalendarTable.sql*
