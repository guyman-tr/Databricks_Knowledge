# Review Sidecar -- BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_Report

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | PASSED | 33 columns |
| All columns have tier suffix | PASSED | Tier 2 + Tier 3 (UpdateDate) |
| Writer SP confirmed | PASSED | SP_Finance_Non_US_Settlement_Report |
| Sample data reviewed | PASSED | Live prod Synapse: TOP 5 by ReportDate DESC -- 20260319, NA Gap_Type, regulation splits and providers match SP |
| Distribution queries | PASSED | Gap_Type `COUNT_BIG` + row count on prod |

## Items for human review

| # | Topic | Confidence | Question |
|---|-------|------------|----------|
| 1 | Historical Gap_Type | High | Legacy gap labels retained in billions of rows; current SP writes `NA` only. Confirm reporting filters for "current policy" views. |
| 2 | FinCEN/FINRA columns | High | Always zero given RegulationID filter; confirm if any exception path is planned. |

## Reviewer corrections

*(None)*

## Tier distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 32 | All business columns |
| Tier 3 | 1 | UpdateDate |
