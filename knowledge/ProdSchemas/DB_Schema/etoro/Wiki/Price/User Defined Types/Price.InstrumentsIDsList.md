# Price.InstrumentsIDsList

> Single-column table-valued parameter (TVP) for passing a batch of instrument IDs to stored procedures, enabling set-based filtering across multiple Price schema queries including OMPD thresholds and pricing configurations.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (the sole column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the most widely reused input parameter type in the Price schema. It allows callers to pass a set of instrument IDs in a single typed parameter, enabling multiple stored procedures to perform set-based filtering without string parsing or repeated single-item calls.

The type is consumed by three procedures:
- `Price.GetActiveOMPDThresholdByInstrumentIds` - returns active OMPD thresholds for the provided instruments
- `Price.GetInstrumentsOMPDThresholdByInstrumentIds` - returns all OMPD thresholds for the provided instruments
- `Price.GetPricingConfigurationsByInstrumentIds` - returns pricing configurations for the provided instruments

This makes InstrumentsIDsList the Price schema's standard "instrument ID filter" TVP, analogous to how ExchangeIDList is the exchange filter TVP.

---

## 2. Business Logic

### 2.1 Multi-Procedure Instrument Filter

**What**: A shared, reusable ID list type used consistently across Price schema read procedures that accept bulk instrument queries.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- InstrumentID values should correspond to valid Trade.Instrument entries (validated implicitly by consuming SPs via JOIN)
- Duplicate InstrumentIDs in the TVP are handled by consuming SP JOIN logic
- The TVP accepts any number of rows; passing a single ID is valid

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. NOT NULL - every row must identify a specific instrument. References Trade.Instrument.InstrumentID implicitly via consuming SP JOINs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetActiveOMPDThresholdByInstrumentIds | @InstrumentsIDs | TVP Parameter | Returns active OMPD thresholds filtered to provided instrument IDs |
| Price.GetInstrumentsOMPDThresholdByInstrumentIds | @InstrumentsIDs | TVP Parameter | Returns all OMPD thresholds filtered to provided instrument IDs |
| Price.GetPricingConfigurationsByInstrumentIds | @InstrumentIds | TVP Parameter | Returns pricing configurations for the provided instrument IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetActiveOMPDThresholdByInstrumentIds | Stored Procedure | Filters active OMPD thresholds by instrument set |
| Price.GetInstrumentsOMPDThresholdByInstrumentIds | Stored Procedure | Filters all OMPD thresholds by instrument set |
| Price.GetPricingConfigurationsByInstrumentIds | Stored Procedure | Filters pricing configurations by instrument set |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Instrument identification required; null IDs are invalid filter criteria |

---

## 8. Sample Queries

### 8.1 Get active OMPD thresholds for a set of instruments

```sql
DECLARE @Instruments Price.InstrumentsIDsList;
INSERT INTO @Instruments VALUES (1001), (1002), (1050);
EXEC Price.GetActiveOMPDThresholdByInstrumentIds @InstrumentsIDs = @Instruments;
```

### 8.2 Get pricing configurations for multiple instruments

```sql
DECLARE @Instruments Price.InstrumentsIDsList;
INSERT INTO @Instruments VALUES (1), (2), (3), (10);
EXEC Price.GetPricingConfigurationsByInstrumentIds @InstrumentIds = @Instruments;
```

### 8.3 Get all OMPD thresholds for a single instrument

```sql
DECLARE @Instruments Price.InstrumentsIDsList;
INSERT INTO @Instruments VALUES (500);
EXEC Price.GetInstrumentsOMPDThresholdByInstrumentIds @InstrumentsIDs = @Instruments;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentsIDsList | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.InstrumentsIDsList.sql*
