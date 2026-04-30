# Trade.ProviderToInstrumentSetMaxPositionUnits

> Updates the maximum position units limit for a provider-instrument pair in Trade.ProviderToInstrument and immediately queues a ConfigType=4 sync event to notify downstream trading system consumers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderToInstrumentSetMaxPositionUnits sets the maximum number of instrument units that can be held in a single position for a given execution provider and instrument. This cap controls position sizing risk at the provider level - different providers may have different maximum exposure limits for the same instrument. After updating Trade.ProviderToInstrument.MaxPositionUnits, it immediately notifies downstream consumers via Trade.SyncConfigurationAdd with ConfigurationUpdateTypeID=4 (max position units sync type).

This procedure exists to support dynamic risk management configuration. Operators can tighten or loosen position size limits without restarting trading services - the sync queue propagates the change to the trading engine and UI in real time. The MaxPositionUnits constraint prevents outsized positions that could exceed a provider's hedging capacity or regulatory limits.

Data flow: Called by back-office risk management tools. Updates Trade.ProviderToInstrument (the provider-instrument configuration table). Queues to Trade.SyncConfiguration via Trade.SyncConfigurationAdd for consumption by downstream trading system components.

---

## 2. Business Logic

### 2.1 MaxPositionUnits Update and Sync

**What**: Updates the maximum position units limit and immediately propagates it to the sync queue.

**Columns/Parameters Involved**: `MaxPositionUnits`, `@MaxPositionUnits`, `ConfigurationUpdateTypeID=4`

**Rules**:
- UPDATE Trade.ProviderToInstrument SET MaxPositionUnits=@MaxPositionUnits WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID.
- After UPDATE: EXEC Trade.SyncConfigurationAdd @InstrumentID, 4, CAST(@MaxPositionUnits AS VARCHAR(500)).
- ConfigType=4 = max position units. The value is cast to varchar for the generic varchar(500) Value column in Trade.SyncConfiguration.
- The decimal value is passed directly - format depends on caller; CAST uses default decimal-to-string conversion.

**Diagram**:
```
Trade.ProviderToInstrumentSetMaxPositionUnits(@ProviderID, @InstrumentID, @MaxPositionUnits)
    |
    v
UPDATE Trade.ProviderToInstrument SET MaxPositionUnits=@MaxPositionUnits WHERE PK
    |
    v
EXEC Trade.SyncConfigurationAdd(@InstrumentID, 4, CAST(@MaxPositionUnits AS VARCHAR(500)))
    |
    v
COMMIT / RETURN 0 or RAISERROR 60000
```

### 2.2 Transaction and Error Handling

**What**: Wraps the update and sync call in a transaction with TRY/CATCH.

**Rules**:
- BEGIN TRANSACTION / COMMIT TRANSACTION wraps the full operation.
- On error: ROLLBACK, RAISERROR, RETURN 60000.
- RETURN 0 on success.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Execution provider identifier. With @InstrumentID forms the PK of Trade.ProviderToInstrument being updated. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Instrument identifier. Used in the PK filter and as the InstrumentID for Trade.SyncConfigurationAdd. |
| 3 | @MaxPositionUnits | DECIMAL | NO | - | CODE-BACKED | The new maximum number of instrument units for a single position. Cast to VARCHAR(500) for the sync queue payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID | Trade.ProviderToInstrument | Modifier (UPDATE) | Sets MaxPositionUnits for the specified provider-instrument pair. |
| (call) | Trade.SyncConfigurationAdd | Callee | Called with ConfigType=4 and the new MaxPositionUnits value (as varchar) to queue the change for downstream consumers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office risk management tools | - | Caller | Called when operators adjust maximum position size limits. |
| Trade.UpdateInstrumentsTradingConfigurations | - | Caller (implied) | Bulk configuration update procedure that calls SyncConfigurationAdd for ConfigType=4; may call this or call SyncConfigurationAdd directly. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrumentSetMaxPositionUnits (procedure)
├── Trade.ProviderToInstrument (table)
└── Trade.SyncConfigurationAdd (procedure)
      └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATE target for MaxPositionUnits column. |
| Trade.SyncConfigurationAdd | Procedure | Called with ConfigType=4 to queue max position units sync event. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office risk management | External callers | Calls this to update position size limits dynamically. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: ConfigurationUpdateTypeID=4 maps specifically to "max position units" in the sync type registry. The companion procedure Trade.ProviderToInstrumentSetMimPositionAmount (note: "Mim" is a typo in the procedure name) handles ConfigType=6 (minimum position amount). Both follow the same update-then-sync pattern.

---

## 8. Sample Queries

### 8.1 Set max position units to 10000 for provider 1, instrument 1

```sql
EXEC Trade.ProviderToInstrumentSetMaxPositionUnits
    @ProviderID = 1,
    @InstrumentID = 1,
    @MaxPositionUnits = 10000;
-- Updates MaxPositionUnits=10000 and queues ConfigType=4 sync event
```

### 8.2 View current MaxPositionUnits for an instrument

```sql
SELECT ProviderID, InstrumentID, MaxPositionUnits, MinPositionAmount
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY ProviderID;
```

### 8.3 Check pending sync events for max position units

```sql
SELECT TOP 10 ID, ConfigurationUpdateTypeID, InstrumentID, Value, Occurred
FROM Trade.SyncConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1 AND ConfigurationUpdateTypeID = 4
ORDER BY ID DESC;
-- ConfigType=4 = max position units
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentSetMaxPositionUnits | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderToInstrumentSetMaxPositionUnits.sql*
