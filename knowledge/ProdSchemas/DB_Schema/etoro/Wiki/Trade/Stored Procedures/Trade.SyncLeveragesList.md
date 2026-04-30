# Trade.SyncLeveragesList

> Publishes the full available leverages list and current default leverage for a provider-instrument pair to the trading system sync queue (Trade.SyncConfiguration), ensuring downstream consumers have current leverage options.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SyncLeveragesList is the leverage synchronization step called after a leverage configuration change. It reads the current set of available leverage values for a provider-instrument pair from Trade.ProviderInstrumentToLeverage, builds a comma-separated string, and queues TWO sync events: the full leverages list (ConfigUpdateType=2) and the default leverage value (ConfigUpdateType=3), both via Trade.SyncConfigurationAdd.

This procedure exists to propagate leverage configuration changes to downstream trading systems. When a leverage tier is added, edited, or removed, the trading engine and UI must be notified of the new set of available options and the new default. Without this sync step, downstream systems would continue using stale leverage configurations.

Data flow: Called by Trade.ProviderInstrumentLeverageAdd and Trade.ProviderInstrumentLeverageEdit (batch items #21, #18) after modifying leverage rows. Two sync events are queued in a single transaction: first the full sorted leverages list, then the default leverage. Both are consumed by downstream sync consumers reading Trade.SyncConfiguration.

---

## 2. Business Logic

### 2.1 Two Sync Events per Call

**What**: Every call to SyncLeveragesList queues exactly two sync events (leverages list + default leverage) as an atomic unit.

**Columns/Parameters Involved**: `@LeveragesList`, `@DefLeverageValue`

**Rules**:
- Event 1: ConfigurationUpdateTypeID=2 = full leverages list as comma-separated string (e.g., "1, 2, 5, 10, 20").
  - Built by SELECT concatenation from ProviderInstrumentToLeverage + Dictionary.Leverage, ORDER BY DL.Value.
  - Trailing comma trimmed: LEFT(@LeveragesList, LEN(@LeveragesList)-1).
  - If no leverages exist (LEN <= 1), empty string is queued.
- Event 2: ConfigurationUpdateTypeID=3 = default leverage value (single integer, e.g., "5").
  - Reads the row WHERE IsDefault=1 from ProviderInstrumentToLeverage for this provider+instrument.
- Both calls are within a single BEGIN TRANSACTION / COMMIT TRANSACTION.
- RETURN 0 on success; RETURN 60000 + RAISERROR on error.

**Diagram**:
```
Trade.SyncLeveragesList(@ProviderID, @InstrumentID)
    |
    v
BUILD leverages list string from ProviderInstrumentToLeverage (ordered by value)
    |
    v
SyncConfigurationAdd(@InstrumentID, ConfigType=2, "1, 2, 5, 10")  -- all leverages
    |
    v
GET default leverage (IsDefault=1)
    |
    v
SyncConfigurationAdd(@InstrumentID, ConfigType=3, "5")  -- default leverage
    |
    v
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Identifies the execution provider. Used to filter ProviderInstrumentToLeverage rows. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Identifies the instrument. Used to filter ProviderInstrumentToLeverage rows and as the InstrumentID parameter in both SyncConfigurationAdd calls. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID | Trade.ProviderInstrumentToLeverage | Reader (SELECT) | Reads all leverage tiers for this pair to build the sync list; reads IsDefault=1 for default leverage. |
| LeverageID | Dictionary.Leverage | JOIN | Resolves LeverageID to Value (integer leverage multiplier). |
| (call) | Trade.SyncConfigurationAdd | Callee | Called twice: once for ConfigType=2 (leverages list), once for ConfigType=3 (default leverage). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderInstrumentLeverageAdd | - | Caller | Calls this after adding a new leverage tier (batch item #21). |
| Trade.ProviderInstrumentLeverageEdit | - | Caller (implied by batch plan) | Calls this after editing a leverage tier (batch item #18). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SyncLeveragesList (procedure)
├── Trade.ProviderInstrumentToLeverage (table)
├── Dictionary.Leverage (table)
└── Trade.SyncConfigurationAdd (procedure)
      └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | SELECT all leverage tiers; SELECT IsDefault=1 for default. |
| Dictionary.Leverage | Table | JOIN to resolve LeverageID to integer Value. |
| Trade.SyncConfigurationAdd | Procedure | Called twice to queue leverages-list and default-leverage sync events. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentLeverageAdd | Procedure | Calls this after inserting a new leverage. |
| Trade.ProviderInstrumentLeverageEdit | Procedure | Calls this after editing a leverage. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Sync leverages list for provider 1, instrument 1

```sql
EXEC Trade.SyncLeveragesList @ProviderID = 1, @InstrumentID = 1;
-- Queues ConfigType=2 (leverages list) and ConfigType=3 (default) to Trade.SyncConfiguration
```

### 8.2 Preview what leverages list would be built

```sql
SELECT STRING_AGG(CAST(DL.Value AS VARCHAR(10)), ', ') WITHIN GROUP (ORDER BY DL.Value) AS LeveragesList,
       MAX(CASE WHEN TPI.IsDefault = 1 THEN DL.Value END) AS DefaultLeverage
FROM Trade.ProviderInstrumentToLeverage TPI WITH (NOLOCK)
JOIN Dictionary.Leverage DL WITH (NOLOCK) ON TPI.LeverageID = DL.LeverageID
WHERE TPI.ProviderID = 1 AND TPI.InstrumentID = 1;
```

### 8.3 Verify sync events were queued

```sql
SELECT TOP 5 ID, ConfigurationUpdateTypeID, InstrumentID, Value
FROM Trade.SyncConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY ID DESC;
-- Should show ConfigType=2 (list) and ConfigType=3 (default) entries
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncLeveragesList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SyncLeveragesList.sql*
