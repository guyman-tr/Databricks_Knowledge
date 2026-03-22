# Lineage — Dealing_dbo.Dealing_Staking_Position_US

## Writer
**SP_Staking_US** (`Dealing_dbo.SP_Staking_US`) — event-driven, triggered when Fivetran updates `Dealing_staging.Fivetran_google_sheets_platform_rewards` with `is_us=1` records for the month. SR-325088 (created 2025-08-01).

Also writes: Dealing_Staking_Results_US, Dealing_Staking_Summary_US, Dealing_Staking_Club_US

## Upstream Sources

| Source Table | Schema | Usage |
|---|---|---|
| Fivetran_google_sheets_platform_rewards | Dealing_staging | Monthly reward parameters (network rewards, distribution, staking period, is_us=1 filter) |
| Dealing_Staking_Parameters_US | Dealing_dbo | US-specific staking config: InstrumentID, Distribution_StartDate, IntroDays |
| BI_DB_PositionPnL | BI_DB_dbo | Open positions on @Date (IsSettled=1, MirrorID=0) |
| Dim_Position | DWH_dbo | Closed positions in staking period (IsSettled=1, MirrorID=0) |
| Dim_Customer | DWH_dbo | CID→GCID mapping, IsValidCustomer filter |
| Fact_SnapshotCustomer | DWH_dbo | RegulationID (filter = 8 FinCEN+FINRA), PlayerLevelID, CountryID, AccountStatusID |
| Dim_PlayerLevel | DWH_dbo | PlayerLevel name lookup |
| Dim_Country | DWH_dbo | Country name |
| Dim_State_and_Province | DWH_dbo | State/region (for excluded-states logic: Nevada, Hawaii) |
| Dim_Regulation | DWH_dbo | Regulation name (FinCEN, FinCEN+FINRA) |
| Dim_PlayerStatus / Dim_PlayerStatusSubReasons | DWH_dbo | AML restriction check (PlayerStatusID IN (2,9,15,4) OR SubReasonID IN (25,33,31,32,26,30,51)) |
| External_USABroker_Apex_UserProgramEnrolment | BI_DB_dbo | US staking opt-in/out events (live Apex feed) |
| External_USABroker_History_UserProgramEnrolment | BI_DB_dbo | US staking opt-in/out history |
| Fact_CurrencyPriceWithSplit | DWH_dbo | USD conversion rate at StakingEndDate |

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| StakingMonthID | Fivetran_google_sheets_platform_rewards.staking_month_id | Tier 4 | LEFT(6) of prior month YYYYMMDD |
| StakingMonth | Fivetran_google_sheets_platform_rewards.staking_end_date → DATENAME(MONTH) | Tier 2 | Month name string |
| StakingYear | Fivetran_google_sheets_platform_rewards.staking_end_date → YEAR() | Tier 2 | Year integer |
| CID | Dim_Position / BI_DB_PositionPnL | Tier 1 | Customer ID |
| GCID | Dim_Customer.GCID | Tier 2 | Global customer ID (across accounts); joined from CID |
| InstrumentID | Dim_Position.InstrumentID | Tier 1 | |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 4 | ADA, ETH, SOL |
| PositionID | Dim_Position / BI_DB_PositionPnL | Tier 1 | |
| Effective_OpenDate | GREATEST(OpenDate+IntroDays+1, FirstTimeIn+IntroDays+1, StakingStartDate) | Tier 2 | Latest of: after intro period, after opt-in, after staking start |
| Effective_CloseDate | LEAST(CloseOccurred/NULL, LastTimeIn, StakingEndDate) | Tier 2 | Earliest of: position close, opt-out date, staking period end |
| Eligible_Staking_Days | DATEDIFF(Effective_CloseDate, Effective_OpenDate) + 1 | Tier 2 | Days contributing to rewards; must be > 0 to appear |
| Total_USD | USD_Compensation from CID-level calc | Tier 2 | CID's total USD-denominated staking amount |
| IsClientEligible | Computed eligibility flags | Tier 2 | 0 if: ineligible country, Etorian, AML-restricted, suspended account |
| PlayerLevel | Dim_PlayerLevel.Name | Tier 1 | Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond |
| RevShare | Hardcoded brackets: B=0.45, S=0.55, G=0.65, P=0.75, PP=0.85, D=0.90 | Tier 2 | Client's share of staking rewards |
| Country | Dim_Country.CountryName | Tier 1 | |
| IsEligibleCountry | Computed | Tier 2 | 0 for excluded states: Nevada, Hawaii (Alabama removed SR-339857) |
| IsCashEquivalentCountry | Dim_Country metadata | Tier 2 | Countries receiving USD credit instead of crypto airdrop |
| IsEtorian | CountryID=250 → 1 | Tier 2 | eToro employees excluded |
| UK_Prohibited | Hardcoded 0 | Tier 2 | Legacy field from global version; always 0 for US |
| Regulation | Dim_Regulation.Name | Tier 1 | FinCEN or FinCEN+FINRA |
| IsRegulationEligible | RegulationID=8 (FinCEN+FINRA) | Tier 2 | Only FinCEN+FINRA (FINRA-registered) US clients are eligible |
| PlayerStatus | Dim_PlayerStatus.Name | Tier 1 | |
| IsAML_Restricted | PlayerStatusID IN (2,9,15,4) OR SubReasonID IN (25,33,31,32,26,30,51) | Tier 2 | AML/fraud restricted |
| IsAccountStatusEligible | AccountStatusID <> 2 | Tier 2 | 0 = suspended/closed account |
| IsWaiver | NonEligiblePosition_PrimaryReason = 'Waiver' | Tier 2 | Opted out before staking period end |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
| IsPI | NULL (always) | Tier 2 | Reserved field, not populated by SP |
| IsOptedIn_ETH | NULL (always) | Tier 2 | Reserved field, not populated by SP; ETH opt-in status is used internally but not stored here |
