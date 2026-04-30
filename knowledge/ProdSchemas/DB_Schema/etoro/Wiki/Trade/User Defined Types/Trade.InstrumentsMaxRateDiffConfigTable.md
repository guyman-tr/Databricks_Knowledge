# Trade.InstrumentsMaxRateDiffConfigTable

> TVP for bulk updates of the maximum allowed rate difference percentage per instrument (price validation threshold).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries per-instrument maximum rate difference configuration - the allowable percentage deviation between reference and execution prices. It models the price validation threshold used to reject or flag suspicious executions when the rate differs too much from expected.

The type exists to support bulk updates when regulators change tolerance levels, when market volatility requires adjustment, or when new instruments are onboarded with different tolerances. UpdateInstrumentsMaxRateDiffPercentage receives this TVP and applies the values to the instrument configuration.

Services populate InstrumentID + ConfigurationValue pairs, pass them to the procedure, which updates Trade.ProviderToInstrument and syncs to Trade.SyncConfiguration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. InstrumentID + ConfigurationValue pairs for bulk instrument max rate diff configuration updates.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument. Identifies the instrument whose max rate diff percentage is being set |
| 2 | ConfigurationValue | decimal(5,2) | NO | - | CODE-BACKED | Maximum allowed rate difference percentage (e.g., 2.50 for 2.5%). Used for price validation during order execution |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMaxRateDiffPercentage | @InstrumentNewConfigTable | Parameter (TVP) | Updates max rate diff percentage for listed instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMaxRateDiffPercentage | Stored Procedure | READONLY parameter for bulk max rate diff updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk max rate diff update
```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentsMaxRateDiffConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, ConfigurationValue)
VALUES (100, 2.50), (101, 3.00), (102, 1.50);
EXEC Trade.UpdateInstrumentsMaxRateDiffPercentage @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.2 Single instrument update
```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentsMaxRateDiffConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, ConfigurationValue)
VALUES (500, 5.00);
EXEC Trade.UpdateInstrumentsMaxRateDiffPercentage @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.3 Populate from query
```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentsMaxRateDiffConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, ConfigurationValue)
SELECT InstrumentID, 2.00 FROM Trade.Instrument WHERE IndustryID = 1;
EXEC Trade.UpdateInstrumentsMaxRateDiffPercentage @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsMaxRateDiffConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsMaxRateDiffConfigTable.sql*
