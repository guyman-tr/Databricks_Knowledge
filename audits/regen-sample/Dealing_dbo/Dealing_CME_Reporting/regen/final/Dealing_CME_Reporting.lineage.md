# Lineage: Dealing_dbo.Dealing_CME_Reporting

## Source Objects

| # | Source Object | Type | Schema | Relationship | Evidence |
|---|--------------|------|--------|-------------|----------|
| 1 | DWH_dbo.Dim_Instrument | Table | DWH_dbo | Instrument filter + display name source | SP_M_CME_Reporting: `FROM DWH_dbo.Dim_Instrument di WHERE di.InstrumentID IN (...)` |
| 2 | DWH_dbo.Dim_Position | Table | DWH_dbo | Position data source (open + close) | SP_M_CME_Reporting: `FROM DWH_dbo.Dim_Position dp JOIN #Ins i ON dp.InstrumentID = i.InstrumentID` |
| 3 | DWH_dbo.Dim_Customer | Table | DWH_dbo | Valid customer filter | SP_M_CME_Reporting: `LEFT JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = dp.CID WHERE dc.IsValidCustomer = 1` |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | Date | ETL-computed | — | @EndOfMonth: last calendar day of the reporting month, derived from @Date parameter via DATEADD arithmetic | Tier 2 — SP_M_CME_Reporting |
| 2 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE: when LOWER(InstrumentDisplayName) LIKE '%crude oil%' then 'Crude Oil Future', else passthrough | Tier 2 — SP_M_CME_Reporting |
| 3 | CID_Count | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT p.CID) across open + close positions for the month, filtered to valid customers | Tier 2 — SP_M_CME_Reporting |
| 4 | Monthly_Volume | DWH_dbo.Dim_Position | Volume, VolumeOnClose | SUM(CAST(p.Volume AS bigint)): Volume for opens + VolumeOnClose for closes, combined via UNION ALL | Tier 2 — SP_M_CME_Reporting |
| 5 | UpdateDate | ETL-computed | — | GETDATE() at insert time | Tier 2 — SP_M_CME_Reporting |
