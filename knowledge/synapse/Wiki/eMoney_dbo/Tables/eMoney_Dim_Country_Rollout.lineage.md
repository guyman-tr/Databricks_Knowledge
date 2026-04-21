# Column Lineage — eMoney_dbo.eMoney_Dim_Country_Rollout

**Generated**: 2026-04-21
**Writer SP**: `SP_eMoney_Dim_Country_Rollout`
**Primary Source**: `DWH_dbo.Dim_Country` (hardcoded CASE for rollout dates)
**ETL Pattern**: DELETE + INSERT (full refresh daily)

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough | Tier 4 |
| 2 | CountryName | DWH_dbo.Dim_Country | Name | Renamed (Name → CountryName) | Tier 4 |
| 3 | RolloutDate | SP_eMoney_Dim_Country_Rollout | — | Hardcoded CASE per CountryID (34 entries, 2020-11-01 to 2025-10-15) | Tier 2 |
| 4 | RolloutDateID | SP_eMoney_Dim_Country_Rollout | — | Computed: CAST(CONVERT(VARCHAR(8), RolloutDate, 112) AS INT) → YYYYMMDD int | Tier 2 |
| 5 | Region | DWH_dbo.Dim_Country | Region | Passthrough | Tier 4 |
| 6 | Desk | DWH_dbo.Dim_Country | Desk | Passthrough | Tier 4 |
| 7 | UpdateDate | SP_eMoney_Dim_Country_Rollout | — | GETDATE() at insert time | Tier 2 |

---

## ETL Pipeline

```
DWH_dbo.Dim_Country (cross-schema, filtered to 34 eToro Money countries)
  + Hardcoded CASE rollout dates (per CountryID in SP)
  + IsCountryOpen filter (RolloutDate <= GETDATE())
    |-- SP_eMoney_Dim_Country_Rollout (DELETE + INSERT daily) ---|
    v
eMoney_dbo.eMoney_Dim_Country_Rollout (34 rows)
  |-- (no UC Gold target identified) ---|
```

---

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Dim_Country | DWH_dbo | Source dimension — provides CountryID, Name, Region, Desk |
| SP_eMoney_Dim_Country_Rollout | eMoney_dbo | Writer SP — hardcodes rollout dates, filters by IsCountryOpen |

---

## Notes

- Only rows where `RolloutDate <= GETDATE()` are inserted — future rollout countries are excluded until their date passes.
- Australia (CountryID=12) rollout date 2025-10-15 was added by Shachar Rubin on 2026-01-12 (per SP comment: "2025-10-12").
- 34 distinct countries as of 2026-04-12.
- DWH_dbo.Dim_Country has no wiki yet → passthrough columns are Tier 4.
