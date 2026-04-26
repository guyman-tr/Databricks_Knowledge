# Lineage: BI_DB_dbo.BI_DB_AB_Test_Data

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_AB_Test_Data
**Object Type**: Table — A/B test period-based assignment with experiment metadata
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — no Generic Pipeline mapping, no External Table, no SSDT SP
**Related Table**: BI_DB_dbo.BI_DB_AB_Test (daily-grain A/B assignment table, 2020–2023 tests)
**Migration History**: BI_DB_Migration.BI_DB_AB_Test_Data (migration staging, ROUND_ROBIN CCI)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | etoro production (Customer) | RealCID | Passthrough | Tier 3 |
| 2 | TestName | Unknown (experiment mgmt tool) | TestName | Passthrough | Tier 3 |
| 3 | IsControl | Unknown (experiment tool) | IsControl | 0=treatment, 1=control | Tier 3 |
| 4 | IsControlPortfolioEnabled | Unknown | Unknown | Experiment variant flag | Tier 4 |
| 5 | ServiceLevelAnchored | Unknown | Unknown | Experiment variant dimension | Tier 4 |
| 6 | IsPortfolioAnchored | Unknown | Unknown | Portfolio anchoring flag for treatment | Tier 3 |
| 7 | FromDateID | Unknown | StartDate | YYYYMMDD experiment start | Tier 3 |
| 8 | ToDateID | Unknown | EndDate | YYYYMMDD experiment end | Tier 3 |
| 9 | UpdateDate | Unknown | — | ETL load timestamp | Tier 5 |

## ETL Pipeline

```
Unknown source (Data Science team experiment tool or manual insert)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_AB_Test_Data (5,000 rows — loaded 2019-09-03, never updated)

Single test recorded:
  DataScienceSeptemberExperimentAM (Sept 2019 — portfolio anchoring experiment)
    FromDateID=20190902, ToDateID=20190930
    5,000 unique CIDs | 0=treatment (IsPortfolioAnchored=1), 1=control (IsPortfolioAnchored=NULL)

No downstream consumers identified.

Migration staging:
  BI_DB_Migration.BI_DB_AB_Test_Data (ROUND_ROBIN CCI — Sept 2024 migration event)
  BI_DB_Migration.JUNK_BI_DB_AB_Test_Data (junk table from migration cleanup)
```
