# Lineage — Dealing_dbo.Dealing_Staking_Results_US

## Writer
**SP_Staking_US** (`Dealing_dbo.SP_Staking_US`) — same SP as Position_US, Summary_US, Club_US

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| StakingMonthID | Fivetran_google_sheets_platform_rewards.staking_month_id | Tier 4 | |
| StakingMonth | DATENAME(MONTH, staking_end_date) | Tier 2 | Month name |
| StakingYear | YEAR(staking_end_date) | Tier 2 | |
| InstrumentID | Fivetran_google_sheets_platform_rewards.instrument_id | Tier 4 | ADA/ETH/SOL |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 4 | ADA, ETH, SOL |
| CID | Dim_Position / BI_DB_PositionPnL | Tier 1 | |
| GCID | Dim_Customer.GCID | Tier 2 | Global CID |
| IsEligible | IsClientEligible × IsPositionEligible | Tier 2 | Combined client+position eligibility |
| NonEligible_PrimaryReason | Client-level: Country/Etorian/AML/AccountStatus; Position-level: Less than $1/Waiver | Tier 2 | First-matched exclusion reason |
| Raw_Staking_Amount | (Units×Days) × RewardsToDistribute / SUM(all Units×Days) | Tier 2 | CID's pro-rata share before RevShare split |
| RevShare | Brackets: B=0.45, S=0.55, G=0.65, P=0.75, PP=0.85, D=0.90 | Tier 2 | |
| Client_Airdrop | Raw_Staking_Amount × RevShare (0 if ineligible) | Tier 2 | Crypto units to airdrop to client |
| Etoro_Amount | Raw_Staking_Amount × (1−RevShare) if eligible; Raw_Staking_Amount if ineligible | Tier 2 | eToro's share of staking rewards |
| OriginalCompensationType | 'None' if ineligible; 'Cash' if IsCashEquivalentCountry=1; 'Airdrop' otherwise | Tier 2 | Intended compensation form at calculation time |
| USD_Compensation | Client_Airdrop × USD_Value from Fact_CurrencyPriceWithSplit at StakingEndDate | Tier 2 | USD value of client airdrop |
| Etoro_Amount_USD | Etoro_Amount × USD_Value | Tier 2 | |
| AirdropID | NULL initially | Tier 2 | Updated post-execution when airdrop is processed |
| AirdropOccurred | NULL (always in SP insert) | Tier 2 | Not set during calculation run |
| IsAirdropSuccess | NULL initially | Tier 2 | Updated post-execution |
| FailReasonID | NULL initially | Tier 2 | Updated if airdrop fails |
| ActualAirdropUnits | NULL initially | Tier 2 | Updated post-execution |
| ActualCompensationType | 'None' if ineligible; 'Cash' if CashEquivalent; '' otherwise | Tier 2 | Actual form used after execution |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
| ClubCategory | Bronze / Silver+Gold+Platinum / Diamond+Platinum Plus | Tier 2 | Tier grouping for $1 minimum threshold calculation |
