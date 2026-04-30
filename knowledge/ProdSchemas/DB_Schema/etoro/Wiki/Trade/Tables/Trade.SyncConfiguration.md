# Trade.SyncConfiguration

> Queue table for propagating instrument configuration changes (spread, leverage, trading hours, etc.) to downstream systems. Rows are consumed after sync and typically empty at rest.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK CLUSTERED on ID) |

---

## 1. Business Meaning

Trade.SyncConfiguration is a queue-style table that holds instrument configuration change events for propagation to downstream systems. When an instrument's configuration is modified (spread, leverage, trading hours, swap rates, or other tradeable parameters), a row is inserted here with ConfigurationUpdateTypeID identifying what changed, the InstrumentID, and the new Value. Sync consumers read and process these entries, then typically delete or mark them as processed.

This table exists because trading configuration changes must be distributed to multiple systems (price feeds, risk engines, mobile apps, compliance systems) that maintain their own copies or caches of instrument settings. Without a centralized queue, each consumer would need to poll the source or receive push notifications through separate channels. The queue pattern allows decoupled, reliable propagation.

Data flows: Rows are inserted by Trade.SyncConfigurationAdd (or equivalent) when instrument configuration is updated. Downstream sync jobs or procedures read the table, process rows in order, and remove them. The table is typically empty when no recent changes have occurred or all pending changes have been consumed. Live data is empty (queue-like, consumed after sync).

---

## 2. Business Logic

### 2.1 Queue Consumption Pattern

**What**: Rows are produced on configuration change and consumed by sync processes.

**Columns/Parameters Involved**: `ID`, `ConfigurationUpdateTypeID`, `InstrumentID`, `Value`

**Rules**:
- IDENTITY(1,1) NOT FOR REPLICATION: ID is not auto-generated on subscriber during replication; avoids ID collisions in replicated topologies
- Rows are inserted with ascending ID; consumers process in ID order for FIFO semantics
- After processing, rows are typically deleted or marked; table stays empty or near-empty at rest
- ConfigurationUpdateTypeID identifies the type of change (spread, leverage, hours, etc.) so consumers know how to interpret Value

**Diagram**:
```
[Instrument config UPDATE] -> Trade.SyncConfigurationAdd -> INSERT row
        |
        v
  [Sync consumer reads] -> Process -> DELETE or mark processed
        |
        v
  Table empty or minimal rows
```

---

## 3. Data Overview

| ID | ConfigurationUpdateTypeID | InstrumentID | Value | Meaning |
|---|---|---|---|---|
| (Table is EMPTY in environment) | - | - | - | No live rows. Queue-like behavior: rows are consumed after sync. When populated: ID=1, ConfigurationUpdateTypeID=1 (e.g., spread change), InstrumentID=5, Value="1.5" would mean EUR/USD spread was updated to 1.5 pips; sync consumer would propagate this to downstream systems. |

**Selection criteria:**
- Table is empty. Representative rows would show variety of ConfigurationUpdateTypeID values and different instruments. Value column stores the new configuration value as a string (varchar 2000).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier for each sync queue entry. NOT FOR REPLICATION: ID is not auto-generated on subscriber during replication, avoiding collisions in replicated environments. Used for FIFO ordering. |
| 2 | ConfigurationUpdateTypeID | int | NO | - | CODE-BACKED | Identifies what type of configuration changed (spread, leverage, trading hours, etc.). Lookup to configuration type dictionary. Consumers use this to interpret Value and route updates correctly. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument.InstrumentID. The instrument whose configuration was updated. |
| 4 | Value | varchar(2000) | NO | - | CODE-BACKED | The new configuration value as a string. Format depends on ConfigurationUpdateTypeID. Examples: spread as "1.5", leverage as "10", trading hours as JSON or encoded string. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument whose configuration changed. |
| ConfigurationUpdateTypeID | (Dictionary/config table) | Implicit | Lookup for configuration change type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SyncConfigurationAdd | - | Writer | Inserts rows when instrument configuration is modified. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SyncConfiguration (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncConfigurationAdd | Procedure | Writes (INSERT) rows when instrument configuration changes. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (ID) | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | ID is the primary key. IDENTITY NOT FOR REPLICATION ensures no auto-generation on subscriber. |

---

## 8. Sample Queries

### 8.1 Read pending sync entries (FIFO)

```sql
SELECT TOP 100 ID, ConfigurationUpdateTypeID, InstrumentID, Value
FROM Trade.SyncConfiguration WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find sync entries for a specific instrument

```sql
SELECT ID, ConfigurationUpdateTypeID, InstrumentID, Value
FROM Trade.SyncConfiguration WITH (NOLOCK)
WHERE InstrumentID = 5
ORDER BY ID;
```

### 8.3 Join to instrument for human-readable context

```sql
SELECT sc.ID, sc.ConfigurationUpdateTypeID, sc.InstrumentID, sc.Value,
       i.BuyCurrencyID, i.SellCurrencyID
FROM Trade.SyncConfiguration sc WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = sc.InstrumentID
ORDER BY sc.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncConfiguration | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SyncConfiguration.sql*
