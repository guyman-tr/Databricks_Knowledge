# History.CES_ReloadExposures

> Audit log for CES (Currency/CEP Exposure Service) exposure reload operations - records who triggered a per-instrument exposure reload and when.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,2) bigint, no PK constraint (heap) |
| **Partition** | No |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

History.CES_ReloadExposures is an audit log that records each time the CES (Currency Exposure Service / CEP Exposure Service) exposure data is reloaded for a specific financial instrument. The reload operation is performed manually or by automated processes when hedging exposure data needs to be refreshed for a given instrument.

The table is a simple heap with no indexes - designed for write-heavy, low-read audit use. Each row records the SQL Server login (DBUserName), the application user (AppUserName), the instrument that was reloaded (InstrumentID), and the time (Occurred).

The table is empty in the current environment. The sole writer is History.CES_LogReloadExposures, which must be called by an external service or admin process.

Notable DDL details:
- IDENTITY(1,2): odd-only IDs (step=2) - likely part of a distributed ID scheme where even IDs would come from another source, or simply an artifact of copying from another table
- Stored on [DICTIONARY] filegroup
- DEFAULT constraint has a typo: "DF_HistoryCEP_ReoloadExposures" (misspelling of "Reload")

---

## 2. Business Logic

### 2.1 Exposure Reload Audit

**What**: Captures who triggered an instrument exposure reload in the CES/hedging system.

**Columns/Parameters Involved**: `InstrumentID`, `AppUserName`, `DBUserName`, `Occurred`

**Rules**:
- Written via History.CES_LogReloadExposures(@AppUserName, @InstrumentID)
- DBUserName = SUSER_NAME() at call time (SQL Server login)
- AppUserName = caller-supplied parameter (application user identity)
- InstrumentID = which instrument's exposure was reloaded
- Occurred = GETUTCDATE() via DEFAULT

---

## 3. Data Overview

Table is empty in current environment (0 rows). Written via History.CES_LogReloadExposures procedure when exposure reload events occur in production.

| ID | Occurred | DBUserName | AppUserName | InstrumentID | Meaning |
|----|----------|-----------|------------|-------------|---------|
| (no data) | - | - | - | - | No exposure reloads recorded in this environment |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY(1,2) | NO | - | VERIFIED | Surrogate row ID. IDENTITY seed=1, step=2 (odd-only IDs). No PK constraint - the table is a heap. |
| 2 | Occurred | datetime | YES | GETUTCDATE() | VERIFIED | UTC timestamp when the exposure reload was logged. Default = GETUTCDATE(). |
| 3 | DBUserName | nvarchar(255) | YES | - | VERIFIED | SQL Server login name of the session that triggered the reload. Populated via SUSER_NAME() in History.CES_LogReloadExposures. |
| 4 | AppUserName | nvarchar(255) | YES | - | VERIFIED | Application-level user name passed as a parameter to History.CES_LogReloadExposures. Identifies the system or user that initiated the reload. |
| 5 | InstrumentID | int | YES | - | VERIFIED | The financial instrument whose CES exposure data was reloaded. Implicit FK to History.Instrument. NULL if the reload was schema-wide rather than instrument-specific. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | The instrument whose exposure was reloaded. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CES_LogReloadExposures | AppUserName, InstrumentID | Writer | Sole writer - called by CES reload process. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CES_ReloadExposures (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CES_LogReloadExposures | Stored Procedure | Writer - logs exposure reload events |

---

## 7. Technical Details

### 7.1 Indexes

None. Table is a heap.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryCEP_ReoloadExposures | DEFAULT | Occurred = GETUTCDATE() (note: "Reoload" typo in constraint name) |

---

## 8. Sample Queries

### 8.1 Get recent exposure reload activity
```sql
SELECT ID, Occurred, DBUserName, AppUserName, InstrumentID
FROM History.CES_ReloadExposures WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.2 Reload history for a specific instrument
```sql
SELECT ID, Occurred, DBUserName, AppUserName
FROM History.CES_ReloadExposures WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CES_ReloadExposures | Type: Table | Source: etoro/etoro/History/Tables/History.CES_ReloadExposures.sql*
