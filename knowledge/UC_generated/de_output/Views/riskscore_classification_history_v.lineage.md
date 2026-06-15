# Column Lineage: main.de_output.riskscore_classification_history_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.riskscore_classification_history_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\de_output\_discovery\source_code\riskscore_classification_history_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\de_output\_discovery\column_lineage\riskscore_classification_history_v.json` (rows: 4, mismatches: 0) |
| **Primary upstream** | `main.de_output.de_output_risk_classification_history` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.de_output.de_output_risk_classification_history` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md` |

## Lineage Chain

```
main.de_output.de_output_risk_classification_history   ←── primary upstream
        │
        ▼
main.de_output.riskscore_classification_history_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.de_output.de_output_risk_classification_history` | `CID` | `passthrough` | — | CID |
| 2 | `RiskScoreName` | `main.de_output.de_output_risk_classification_history` | `RiskScoreName` | `passthrough` | — | RiskScoreName |
| 3 | `BeginTime` | `main.de_output.de_output_risk_classification_history` | `BeginTime` | `passthrough` | — | BeginTime |
| 4 | `EndTime` | `main.de_output.de_output_risk_classification_history` | `EndTime` | `passthrough` | — | EndTime |

## Cross-check vs system.access.column_lineage

- Total target columns: **4**
- OK: **4**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
