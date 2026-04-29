# BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | BI_DB_dbo | Life stage (LSD) valid at end of month | @endofmonthINT BETWEEN DateID AND ToDateID |
| 2 | BI_DB_dbo.BI_DB_CID_DailyCluster | BI_DB_dbo | Cluster classification valid at end of month | @endofmonthINT BETWEEN FromDateID AND ToDateID |
| 3 | DWH_dbo.Dim_Customer | DWH_dbo | Customer-to-country mapping | RealCID join |
| 4 | DWH_dbo.Dim_Country | DWH_dbo | Country name and desk | CountryID join |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | DateID | Parameter | @endofmonthINT | EOMONTH(previous month) as INT |
| 2 | Date | Parameter | @endofmonth | EOMONTH(previous month) as date string |
| 3 | RealCID | BI_DB_CID_LifeStageDefinition | RealCID | Passthrough |
| 4 | LSD | BI_DB_CID_LifeStageDefinition | LSD | Passthrough — active at month-end |
| 5 | Classification | BI_DB_CID_DailyCluster | ClusterSF | Passthrough — active at month-end |
| 6 | ClusterDetail | BI_DB_CID_DailyCluster | ClusterDetail | Passthrough — active at month-end |
| 7 | Desk | Dim_Country | Desk | Dim-lookup via Dim_Customer.CountryID |
| 8 | Country | Dim_Country | Name | Dim-lookup via Dim_Customer.CountryID |
| 9 | UpdateDate | ETL | GETDATE() | Metadata |
