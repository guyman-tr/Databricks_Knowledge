# History.InstrumentsExcludedFromHalt

> Temporal history table recording changes to the whitelist of instruments exempt from trading halt events, preserving the complete audit trail of which instruments were excluded from system-wide halts and when.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentsExcludedFromHalt is the SQL Server system-versioning history table for `Trade.InstrumentsExcludedFromHalt`, which is a whitelist of trading instruments that remain active even when a system-wide trading halt is declared. When eToro triggers an emergency halt (due to extreme market volatility, a circuit breaker event, or an operational crisis), all instruments pause trading - except those on this exclusion list. Instruments added to this list are considered critical enough to remain tradeable regardless of system halt conditions.

This history table answers "which instruments were on the halt exclusion list during the market volatility event in May 2024?" and "was instrument X protected from halts during a specific window?" It provides an audit trail for risk and compliance reviews of why certain positions could still be opened or closed during halt periods.

Data flows in automatically via SQL Server SYSTEM_VERSIONING from `Trade.InstrumentsExcludedFromHalt`. Changes are managed via the Trade.InsertInstrumentHalt (add to exclusion list) and Trade.RemoveInstrumentHalt (remove from exclusion list) stored procedures. Live data shows only a handful of instruments (1, 12, 1001) appear in the history, confirming this is a small, infrequently modified emergency-operations list.

---

## 2. Business Logic

### 2.1 Halt Exclusion Mechanics

**What**: Instruments added to this table bypass the trading halt mechanism, remaining tradeable while other instruments are suspended.

**Columns/Parameters Involved**: `InstrumentID`, `SysStartTime`, `SysEndTime`

**Rules**:
- Only instruments explicitly inserted into Trade.InstrumentsExcludedFromHalt are exempt from halts
- Adding an instrument here does NOT override individual instrument suspension (e.g., delisting) - only system-wide halts
- The temporal mechanism records every add/remove as a history row
- Rows where SysStartTime approximately equals SysEndTime indicate very brief exclusion windows (the instrument was added and removed nearly simultaneously, or a failed/reverted operation)

**Diagram**:
```
System Halt Event Declared
         |
         v
Trade.InstrumentsExcludedFromHalt
         |
  InstrumentID present? --YES--> Instrument remains OPEN for trading
         |
        NO
         |
         v
  Instrument is HALTED (no new positions, pending orders may be cancelled)
```

---

## 3. Data Overview

| InstrumentID | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|
| 1 | 2024-05-19 13:11:30 | 2024-05-19 13:11:30 | Very brief exclusion for instrument 1 during May 2024 - added and removed in the same second, likely a test or reverted operational action |
| 1 | 2024-05-19 12:53:22 | 2024-05-19 13:11:27 | Instrument 1 was on the halt exclusion list for ~18 minutes during May 19 2024 market event |
| 1001 | 2024-05-15 12:06:59 | 2024-05-15 12:06:59 | Instant add/remove for instrument 1001 during May 15 2024 - zero-duration exclusion window |
| 12 | 2024-05-15 12:06:59 | 2024-05-15 12:06:59 | Instrument 12 similarly had a zero-duration exclusion window on May 15 2024 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument exempted from system-wide halts. PK in the live Trade.InstrumentsExcludedFromHalt table (only one active exclusion row per instrument at a time). FK to Trade.Instrument(InstrumentID) in the live table. |
| 2 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name of the session that added or removed the instrument from the exclusion list. Computed from suser_name() in the live table; stored statically here for audit. |
| 3 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user context when the change was made. Computed from context_info() in the live table, set by the application before DML execution. Stored statically here. |
| 4 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument was added to the halt exclusion list (row became active in Trade.InstrumentsExcludedFromHalt). |
| 5 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument was removed from the halt exclusion list (row was deleted or changed in Trade.InstrumentsExcludedFromHalt). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose halt exclusion status is recorded. FK enforced on the live Trade.InstrumentsExcludedFromHalt, not on this history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentsExcludedFromHalt | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table via SQL Server temporal mechanism. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table - passive receiver of change data from the live table.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsExcludedFromHalt | Table | Live temporal table whose change history is stored here |
| Trade.InsertInstrumentHalt | Stored Procedure | Writer - adds instruments to the exclusion list, creating history rows here |
| Trade.RemoveInstrumentHalt | Stored Procedure | Deleter - removes instruments from the exclusion list, creating history rows here |
| Trade.GetExcludeHaltInstruments | Stored Procedure | Reader - queries the current live exclusion list (not this history table directly) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentsExcludedFromHalt | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find all instruments that were on the halt exclusion list during a specific event
```sql
DECLARE @EventStart datetime2 = '2024-05-19 12:00:00'
DECLARE @EventEnd   datetime2 = '2024-05-19 14:00:00'
SELECT
    InstrumentID,
    SysStartTime AS ExclusionAdded,
    SysEndTime   AS ExclusionRemoved,
    DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds,
    DbLoginName,
    AppLoginName
FROM History.InstrumentsExcludedFromHalt WITH (NOLOCK)
WHERE SysStartTime < @EventEnd
  AND SysEndTime > @EventStart
ORDER BY SysStartTime
```

### 8.2 Show current instruments excluded from halts (from live table)
```sql
SELECT
    InstrumentID,
    SysStartTime AS ExcludedSince
FROM Trade.InstrumentsExcludedFromHalt WITH (NOLOCK)
```

### 8.3 Full history of halt exclusion changes for a specific instrument
```sql
SELECT
    InstrumentID,
    SysStartTime AS ExclusionAdded,
    SysEndTime   AS ExclusionRemoved,
    DbLoginName,
    AppLoginName
FROM History.InstrumentsExcludedFromHalt WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY SysStartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentsExcludedFromHalt | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentsExcludedFromHalt.sql*
