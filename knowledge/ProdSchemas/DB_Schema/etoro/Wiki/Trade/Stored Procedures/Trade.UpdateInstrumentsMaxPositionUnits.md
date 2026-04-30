# Trade.UpdateInstrumentsMaxPositionUnits

> Batch-updates MaxPositionUnits in Trade.ProviderToInstrument and queues a SyncConfiguration event (type 4) per instrument to synchronize the change to the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentMaxPositionUnitsConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsMaxPositionUnits sets the maximum number of position units a customer can hold for each instrument. `MaxPositionUnits` in `Trade.ProviderToInstrument` caps the total units any single customer can have open on a given instrument at once - a risk management limit that prevents position concentration.

After updating the database value, the procedure also inserts a record into `Trade.SyncConfiguration` with ConfigurationUpdateTypeID=4 (MaxPositionUnits). This sync queue is consumed by the trading engine to apply the new limits without requiring a service restart. The two-step write (update + sync queue) ensures the database and the in-memory trading engine stay consistent.

---

## 2. Business Logic

### 2.1 ProviderToInstrument Update + SyncConfiguration Queue

**What**: Updates MaxPositionUnits in Trade.ProviderToInstrument and queues a SyncConfiguration event in the same transaction.

**Columns/Parameters Involved**: `@InstrumentNewConfigTable.InstrumentID`, `.ConfigurationValue`, `Trade.ProviderToInstrument.MaxPositionUnits`, `Trade.SyncConfiguration.ConfigurationUpdateTypeID`

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET MaxPositionUnits=f.ConfigurationValue INNER JOIN @InstrumentNewConfigTable f ON f.InstrumentID=TI.InstrumentID`
- `INSERT INTO Trade.SyncConfiguration (ConfigurationUpdateTypeID, InstrumentID, Value) SELECT 4, InstrumentID, ConfigurationValue FROM @InstrumentNewConfigTable`
- ConfigurationUpdateTypeID=4 = MaxPositionUnits sync event type
- Both statements inside BEGIN TRAN / COMMIT TRAN - atomic update + queue
- CATCH: rollback if @@TRANCOUNT=1, commit if @@TRANCOUNT>1 (nested transaction pattern)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentMaxPositionUnitsConfigTable READONLY | NO | - | CODE-BACKED | TVP with the new MaxPositionUnits values per instrument. Each row: InstrumentID (JOIN key to ProviderToInstrument), ConfigurationValue (the new maximum position units limit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentMaxPositionUnitsConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates MaxPositionUnits per InstrumentID |
| INSERT target | Trade.SyncConfiguration | Writer | Queues ConfigurationUpdateTypeID=4 sync events for the trading engine |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no explicit EXECUTE grants found. PROD_BIadmins has VIEW DEFINITION. Invoked by configuration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMaxPositionUnits (procedure)
+-- Trade.InstrumentMaxPositionUnitsConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
+-- Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMaxPositionUnitsConfigTable | User Defined Type (TVP) | Input parameter type (InstrumentID, ConfigurationValue) |
| Trade.ProviderToInstrument | Table | UPDATE target for MaxPositionUnits |
| Trade.SyncConfiguration | Table | INSERT target for ConfigurationUpdateTypeID=4 sync events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (configuration tooling) | - | Called when adjusting maximum position unit limits per instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp table or index created - TVP used directly in the UPDATE.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON, BEGIN TRAN/COMMIT, TRY/CATCH with THROW.

---

## 8. Sample Queries

### 8.1 Update MaxPositionUnits for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentMaxPositionUnitsConfigTable;

INSERT INTO @Config (InstrumentID, ConfigurationValue)
VALUES
  (1001, 1000),
  (1002, 500);

EXEC Trade.UpdateInstrumentsMaxPositionUnits @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current MaxPositionUnits settings
```sql
SELECT InstrumentID, MaxPositionUnits
FROM   Trade.ProviderToInstrument WITH (NOLOCK)
WHERE  InstrumentID IN (1001, 1002);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsMaxPositionUnits | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMaxPositionUnits.sql*
