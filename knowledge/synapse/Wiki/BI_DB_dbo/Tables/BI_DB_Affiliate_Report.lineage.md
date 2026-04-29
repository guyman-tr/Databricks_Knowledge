# BI_DB_dbo.BI_DB_Affiliate_Report — Column Lineage

## Source Objects

| Source Table | Source Type | Relationship |
|---|---|---|
| Unknown (no writer SP in SSDT, no references) | — | Table is dormant with 0 rows. Likely legacy on-prem BI_DB migration artifact. |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Month | Unknown | — | Monthly period (varchar(7), e.g., '2023-08') |
| MonthID | Unknown | — | Integer month key (YYYYMM format) |
| Region | Unknown | — | Affiliate operating region |
| AffiliateID | Unknown | — | Affiliate partner ID (fiktivo system) |
| AffiliatesGroupsName | Unknown | — | Affiliate group/tier name |
| Channel | Unknown | — | Marketing channel |
| SubChannel | Unknown | — | Marketing sub-channel |
| Contact | Unknown | — | Affiliate manager contact |
| ContractName | Unknown | — | Contract arrangement name |
| Registrations | Unknown | — | Registration count for the period |
| FTDs | Unknown | — | First-time deposit count |
| FTDEs | Unknown | — | First-time deposit equivalent count |
| ActiveTraders | Unknown | — | Active trader count |
| VerificationLevel2 | Unknown | — | KYC Level 2 completed count |
| VerificationLevel3 | Unknown | — | KYC Level 3 completed count |
| FTD Amount | Unknown | — | Total first-time deposit monetary value |
| Deposit Amount | Unknown | — | Total deposit monetary value |
| Cashout Amount | Unknown | — | Total cashout/withdrawal monetary value |
| Depositing Users | Unknown | — | Distinct users who deposited |
| Cashout Users | Unknown | — | Distinct users who cashed out |
| Full Commission | Unknown | — | Total affiliate commission paid |
| Rollover Fees | Unknown | — | Rollover/overnight position fees |
| Cost | Unknown | — | Marketing cost |
| Invested | Unknown | — | Total invested amount by affiliate's customers |
| Equity | Unknown | — | Total equity of affiliate's customers |
| LTV | Unknown | — | Lifetime value metric |
| UpdateDate | Unknown | — | ETL metadata timestamp |
