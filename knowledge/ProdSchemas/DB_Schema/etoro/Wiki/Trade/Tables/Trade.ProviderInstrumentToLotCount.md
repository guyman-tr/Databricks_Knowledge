# Trade.ProviderInstrumentToLotCount

> Maps available lot count (unit quantity) configurations per provider-instrument pair: defines which position sizes (1, 2, 4, 10, 100, etc. units) a user can select when opening a position for a given instrument through a given execution provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID, LotCountGroupID, LotCountID (composite PK) |
| **Partition** | MAIN filegroup |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Trade.ProviderInstrumentToLotCount stores the per-provider, per-instrument lot count configuration. Each row indicates that a specific lot count (unit quantity from Dictionary.LotCount, e.g., 1, 2, 4, 10, 100) is available for a given (ProviderID, InstrumentID) pair. LotCountGroupID groups lot counts by tier (e.g., player level - Bronze, Silver, Gold). IsDefault marks the default position size when the user does not specify one. Percentage may be used for allocation or display weighting.

This table exists because different instruments and providers have different allowed position sizes. Rather than arbitrary unit quantities, the platform constrains positions to a predefined set of lot count values that are compatible with hedge execution and fee calculations. Without it, Trade.GetProviderToInstrument could not return available lot counts, and position open logic could not validate requested sizes. Trade.CheckValidInstruments raises an error if an instrument has no ProviderInstrumentToLotCount rows.

Data flows: Rows are created by Trade.InsertInstrumentRealTable and Trade.MigrateInstrument during instrument setup. Trade.GetProviderToInstrument JOINs this table to expose lot count options. Trade.MigrateInstrument can DELETE and re-INSERT lot counts when migrating instruments (e.g., deleting MaxUnits and re-adding). Trade.CheckValidInstruments validates instrument has at least one lot count.

---

## 2. Business Logic

### 2.1 Lot Count Tiers per Provider-Instrument

**What**: Each (ProviderID, InstrumentID) can have multiple lot count options; one is marked default. LotCountGroupID links to player level tiers.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `LotCountGroupID`, `LotCountID`, `IsDefault`, `Percentage`

**Rules**:
- One row per (ProviderID, InstrumentID, LotCountGroupID, LotCountID). Composite PK.
- LotCountID references Dictionary.LotCount. LotCountID equals Value in Dictionary.LotCount - the ID IS the lot count value (e.g., LotCountID 100 = 100 units).
- LotCountGroupID: Groups lot counts by tier. 0 in sample; Dictionary.LotCountGroup maps to player levels (Bronze, Silver, Gold, Platinum).
- IsDefault=1: Default position size when user does not specify. Sample shows LotCountID 4 (4 units) as default for EUR/USD.
- Percentage: Sample shows 0; may be used for allocation or display.
- Trade.MigrateInstrument: Deletes rows WHERE InstrumentID=@InstrumentID AND LotCountID=@MaxUnits, then INSERTs new config.

**Diagram**:
```
Trade.ProviderToInstrument (ProviderID, InstrumentID)
    |
    v
Trade.ProviderInstrumentToLotCount
    |-- LotCountID -> Dictionary.LotCount (0, 1, 2, 4, 6, 8, 10, 20, 50, 100, 150...)
    |-- LotCountGroupID: 0 = default group; other values map to player tiers
    |-- IsDefault: 1 = default position size
```

### 2.2 Validation Requirement

