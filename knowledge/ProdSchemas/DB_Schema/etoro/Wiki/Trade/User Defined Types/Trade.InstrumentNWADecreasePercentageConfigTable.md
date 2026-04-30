# Trade.InstrumentNWADecreasePercentageConfigTable

> TVP for bulk updates of NWA (Net Wealth Adjustment) decrease percentage per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries InstrumentID + ConfigurationValue pairs for NWA (Net Wealth Adjustment) decrease percentage. It models the percentage by which net wealth exposure is reduced for an instrument, typically used in margin or risk calculations.

The type exists to support bulk updates when NWA parameters change across instruments (e.g., risk model updates). Configuration services populate the TVP and pass it to the update procedure.

Services build the table, pass it as READONLY, and the procedure JOINs it against instrument config tables to apply the new NWA decrease percentages.

---

## 2. Business Logic

InstrumentID + ConfigurationValue pairs for bulk instrument NWA decrease percentage configuration updates. The ConfigurationValue is an integer percentage.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the config. |
| 2 | ConfigurationValue | int | NO | - | CODE-BACKED | NWA decrease percentage applied for the instrument in risk/margin calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsNWADecreasePercentage | @InstrumentNewConfigTable | Parameter (TVP) | Bulk-updates NWA decrease percentage per instrument. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsNWADecreasePercentage | Stored Procedure | READONLY parameter for bulk NWA decrease percentage updates |

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
DECLARE @Config Trade.InstrumentNWADecreasePercentageConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue) VALUES (12345, 10), (12346, 20);
EXEC Trade.UpdateInstrumentsNWADecreasePercentage @InstrumentNewConfigTable = @Config;
```

### 8.2 Build from existing table
```sql
DECLARE @Config Trade.InstrumentNWADecreasePercentageConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue)
SELECT InstrumentID, 15 FROM Trade.Instrument WHERE IndustryID = 2;
EXEC Trade.UpdateInstrumentsNWADecreasePercentage @InstrumentNewConfigTable = @Config;
```

### 8.3 Single-instrument update
```sql
DECLARE @Config Trade.InstrumentNWADecreasePercentageConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue) VALUES (99999, 25);
EXEC Trade.UpdateInstrumentsNWADecreasePercentage @InstrumentNewConfigTable = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentNWADecreasePercentageConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentNWADecreasePercentageConfigTable.sql*
