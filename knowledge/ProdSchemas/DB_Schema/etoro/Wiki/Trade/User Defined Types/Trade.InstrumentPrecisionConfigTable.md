# Trade.InstrumentPrecisionConfigTable

> TVP for bulk updates of precision (decimal places) and above-dollar precision per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries InstrumentID + ConfigurationValue + AboveDollarPrecision for display and calculation precision per instrument. It models how many decimal places are shown for prices and quantities, with separate handling for values above one unit (e.g., stock vs crypto precision).

The type exists to support bulk precision updates when instruments are reclassified or display rules change. Configuration services populate the TVP and pass it to Trade.UpdateInstrumentsPrecision.

Services build the table, pass it as READONLY, and the procedure JOINs it against instrument config tables to apply the new precision settings.

---

## 2. Business Logic

InstrumentID + ConfigurationValue + AboveDollarPrecision triplet for bulk instrument precision configuration. ConfigurationValue is the base precision; AboveDollarPrecision governs display for values >= 1.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the config. |
| 2 | ConfigurationValue | tinyint | NO | - | CODE-BACKED | Base decimal precision (number of decimal places) for the instrument. |
| 3 | AboveDollarPrecision | tinyint | NO | - | CODE-BACKED | Decimal places used when value is at or above 1 unit (e.g., whole-number display). |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsPrecision | @InstrumentNewConfigTable | Parameter (TVP) | Bulk-updates precision and above-dollar precision per instrument. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsPrecision | Stored Procedure | READONLY parameter for bulk precision updates |

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
DECLARE @Config Trade.InstrumentPrecisionConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue, AboveDollarPrecision) VALUES (12345, 2, 2), (12346, 4, 4);
EXEC Trade.UpdateInstrumentsPrecision @InstrumentNewConfigTable = @Config;
```

### 8.2 Build from existing table
```sql
DECLARE @Config Trade.InstrumentPrecisionConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue, AboveDollarPrecision)
SELECT InstrumentID, 2, 2 FROM Trade.Instrument WHERE Symbol LIKE '%.FX%';
EXEC Trade.UpdateInstrumentsPrecision @InstrumentNewConfigTable = @Config;
```

### 8.3 Single-instrument update
```sql
DECLARE @Config Trade.InstrumentPrecisionConfigTable;
INSERT INTO @Config (InstrumentID, ConfigurationValue, AboveDollarPrecision) VALUES (99999, 4, 4);
EXEC Trade.UpdateInstrumentsPrecision @InstrumentNewConfigTable = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentPrecisionConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentPrecisionConfigTable.sql*
