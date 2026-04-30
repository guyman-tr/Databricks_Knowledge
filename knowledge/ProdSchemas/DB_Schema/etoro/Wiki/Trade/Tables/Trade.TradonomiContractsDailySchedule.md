# Trade.TradonomiContractsDailySchedule

> Intraday trading schedule that defines when each instrument can be traded - used for instruments with market hours (e.g., stocks) or session breaks (e.g., forex maintenance windows).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DailyScheduleID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.TradonomiContractsDailySchedule stores the intraday trading windows for instruments. Each row defines a time range (FromTime, ToTime) when an instrument is tradeable. For 24-hour instruments (most forex), FromTime=ToTime at midnight indicates always-available. For instruments with market hours or session breaks (e.g., some indices or forex pairs with maintenance windows), two rows per instrument are common: one for the main session (e.g., 00:00-21:15) and one for the alternate session (e.g., 21:30-00:00 next day). This table answers "Can I trade Instrument X at time T?" for order routing and validation.

This table exists because not all instruments trade 24/5. Stock exchanges have open/close times; some forex pairs have daily settlement windows. Without it, the system could not enforce trading-hour restrictions or display correct "market open/closed" status. Trade.GetTradonomiContractsDailySchedule view exposes this data joined to instrument display names. Trade.InsertTradonomiContactDailySchedule populates it when instruments are configured.

Data is created by Trade.InsertTradonomiContactDailySchedule, which calls Internal.GetTradonomiContractsDailyScheduleID for DailyScheduleID allocation. The view Trade.GetTradonomiContractsDailySchedule joins to Trade.Instrument and Dictionary.Currency for human-readable display.

---

## 2. Business Logic

### 2.1 Daily Schedule Windows

**What**: Each row is a time window (FromTime, ToTime) for a given instrument, identified by DailyScheduleID.

**Columns/Parameters Involved**: `DailyScheduleID`, `InstrumentID`, `FromTime`, `ToTime`

**Rules**:
- One or more rows per InstrumentID. A single row with FromTime=ToTime at midnight (e.g., 2010-01-01 00:00:00) indicates 24-hour trading.
- Two rows per instrument: main session (e.g., 00:00-21:15) and alternate (e.g., 21:30-00:00). ToTime before FromTime or equal to midnight crosses to next calendar day.
- DailyScheduleID is the surrogate PK; InstrumentID links to Trade.Instrument. The table name references "TradonomiContracts" but the FK is to Instrument - the schedule applies at instrument level for Tradonomi liquidity routing.

**Diagram**:
```
InstrumentID=17 (likely indices/stocks with sessions)
  DailyScheduleID=1: 00:00-21:15 -> Main session
  DailyScheduleID=2: 21:30-00:00 -> Alternate session (rolls to next day)
InstrumentID=1 (EUR/USD - forex)
  DailyScheduleID=15: 00:00-00:00 -> 24-hour (always tradeable)
```

### 2.2 Instrument-Level Assignment

**What**: Each InstrumentID has at least one schedule row. Multiple rows represent split sessions (e.g., pre-market + regular + after-hours).

**Columns/Parameters Involved**: `InstrumentID`, `FromTime`, `ToTime`

**Rules**:
- FK to Trade.Instrument ensures the instrument exists. No explicit link to Trade.TradonomiContracts - schedule is instrument-scoped.
- Used by GetTradonomiContractsDailySchedule view for display and by potential order validation logic.

---

## 3. Data Overview

| DailyScheduleID | InstrumentID | FromTime | ToTime | Meaning |
|-----------------|--------------|----------|--------|---------|
| 1 | 17 | 2010-04-08 00:00:00 | 2010-04-08 21:15:00 | Main trading session for instrument 17 - 21h15 window. Likely indices or instruments with daily settlement. |
| 2 | 17 | 2010-04-08 21:30:00 | 2010-04-08 00:00:00 | Alternate session for instrument 17 - 21:30 to midnight (next day). Covers post-main or pre-main window. |
| 15 | 1 | 2010-01-01 00:00:00 | 2010-01-01 00:00:00 | EUR/USD (instrument 1) - 24-hour schedule. FromTime=ToTime at midnight means always tradeable. |
| 18 | 2 | 2010-01-01 00:00:00 | 2010-01-01 00:00:00 | GBP/USD (instrument 2) - same 24-hour pattern as major forex. |
| 34 | 18 | 2010-01-01 00:00:00 | 2010-01-01 00:00:00 | Instrument 18 - 24-hour. Demonstrates mix of session-based vs always-on instruments. |

