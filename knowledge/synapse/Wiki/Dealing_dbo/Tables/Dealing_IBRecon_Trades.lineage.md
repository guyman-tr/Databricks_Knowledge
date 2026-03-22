# Column Lineage — Dealing_dbo.Dealing_IBRecon_Trades

**Writer**: `Dealing_dbo.SP_IB_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — IB equity trades vs eToro trade activity
**Status**: ⚠️ Stale — last data 2025-08-22

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro trade activity side (HS 126) |
| Dealing_staging.LP_IB_I3158027_Trades | LP Feed (Tier 2) | IB trade confirmations (primary account) |
| Dealing_staging.LP_IB_I1893329_Daily_Trades | LP Feed (Tier 2) | IB secondary account trades |

## Column → Source Mapping

| Column | Source | Notes |
|---|---|---|
| Date | @Date | Trade date |
| InstrumentID | Dim_Instrument | Via ISIN + currency |
| ISINCode | IB file / Duco | Join key |
| Buy/Sell | IB file / Duco | Trade direction |
| IB_Units | LP_IB_I3158027_Trades | Trade quantity (CAST to FLOAT for NULLIF division safety) |
| eToro_Units | Duco_ActivityRecon | eToro_Units (SUM) |
| Clients_Units | Duco_ActivityRecon | ClientUnits |
| IB-eToro_Units | Computed | IB_Units − eToro_Units |
| IB-Clients_Units | Computed | IB_Units − Clients_Units |
| IB_Rate | LP_IB | Trade price |
| eToro_Rate | Duco_ActivityRecon | eToro_AvgRate (AVG) |
| IB_LocalAmount | LP_IB | Trade notional local |
| eToro_Amount | Duco_ActivityRecon | eToroLocalAmount |
| Clients_Amount | Duco_ActivityRecon | ClientAmount |
| IB_AmountUSD | LP_IB | USD notional |
| eToro_AmountUSD | Duco_ActivityRecon | eToroUSDAmount |
| HedgeServerID | Duco | HedgeServerID |
| Exchange | LP_IB | Trading venue |
| UpdateDate | GETDATE() | Insertion timestamp |
