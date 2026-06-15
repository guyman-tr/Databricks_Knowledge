# Column Lineage: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_nixar_beta_dailybetatarget_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_nixar_beta_dailybetatarget_v.json` (rows: 3, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nixar_beta_dailybetatarget.md` |

## Lineage Chain

```
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget   ←── primary upstream
        │
        ▼
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `InstrumentID` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 2 | `InstrumentIDToHedge` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget` | `InstrumentIDToHedge` | `passthrough` | — | InstrumentIDToHedge |
| 3 | `Multiplier` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget` | `Multiplier` | `passthrough` | — | Multiplier |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **3**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
