# Column Lineage — Dealing_dbo.Dealing_BNY_VIRTU_ReconTrades

**Writer**: `Dealing_dbo.SP_BNY_VIRTU_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — BNY + VIRTU vs eToro trade activity

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro trades side |
| Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions | LP Feed (Tier 2) | BNY trade confirmations |
| Dealing_staging.LP_VIRTU_ETORO_Allocations_Sheet | LP Feed (Tier 2) | VIRTU trade allocations (global) |
| Dealing_staging.LP_VIRTU_ETORO_Allocations_APAC_Sheet | LP Feed (Tier 2) | VIRTU APAC allocations |
| Dealing_staging.LP_VIRTU_ETORO_Allocations_US_Sheet | LP Feed (Tier 2) | VIRTU US allocations |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | HS → LP mapping, activity |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | Sunday→Friday fallback |
| Account_Number | LP_BNY / LP_VIRTU | LP account |
| BNY_Units | LP_BNY_Custody_Security_Transactions | Trade quantity |
| VIRTU_Units | LP_VIRTU_ETORO_Allocations_Sheet | Trade allocation quantity |
| eToro_Units | Dealing_Duco_ActivityRecon | eToro_Units (SUM) |
| Clients_Units | Dealing_Duco_ActivityRecon | ClientUnits (SUM) |
| BNY-eToro_Units | Computed | BNY_Units − eToro_Units |
| VIRTU-eToro_Units | Computed | VIRTU_Units − eToro_Units |
| BNY_LocalAmount | LP_BNY | Gross notional local |
| VIRTU_LocalAmount | LP_VIRTU | Gross notional local |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon | eToroLocalAmount (GBX ÷100) |
| BNY_AmountUSD | LP_BNY | USD notional |
| VIRTU_AmountUSD | LP_VIRTU | USD notional |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon | eToroUSDAmount |
| Clients_AmountUSD | Dealing_Duco_ActivityRecon | ClientAmount |
| BNY_Rate / VIRTU_Rate | LP files | Trade price |
| eToro_Rate | Dealing_Duco_ActivityRecon | eToro_AvgRate (AVG) |
| BNY_FXRate | LP_BNY | FX rate |
| VIRTU_FXRate | LP_VIRTU | FX rate |
| eToro_FXRate | Dealing_Duco_ActivityRecon | FXratetoUSD |
| Buy/Sell | ISNULL(Duco, LP) | Trade direction |
| UpdateDate | GETDATE() | Insertion timestamp |
| activity | Fivetran mapping | Activity tag |
