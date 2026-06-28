# Column Lineage: main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_marketing_marketingcloud_user_behavior_pi_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_marketing_marketingcloud_user_behavior_pi_v.json` (rows: 1, mismatches: 0) |
| **Primary upstream** | `main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_marketing_marketingcloud_user_behavior_pi.md` |

## Lineage Chain

```
main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi   ←── primary upstream
        │
        ▼
main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `AccountId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `CIDViewed` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `UserPI` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `LastVisit` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `LastOpen` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `LastMonthAmountInvest` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `LastMonthOpenPositionsInvest` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `TotalAmountInvest` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `TotalPositionsInvest` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `OpenActiveInstruments` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `DateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `UpdateDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **1**
- OK: **1**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
