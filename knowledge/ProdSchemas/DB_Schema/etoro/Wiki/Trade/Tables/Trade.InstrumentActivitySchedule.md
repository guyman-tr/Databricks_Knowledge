# Trade.InstrumentActivitySchedule

> Configures time-bounded activity windows (FromDate/ToDate) per instrument for scheduling trading hours or maintenance windows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ActivityScheduleID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active |

---

## 1. Business Meaning

Trade.InstrumentActivitySchedule stores date-bounded activity schedules per instrument. Each row defines a time window (FromDate to ToDate) during which an instrument may be active or inactive, controlled by the IsActive flag. This supports use cases such as trading hours, maintenance windows, or scheduled instrument enable/disable periods.

The table exists to decouple instrument activity from the base Trade.Instrument definition. Instead of modifying the instrument record, operations can define multiple overlapping or sequential windows. Without it, scheduling logic would require direct edits to instrument configuration or separate ad-hoc tables.

Data flow: ActivityScheduleID is allocated via `Internal.GetInstrumentActivityScheduleID` (uses Internal.GenInstrumentActivityScheduleID identity). INSERTs are not found in the Trade schema procedures - the infrastructure exists but the table is currently empty. Trade.Instrument doc labels this table as "Trading hours and activity windows per instrument."

---

## 2. Business Logic

### 2.1 Activity Window

**What**: A date range during which an instrument's activity state applies.

**Columns/Parameters Involved**: `FromDate`, `ToDate`, `IsActive`

**Rules**:
- FromDate and ToDate define an inclusive date window; the schedule applies when current date falls within this range
- IsActive=1: schedule is active (instrument allowed); IsActive=0: schedule is inactive (instrument blocked or maintenance)
- Default IsActive=0 - new rows are inactive until explicitly activated
- Multiple rows per InstrumentID allow overlapping or sequential windows (e.g., weekday vs weekend hours)

**Diagram**:
```
InstrumentID=1 (EUR/USD)
  Row 1: FromDate=2024-01-01, ToDate=2024-12-31, IsActive=1  -> Trading allowed
  Row 2: FromDate=2024-06-01, ToDate=2024-06-02, IsActive=0   -> Maintenance window
```

---

## 3. Data Overview

The table has no rows. Representative structure for future data:

| ActivityScheduleID | InstrumentID | IsActive | FromDate | ToDate | Meaning |
|---|---|---|---|---|---|
| 1 | 1 | 1 | 2024-01-01 00:00 | 2024-12-31 23:59 | EUR/USD trading window - active for full year |
| 2 | 1 | 0 | 2024-06-15 00:00 | 2024-06-16 23:59 | EUR/USD maintenance - trading disabled |
| 3 | 1203 | 1 | 2024-01-01 00:00 | 2024-12-31 23:59 | Bayer AG stock - active window |

**Selection criteria**: Table is empty. Above shows intended pattern - one row per schedule, FromDate/ToDate define the window, IsActive controls enable/disable.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActivityScheduleID | int | NO | - | CODE-BACKED | Primary key. Allocated by `Internal.GetInstrumentActivityScheduleID` (INSERT into Internal.GenInstrumentActivityScheduleID, SCOPE_IDENTITY). Unique per schedule row. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument(InstrumentID). The instrument this schedule applies to. Multiple rows per InstrumentID allowed for overlapping windows. |
| 3 | IsActive | tinyint | NO | 0 | CODE-BACKED | Activity state: 0=inactive (default, schedule disabled or maintenance), 1=active (schedule enabled, instrument tradeable). Default (0) ensures new rows are off until explicitly set. |
| 4 | FromDate | datetime | NO | - | NAME-INFERRED | Start of the schedule window (inclusive). When current date >= FromDate, the schedule applies. |
| 5 | ToDate | datetime | NO | - | NAME-INFERRED | End of the schedule window (inclusive). When current date <= ToDate, the schedule applies. Window is FromDate <= date <= ToDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The instrument this activity schedule applies to. Resolve via JOIN for instrument symbol/name. |

### 5.2 Referenced By (other objects point to this)

No Trade views or procedures reference this table in FROM/JOIN. Grep across etoro/etoro/Trade/Views and Stored Procedures found no consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentActivitySchedule (table)
└── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID |

### 6.2 Objects That Depend On This

No Trade views or procedures reference this table in the repository. Internal.GetInstrumentActivityScheduleID allocates ActivityScheduleID for INSERTs but does not read from this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade_InstrumentActivitySchedule | CLUSTERED | ActivityScheduleID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Trade_InstrumentActivitySchedule | PRIMARY KEY | ActivityScheduleID - unique identifier |
| FK_InstrumentActivitySchedule__Instrument | FOREIGN KEY | InstrumentID references Trade.Instrument(InstrumentID) |
| DF_InstrumentActivitySchedule_IsActive | DEFAULT | IsActive = 0 when not specified |

---

## 8. Sample Queries

### 8.1 Count all schedule rows
```sql
SELECT COUNT(*) AS Cnt
FROM Trade.InstrumentActivitySchedule WITH (NOLOCK);
```

### 8.2 List all schedules with instrument names
```sql
SELECT IAS.ActivityScheduleID,
       IAS.InstrumentID,
       IAS.IsActive,
       IAS.FromDate,
       IAS.ToDate
FROM Trade.InstrumentActivitySchedule IAS WITH (NOLOCK)
JOIN Trade.Instrument TI WITH (NOLOCK) ON IAS.InstrumentID = TI.InstrumentID
ORDER BY IAS.InstrumentID, IAS.FromDate;
```

### 8.3 Find active schedules for current date
```sql
SELECT IAS.ActivityScheduleID,
       IAS.InstrumentID,
       IAS.IsActive,
       IAS.FromDate,
       IAS.ToDate
FROM Trade.InstrumentActivitySchedule IAS WITH (NOLOCK)
WHERE IAS.FromDate <= CAST(GETUTCDATE() AS DATE)
  AND IAS.ToDate >= CAST(GETUTCDATE() AS DATE)
  AND IAS.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 5.6/10 (Elements: 6.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentActivitySchedule | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentActivitySchedule.sql*
