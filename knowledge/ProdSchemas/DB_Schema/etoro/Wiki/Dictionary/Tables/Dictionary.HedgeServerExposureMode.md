# Dictionary.HedgeServerExposureMode

> Lookup table defining four hedge server exposure calculation modes — Normal, Major, Portfolio, and Spot — that determine how the hedge server aggregates and manages exposure for different instrument categories.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExposureModeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeServerExposureMode defines how the hedge server calculates and manages exposure for different instrument groups. Exposure mode determines the aggregation strategy — whether customer positions are netted at the individual instrument level, grouped by major currency pair characteristics, managed as a portfolio basket, or treated as spot market positions.

This table exists because different asset classes and market structures require fundamentally different hedging approaches. Forex majors can be hedged with simple netting. A portfolio of correlated stocks might benefit from basket hedging. Spot positions may require immediate pass-through hedging. The exposure mode tells the hedge server which aggregation algorithm to apply.

The ExposureModeID is referenced in both Hedge.ServerConfiguration (default mode per server) and Hedge.HedgeServerExposureModeConfiguration (per-instrument-group overrides). Historical changes are tracked in History.HedgeServerExposureModeConfiguration.

---

## 2. Business Logic

### 2.1 Exposure Aggregation Strategies

**What**: Four modes control how customer positions are aggregated for hedging purposes.

**Columns/Parameters Involved**: `ExposureModeID`, `Description`

**Rules**:
- **Normal (0)**: Standard instrument-level netting. Each instrument's long and short customer positions are netted, and the residual is hedged. Suitable for most liquid instruments.
- **Major (1)**: Enhanced aggregation for major/liquid instruments. May apply tighter hedging thresholds or faster execution since major instruments have deep liquidity and tight spreads.
- **Portfolio (2)**: Basket-level hedging. Multiple correlated instruments are aggregated into a portfolio exposure, and the net portfolio risk is hedged rather than individual instruments. Reduces hedge costs for diversified portfolios.
- **SpotExposureMode (3)**: Spot market hedging. Positions are hedged at spot rates with immediate pass-through, used for instruments that settle as spot (e.g., crypto, physical commodities).
- Exposure mode is configured per hedge server (Hedge.ServerConfiguration) with instrument-group overrides (Hedge.HedgeServerExposureModeConfiguration).

**Diagram**:
```
Exposure Modes:
┌─────────────────────────────────────────────────────────┐
│ Normal (0)  │ Per-instrument netting → Hedge residual   │
│ Major (1)   │ Tight thresholds → Fast hedge execution   │
│ Portfolio(2)│ Multi-instrument basket → Net portfolio    │
│ Spot (3)    │ Immediate pass-through → Spot settlement  │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Data Overview

| ExposureModeID | Description | Meaning |
|---|---|---|
| 0 | Normal | Standard per-instrument netting. Customer longs and shorts are netted per instrument, and the residual exposure is hedged at the LP. Default mode for most instruments. |
| 1 | Major | Exposure mode optimized for major/liquid instruments. Applies tighter hedging thresholds and faster execution cycles, leveraging deep liquidity available in major pairs. |
| 2 | Portfolio | Basket-level aggregation. Multiple correlated instruments are grouped, and the net portfolio exposure is hedged. Reduces overall hedge costs through diversification benefits. |
| 3 | SpotExposureMode | Spot market hedging with immediate pass-through execution. Used for instruments that settle at spot (crypto, physical commodities) where delayed hedging creates settlement risk. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExposureModeID | int | NO | - | VERIFIED | Primary key identifying the exposure mode. 0=Normal (per-instrument netting), 1=Major (tight thresholds for liquid instruments), 2=Portfolio (basket aggregation), 3=SpotExposureMode (immediate spot pass-through). Referenced by Hedge.ServerConfiguration and Hedge.HedgeServerExposureModeConfiguration. |
| 2 | Description | varchar(50) | NO | - | VERIFIED | Human-readable description of the exposure mode. Displayed in hedge server configuration screens and exposure monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ServerConfiguration | ExposureModeID | Implicit FK | Default exposure mode per hedge server instance |
| Hedge.HedgeServerExposureModeConfiguration | ExposureModeID | Implicit FK | Per-instrument-group exposure mode overrides |
| History.HedgeServerExposureModeConfiguration | ExposureModeID | Implicit FK | Historical tracking of exposure mode configuration changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ServerConfiguration | Table | Default exposure mode configuration |
| Hedge.HedgeServerExposureModeConfiguration | Table | Per-instrument-group overrides |
| History.HedgeServerExposureModeConfiguration | Table | Historical change tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeServerExposureMode | CLUSTERED PK | ExposureModeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeServerExposureMode | PRIMARY KEY | Unique exposure mode identifier |

---

## 8. Sample Queries

### 8.1 List all exposure modes
```sql
SELECT  ExposureModeID,
        Description
FROM    [Dictionary].[HedgeServerExposureMode] WITH (NOLOCK)
ORDER BY ExposureModeID;
```

### 8.2 Join to server configuration
```sql
SELECT  sc.ServerID,
        em.Description AS ExposureMode
FROM    [Hedge].[ServerConfiguration] sc WITH (NOLOCK)
JOIN    [Dictionary].[HedgeServerExposureMode] em WITH (NOLOCK)
        ON sc.ExposureModeID = em.ExposureModeID;
```

### 8.3 Show instrument-group exposure mode overrides
```sql
SELECT  emc.InstrumentGroupID,
        em.Description AS ExposureMode
FROM    [Hedge].[HedgeServerExposureModeConfiguration] emc WITH (NOLOCK)
JOIN    [Dictionary].[HedgeServerExposureMode] em WITH (NOLOCK)
        ON emc.ExposureModeID = em.ExposureModeID
ORDER BY emc.InstrumentGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeServerExposureMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeServerExposureMode.sql*
