# Column Lineage — Dealing_dbo.Dealing_IBRecon_EODHoldings

**Writer**: `Dealing_dbo.SP_IB_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Interactive Brokers equity vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_EODRecon | Production (Tier 1) | eToro EOD side (HS 126) |
| Dealing_staging.LP_IB_I3158027_Open_Positions | LP Feed (Tier 2) | IB equity positions (primary account UL3148833) |
| Dealing_staging.LP_IB_I1893329_Open_Positions | LP Feed (Tier 2) | IB secondary account (I16058395, Russian ADRs) |

## Date Logic

- `@Date2 = MAX(ReportDate) WHERE ReportDate <= @Date` — if IB data is unavailable for @Date, falls back to nearest prior date.

## Column → Source Mapping

| Column | Source | Notes |
|---|---|---|
| Date | @Date2 | Adjusted for IB data availability |
| InstrumentID | Dim_Instrument | Via ISIN + currency join |
| ISINCode | IB file / Duco | Join key |
| IB_Symbol | LP_IB_...Open_Positions | IB ticker |
| eToro_Symbol | Dim_Instrument | eToro ticker via InstrumentID |
| IsBuy | Duco | `CASE WHEN [Buy/Sell]='Buy' THEN 1 ELSE 0 END` |
| CurrencyPrimary | Duco | SellCurrency |
| IB_Units | LP_IB_...Open_Positions | Open position quantity |
| eToro_Units | Duco_EODRecon | eToro_Units (SUM) |
| Clients_Units | Duco_EODRecon | ClientUnits (SUM) |
| IB-eToro_Units | Computed | IB_Units − eToro_Units |
| IB-Clients_Units | Computed | IB_Units − Clients_Units |
| IB_LocalAmount | LP_IB | Position value local (GBX ÷100) |
| IB_AmountUSD | LP_IB | USD position value |
| eToro_AmountUSD | Duco_EODRecon | eToroUSDAmount |
| Clients_AmountNOP | Duco_EODRecon | ClientAmount |
| Reality-Supposed | Computed | IB_AmountUSD − eToro_AmountUSD |
| Reality-Client | Computed | IB_AmountUSD − Clients_AmountNOP |
| IB_Rate | LP_IB | Price per unit |
| FX_Rate | LP_IB | FX rate |
| HedgeServerID | Duco_EODRecon | HedgeServerID |
| Exchange | LP_IB | Trading venue |
| LastExecutionTime | LP_IB | Last execution timestamp |
| ClientAccountID | LP_IB | IB sub-account ID |
| UpdateDate | GETDATE() | Insertion timestamp |

## Active Account Scope

| HedgeServerID | ClientAccountID | Status |
|---|---|---|
| 126 | UL3148833 | Active (primary equity) |
| 126 | I16058395 | Active (Russian ADRs - frozen) |
| 121 | UL1894678 | Removed 2024-04-16 (SR-247903) |
| 25 | - | Stopped 2023-06-12 |
