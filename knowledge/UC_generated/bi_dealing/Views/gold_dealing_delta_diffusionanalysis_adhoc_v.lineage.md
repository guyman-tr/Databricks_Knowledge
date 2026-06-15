# Column Lineage: main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_delta_diffusionanalysis_adhoc_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_delta_diffusionanalysis_adhoc_v.json` (rows: 12, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysis_adhoc.md` |

## Lineage Chain

```
main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc   ←── primary upstream
        │
        ▼
main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionsTime` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `PositionsTime` | `passthrough` | — | PositionsTime |
| 2 | `InstrumentName` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 3 | `InstrumentID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 4 | `HedgeServerID` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `HedgeServerID` | `passthrough` | — | HedgeServerID |
| 5 | `NOP` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `—` | `udf` | — | FORMAT_NUMBER(NOP, ',###') AS NOP |
| 6 | `NOP_80Percent` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `—` | `udf` | — | FORMAT_NUMBER(NOP_80Percent, ',###') AS NOP_80Percent |
| 7 | `Delta` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(Delta, ',###')) AS Delta |
| 8 | `DeltaSquared` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `—` | `unknown` | — | IF(Sigma IS NULL, 'Missing Sigma', FORMAT_NUMBER(DeltaSquared, ',###')) AS DeltaSquared |
| 9 | `Mid` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `Mid` | `passthrough` | — | Mid |
| 10 | `T` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `T` | `passthrough` | — | T |
| 11 | `Sigma` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `—` | `coalesce` | — | COALESCE(Sigma, 'Missing Sigma') AS Sigma |
| 12 | `SigmaDate` | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc` | `SigmaDate` | `passthrough` | — | SigmaDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **12**
- OK: **5**, WARN: **0**, ERROR: **0**, INFO: **7**  ✓

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**
