# Column Lineage — Dealing_dbo.Dealing_BNY_Citadel_ReconTrades

**Writer**: `Dealing_dbo.SP_BNY_VIRTU_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — BNY + Citadel vs eToro (Stocks - Real trades)

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro side: eToro_Units, Clients_Units, amounts, rates |
| Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions | LP Feed (Tier 2) | BNY side: BNY_Units, BNY amounts |
| Dealing_staging.LP_Citadel_eToro_Confirm | LP Feed (Tier 2) | Citadel side: Citadel_Units, Citadel amounts |
| Dealing_staging.LP_VIRTU_ETORO_Allocations_Sheet (+ APAC + US) | LP Feed (Tier 2) | VIRTU data (merged in BNY_Detailed) |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | HS → LP account mapping, activity tag |
| DWH_dbo.Dim_Instrument | Dimension (Tier 1) | InstrumentID resolution |

## Column → Source Mapping

| Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | SP parameter | @TotalDate | DATEADD Sunday→Friday fallback |
| Account_Number | LP_BNY_... | Account number | Direct |
| InstrumentID | Dealing_Duco_ActivityRecon | InstrumentID | Via ISIN join |
| ISINCode | LP_BNY / LP_Citadel / Duco | ISINCode | ISNULL(eToro, LP) |
| Buy/Sell | Dealing_Duco_ActivityRecon | [Buy/Sell] | ISNULL(eToro, LP) |
| CurrencyPrimary | Duco | SellCurrency | GBX → GBP normalised |
| BNY_Units | LP_BNY_Custody_Security_Transactions | units column | Direct |
| Citadel_Units | LP_Citadel_eToro_Confirm | quantity | Direct |
| eToro_Units | Dealing_Duco_ActivityRecon | eToro_Units | Aggregated SUM |
| Clients_Units | Dealing_Duco_ActivityRecon | ClientUnits | Aggregated SUM |
| BNY-eToro_Units | Computed | BNY_Units − eToro_Units | Arithmetic diff |
| Citadel-eToro_Units | Computed | Citadel_Units − eToro_Units | Arithmetic diff |
| BNY_LocalAmount | LP_BNY | local amount | Direct |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon | eToroLocalAmount | GBX ÷100 |
| BNY_AmountUSD | LP_BNY | USD amount | Direct |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon | eToroUSDAmount | Direct |
| BNY_Rate | LP_BNY | price | Direct |
| eToro_Rate | Dealing_Duco_ActivityRecon | eToro_AvgRate | AVG |
| UpdateDate | GETDATE() | - | Insertion timestamp |
| activity | External_Fivetran_dealing_active_hs_mappings | activity | From HS mapping |
