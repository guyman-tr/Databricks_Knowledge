# Price.SkewModels

> Registry of available skew algorithm implementations, mapping each model to its .NET assembly and class name so the Skew Model Service can dynamically load the correct pricing skew algorithm at runtime.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | ModelID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

SkewModels is the central registry for pricing skew algorithm implementations. Each row identifies a distinct skew algorithm that the SkewModelService can instantiate and run. The `Assembly` and `Class` columns provide the full .NET assembly filename and fully-qualified class name, enabling plugin-style dynamic loading of skew algorithms without code changes.

Currently 2 models are registered:
- **BuyRatio** (ModelID=1): Algorithm implemented in `SkewModelService.BuyRatioModel.dll` / `SkewModelService.BuyRatioModel.BuyRatioModel`. This is the primary model that uses buy/sell ratio of client positions to determine skew direction and magnitude. Its configuration tables are `Price.BuyRatioSkewConditions`, `Price.BuyRatioThresholds`, `Price.BuyRatio`, and `Price.ActiveSkew`.
- **PriceAlgo** (ModelID=2): Algorithm implemented in `SkewModelService.PriceAlgoModel.dll` / `SkewModelService.PriceAlgoModel.PriceAlgoModel`. This uses the pricing algorithm approach, with configuration in `Price.PriceAlgoSkewConditions` and `Price.PriceAlgoThresholds`.

The table has no temporal versioning, no computed columns, and no FK constraints - it is a simple, small, stable reference table. It is the parent of `Price.InstrumentSkewModel` (which assigns models to instruments) and `Price.InstanceIDToSkewModelID` (which assigns models to service instances). `Price.SkewModelValue` stores the runtime-computed skew outputs per model.

---

## 2. Business Logic

### 2.1 Plugin-Based Algorithm Registry

**What**: Each registered model is a loadable .NET assembly. Adding a new skew algorithm requires inserting a row here with the correct assembly and class references.

**Columns/Parameters Involved**: `ModelID`, `Name`, `Assembly`, `Class`

**Rules**:
- ModelID is the stable identifier used in `Price.InstrumentSkewModel` and `Price.InstanceIDToSkewModelID` FKs
- The SkewModelService resolves the assembly and class at startup to instantiate the algorithm
- Currently 2 models: BuyRatio (ModelID=1) and PriceAlgo (ModelID=2)
- Name is varchar(50) - human-readable label for display and configuration management
- Assembly is varchar(100) - the DLL filename
- Class is varchar(100) - the fully-qualified .NET type name

---

## 3. Data Overview

| ModelID | Name | Assembly | Class |
|---|---|---|---|
| 1 | BuyRatio | SkewModelService.BuyRatioModel.dll | SkewModelService.BuyRatioModel.BuyRatioModel |
| 2 | PriceAlgo | SkewModelService.PriceAlgoModel.dll | SkewModelService.PriceAlgoModel.PriceAlgoModel |

2 rows total. Both models are active skew algorithm implementations loaded by the SkewModelService.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int | NOT NULL | - | VERIFIED | Primary key. The unique identifier for this skew model. Referenced by Price.InstrumentSkewModel (assigns model to instruments) and Price.InstanceIDToSkewModelID (assigns model to service instances). Current values: 1=BuyRatio, 2=PriceAlgo. |
| 2 | Name | varchar(50) | NOT NULL | - | VERIFIED | Human-readable name of the skew model. Current values: "BuyRatio" (ratio-based skew algorithm) and "PriceAlgo" (pricing algorithm-based skew). Used for display in configuration tools. |
| 3 | Assembly | varchar(100) | NOT NULL | - | VERIFIED | The .NET assembly filename containing the skew algorithm implementation. Current values: "SkewModelService.BuyRatioModel.dll" and "SkewModelService.PriceAlgoModel.dll". The SkewModelService loads this DLL to instantiate the algorithm. |
| 4 | Class | varchar(100) | NOT NULL | - | VERIFIED | The fully-qualified .NET class name within the assembly that implements the skew algorithm. Current values: "SkewModelService.BuyRatioModel.BuyRatioModel" and "SkewModelService.PriceAlgoModel.PriceAlgoModel". Used with Assembly for Reflection-based instantiation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. SkewModels is a root registry table with no FK dependencies.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentSkewModel | ModelID | FK | Maps instruments to a skew model (one model per instrument) |
| Price.InstanceIDToSkewModelID | ModelID | FK | Maps service instance IDs to a skew model (one model per instance) |
| Price.SkewModelValue | ModelID | FK | Stores computed skew values per (instrument, model) combination |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SkewModels (table - leaf, no FK dependencies)
```

---

### 6.1 Objects This Depends On

None. SkewModels has no FK constraints and is a root/leaf table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentSkewModel | Table | FK target - ModelID must reference a registered skew model |
| Price.InstanceIDToSkewModelID | Table | FK target - ModelID must reference a registered skew model |
| Price.SkewModelValue | Table | FK target - ModelID must reference a registered skew model |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_SkewModels | CLUSTERED PK | ModelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Price_SkewModels | PRIMARY KEY | One row per registered skew algorithm (ModelID) |

No temporal versioning, no computed columns, no audit triggers.

---

## 8. Sample Queries

### 8.1 View all registered skew models

```sql
SELECT ModelID, Name, Assembly, Class
FROM Price.SkewModels WITH (NOLOCK)
ORDER BY ModelID;
```

### 8.2 Find which instruments use each skew model

```sql
SELECT
    SM.ModelID,
    SM.Name AS ModelName,
    COUNT(ISM.InstrumentID) AS InstrumentCount
FROM Price.SkewModels SM WITH (NOLOCK)
LEFT JOIN Price.InstrumentSkewModel ISM WITH (NOLOCK)
    ON ISM.ModelID = SM.ModelID
GROUP BY SM.ModelID, SM.Name
ORDER BY SM.ModelID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SkewModels | Type: Table | Source: etoro/etoro/Price/Tables/Price.SkewModels.sql*
