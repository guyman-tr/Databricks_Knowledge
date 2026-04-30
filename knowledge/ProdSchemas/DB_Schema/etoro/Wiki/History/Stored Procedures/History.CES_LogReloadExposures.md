# History.CES_LogReloadExposures

> Audit writer that records each per-instrument CES exposure reload event into History.CES_ReloadExposures, capturing the SQL Server login, application username, and the instrument whose exposure data was reloaded.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value; fire-and-forget audit INSERT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.CES_LogReloadExposures` is the sole writer for `History.CES_ReloadExposures`. It is called when the CES (Currency Exposure Service) exposure data for a specific financial instrument is reloaded. The CES service maintains in-memory hedge exposure aggregates per instrument; when these need to be refreshed from the database (e.g., after a reconciliation or data correction), this procedure captures the audit record of who triggered the reload and for which instrument.

This procedure parallels `History.CEP_LogReloadRules`: both are simple audit-capture writers for management/configuration events in the trading infrastructure. CES_LogReloadExposures is instrument-scoped (records which instrument was reloaded), while CEP_LogReloadRules is global (records a full rules engine reload).

The target table is currently empty in the observed environment. No error handling is present - INSERT failures are silently lost.

---

## 2. Business Logic

### 2.1 Per-Instrument Exposure Reload Audit

**What**: Records that the CES exposure data for a specific instrument was reloaded, along with who triggered it.

**Columns/Parameters Involved**: `@AppUserName`, `@InstrumentID`, `SUSER_NAME()` (automatic)

**Rules**:
- DBUserName = SUSER_NAME() - captured automatically at call time, not passed as a parameter
- @AppUserName = application-layer identity of the user triggering the reload
- @InstrumentID = which instrument's exposure was reloaded (allows querying reload history per instrument)
- Occurred defaults to GETUTCDATE() in the target table - not a procedure parameter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppUserName | nvarchar(255) | NO | - | CODE-BACKED | Application-layer username of the operator who triggered the exposure reload. Stored as History.CES_ReloadExposures.AppUserName. Used alongside DBUserName (auto-captured from SUSER_NAME()) for dual-identity audit. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | ID of the financial instrument whose CES exposure data was reloaded. Stored as History.CES_ReloadExposures.InstrumentID. Implicit FK to Trade.Instrument. Enables querying which instruments have had exposure reloads and when. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AppUserName, @InstrumentID | History.CES_ReloadExposures | Write target | Inserts one audit row per reload event |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument whose exposure was reloaded |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External CES management tooling | (application call) | Application | Called when CES exposure reload is triggered for an instrument. No SSDT procedures call this procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CES_LogReloadExposures (procedure)
└── History.CES_ReloadExposures (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CES_ReloadExposures | Table | INSERT target - one audit row per instrument reload event |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External CES management tooling | Application | Calls this procedure when exposure reload operations are performed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH. Target table is a heap with no PK constraint or indexes (stored on [DICTIONARY] filegroup).

---

## 8. Sample Queries

### 8.1 Show all CES exposure reload events by instrument

```sql
SELECT
    ID,
    Occurred,
    DBUserName,
    AppUserName,
    InstrumentID
FROM History.CES_ReloadExposures WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Find exposure reloads for a specific instrument

```sql
SELECT
    ID,
    Occurred,
    AppUserName
FROM History.CES_ReloadExposures WITH (NOLOCK)
WHERE InstrumentID = 7
ORDER BY Occurred DESC
```

### 8.3 Count reloads per instrument to identify frequently reloaded exposures

```sql
SELECT
    InstrumentID,
    COUNT(*) AS ReloadCount,
    MAX(Occurred) AS LastReload
FROM History.CES_ReloadExposures WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY ReloadCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CES_LogReloadExposures | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CES_LogReloadExposures.sql*
