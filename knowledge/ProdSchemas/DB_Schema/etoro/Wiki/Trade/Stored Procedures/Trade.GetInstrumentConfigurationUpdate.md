# Trade.GetInstrumentConfigurationUpdate

> Dequeues the next pending instrument configuration change from Trade.SyncConfiguration by deleting and outputting the oldest row.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | ID (from Trade.SyncConfiguration) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements a queue-dequeue pattern on Trade.SyncConfiguration. It deletes the oldest row (by ID) from the table and outputs the deleted row's data. This is how price servers and configuration consumers poll for instrument configuration changes - each call retrieves and removes one pending change notification.

The procedure exists because instrument configurations (precision, trading rules, visibility) change dynamically via admin operations. These changes need to propagate to price servers and trading engines. Trade.SyncConfiguration acts as a change queue, and this SP is the dequeue operation.

Data flow: no input parameters. The SP finds the row with MIN(ID) in Trade.SyncConfiguration, DELETE TOP(1) with OUTPUT clause to return the deleted row's ConfigurationUpdateTypeID, InstrumentID, and Value. The consumer processes the change and calls again for the next one.

---

## 2. Business Logic

### 2.1 Queue-Dequeue Pattern

**What**: FIFO queue implemented via DELETE TOP(1) with OUTPUT, ordered by MIN(ID).

**Columns/Parameters Involved**: `ID`, `ConfigurationUpdateTypeID`, `InstrumentID`, `Value`

**Rules**:
- Dequeues one row per call (DELETE TOP 1)
- Uses WHERE ID IN (SELECT MIN(ID)) to ensure FIFO ordering
- OUTPUT Deleted.* returns the dequeued row to the caller
- Empty queue returns no rows (no error)
- Consumer is expected to poll repeatedly until no rows returned

**Diagram**:
```
Trade.SyncConfiguration (queue)
  [ID=1, TypeID=3, InstrumentID=1001, Value='5']  <-- MIN(ID) - dequeued first
  [ID=2, TypeID=1, InstrumentID=1002, Value='1']
  [ID=3, TypeID=2, InstrumentID=1001, Value='0.01']

EXEC GetInstrumentConfigurationUpdate
  --> DELETE + OUTPUT row ID=1
  --> Returns: ConfigurationUpdateTypeID=3, InstrumentID=1001, Value='5'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConfigurationUpdateTypeID (output) | INT | - | - | CODE-BACKED | Type of configuration change. Determines which instrument property changed. |
| 2 | InstrumentID (output) | INT | - | - | CODE-BACKED | Instrument affected by the configuration change. |
| 3 | Value (output) | VARCHAR | YES | - | CODE-BACKED | New value for the changed property. Interpretation depends on ConfigurationUpdateTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.SyncConfiguration | DELETE (OUTPUT) | Queue table - rows are dequeued (deleted) with output |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConfigurationUpdate (procedure)
+-- Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncConfiguration | Table | DELETE with OUTPUT - dequeues oldest row |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Note: This SP performs a DELETE (write operation) despite its "Get" name prefix.

---

## 8. Sample Queries

### 8.1 Dequeue next configuration update

```sql
EXEC Trade.GetInstrumentConfigurationUpdate;
```

### 8.2 Check queue depth without dequeuing

```sql
SELECT  COUNT(*) AS PendingUpdates
FROM    Trade.SyncConfiguration WITH (NOLOCK);
```

### 8.3 Peek at next update without dequeuing

```sql
SELECT  TOP 1 ConfigurationUpdateTypeID, InstrumentID, Value
FROM    Trade.SyncConfiguration WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentConfigurationUpdate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentConfigurationUpdate.sql*
