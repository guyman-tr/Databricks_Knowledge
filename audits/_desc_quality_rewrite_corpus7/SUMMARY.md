# Description Quality — Phase F: SQL-grounded climbing

## Progression

| Phase | Description | FOUND | EXHAUSTED | % |
|---|---|---:|---:|---:|
| **D** | Wiki-only chain climb | 937 | 86 | 91.6% |
| **E** | + multi-table parser, §3 alias resolver, §3 empty-cell fallback | 1,007 | 16 | 98.4% |
| **F** | + SSDT SQL walker (current) | **1,022** | **1** | **99.9%** |

Zero regressions across all phases (no row that was FOUND in a prior phase became EXHAUSTED later; no terminal-source shifted for any previously-FOUND row).

## What Phase F added

A new module `tools/desc_quality/sql_walker.py` parses the SSDT source SQL of views/functions (via existing `tools/cleanup_tier1/sql_locator.py` for file routing) and walks the projections through CTEs, derived subqueries, and UNION branches until it finds a non-trivial producing expression. The walker is invoked by the climber as a last-resort fallback when wiki-based avenues fail.

### Three classes of SQL output

1. **Expression terminal** (CASE / COALESCE / literal / arithmetic):
   - Output goes directly into the rewritten cell.
   - Example: `Function_PnL_Single_Day.IsMarginTrade` → wiki had empty Source cell and "Direct". SQL walker found `CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END (sql-derived [case] from Function_PnL_Single_Day)`.

2. **Passthrough to a real upstream table**:
   - Climber redirects to that table's wiki and continues the chain. The aliased prefix is ignored (the SQL knows the real object).
   - Example: `Function_Instrument_Snapshot_Enriched.InstrumentID` → wiki Source `etig.InstrumentID` couldn't be resolved by alias map; SQL walker said "passthrough from DWH_dbo.Dim_Instrument" → climber walked to `Dim_Instrument.InstrumentID` and adopted its rich description.

3. **Passthrough from a no-wiki source** (external table, sys.objects):
   - Climber synthesizes a terminal that names the source.
   - Example: `Function_MIMO_Options_Platform.OfficeCode` → `Passthrough from BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity.OfficeCode (no upstream wiki)`.

### Wiki-not-a-column-table rescue

When the climb hits a hop whose wiki has no §4 column table (e.g. `V_M2M_Date_DateRange` whose §4 is "ETL & Data Pipeline"), the climber now ALSO tries SQL-walking that hop's wiki to continue. Reclaimed both V_Liabilities `DateID` and `FullDate` by walking V_M2M_Date_DateRange.sql → identifying `Dim_Date` as the source → adopting Dim_Date's rich descriptions.

## Function_PnL_Single_Day — worked example

Original wiki state (all 13 trivial rows had empty Source cells):

```
| 1 | DateID         |  | @dateID            | T2 |
| 2 | CID            |  | Direct             | T1 |
| 16 | IsFuture      |  | Direct             | T1 |
| 17 | IsCopyFund    |  | Direct             | T1 |
| 18 | IsMarginTrade |  | Direct             | T1 |
```

After Phase F rewrite:

| Column | New cell |
|---|---|
| CID | (via §3-primary-source: Dim_Position) Customer ID. … |
| PositionID | (via §3-primary-source: Dim_Position) Position primary key… |
| IsFuture | (via §3-schema-priority: Dim_Instrument) 1=futures contract, 0=non-futures, 243 flagged as futures. … |
| IsBuy | (via §3-primary-source: Dim_Position) 1 = Long/Buy (profit when price rises), 0 = Short/Sell. … |
| **ClosedOnDate** | **(sql-derived [literal]) `0` — branch indicator literal from BI_DB_PositionPnL arm** |
| **IsCopyFund** | **(sql-derived [case]) `CASE WHEN NOT cpt.PositionID IS NULL THEN 1 ELSE 0 END`** |
| **IsMarginTrade** | **(sql-derived [case]) `CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END`** |

The 3 originally-orphan columns (no upstream wiki anywhere in the corpus) now carry their actual CASE expressions, sourced directly from the function's DDL.

## The 1 remaining EXHAUSTED

`V_Liabilities.CopyFundAUM` → `Fact_SnapshotEquity.CopyFundAUM`. Fact_SnapshotEquity is a TABLE (not a view/function), so the SSDT producer SQL is a Stored Procedure — outside the current SQL walker's scope. The `CopyFundAUM` column also does not appear in Fact_SnapshotEquity.md's §4 (possibly renamed in the table but not in the wiki).

This is a genuine wiki authoring gap; the visible Passthrough tag will mark it so a human can fix the upstream wiki.

## V_Liabilities — 62 / 63 trivial rows rewritten

(Up from 60 in Phase E: now also includes DateID and FullDate via the SQL-walk-through-broken-upstream rescue.)

## Acceptance

| Metric | Value |
|---|---|
| Wikis examined | 3,407 |
| Wikis with proposed edits | 39 |
| Trivial rows | 1,023 |
| FOUND | 1,022 |
| EXHAUSTED | 1 |
| Climb success | 99.90% |
| Regressions vs. any prior phase | 0 |

## Artifacts in this directory

- `report.csv` — one row per (wiki, column) trivial-cell decision
- `proposed_fixes.csv` — review-CLI-compatible diff with `old_description`, `new_description`, `reason`
- `diff.patch` — unified diff for the 39 affected wikis
- `SUMMARY.md` — this file

## How to apply

```
python tools/desc_quality/rewrite.py --glob "knowledge/synapse/Wiki/**/*.md" --apply
```

Or single-wiki:

```
python tools/desc_quality/rewrite.py --wiki knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md --apply
```
