# Trade.ProviderInstrumentToLeverage

> Maps available leverage tiers per provider-instrument pair: defines which leverage values (1x, 2x, 5x, 10x, etc.) a user can select when opening a position for a given instrument through a given execution provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID, LeverageID, LeverageType (composite PK) |
| **Partition** | No |
| **Indexes** | 5 active (PK, UQ 3-column, TPIL_INSTRUMENT, TPIL_LEVERAGE, TPIL_PROVIDERINSTRUMENT) |

---

## 1. Business Meaning

Trade.ProviderInstrumentToLeverage stores the per-provider, per-instrument leverage configuration. Each row indicates that a specific leverage tier (e.g., 1x, 2x, 5x, 10x, 30x, 100x) is available for a given (ProviderID, InstrumentID) pair. IsDefault marks the leverage offered when the user does not specify one. LeverageType (default 1) distinguishes leverage categories (e.g., retail vs professional). The table is system-versioned and audit-logged for compliance.

This table exists because different instruments and providers have different leverage restrictions (regulatory, risk). Forex may allow 30x, crypto 2x, stocks 1x (no leverage). The platform must know which leverage values to present in the UI and enforce at order validation. Without it, Trade.GetInstrumentDataForAPI, Trade.InstrumentAvailableLeverages, and Trade.GetProviderToInstrument could not return available leverages. Trade.CheckValidInstruments raises an error if an instrument has no ProviderInstrumentToLeverage rows.

Data flows: Rows are created by Trade.ProviderInstrumentLeverageAdd, Trade.InsertInstrumentTradingData, Trade.UpdateInstrumentsAvailableLeverages, and Trade.InsertInstrumentRealTable (instrument setup). Trade.ProviderInstrumentLeverageEdit and Trade.ProviderInstrumentLeverageDelete modify/remove. Trade.SyncLeveragesList is called after add/edit to refresh derived lists. System versioning tracks changes to History.TradeProviderInstrumentToLeverage; ASM audit triggers log to History.AuditHistory.

---

## 2. Business Logic

### 2.1 Leverage Tiers per Provider-Instrument

**What**: Each (ProviderID, InstrumentID) can have multiple leverage options; one is marked default.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `LeverageID`, `IsDefault`, `LeverageType`, `Percentage`

**Rules**:
- One row per (ProviderID, InstrumentID, LeverageID, LeverageType). UQ_ProviderInstrumentToLeverage_3columns enforces (InstrumentID, ProviderID, LeverageID) uniqueness (LeverageType excluded from UQ).
- IsDefault=1: This leverage is offered when user does not specify. ProviderInstrumentLeverageAdd/Edit: when adding with IsDefault=1, all other rows for same (ProviderID, InstrumentID) get IsDefault=0.
- LeverageID references Dictionary.Leverage. Value column holds the numeric leverage (1, 2, 5, 10, 20, 30, 50, 100, 200, 400).
- Percentage: Sample shows 0; may be used for allocation or display weighting.
- LeverageType defaults to 1 (retail). Other values may denote professional/restricted tiers.

**Diagram**:
```
Trade.ProviderToInstrument (ProviderID, InstrumentID)
    |
    v
Trade.ProviderInstrumentToLeverage
    |-- LeverageID -> Dictionary.Leverage (1, 2, 5, 10, 20, 30, 50, 100, 200, 400)
    |-- IsDefault: 1 = default offer
    |-- LeverageType: 1 = default
```

### 2.2 Validation Requirement

**What**: Every instrument in ProviderToInstrument must have at least one leverage row for valid trading config.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`

**Rules**:
- Trade.CheckValidInstruments: UNION includes SELECT TOP 1 1 FROM Trade.ProviderInstrumentToLeverage WHERE InstrumentID=@InstrumentID. If no row exists, raises error "Trade.ProviderInstrumentToLeverage is empty please check".
- Trade.InstrumentAvailableLeverages and Trade.GetInstrumentMaxLeverage use ProviderInstrumentToLeverage to determine available leverage options and max leverage per instrument.

---

## 3. Data Overview

| ProviderID | InstrumentID | LeverageID | IsDefault | Percentage | LeverageType | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | 5 | 0 | 0 | 1 | EUR/USD: LeverageID 5 = 50x available, not default. |
| 1 | 1 | 6 | 1 | 0 | 1 | EUR/USD: LeverageID 6 = 100x, default for this pair. |
| 1 | 1 | 7 | 0 | 0 | 1 | EUR/USD: 200x available. |
| 1 | 2 | 10 | 1 | 0 | 1 | GBP: 30x is default. |
| 1 | 2 | 11 | 0 | 0 | 1 | GBP: 20x (LeverageID 11) available. |

**Selection criteria for the 5 rows:**
- Picked from live TOP 10. EUR/USD (1) and GBP (2) show multiple leverage tiers. IsDefault varies. LeverageType=1 in all samples. Dictionary.Leverage: 5=50, 6=100, 7=200, 10=30, 11=20.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. Part of PK. Identifies execution provider (e.g., 1=Tradonomi). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument (via ProviderToInstrument). Part of PK. Identifies tradeable instrument. |
| 3 | LeverageID | int | NO | - | CODE-BACKED | FK to Dictionary.Leverage. Part of PK. Leverage tier (1=1x, 2=5x, 3=10x, 5=50x, 6=100x, 7=200x, 8=400x, 9=2x, 10=30x, 11=20x). |
| 4 | IsDefault | bit | NO | - | CODE-BACKED | 1=default leverage for this provider-instrument (offered when user does not specify), 0=available but not default. ProviderInstrumentLeverageAdd/Edit set IsDefault=0 for others when adding with 1. |
| 5 | Percentage | int | NO | - | CODE-BACKED | Display or allocation weight. Sample shows 0. |
| 6 | LeverageType | int | NO | 1 | CODE-BACKED | Leverage category. Default 1 (retail). Part of PK. May distinguish professional/restricted tiers. |
| 7 | DbLoginName | (computed) | - | - | CODE-BACKED | Computed: suser_name(). Current DB login for audit. |
| 8 | AppLoginName | (computed) | - | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context. |
| 9 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. GENERATED ALWAYS AS ROW START. |
| 10 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end. GENERATED ALWAYS AS ROW END. History in History.TradeProviderInstrumentToLeverage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK (FK_TPVI_TPIL) | Provider-instrument pair must exist |
| LeverageID | Dictionary.Leverage | FK (FK_DLVG_TPIL) | Leverage tier from lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetProviderToInstrument | TPIL | JOIN | View includes leverage data |
| Trade.InstrumentAvailableLeverages | TPL | FROM | Available leverages per instrument |
| Trade.GetInstrumentMaxLeverage | PITL | FROM | Max leverage per instrument |
| Trade.GetInstrumentDataForAPI | pitl | FROM | API instrument data |
| Trade.GetInstrumentDataForAPITest | pitl | FROM | Test API data |
| Trade.ProviderInstrumentLeverageAdd | - | INSERT | Writer |
| Trade.ProviderInstrumentLeverageEdit | - | UPDATE | Modifier |
| Trade.ProviderInstrumentLeverageDelete | - | DELETE | Deleter |
| Trade.InsertInstrumentTradingData | - | INSERT | Instrument setup |
| Trade.UpdateInstrumentsAvailableLeverages | - | DELETE/INSERT | Bulk refresh |
| Trade.InsertInstrumentRealTable | - | INSERT | Real instrument setup |
| Trade.InsertNewTradingResourceDefault | TPL | FROM | Default config |
| Trade.SyncLeveragesList | TPI | FROM | Sync derived leverage list |
| Trade.CheckValidInstruments | - | EXISTS | Validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderInstrumentToLeverage (table)
```

