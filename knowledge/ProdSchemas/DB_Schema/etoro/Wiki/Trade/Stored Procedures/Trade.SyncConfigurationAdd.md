# Trade.SyncConfigurationAdd

> Inserts a single instrument configuration change event into the sync queue (Trade.SyncConfiguration), enabling downstream systems to propagate the updated value.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @ConfigurationUpdateID as the logical key for each queued event |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SyncConfigurationAdd is the standard writer for the Trade.SyncConfiguration queue table. It accepts a single configuration change event (the instrument, the type of change, and the new value) and appends it to the queue for downstream sync consumers to pick up and propagate to other systems.

This procedure exists to centralize and standardize how configuration change events are enqueued. All higher-level configuration update procedures (leverage edits, metadata updates, trading configuration changes, futures configurations) call this as a final step to register their changes in the sync queue. Without this procedure, each caller would write directly to Trade.SyncConfiguration, bypassing error handling and creating coupling to the queue table's physical structure.

Data flow: A caller (such as Trade.SyncLeveragesList or Trade.UpdateInstrumentsTradingConfigurations) performs the main configuration update and then calls this procedure to enqueue the event. The procedure inserts a row into Trade.SyncConfiguration and returns 0 on success. If the insert fails (e.g., constraint violation), the TRY/CATCH block raises error 60000 and returns that code to the caller.

---

## 2. Business Logic

### 2.1 Queue Insertion with Error Propagation

**What**: Wraps the INSERT into Trade.SyncConfiguration in a TRY/CATCH to standardize error handling and return codes for all callers.

**Columns/Parameters Involved**: `@InstrumentID`, `@ConfigurationUpdateID`, `@Value`

**Rules**:
- The parameter @ConfigurationUpdateID maps to the column ConfigurationUpdateTypeID (the parameter name differs from the column name - the original commented-out code shows a lookup was planned but never implemented).
- On success: RETURN 0.
- On any error: captures ERROR_NUMBER(), raises RAISERROR 60000 with context "Trade.SyncConfigurationAdd" and the captured error number, then RETURN 60000.
- No validation is performed on @Value content - format is governed by the ConfigurationUpdateTypeID convention.

**Diagram**:
```
Caller (e.g., SyncLeveragesList)
    |
    v
Trade.SyncConfigurationAdd(@InstrumentID, @ConfigurationUpdateID, @Value)
    |
    +-- TRY: INSERT INTO Trade.SyncConfiguration -> RETURN 0
    |
    +-- CATCH: RAISERROR(60000) -> RETURN 60000
```

### 2.2 Parameter Name Mismatch (Historical Note)

**What**: The parameter @ConfigurationUpdateID maps to the column ConfigurationUpdateTypeID. There is a commented-out block that was intended to look up ConfigurationUpdateTypeID from Dictionary.ConfigurationUpdateType by name (@ConfigurationUpdateDesc) - this was never implemented, so callers pass the ID directly.

**Columns/Parameters Involved**: `@ConfigurationUpdateID`, `ConfigurationUpdateTypeID`

**Rules**:
- @ConfigurationUpdateID is inserted directly as ConfigurationUpdateTypeID.
- No dictionary lookup occurs at procedure runtime.
- Callers are responsible for passing the correct integer ID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The instrument whose configuration was changed. Inserted into Trade.SyncConfiguration.InstrumentID. FK to Trade.Instrument. |
| 2 | @ConfigurationUpdateID | INT | NO | - | CODE-BACKED | The type of configuration change (spread, leverage, trading hours, metadata, etc.). Mapped directly to Trade.SyncConfiguration.ConfigurationUpdateTypeID. Callers supply the integer ID; no dictionary lookup is performed. Note: parameter name differs from the column it populates (ConfigurationUpdateTypeID). |
| 3 | @Value | varchar(500) | NO | - | CODE-BACKED | The new configuration value as a string. Format depends on the ConfigurationUpdateTypeID - examples: "1.5" for spread, "10" for leverage multiplier. Inserted into Trade.SyncConfiguration.Value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument whose configuration changed. |
| @ConfigurationUpdateID | Dictionary.ConfigurationUpdateType | Implicit | Identifies the type of configuration change. The commented-out lookup shows this table was the intended source of the ID. |
| (procedure) | Trade.SyncConfiguration | Writer (INSERT) | Appends a new configuration sync event to the queue. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SyncLeveragesList | - | Caller | Calls this to enqueue leverage configuration changes after syncing provider leverage lists. |
| Trade.ProviderInstrumentLeverageEdit | - | Caller | Calls this after editing a provider instrument leverage configuration. |
| Trade.ProviderToInstrumentSetMaxPositionUnits | - | Caller | Calls this after updating max position units for a provider-instrument mapping. |
| Trade.ProviderToInstrumentSetMimPositionAmount | - | Caller | Calls this after updating minimum position amount for a provider-instrument mapping. |
| Trade.UpdateInstrumentsTradingConfigurations | - | Caller | Calls this when propagating trading configuration updates for instruments. |
| Trade.UpdateInstrumentsTradingConfigurationsTmp | - | Caller | Temporary/staging variant of the above; also calls this. |
| Trade.UpdateInstrumentsTradingOrdersConfigurations | - | Caller | Calls this after updating order-level trading configurations. |
| Trade.UpdateInstrumentsMetaDataConfigurations | - | Caller | Calls this after updating instrument metadata configuration values. |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | - | Caller | Extended metadata configuration updater; also calls this. |
| Trade.UpdateFuturesTradingConfigurations | - | Caller | Calls this for futures instrument trading configuration changes. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SyncConfigurationAdd (procedure)
└── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncConfiguration | Table | INSERT - appends a configuration sync event to the queue. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncLeveragesList | Procedure | Calls this to queue leverage sync events. |
| Trade.ProviderInstrumentLeverageEdit | Procedure | Calls this after leverage edits. |
| Trade.ProviderToInstrumentSetMaxPositionUnits | Procedure | Calls this after max-units updates. |
| Trade.ProviderToInstrumentSetMimPositionAmount | Procedure | Calls this after min-amount updates. |
| Trade.UpdateInstrumentsTradingConfigurations | Procedure | Calls this during trading configuration propagation. |
| Trade.UpdateInstrumentsTradingConfigurationsTmp | Procedure | Calls this (staging/temp variant). |
| Trade.UpdateInstrumentsTradingOrdersConfigurations | Procedure | Calls this for order configuration updates. |
| Trade.UpdateInstrumentsMetaDataConfigurations | Procedure | Calls this for metadata configuration updates. |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Procedure | Calls this (extended metadata variant). |
| Trade.UpdateFuturesTradingConfigurations | Procedure | Calls this for futures configuration updates. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Add a leverage configuration sync event

```sql
-- Queue a leverage change for InstrumentID=5, ConfigurationUpdateTypeID=2, new value "10"
EXEC Trade.SyncConfigurationAdd
    @InstrumentID = 5,
    @ConfigurationUpdateID = 2,
    @Value = '10';
```

### 8.2 Verify the queued event was inserted

```sql
SELECT TOP 5 ID, ConfigurationUpdateTypeID, InstrumentID, Value
FROM Trade.SyncConfiguration WITH (NOLOCK)
ORDER BY ID DESC;
```

### 8.3 See all callers by examining recent queue entries for a specific instrument

```sql
SELECT TOP 10 ID, ConfigurationUpdateTypeID, InstrumentID, Value
FROM Trade.SyncConfiguration WITH (NOLOCK)
WHERE InstrumentID = 5
ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncConfigurationAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SyncConfigurationAdd.sql*
