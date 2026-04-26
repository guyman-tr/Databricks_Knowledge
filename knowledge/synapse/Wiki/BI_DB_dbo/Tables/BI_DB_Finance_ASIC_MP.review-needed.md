# Review Sidecar — BI_DB_dbo.BI_DB_Finance_ASIC_MP

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | PASS | 32 columns in DDL, 32 in wiki |
| All columns have tier suffix | PASS | 31 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | PASS | SP_Finance_ASIC_MP matches OpsDB (Priority 0, SB_Daily) |
| Sample data reviewed | PASS | 5 rows — Close_Position phase, Commodities/Currencies, regulation = 'ASIC & GAML', amounts consistent with phase logic |
| ETL pattern confirmed | PASS | DELETE-INSERT by DateID |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | OpsDB dependencies | Medium | OpsDB lists SP_User_Segment_Snapshot (Priority 20) as a dependency, but the SP code does not reference any Segment/Snapshot tables. This may be an OpsDB scheduling artifact rather than a data dependency. Confirm whether this is a scheduling-only dependency. |
| 2 | IsSettled change phase | Medium | The change-detection phase uses `External_etoro_History_PositionChangeLog_Yesterday` which is created by a separate SP call. If that external table creation fails silently, the change phase would produce no rows but no error. Confirm if there is error handling around this. |
| 3 | GBP/EUR conversion | Medium | Currency conversion uses Ask price from Fact_CurrencyPriceWithSplit for InstrumentID 2 (GBP) and 1 (EUR). If no price exists for that date, the LEFT JOIN returns NULL and division by NULL produces NULL amounts. Confirm whether this is the intended fallback behavior. |
| 4 | Position_Phase for changes | Low | The IsSettled-change phase also uses 'Open_Position' as its Position_Phase label, making it indistinguishable from actual opens. Confirm whether this is intentional or whether a distinct phase label should be used. |
| 5 | Regulation filter asymmetry | Medium | Open positions are filtered by `dp.RegulationIDOnOpen IN (4, 10)` (position-level), but close positions use `fsc.RegulationID IN (4, 10)` (customer snapshot-level). A customer could change regulation between open and close. Confirm this asymmetry is intentional for regulatory reporting. |
| 6 | No downstream consumers | Low | No BI_DB SPs reference this table. Confirm it is consumed only by external dashboards (Tableau/Excel). |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 31 | All business columns |
| Tier 3 | 1 | UpdateDate |
