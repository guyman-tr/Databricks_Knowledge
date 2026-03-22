# Column Lineage: Dealing_dbo.Dealing_MarketMakerBoundaries_Real

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_MarketMakerBoundaries_Real` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `MarketMaker.dbo.Configurations` (production JSON config) |
| **ETL SP** | `SP_MarketMakerBoundaries` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
MarketMaker.dbo.Configurations (JSON) ──► Dealing_staging ──► SP_MarketMakerBoundaries ──► Dealing_MarketMakerBoundaries_Real
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| InstrumentName | JSON key | — | ETL-computed | Extracted from JSON `$.eToro_Real_IM` + `$.etoro_MM_HBC_Real` keys |
| LowerBound | JSON value | Key="Key" | ETL-computed | Extracted from JSON key-value pairs |
| UpperBound | JSON value | Key="Value" | ETL-computed | Extracted from JSON key-value pairs |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| Type | JSON section | — | ETL-computed | 'eToro_Real_IM' or 'etoro_MM_HBC_Real'. Added SR-351431. |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 6 |
| **Total** | 6 |
