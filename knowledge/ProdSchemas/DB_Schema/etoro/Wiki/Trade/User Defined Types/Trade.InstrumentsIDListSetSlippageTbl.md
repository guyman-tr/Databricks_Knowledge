# Trade.InstrumentsIDListSetSlippageTbl

> TVP for bulk updates of instrument slippage configuration (slippage tolerance and units quantity type per instrument).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries per-instrument slippage configuration - the allowed deviation between expected and executed price (Slippage) plus the units quantity type that defines how slippage is measured (UnitsQuantityType). It models the operational parameters for order execution quality on each tradable instrument.

The type exists to support bulk slippage updates when market conditions change, when instruments require different tolerance levels, or when operations teams adjust execution parameters across many instruments at once. SetInstrumentSlippage receives this TVP and applies the values to the underlying instrument configuration.

Services populate the TVP with InstrumentID + Slippage + UnitsQuantityType rows, pass it to Trade.SetInstrumentSlippage, and the procedure updates the instrument configuration tables accordingly.

---

## 2. Business Logic

InstrumentID + Slippage + UnitsQuantityType triples for bulk instrument slippage configuration updates. Each row defines the slippage tolerance and measurement unit for one instrument.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument. Identifies the instrument whose slippage is being configured |
| 2 | Slippage | dbo.dtPrice | YES | - | NAME-INFERRED | Slippage tolerance value (dtPrice is a scalar alias, typically decimal). Maximum allowed price deviation for execution |
| 3 | UnitsQuantityType | tinyint | YES | - | NAME-INFERRED | Defines how slippage/quantity units are interpreted (e.g., percentage vs fixed amount). Likely references a dictionary or enum |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetInstrumentSlippage | @Instruments_NewSlippage | Parameter (TVP) | Applies bulk slippage configuration updates to instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetInstrumentSlippage | Stored Procedure | READONLY parameter for bulk slippage updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for slippage update
```sql
DECLARE @Instruments_NewSlippage Trade.InstrumentsIDListSetSlippageTbl;
INSERT INTO @Instruments_NewSlippage (InstrumentID, Slippage, UnitsQuantityType)
VALUES (123, 0.001, 1), (456, 0.002, 1);
EXEC Trade.SetInstrumentSlippage @Instruments_NewSlippage = @Instruments_NewSlippage;
```

### 8.2 Single instrument slippage update
```sql
DECLARE @Instruments_NewSlippage Trade.InstrumentsIDListSetSlippageTbl;
INSERT INTO @Instruments_NewSlippage (InstrumentID, Slippage, UnitsQuantityType)
VALUES (789, 0.0005, 0);
EXEC Trade.SetInstrumentSlippage @Instruments_NewSlippage = @Instruments_NewSlippage;
```

### 8.3 Populate from existing config
```sql
DECLARE @Instruments_NewSlippage Trade.InstrumentsIDListSetSlippageTbl;
INSERT INTO @Instruments_NewSlippage (InstrumentID, Slippage, UnitsQuantityType)
SELECT InstrumentID, Slippage * 1.1, UnitsQuantityType
FROM Trade.InstrumentSlippageConfig WHERE InstrumentID IN (1,2,3);
EXEC Trade.SetInstrumentSlippage @Instruments_NewSlippage = @Instruments_NewSlippage;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.3/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsIDListSetSlippageTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsIDListSetSlippageTbl.sql*
