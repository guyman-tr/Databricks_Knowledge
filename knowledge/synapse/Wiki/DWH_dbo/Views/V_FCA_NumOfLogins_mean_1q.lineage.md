# Column Lineage — DWH_dbo.V_FCA_NumOfLogins_mean_1q

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| Date | System | `CAST(GETDATE() AS DATE)` — current date |
| RealCID | Fact_CustomerAction.RealCID | GROUP BY key |
| NumOfLogins_mean_1q | Fact_CustomerAction (COUNT) | `COUNT(*) / DATEDIFF(day, 3 months ago, today)` — filtered to ActionTypeID = 14, trailing 3 months |
