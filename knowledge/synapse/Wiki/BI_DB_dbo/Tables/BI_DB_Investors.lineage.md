# BI_DB_dbo.BI_DB_Investors — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_Investors_STG | BI_DB Staging | Pre-aggregated investor activity (Manual/Copy/Balance) |
| BI_DB_dbo.BI_DB_CID_DailyCluster | BI_DB Table | Salesforce cluster assignment per CID per date |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Date | BI_DB_Investors_STG | Date | Passthrough |
| DateID | BI_DB_Investors_STG | DateID | Passthrough |
| AccountManagerID | BI_DB_Investors_STG | AccountManagerID | Passthrough |
| CountryID | BI_DB_Investors_STG | CountryID | Passthrough |
| RegulationID | BI_DB_Investors_STG | RegulationID | Passthrough |
| ActionType | BI_DB_Investors_STG | ActionType | Passthrough (Manual/Copy/Balance) |
| InstrumentType | BI_DB_Investors_STG | InstrumentType | Passthrough |
| AssetType | BI_DB_Investors_STG | AssetType | Passthrough (Investment/Trade) |
| Customers | BI_DB_Investors_STG | CID | COUNT(DISTINCT CID) for Manual/Copy, COUNT(CID) for Balance |
| Amount | BI_DB_Investors_STG | NetMI | SUM(NetMI) — net money invested |
| AUM_AUA | BI_DB_Investors_STG | AUA/AUM | SUM(AUA) or SUM(AUM) depending on source stream |
| UpdateDate | — | — | GETDATE() |
| ClusterSF | BI_DB_CID_DailyCluster | ClusterSF | LEFT JOIN on CID with date range |

## Pipeline

```
BI_DB_dbo.BI_DB_Investors_STG (pre-aggregated: Manual/Copy/Balance source streams)
  + BI_DB_dbo.BI_DB_CID_DailyCluster (Salesforce cluster per CID, date-ranged SCD)
    |-- SP_InvestorReport_Cluster @dd (daily, delete-insert by DateID) --|
    |   3 source streams: Manual, Copy, Balance                          |
    |   Each: GROUP BY Date/AM/Country/Regulation/Action/Asset/Cluster   |
    |   UNION all 3 streams                                              |
    v
BI_DB_dbo.BI_DB_Investors (132.9M rows, daily)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
