# Lineage — Dealing_dbo.Dealing_Staking_OptedOut

**Writer SP**: `Dealing_dbo.SP_Staking_DailyPool` (daily, SB_Daily pipeline — co-written with Dealing_Staking_DailyPool)
**Write pattern**: DELETE WHERE Date = @Date, then INSERT from #OptedOut_Final JOIN #Staking_Parameters

## Source Chain

```
BI_DB_dbo.BI_DB_PositionPnL (AmountInUnitsDecimal, InstrumentID)
+ DWH_dbo.Dim_Customer (GCID, RegulationID → Regulation name)
+ opt-in/out waiver tables (Dealing_staging.Fivetran_google_sheets_*)
+ Dealing_dbo.Dealing_Staking_Parameters (LiquidityBuffer, IntroDays)
+ USD rate (likely from external tables or staging)
→ #OptedOut_PerCID (per-client breakdown)
→ #OptedOut_Final (aggregated by InstrumentID, Currency, Regulation)
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| Date | @Date SP parameter | Tier 3 | Daily snapshot date |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL.InstrumentID | Tier 3 | FK to Dim_Instrument |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 3 | Crypto ticker |
| LiquidityBuffer | Dealing_Staking_Parameters.LiquidityBuffer | Tier 3 | From #Staking_Parameters |
| USD_Rate | External rate source (exchange rate at snapshot time) | Tier 3 | USD/crypto conversion rate |
| Regulation | DWH_dbo.Dim_Customer regulation name | Tier 1 — DWH_dbo | e.g., "FCA", "CySEC", "FSA Seychelles" |
| EligibleClients | COUNT(DISTINCT GCID) eligible for staking | Tier 3 | Clients past intro period, eligible regulation |
| EligibleUnits | SUM(EligibleUnits) from #OptedOut_PerCID | Tier 3 | Total units eligible regardless of opt-in |
| EligibleValue | SUM(EligibleUnits * USD_Rate) | Tier 3 | USD value of eligible holdings |
| OptedInClients | SUM(IsOptedIn) count | Tier 3 | Clients who opted in to staking |
| OptedInUnits | SUM(EligibleUnits WHERE IsOptedIn=1) | Tier 3 | Opted-in holdings |
| OptedInValue | SUM(EligibleUnits * USD_Rate WHERE IsOptedIn=1) | Tier 3 | Opted-in USD value |
| OptedOutClients | EligibleClients - OptedInClients | Tier 3 | Clients who opted out |
| OptedOutUnits | SUM(EligibleUnits WHERE IsOptedIn=0) | Tier 3 | Opted-out holdings |
| OptedOutValue | SUM(EligibleUnits * USD_Rate WHERE IsOptedIn=0) | Tier 3 | Opted-out USD value |
| Units_AvailableForStaking | LEAST(EligibleUnits * LiquidityBuffer, OptedInUnits * 0.95[ETH: 0.90]) | Tier 3 | Liquidity-buffered amount eToro can stake on-chain |
| Value_AvailableForStaking | Same as Units_AvailableForStaking but USD | Tier 3 | |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | |
