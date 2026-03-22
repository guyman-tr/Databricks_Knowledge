# Dealing_dbo.Dealing_BNY_Detailed

## 1. Overview

**Detailed staging data** for the BNY/VIRTU/Citadel reconciliation pipeline. Each row represents a single raw position or trade record from one counterparty (BNY, eToro, VIRTU, or Citadel) for a given instrument and date, before the cross-counterparty comparison tables are computed. Unlike the summary recon tables, this table stores the **unnormalised per-counterparty source rows**, tagged by `Type` and `EOD/Trades`.

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Type` (counterparty) + `EOD/Trades` indicator.

---

## 2. Business Context

`SP_BNY_VIRTU_Recon` writes all four BNY/VIRTU/Citadel output tables, including this detailed source table. This table is the largest in the batch (~5.2M rows) because it contains **one row per source system per instrument per date** rather than the aggregated reconciliation row.

**Type breakdown** (from live data):

| Type | EOD/Trades | activity | Notes |
|---|---|---|---|
| eToro | EOD | Stocks - Real | Dominant — eToro EOD hedge position |
| eToro | Trades | Stocks - Real | eToro trade activity |
| BNY | EOD | Stocks - Real / CFD | BNY custodian EOD holdings |
| VIRTU | Trades | Stocks - Real / CFD | VIRTU trade confirmations |
| BNY | Trades | Stocks - Real / CFD | BNY trade reports |
| Citadel | Trades | Stocks - Real | Citadel trade confirms |

**Use case**: Auditing raw source data before reconciliation. Analysts can filter by Type to isolate individual LP feeds or compare pre-aggregation figures with the summary recon tables.

**Data currency**: Active daily as of 2026-03-10. Covers both Real and CFD stocks activity (minor CFD fraction).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 21 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~5,244,945 (largest BNY recon table) |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **Type distribution** | eToro (EOD + Trades) ~55%, BNY ~32%, VIRTU ~11%, Citadel <1% |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date — the reconciliation date for this row. (Tier 2 — SP_BNY_VIRTU_Recon) |
| 2 | Account_Number | int | YES | LP custodian account number. Populated for LP-side rows (Type = BNY/VIRTU/Citadel); NULL for eToro-side rows. |
| 3 | HedgeServerID | int | YES | eToro hedge server identifier. Populated for eToro-side rows; NULL for LP-side rows. |
| 4 | LiquidityAccountID | int | YES | eToro liquidity account identifier. Used to map eToro side to the correct LP account via Fivetran HS mapping. |
| 5 | activity | varchar(100) | YES | Product type: 'Stocks - Real', 'Stocks - CFDs', 'Stocks - CFD'. Derived from Fivetran LP mapping. |
| 6 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. NULL for LP-side rows where instrument could not be resolved. |
| 7 | InstrumentDisplayName | varchar(100) | YES | Human-readable name. Populated from eToro side or LP file depending on row type. |
| 8 | Symbol | varchar(250) | YES | Ticker symbol. |
| 9 | ISINCode | varchar(250) | YES | ISIN — primary cross-system matching key. |
| 10 | Buy/Sell | varchar(100) | YES | Trade direction for Trades rows ('Buy'/'Sell'). NULL for EOD rows. |
| 11 | CurrencyPrimary | varchar(50) | YES | Instrument local currency (GBX normalised to GBP in amounts). |
| 12 | Exchange | varchar(80) | YES | Trading venue (e.g., "SKANDINAVISKA EB", "BNY LDN-CREST"). |
| 13 | Units | decimal(16,6) | YES | Position or trade units for this counterparty row. |
| 14 | Clients_Units | decimal(16,6) | YES | Corresponding client NOP units (from eToro side). NULL for LP rows. |
| 15 | LocalAmount | money | YES | Notional value in local currency. |
| 16 | AmountUSD | money | YES | Notional value in USD. |
| 17 | Rate | decimal(16,6) | YES | Price per unit in local currency. |
| 18 | FXRate | decimal(16,6) | YES | FX rate (local → USD) at the time of this record. |
| 19 | Type | varchar(50) | YES | **Row type identifier**: 'BNY', 'eToro', 'VIRTU', or 'Citadel'. Indicates which counterparty system this row came from. |
| 20 | EOD/Trades | varchar(50) | YES | **Record category**: 'EOD' = end-of-day holdings snapshot; 'Trades' = executed trade activity. |
| 21 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro EOD) | [Dealing_Duco_EODRecon](Dealing_Duco_EODRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (eToro Trades) | [Dealing_Duco_ActivityRecon](Dealing_Duco_ActivityRecon.md) | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument dim) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (summary recon) | [Dealing_BNY_VIRTU_ReconEODHolding](Dealing_BNY_VIRTU_ReconEODHolding.md) | Same SP, aggregated form |
| Sibling (summary recon) | [Dealing_BNY_VIRTU_ReconTrades](Dealing_BNY_VIRTU_ReconTrades.md) | Same SP, aggregated form |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_BNY_VIRTU_Recon` |
| **Schedule** | Daily (SB_Daily), weekdays only |
| **OpsDB Priority** | N/A (not registered individually) |
| **Pattern** | DELETE-INSERT by Date |
| **Sources** | Dealing_Duco_EODRecon, Dealing_Duco_ActivityRecon, all LP_BNY/VIRTU/Citadel staging tables |

---

## 8. Usage Notes

- Filter by `Type` to isolate a specific counterparty's raw data.
- Filter by `EOD/Trades` to distinguish position snapshots from trade flows.
- The `LiquidityAccountID` for eToro rows connects back to the Fivetran HS mapping (`External_Fivetran_dealing_active_hs_mappings`), which defines which eToro hedge server corresponds to which LP account.
