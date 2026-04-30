# Price.OMPDActiveThreshold

> Per-instrument configuration table that designates which OMPD (Order Management Price Deviation) threshold type - Pips or Percentage - is currently active for each instrument, acting as a selector switch for the two-type threshold system.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

OMPD (Order Management Price Deviation) is a price protection mechanism that rejects or flags orders when the market price has moved beyond an acceptable threshold from the price at order creation. The deviation tolerance can be defined in two ways for each instrument: as an absolute number of Pips (ThresholdType=1) or as a Percentage (ThresholdType=2). Both threshold values are stored in `Price.OMPDThresholdValues`.

OMPDActiveThreshold acts as the "selector switch" - it declares which of the two threshold types is currently the active enforcement mode for each instrument. The pricing/order system reads this table to know which column to apply from OMPDThresholdValues. For example, an FX instrument might be configured to use Pips (more natural for forex), while a stock might use Percentage (more natural for equity pricing).

With 9,848 rows, this table covers effectively all actively configured instruments. The join pattern used in `Price.GetActiveOMPDThresholdByInstrumentIds` is: `JOIN OMPDThresholdValues TV ON AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType` - meaning only the row in OMPDThresholdValues that matches the active ThresholdType is returned for each instrument.

Note: The FK for InstrumentID points to `Trade.InstrumentMetaData` (not the more common `Trade.Instrument`), reflecting that OMPD configuration is a metadata-level instrument property.

---

## 2. Business Logic

### 2.1 Active Threshold Type Selection

**What**: Each instrument has exactly one "active" threshold type at any time. This determines whether OMPD deviation is enforced in Pips or Percentage units.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`

**Rules**:
- PK on InstrumentID enforces one active type per instrument
- ThresholdType FK -> Dictionary.OMPDThresholdType: 1=Pips, 2=Percentage
- `Price.UpdateActiveOMPDThresholdByInstrumentId` updates ThresholdType for an existing InstrumentID - raises error if InstrumentID not found
- `Price.CreateActiveOMPDThresholdByInstrumentId` inserts a new row (creates the active threshold designation for a new instrument)
- Switching from Pips to Percentage (or vice versa) does NOT delete either value from OMPDThresholdValues - it only changes which row is referenced

### 2.2 OMPD Resolution Pattern (Active + Values Join)

**What**: The full OMPD configuration (active type + actual value) is resolved by joining this table with OMPDThresholdValues.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`

**Rules**:
- Join: `AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType`
- This pattern returns only the value for the active type, not the inactive type
- Used by: `Price.GetActiveOMPDThresholdByInstrumentIds` with pagination support
- `Price.GetInstrumentsOMPDThresholdByInstrumentIds` and `Price.GetInstrumentsOMPDThresholdByExchangeIds` return both threshold types per instrument (using OMPDThresholdValues directly, not necessarily filtered by active type)

```
OMPDActiveThreshold (selector)           OMPDThresholdValues (value store)
InstrumentID=1, ThresholdType=1   ---->  InstrumentID=1, ThresholdType=1, Value=40 (Pips) [returned]
                                         InstrumentID=1, ThresholdType=2, Value=50 (%) [not joined]
```

---

## 3. Data Overview

| InstrumentID | ThresholdType | Meaning |
|---|---|---|
| 1 (EUR/USD) | 1 (Pips) | EUR/USD uses Pips for OMPD enforcement. A 40-pip deviation threshold is active. |
| 2 | 2 (Percentage) | Instrument 2 uses Percentage. Percentage threshold active. |
| 3 | 2 (Percentage) | Same pattern - percentage-based instruments (likely equities or crypto). |
| 4 | 2 (Percentage) | Percentage type active. |

