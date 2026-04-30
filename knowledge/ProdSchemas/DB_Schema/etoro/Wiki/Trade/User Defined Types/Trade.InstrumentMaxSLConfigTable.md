# Trade.InstrumentMaxSLConfigTable

> TVP for bulk updates of maximum stop-loss percentage per instrument in the trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries InstrumentID + ConfigurationValue pairs for maximum stop-loss percentage. It models the domain concept of instrument-level limits on how far a stop-loss order can be set from the open price (expressed as a percentage).

The type exists to support bulk configuration updates across many instruments at once. Operations that adjust risk parameters (e.g., after regulatory changes or instrument reclassification) populate this TVP and pass it to stored procedures.

Services or ETL jobs build the table, pass it as a READONLY parameter, and the consuming procedure JOINs it against Trade.ProviderToInstrument to apply the new MaxStopLossPercentage values.

---

## 2. Business Logic

InstrumentID + ConfigurationValue pairs for bulk instrument max stop-loss configuration updates. The ConfigurationValue is a percentage (decimal 5,2) limiting how far stop-loss can be set.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the config. |
| 2 | ConfigurationValue | decimal(5,2) | NO | - | CODE-BACKED | Maximum stop-loss percentage allowed for the instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMaxStopLossPrecentage | @InstrumentNewConfigTable | Parameter (TVP) | Bulk-updates MaxStopLossPercentage in ProviderToInstrument and writes to SyncConfiguration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMaxStopLossPrecentage | Stored Procedure | READONLY parameter for bulk max stop-loss config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to update procedure
```sql
DECLARE @Config Trade.InstrumentMaxSLConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue) VALUES (12345, 50.00), (12346, 75.50);
EXEC Trade.UpdateInstrumentsMaxStopLossPrecentage @InstrumentNewConfigTable = @Config;
```

### 8.2 Build from existing table
```sql
DECLARE @Config Trade.InstrumentMaxSLConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue)
SELECT InstrumentID, 60.00 FROM Trade.Instrument WHERE Symbol = 'AAPL';
EXEC Trade.UpdateInstrumentsMaxStopLossPrecentage @InstrumentNewConfigTable = @Config;
```

### 8.3 Single-instrument update
```sql
DECLARE @Config Trade.InstrumentMaxSLConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue) VALUES (99999, 25.00);
EXEC Trade.UpdateInstrumentsMaxStopLossPrecentage @InstrumentNewConfigTable = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMaxSLConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentMaxSLConfigTable.sql*
