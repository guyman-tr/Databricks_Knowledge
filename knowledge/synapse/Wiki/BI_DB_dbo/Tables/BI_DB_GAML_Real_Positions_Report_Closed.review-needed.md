# Review Sidecar -- BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Closed

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | PASSED | 19 columns |
| All columns have tier suffix | PASSED | Tier 2 + Tier 3 (UpdateDate) |
| Writer SP confirmed | PASSED | SP_Finance_Non_US_Settlement_Report |
| Sample data reviewed | PASSED | Live prod Synapse: TOP 5 ORDER BY CloseDateID DESC |
| Distribution queries | PASSED | Regulation_Name, InstrumentType `COUNT_BIG`; row count |

## Items for human review

| # | Topic | Confidence | Question |
|---|-------|------------|----------|
| 1 | Max CloseDateID vs other tables | Medium | Sample ORDER BY CloseDateID DESC returned 20250702 while opened table shows 20260319 -- may reflect days with zero GAML closes; confirm reporting expectations. |

## Reviewer corrections

*(None)*

## Tier distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 18 | All business columns |
| Tier 3 | 1 | UpdateDate |
