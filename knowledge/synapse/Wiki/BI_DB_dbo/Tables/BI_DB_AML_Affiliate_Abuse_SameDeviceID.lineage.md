# Lineage: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID

## Object
- **Schema**: BI_DB_dbo
- **Object**: BI_DB_AML_Affiliate_Abuse_SameDeviceID
- **Type**: Table
- **Writer SP**: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)
- **UC Target**: Not_Migrated

## ETL Pipeline
```
DWH_dbo.Dim_Customer + DWH_dbo.Dim_Affiliate (SubChannelID filter)
  |-- SP Step 03: #cidlevel (CIDs for activated affiliates, registered>=2023) ---|
  v
DWH_dbo.STS_User_Operations_Data_History + DWH_dbo.Fact_BillingDeposit (SessionID join)
  |-- SP Step 09: #DeviceID (device sharing, HAVING COUNT(RealCid)>1) ---|
  v
TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID (74 rows, frozen 2024-12-31)
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| AffiliateID | Dim_Customer → Dim_Affiliate | AffiliateID | passthrough |
| NumOfClientsSameDeviceID | STS_User_Operations_Data_History | RealCid | COUNT DISTINCT per DeviceId, HAVING >1 |
| ClientDeviceId | STS_User_Operations_Data_History | ClientDeviceId | passthrough; excludes '00000000-0000-0000-0000-000000000000' |
| UpdateDate | ETL metadata | — | GETDATE() |

## Source Objects
- `DWH_dbo.Dim_Customer` — customer-affiliate join (AffiliateID linkage)
- `DWH_dbo.Dim_Affiliate` — SubChannelID filter (20,31,39,40,41,42,44)
- `DWH_dbo.STS_User_Operations_Data_History` — device ID sessions (DateID>=20220101, SessionId≠0)
- `DWH_dbo.Fact_BillingDeposit` — session-to-deposit linkage (PaymentStatusID=2 approved deposits only)
