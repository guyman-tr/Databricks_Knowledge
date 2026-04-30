# History.PortfolioConversionConfigurations

> SQL Server temporal history table storing prior row versions of Hedge.PortfolioConversionConfigurations, preserving the audit trail for changes to the instrument-to-hedge-instrument conversion multiplier mappings used by the hedging engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.PortfolioConversionConfigurations is the SQL Server system-versioning history table for Hedge.PortfolioConversionConfigurations (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[PortfolioConversionConfigurations])`). Whenever a configuration row is updated or deleted, the prior version is automatically written here.

Hedge.PortfolioConversionConfigurations maps a source instrument (InstrumentID) to a hedge instrument (InstrumentIDToHedge) with a conversion Multiplier. The hedging engine uses this configuration for portfolio conversion operations - when it needs to hedge exposure in one instrument using a different instrument, this table provides the instrument pair and the scaling factor to apply when calculating equivalent hedge quantity.

The INSERT-capture trigger `TRG_T_PortfolioConversionConfigurations` fires on INSERT and performs a self-UPDATE (`SET InstrumentID = InstrumentID`) to force the temporal engine to write an INSERT-capture record (SysStartTime=SysEndTime zero-duration row).

This is the newer/active version of the table, superseding History.PortfolioConversionConfiguration (singular, no HostName column). The current history table has 2 rows - both INSERT-capture records for the initial configuration of InstrumentID=17 with two hedge instruments (289, 290), set up via ConfigurationManager in December 2023.

---

## 2. Business Logic

### 2.1 Portfolio Conversion Instrument Mapping

**What**: Each row in the source table defines how one instrument should be hedged using another, with a conversion multiplier.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentIDToHedge`, `Multiplier`

**Rules**:
- Composite PK in the source table: (InstrumentID, InstrumentIDToHedge). One instrument can map to multiple hedge instruments.
- Multiplier: the scaling factor for converting exposure. 1.0 means full 1:1 hedge equivalence; 0 means this mapping is disabled/inactive.
- Current active mappings (from source table as of Dec 2023):
  - InstrumentID=17 -> InstrumentIDToHedge=289, Multiplier=0 (inactive/disabled)
  - InstrumentID=17 -> InstrumentIDToHedge=290, Multiplier=1 (full hedge)
- Managed by ConfigurationManager application via BackOffice users (e.g., user "ranlev" on HostName "STG-TRD-R-HEDGE").

### 2.2 INSERT-Capture Trigger Pattern

**What**: The TRG_T_PortfolioConversionConfigurations trigger captures INSERT events in the temporal history.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- SQL Server temporal only automatically writes history on UPDATE/DELETE - not INSERT.
- On INSERT, the trigger performs `UPDATE A SET A.InstrumentID = A.InstrumentID` (self-join on the composite key) which triggers the temporal engine to write the pre-UPDATE state as a history row.
- Result: history rows where SysStartTime=SysEndTime represent INSERT-capture records.
- The two current history rows are both INSERT-capture records from Dec 2023.

---

## 3. Data Overview

| InstrumentID | InstrumentIDToHedge | Multiplier | DbLoginName | HostName | SysStartTime | SysEndTime | Meaning |
|-------------|-------------------|-----------|-------------|----------|-------------|------------|---------|
| 17 | 289 | 0 | TRAD\ranlev | STG-TRD-R-HEDGE | 2023-12-19 10:21:56 | 2023-12-19 10:21:56 | INSERT-capture record; InstrumentID=17->289 with Multiplier=0 (disabled). No subsequent changes. |
| 17 | 290 | 1 | TRAD\ranlev | STG-TRD-R-HEDGE | 2023-12-19 10:21:56 | 2023-12-19 10:21:56 | INSERT-capture record; InstrumentID=17->290 with Multiplier=1 (active hedge). No subsequent changes. |

