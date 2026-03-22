# Column Lineage: Dealing_dbo.Dealing_Staking_Results

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Staking_Results` |
| **UC Target** | `general.dealing_dbo.dealing_staking_results` |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` + `Dealing_staging.Fivetran_google_sheets_platform_rewards` |
| **ETL SP** | `Dealing_dbo.SP_Staking` |
| **Secondary Sources** | `Dealing_dbo.Dealing_Staking_Position` (pre-computed eligibility), `DWH_dbo.Dim_CustomerStakingAirdrop` (airdrop execution results), `Dealing_dbo.Dealing_Staking_Club` (club category) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Dealing_Staking_Position (eligibility per position)
  + Fivetran google_sheets (rewards config, RevShare)
  + DWH_dbo airdrop execution tables (IsAirdropSuccess, ActualAirdropUnits)
  → SP_Staking result computation (#Results)
  → Dealing_dbo.Dealing_Staking_Results (1 row per CID per instrument per staking month)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| StakingMonthID | Fivetran google_sheets | staking_month_id | passthrough | @StakingMonthID | ⚠️ Malformed 2025100 (should be 202510) from historical SP bug |
| StakingMonth | Fivetran google_sheets | staking_end_date | ETL-computed | `DATENAME(MONTH, staking_end_date)` | Month name |
| StakingYear | Fivetran google_sheets | staking_end_date | ETL-computed | `YEAR(staking_end_date)` | Calendar year |
| InstrumentID | Fivetran google_sheets | instrument_id | passthrough | Direct: sp.InstrumentID | Crypto instrument |
| Currency | Fivetran google_sheets | currency | passthrough | Direct: sp.Currency | Crypto ticker |
| CID | Dealing_Staking_Position | CID | passthrough | Direct: from eligible pool | Client ID |
| GCID | Dealing_Staking_Position | GCID | passthrough | Direct: from eligible pool | Group customer ID |
| IsEligible | Dealing_Staking_Position | IsClientEligible | ETL-computed | 1 = meets all eligibility criteria | Consolidated eligibility flag |
| NonEligible_PrimaryReason | multiple | — | ETL-computed | First failing eligibility check: country, regulation, AML, account status, opt-out, etc. | NULL when IsEligible=1 |
| Raw_Staking_Amount | Dealing_Staking_Position | Total_USD * Eligible_Staking_Days | ETL-computed | `SUM(Total_USD × Eligible_Staking_Days / TotalStakingDays)` for eligible positions | Client's proportional share of the total staked pool |
| RevShare | Dealing_Staking_Position | RevShare | passthrough | Direct: client's PlayerLevel RevShare bracket (0.45–0.90) | Revenue share percentage for this client |
| Client_Airdrop | Raw_Staking_Amount + RevShare | — | ETL-computed | `Raw_Staking_Amount / SUM(ALL Raw_Staking_Amount) × RewardsToDistribute × RevShare` | Crypto units allocated to the client |
| Etoro_Amount | Raw_Staking_Amount + RevShare | — | ETL-computed | `Raw_Staking_Amount / SUM(ALL) × RewardsToDistribute × (1 - RevShare)` | Crypto units retained by eToro |
| OriginalCompensationType | country/regulation check | — | ETL-computed | 'Crypto' vs 'Cash' based on IsCashEquivalentCountry | Hungary = Cash; others = Crypto |
| USD_Compensation | Client_Airdrop + conversion rate | — | ETL-computed | `Client_Airdrop × USD_ConversionRate (at staking_end_date)` | USD equivalent of rewards |
| Etoro_Amount_USD | Etoro_Amount + conversion rate | — | ETL-computed | `Etoro_Amount × USD_ConversionRate` | eToro's USD equivalent of retained rewards |
| AirdropID | DWH airdrop execution | AirdropID | passthrough | From airdrop execution table post-distribution | Airdrop transaction identifier (NULL before distribution) |
| AirdropOccurred | DWH airdrop execution | AirdropOccurred | passthrough | Actual distribution date | NULL before the airdrop runs |
| IsAirdropSuccess | DWH airdrop execution | — | ETL-computed | 1 = airdrop delivered; 0 = failed; NULL = not yet run | Airdrop delivery status |
| FailReasonID | DWH airdrop execution | — | ETL-computed | Reason code when IsAirdropSuccess=0 | NULL when successful |
| ActualAirdropUnits | DWH airdrop execution | — | ETL-computed | Actual units transferred (may differ from Client_Airdrop due to rounding) | Post-execution actual value |
| ActualCompensationType | DWH airdrop execution | — | ETL-computed | Actual delivery method (may differ from OriginalCompensationType if override) | Final compensation type |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |
| ClubCategory | Dealing_Staking_Club | ClubCategory | join-enriched | Client's club tier (Silver/Gold/Platinum/Diamond & Platinum Plus) per ≤40 USD holdings threshold | Club tier for reduced commission eligibility |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Join-enriched** | 1 |
| **ETL-computed** | 16 |
| **ETL metadata** | 1 |
| **Total** | 26 |
