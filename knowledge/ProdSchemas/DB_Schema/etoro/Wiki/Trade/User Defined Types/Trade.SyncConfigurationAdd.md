# Trade.SyncConfigurationAdd

> TVP used to batch-add instrument sync configurations (leverages, max position units, min position amount, etc.) to instrument trading and metadata configuration procedures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int), ConfigurationUpdateTypeID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

SyncConfigurationAdd carries instrument-specific sync configuration updates. Each row represents a single configuration entry for an instrument: InstrumentID identifies the instrument, ConfigurationUpdateTypeID identifies the kind of configuration (e.g., 2=leverages list, 3=default leverage, 4=max position units, 6=min position amount), and Value holds the configuration string or number.

This type exists because multiple trading and metadata operations need to push configuration changes into Trade tables (instruments trading configurations, metadata configurations, futures configs). Services and admin tools pass batches of configuration updates as TVPs to avoid round-trips and enable bulk sync.

The type flows from services and admin procedures (e.g., SyncLeveragesList, ProviderInstrumentLeverageEdit) that build configuration values, into procedures like UpdateInstrumentsTradingConfigurations, UpdateInstrumentsMetaDataConfigurations, UpdateFuturesTradingConfigurations, and UpdateInstrumentsTradingOrdersConfigurations, which SELECT from the TVP and merge into the target configuration tables.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups (InstrumentID, ConfigurationUpdateTypeID) with a Value - each row is an independent configuration entry.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier |
| 2 | ConfigurationUpdateTypeID | int | NO | - | CODE-BACKED | Type of configuration (2=leverages, 3=default leverage, 4=max position units, 6=min position amount) |
| 3 | Value | varchar(1000) | NO | - | CODE-BACKED | Configuration value (e.g., comma-separated leverages, single numeric value) |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsTradingConfigurations | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Merges sync configurations into instrument trading configs |
| Trade.UpdateInstrumentsMetaDataConfigurations | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Merges sync configurations into instrument metadata configs |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Extended metadata configuration sync |
| Trade.UpdateInstrumentsTradingConfigurationsTmp | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Temporary/template config sync |
| Trade.UpdateFuturesTradingConfigurations | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Syncs configurations for futures instruments |
| Trade.UpdateInstrumentsTradingOrdersConfigurations | @InstrumentSyncConfigurationAddTable | Parameter (TVP) | Syncs order-related configurations |
| Trade.SyncConfigurationAdd (procedure) | - | Invoked by | Procedure SyncConfigurationAdd uses scalar params; callers use TVP in other procedures |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsTradingConfigurations | Stored Procedure | READONLY parameter for config merge |
| Trade.UpdateInstrumentsMetaDataConfigurations | Stored Procedure | READONLY parameter for metadata config merge |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Stored Procedure | READONLY parameter for extended metadata |
| Trade.UpdateInstrumentsTradingConfigurationsTmp | Stored Procedure | READONLY parameter for config sync |
| Trade.UpdateFuturesTradingConfigurations | Stored Procedure | READONLY parameter for futures config sync |
| Trade.UpdateInstrumentsTradingOrdersConfigurations | Stored Procedure | READONLY parameter for order config sync |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for leverage sync
```sql
DECLARE @InstrumentSyncConfigurationAddTable Trade.SyncConfigurationAdd;
INSERT INTO @InstrumentSyncConfigurationAddTable (InstrumentID, ConfigurationUpdateTypeID, Value)
VALUES (12345, 3, '100');
EXEC Trade.UpdateInstrumentsTradingConfigurations @InstrumentSyncConfigurationAddTable = @InstrumentSyncConfigurationAddTable;
```

### 8.2 Declare and populate for max position units
```sql
DECLARE @InstrumentSyncConfigurationAddTable Trade.SyncConfigurationAdd;
INSERT INTO @InstrumentSyncConfigurationAddTable (InstrumentID, ConfigurationUpdateTypeID, Value)
VALUES (12345, 4, '50000');
EXEC Trade.UpdateInstrumentsTradingConfigurations @InstrumentSyncConfigurationAddTable = @InstrumentSyncConfigurationAddTable;
```

### 8.3 Multi-row batch sync
```sql
DECLARE @InstrumentSyncConfigurationAddTable Trade.SyncConfigurationAdd;
INSERT INTO @InstrumentSyncConfigurationAddTable (InstrumentID, ConfigurationUpdateTypeID, Value)
VALUES (100, 3, '50'), (101, 3, '100'), (102, 4, '10000');
EXEC Trade.UpdateInstrumentsTradingConfigurations @InstrumentSyncConfigurationAddTable = @InstrumentSyncConfigurationAddTable;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncConfigurationAdd | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SyncConfigurationAdd.sql*
