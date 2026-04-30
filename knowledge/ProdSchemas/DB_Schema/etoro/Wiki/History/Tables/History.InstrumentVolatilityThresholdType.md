# History.InstrumentVolatilityThresholdType

> Temporal history table recording all changes to the per-instrument volatility threshold type assignment, preserving the audit trail of which measurement method (pips vs percentage) was used to evaluate price volatility for each instrument's circuit breaker logic.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentVolatilityThresholdType is the SQL Server system-versioning history table for `Trade.InstrumentVolatilityThresholdType`, which assigns each trading instrument a volatility threshold measurement type. This type determines how the system evaluates whether a price move is "too large" and should trigger a circuit breaker (halt trading for that instrument). An instrument can be classified as either pips-based (absolute pip movement) or percentage-based (percentage change from last price) for volatility detection.

This table answers audit questions such as "was instrument X on percentage-based or pips-based volatility monitoring when the incident occurred?" and "when did this instrument switch from pips to percentage monitoring?" These questions arise during post-incident reviews of market volatility events to understand whether the volatility detection method was appropriate.

Data flows in automatically via SYSTEM_VERSIONING from `Trade.InstrumentVolatilityThresholdType`. Live data shows VolatilityThresholdTypeID=2 (Percentage) for all recently changed instruments, suggesting a bulk migration away from pips-based measurement. Changes are infrequent - typically applied in batches when operational teams update volatility monitoring policy.

---

## 2. Business Logic

### 2.1 Volatility Threshold Measurement Type

**What**: Determines the unit in which price volatility is measured to decide if trading should be halted for an instrument.

**Columns/Parameters Involved**: `InstrumentID`, `VolatilityThresholdTypeID`

**Rules**:
- VolatilityThresholdTypeID = 1 (Pips): Volatility is measured as an absolute pip difference between consecutive prices. Used for forex instruments where pip units are meaningful.
- VolatilityThresholdTypeID = 2 (Percentage): Volatility is measured as the percentage difference between the last rate and current rate. Better suited for stocks and crypto where prices vary widely in absolute terms.
- Only one assignment per instrument (PK = InstrumentID in live table)
- Live data shows recent bulk migration to type 2 (Percentage) for instruments 205000-205001 and 1059363-1059364

**Diagram**:
```
Price Volatility Detection:
  InstrumentID -> VolatilityThresholdTypeID
                       |
          1 (Pips)     |    2 (Percentage)
             |         |          |
    |current - last|   |   (|current - last| / last) * 100
    in pips         |   |   as percentage
             |                    |
          Compare vs              Compare vs
          threshold in pips       threshold in %
             |                    |
         Exceeds? -> HALT     Exceeds? -> HALT
```

---

## 3. Data Overview

| InstrumentID | VolatilityThresholdTypeID | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|
| 1059364 | 2 (Percentage) | 2025-11-05 | 2025-12-08 | Instrument 1059364 was on percentage-based monitoring for ~33 days before being changed again |
| 1059363 | 2 (Percentage) | 2025-11-05 | 2025-12-08 | Same batch change - instruments in the same range migrated together |
| 205001 | 2 (Percentage) | 2024-11-17 | 2024-11-19 | Brief 2-day window with type 2 before another change on Nov 19 2024 |
| 205000 | 2 (Percentage) | 2024-11-17 | 2024-11-19 | Same 2-day window as 205001, changed in same batch operation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this volatility threshold type assignment applies to. PK in the live table (one assignment per instrument). FK to Trade.Instrument(InstrumentID). |
| 2 | VolatilityThresholdTypeID | int | NO | - | VERIFIED | The volatility measurement method: 1=Pips (absolute pip movement threshold), 2=Percentage (percentage price change threshold). FK to Dictionary.VolatilityThresholdType. Live data shows 2 (Percentage) for all recent rows. |
| 3 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this assignment became active in Trade.InstrumentVolatilityThresholdType. |
| 4 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this assignment was superseded. |
| 5 | UserName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name of the session that made the change. Computed from suser_name() in the live table; stored statically here for audit. (Note: column name is UserName rather than DbLoginName, unlike other temporal tables in this schema.) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose volatility threshold type history is recorded. |
| VolatilityThresholdTypeID | Dictionary.VolatilityThresholdType | Implicit (FK in live table) | The measurement method: 1=Pips, 2=Percentage. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentVolatilityThresholdType | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentVolatilityThresholdType | Table | Live temporal table whose history is stored here |
| Trade.CheckValidInstruments | Stored Procedure | Reader - checks instrument validity including volatility threshold configuration |
| Trade.InsertInstrumentRealTable | Stored Procedure | Writer - sets initial volatility threshold type when creating a new instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentVolatilityThresholdType | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find volatility threshold type for an instrument at a point in time
```sql
DECLARE @InstrumentID int = 205001
DECLARE @AsOf datetime2 = '2024-11-18 00:00:00'
SELECT
    InstrumentID,
    VolatilityThresholdTypeID,
    SysStartTime AS ActiveFrom,
    SysEndTime AS ActiveTo,
    UserName
FROM History.InstrumentVolatilityThresholdType WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND SysStartTime <= @AsOf
  AND SysEndTime > @AsOf
```

### 8.2 Find all instruments that changed volatility threshold type in a date range
```sql
SELECT
    InstrumentID,
    VolatilityThresholdTypeID,
    SysStartTime AS ChangeApplied,
    SysEndTime AS ChangeSuperseded,
    UserName
FROM History.InstrumentVolatilityThresholdType WITH (NOLOCK)
WHERE SysEndTime > '2024-11-01'
  AND SysStartTime < '2024-12-01'
ORDER BY SysStartTime, InstrumentID
```

### 8.3 Find all instruments currently using pips-based volatility measurement
```sql
SELECT
    InstrumentID,
    VolatilityThresholdTypeID,
    SysStartTime AS ConfiguredSince
FROM Trade.InstrumentVolatilityThresholdType WITH (NOLOCK)
WHERE VolatilityThresholdTypeID = 1  -- Pips
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentVolatilityThresholdType | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentVolatilityThresholdType.sql*
