# Lineage — Dealing_dbo.Dealing_Staking_OptedOut_PerCID_US

## Writer
**SP_Staking_DailyPool_US** (`Dealing_dbo.SP_Staking_DailyPool_US`) — daily, also writes Dealing_Staking_OptedOut_US and Dealing_Staking_DailyPool_US

## Upstream Sources

| Source | Schema | Usage |
|---|---|---|
| Dealing_Staking_Parameters_US | Dealing_dbo | LiquidityBuffer, InstrumentID/Currency list, DailyPool_StartDate filter |
| Dim_Customer | DWH_dbo | CID→GCID mapping, CountryID |
| Fact_SnapshotCustomer | DWH_dbo | RegulationID, VerificationLevelID |
| Dim_State_and_Province | DWH_dbo | State name and ShortName (non-eligible state filter) |
| BI_DB_PositionPnL | BI_DB_dbo | Open settled positions (IsSettled=1, MirrorID=0) — eligible units |
| External_USABroker_Apex_UserProgramEnrolment | BI_DB_dbo | Opt-in/out events |
| External_USABroker_History_UserProgramEnrolment | BI_DB_dbo | Historical opt-in/out events |
| Fact_CurrencyPriceWithSplit | DWH_dbo | USD rate for the day |

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| Date | SP parameter @Date | Tier 2 | Reporting date |
| CID | Dim_Customer.RealCID | Tier 1 | |
| GCID | Dim_Customer.GCID | Tier 2 | Global CID |
| InstrumentID | Dealing_Staking_Parameters_US.InstrumentID | Tier 4 | |
| Currency | Dealing_Staking_Parameters_US.Currency | Tier 4 | ADA/ETH/SOL/SUI |
| USD_Rate | Fact_CurrencyPriceWithSplit.BidSpreaded | Tier 2 | Daily spot rate |
| Regulation | Dim_Regulation.Name | Tier 1 | FinCEN+FINRA |
| EligibleUnits | BI_DB_PositionPnL.AmountInUnitsDecimal sum | Tier 2 | Open settled non-copy positions |
| EligibleValue | EligibleUnits × USD_Rate | Tier 2 | USD value of holdings |
| IsOptedIn | Computed from Apex enrollment tables | Tier 2 | 1 = opted in for @Date |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
| Country | Dim_State_and_Province.Name | Tier 1 | US state name (field is named Country for historical reasons) |
