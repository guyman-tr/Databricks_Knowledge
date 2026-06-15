# Column Lineage: main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_delta_diffusionanalysisfx_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_delta_diffusionanalysisfx_v.json` (rows: 14, mismatches: 7) |
| **Primary upstream** | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysisfx.md` |

## Lineage Chain

```
main.bi_dealing.gold_dealing_delta_diffusionanalysisfx   ←── primary upstream
        │
        ▼
main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionsTime` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `PositionsTime` | `passthrough` | — | PositionsTime |
| 2 | `InstrumentName` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 3 | `InstrumentID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 4 | `HedgeServerID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `HedgeServerID` | `passthrough` | — | HedgeServerID |
| 5 | `USD_NOP` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `udf` | — | FORMAT_NUMBER(USD_NOP, ',###') AS USD_NOP |
| 6 | `UnitsNOP` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `udf` | — | FORMAT_NUMBER(UnitsNOP, ',###') AS UnitsNOP |
| 7 | `Delta` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(Delta, ',###')) AS Delta |
| 8 | `DeltaRatio` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', DeltaRatio) AS DeltaRatio |
| 9 | `DeltaSquared` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(DeltaSquared, ',###')) AS DeltaSquared |
| 10 | `DeltaSquaredRatio` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', DeltaSquaredRatio) AS DeltaSquaredRatio |
| 11 | `Mid` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `Mid` | `passthrough` | — | Mid |
| 12 | `T` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `T` | `passthrough` | — | T |
| 13 | `Sigma` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `—` | `coalesce` | — | COALESCE(Sigma, 'Missing Sigma') AS Sigma |
| 14 | `SigmaDate` | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx` | `SigmaDate` | `passthrough` | — | SigmaDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **14**
- OK: **7**, WARN: **0**, ERROR: **7**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `USD_NOP` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.usd_nop` | ERROR |
| `UnitsNOP` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.unitsnop` | ERROR |
| `Delta` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.delta`, `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.sigma` | ERROR |
| `DeltaRatio` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.deltaratio`, `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.sigma` | ERROR |
| `DeltaSquared` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.deltasquared`, `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.sigma` | ERROR |
| `DeltaSquaredRatio` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.deltasquaredratio`, `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.sigma` | ERROR |
| `Sigma` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysisfx.sigma` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **4**
