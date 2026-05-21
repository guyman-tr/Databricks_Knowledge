# Dealing_dbo.Dealing_GSReconTrades

## 1. Overview

**Daily trade reconciliation** comparing Goldman Sachs (GS) executed trade activity against eToro's hedge positions and client NOP for CFD instruments. Adds a `Total_Commission_USD` column to capture GS-reported commission per trade — a field not present in the EOD holdings table.

**Row grain**: `Date` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_GSRecon` (Author: Gili Goldbaum, 2023-11-22) writes both GS output tables. SB_Daily Priority 0.

**Reconciliation flow**:
1. **eToro side** — from `Dealing_Duco_ActivityRecon` (trade activity) for GS-mapped HedgeServerIDs.
2. **GS side** — from `Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302304_712993_Sheet1` (GS trade confirmations). Filters out `[Event]` IN ('Equity Reset', 'Financing Payment', 'Spread Change') — only executable trades are reconciled.
3. **Join key**: ISIN + currency + Buy/Sell (FULL OUTER JOIN).

**GS field mapping** (LP → Synapse column):
- `[Quantity]` → `GS_Units`
- `[Trade Gross Notional]` → `GS_LocalAmount`
- `[Trade Gross Notional] × FX` → `GS_AmountUSD`
- `[Trade Gross Price]` → `GS_Rate`
- `[FX Contract to Underlyer]` → `GS_FXRate`
- `[Commission Amount] × FX` → `Total_Commission_USD`

**Data pattern**: Many rows have `GS_Units = 0` with non-zero `Clients_Units` — these are client-only position records where no corresponding GS trade exists (pure discrepancy rows from the FULL OUTER JOIN).

**Key change** — SR-318900 (2025-06-17): Changed GS trades source to account 1200626261 (was previously a different account number).

**Data currency**: Active daily as of 2026-03-10. ~393K rows.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 30 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

| Check | Result |
|--------|--------|
| **Row count** | ~393,326 |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **GS_Units = 0 rows** | Large proportion — FULL OUTER JOIN captures client-only discrepancy rows |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. |
| 2 | HedgeServerID | int | YES | eToro hedge server (GS account). |
| 3 | Account_Number | varchar(50) | YES | GS account number. NULL for eToro-only rows. |
| 4 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 5 | InstrumentDisplayName | varchar(max) | YES | Instrument name (from GS `[Underlyer Name]` or eToro). |
| 6 | Symbol | varchar(250) | YES | Ticker (RIC from GS `[Underlyer RIC]`). |
| 7 | ISINCode | varchar(250) | YES | ISIN. Primary join key. |
| 8 | Buy/Sell | varchar(100) | YES | Trade direction. |
| 9 | CurrencyPrimary | varchar(50) | YES | Local currency (`[Underlyer CCY]` from GS). GBX → GBP normalised. |
| 10 | GS_Units | decimal(16,6) | YES | Trade quantity from GS (`[Quantity]`). Zero when GS has no trade for this instrument/direction. |
| 11 | eToro_Units | decimal(16,6) | YES | eToro hedge trade units. (Tier 2 — Dealing_Duco_ActivityRecon.eToro_Units) |
| 12 | Clients_Units | decimal(16,6) | YES | Client NOP units. (Tier 2 — Dealing_Duco_ActivityRecon.ClientUnits) |
| 13 | GS-eToro_Units | decimal(16,6) | YES | **Reconciliation diff**: GS_Units − eToro_Units. |
| 14 | GS-Clients_Units | decimal(16,6) | YES | GS_Units − Clients_Units. |
| 15 | GS_Rate | decimal(16,6) | YES | GS average trade price (`[Trade Gross Price]`). |
| 16 | eToro_Rate | decimal(16,6) | YES | eToro average rate. |
| 17 | GS-eToro_Rate | decimal(16,6) | YES | GS_Rate − eToro_Rate. Price discrepancy. |
| 18 | GS_LocalAmount | money | YES | GS trade gross notional in local currency. |
| 19 | eToro_LocalAmount | money | YES | eToro trade notional in local currency. |
| 20 | GS-eToro_LocalAmount | money | YES | GS_LocalAmount − eToro_LocalAmount. |
| 21 | GS_AmountUSD | money | YES | GS notional in USD. |
| 22 | eToro_AmountUSD | money | YES | eToro notional in USD. |
| 23 | Clients_AmountUSD | money | YES | Client amount in USD. |
| 24 | GS-eToro_AmountUSD | money | YES | GS_AmountUSD − eToro_AmountUSD. |
| 25 | GS-Clients_AmountUSD | money | YES | GS_AmountUSD − Clients_AmountUSD. |
| 26 | GS_FXRate | decimal(16,6) | YES | GS FX rate (`[FX Contract to Underlyer]`). |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro FX rate. |
| 28 | Total_Commission_USD | money | YES | GS-reported total commission in USD (`[Commission Amount] × FX rate`). Used for cost tracking. |
| 29 | Exchange | varchar(80) | YES | Trading venue. |
| 30 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_ActivityRecon](Dealing_Duco_ActivityRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (EOD) | [Dealing_GSReconEODHolding](Dealing_GSReconEODHolding.md) | Same SP_GSRecon |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_GSRecon` |
| **Schedule** | Daily (SB_Daily), Priority 0 |
| **OpsDB** | Registered as Dealing_dbo.Dealing_GSReconTrades |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_ActivityRecon |
| **LP Source** | Dealing_staging.LP_GS_SRPB_221797_1200626261_Equity_Synthetic_302304_712993_Sheet1 |

---

## 8. Usage Notes

- Filter `GS_Units <> 0` to isolate rows where GS reported a trade; rows where `GS_Units = 0` are client-only discrepancy rows from the FULL OUTER JOIN.
- `Total_Commission_USD` is unique to this table vs the EOD table — useful for cost/best-execution analysis against GS.
