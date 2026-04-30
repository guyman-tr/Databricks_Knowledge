# Trade.UpdateInstrumentsMaxRateDiffPercentage

> Batch-updates AllowedRateDiffPercentage in Trade.ProviderToInstrument and queues a SyncConfiguration event (type 8) per instrument to synchronize the change to the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentsMaxRateDiffConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsMaxRateDiffPercentage configures the maximum allowed rate difference percentage for order execution on each instrument. `AllowedRateDiffPercentage` in `Trade.ProviderToInstrument` defines how much a trade's execution price can deviate (as a percentage) from the requested rate before the order is considered out of range. This is a core execution quality parameter - too tight a value causes frequent order rejections; too loose allows excessive slippage.

The procedure follows the same pattern as `Trade.UpdateInstrumentsMaxPositionUnits`: update the configuration column and insert a SyncConfiguration event in the same transaction. ConfigurationUpdateTypeID=8 is the sync type for AllowedRateDiffPercentage changes, consumed by the trading engine to apply the new tolerance without a restart.

OpsFlowAPI has EXECUTE permission, indicating this is called via the trading operations API.

---

## 2. Business Logic

### 2.1 ProviderToInstrument Update + SyncConfiguration Queue

**What**: Updates AllowedRateDiffPercentage in Trade.ProviderToInstrument and queues a SyncConfiguration event (type 8) in the same transaction.

**Columns/Parameters Involved**: `@InstrumentNewConfigTable.InstrumentID`, `.ConfigurationValue`, `Trade.ProviderToInstrument.AllowedRateDiffPercentage`, `Trade.SyncConfiguration.ConfigurationUpdateTypeID`

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET AllowedRateDiffPercentage=f.ConfigurationValue INNER JOIN @InstrumentNewConfigTable f ON f.InstrumentID=TI.InstrumentID`
- `INSERT INTO Trade.SyncConfiguration (ConfigurationUpdateTypeID, InstrumentID, Value) SELECT 8, InstrumentID, ConfigurationValue FROM @InstrumentNewConfigTable`
- ConfigurationUpdateTypeID=8 = AllowedRateDiffPercentage sync event type
- Both statements inside BEGIN TRAN / COMMIT TRAN

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentsMaxRateDiffConfigTable READONLY | NO | - | CODE-BACKED | TVP with the new AllowedRateDiffPercentage values per instrument. Each row: InstrumentID (JOIN key to ProviderToInstrument), ConfigurationValue (the new maximum allowed rate difference percentage, e.g., 0.5 = 0.5%). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentsMaxRateDiffConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates AllowedRateDiffPercentage per InstrumentID |
| INSERT target | Trade.SyncConfiguration | Writer | Queues ConfigurationUpdateTypeID=8 sync events for the trading engine |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OpsFlowAPI (DB role) | GRANT EXECUTE | Permission | Trading operations API calls this to update rate diff tolerance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMaxRateDiffPercentage (procedure)
+-- Trade.InstrumentsMaxRateDiffConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
+-- Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsMaxRateDiffConfigTable | User Defined Type (TVP) | Input parameter type (InstrumentID, ConfigurationValue) |
| Trade.ProviderToInstrument | Table | UPDATE target for AllowedRateDiffPercentage |
| Trade.SyncConfiguration | Table | INSERT target for ConfigurationUpdateTypeID=8 sync events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OpsFlowAPI (DB role) | Permission grantee | Trading operations API calls this to configure rate diff tolerance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp table or index created.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON, BEGIN TRAN/COMMIT, TRY/CATCH with THROW.

---

## 8. Sample Queries

### 8.1 Update AllowedRateDiffPercentage for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentsMaxRateDiffConfigTable;

INSERT INTO @Config (InstrumentID, ConfigurationValue)
VALUES
  (1001, 0.50),
  (1002, 0.75);

EXEC Trade.UpdateInstrumentsMaxRateDiffPercentage @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current rate diff settings
```sql
SELECT InstrumentID, AllowedRateDiffPercentage
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
*Object: Trade.UpdateInstrumentsMaxRateDiffPercentage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMaxRateDiffPercentage.sql*