**What**: Every instrument in ProviderToInstrument must have at least one lot count row for valid trading config.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`

**Rules**:
- Trade.CheckValidInstruments: UNION includes SELECT TOP 1 1 FROM Trade.ProviderInstrumentToLotCount WHERE InstrumentID=@InstrumentID. If no row exists, raises error "Trade.ProviderInstrumentToLotCount is empty please check".
- Trade.GetProviderToInstrument view exposes lot count data for clients.

---

## 3. Data Overview

| ProviderID | InstrumentID | LotCountGroupID | LotCountID | IsDefault | Percentage | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 1 | 0 | 0 | EUR/USD: 1 unit available, not default. |
| 1 | 1 | 0 | 4 | 1 | 0 | EUR/USD: 4 units is default. |
| 1 | 1 | 0 | 10 | 0 | 0 | EUR/USD: 10 units available. |
| 1 | 1 | 0 | 100 | 0 | 0 | EUR/USD: 100 units available. |
| 1 | 1 | 0 | 150 | 0 | 0 | EUR/USD: 150 units available. |

**Selection criteria for the 5 rows:**
- Picked from live TOP 10 for InstrumentID=1 (EUR/USD). LotCountGroupID=0 in all. LotCountID 4 is default. Dictionary.LotCount: LotCountID = Value (1=1, 4=4, etc.).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider (via ProviderToInstrument). Part of PK. Identifies execution provider. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument (via ProviderToInstrument). Part of PK. Identifies tradeable instrument. |
| 3 | LotCountGroupID | int | NO | - | CODE-BACKED | Lot count tier/group. 0 in sample. Links to Dictionary.LotCountGroup for player-level restrictions (Bronze, Silver, Gold). Part of PK. |
| 4 | LotCountID | int | NO | - | CODE-BACKED | FK to Dictionary.LotCount. Part of PK. LotCountID equals the unit value in Dictionary.LotCount (e.g., 1, 4, 10, 100). |
| 5 | IsDefault | bit | NO | - | CODE-BACKED | 1=default position size for this provider-instrument when user does not specify, 0=available but not default. |
| 6 | Percentage | int | NO | - | CODE-BACKED | Display or allocation weight. Sample shows 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK (FK_TPVI_TPLC) | Provider-instrument pair must exist |
| LotCountID | Dictionary.LotCount | FK (FK_DLLC_TPLC) | Lot count value from lookup |
| LotCountGroupID | Dictionary.LotCountGroup | Implicit | Tier/player level grouping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetProviderToInstrument | TPLC | JOIN | View includes lot count data |
| Trade.InsertInstrumentRealTable | - | INSERT | Instrument setup |
| Trade.MigrateInstrument | - | DELETE/INSERT | Lot count config migration |
| Trade.CheckValidInstruments | - | EXISTS | Validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderInstrumentToLotCount (table)
```

Tables have no code-level dependencies. FK targets (Trade.ProviderToInstrument, Dictionary.LotCount) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK: (ProviderID, InstrumentID) |
| Dictionary.LotCount | Table | FK: LotCountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | JOIN |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.MigrateInstrument | Procedure | DELETE/INSERT |
| Trade.CheckValidInstruments | Procedure | EXISTS |
| Trade.PositionTbl | Table | LotCount column values validated against ProviderInstrumentToLotCount per instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPLC | CLUSTERED PK | ProviderID, InstrumentID, LotCountGroupID, LotCountID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPLC | PRIMARY KEY | ProviderID, InstrumentID, LotCountGroupID, LotCountID |
| FK_DLLC_TPLC | FOREIGN KEY | LotCountID -> Dictionary.LotCount.LotCountID |
| FK_TPVI_TPLC | FOREIGN KEY | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |

---

## 8. Sample Queries

### 8.1 List available lot counts for an instrument with values
```sql
SELECT  pitlc.ProviderID,
        pitlc.InstrumentID,
        pitlc.LotCountGroupID,
        lc.Value AS LotCount,
        pitlc.IsDefault,
        pitlc.Percentage
FROM    Trade.ProviderInstrumentToLotCount pitlc WITH (NOLOCK)
JOIN    Dictionary.LotCount lc WITH (NOLOCK) ON pitlc.LotCountID = lc.LotCountID
WHERE   pitlc.InstrumentID = 1 AND pitlc.ProviderID = 1
ORDER BY lc.Value;
```

### 8.2 Get default lot count per provider-instrument
```sql
SELECT  pitlc.ProviderID,
        pitlc.InstrumentID,
        pitlc.LotCountGroupID,
        lc.Value AS DefaultLotCount
FROM    Trade.ProviderInstrumentToLotCount pitlc WITH (NOLOCK)
JOIN    Dictionary.LotCount lc WITH (NOLOCK) ON pitlc.LotCountID = lc.LotCountID
WHERE   pitlc.IsDefault = 1
ORDER BY pitlc.InstrumentID, pitlc.ProviderID;
```

### 8.3 Count lot count options per instrument
```sql
SELECT  pitlc.InstrumentID,
        pitlc.ProviderID,
        pitlc.LotCountGroupID,
        COUNT(*) AS LotCountOptions
FROM    Trade.ProviderInstrumentToLotCount pitlc WITH (NOLOCK)
GROUP BY pitlc.InstrumentID, pitlc.ProviderID, pitlc.LotCountGroupID
ORDER BY pitlc.InstrumentID, pitlc.ProviderID, pitlc.LotCountGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,4,5,7,8,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderInstrumentToLotCount | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ProviderInstrumentToLotCount.sql*
