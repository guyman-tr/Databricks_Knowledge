# Lineage — Dealing_dbo.Dealing_Staking_Summary_US

## Writer
**SP_Staking_US** (`Dealing_dbo.SP_Staking_US`) — same SP as Position_US, Results_US, Club_US

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| StakingMonthID | Fivetran_google_sheets_platform_rewards.staking_month_id | Tier 4 | |
| StakingMonth | DATENAME(MONTH, staking_end_date) | Tier 2 | Month name |
| StakingYear | YEAR(staking_end_date) | Tier 2 | |
| InstrumentID | Fivetran_google_sheets_platform_rewards.instrument_id | Tier 4 | |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 4 | ADA, ETH, SOL |
| StakingStartDate | Fivetran_google_sheets_platform_rewards.staking_start_date | Tier 4 | |
| StakingEndDate | Fivetran_google_sheets_platform_rewards.staking_end_date | Tier 4 | |
| NetworkReportedRewards | Fivetran_google_sheets_platform_rewards.network_reported_rewards | Tier 4 | Total blockchain rewards for the period |
| RewardsToDistribute | Fivetran_google_sheets_platform_rewards.rewards_to_distribute | Tier 4 | Portion of network rewards eToro distributes |
| USD_ConversionRate | Fact_CurrencyPriceWithSplit.BidSpreaded at StakingEndDate | Tier 2 | Single point-in-time rate for USD columns |
| RewardsToDistribute_USD | RewardsToDistribute × USD_ConversionRate | Tier 2 | |
| ClientUnits | SUM(Client_Airdrop) over all CIDs | Tier 2 | Total crypto units to distribute to clients |
| EtoroUnits | SUM(Etoro_Amount) over all CIDs | Tier 2 | Total crypto units retained by eToro |
| ClientUSD | SUM(USD_Compensation) where IsEligible=1 | Tier 2 | Total USD value distributed to eligible clients |
| EtoroUSD | SUM(Etoro_Amount_USD) over all CIDs | Tier 2 | |
| ClientPercent | ClientUnits / (ClientUnits + EtoroUnits) | Tier 2 | Client share of total distributed rewards |
| EtoroPercent | EtoroUnits / (ClientUnits + EtoroUnits) | Tier 2 | eToro share |
| UtilizedUnits | SUM(Raw_Staking_Amount) | Tier 2 | Total allocated to CIDs (before RevShare split) |
| UnutilizedUnits | RewardsToDistribute − UtilizedUnits | Tier 2 | Rounding residual |
| UtilizedPercent | UtilizedUnits / RewardsToDistribute | Tier 2 | |
| UnutilizedPercent | 1 − UtilizedPercent | Tier 2 | |
| IneligibleCustomerRewards | SUM(Etoro_Amount) where IsEligible=0 | Tier 2 | Rewards that went to eToro because client was ineligible |
| RevShareCommission | SUM(Etoro_Amount) where IsEligible=1 | Tier 2 | eToro's RevShare portion from eligible clients (incl. cash-equivalent) |
| PercentUnutilized | UnutilizedUnits / EtoroUnits | Tier 2 | Fraction of eToro pool that was unused |
| PercentIneligible | IneligibleCustomerRewards / EtoroUnits | Tier 2 | Fraction of eToro pool from ineligible clients |
| PercentRevShare | RevShareCommission / EtoroUnits | Tier 2 | Fraction of eToro pool from eligible client RevShare |
| EtoroYield | RewardsToDistribute × TotalStakingDays / MonthlyPool | Tier 2 | Implied yield for the period |
| AnnualizedYield | (1 + RewardsToDistribute / MonthlyPool)^365 − 1 | Tier 2 | Annualized staking yield |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
| MonthlyPool | SUM(Units × Eligible_Staking_Days) over all CIDs | Tier 2 | Total weighted eligible units for the period (denominator for all pro-rata calcs) |
| IntroDays | Dealing_Staking_Parameters_US.IntroDays | Tier 4 | Minimum holding days before position qualifies |