Tables have no code-level dependencies. FK targets (Trade.ProviderToInstrument, Dictionary.Leverage) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK: (ProviderID, InstrumentID) |
| Dictionary.Leverage | Table | FK: LeverageID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | JOIN |
| Trade.InstrumentAvailableLeverages | View | FROM |
| Trade.GetInstrumentMaxLeverage | View | FROM |
| Trade.GetInstrumentDataForAPI | Procedure | FROM |
| Trade.ProviderInstrumentLeverageAdd | Procedure | INSERT |
| Trade.ProviderInstrumentLeverageEdit | Procedure | UPDATE |
| Trade.ProviderInstrumentLeverageDelete | Procedure | DELETE |
| Trade.InsertInstrumentTradingData | Procedure | INSERT |
| Trade.UpdateInstrumentsAvailableLeverages | Procedure | DELETE/INSERT |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.CheckValidInstruments | Procedure | EXISTS |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPIL | CLUSTERED PK | ProviderID, InstrumentID, LeverageID, LeverageType | - | - | Active |
| UQ_ProviderInstrumentToLeverage_3columns | NC UNIQUE | InstrumentID, ProviderID, LeverageID | - | - | Active |
| TPIL_INSTRUMENT | NC | InstrumentID | - | - | Active |
| TPIL_LEVERAGE | NC | LeverageID | - | - | Active |
| TPIL_PROVIDERINSTRUMENT | NC | ProviderID, InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPIL | PRIMARY KEY | ProviderID, InstrumentID, LeverageID, LeverageType |
| UQ_ProviderInstrumentToLeverage_3columns | UNIQUE | InstrumentID, ProviderID, LeverageID |
| DF_ProviderInstrumentToLeverage_LeverageType | DEFAULT | LeverageType = 1 |
| DF_ProviderInstrumentToLeverage_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ProviderInstrumentToLeverage_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |
| FK_DLVG_TPIL | FOREIGN KEY | LeverageID -> Dictionary.Leverage.LeverageID |
| FK_TPVI_TPIL | FOREIGN KEY | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |

---

## 8. Sample Queries

### 8.1 List available leverages for an instrument with labels
```sql
SELECT  pti.ProviderID,
        pti.InstrumentID,
        dl.Value AS LeverageValue,
        pti.IsDefault,
        pti.LeverageType
FROM    Trade.ProviderInstrumentToLeverage pti WITH (NOLOCK)
JOIN    Dictionary.Leverage dl WITH (NOLOCK) ON pti.LeverageID = dl.LeverageID
WHERE   pti.InstrumentID = 1 AND pti.ProviderID = 1
ORDER BY dl.Value;
```

### 8.2 Get default leverage per provider-instrument
```sql
SELECT  pti.ProviderID,
        pti.InstrumentID,
        dl.Value AS DefaultLeverage
FROM    Trade.ProviderInstrumentToLeverage pti WITH (NOLOCK)
JOIN    Dictionary.Leverage dl WITH (NOLOCK) ON pti.LeverageID = dl.LeverageID
WHERE   pti.IsDefault = 1
ORDER BY pti.InstrumentID, pti.ProviderID;
```

### 8.3 Instruments with max leverage by provider
```sql
SELECT  pti.InstrumentID,
        pti.ProviderID,
        MAX(dl.Value) AS MaxLeverage
FROM    Trade.ProviderInstrumentToLeverage pti WITH (NOLOCK)
JOIN    Dictionary.Leverage dl WITH (NOLOCK) ON pti.LeverageID = dl.LeverageID
GROUP BY pti.InstrumentID, pti.ProviderID
ORDER BY pti.InstrumentID, pti.ProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,4,5,7,8,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderInstrumentToLeverage | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ProviderInstrumentToLeverage.sql*
