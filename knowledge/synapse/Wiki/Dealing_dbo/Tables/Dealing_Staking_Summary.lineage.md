# Column Lineage: Dealing_dbo.Dealing_Staking_Summary

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Staking_Summary` |
| **UC Target** | `general.dealing_dbo.dealing_staking_summary` |
| **Primary Source** | `Dealing_staging.Fivetran_google_sheets_platform_rewards` + `Dealing_dbo.Dealing_Staking_Results` (aggregated) |
| **ETL SP** | `Dealing_dbo.SP_Staking` |
| **Secondary Sources** | `DWH_dbo.Fact_CurrencyPriceWithSplit` (USD conversion rate at staking end date) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Fivetran google_sheets (NetworkReportedRewards, RewardsToDistribute, dates)
  + Dealing_Staking_Results (aggregated Client/Etoro distribution)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (USD_ConversionRate at staking_end_date)
  → SP_Staking #Summary aggregation
  → Dealing_dbo.Dealing_Staking_Summary (1 row per instrument per staking month — 9 instruments × ~N months = 158 rows total)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| StakingMonthID | Fivetran google_sheets | staking_month_id | passthrough | @StakingMonthID | ⚠️ Malformed 2025030 — use StakingMonth+StakingYear for ordering |
| StakingMonth | Fivetran google_sheets | staking_end_date | ETL-computed | `DATENAME(MONTH, staking_end_date)` | Month name |
| StakingYear | Fivetran google_sheets | staking_end_date | ETL-computed | `YEAR(staking_end_date)` | Calendar year |
| InstrumentID | Fivetran google_sheets | instrument_id | passthrough | Direct: sp.InstrumentID | Crypto instrument |
| Currency | Fivetran google_sheets | currency | passthrough | Direct: sp.Currency | Crypto ticker |
| StakingStartDate | Fivetran google_sheets | staking_start_date | passthrough | Direct: sp.StakingStartDate | Official start of the staking measurement period |
| StakingEndDate | Fivetran google_sheets | staking_end_date | passthrough | Direct: sp.StakingEndDate | Official end of the staking measurement period |
| NetworkReportedRewards | Fivetran google_sheets | network_reported_rewards | passthrough | Direct: network_reported_rewards | Total rewards reported by the blockchain network (before any adjustments) |
| RewardsToDistribute | Fivetran google_sheets | rewards_to_distribute | passthrough | Direct: rewards_to_distribute | Actual rewards to distribute (may include bonus buffer from prior months) |
| USD_ConversionRate | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded | passthrough | BidSpreaded at OccurredDateID = staking_end_date | Crypto/USD rate at period end for USD conversion |
| RewardsToDistribute_USD | RewardsToDistribute + USD_ConversionRate | — | ETL-computed | `RewardsToDistribute × USD_ConversionRate` | USD value of total rewards distributed |
| ClientUnits | Dealing_Staking_Results | Client_Airdrop | ETL-computed | `SUM(Client_Airdrop)` for all eligible clients | Total crypto units distributed to all clients |
| EtoroUnits | Dealing_Staking_Results | Etoro_Amount | ETL-computed | `SUM(Etoro_Amount)` | Total crypto units retained by eToro |
| ClientUSD | ClientUnits + USD_ConversionRate | — | ETL-computed | `ClientUnits × USD_ConversionRate` | USD value of client distributions |
| EtoroUSD | EtoroUnits + USD_ConversionRate | — | ETL-computed | `EtoroUnits × USD_ConversionRate` | USD value of eToro's share |
| ClientPercent | ClientUnits / RewardsToDistribute | — | ETL-computed | `ClientUnits / RewardsToDistribute` | Fraction of total rewards going to clients |
| EtoroPercent | EtoroUnits / RewardsToDistribute | — | ETL-computed | `EtoroUnits / RewardsToDistribute` | Fraction retained by eToro |
| UtilizedUnits | Dealing_Staking_Position | Total_USD | ETL-computed | `SUM(Total_USD)` for eligible + opted-in positions | Crypto units from positions that qualified for staking |
| UnutilizedUnits | OptedOut pool | — | ETL-computed | `MonthlyPool - UtilizedUnits` | Crypto units from opted-out or ineligible positions |
| UtilizedPercent | UtilizedUnits / MonthlyPool | — | ETL-computed | `UtilizedUnits / MonthlyPool` | Pool utilization rate |
| UnutilizedPercent | UnutilizedUnits / MonthlyPool | — | ETL-computed | `UnutilizedUnits / MonthlyPool` | Fraction of pool not utilized |
| IneligibleCustomerRewards | — | — | ETL-computed | Rewards that would have gone to ineligible clients | Redistributed to eToro |
| RevShareCommission | Dealing_Staking_Results | Etoro_Amount | ETL-computed | `SUM(Etoro_Amount)` — eToro's RevShare portion specifically | eToro's commission from the revenue share model |
| PercentUnutilized | UnutilizedUnits / MonthlyPool | — | ETL-computed | Duplicate of UnutilizedPercent (historical column) | May be redundant with UnutilizedPercent |
| PercentIneligible | IneligibleCustomerRewards / RewardsToDistribute | — | ETL-computed | Fraction of rewards lost to ineligibility | Quality metric for population eligibility |
| PercentRevShare | RevShareCommission / ClientUnits | — | ETL-computed | Weighted average RevShare across all clients | Blended revenue share rate |
| EtoroYield | EtoroUSD / MonthlyPool_USD | — | ETL-computed | eToro's yield as fraction of total pool value | eToro profitability metric |
| AnnualizedYield | EtoroYield | — | ETL-computed | `EtoroYield × (365 / TotalStakingDays)` | Annualized yield for benchmark comparison |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |
| MonthlyPool | Dealing_Staking_Position | Total_USD | ETL-computed | `SUM(Total_USD)` for ALL positions (eligible+ineligible), denominator for yield calculations | Total USD value of all staked positions this month |
| IntroDays | Dealing_Staking_Parameters | IntroDays | passthrough | Direct: p.IntroDays per instrument | Grace period days before staking period start (positions opened within IntroDays before start still qualify) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 8 |
| **ETL-computed** | 24 |
| **ETL metadata** | 1 |
| **Total** | 34 |
