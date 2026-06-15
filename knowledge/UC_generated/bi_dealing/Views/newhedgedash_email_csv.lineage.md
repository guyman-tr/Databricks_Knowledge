# Column Lineage: main.bi_dealing.newhedgedash_email_csv

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.newhedgedash_email_csv` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\newhedgedash_email_csv.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\newhedgedash_email_csv.json` (rows: 21, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.bi_output_dealing_nhd_dashboard` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.bi_output_dealing_nhd_dashboard` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nhd_dashboard.md` |

## Lineage Chain

```
main.bi_dealing.bi_output_dealing_nhd_dashboard   ←── primary upstream
        │
        ▼
main.bi_dealing.newhedgedash_email_csv   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Date` | `passthrough` | — | Date |
| 2 | `HS` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `HS` | `passthrough` | — | HS |
| 3 | `LiquidityAccountID` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `LiquidityAccountID` | `passthrough` | — | LiquidityAccountID |
| 4 | `LiquidityAccountName` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `LiquidityAccountName` | `passthrough` | — | LiquidityAccountName |
| 5 | `INS` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `INS` | `passthrough` | — | INS |
| 6 | `InstrumentType` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `InstrumentType` | `passthrough` | — | InstrumentType |
| 7 | `Symbol` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Symbol` | `passthrough` | — | Symbol |
| 8 | `Clients_Units_Buy` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_Units_Buy` | `passthrough` | — | Clients_Units_Buy |
| 9 | `Clients_Units_Sell` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_Units_Sell` | `passthrough` | — | Clients_Units_Sell |
| 10 | `Clients_Units` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_Units` | `passthrough` | — | Clients_Units |
| 11 | `eToro_Units` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `eToro_Units` | `passthrough` | — | eToro_Units |
| 12 | `Diff_Units` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Diff_Units` | `passthrough` | — | Diff_Units |
| 13 | `Clients_NOPUSD_Buy` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_NOPUSD_Buy` | `passthrough` | — | Clients_NOPUSD_Buy |
| 14 | `Clients_NOPUSD_Sell` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_NOPUSD_Sell` | `passthrough` | — | Clients_NOPUSD_Sell |
| 15 | `Clients_NOPUSD` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Clients_NOPUSD` | `passthrough` | — | Clients_NOPUSD |
| 16 | `eToro_NOPUSD` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `eToro_NOPUSD` | `passthrough` | — | eToro_NOPUSD |
| 17 | `Uncovered_NOP` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Uncovered_NOP` | `passthrough` | — | Uncovered_NOP |
| 18 | `ISINCode` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `ISINCode` | `passthrough` | — | ISINCode |
| 19 | `Ask` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Ask` | `passthrough` | — | Ask |
| 20 | `Bid` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `Bid` | `passthrough` | — | Bid |
| 21 | `UpdateDate` | `main.bi_dealing.bi_output_dealing_nhd_dashboard` | `UpdateDate` | `passthrough` | — | UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **5**, WARN: **0**, ERROR: **0**, INFO: **16**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
