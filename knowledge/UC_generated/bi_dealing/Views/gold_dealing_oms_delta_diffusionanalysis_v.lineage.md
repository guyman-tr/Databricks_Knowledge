# Column Lineage: main.bi_dealing.gold_dealing_oms_delta_diffusionanalysis_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_oms_delta_diffusionanalysis_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_oms_delta_diffusionanalysis_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_oms_delta_diffusionanalysis_v.json` (rows: 8, mismatches: 1) |
| **Primary upstream** | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysis.md` |

## Lineage Chain

```
main.bi_dealing.gold_dealing_delta_diffusionanalysis   ←── primary upstream
        │
        ▼
main.bi_dealing.gold_dealing_oms_delta_diffusionanalysis_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Instrument` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `InstrumentID` | `cast` | — | cast to STRING — CAST(InstrumentID AS STRING) AS Instrument |
| 2 | `Model` | `—` | `—` | `literal` | — | literal `'FuturesNOP'` — 'FuturesNOP' AS Model |
| 3 | `ModelParameter` | `—` | `—` | `literal` | — | literal `'portfolioId'` — 'portfolioId' AS ModelParameter |
| 4 | `Value` | `—` | `—` | `literal` | — | literal `'HS225-ExpiringFutures-Hedging_NOP'` — 'HS225-ExpiringFutures-Hedging_NOP' AS Value |
| 5 | `UpdateTime` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `PositionsTime` | `cast` | — | cast to STRING — CAST(PositionsTime AS STRING) AS UpdateTime |
| 6 | `ModelVersion` | `—` | `—` | `literal` | — | literal `'1'` — '1' AS ModelVersion |
| 7 | `URL` | `—` | `—` | `literal` | — | literal `'/api/db/table/PortfolioProperty'` — '/api/db/table/PortfolioProperty' AS URL |
| 8 | `OmsParam` | `—` | `—` | `literal` | — | literal `'portfolioId'` — 'portfolioId' AS OmsParam |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **7**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Value` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.deltasquared`, `main.bi_dealing.gold_dealing_delta_diffusionanalysis.instrumentid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **6**

## Joins (detected)

- `LEFT OUTER` — LEFT OUTER JOIN factors AS ff USING (InstrumentID)
