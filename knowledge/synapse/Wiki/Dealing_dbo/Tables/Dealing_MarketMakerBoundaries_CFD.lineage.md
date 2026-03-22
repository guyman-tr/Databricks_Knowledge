# Column Lineage: Dealing_dbo.Dealing_MarketMakerBoundaries_CFD

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_MarketMakerBoundaries_CFD` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `MarketMaker.dbo.Configurations` (production JSON config) |
| **ETL SP** | `SP_MarketMakerBoundaries` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
MarketMaker.dbo.Configurations (JSON) ──► Dealing_staging ──► SP_MarketMakerBoundaries ──► Dealing_MarketMakerBoundaries_CFD
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| InstrumentName | JSON key | — | ETL-computed | Extracted from JSON `$.etoro_cfd` keys via OPENJSON |
| LowerBound | JSON value | Key="Key" | ETL-computed | Extracted from JSON key-value pairs |
| UpperBound | JSON value | Key="Value" | ETL-computed | Extracted from JSON key-value pairs |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| Type | JSON section | — | ETL-computed | 'etoro_cfd' for CFD boundaries. Added SR-351431. |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 6 |
| **Total** | 6 |
