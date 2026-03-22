# Dealing_dbo.Dealing_MarketMakerBoundaries_CFD

> Daily CFD instrument exposure band limits from market maker configuration — defines the acceptable lower/upper net position boundaries per instrument for CFD dealing.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `MarketMaker.dbo.Configurations` (JSON configuration) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table stores the daily exposure band limits for CFD instruments from the market maker system. Each row defines the acceptable net position range (LowerBound to UpperBound) for one instrument. These boundaries govern the CEP (Complex Event Processing) rules that trigger automatic hedging when net exposure exceeds the defined bands.

The data is extracted from a JSON configuration in `Dealing_staging.External_MarketMaker_dbo_Configurations`, specifically the `$.etoro_cfd` section of the `PushedOrderWithLPAndAggregationExecution_ExposureBandLimitsPerInstrumentPerPartyName` configuration. The SP parses the JSON using OPENJSON and extracts key-value pairs.

Author: Nixar Habib, created 2022-05-10. Type column added SR-351431 (2026-01-12) to distinguish between HBC and CBH configurations.

---

## 2. Business Logic

### 2.1 Boundary Interpretation

**What**: LowerBound and UpperBound define the acceptable net position range in units.

**Rules**:
- LowerBound is typically negative (maximum short exposure allowed)
- UpperBound is typically positive (maximum long exposure allowed)
- When net position exceeds either bound, CEP triggers an automatic hedge trade
- Boundaries are symmetric for most instruments (e.g., -10000 to 10000)

### 2.2 JSON Extraction

**What**: The SP extracts instrument boundaries from a nested JSON configuration.

**Rules**:
- Source config name: `PushedOrderWithLPAndAggregationExecution_ExposureBandLimitsPerInstrumentPerPartyName`
- CFD section: `$.etoro_cfd`
- Each instrument has a `Key` (LowerBound) and `Value` (UpperBound) in the JSON
- The latest configuration is used (ORDER BY LastUpdate, TOP 1)

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current boundaries | `WHERE Date = (SELECT MAX(Date) FROM ...)` |
| Boundary changes over time | `WHERE InstrumentName = @instrument ORDER BY Date` |
| Tightest/widest boundaries | `ORDER BY (UpperBound - LowerBound)` for a specific date |

### 3.2 Gotchas

- **DDL may not include Type column**: The DDL shows 5 columns but the SP inserts 6 (Type added SR-351431). Live data confirms Type exists.
- **Units, not USD**: Boundaries are in instrument units, not USD amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 — SP_MarketMakerBoundaries) |
| 2 | InstrumentName | varchar(250) | YES | Instrument name from market maker config. Format: "SYMBOL-CURRENCY" (e.g., "ZRX-USD", "BTC-USD"). (Tier 2 — SP_MarketMakerBoundaries) |
| 3 | LowerBound | bigint | YES | Minimum net position limit (units). Typically negative. When net short position exceeds this, CEP triggers a buy hedge. (Tier 2 — SP_MarketMakerBoundaries) |
| 4 | UpperBound | bigint | YES | Maximum net position limit (units). Typically positive. When net long position exceeds this, CEP triggers a sell hedge. (Tier 2 — SP_MarketMakerBoundaries) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_MarketMakerBoundaries) |
| 6 | Type | varchar(50) | YES | Configuration source type. Values: 'etoro_cfd'. Distinguishes between HBC and CBH configs. Added SR-351431 (2026-01-12). (Tier 2 — SP_MarketMakerBoundaries) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
MarketMaker.dbo.Configurations (JSON) → Dealing_staging → OPENJSON parsing → Dealing_MarketMakerBoundaries_CFD
```

---

## 6. Relationships

### 6.1 Companion Objects

| Object | Relationship |
|--------|-------------|
| Dealing_dbo.Dealing_MarketMakerBoundaries_Real | Same SP, same source — Real stock boundaries |
| Dealing_dbo.Dealing_CEP_ExecutionMonitoring | CEP uses these boundaries to trigger hedge trades |
| Dealing_dbo.Dealing_MarketMakerAllTrade | Hedge trades triggered when boundaries are exceeded |

---

*Generated: 2026-03-21 | Quality: 7.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_MarketMakerBoundaries_CFD | Type: Table | Production Source: JSON config*
