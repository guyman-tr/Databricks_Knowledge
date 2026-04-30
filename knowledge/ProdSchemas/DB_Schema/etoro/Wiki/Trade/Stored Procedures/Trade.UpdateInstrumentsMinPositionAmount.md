# Trade.UpdateInstrumentsMinPositionAmount

> Batch-updates MinPositionAmount in Trade.ProviderToInstrument and queues a SyncConfiguration event (type 6) per instrument, converting the value to varchar with style 2 for the sync queue entry.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentMinPositionAmountConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsMinPositionAmount sets the minimum dollar amount a customer must invest to open a position on each instrument. `MinPositionAmount` in `Trade.ProviderToInstrument` enforces the minimum trade size - for example, requiring at least $50 to open a stock position or $25 for a crypto position. This is a customer-facing limit that protects both the customer (avoids trivially small positions) and eToro (avoids positions too small to be worth executing).

The procedure queues a SyncConfiguration event (ConfigurationUpdateTypeID=6) to notify the trading engine. The sync queue stores the value as a varchar with CONVERT style 2, which formats the decimal value without trailing zeros (scientific notation suppressed) - suitable for string-based configuration parsing by the engine.

---

## 2. Business Logic

### 2.1 ProviderToInstrument Update + SyncConfiguration Queue

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET MinPositionAmount=f.ConfigurationValue INNER JOIN @InstrumentNewConfigTable f ON f.InstrumentID=TI.InstrumentID`
- `INSERT INTO Trade.SyncConfiguration (ConfigurationUpdateTypeID, InstrumentID, Value) SELECT 6, InstrumentID, CONVERT(varchar(50), ConfigurationValue, 2) FROM @InstrumentNewConfigTable`
- ConfigurationUpdateTypeID=6 = MinPositionAmount sync event type
- `CONVERT(varchar(50), ConfigurationValue, 2)` formats the numeric value as a string: style 2 for float conversion removes trailing zeros and produces a clean decimal string (e.g., 50.00 -> "50")
- Both statements inside BEGIN TRAN / COMMIT TRAN

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentMinPositionAmountConfigTable READONLY | NO | - | CODE-BACKED | TVP with the new MinPositionAmount values. Each row: InstrumentID (JOIN key to ProviderToInstrument), ConfigurationValue (the new minimum position dollar amount, e.g., 50.00 = minimum $50 investment). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentMinPositionAmountConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates MinPositionAmount per InstrumentID |
| INSERT target | Trade.SyncConfiguration | Writer | Queues ConfigurationUpdateTypeID=6 sync events (value converted to varchar with style 2) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. PROD_BIadmins has VIEW DEFINITION. Invoked by configuration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMinPositionAmount (procedure)
+-- Trade.InstrumentMinPositionAmountConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
+-- Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMinPositionAmountConfigTable | User Defined Type (TVP) | Input parameter type (InstrumentID, ConfigurationValue) |
| Trade.ProviderToInstrument | Table | UPDATE target for MinPositionAmount |
| Trade.SyncConfiguration | Table | INSERT target for ConfigurationUpdateTypeID=6 sync events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (configuration tooling) | - | Called when adjusting minimum position amount limits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON, BEGIN TRAN/COMMIT, TRY/CATCH with THROW. The `CONVERT(varchar(50), ConfigurationValue, 2)` style is distinct from the other SyncConfiguration procedures that pass the value directly.

---

## 8. Sample Queries

### 8.1 Update MinPositionAmount for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentMinPositionAmountConfigTable;

INSERT INTO @Config (InstrumentID, ConfigurationValue)
VALUES
  (1001, 50.00),
  (1002, 25.00);

EXEC Trade.UpdateInstrumentsMinPositionAmount @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current MinPositionAmount settings
```sql
SELECT InstrumentID, MinPositionAmount
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
*Object: Trade.UpdateInstrumentsMinPositionAmount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMinPositionAmount.sql*
