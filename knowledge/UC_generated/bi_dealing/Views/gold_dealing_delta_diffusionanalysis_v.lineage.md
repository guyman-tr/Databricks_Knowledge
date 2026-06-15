# Column Lineage: main.bi_dealing.gold_dealing_delta_diffusionanalysis_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_delta_diffusionanalysis_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_delta_diffusionanalysis_v.json` (rows: 13, mismatches: 6) |
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
main.bi_dealing.gold_dealing_delta_diffusionanalysis_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionsTime` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `PositionsTime` | `passthrough` | — | PositionsTime |
| 2 | `InstrumentName` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 3 | `InstrumentID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 4 | `HedgeServerID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `HedgeServerID` | `passthrough` | — | HedgeServerID |
| 5 | `NOP` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `udf` | — | FORMAT_NUMBER(NOP, ',###') AS NOP |
| 6 | `NOP_80Percent` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `udf` | — | FORMAT_NUMBER(NOP_80Percent, ',###') AS NOP_80Percent |
| 7 | `Delta` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(Delta, ',###')) AS Delta |
| 8 | `DeltaSquared` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(DeltaSquared, ',###')) AS DeltaSquared |
| 9 | `Mid` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `Mid` | `passthrough` | — | Mid |
| 10 | `T` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `T` | `passthrough` | — | T |
| 11 | `Sigma` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `coalesce` | — | COALESCE(Sigma, 'Missing Sigma') AS Sigma |
| 12 | `SigmaDate` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `SigmaDate` | `passthrough` | — | SigmaDate |
| 13 | `DeltaRoot` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(DeltaRoot, ',###')) AS DeltaRoot |

## Cross-check vs system.access.column_lineage

- Total target columns: **13**
- OK: **7**, WARN: **0**, ERROR: **6**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `NOP` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.nop` | ERROR |
| `NOP_80Percent` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.nop_80percent` | ERROR |
| `Delta` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.delta`, `main.bi_dealing.gold_dealing_delta_diffusionanalysis.sigma` | ERROR |
| `DeltaSquared` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.deltasquared`, `main.bi_dealing.gold_dealing_delta_diffusionanalysis.sigma` | ERROR |
| `Sigma` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.sigma` | ERROR |
| `DeltaRoot` | — | `main.bi_dealing.gold_dealing_delta_diffusionanalysis.deltaroot`, `main.bi_dealing.gold_dealing_delta_diffusionanalysis.sigma` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **3**
