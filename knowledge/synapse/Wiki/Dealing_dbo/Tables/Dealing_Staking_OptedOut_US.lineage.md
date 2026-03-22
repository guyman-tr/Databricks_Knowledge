# Lineage — Dealing_dbo.Dealing_Staking_OptedOut_US

## Writer
**SP_Staking_DailyPool_US** (`Dealing_dbo.SP_Staking_DailyPool_US`) — daily aggregate; same SP as OptedOut_PerCID_US and DailyPool_US

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| Date | SP parameter | Tier 2 | |
| InstrumentID / Currency | Dealing_Staking_Parameters_US | Tier 4 | |
| LiquidityBuffer | Dealing_Staking_Parameters_US.LiquidityBuffer | Tier 4 | Fraction of opted-in units available for staking |
| USD_Rate | Fact_CurrencyPriceWithSplit.BidSpreaded | Tier 2 | Daily spot |
| Regulation | Dim_Regulation.Name | Tier 1 | Always FinCEN+FINRA in this table |
| EligibleClients | COUNT(eligible CIDs) | Tier 2 | Eligible FinCEN+FINRA verified clients |
| EligibleUnits | SUM(BI_DB_PositionPnL.AmountInUnitsDecimal) | Tier 2 | All eligible open positions |
| EligibleValue | EligibleUnits × USD_Rate | Tier 2 | |
| OptedInClients | COUNT where IsOptedIn=1 | Tier 2 | |
| OptedInUnits | SUM units where IsOptedIn=1 | Tier 2 | |
| OptedInValue | OptedInUnits × USD_Rate | Tier 2 | |
| OptedOutClients | COUNT where IsOptedIn=0 | Tier 2 | |
| OptedOutUnits | SUM units where IsOptedIn=0 | Tier 2 | |
| OptedOutValue | OptedOutUnits × USD_Rate | Tier 2 | |
| Units_AvailableForStaking | OptedInUnits × LiquidityBuffer | Tier 2 | Units actually available after liquidity buffer |
| Value_AvailableForStaking | Units_AvailableForStaking × USD_Rate | Tier 2 | |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
