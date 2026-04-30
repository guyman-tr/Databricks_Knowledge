# Trade.InstrumentAvailableLeveragesConfigTable

> TVP for bulk-updating the available leverage range per instrument. Each row sets min, max, and default leverage. LeverageID values reference Dictionary.Leverages.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentAvailableLeveragesConfigTable is a table-valued parameter used to bulk-update the available leverage configuration per instrument. Each row specifies for one instrument: MinLeverageID, MaxLeverageID, and DefaultLeverageID. These values reference Dictionary.Leverages - the lookup table for leverage multipliers (e.g. 1x, 2x, 5x, 10x).

Trade.UpdateInstrumentsAvailableLeverages accepts this TVP via the parameter @InstrumentNewConfigTable. Regulatory requirements and instrument type often dictate the allowed leverage range. For example, InstrumentID=1 (BTC/USD) might have MinLeverageID=1 (1x), MaxLeverageID=5 (2x), DefaultLeverageID=3 (1x) depending on jurisdiction and asset class.

---

## 2. Business Logic

### 2.1 Leverage Range Configuration

**What**: Defines the allowed leverage range and default for each instrument. Used for bulk config updates.

**Columns/Parameters Involved**: InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID.

**Rules**: All columns NOT NULL. InstrumentID identifies the instrument. MinLeverageID and MaxLeverageID define the allowed range; DefaultLeverageID is the preselected value. MinLeverageID <= DefaultLeverageID <= MaxLeverageID is typically enforced. LeverageID values reference Dictionary.Leverages.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | High | Instrument identifier. References Instrument.InstrumentTbl. |
| 2 | MinLeverageID | int | NOT NULL | - | High | Minimum allowed leverage. References Dictionary.Leverages. |
| 3 | MaxLeverageID | int | NOT NULL | - | High | Maximum allowed leverage. References Dictionary.Leverages. |
| 4 | DefaultLeverageID | int | NOT NULL | - | High | Default leverage for new positions. References Dictionary.Leverages. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Instrument.InstrumentTbl | Implicit | Tradable instrument |
| MinLeverageID | Dictionary.Leverages | Implicit | Minimum leverage lookup |
| MaxLeverageID | Dictionary.Leverages | Implicit | Maximum leverage lookup |
| DefaultLeverageID | Dictionary.Leverages | Implicit | Default leverage lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsAvailableLeverages | @InstrumentNewConfigTable | Parameter (TVP) | Bulk update of leverage config |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Trade.UpdateInstrumentsAvailableLeverages

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update Single Instrument Leverage Config

```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentAvailableLeveragesConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID)
VALUES (1001, 1, 5, 3);  -- 1x min, 2x max, 1x default (example)
EXEC Trade.UpdateInstrumentsAvailableLeverages @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.2 Bulk Update Multiple Instruments

```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentAvailableLeveragesConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID)
VALUES (1001, 1, 5, 3),
       (1002, 1, 10, 5),
       (1003, 1, 2, 1);
EXEC Trade.UpdateInstrumentsAvailableLeverages @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.3 Populate from Regulatory Config Table

```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentAvailableLeveragesConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID)
SELECT InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID
FROM Config.RegulatoryLeverageLimits WHERE RegionID = @RegionID;
EXEC Trade.UpdateInstrumentsAvailableLeverages @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentAvailableLeveragesConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentAvailableLeveragesConfigTable.sql*
