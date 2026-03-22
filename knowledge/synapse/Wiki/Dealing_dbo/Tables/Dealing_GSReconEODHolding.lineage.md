# Column Lineage — Dealing_dbo.Dealing_GSReconEODHolding

**Writer**: `Dealing_dbo.SP_GSRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Goldman Sachs vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_EODRecon | Production (Tier 1) | eToro EOD holdings side |
| Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302321_713868_PositionValuationSummary | LP Feed (Tier 2) | GS EOD position valuations |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | GS HS → LA mapping (activity='Stocks - CFDs', provider='GS') |

## GS Source Field Mapping

| GS File Column | Synapse Column | Notes |
|---|---|---|
| [Account Number] | Account_Number | GS account ID |
| [Underlyer Product Description] | InstrumentDisplayName | GS instrument name |
| [Underlyer RIC] | Symbol | GS ticker (RIC format) |
| [Underlyer ISIN] | ISINCode | Primary join key |
| [Underlyer Currency] | CurrencyPrimary | Local currency |
| [TD Quantity] | GS_Units | EOD position quantity |
| [Current Market Value] | GS_LocalAmount | Market value local |
| [Current Market Value] × [FX Contract to Underlyer] | GS_AmountUSD | USD valuation |
| [Current Price] | GS_Rate | Price per unit |
| [FX Contract to Underlyer] | GS_FXRate | FX rate |

## Column → Source Mapping (computed)

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter @Date | Direct |
| HedgeServerID | Duco_EODRecon | HedgeServerID |
| GS-eToro_Units | Computed | ISNULL(GS_Units,0) − ISNULL(eToro_Units,0) |
| GS-Clients_Units | Computed | ISNULL(GS_Units,0) − ISNULL(Clients_Units,0) |
| eToro_Units | Duco_EODRecon | eToro_Units (SUM) |
| eToro_LocalAmount | Duco_EODRecon | eToroLocalAmount (GBX ÷100) |
| eToro_AmountUSD | Duco_EODRecon | eToroUSDAmount |
| Clients_Units | Duco_EODRecon | ClientUnits |
| Clients_AmountUSD | Duco_EODRecon | ClientAmount |
| eToro_Rate | Duco_EODRecon | eToroRate |
| eToro_FXRate | Duco_EODRecon | FXratetoUSD |
| UpdateDate | GETDATE() | Insertion timestamp |

## Filtering

- GS source filtered: `ReportDateID = @DateID`
- eToro side filtered: GS-mapped HS+LA from Fivetran (activity='Stocks - CFDs', provider='GS', most recent mapping ≤ @Date)
- Join: FULL OUTER JOIN on ISINCode + CurrencyPrimary