**Selection criteria for the 5 rows:** Picked rows showing both session-based (instrument 17 with two windows) and 24-hour (instruments 1, 2, 18) patterns. Date portion is typically ignored; time-of-day is the meaningful part.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DailyScheduleID | int | NO | - | CODE-BACKED | Surrogate primary key. Allocated by Internal.GetTradonomiContractsDailyScheduleID. Unique per schedule row. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument this schedule applies to. One instrument can have multiple schedule rows (split sessions). |
| 3 | FromTime | datetime | NO | - | CODE-BACKED | Start of trading window (UTC). For 24h instruments typically 00:00:00. Used to determine if current time falls within tradeable period. |
| 4 | ToTime | datetime | NO | - | CODE-BACKED | End of trading window (UTC). For 24h instruments typically 00:00:00 (same as FromTime). ToTime before FromTime indicates window crosses midnight. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The tradeable instrument. FK_InstrumentDailySchedule___Instrument. Schedule applies at instrument level. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTradonomiContractsDailySchedule | TCDS | FROM | View exposes schedule with instrument and currency abbreviation. |
| Trade.InsertTradonomiContactDailySchedule | INSERT | Writer | Procedure creates new schedule rows via INSERT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TradonomiContractsDailySchedule (table)
└── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID. Instrument must exist. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTradonomiContractsDailySchedule | View | FROM/JOIN |
| Trade.InsertTradonomiContactDailySchedule | Procedure | INSERT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade__InstrumentDailySchedule | CLUSTERED | DailyScheduleID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_InstrumentDailySchedule___Instrument | FK | InstrumentID -> Trade.Instrument.InstrumentID (NOCHECK) |

---

## 8. Sample Queries

### 8.1 Get schedule for an instrument with display info
```sql
SELECT TCDS.DailyScheduleID,
       TCDS.InstrumentID,
       DCUR.Abbreviation AS InstrumentAbbrev,
       TCDS.FromTime,
       TCDS.ToTime
  FROM Trade.TradonomiContractsDailySchedule TCDS WITH (NOLOCK)
 INNER JOIN Trade.Instrument TINS WITH (NOLOCK) ON TCDS.InstrumentID = TINS.InstrumentID
 INNER JOIN Dictionary.Currency DCUR WITH (NOLOCK) ON TINS.BuyCurrencyID = DCUR.CurrencyID
 WHERE TCDS.InstrumentID = 1
 ORDER BY TCDS.DailyScheduleID;
```

### 8.2 Instruments with split sessions (multiple rows per instrument)
```sql
SELECT InstrumentID,
       COUNT(*) AS ScheduleCount,
       MIN(FromTime) AS EarliestFrom,
       MAX(ToTime) AS LatestTo
  FROM Trade.TradonomiContractsDailySchedule TCDS WITH (NOLOCK)
 GROUP BY InstrumentID
HAVING COUNT(*) > 1
 ORDER BY InstrumentID;
```

### 8.3 24-hour instruments (FromTime = ToTime)
```sql
SELECT TCDS.DailyScheduleID,
       TCDS.InstrumentID,
       TCDS.FromTime,
       TCDS.ToTime,
       DCUR.Abbreviation
  FROM Trade.TradonomiContractsDailySchedule TCDS WITH (NOLOCK)
 INNER JOIN Trade.Instrument TINS WITH (NOLOCK) ON TCDS.InstrumentID = TINS.InstrumentID
 INNER JOIN Dictionary.Currency DCUR WITH (NOLOCK) ON TINS.BuyCurrencyID = DCUR.CurrencyID
 WHERE TCDS.FromTime = TCDS.ToTime
 ORDER BY TCDS.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradonomiContractsDailySchedule | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.TradonomiContractsDailySchedule.sql*
