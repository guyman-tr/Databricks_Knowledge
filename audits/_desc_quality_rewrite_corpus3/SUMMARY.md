# Description Quality — Phase E Dry-Run Summary (enhanced climber)

## What changed vs. Phase D

Phase D climb success: **937 / 1,023 trivial rows = 91.6%**.

Phase E added three climber enhancements:

| Enhancement | Reclaimed | Description |
|---|---:|---|
| **E1 — Multi-table §4 parser** | +16 | Wikis like `Dim_Customer` split §4 into sub-tables (Identity, PII, Acquisition, Lifecycle, …). The parser now collects rows from every sub-table, not just the first. |
| **E2 — §3 fallback for empty Source cells** | +10 | When Source cell is blank, try each `## 3. Source Objects` candidate. Unique match wins. |
| **E3 — Alias resolver via column-set overlap** | +44 | When Source cell is `<alias>.<col>` (e.g. `isn.IsFuture`), the alias is resolved to a §3 candidate by counting how many of that alias's columns appear in each candidate's §4. Highest score wins. |
| **+ Branch C / D tie-breakers** | (covered above) | When a column appears in multiple §3 candidates: prefer the §3 candidate with maximum overlap of the WHOLE wiki's column set ("primary source"); else prefer DWH_dbo over BI_DB_dbo, larger table wins. |

Phase E climb success: **1,007 / 1,023 = 98.4%**.

| | Phase D | Phase E |
|---|---:|---:|
| Trivial rows | 1,023 | 1,023 |
| FOUND | 937 | **1,007** |
| EXHAUSTED | 86 | **16** |
| Climb success | 91.6% | **98.4%** |
| Wikis with proposed edits | 33 | 36 |
| Regressions (FOUND -> EXHAUSTED) | — | 0 |
| Terminal-source shifts on previously-FOUND rows | — | 0 |

## The 16 remaining EXHAUSTED — honest failures

Every one of these is a real-world authoring or upstream-completeness issue that no climber heuristic can paper over.

| Wiki | Column | Cause | Action |
|---|---|---|---|
| Function_MIMO_Options_Platform | OfficeCode, RegisteredRepCode, AccountNumber, TransactionID | Source `External_Sodreconciliation_apex_EXT869_CashActivity` — external table, no wiki | Create the external wiki, or accept Passthrough tag |
| Function_Search_Functions | function_name, function_type | Source `sys.objects` — SQL Server system catalog, no wiki | Accept Passthrough |
| Function_Instrument_Snapshot_Enriched | InstrumentID | `etig.InstrumentID` — alias `etig` (DWH_staging.Trade_InstrumentGroups), no wiki | Create the staging wiki |
| Function_PnL_Single_Day | IsCopyFund, IsMarginTrade, ClosedOnDate | Empty source cell, no §3 candidate has the column | Fix the wiki — add Source values |
| Function_Population_Active_Traders | RealCID, DateID | Multi-source (`Fact_X, Function_Y`) — column is from a JOIN, not a passthrough | Fix the wiki — these rows should not say "Direct"; they are coalesces |
| Function_Revenue_Trading_Instrument_Level | IsSettled | Multi-source | Same |
| V_Liabilities | DateID, FullDate | Upstream `V_M2M_Date_DateRange.md` has §4 = "ETL & Data Pipeline", not a column table | Fix the upstream wiki |
| V_Liabilities | CopyFundAUM | Upstream `Fact_SnapshotEquity.md` has no `CopyFundAUM` row (possibly renamed) | Add CopyFundAUM to Fact_SnapshotEquity wiki |

Reason histogram:
- 7 unresolved_object — externals & sys catalog
- 3 empty_source_no_section3_match — wiki authoring gaps
- 3 multi_source — wikis incorrectly labeled join-derived columns as "Direct"
- 2 section_4_not_a_column_table — upstream wiki is a non-column doc
- 1 column_not_found — column missing from upstream wiki

## V_Liabilities — still rich

V_Liabilities: 63 trivial rows → 60 FOUND, 3 EXHAUSTED (same as Phase D, same 3 honest failures).

## Worked example — `Function_Instrument_Snapshot_Enriched.IsFuture`

- Source cell: `isn.IsFuture`
- §3 candidates: `Dim_Instrument`, `Dim_Instrument_Snapshot`, `Fact_CurrencyPriceWithSplit`
- Aliased columns under `isn` in this wiki: 45 columns
- Overlap scores: Dim_Instrument 45/45, Dim_Instrument_Snapshot 7/45, Fact_CurrencyPriceWithSplit 2/45
- Alias `isn` → Dim_Instrument
- Climb: `Function_Instrument_Snapshot_Enriched.IsFuture` → `Dim_Instrument.IsFuture` → "1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument)"
- Rendered cell: `1=futures contract … (via Dim_Instrument)`

(The alias name `isn` is misleading — it sounds like Instrument_Snapshot_Name, but the actual SQL uses it for Dim_Instrument. The column-set overlap doesn't care what the writer named the alias.)

## How to apply

**V_Liabilities only:**
```
python tools/desc_quality/rewrite.py --wiki knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md --apply
```

**All 36 affected wikis:**
```
python tools/desc_quality/rewrite.py --glob "knowledge/synapse/Wiki/**/*.md" --apply
```

**Include passthrough tags for the 16 exhausted:**
```
python tools/desc_quality/rewrite.py --glob "knowledge/synapse/Wiki/**/*.md" --apply --include-exhausted
```
