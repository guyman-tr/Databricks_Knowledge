# Description Quality — Phase D Dry-Run Summary

## Pipeline

1. Spec: `.cursor/rules/uc-pipeline-doc/description-quality.mdc`
2. Grader: `tools/desc_quality/grade.py` — classified 20,655 rows across 961 wikis as TRANSFORMATION / SEMANTIC / TRIVIAL
3. Climber: `tools/desc_quality/upstream_climber.py` — walks the `Source` cell to upstream wikis until non-trivial
4. Rewriter: `tools/desc_quality/rewrite.py` — replaces the trivial cell with the climbed upstream text + `(via {upstream_object})` tag

## Corpus-level results

| Metric | Count |
|---|---|
| Wikis examined | 3,407 |
| Wikis with rows graded | 961 |
| Rows graded | 20,655 |
| HAS_TRANSFORMATION | 5,439 (26.3%) |
| HAS_SEMANTIC | 14,193 (68.7%) |
| TRIVIAL | 1,023 (5.0%) |
| TRIVIAL rows climbable (FOUND) | 937 (91.6% of trivial) |
| TRIVIAL rows exhausted | 86 (8.4% of trivial) |
| Wikis with proposed edits | 33 |

## What the rewriter touches and does NOT touch

| Row type | Touched? |
|---|---|
| TRIVIAL with successful upstream climb | YES — replaced with `{upstream text} (via {upstream_object})` |
| TRIVIAL with exhausted climb | NO by default (use `--include-exhausted` to mark with `Passthrough — no upstream semantic (chain: …)` tag) |
| HAS_TRANSFORMATION | NO |
| HAS_SEMANTIC | NO |

## V_Liabilities — the test case

Before / after sample:

```diff
- | 1 | CID | Fact_SnapshotEquity.CID | Direct | T2 |
+ | 1 | CID | Fact_SnapshotEquity.CID | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 — SP_Fact_SnapshotEquity) (via Fact_SnapshotEquity) | T2 |

- | 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Direct | T2 |
+ | 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) (via Fact_SnapshotEquity) | T2 |
```

V_Liabilities: 60 of 63 trivial rows rewritten with rich semantic content. The 3 exhausted cases are:
- `DateID` → `V_M2M_Date_DateRange.DateKey` (upstream wiki's §4 is ETL & Data Pipeline, not a column table)
- `FullDate` → `V_M2M_Date_DateRange.FullDate` (same wiki)
- `CopyFundAUM` → `Fact_SnapshotEquity.CopyFundAUM` (column not in upstream wiki — possibly renamed)

## Worst 10 wikis by trivial count — all should be cleaned

| Wiki | Trivial | Climbable | Exhausted |
|---|---:|---:|---:|
| DWH_dbo/Views/V_Liabilities.md | 63 | 60 | 3 |
| BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.md | 61 | ~58 | ~3 |
| BI_DB_dbo/Functions/Function_Revenue_Commissions.md | 54 | ~54 | ~0 |
| BI_DB_dbo/Functions/Function_Revenue_FullCommissions.md | 54 | ~54 | ~0 |
| BI_DB_dbo/Functions/Function_Revenue_ConversionFee.md | 54 | ~54 | ~0 |
| BI_DB_dbo/Functions/Function_Revenue_CryptoToFiat_C2F.md | 51 | ~51 | ~0 |
| BI_DB_dbo/Functions/Function_Revenue_StakingFee.md | 50 | 50 | 0 |
| BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md | 47 | ? | ? |
| BI_DB_dbo/Functions/Function_MIMO_First_Deposit_All_Platforms.md | 46 | ? | ? |
| BI_DB_dbo/Functions/Function_Revenue_CashoutFee_ExcludeRedeem.md | 44 | ? | ? |

## How to apply

**One wiki:**
```
python tools/desc_quality/rewrite.py --wiki knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md --apply
```

**All 33 wikis at once:**
```
python tools/desc_quality/rewrite.py --glob "knowledge/synapse/Wiki/**/*.md" --apply
```

**Include exhausted (visible-failure tags):**
```
python tools/desc_quality/rewrite.py --wiki ... --apply --include-exhausted
```

## Output artifacts in this directory

- `report.csv` — one row per (wiki, column) touched, with old/new/status/hops
- `proposed_fixes.csv` — same schema as `tools/cleanup_tier1/apply_column_fixes.py`, usable with the existing review CLI
- `diff.patch` — unified diff for every wiki touched

## Limitations / known unknowns

- Wikis whose §4 is not a column table (e.g. `ETL & Data Pipeline`, `Live Data Verification`) are reported as exhausted-with-reason. The wiki content may still have semantics in some §X-3 prose block, but the climber doesn't read prose — strictly the table.
- The climber adopts upstream text verbatim. If the upstream is wrong (HAS_TRANSFORMATION but incorrect math), the rewriter propagates the error one hop down. The SQL-grounded audit pipeline is the correct check for that. They're complementary.
- Some wikis use `Element` instead of `Column` in their header; the parser handles both.
- The corpus contains ~2,400 wikis with no `## 4.` section at all (SPs, lineage files, indices). Those are skipped silently.