Total rows: 9,848 (covers all actively configured instruments).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. FK to Trade.InstrumentMetaData. The instrument for which this active threshold designation applies. One active type per instrument enforced by PK. Note: FK references Trade.InstrumentMetaData (not Trade.Instrument) - consistent with OMPD being a metadata-level property. (Trade.InstrumentMetaData) |
| 2 | ThresholdType | int | NOT NULL | - | VERIFIED | FK to Dictionary.OMPDThresholdType. The threshold type currently active for this instrument. Values: 1=Pips (absolute pip count), 2=Percentage (percentage of price). This is the selector that determines which row in Price.OMPDThresholdValues is used when resolving the active OMPD limit. (Dictionary.OMPDThresholdType) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | FK (FK_ActiveThreshold_InstrumentID) | The instrument whose active threshold type is configured here. Uses InstrumentMetaData (not Trade.Instrument). |
| ThresholdType | Dictionary.OMPDThresholdType | FK (FK_ActiveThreshold_ActiveThresholdTypeID) | The threshold unit type: 1=Pips, 2=Percentage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetActiveOMPDThresholdByInstrumentIds | InstrumentID, ThresholdType | JOIN SOURCE | Joins to OMPDThresholdValues on (InstrumentID, ThresholdType) to return active threshold value per instrument |
| Price.UpdateActiveOMPDThresholdByInstrumentId | InstrumentID | MODIFIER | Updates ThresholdType for an existing instrument row |
| Price.CreateActiveOMPDThresholdByInstrumentId | InstrumentID | WRITER | Inserts new active threshold designation for an instrument |
| Price.DeleteOMPDThresholdByInstrumentID | InstrumentID | DELETER | Removes active threshold and corresponding values for an instrument |
| Price.UpdateInstrumentThresholdsWithActiveThreshold | InstrumentID | READER | Uses active threshold to compute updated values |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.OMPDActiveThreshold (table)
|- Trade.InstrumentMetaData (table, FK target - leaf)
|- Dictionary.OMPDThresholdType (table, FK target - leaf: ThresholdTypeID=1 Pips, ThresholdTypeID=2 Percentage)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FK target - InstrumentID must reference a valid instrument metadata row |
| Dictionary.OMPDThresholdType | Table | FK target - ThresholdType must reference a valid threshold type (1=Pips, 2=Percentage) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetActiveOMPDThresholdByInstrumentIds | Stored Procedure | JOIN source - resolves active threshold type + value per instrument |
| Price.UpdateActiveOMPDThresholdByInstrumentId | Stored Procedure | MODIFIER - changes active threshold type for an instrument |
| Price.CreateActiveOMPDThresholdByInstrumentId | Stored Procedure | WRITER - creates new active threshold row for instrument |
| Price.DeleteOMPDThresholdByInstrumentID | Stored Procedure | DELETER - removes this row when instrument OMPD config is deleted |
| Price.UpdateInstrumentThresholdsWithActiveThreshold | Stored Procedure | READER - uses active threshold type to update computed thresholds |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OMPDActiveThreshold | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OMPDActiveThreshold | PRIMARY KEY | One active threshold type per instrument (InstrumentID) |
| FK_ActiveThreshold_InstrumentID | FK | InstrumentID -> Trade.InstrumentMetaData(InstrumentID) |
| FK_ActiveThreshold_ActiveThresholdTypeID | FK | ThresholdType -> Dictionary.OMPDThresholdType(ThresholdTypeID) |

---

## 8. Sample Queries

### 8.1 View active threshold type for all instruments

```sql
SELECT
    AT.InstrumentID,
    AT.ThresholdType,
    OTT.Name AS ThresholdTypeName,
    OTT.Description
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = AT.ThresholdType
ORDER BY AT.InstrumentID;
```

### 8.2 Get active OMPD threshold (type + value) per instrument

```sql
SELECT
    AT.InstrumentID,
    AT.ThresholdType,
    OTT.Name AS TypeName,
    TV.Value AS ActiveThresholdValue
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Price.OMPDThresholdValues TV WITH (NOLOCK)
    ON TV.InstrumentID = AT.InstrumentID
    AND TV.ThresholdType = AT.ThresholdType
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = AT.ThresholdType
ORDER BY AT.InstrumentID;
```

### 8.3 Distribution of active threshold types

```sql
SELECT
    AT.ThresholdType,
    OTT.Name AS TypeName,
    COUNT(*) AS InstrumentCount
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = AT.ThresholdType
GROUP BY AT.ThresholdType, OTT.Name
ORDER BY AT.ThresholdType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.OMPDActiveThreshold | Type: Table | Source: etoro/etoro/Price/Tables/Price.OMPDActiveThreshold.sql*
