# Lineage: BI_DB_dbo.BI_DB_GuruRatios

## Source Objects

| Source Object | Schema | Type | Relationship | Join Condition |
|--------------|--------|------|-------------|----------------|
| etoroGeneral_History_GuruCopiers | general | External Table | Data source — copier hierarchy with Cash + Investment | partition_date = @Timestamp |
| V_Liabilities | DWH_dbo | View | Data source — RealizedEquity for ratio denominator | GC.ParentCID = V.CID AND V.DateID = @TimestampID |
| Dim_Customer | DWH_dbo | Table | Enrichment — UserName lookup | R.RealCID = C.RealCID |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|--------------|-----------|------|
| RealCID | etoroGeneral_History_GuruCopiers | ParentCID | Top 50 PIs by copy AUM selected in SP_Guru_Ratio_Populate; passed as @cid to SP_GuruRatio | T1 (Customer.CustomerStatic) |
| Ratio | V_Liabilities / etoroGeneral_History_GuruCopiers | RealizedEquity, Cash, Investment | Recursive traversal of copier tree: at each level, ratio = (ISNULL(Cash,0)+ISNULL(Investment,0)) / NULLIF(RealizedEquity,0) * parent_ratio; TotalSum = sum of all level ratios | T2 |
| UserName | Dim_Customer | UserName | Direct lookup via R.RealCID = C.RealCID in SP_Guru_Ratio_Populate post-INSERT UPDATE | T1 (Customer.CustomerStatic) |
| UpdateDate | — | — | GETDATE() at INSERT time inside SP_GuruRatio | T2 (SP_GuruRatio) |
