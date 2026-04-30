# Trade.GranularAggregatesTableType_MOT

> Memory-optimized TVP for intermediate portfolio aggregation. Aggregates positions at granular level: per MirrorID + InstrumentID + IsBuy + IsSettled. Detailed breakdown before rolling up to instrument-level.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | MirrorID, InstrumentID, IsBuy, IsSettled |
| **Partition** | N/A |
| **Indexes** | IX_InstrumentID_MirrorID (NC), IX_MirrorID_InstrumentID (NC) |

---

## 1. Business Meaning

Trade.GranularAggregatesTableType_MOT is a memory-optimized table type used as an intermediate result container in portfolio aggregation. It holds aggregates at the granular level: per MirrorID + InstrumentID + IsBuy + IsSettled combination. This is the detailed breakdown level before rolling up to instrument-level aggregates (InstrumentAggregatesTableType_MOT).

Trade.GetPortfolioAggregates populates this via local variable @GranularAggregates. Columns include TotalUnits, TotalAmount, TotalFees, TotalTaxes, WeightedRateSum (for weighted average open rate), InitialExposure, TotalLots, TotalLeverages, date ranges (FirstOpenDate, LastOpenDate), and net aggregates (NetUnits, NetLots, NetOpenRateSum, NetInitExposure). PnLVersion indicates which PnL calculation formula applies. Two indexes support lookups by instrument-first or mirror-first.

---

## 2. Business Logic

### 2.1 Granular Portfolio Aggregation

**What**: Positions are aggregated at the finest grain - per mirror, instrument, buy/sell, and settled/CFD. Totals and nets are computed for downstream instrument-level rollup.

**Columns/Parameters Involved**: MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion, TotalUnits, WeightedRateSum, InitialExposure, TotalAmount, TotalFees, TotalTaxes, TotalLots, TotalLeverages, FirstOpenDate, LastOpenDate, NetUnits, NetLots, NetOpenRateSum, NetInitExposure.

**Rules**:
- Granularity: (MirrorID, InstrumentID, IsBuy, IsSettled).
- Total* columns: sum aggregates; Net* columns: buy minus sell.
- WeightedRateSum: for weighted average open rate calculation.
- InitialExposure: sum of position amounts * leverage.
- PnLVersion: which PnL formula version (different versions exist).
- IX_InstrumentID_MirrorID and IX_MirrorID_InstrumentID enable fast lookups.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | YES | - | High | Copy-trade mirror ID |
| 2 | InstrumentID | int | NO | - | High | Instrument identifier |
| 3 | IsBuy | bit | NO | - | High | 1=long/buy, 0=short/sell |
| 4 | IsSettled | bit | NO | - | High | Settlement type (real stock vs CFD) |
| 5 | PnLVersion | tinyint | YES | - | High | PnL formula version for calculation |
| 6 | TotalUnits | decimal(38,8) | YES | - | High | Sum of position units |
| 7 | WeightedRateSum | decimal(38,8) | YES | - | High | For weighted average open rate |
| 8 | InitialExposure | decimal(38,8) | YES | - | High | Sum of amounts * leverage |
| 9 | TotalAmount | decimal(38,2) | YES | - | High | Sum of position amounts |
| 10 | TotalFees | decimal(38,2) | YES | - | High | Sum of fees |
| 11 | TotalTaxes | decimal(38,2) | YES | - | High | Sum of taxes |
| 12 | TotalLots | decimal(38,8) | YES | - | High | Sum of lots |
| 13 | TotalLeverages | decimal(38,8) | YES | - | High | Sum of leverages |
| 14 | FirstOpenDate | datetime | YES | - | High | Earliest open date in group |
| 15 | LastOpenDate | datetime | YES | - | High | Latest open date in group |
| 16 | NetUnits | decimal(38,8) | YES | - | High | Net units (buy minus sell) |
| 17 | NetLots | decimal(38,8) | YES | - | High | Net lots |
| 18 | NetOpenRateSum | decimal(38,8) | YES | - | High | Net open rate sum |
| 19 | NetInitExposure | decimal(38,8) | YES | - | High | Net initial exposure |

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
| Trade.GetPortfolioAggregates | @GranularAggregates (local variable) | Local variable | Intermediate aggregation container |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Trade.GetPortfolioAggregates (local variable @GranularAggregates)

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
DECLARE @GranularAggregates Trade.GranularAggregatesTableType_MOT;
-- Aggregation logic populates @GranularAggregates from positions
-- Then rolls up into @InstrumentAggregates
```

### 8.2 Lookup by Instrument and Mirror

```sql
DECLARE @GranularAggregates Trade.GranularAggregatesTableType_MOT;
-- After population...
SELECT * FROM @GranularAggregates
WHERE InstrumentID = 1001 AND MirrorID = 500;
```

### 8.3 Sum NetUnits by Instrument

```sql
DECLARE @GranularAggregates Trade.GranularAggregatesTableType_MOT;
-- After population...
SELECT InstrumentID, SUM(NetUnits) AS TotalNetUnits
FROM @GranularAggregates GROUP BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GranularAggregatesTableType_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.GranularAggregatesTableType_MOT.sql*
