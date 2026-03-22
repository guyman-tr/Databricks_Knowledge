# Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding

## 1. Overview

**Daily end-of-day holdings reconciliation** comparing BNY Mellon's custodian position for each instrument against eToro's internal hedge position (eToro_Units) and client NOP (Clients_Units). Each row represents one instrument position for one date, with diff columns exposing discrepancies between the LP and eToro views.

**Row grain**: `Date` + `InstrumentID` (+ implicit BNY account scope via LP mapping).

---

## 2. Business Context

Part of the **BNY/VIRTU/Citadel daily reconciliation pipeline** operated by `SP_BNY_VIRTU_Recon` (Author: Gili Goldbaum, 2023-11-06). Registered in OpsDB as a **SB_Daily Priority 0** task.

**Reconciliation flow**:
1. **eToro side** — pulled from `Dealing_Duco_EODRecon` filtered to HedgeServerIDs mapped to BNY accounts via Fivetran (`liquidity_provider LIKE '%-BNY'`).
2. **BNY side** — from `Dealing_staging.LP_BNY_Custody_Valuation_CustodyValuation` (BNY EOD position/valuation reports).
3. **Join key**: ISIN + currency.
4. **FULL OUTER JOIN** — captures instruments present on only one side (LP-only or eToro-only positions).

**Business rules**:
- Weekends skipped. Sunday runs against Friday data.
- GBX currencies: amounts divided by 100 to normalise to GBP.
- Activity scope: Real Stocks (dominant) + Stocks-CFDs (minor).
- DELETE-INSERT by date.

**Data currency**: Active daily as of 2026-03-10. ~1.6M rows.

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
| **Row count** | ~1,566,424 |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **Typical diff** | Most rows show BNY-eToro_Units ≈ 0; non-zero rows are recon breaks |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (EOD snapshot date). |
| 2 | Account_Number | int | YES | BNY custodian sub-account number. NULL for eToro-only rows. |
| 3 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 4 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. |
| 5 | Symbol | varchar(250) | YES | Ticker symbol. |
| 6 | ISINCode | varchar(250) | YES | ISIN — primary join key between BNY and eToro sides. |
| 7 | CurrencyPrimary | varchar(50) | YES | Local currency (GBX normalised to GBP). |
| 8 | Exchange | varchar(80) | YES | Trading venue. |
| 9 | BNY_Units | decimal(16,6) | YES | EOD position units reported by BNY custodian. (Tier 2 — LP_BNY_Custody_Valuation) |
| 10 | eToro_Units | decimal(16,6) | YES | EOD hedge units from eToro's internal hedge position. (Tier 1 — Dealing_Duco_EODRecon.eToro_Units) |
| 11 | Clients_Units | decimal(16,6) | YES | Aggregated client NOP units. (Tier 1 — Dealing_Duco_EODRecon.ClientUnits) |
| 12 | BNY-eToro_Units | decimal(16,6) | YES | **Reconciliation diff**: BNY_Units − eToro_Units. Non-zero = recon break to investigate. |
| 13 | BNY-Clients_Units | decimal(16,6) | YES | BNY_Units − Clients_Units. LP vs client position comparison. |
| 14 | BNY_LocalAmount | money | YES | Position market value in local currency (BNY reported). |
| 15 | eToro_LocalAmount | money | YES | eToro's local amount valuation. GBX normalised ÷100. |
| 16 | BNY-eToro_LocalAmount | money | YES | BNY_LocalAmount − eToro_LocalAmount. |
| 17 | BNY_AmountUSD | money | YES | Position value in USD (BNY reported). |
| 18 | eToro_AmountUSD | money | YES | eToro position value in USD. |
| 19 | Clients_AmountUSD | money | YES | Client NOP value in USD. |
| 20 | BNY-eToro_AmountUSD | money | YES | BNY_AmountUSD − eToro_AmountUSD. Dollar value of the recon break. |
| 21 | BNY-Clients_AmountUSD | money | YES | BNY_AmountUSD − Clients_AmountUSD. |
| 22 | BNY_Rate | decimal(16,6) | YES | BNY's price per unit in local currency. |
| 23 | eToro_Rate | decimal(16,6) | YES | eToro's price per unit. |
| 24 | BNY-eToro_Rate | decimal(16,6) | YES | BNY_Rate − eToro_Rate. Price discrepancy. |
| 25 | BNY_FXRate | decimal(16,6) | YES | BNY's FX rate (local → USD). |
| 26 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate. |
| 27 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 28 | activity | varchar(100) | YES | Product type tag ('Stocks - Real', 'Stocks - CFDs'). From Fivetran LP mapping. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_EODRecon](Dealing_Duco_EODRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (trades recon) | [Dealing_BNY_VIRTU_ReconTrades](Dealing_BNY_VIRTU_ReconTrades.md) | Same SP, trades activity |
| Sibling (detailed) | [Dealing_BNY_Detailed](Dealing_BNY_Detailed.md) | Same SP, unnormalised source rows |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_BNY_VIRTU_Recon` |
| **Schedule** | Daily (SB_Daily), Priority 0 |
| **OpsDB** | Registered as Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_EODRecon |
| **LP Source** | Dealing_staging.LP_BNY_Custody_Valuation_CustodyValuation |
