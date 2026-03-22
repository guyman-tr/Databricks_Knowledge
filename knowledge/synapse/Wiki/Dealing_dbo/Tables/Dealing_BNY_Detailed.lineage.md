# Column Lineage — Dealing_dbo.Dealing_BNY_Detailed

**Writer**: `Dealing_dbo.SP_BNY_VIRTU_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — unnormalised per-counterparty source rows

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_EODRecon | Production (Tier 1) | eToro EOD rows (Type='eToro', EOD/Trades='EOD') |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro Trade rows (Type='eToro', EOD/Trades='Trades') |
| Dealing_staging.LP_BNY_Custody_Valuation_CustodyValuation | LP Feed (Tier 2) | BNY EOD rows |
| Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions | LP Feed (Tier 2) | BNY Trade rows |
| Dealing_staging.LP_VIRTU_ETORO_Allocations_Sheet | LP Feed (Tier 2) | VIRTU Trade rows |
| Dealing_staging.LP_Citadel_eToro_Confirm | LP Feed (Tier 2) | Citadel Trade rows |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | HS → LP account mapping, activity, LiquidityAccountID |

## Column → Source Mapping

| Column | Source | Notes |
|---|---|---|
| Date | SP parameter @TotalDate | Sunday→Friday fallback |
| Account_Number | LP_BNY or LP_VIRTU/Citadel | LP account number. NULL for eToro rows |
| HedgeServerID | Duco tables | eToro HS. NULL for LP rows |
| LiquidityAccountID | Fivetran mapping | Joins eToro HS to LP account |
| activity | Fivetran mapping | 'Stocks - Real', 'Stocks - CFDs', etc. |
| InstrumentID | Dim_Instrument via ISIN | NULL if LP instrument not in eToro system |
| ISINCode | LP or Duco | ISIN |
| Buy/Sell | LP or Duco | Trade direction (Trades rows only) |
| Units | LP or Duco | Units per counterparty row |
| Clients_Units | Duco | Client NOP. NULL for LP rows |
| LocalAmount | LP or Duco | Notional in local currency |
| AmountUSD | LP or Duco | USD notional |
| Rate | LP or Duco | Price per unit |
| FXRate | LP or Duco | Local → USD FX rate |
| Type | SP logic | 'BNY', 'eToro', 'VIRTU', 'Citadel' — hardcoded per source |
| EOD/Trades | SP logic | 'EOD' or 'Trades' — hardcoded per source branch |
| UpdateDate | GETDATE() | Insertion timestamp |
