# Market.PureProvidersExchangeDailySchedules

> Archival table storing raw, unprocessed exchange schedule data exactly as received from external providers (Xignite), preserving the original UTC offset for audit and debugging purposes.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ExchangeDailyScheduleID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (NC PK) |

---

## 1. Business Meaning

This table preserves the raw, unmodified exchange schedule data exactly as received from external providers (currently Xignite). While `ProvidersExchangeDailySchedules` stores processed data with eToro exchange IDs and converted UTC times, this table captures the original provider response including the raw UTC offset at the time of the query.

This table exists for audit and debugging purposes. When schedule discrepancies arise (e.g., an instrument was enabled/disabled at the wrong time), the raw provider data can be compared against the processed data to identify where the issue occurred - was it in the provider's response, the timezone conversion, or the merge logic?

**Important data observation**: Despite 27 exchanges being registered in CalendarProviderExchanges, live data shows only US exchanges (ExchangeIDs 4=NASDAQ, 5=NYSE, 20=NYSE segment) are archived here (~5.1K rows). European and other exchanges' raw Xignite responses are NOT preserved in this table. This means raw-data audit capability is limited to US markets only - for non-US exchanges, only the processed data in ProvidersExchangeDailySchedules is available.

Data is written by the ProvideCalendar Azure Function via `SetPureProviderExchangeCalendarBulk`, which takes the ExchangeID as a separate parameter and atomically replaces all existing data for that exchange on the affected dates. No temporal versioning - this is a simple archival table.

---

## 2. Business Logic

### 2.1 UTC Offset Preservation

**What**: Unlike other schedule tables, this table captures the raw UTC offset from the provider response.

**Columns/Parameters Involved**: `UTCOffset`, `OpenTimeUTC`, `CloseTimeUTC`

**Rules**:
- UTCOffset is the hour offset from UTC at the time of the provider query (e.g., -4.000 for EDT, -5.000 for EST)
- This captures DST state, enabling verification of timezone conversions
- Both local and UTC times are stored alongside the offset for complete audit trail

---

## 3. Data Overview

~5.1K rows. Raw Xignite data archived with UTC offsets. Only covers US exchanges (IDs 4, 5, 20):

| ExchangeID | Date | IsOpen | OpenTimeUTC | CloseTimeUTC | UTCOffset | OccurredAt | Meaning |
|---|---|---|---|---|---|---|---|
| 20 | 2026-05-11 | 1 | 13:30 | 20:00 | -4.000 | 2026-04-12 00:06 | NYSE segment open. UTCOffset=-4 confirms EDT (summer). |
| 4 | 2026-05-11 | 1 | 13:30 | 20:00 | -4.000 | 2026-04-12 00:06 | NASDAQ open same hours as NYSE. |
| 5 | 2026-05-10 | 0 | 04:00 | 04:00 | -4.000 | 2026-04-11 00:06 | NYSE closed (Sunday). Open=Close=04:00 is the "closed" sentinel. |
| 4 | 2026-05-08 | 1 | 13:30 | 20:00 | -4.000 | 2026-04-09 00:06 | NASDAQ open on Friday. Queried 30 days ahead. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeDailyScheduleID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. Passed as @ExchangeID parameter to the bulk SP (not in the TVP). |
| 3 | Date | date | NO | - | CODE-BACKED | Calendar date for this raw schedule entry. |
| 4 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange is open per the provider's response. |
| 5 | OpenTime | datetime | NO | - | CODE-BACKED | Exchange open time in local timezone as reported by the provider. Raw, unprocessed. |
| 6 | CloseTime | datetime | NO | - | CODE-BACKED | Exchange close time in local timezone. Raw, unprocessed. |
| 7 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Exchange open time in UTC as converted by the provider or the ingestion function. |
| 8 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Exchange close time in UTC. |
| 9 | UTCOffset | decimal(5,3) | NO | - | CODE-BACKED | UTC offset in hours at the time of the provider query. Captures DST state. E.g., -5.000=EST, -4.000=EDT, +1.000=CET. Preserved for audit trail. |
| 10 | OccurredAt | datetime | NO | - | CODE-BACKED | Timestamp when the raw data was received/stored. Set to GETUTCDATE() by the bulk SP. Records when the provider was queried. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Market.CalendarProviderExchanges | Implicit FK | References a registered provider exchange |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetPureProviderExchangeCalendarBulk | N/A | WRITER | Bulk deletes + inserts raw provider data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetPureProviderExchangeCalendarBulk | Stored Procedure | WRITER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PureProvidersExchangeDailySchedules | NC PK | ExchangeDailyScheduleID | - | - | Active |

### 7.2 Constraints

None beyond PK.

**Note**: No temporal versioning. No triggers. No clustered index on Date (unlike the processed schedule tables).

---

## 8. Sample Queries

### 8.1 View raw provider data for an exchange

```sql
SELECT TOP 10 ExchangeID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, UTCOffset, OccurredAt
FROM Market.PureProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY Date DESC;
```

### 8.2 Audit: compare raw vs processed UTC times

```sql
SELECT p.Date, p.OpenTimeUTC AS RawOpenUTC, p.UTCOffset,
       pe.OpenTimeUTC AS ProcessedOpenUTC
FROM Market.PureProvidersExchangeDailySchedules p WITH (NOLOCK)
JOIN Market.ProvidersExchangeDailySchedules pe WITH (NOLOCK)
    ON p.ExchangeID = pe.ExchangeID AND p.Date = pe.Date AND pe.ProviderID = 1
WHERE p.ExchangeID = 4
ORDER BY p.Date DESC;
```

### 8.3 Check UTCOffset variation (DST transitions)

```sql
SELECT ExchangeID, UTCOffset, MIN(Date) AS FirstDate, MAX(Date) AS LastDate, COUNT(*) AS Days
FROM Market.PureProvidersExchangeDailySchedules WITH (NOLOCK)
GROUP BY ExchangeID, UTCOffset
ORDER BY ExchangeID, UTCOffset;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | "Holds Market Hours information that was received from providers." Raw provider data archival table. |
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | ProvideCalendar function reads from Xignite and writes raw data here, then publishes to MarketCalendar queue. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.PureProvidersExchangeDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.PureProvidersExchangeDailySchedules.sql*
