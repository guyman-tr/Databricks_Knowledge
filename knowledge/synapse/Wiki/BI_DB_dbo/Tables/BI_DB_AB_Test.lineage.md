# Lineage: BI_DB_dbo.BI_DB_AB_Test

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_AB_Test
**Object Type**: Table — A/B test daily assignment tracking (experiment management)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — no Generic Pipeline mapping, no External Table, no SSDT SP
**Related Table**: BI_DB_dbo.BI_DB_AB_Test_Data (period-based A/B test assignment table, 2019 only)
**Migration History**: BI_DB_Migration.BI_DB_AB_Test (migration staging, ROUND_ROBIN CCI, UpdateDate varchar(50))

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | DateID | Unknown (experiment mgmt tool) | DateID | YYYYMMDD int key | Tier 3 |
| 2 | Date | Unknown | Date | Calendar date | Tier 3 |
| 3 | RealCID | etoro production (Customer) | RealCID | Passthrough | Tier 3 |
| 4 | IsControl | Unknown (experiment tool) | IsControl | 0=treatment, 1=control | Tier 3 |
| 5 | BI_Owner | Unknown (manually entered) | — | BI analyst name who owns the test | Tier 3 |
| 6 | Business_Owner | Unknown (manually entered) | — | Product/business owner name | Tier 3 |
| 7 | Name | Unknown (experiment tool) | TestName | A/B test identifier string | Tier 3 |
| 8 | UpdateDate | Unknown | — | ETL load timestamp | Tier 5 |

## ETL Pipeline

```
Unknown source (experiment management platform or manual SQL insert)
  |-- No Generic Pipeline, no External Table, no SSDT SP --|
  v
BI_DB_dbo.BI_DB_AB_Test (314,240 rows — last updated 2023-04-30, stale since)

Known tests loaded:
  AB_Test_lead_conv_202202     (BI: Tom Boksenbojm / Business: Elie Edery)
    2022-03-02 → 2023-04-29 | 239,186 CIDs | 33,840 control / 205,346 treatment
  AB_Test_Onboarding_202007    (BI: Tom Boksenbojm / Business: Steven Freedman)
    2020-06-10 → 2022-03-01 | ~73,675 unique CIDs | all rows IsControl=1

No downstream consumers identified in SSDT SPs or views.

Migration artifact:
  BI_DB_Migration.BI_DB_AB_Test → same schema, ROUND_ROBIN CCI (Sept 2024 migration staging)
```
