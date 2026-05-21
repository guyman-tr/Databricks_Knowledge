# Dealing_dbo.Dealing_IBRecon_Trades

## 1. Overview

**Executed trade reconciliation** for Interactive Brokers equity accounts, comparing IB-reported trade activity against eToro's hedge trades and client position changes. Mirrors the column structure of `Dealing_IBRecon_EODHoldings` but captures trade flows rather than EOD snapshots.

**Row grain**: `Date` + `InstrumentID` + `Buy/Sell` direction + `HedgeServerID`.

> ⚠️ **Pipeline Alert**: Most recent data is **2025-08-22** (7+ months stale as of 2026-03-21). The IB trades feed may have been disrupted or this table may represent a decommissioned reporting scope. The IB EOD holdings table continues to be updated; only the trades table appears to be stale.

---

## 2. Business Context

`SP_IB_Recon` (Author: Adar Cahlon, 2021-07-01) writes this table. Registered in OpsDB as **SB_Daily Priority 0**.

**Reconciliation flow**:
1. **eToro side** — from `Dealing_Duco_ActivityRecon` (trade activity) for HS 126.
2. **IB side** — from `Dealing_staging.LP_IB_I3158027_Trades` and `LP_IB_I1893329_Daily_Trades`.
3. **Join key**: ISIN + currency + Buy/Sell (FULL OUTER JOIN).

**Key history**:
- 2021-07-26: Added executed trades part.
- 2021-08-10: Changed to LP_IB_I3158027_Trades as source.
- 2021-09-02: Added HS 121 / I1893329.
- SR-247903 (2024-04-16): Removed HS 121.

**Data currency**: Stale — last update **2025-08-22**. ~308K rows (all historical).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 26 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

| Check | Result |
|--------|--------|
| **Row count** | ~308,809 |
| **Max date** | 2025-08-22 ⚠️ stale |
| **Note** | EOD holdings table (same SP) is current; only trades is stale |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. |
| 2 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument name. |
| 4 | ISINCode | varchar(50) | YES | ISIN — join key. |
| 5 | Buy/Sell | varchar(50) | YES | Trade direction ('Buy' / 'Sell'). |
| 6 | CurrencyPrimary | varchar(50) | YES | Local currency. |
| 7 | IB_Units | decimal(16,6) | YES | Trade units reported by IB. (Tier 2 — LP_IB_I3158027_Trades) |
| 8 | eToro_Units | decimal(16,6) | YES | eToro hedge trade units. (Tier 2 — Dealing_Duco_ActivityRecon.eToro_Units) |
| 9 | Clients_Units | decimal(16,6) | YES | Client NOP units. |
| 10 | IB-eToro_Units | decimal(16,6) | YES | IB_Units − eToro_Units. Reconciliation diff. |
| 11 | IB-Clients_Units | decimal(16,6) | YES | IB_Units − Clients_Units. |
| 12 | IB_Rate | decimal(16,6) | YES | IB trade price per unit. |
| 13 | eToro_Rate | decimal(16,6) | YES | eToro average rate per unit. |
| 14 | IB-eToro_Rate | decimal(16,6) | YES | IB_Rate − eToro_Rate. |
| 15 | IB_LocalAmount | money | YES | IB trade notional in local currency. |
| 16 | eToro_Amount | money | YES | eToro trade notional in local currency. |
| 17 | Clients_Amount | money | YES | Client position notional in local currency. |
| 18 | IB-eToro_Amount | money | YES | IB_LocalAmount − eToro_Amount. |
| 19 | IB-Clients_Amount | money | YES | IB_LocalAmount − Clients_Amount. |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 21 | IB_AmountUSD | money | YES | IB trade notional in USD. |
| 22 | eToro_AmountUSD | money | YES | eToro trade notional in USD. |
| 23 | IB-eToro_AmountUSD | money | YES | IB_AmountUSD − eToro_AmountUSD. |
| 24 | IB-Clients_AmountUSD | money | YES | IB_AmountUSD − Client amount in USD. |
| 25 | HedgeServerID | int | YES | eToro hedge server (126). |
| 26 | Exchange | varchar(100) | YES | Trading venue. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_ActivityRecon](Dealing_Duco_ActivityRecon.md) | HedgeServerID + Date |
| Sibling (EOD) | [Dealing_IBRecon_EODHoldings](Dealing_IBRecon_EODHoldings.md) | Same SP |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_IB_Recon` |
| **Schedule** | Daily (SB_Daily), Priority 0 (registered in OpsDB) |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_ActivityRecon |
| **LP Source** | Dealing_staging.LP_IB_I3158027_Trades, LP_IB_I1893329_Daily_Trades |
