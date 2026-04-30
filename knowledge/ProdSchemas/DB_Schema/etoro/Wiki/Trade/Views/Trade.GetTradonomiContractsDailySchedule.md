# Trade.GetTradonomiContractsDailySchedule

> View exposing intraday trading schedule with instrument abbreviation - used for market hours and session-break displays.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | DailyScheduleID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetTradonomiContractsDailySchedule joins Trade.TradonomiContractsDailySchedule with Trade.Instrument and Dictionary.Currency (via BuyCurrencyID) to expose each daily schedule row with the instrument's display abbreviation. Each row defines a trading window (FromTime, ToTime) for an instrument. For 24-hour instruments (e.g., major forex), FromTime=ToTime at midnight indicates always tradeable. For instruments with market hours (e.g., indices, stocks), two rows per instrument are common: main session (e.g., 00:00-21:15) and alternate session (e.g., 21:30-00:00).

This view exists because back-office and trading UIs need to answer "Can I trade instrument X at time T?" with human-readable instrument names. Trade.InsertTradonomiContactDailySchedule populates the base table; this view enriches it for display and validation.

---

## 2. Business Logic

### 2.1 Schedule Windows

**What**: Each row is a (DailyScheduleID, InstrumentID, FromTime, ToTime) with Abbreviation for display.

**Columns/Parameters Involved**: `DailyScheduleID`, `InstrumentID`, `Abbreviation`, `FromTime`, `ToTime`

**Rules**:
- One or more rows per InstrumentID
- FromTime=ToTime at midnight (e.g., 2010-01-01 00:00:00) = 24-hour trading
- Two rows: main session (00:00-21:15) and alternate (21:30-00:00) - ToTime before FromTime crosses to next day
- Abbreviation comes from Instrument.BuyCurrencyID -> Dictionary.Currency (BuyCurrencyID for forex/stocks)

**Diagram**:
```
Trade.TradonomiContractsDailySchedule (DailyScheduleID, InstrumentID, FromTime, ToTime)
       | JOIN InstrumentID
       v
Trade.Instrument (BuyCurrencyID)
       | JOIN BuyCurrencyID
       v
Dictionary.Currency (Abbreviation)
```

### 2.2 Currency Display

**What**: Abbreviation uses BuyCurrencyID only - for forex this is the base currency (e.g., EUR for EUR/USD); for stocks the asset symbol.

---

## 3. Data Overview

| DailyScheduleID | InstrumentID | Abbreviation | FromTime | ToTime | Meaning |
|-----------------|--------------|--------------|----------|--------|---------|
| 1 | 17 | XTI | 2010-04-08 00:00:00 | 2010-04-08 21:15:00 | Oil (XTI) main session - 21h15 window. |
| 2 | 17 | XTI | 2010-04-08 21:30:00 | 2010-04-08 00:00:00 | XTI alternate session - 21:30 to midnight. |
| 3 | 27 | SPX500 | 2010-04-08 00:00:00 | 2010-04-08 21:15:00 | S&P 500 index main session. |
| 4 | 27 | SPX500 | 2010-04-08 21:30:00 | 2010-04-08 00:00:00 | SPX500 alternate session. |
| 5 | 28 | NSDQ100 | 2010-04-08 00:00:00 | 2010-04-08 21:15:00 | Nasdaq 100 main session. |

**Live sampling**: Instrument 17 (XTI) and 27 (SPX500) show two rows each - main and alternate sessions. Time portion is meaningful; date is typically placeholder. Abbreviation matches instrument display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Source Table | Description |
|---|---------|------|----------|---------|------------|--------------|-------------|
| 1 | DailyScheduleID | int | NO | - | CODE-BACKED | Trade.TradonomiContractsDailySchedule | Surrogate primary key. Unique per schedule row. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Trade.TradonomiContractsDailySchedule | FK to Trade.Instrument. Instrument this schedule applies to. |
| 3 | Abbreviation | varchar | - | - | CODE-BACKED | Dictionary.Currency (via Instrument.BuyCurrencyID) | Instrument display symbol (e.g., XTI, SPX500, NSDQ100). |
| 4 | FromTime | datetime | NO | - | CODE-BACKED | Trade.TradonomiContractsDailySchedule | Start of trading window (UTC). Midnight = 24h. |
| 5 | ToTime | datetime | NO | - | CODE-BACKED | Trade.TradonomiContractsDailySchedule | End of trading window. Midnight or before FromTime = crosses midnight. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Base Table | Join Condition | Relationship Type | Description |
|------------|----------------|-------------------|-------------|
| Trade.TradonomiContractsDailySchedule (TCDS) | FROM | Source | Schedule rows. |
| Trade.Instrument (TINS) | TCDS.InstrumentID = TINS.InstrumentID | INNER JOIN | Resolve BuyCurrencyID. |
| Dictionary.Currency (DCUR) | TINS.BuyCurrencyID = DCUR.CurrencyID | INNER JOIN | Abbreviation for display. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Type | Role | Description |
|--------------|------|------|-------------|
| Trade.InsertTradonomiContactDailySchedule | Procedure | Writer to base table | Populates TradonomiContractsDailySchedule; view consumes that data. |
| Trade.TradonomiContractsDailySchedule (table doc) | Reference | - | View documented as consumer of base table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTradonomiContractsDailySchedule (view)
├── Trade.TradonomiContractsDailySchedule (table)
├── Trade.Instrument (table)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContractsDailySchedule | Table | FROM - DailyScheduleID, InstrumentID, FromTime, ToTime. |
| Trade.Instrument | Table | INNER JOIN - BuyCurrencyID for abbreviation. |
| Dictionary.Currency | Table | INNER JOIN - Abbreviation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertTradonomiContactDailySchedule | Procedure | Writes to base table; view reads it. |

---

## 7. Technical Details

### 7.1 DDL Summary

- No SCHEMABINDING
- INNER JOINs - instruments must exist and have valid BuyCurrencyID
- Abbreviation = DCUR.Abbreviation (single currency via BuyCurrencyID)

### 7.2 Column Mapping

| Output Column | Source |
|--------------|--------|
| DailyScheduleID | TCDS.DailyScheduleID |
| InstrumentID | TCDS.InstrumentID |
| Abbreviation | DCUR.Abbreviation |
| FromTime | TCDS.FromTime |
| ToTime | TCDS.ToTime |

---

## 8. Sample Queries

### 8.1 Get schedule for instrument with display name

```sql
SELECT DailyScheduleID,
       InstrumentID,
       Abbreviation,
       FromTime,
       ToTime
  FROM Trade.GetTradonomiContractsDailySchedule WITH (NOLOCK)
 WHERE InstrumentID = 17
 ORDER BY DailyScheduleID
```

### 8.2 Instruments with split sessions (multiple rows per instrument)

```sql
SELECT InstrumentID,
       Abbreviation,
       COUNT(*) AS ScheduleCount,
       MIN(FromTime) AS EarliestFrom,
       MAX(ToTime) AS LatestTo
  FROM Trade.GetTradonomiContractsDailySchedule WITH (NOLOCK)
 GROUP BY InstrumentID, Abbreviation
HAVING COUNT(*) > 1
 ORDER BY InstrumentID
```

### 8.3 24-hour instruments (FromTime = ToTime)

```sql
SELECT DailyScheduleID,
       InstrumentID,
       Abbreviation,
       FromTime,
       ToTime
  FROM Trade.GetTradonomiContractsDailySchedule WITH (NOLOCK)
 WHERE FromTime = ToTime
 ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 5/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTradonomiContractsDailySchedule | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetTradonomiContractsDailySchedule.sql*
