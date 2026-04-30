# Trade.InstrumentAggregatesTableType_MOT

> Memory-optimized TVP for instrument-level portfolio aggregation. Rolled-up version of GranularAggregatesTableType_MOT - combines buy/sell/settled/CFD into per-instrument totals for final portfolio summary.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | MirrorID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | IX_InstrumentID_MirrorID (NC), IX_MirrorID_InstrumentID (NC) |

---

## 1. Business Meaning

Trade.InstrumentAggregatesTableType_MOT is a memory-optimized table type used as the instrument-level result container in portfolio aggregation. It is the rolled-up version of GranularAggregatesTableType_MOT - combining buy/sell, settled/CFD into per-instrument totals.

Trade.GetPortfolioAggregates populates this via local variable @InstrumentAggregates. All columns are prefixed with "Instrument" to distinguish from granular level: InstrumentTotalUnits, InstrumentTotalAmount, InstrumentTotalFees, InstrumentTotalTaxes, InstrumentTotalLots, InstrumentTotalLeverages, InstrumentFirstOpenDate, InstrumentLastOpenDate, InstrumentNetUnits, InstrumentNetLots, InstrumentNetOpenRateSum, InstrumentNetInitExposure. Same aggregate pattern as granular: totals, nets, date ranges. Two indexes mirror the granular type for consistent lookup patterns (instrument-first and mirror-first).

---

## 2. Business Logic

### 2.1 Instrument-Level Portfolio Rollup

**What**: Granular aggregates are rolled up to one row per (MirrorID, InstrumentID). Produces final instrument-level portfolio summary for reporting and dashboards.

**Columns/Parameters Involved**: MirrorID, InstrumentID, InstrumentTotalUnits, InstrumentTotalAmount, InstrumentTotalFees, InstrumentTotalTaxes, InstrumentTotalLots, InstrumentTotalLeverages, InstrumentFirstOpenDate, InstrumentLastOpenDate, InstrumentNetUnits, InstrumentNetLots, InstrumentNetOpenRateSum, InstrumentNetInitExposure.

**Rules**:
- One row per (MirrorID, InstrumentID).
- Instrument* columns: rolled-up totals and nets from granular level.
- Same index layout as GranularAggregatesTableType_MOT for consistent JOIN patterns.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | YES | - | High | Copy-trade mirror ID |
| 2 | InstrumentID | int | NO | - | High | Instrument identifier |
| 3 | InstrumentTotalUnits | decimal(38,8) | YES | - | High | Rolled-up total units |
| 4 | InstrumentTotalAmount | decimal(38,2) | YES | - | High | Rolled-up total amount |
| 5 | InstrumentTotalFees | decimal(38,2) | YES | - | High | Rolled-up total fees |
| 6 | InstrumentTotalTaxes | decimal(38,2) | YES | - | High | Rolled-up total taxes |
| 7 | InstrumentTotalLots | decimal(38,8) | YES | - | High | Rolled-up total lots |
| 8 | InstrumentTotalLeverages | decimal(38,8) | YES | - | High | Rolled-up total leverages |
| 9 | InstrumentFirstOpenDate | datetime | YES | - | High | Earliest open date across positions |
| 10 | InstrumentLastOpenDate | datetime | YES | - | High | Latest open date across positions |
| 11 | InstrumentNetUnits | decimal(38,8) | YES | - | High | Net units per instrument |
| 12 | InstrumentNetLots | decimal(38,8) | YES | - | High | Net lots per instrument |
| 13 | InstrumentNetOpenRateSum | decimal(38,8) | YES | - | High | Net open rate sum |
| 14 | InstrumentNetInitExposure | decimal(38,8) | YES | - | High | Net initial exposure |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.MirrorTbl | Implicit | Copy-trade mirror |
| InstrumentID | Instrument.InstrumentTbl | Implicit | Tradable instrument |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPortfolioAggregates | @InstrumentAggregates (local variable) | Local variable | Instrument-level aggregation container |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Trade.GetPortfolioAggregates (local variable @InstrumentAggregates)

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_InstrumentID_MirrorID | NC | InstrumentID ASC, MirrorID ASC | - | - | Active |
| IX_MirrorID_InstrumentID | NC | MirrorID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

None. Memory-optimized with MEMORY_OPTIMIZED = ON.

---

## 8. Sample Queries

### 8.1 Declare and Use in GetPortfolioAggregates

```sql
-- Inside Trade.GetPortfolioAggregates (conceptual)
DECLARE @InstrumentAggregates Trade.InstrumentAggregatesTableType_MOT;
-- Rollup from @GranularAggregates populates this
-- Final results returned to caller
```

### 8.2 Lookup by Instrument

```sql
DECLARE @InstrumentAggregates Trade.InstrumentAggregatesTableType_MOT;
-- After population...
SELECT * FROM @InstrumentAggregates WHERE InstrumentID = 1001;
```

### 8.3 Portfolio Summary by Mirror

```sql
DECLARE @InstrumentAggregates Trade.InstrumentAggregatesTableType_MOT;
-- After population...
SELECT MirrorID, SUM(InstrumentTotalAmount) AS MirrorTotal,
       SUM(InstrumentNetUnits) AS MirrorNetUnits
FROM @InstrumentAggregates GROUP BY MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentAggregatesTableType_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentAggregatesTableType_MOT.sql*
