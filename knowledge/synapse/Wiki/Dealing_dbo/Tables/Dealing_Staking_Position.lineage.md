# Column Lineage: Dealing_dbo.Dealing_Staking_Position

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Staking_Position` |
| **UC Target** | `general.dealing_dbo.dealing_staking_position` |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` (eligible staking positions) |
| **ETL SP** | `Dealing_dbo.SP_Staking` |
| **Secondary Sources** | `Dealing_staging.Fivetran_google_sheets_platform_rewards` (staking parameters), `DWH_dbo.Dim_Customer` (eligibility attributes), `DWH_dbo.Dim_PlayerLevel` (PlayerLevel/RevShare), `Dealing_dbo.Dealing_Staking_Parameters` (IntroDays config) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
etoro platform (production PositionPnL data)
  → BI_DB_dbo.BI_DB_PositionPnL (daily position snapshot)
  + Dealing_staging.Fivetran_google_sheets_platform_rewards (Google Sheets staking config per month)
  + Dealing_dbo.Dealing_Staking_Parameters (IntroDays config per instrument)
  + DWH_dbo.Dim_Customer + Fact_SnapshotCustomer (eligibility: country, regulation, AML status)
  → SP_Staking #EligiblePool + #AllPositions + position-level eligibility checks
  → Dealing_dbo.Dealing_Staking_Position (1 row per position per staking month)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| StakingMonthID | Fivetran google_sheets | staking_month_id | passthrough | Direct: @StakingMonthID = LEFT(CAST(CONVERT(VARCHAR(8), DATEADD(MONTH,-1,@Date),112) AS INT),6) | ⚠️ Historical values 2025030 and 2024100 are malformed (7-digit) due to LEFT(7) bug in older SP versions — use StakingMonth+StakingYear for time filtering |
| StakingMonth | Fivetran google_sheets | staking_end_date | ETL-computed | `DATENAME(MONTH, staking_end_date)` | Month name (January–December) |
| StakingYear | Fivetran google_sheets | staking_end_date | ETL-computed | `YEAR(staking_end_date)` | Calendar year of the staking period |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | Direct: dc.RealCID | Client account ID |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough | Direct: dc.GCID | Group/household customer ID |
| InstrumentID | Fivetran google_sheets | instrument_id | passthrough | Direct: sp.InstrumentID (ADA/TRX/SOL/ETH/POL/NEAR/DOT/ATOM/SUI) | Staking-eligible crypto instrument |
| Currency | Fivetran google_sheets | currency | passthrough | Direct: sp.Currency | Crypto ticker (ADA, TRX, SOL, ETH, etc.) |
| PositionID | BI_DB_dbo.BI_DB_PositionPnL | PositionID | passthrough | Direct: p.PositionID | Position contributing to staking pool |
| Effective_OpenDate | BI_DB_dbo.BI_DB_PositionPnL | OpenDate | ETL-computed | MAX(staking_start_date - IntroDays, actual_open_date) | Adjusted open date to account for intro period grace days |
| Effective_CloseDate | BI_DB_dbo.BI_DB_PositionPnL | CloseDate | ETL-computed | MIN(staking_end_date, actual_close_date) | Adjusted close date capped at period end |
| Eligible_Staking_Days | Effective_OpenDate/CloseDate | — | ETL-computed | `DATEDIFF(DAY, Effective_OpenDate, Effective_CloseDate) + 1` | Days position was eligible within the staking period |
| Total_USD | BI_DB_dbo.BI_DB_PositionPnL | Units_Invested_USD | ETL-computed | `SUM(units_invested_USD)` per position over eligible days | USD value of the staked position |
| IsClientEligible | multiple eligibility checks | — | ETL-computed | AND of all eligibility flags (country, regulation, AML, account status, waiver, opted-in) | 1 = fully eligible for rewards; 0 = ineligible |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | LEFT JOIN Dim_PlayerLevel ON PlayerLevelID | Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond |
| RevShare | #RevShareBrackets | RevShare | ETL-computed | `CASE PlayerLevelID: 1→0.45, 5→0.55, 3→0.65, 2→0.75, 6→0.85, 7→0.90` | Client's share fraction of staking rewards (e.g., 0.75 = 75% to client) |
| Country | DWH_dbo.Dim_Customer | CountryID | join-enriched | Country name via Dim_Country lookup | Client country for eligibility determination |
| IsEligibleCountry | DWH_dbo.Dim_Customer | CountryID | ETL-computed | Country NOT IN (...large exclusion list...) → 1 else 0 | Whether country is eligible for staking rewards |
| IsCashEquivalentCountry | DWH_dbo.Dim_Customer | CountryID | ETL-computed | `CountryID IN (63,67,96,105,148,167,94) THEN 1 ELSE 0` | Cash compensation instead of crypto airdrop (e.g., Hungary=94) |
| IsEtorian | DWH_dbo.Dim_Customer | IsEtoro | ETL-computed | eToro employee flag | 1 = eToro internal employee (excluded from rewards) |
| UK_Prohibited | DWH_dbo.Dim_Customer | CountryID/RegulationID | ETL-computed | UK FCA prohibition flag per SR-262096 | 1 = FCA-prohibited from staking for certain coins |
| Regulation | DWH_dbo.Dim_Regulation | Name | join-enriched | LEFT JOIN Dim_Regulation ON RegulationID | Regulatory entity (EU, UK, AS, etc.) |
| IsRegulationEligible | DWH_dbo.Dim_Customer | RegulationID | ETL-computed | RegulationID NOT IN (6,7,8) (US excluded) → 1 else 0 | Non-US regulations only |
| PlayerStatus | DWH_dbo.Dim_Customer | — | ETL-computed | Account status at staking run time | Active/Inactive/Closed |
| IsAML_Restricted | DWH_dbo.Dim_Customer | — | ETL-computed | AML restriction flag | 1 = AML-blocked client |
| IsAccountStatusEligible | DWH_dbo.Dim_Customer | — | ETL-computed | Active account status check | 1 = eligible account status |
| IsWaiver | Dealing_dbo.Dealing_Staking_OptedOut / OptedOut_PerCID | — | ETL-computed | Position-level opt-in/opt-out status from waiver calendar (#Waiver_All_Daily/#Waiver_ETH_Daily) | 1 = client opted out for this position |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |
| IsPI | DWH_dbo.Dim_Customer | GuruStatusID | ETL-computed | `CASE WHEN GuruStatusID IN (5,6) THEN 1 ELSE 0 END` | 1 = Popular Investor |
| IsOptedIn_ETH | #Waiver_ETH_Daily | IsOptedIn_ETH | ETL-computed | ETH-specific opt-in flag (ETH is opt-in by default OFF, all other coins default ON) | 1 = client opted into ETH staking |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Join-enriched** | 3 |
| **ETL-computed** | 18 |
| **ETL metadata** | 1 |
| **Total** | 31 |
