# Column Lineage — DWH_dbo.V_Dim_Instrument_Correlation

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| All 10 columns | Dim_Instrument_Correlation_Active | 3-part UNION ALL: recent half-matrix expansion + mirror pairs + older full matrix passthrough |

## Date split at 20250202. See [Dim_Instrument_Correlation.lineage.md](Dim_Instrument_Correlation.lineage.md) for upstream architecture.
