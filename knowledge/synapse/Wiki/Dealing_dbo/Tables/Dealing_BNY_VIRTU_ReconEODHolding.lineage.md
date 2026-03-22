# Column Lineage — Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding

**Writer**: `Dealing_dbo.SP_BNY_VIRTU_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — BNY vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_EODRecon | Production (Tier 1) | eToro EOD holdings side |
| Dealing_staging.LP_BNY_Custody_Valuation_CustodyValuation | LP Feed (Tier 2) | BNY EOD custodian positions |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | HS → LP account mapping, activity |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | Sunday→Friday fallback |
| Account_Number | LP_BNY_Custody_Valuation | BNY account number |
| InstrumentID | Dealing_Duco_EODRecon | Via ISIN join to eToro side |
| ISINCode | ISNULL(Duco, LP) | Prefer eToro side |
| CurrencyPrimary | Duco | GBX normalised to GBP |
| BNY_Units | LP_BNY_Custody_Valuation | Position quantity |
| eToro_Units | Dealing_Duco_EODRecon | eToro_Units (SUM aggregated) |
| Clients_Units | Dealing_Duco_EODRecon | ClientUnits (SUM aggregated) |
| BNY-eToro_Units | Computed | ISNULL(BNY_Units,0) − ISNULL(eToro_Units,0) |
| BNY-Clients_Units | Computed | ISNULL(BNY_Units,0) − ISNULL(Clients_Units,0) |
| BNY_LocalAmount | LP_BNY_Custody_Valuation | Market value local |
| eToro_LocalAmount | Dealing_Duco_EODRecon | eToroLocalAmount (GBX ÷100) |
| BNY_AmountUSD | LP_BNY_Custody_Valuation | Market value USD |
| eToro_AmountUSD | Dealing_Duco_EODRecon | eToroUSDAmount |
| Clients_AmountUSD | Dealing_Duco_EODRecon | ClientAmount |
| BNY_Rate | LP_BNY_Custody_Valuation | Price per unit |
| eToro_Rate | Dealing_Duco_EODRecon | eToroRate |
| BNY_FXRate | LP_BNY_Custody_Valuation | FX rate |
| eToro_FXRate | Dealing_Duco_EODRecon | FXratetoUSD |
| UpdateDate | GETDATE() | Insertion timestamp |
| activity | Fivetran mapping | Activity tag |
