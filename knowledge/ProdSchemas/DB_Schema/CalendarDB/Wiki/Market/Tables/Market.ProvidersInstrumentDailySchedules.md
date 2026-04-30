# Market.ProvidersInstrumentDailySchedules

> Stores daily instrument-level trading schedule overrides from eToro dealers (ProviderID=0), used as the highest-precedence input to the merged schedule calculation.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 NC PK + 1 Clustered on Date) |

---

## 1. Business Meaning

This table stores instrument-specific daily schedule overrides. Per Confluence: "At the moment only eToro overrides (provider=0) are saved here, because the provider (Xignite) returns only exchange-level market hours." This means all rows have ProviderID=0, representing manual configurations set by dealers via CM's "Edit Overrides" screen.

Instrument overrides have the highest merge precedence in the system: they override exchange overrides, provider data, and defaults. Live data reveals this is not just ad-hoc date overrides - dealers use this table to pre-plan complete annual calendars for specific instruments, with entries extending 8+ months into the future (e.g., closure dates for December 2026 set in January 2026). This includes holiday closures (IsOpen=0) and special trading hours for instruments whose schedules differ from their exchange defaults (e.g., Asian-Pacific instruments with restricted UTC windows like 01:08-10:59 UTC).

Data is written by Configuration Manager. The MarketCalendar Azure Function reads this table as the first (highest-priority) source during the merge process. Currently contains ~6.4K rows covering a variety of instruments with pre-planned schedules.

---

## 2. Business Logic

### 2.1 Instrument-Level Override Priority

**What**: These entries take highest precedence in the merge, overriding ALL other sources.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`

**Rules**:
- ProviderID = 0 (eToro): All current rows are eToro overrides from CM
- These are merged FIRST - before exchange overrides, before provider data, before defaults
- Per Confluence: "Instrument configuration is stronger than exchange configuration"

---

## 3. Data Overview

~6.4K rows. All from eToro overrides (ProviderID=0). Schedules extend months ahead for specific instruments:

| ProviderID | InstrumentID | Date | IsOpen | OpenTimeUTC | CloseTimeUTC | Meaning |
|---|---|---|---|---|---|---|
| 0 | 211003 | 2026-12-07 | 0 | 00:00:05 | 23:50:00 | Instrument 211003 manually closed on this date (holiday/special closure). |
| 0 | 211003 | 2026-12-06 | 1 | 01:08 | 10:59:55 | Same instrument open the day before. Short trading window suggests an Asian/Pacific instrument. |
| 0 | 207010 | 2026-11-30 | 0 | 00:00:05 | 23:50:00 | Instrument 207010 closed (likely US Thanksgiving-adjacent). |
| 0 | 201006 | 2026-09-21 | 0 | 00:00 | 00:00 (next day) | Instrument 201006 closed for full day. |
| 0 | 201006 | 2026-09-18 | 1 | 01:08 | 13:29:55 | Same instrument open before the closure date. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | Timestamp when this row was inserted. |
| 3 | ProviderID | int | NO | - | VERIFIED | Calendar data provider. Currently always 0 (eToro overrides) since Xignite provides exchange-level data only, not instrument-level. Implicit FK to CalenderProviders. |
| 4 | InstrumentID | int | NO | - | VERIFIED | eToro internal instrument identifier. Identifies the specific instrument this override applies to. |
| 5 | Date | date | NO | - | CODE-BACKED | Calendar date for this override. Clustered index. |
| 6 | IsOpen | bit | NO | - | CODE-BACKED | Whether this instrument should be open on this date per the override. |
| 7 | OpenTime | datetime | NO | - | CODE-BACKED | Instrument open time in local timezone. |
| 8 | CloseTime | datetime | NO | - | CODE-BACKED | Instrument close time in local timezone. |
| 9 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Instrument open time in UTC. |
| 10 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Instrument close time in UTC. |
| 11 | DeltaOpenMins | int | YES | - | CODE-BACKED | Minute-level open time offset. |
| 12 | DeltaCloseMins | int | YES | - | CODE-BACKED | Minute-level close time offset. |
| 13 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision open time offset. |
| 14 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision close time offset. |
| 15 | DbLoginName | computed(suser_name()) | NO | - | CODE-BACKED | Computed audit: SQL Server login. |
| 16 | AppLoginName | computed(CONVERT(varchar(500),context_info())) | NO | - | CODE-BACKED | Computed audit: application session identity. |
| 17 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal ROW START. |
| 18 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. History in History.ProvidersInstrumentDailySchedules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Market.CalenderProviders | Implicit FK | Currently always 0 (eToro) |
| InstrumentID | Market.InstrumentTimeZones | Implicit FK | Instrument timezone for conversion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MarketCalendar Azure Function | N/A | READER | Reads as highest-priority merge input |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MarketCalendar Azure Function | External Service | Highest-priority merge input |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarketProvidersInstrumentDailySchedules | NC PK | ID | - | - | Active |
| IX_ProvidersInstrumentDailySchedules_Date | CLUSTERED | Date | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ProvidersInstrumentDailySchedules_SysStart | DEFAULT | getutcdate() |
| DF_ProvidersInstrumentDailySchedules_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 |

**Trigger**: `TRG_T_ProvidersInstrumentDailySchedules` - FOR INSERT, self-update for temporal audit.

---

## 8. Sample Queries

### 8.1 Get instrument overrides from today

```sql
SELECT InstrumentID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersInstrumentDailySchedules WITH (NOLOCK)
WHERE ProviderID = 0 AND Date >= CAST(GETUTCDATE() AS date)
ORDER BY Date, InstrumentID;
```

### 8.2 Find instruments with overrides for a specific date

```sql
SELECT InstrumentID, IsOpen, OpenTimeUTC, CloseTimeUTC, DeltaOpenSecs, DeltaCloseSecs
FROM Market.ProvidersInstrumentDailySchedules WITH (NOLOCK)
WHERE Date = '2026-04-14' AND ProviderID = 0
ORDER BY InstrumentID;
```

### 8.3 Count overrides by instrument

```sql
SELECT InstrumentID, COUNT(*) AS OverrideCount
FROM Market.ProvidersInstrumentDailySchedules WITH (NOLOCK)
WHERE ProviderID = 0 AND Date >= CAST(GETUTCDATE() AS date)
GROUP BY InstrumentID
ORDER BY OverrideCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "Atm only etoro overrides (provider=0) are saved here, because provider returns only exchange market hours." Written by CM Overrides, read by MarketCalendar function. |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "Maintains data for instruments specifically (written by the CM)." Overrides query: WHERE ProviderID=0. IsManual and HasDailyBreak taken from defaults table. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.ProvidersInstrumentDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.ProvidersInstrumentDailySchedules.sql*
