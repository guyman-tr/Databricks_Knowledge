# Column Lineage: DWH_dbo.Dim_SocialNetwork

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_SocialNetwork` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork` |
| **Primary Source** | Unknown (legacy migration; likely etoro.Dictionary.SocialNetwork) |
| **ETL SP** | None active in SSDT repo |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Unknown source (legacy etoro.Dictionary.SocialNetwork - unconfirmed)
  -> One-time migration (2013-2014 - frozen)
  -> DWH_dbo.Dim_SocialNetwork (4 rows, static)
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **unknown** | Source column unknown - frozen legacy migration; no active ETL SP found. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| SocialNetworkID | Unknown (legacy) | Unknown | unknown | PK. 0=N/A, 1=Facebook, 2=Twitter, 3=LinkedIn. Frozen 2013-2014. |
| Name | Unknown (legacy) | Unknown | unknown | Social platform name. Frozen. |
| DWHSocialNetworkID | Unknown (legacy) | Unknown | unknown | Likely alias of SocialNetworkID. Frozen. |
| StatusID | Unknown (legacy) | Unknown | unknown | Value 1 for all rows. Frozen. |
| UpdateDate | Unknown (legacy) | Unknown | unknown | 2013-2014 timestamps. Not getdate(). Frozen. |
| InsertDate | Unknown (legacy) | Unknown | unknown | 2013-2014 timestamps. Frozen. |

## Note on Frozen Status

Dim_SocialNetwork is NOT refreshed by SP_Dictionaries_DL_To_Synapse or any other SP found in the DWH_dbo SSDT repo. The table contains 4 rows with UpdateDate/InsertDate from 2013-2014, indicating a one-time legacy migration. ETL lineage cannot be confirmed from current SSDT artifacts.

## Summary

| Category | Count |
|----------|-------|
| **Unknown (frozen)** | 6 |
| **Total** | 6 |
