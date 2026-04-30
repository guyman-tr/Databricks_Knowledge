# Trade.SevisionCriticalInstruments

> Whitelist of instruments flagged as "critical" for the Sevision monitoring/supervision system. Critical instruments receive enhanced monitoring and tighter risk controls.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Trade.SevisionCriticalInstruments is a small whitelist table that marks specific instruments as "critical" for the Sevision monitoring or supervision system. Sevision (likely "Supervision" or a risk monitoring system name) requires certain instruments to receive enhanced monitoring, tighter risk controls, or additional validation during trading operations. When an instrument is in this table, downstream processes treat it differently - for example, applying stricter validation, more frequent checks, or special handling in risk calculations.

This table exists to support compliance and risk management for high-impact instruments. Without it, the Sevision system would not know which instruments require elevated scrutiny. The table is intentionally small; currently only InstrumentID=7 is flagged. It is system-versioned (temporal) so all add/remove actions are auditable.

Data flows: Procedures add or remove InstrumentIDs via INSERT/DELETE. Trade.GetInstrumentsForSevision reads the current whitelist to return instruments requiring enhanced monitoring. The UserName computed column (suser_name()) tracks who made the last change to each row.

---

## 2. Business Logic

### 2.1 Critical Instrument Whitelist

**What**: A row in this table means the instrument is flagged for Sevision-critical processing. Absence means standard treatment.

**Columns/Parameters Involved**: `InstrumentID`, `UserName`, `SysStartTime`, `SysEndTime`

**Rules**:
- InstrumentID is the only business key. References Trade.Instrument.
- One row per critical instrument. No duplicate InstrumentIDs (PK).
- UserName = suser_name() - computed at insert/update to capture who modified.
- SysStartTime/SysEndTime are system-versioned columns. History in History.SevisionCriticalInstruments.

**Diagram**:
```
[Add Critical Instrument] -> INSERT InstrumentID=7
        |
        v
  [Sevision monitors InstrumentID=7 with enhanced rules]
        |
        v
[Remove] -> DELETE -> Instrument returns to standard monitoring
```

### 2.2 Temporal Audit

**What**: All changes (add/remove/modify) are retained in history.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `History.SevisionCriticalInstruments`

**Rules**:
- SysStartTime: When this version became active (GENERATED ALWAYS AS ROW START).
- SysEndTime: When superseded (GENERATED ALWAYS AS ROW END). '9999-12-31' for current.
- Query FOR SYSTEM_TIME to audit who added/removed which instruments and when.

---

## 3. Data Overview

| InstrumentID | UserName | SysStartTime | SysEndTime | Meaning |
|--------------|----------|--------------|------------|---------|
| 7 | (computed) | 2023-01-04 | 9999-12-31 23:59:59.9999999 | Instrument 7 is critical for Sevision. Flagged since 2023-01-04. Receives enhanced monitoring. |

**Selection criteria**: Only 1 row in live data. Represents the single instrument currently flagged as critical.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK. FK to Trade.Instrument. The instrument flagged as critical for Sevision. |
| 2 | SysStartTime | datetime2(7) | NO | GENERATED | CODE-BACKED | System-versioned row start. When this row version became active. |
| 3 | SysEndTime | datetime2(7) | NO | GENERATED | CODE-BACKED | System-versioned row end. When superseded. '9999-12-31' for current. |
| 4 | UserName | (computed) | NO | suser_name() | CODE-BACKED | Computed: suser_name(). Captures who inserted or last updated the row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The instrument being flagged as critical. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentsForSevision | SELECT | Reader | Returns instruments in the critical whitelist. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SevisionCriticalInstruments (table)
(no code-level dependencies - table is leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID. |
| History.SevisionCriticalInstruments | Table | System-versioning history table. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentsForSevision | Stored Procedure | Reads critical instruments. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SevisionCriticalInstruments | CLUSTERED | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SevisionCriticalInstruments | PRIMARY KEY | Unique InstrumentID. |
| PERIOD FOR SYSTEM_TIME | System Versioning | SysStartTime, SysEndTime for temporal history. |

---

## 8. Sample Queries

### 8.1 Current critical instruments

```sql
SELECT
    InstrumentID,
    UserName,
    SysStartTime,
    SysEndTime
FROM Trade.SevisionCriticalInstruments WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.2 Critical instruments with instrument details

```sql
SELECT
    s.InstrumentID,
    i.InstrumentTypeID,
    i.BuyCurrencyID,
    i.SellCurrencyID,
    s.UserName,
    s.SysStartTime
FROM Trade.SevisionCriticalInstruments s WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = s.InstrumentID
ORDER BY s.InstrumentID;
```

### 8.3 Historical changes (temporal)

```sql
SELECT
    InstrumentID,
    UserName,
    SysStartTime,
    SysEndTime
FROM Trade.SevisionCriticalInstruments
FOR SYSTEM_TIME ALL
ORDER BY InstrumentID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SevisionCriticalInstruments | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SevisionCriticalInstruments.sql*
