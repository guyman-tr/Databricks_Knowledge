# BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | general.etoroGeneral_History_GuruCopiers | general | Copy AUM, copier counts | Timestamp = @Date+1 |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | Valid customer filter, copyfund identification, UserName | RealCID join (parent + child) |
| 3 | DWH_dbo.V_Liabilities | DWH_dbo | RealizedEquity, StandardDeviation | CID = ParentCID, DateID |
| 4 | BI_DB_dbo.BI_DB_rsk_Portfolio | BI_DB_dbo | Per-instrument NOP for weight calculation | CID = ParentCID, Date |
| 5 | DWH_dbo.Dim_Instrument_Correlation | DWH_dbo | Instrument covariance matrix (SampleSize>=200) | DateID = @DateIDCorrelation |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @Date | Direct |
| 2 | CID1 | etoroGeneral_History_GuruCopiers | ParentCID | Top 100 PI by AUM or eCopiers |
| 3 | ParentUserName1 | etoroGeneral_History_GuruCopiers | ParentUserName | Passthrough |
| 4 | Type1 | Dim_Customer | AccountTypeID | CASE: 9='Copyfund', else='Regular' |
| 5 | CID2 | etoroGeneral_History_GuruCopiers | ParentCID | Cross-join pair |
| 6 | ParentUserName2 | etoroGeneral_History_GuruCopiers | ParentUserName | Cross-join pair |
| 7 | Type2 | Dim_Customer | AccountTypeID | CASE: same as Type1 |
| 8 | COV | Dim_Instrument_Correlation + rsk_Portfolio | Covariance × Weights | SUM(Covariance × Weight1 × Weight2) |
| 9 | STD1 | V_Liabilities | StandardDeviation | Passthrough for PI 1 |
| 10 | AUM1 | etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPos+Dit_PnL | SUM for PI 1 |
| 11 | RealizedAUM1 | etoroGeneral_History_GuruCopiers | Cash+Investment+DetachedPos | SUM (no PnL) for PI 1 |
| 12 | eCopiers1 | etoroGeneral_History_GuruCopiers | Derived | COUNT WHERE equity >= $100 for PI 1 |
| 13 | rn_AUM1 | Computed | ROW_NUMBER() PARTITION BY Type ORDER BY AUM DESC | Rank for PI 1 |
| 14 | rn_eCopiers1 | Computed | ROW_NUMBER() PARTITION BY Type ORDER BY eCopiers DESC | Rank for PI 1 |
| 15 | STD2 | V_Liabilities | StandardDeviation | Passthrough for PI 2 |
| 16 | AUM2 | etoroGeneral_History_GuruCopiers | Same as AUM1 | SUM for PI 2 |
| 17 | RealizedAUM2 | etoroGeneral_History_GuruCopiers | Same as RealizedAUM1 | SUM for PI 2 |
| 18 | eCopiers2 | etoroGeneral_History_GuruCopiers | Derived | COUNT for PI 2 |
| 19 | rn_AUM2 | Computed | ROW_NUMBER() | Rank for PI 2 |
| 20 | rn_eCopiers2 | Computed | ROW_NUMBER() | Rank for PI 2 |
| 21 | Pearson | Computed | COV / (STD1 × STD2) | Pearson correlation coefficient |
| 22 | UpdateDate | ETL | GETDATE() | Row insert timestamp |
