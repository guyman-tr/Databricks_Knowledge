# Dealing_dbo.Dealing_GSReconEODHolding

## 1. Overview

**Daily end-of-day holdings reconciliation** comparing Goldman Sachs (GS) custodian positions against eToro's internal hedge positions and client NOP for CFD-scope instruments. Each row represents one instrument for one date, with arithmetic diff columns flagging discrepancies between GS and eToro.

**Row grain**: `Date` + `InstrumentID` (+ implicit GS account scope via Fivetran mapping).

---

## 2. Business Context

`SP_GSRecon` (Author: Gili Goldbaum, 2023-11-22) writes both GS reconciliation output tables and runs daily as a **SB_Daily Priority 0** task.

**Reconciliation flow**:
1. **eToro side** — from `Dealing_Duco_EODRecon` filtered to HedgeServerID + LiquidityAccountID matching GS accounts (activity = 'Stocks - CFDs', liquidity_provider = 'GS' via Fivetran).
2. **GS side** — from `Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302321_713868_PositionValuationSummary` (GS EOD position valuation report for account 1200626261).
3. **Join key**: ISIN + currency (FULL OUTER JOIN).

**Key changes** (from SP change log):
- SR-277911 (2024-10-29/30): Fixed data type errors.
- SR-278675 (2024-11-01): Moved HS/LA mapping to Fivetran.
- SR-306341 (2025-03-23): Added CFDs activity filter.
- SR-318900 (2025-06-17): Changed GS trades table to account 1200626261 (EOD uses same account prefix).

**GS field mapping** (LP → Synapse column):
- `[TD Quantity]` → `GS_Units`
- `[Current Market Value]` → `GS_LocalAmount`
- `[Current Market Value] × [FX Contract to Underlyer]` → `GS_AmountUSD`
- `[Current Price]` → `GS_Rate`
- `[FX Contract to Underlyer]` → `GS_FXRate`

**Data currency**: Active daily as of 2026-03-10. ~644K rows.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 28 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

| Check | Result |
|--------|--------|
| **Row count** | ~643,933 |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **HedgeServerID** | Primarily HS 101 (GS prime brokerage account) |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (EOD snapshot date). |
| 2 | HedgeServerID | int | YES | eToro hedge server handling the GS account. Populated from eToro Duco side. |
| 3 | Account_Number | varchar(50) | YES | GS account number (e.g., "63823934"). From LP file `[Account Number]`. |
| 4 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 5 | InstrumentDisplayName | varchar(max) | YES | Instrument name. Coalesced from eToro/GS sides. |
| 6 | Symbol | varchar(250) | YES | Ticker symbol (RIC format from GS, ticker from eToro). |
| 7 | ISINCode | varchar(250) | YES | ISIN — primary join key. |
| 8 | CurrencyPrimary | varchar(50) | YES | Local currency. GBX → GBP normalised in amounts. |
| 9 | Exchange | varchar(80) | YES | Trading venue. |
| 10 | GS_Units | decimal(16,6) | YES | EOD position units from GS. Sourced from `[TD Quantity]` in GS valuation report. (Tier 2 — LP_GS_...PositionValuationSummary) |
| 11 | eToro_Units | decimal(16,6) | YES | EOD hedge units from eToro's internal position. (Tier 1 — Dealing_Duco_EODRecon.eToro_Units) |
| 12 | Clients_Units | decimal(16,6) | YES | Client NOP units. (Tier 1 — Dealing_Duco_EODRecon.ClientUnits) |
| 13 | GS-eToro_Units | decimal(16,6) | YES | **Reconciliation diff**: GS_Units − eToro_Units. Non-zero = recon break. |
| 14 | GS-Clients_Units | decimal(16,6) | YES | GS_Units − Clients_Units. |
| 15 | GS_LocalAmount | money | YES | GS market value in local currency (`[Current Market Value]`). |
| 16 | eToro_LocalAmount | money | YES | eToro local valuation. |
| 17 | GS-eToro_LocalAmount | money | YES | GS_LocalAmount − eToro_LocalAmount. |
| 18 | GS_AmountUSD | money | YES | GS position value in USD (`[Current Market Value] × FX rate`). |
| 19 | eToro_AmountUSD | money | YES | eToro position value in USD. |
| 20 | Clients_AmountUSD | money | YES | Client NOP value in USD. |
| 21 | GS-eToro_AmountUSD | money | YES | GS_AmountUSD − eToro_AmountUSD. Dollar value of the break. |
| 22 | GS-Clients_AmountUSD | money | YES | GS_AmountUSD − Clients_AmountUSD. |
| 23 | GS_Rate | decimal(16,6) | YES | GS price per unit (`[Current Price]`). |
| 24 | eToro_Rate | decimal(16,6) | YES | eToro rate per unit. |
| 25 | GS-eToro_Rate | decimal(16,6) | YES | GS_Rate − eToro_Rate. |
| 26 | GS_FXRate | decimal(16,6) | YES | GS FX rate (`[FX Contract to Underlyer]`). |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro FX rate. |
| 28 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_EODRecon](Dealing_Duco_EODRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (trades recon) | [Dealing_GSReconTrades](Dealing_GSReconTrades.md) | Same SP_GSRecon |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_GSRecon` |
| **Schedule** | Daily (SB_Daily), Priority 0 |
| **OpsDB** | Registered as Dealing_dbo.Dealing_GSReconEODHolding |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_EODRecon |
| **LP Source** | Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302321_713868_PositionValuationSummary |
