# Column Lineage: main.bi_dealing.gold_dealing_delta_oms_models_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_delta_oms_models_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_delta_oms_models_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_delta_oms_models_v.json` (rows: 8, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.gold_dealing_delta_oms_diffusion` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.gold_dealing_delta_oms_diffusion` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_oms_diffusion.md` |

## Lineage Chain

```
main.bi_dealing.gold_dealing_delta_oms_diffusion   ←── primary upstream
        │
        ▼
main.bi_dealing.gold_dealing_delta_oms_models_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Instrument` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `Instrument` | `passthrough` | — | Instrument |
| 2 | `Model` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `Model` | `passthrough` | — | Model |
| 3 | `ModelParameter` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `ModelParameter` | `passthrough` | — | ModelParameter |
| 4 | `Value` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `Value` | `passthrough` | — | Value |
| 5 | `UpdateTime` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `UpdateTime` | `passthrough` | — | UpdateTime |
| 6 | `ModelVersion` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `ModelVersion` | `passthrough` | — | ModelVersion |
| 7 | `URL` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `URL` | `passthrough` | — | URL |
| 8 | `OmsParam` | `main.bi_dealing.gold_dealing_delta_oms_diffusion` | `OmsParam` | `passthrough` | — | OmsParam |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **8**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
