# Column Lineage — Dealing_dbo.Dealing_GSReconTrades

**Writer**: `Dealing_dbo.SP_GSRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Goldman Sachs vs eToro executed trades

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro trades side |
| Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302304_712993_Sheet1 | LP Feed (Tier 2) | GS trade confirmations (account 1200626261, changed SR-318900 Jun 2025) |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | GS HS → LA mapping |

## GS Source Field Mapping

| GS File Column | Synapse Column | Notes |
|---|---|---|
| [Account Number] | Account_Number | GS sub-account |
| [Underlyer Name] | InstrumentDisplayName | Instrument name |
| [Underlyer RIC] | Symbol | RIC ticker |
| [Underlyer ISIN] | ISINCode | Join key |
| [Buy/Sell] | Buy/Sell | Trade direction |
| [Underlyer CCY] | CurrencyPrimary | Local currency |
| [Quantity] | GS_Units | Trade quantity |
| [Trade Gross Notional] | GS_LocalAmount | Trade notional local |
| [Trade Gross Notional] × FX | GS_AmountUSD | USD notional |
| [Trade Gross Price] | GS_Rate | Execution price |
| [FX Contract to Underlyer] | GS_FXRate | FX rate |
| [Commission Amount] × FX | Total_Commission_USD | Commission in USD |

## GS Filter

- `WHERE ReportDateID = @DateID AND [Event] NOT IN ('Equity Reset', 'Financing Payment', 'Spread Change')` — only executable trades

## Column → Source Mapping (computed)

| Column | Source | Transform |
|---|---|---|
| eToro_Units | Duco_ActivityRecon | eToro_Units (SUM) |
| Clients_Units | Duco_ActivityRecon | ClientUnits (SUM) |
| eToro_LocalAmount | Duco_ActivityRecon | eToroLocalAmount (GBX ÷100) |
| eToro_AmountUSD | Duco_ActivityRecon | eToroUSDAmount |
| eToro_Rate | Duco_ActivityRecon | eToro_AvgRate (AVG) |
| eToro_FXRate | Duco_ActivityRecon | FXratetoUSD |
| GS-eToro_Units | Computed | ISNULL(GS,0) − ISNULL(eToro,0) |
| GS-Clients_Units | Computed | ISNULL(GS,0) − ISNULL(Clients,0) |
| UpdateDate | GETDATE() | Insertion timestamp |

## Filtering

- Join: FULL OUTER JOIN on ISINCode + CurrencyPrimary + [Buy/Sell]
