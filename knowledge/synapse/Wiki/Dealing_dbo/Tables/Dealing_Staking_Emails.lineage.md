# Column Lineage: Dealing_dbo.Dealing_Staking_Emails

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Staking_Emails` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `SP_Staking_Emails` (ETL-computed from staking daily pool data) |
| **ETL SP** | `SP_Staking_Emails`, `SP_Staking_Emails_US` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Dealing_Staking_DailyPool + Dealing_Staking_Parameters ─┐
DWH_dbo.Dim_Customer ──────────────────────────────────┼──► SP_Staking_Emails ──► Dealing_Staking_Emails
DWH_dbo.Dim_Country ───────────────────────────────────┘
```

## Column Lineage

| DWH Column | Transform | Notes |
|-----------|-----------|-------|
| StakingMonthID | ETL-computed | YYYYMM format |
| StakingYear | ETL-computed | Year portion |
| Country | join-enriched | From Dim_Country |
| StakingMonth | ETL-computed | Month name |
| GCID | passthrough | Global Customer ID |
| Language | join-enriched | Customer language preference |
| {Crypto}Units | ETL-computed | Monthly staking units per crypto |
| {Crypto}MPercentage | ETL-computed | Monthly yield percentage |
| {Crypto}CPercentage | ETL-computed | Club tier percentage |
| {Crypto}Reward | ETL-computed | Calculated reward amount |
| ClubTier | join-enriched | Customer club tier |
| Mailing_Group | ETL-computed | Email segment |
| UpdateDate | ETL-computed | `GETDATE()` |
