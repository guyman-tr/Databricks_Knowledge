# Column Lineage: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_nixar_beta_dailybetaprod_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_nixar_beta_dailybetaprod_v.json` (rows: 20, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nixar_beta_dailybetaprod.md` |

## Lineage Chain

```
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod   ←── primary upstream
        │
        ▼
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `InstrumentName` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 2 | `Date` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `Date` | `passthrough` | — | Date |
| 3 | `SectorBeta` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorBeta` | `passthrough` | — | SectorBeta |
| 4 | `SectorName` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorName` | `passthrough` | — | SectorName |
| 5 | `SectorBeta30` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorBeta30` | `passthrough` | — | SectorBeta30 |
| 6 | `SectorBeta90` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorBeta90` | `passthrough` | — | SectorBeta90 |
| 7 | `AskClose` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `AskClose` | `passthrough` | — | AskClose |
| 8 | `BidClose` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `BidClose` | `passthrough` | — | BidClose |
| 9 | `InstrumentAskPctChange` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `InstrumentAskPctChange` | `passthrough` | — | InstrumentAskPctChange |
| 10 | `PriceTime` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `PriceTime` | `passthrough` | — | PriceTime |
| 11 | `SectorAskClose` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorAskClose` | `passthrough` | — | SectorAskClose |
| 12 | `SectorBidClose` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorBidClose` | `passthrough` | — | SectorBidClose |
| 13 | `SectorAskPctChange` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorAskPctChange` | `passthrough` | — | SectorAskPctChange |
| 14 | `SectorPriceTime` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorPriceTime` | `passthrough` | — | SectorPriceTime |
| 15 | `InstrumentID` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 16 | `SectorID` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `SectorID` | `passthrough` | — | SectorID |
| 17 | `Correlation30` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `Correlation30` | `passthrough` | — | Correlation30 |
| 18 | `Correlation` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `Correlation` | `passthrough` | — | Correlation |
| 19 | `Correlation90` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `Correlation90` | `passthrough` | — | Correlation90 |
| 20 | `UpdateDate` | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | `UpdateDate` | `passthrough` | — | UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **20**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **20**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
