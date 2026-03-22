# Dealing_dbo.Dealing_MarketMakerBoundaries_Real

> Daily Real stock instrument exposure band limits from market maker configuration — defines the acceptable lower/upper net position boundaries per instrument for real stock dealing.

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

This table stores the daily exposure band limits for Real stock instruments (non-CFD) from the market maker system. Functionally identical to `Dealing_MarketMakerBoundaries_CFD` but for real stock positions. Each row defines the acceptable net position range per instrument.

Data extracted from the `$.eToro_Real_IM` and `$.etoro_MM_HBC_Real` sections of the same JSON configuration. The Real table includes two types: standard Real IM (Investment Management) and HBC Real boundaries (added SR-351431).

Same SP (`SP_MarketMakerBoundaries`), same source configuration, different JSON section.

---

## 2. Business Logic

### 2.1 Dual Real Types

**What**: Real boundaries come from two JSON sections.

**Rules**:
- `eToro_Real_IM` — Standard Real Investment Management boundaries
- `etoro_MM_HBC_Real` — HBC (High-Balance Client?) Real boundaries (added SR-351431)
- Both are UNION ALL'd into the same table, distinguished by `Type` column

Same boundary interpretation as CFD: LowerBound = max short exposure, UpperBound = max long exposure.

---

## 3. Query Advisory

Same patterns as `Dealing_MarketMakerBoundaries_CFD`. Filter by `Type` to separate IM vs HBC boundaries.

### 3.1 Gotchas

- **Two types in one table**: Unlike CFD (single type), Real has 'eToro_Real_IM' and 'etoro_MM_HBC_Real'. Filter by Type if comparing.
- **Same DDL mismatch**: Type column not in DDL but present in live data.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 — SP_MarketMakerBoundaries) |
| 2 | InstrumentName | varchar(250) | YES | Instrument name from market maker config (e.g., "ZRX-USD"). (Tier 2 — SP_MarketMakerBoundaries) |
| 3 | LowerBound | bigint | YES | Minimum net position limit (units). Typically negative. (Tier 2 — SP_MarketMakerBoundaries) |
| 4 | UpperBound | bigint | YES | Maximum net position limit (units). Typically positive. (Tier 2 — SP_MarketMakerBoundaries) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_MarketMakerBoundaries) |
| 6 | Type | varchar(50) | YES | Configuration source type. 'eToro_Real_IM' (standard) or 'etoro_MM_HBC_Real' (HBC). Added SR-351431. (Tier 2 — SP_MarketMakerBoundaries) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
MarketMaker.dbo.Configurations (JSON) → Dealing_staging → OPENJSON parsing → Dealing_MarketMakerBoundaries_Real
```

---

## 6. Relationships

### 6.1 Companion Objects

| Object | Relationship |
|--------|-------------|
| Dealing_dbo.Dealing_MarketMakerBoundaries_CFD | Same SP, same source — CFD boundaries |
| Dealing_dbo.Dealing_CEP_ExecutionMonitoring | CEP uses these boundaries to trigger hedge trades |

---

*Generated: 2026-03-21 | Quality: 7.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_MarketMakerBoundaries_Real | Type: Table | Production Source: JSON config*