2 rows total | Period: Dec 2023 | Only INSERT-capture records (configuration unchanged since setup)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Source instrument whose exposure is being converted/hedged. Part of the composite key from source table. FK to Trade.Instrument (fk_potfolioConvertedInstrument). |
| 2 | InstrumentIDToHedge | int | NO | - | CODE-BACKED | Target instrument used to hedge the source instrument's exposure. Part of the composite key. FK to Trade.Instrument (fk_potfolioHedgedInstrument). One InstrumentID can map to multiple InstrumentIDToHedge values. |
| 3 | Multiplier | decimal(16,8) | NO | - | CODE-BACKED | Conversion factor for calculating hedge quantity from source exposure. 0 = mapping disabled/inactive; 1.0 = full 1:1 equivalent hedge; other values = partial or scaled hedge. |
| 4 | SysStartTime | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. SQL Server temporal period start. datetime2(2) precision (10ms). SysStartTime=SysEndTime indicates INSERT-capture record from TRG_T_PortfolioConversionConfigurations. |
| 5 | SysEndTime | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this configuration version was superseded. SysStartTime=SysEndTime = INSERT-capture record. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change, computed from SUSER_NAME() in source table. Captured at write time. Typically "TRAD\{username}" format (e.g., "TRAD\ranlev"). |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from CONTEXT_INFO() in source. Set by ConfigurationManager before the write. Format: "{username};ConfigurationManager" padded with null bytes to 500 chars. |
| 8 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Server hostname from host_name() at write time. Identifies which hedge engine server (e.g., "STG-TRD-R-HEDGE") made the configuration change. Added in this version; absent in the older History.PortfolioConversionConfiguration (singular). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Hedge.PortfolioConversionConfigurations | Temporal History | This table is the declared HISTORY_TABLE for Hedge.PortfolioConversionConfigurations. |
| InstrumentID | Trade.Instrument | Implicit | Source instrument being hedged. FK enforced via fk_potfolioConvertedInstrument in source table. |
| InstrumentIDToHedge | Trade.Instrument | Implicit | Target hedge instrument. FK enforced via fk_potfolioHedgedInstrument in source table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.PortfolioConversionConfigurations | HISTORY_TABLE | Temporal system versioning | All row version changes are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PortfolioConversionConfigurations | Table | Source of all history writes via SQL Server temporal system versioning |
| Hedge.GetPortfolioConversionConfigurations | Stored Procedure | READER of source table - retrieves current portfolio conversion configuration for the hedge engine |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PortfolioConversionConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup | PRIMARY |
| Data Compression | PAGE |

---

## 8. Sample Queries

### 8.1 View change history for a specific instrument conversion mapping

```sql
SELECT InstrumentID, InstrumentIDToHedge, Multiplier, DbLoginName, HostName,
       SysStartTime, SysEndTime,
       CASE WHEN SysStartTime = SysEndTime THEN 'INSERT-capture' ELSE 'UPDATE/DELETE' END AS RecordType
FROM History.PortfolioConversionConfigurations WITH (NOLOCK)
WHERE InstrumentID = 17
ORDER BY SysStartTime;
```

### 8.2 Compare current configuration with historical versions

```sql
SELECT 'Current' AS Version, InstrumentID, InstrumentIDToHedge, Multiplier, SysStartTime
FROM Hedge.PortfolioConversionConfigurations WITH (NOLOCK)
UNION ALL
SELECT 'History', InstrumentID, InstrumentIDToHedge, Multiplier, SysStartTime
FROM History.PortfolioConversionConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, InstrumentIDToHedge, SysStartTime;
```

### 8.3 Find all multiplier changes (excluding INSERT-capture records)

```sql
SELECT InstrumentID, InstrumentIDToHedge, Multiplier, DbLoginName, HostName, SysStartTime, SysEndTime
FROM History.PortfolioConversionConfigurations WITH (NOLOCK)
WHERE SysStartTime <> SysEndTime
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PortfolioConversionConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.PortfolioConversionConfigurations.sql*
