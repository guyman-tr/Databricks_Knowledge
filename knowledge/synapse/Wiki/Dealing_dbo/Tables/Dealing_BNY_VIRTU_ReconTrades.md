# Dealing_dbo.Dealing_BNY_VIRTU_ReconTrades

## 1. Overview

**Daily trade reconciliation** comparing executed trade activity from two LP counterparties — BNY Mellon (BNY) and VIRTU Financial — against eToro's hedge positions and client activity. Each row is an instrument-direction-date combination with both BNY and VIRTU columns side-by-side against eToro, enabling comparison of two settlement/execution paths for the same trade flow.

**Row grain**: `Date` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

Part of the **BNY/VIRTU/Citadel daily reconciliation pipeline** (`SP_BNY_VIRTU_Recon`, Gili Goldbaum, 2023-11-06). Registered in OpsDB as a **SB_Daily Priority 0** task.

**Reconciliation flow**:
1. **eToro side** — from `Dealing_Duco_ActivityRecon` for HedgeServerIDs mapped to BNY-type accounts.
2. **BNY side** — from `Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions`.
3. **VIRTU side** — from `Dealing_staging.LP_VIRTU_ETORO_Allocations_Sheet` (and APAC/US variants).
4. **Join key**: ISIN + currency + Buy/Sell direction (FULL OUTER JOIN across all three sides).

**Key history** (from SP change log):
- SR-255494 (2024-05-06): Removed HS 225.
- SR-282875 (2024-11-28): Moved HS/LA mapping to Fivetran (deduplication).
- SR-326320 (2025-08-07): Filter out specific BNY transaction types.
- SR-347273 (2025-12-10): Deduplication fix in Fivetran temp tables.

**Data currency**: Active daily as of 2026-03-10. ~1.6M rows.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 41 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

| Check | Result |
|--------|--------|
| **Row count** | ~1,618,874 |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **Buy/Sell split** | Approximately even Buy/Sell |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Trade activity date. |
| 2 | Account_Number | int | YES | LP custodian account number (BNY or VIRTU). NULL for eToro-only records. |
| 3 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 4 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. |
| 5 | Symbol | varchar(250) | YES | Ticker symbol. |
| 6 | ISINCode | varchar(250) | YES | ISIN — primary join key. |
| 7 | CurrencyPrimary | varchar(50) | YES | Local currency (GBX → GBP normalised in amounts). |
| 8 | Exchange | varchar(80) | YES | Trading venue. |
| 9 | BNY_Units | decimal(16,6) | YES | Trade units reported by BNY. (Tier 2 — LP_BNY_Custody_Security_Transactions) |
| 10 | VIRTU_Units | decimal(16,6) | YES | Trade units reported by VIRTU. (Tier 2 — LP_VIRTU_ETORO_Allocations_Sheet) |
| 11 | eToro_Units | decimal(16,6) | YES | Trade units from eToro hedge activity. (Tier 2 — Dealing_Duco_ActivityRecon.eToro_Units) |
| 12 | Clients_Units | decimal(16,6) | YES | Client NOP units. (Tier 2 — Dealing_Duco_ActivityRecon.ClientUnits) |
| 13 | BNY-eToro_Units | decimal(16,6) | YES | **Reconciliation diff**: BNY_Units − eToro_Units. |
| 14 | BNY-Clients_Units | decimal(16,6) | YES | BNY_Units − Clients_Units. |
| 15 | VIRTU-eToro_Units | decimal(16,6) | YES | VIRTU_Units − eToro_Units. Recon diff for VIRTU channel. |
| 16 | VIRTU-Clients_Units | decimal(16,6) | YES | VIRTU_Units − Clients_Units. |
| 17 | BNY_LocalAmount | money | YES | BNY trade notional in local currency. |
| 18 | VIRTU_LocalAmount | money | YES | VIRTU trade notional in local currency. |
| 19 | eToro_LocalAmount | money | YES | eToro trade notional (GBX ÷100). |
| 20 | BNY-eToro_LocalAmount | money | YES | BNY_LocalAmount − eToro_LocalAmount. |
| 21 | VIRTU-eToro_LocalAmount | money | YES | VIRTU_LocalAmount − eToro_LocalAmount. |
| 22 | BNY_AmountUSD | money | YES | BNY trade notional in USD. |
| 23 | VIRTU_AmountUSD | money | YES | VIRTU trade notional in USD. |
| 24 | eToro_AmountUSD | money | YES | eToro trade notional in USD. |
| 25 | Clients_AmountUSD | money | YES | Client position notional in USD. |
| 26 | BNY-eToro_AmountUSD | money | YES | BNY_AmountUSD − eToro_AmountUSD. |
| 27 | BNY-Clients_AmountUSD | money | YES | BNY_AmountUSD − Clients_AmountUSD. |
| 28 | VIRTU-eToro_AmountUSD | money | YES | VIRTU_AmountUSD − eToro_AmountUSD. |
| 29 | VIRTU-Clients_AmountUSD | money | YES | VIRTU_AmountUSD − Clients_AmountUSD. |
| 30 | BNY_Rate | decimal(16,6) | YES | Trade price per unit (BNY). |
| 31 | VIRTU_Rate | decimal(16,6) | YES | Trade price per unit (VIRTU). |
| 32 | eToro_Rate | decimal(16,6) | YES | eToro average trade rate per unit. |
| 33 | BNY-eToro_Rate | decimal(16,6) | YES | BNY_Rate − eToro_Rate. |
| 34 | VIRTU-eToro_Rate | decimal(16,6) | YES | VIRTU_Rate − eToro_Rate. |
| 35 | BNY_FXRate | decimal(16,6) | YES | FX rate used by BNY. |
| 36 | VIRTU_FXRate | decimal(16,6) | YES | FX rate used by VIRTU. |
| 37 | eToro_FXRate | decimal(16,6) | YES | FX rate used by eToro. |
| 38 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 39 | Buy/Sell | varchar(100) | YES | Trade direction: 'Buy' or 'Sell'. |
| 40 | activity | varchar(100) | YES | Product type tag. Predominantly 'Stocks - Real'; includes 'Stocks - CFDs'. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_ActivityRecon](Dealing_Duco_ActivityRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (EOD) | [Dealing_BNY_VIRTU_ReconEODHolding](Dealing_BNY_VIRTU_ReconEODHolding.md) | Same SP |
| Sibling (Citadel) | [Dealing_BNY_Citadel_ReconTrades](Dealing_BNY_Citadel_ReconTrades.md) | Same SP |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_BNY_VIRTU_Recon` |
| **Schedule** | Daily (SB_Daily), Priority 0 |
| **OpsDB** | Registered as Dealing_dbo.Dealing_BNY_VIRTU_ReconTrades |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_ActivityRecon |
| **LP Sources** | LP_BNY_Custody_Security_Transactions, LP_VIRTU_ETORO_Allocations_Sheet (+ APAC + US variants) |
