# Market.ProvidersExchangeDailySchedules

> Stores daily exchange-level trading schedules from both external providers (Xignite, ProviderID=1) and eToro manual overrides (ProviderID=0), used as input to the merged schedule calculation.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 NC PK + 1 Clustered on Date) |

---

## 1. Business Meaning

This table stores exchange-level daily trading schedules from two sources: (1) Xignite (ProviderID=1), an external market data API that provides exchange open/close times, and (2) eToro manual overrides (ProviderID=0), where dealers use Configuration Manager to override specific dates (e.g., early close on Christmas Eve, holiday closures).

This table is a critical input to the merge process. The MarketCalendar Azure Function reads override entries (ProviderID=0) and provider entries (ProviderID=1) from here, then combines them with default weekly calendars to produce the final MergedDailySchedules. Overrides (ProviderID=0) take precedence over provider data (ProviderID=1).

Data is written by the ProvideCalendar Azure Function (for Xignite data, via `SetProviderExchangeCalendarBulk`) and by Configuration Manager (for eToro overrides). The ProvideCalendar function queries Xignite daily, sending 7 API calls per exchange for upcoming days. Currently contains ~28.5K rows.

---

## 2. Business Logic

### 2.1 Dual-Purpose ProviderID

**What**: ProviderID=0 rows are overrides, ProviderID=1 rows are provider data. Same table, different business purpose.

**Columns/Parameters Involved**: `ProviderID`

**Rules**:
- ProviderID = 0 (eToro overrides): Written by CM "Edit Overrides" screen. Highest merge precedence for exchange-level data.
- ProviderID = 1 (Xignite): Written by ProvideCalendar Azure Function. Overridden by ProviderID=0 entries for the same exchange/date.
- Query pattern for overrides: `WHERE ProviderID = 0 AND Date >= today`
- Query pattern for Xignite: `WHERE ProviderID = 1 AND Date >= today`

---

## 3. Data Overview

~28.5K rows. Recent Xignite provider data (ProviderID=1) for upcoming dates:

| ProviderID | ExchangeID | Date | IsOpen | OpenTimeUTC | CloseTimeUTC | Meaning |
|---|---|---|---|---|---|---|
| 1 | 36 | 2026-04-17 | 1 | 07:00 | 14:50 | Warsaw (XWAR) open 07:00-14:50 UTC. Standard European trading hours from Xignite. |
| 1 | 33 | 2026-04-17 | 1 | 13:30 | 20:00 | NYSE segment (ExchangeID=33) open 13:30-20:00 UTC. US Eastern trading hours. |
| 1 | 31 | 2026-04-17 | 1 | 23:59 (prev day) | 06:00 | ASX Australia open across midnight UTC. Opens late evening UTC (morning AEST). |
| 1 | 24 | 2026-04-17 | 0 | - | - | Saudi Exchange (XSAU) closed on this date (likely holiday/weekend). IsOpen=0. |
| 1 | 22 | 2026-04-17 | 1 | 07:00 | 15:30 | Lisbon (XLIS) open 07:00-15:30 UTC. Standard European hours. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | Timestamp when this row was inserted (GETDATE() in SP). |
| 3 | ProviderID | int | NO | - | VERIFIED | Calendar data provider. 0 = eToro overrides (from CM), 1 = Xignite (from ProvideCalendar function). Determines merge precedence: 0 > 1. Implicit FK to CalenderProviders. |
| 4 | ExchangeID | int | NO | - | VERIFIED | eToro internal exchange identifier. |
| 5 | Date | date | NO | - | CODE-BACKED | Calendar date. Clustered index for efficient date-range queries. |
| 6 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange is open on this date per this provider/override. |
| 7 | OpenTime | datetime | NO | - | CODE-BACKED | Exchange open time in local timezone. |
| 8 | CloseTime | datetime | NO | - | CODE-BACKED | Exchange close time in local timezone. |
| 9 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Exchange open time in UTC. |
| 10 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Exchange close time in UTC. |
| 11 | DeltaOpenMins | int | YES | - | CODE-BACKED | Minute-level open time offset. |
| 12 | DeltaCloseMins | int | YES | - | CODE-BACKED | Minute-level close time offset. |
| 13 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision open time offset. |
| 14 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision close time offset. |
| 15 | DbLoginName | computed(suser_name()) | NO | - | CODE-BACKED | Computed audit: SQL Server login. |
| 16 | AppLoginName | computed(CONVERT(varchar(500),context_info())) | NO | - | CODE-BACKED | Computed audit: application session identity. |
| 17 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal ROW START. |
| 18 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. History in History.ProvidersExchangeDailySchedules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Market.CalenderProviders | Implicit FK | 0=eToro, 1=Xignite |
| ExchangeID | Market.CalendarProviderExchanges | Implicit FK | Registered provider-exchange mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetProviderExchangeCalendarBulk | N/A | WRITER | Bulk deletes + inserts for a provider's exchange schedules |
| MarketCalendar Azure Function | N/A | READER | Reads overrides and provider data for merge calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetProviderExchangeCalendarBulk | Stored Procedure | WRITER - bulk delete + insert |
| MarketCalendar Azure Function | External Service | READER - merge input |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarketProviderExchangeDailySchedules | NC PK | ID | - | - | Active |
| IX_ProvidersExchangeDailySchedules_Date | CLUSTERED | Date | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ProvidersExchangeDailySchedules_SysStart | DEFAULT | getutcdate() |
| DF_ProvidersExchangeDailySchedules_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 |

**Trigger**: `TRG_T_ProvidersExchangeDailySchedules` - FOR INSERT, self-update for temporal audit.

---

## 8. Sample Queries

### 8.1 Get Xignite schedule for an exchange

```sql
SELECT Date, ExchangeID, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ProviderID = 1 AND ExchangeID = 4 AND Date >= CAST(GETUTCDATE() AS date)
ORDER BY Date;
```

### 8.2 Get eToro overrides

```sql
SELECT Date, ExchangeID, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ProviderID = 0 AND Date >= CAST(GETUTCDATE() AS date)
ORDER BY Date;
```

### 8.3 Compare overrides vs provider for same exchange/date

```sql
SELECT p.ProviderID, p.ExchangeID, p.Date, p.IsOpen, p.OpenTimeUTC, p.CloseTimeUTC
FROM Market.ProvidersExchangeDailySchedules p WITH (NOLOCK)
WHERE p.ExchangeID = 4 AND p.Date = '2026-04-14'
ORDER BY p.ProviderID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "Market hours data from provider is saved here. Overrides are saved with provider=0 (etoro)." Written by ProvideCalendar function and CM Overrides. Read by MarketCalendar function. |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "Written by Provider Calendar function (through SetProviderExchangeCalendarBulk Stored procedure)." Override query: WHERE ProviderID=0, Provider query: WHERE ProviderID=1. |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | Exchange/instrument open time data derived from PureProvidersExchangeDailySchedules. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.ProvidersExchangeDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.ProvidersExchangeDailySchedules.sql*
