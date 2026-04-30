# Trade.UpdateInstrumentsMaxStopLossPrecentage

> Batch-updates MaxStopLossPercentage in Trade.ProviderToInstrument and queues a SyncConfiguration event (type 7) per instrument to synchronize the change to the trading engine. (Note: "Precentage" is a typo in the original procedure name.)

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentMaxSLConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsMaxStopLossPrecentage sets the maximum stop-loss percentage for each instrument in `Trade.ProviderToInstrument`. `MaxStopLossPercentage` defines the furthest below entry price (as a percentage) that a customer can set a stop-loss order. This caps the downside risk exposure that eToro allows customers to take on a per-instrument basis - for example, limiting stop-losses to no more than 95% below entry for volatile instruments.

The procedure name contains a known typo ("Precentage" instead of "Percentage") that has been preserved for backward compatibility with callers. OpsFlowAPI has EXECUTE permission.

After updating the database, the procedure queues a SyncConfiguration event (ConfigurationUpdateTypeID=7) to notify the trading engine of the new max stop-loss limit without requiring a restart.

---

## 2. Business Logic

### 2.1 ProviderToInstrument Update + SyncConfiguration Queue

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET MaxStopLossPercentage=f.ConfigurationValue INNER JOIN @InstrumentNewConfigTable f ON f.InstrumentID=TI.InstrumentID`
- `INSERT INTO Trade.SyncConfiguration (ConfigurationUpdateTypeID, InstrumentID, Value) SELECT 7, InstrumentID, ConfigurationValue FROM @InstrumentNewConfigTable`
- ConfigurationUpdateTypeID=7 = MaxStopLossPercentage sync event type
- Both statements inside BEGIN TRAN / COMMIT TRAN

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentMaxSLConfigTable READONLY | NO | - | CODE-BACKED | TVP with the new MaxStopLossPercentage values. Each row: InstrumentID (JOIN key), ConfigurationValue (the new max stop-loss percentage, e.g., 95 = customers cannot set SL more than 95% below entry). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentMaxSLConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates MaxStopLossPercentage per InstrumentID |
| INSERT target | Trade.SyncConfiguration | Writer | Queues ConfigurationUpdateTypeID=7 sync events |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OpsFlowAPI (DB role) | GRANT EXECUTE | Permission | Trading operations API calls this to configure max stop-loss limits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMaxStopLossPrecentage (procedure)
+-- Trade.InstrumentMaxSLConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
+-- Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMaxSLConfigTable | User Defined Type (TVP) | Input parameter type (InstrumentID, ConfigurationValue) |
| Trade.ProviderToInstrument | Table | UPDATE target for MaxStopLossPercentage |
| Trade.SyncConfiguration | Table | INSERT target for ConfigurationUpdateTypeID=7 sync events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OpsFlowAPI (DB role) | Permission grantee | Trading operations API for stop-loss configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON, BEGIN TRAN/COMMIT, TRY/CATCH with THROW. Name typo "Precentage" is intentional preservation for backward compatibility.

---

## 8. Sample Queries

### 8.1 Update MaxStopLossPercentage for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentMaxSLConfigTable;

INSERT INTO @Config (InstrumentID, ConfigurationValue)
VALUES
  (1001, 95),   -- max 95% SL below entry
  (1002, 90);

EXEC Trade.UpdateInstrumentsMaxStopLossPrecentage @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current MaxStopLossPercentage
```sql
SELECT InstrumentID, MaxStopLossPercentage
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
*Object: Trade.UpdateInstrumentsMaxStopLossPrecentage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMaxStopLossPrecentage.sql*
