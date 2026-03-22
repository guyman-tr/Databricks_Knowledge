# Dealing_dbo.Dealing_IBRecon_EODHoldings_CFD

## 1. Overview

**CFD-specific end-of-day holdings reconciliation** for Interactive Brokers, covering the CFD hedge book on HS 300. Structurally identical to `Dealing_IBRecon_EODHoldings` except: covers the CFD account (HS 300) rather than equity accounts (HS 126), and does not include `LastExecutionTime`. Very small volume (~538 rows total) suggesting limited CFD hedging through IB.

**Row grain**: `Date` + `InstrumentID` + `IsBuy` + `ClientAccountID`.

---

## 2. Business Context

Added to `SP_IB_Recon` in February 2025 (SR-302234, Adar Cahlon). Initially mapped to HS 121, then changed to **HS 300** in April 2025 (SR-308489). Not registered in OpsDB independently.

**IB CFD account history**:
- SR-302234 (2025-02-25): IB CFD added, initially HS 121.
- SR-308489 (2025-04-03): Changed IB CFD to HS 300.

**Active scope**: HS 300 / UL1894678 (most rows, active through 2026-03-06). HS 121 / UL1894678 (stopped 2025-03-31 — pre-dates HS 300 migration).

**LP source**: `Dealing_staging.LP_IB_I1893329_Open_Positions` and `LP_IB_I1893329_Daily_Trades` for the CFD accounts.

**Data currency**: Near-current (most recent: 2026-03-09). Only 538 rows — small CFD book.

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
| **Row count** | 538 (very small CFD book) |
| **Date range** | Near-current (most recent: 2026-03-09) |
| **Active account** | HS 300 / UL1894678 (last data: 2026-03-06) |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. |
| 2 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument name. |
| 4 | ISINCode | varchar(50) | YES | ISIN — primary join key. |
| 5 | IB_Symbol | varchar(50) | YES | IB ticker symbol. |
| 6 | eToro_Symbol | varchar(50) | YES | eToro ticker symbol. |
| 7 | IsBuy | bit | YES | Direction flag: 1 = long, 0 = short. |
| 8 | CurrencyPrimary | varchar(50) | YES | Instrument local currency. |
| 9 | IB_Units | decimal(16,6) | YES | IB CFD position units. (Tier 2 — LP_IB_I1893329_Open_Positions) |
| 10 | eToro_Units | decimal(16,6) | YES | eToro hedge units. (Tier 1 — Dealing_Duco_EODRecon.eToro_Units) |
| 11 | Clients_Units | decimal(16,6) | YES | Client NOP units. |
| 12 | IB-eToro_Units | decimal(16,6) | YES | IB_Units − eToro_Units. Reconciliation diff. |
| 13 | IB-Clients_Units | decimal(16,6) | YES | IB_Units − Clients_Units. |
| 14 | IB_LocalAmount | money | YES | IB position value in local currency. |
| 15 | IB_AmountUSD | money | YES | IB position value in USD. |
| 16 | eToro_AmountUSD | money | YES | eToro position value in USD. |
| 17 | Clients_AmountNOP | money | YES | Client NOP value in USD. |
| 18 | Reality-Supposed | money | YES | IB_AmountUSD − eToro_AmountUSD. LP vs eToro USD discrepancy. |
| 19 | Reality-Client | money | YES | IB_AmountUSD − Clients_AmountNOP. LP vs client discrepancy. |
| 20 | IB_Rate | decimal(16,6) | YES | IB price per unit. |
| 21 | FX_Rate | decimal(16,6) | YES | FX rate (local → USD). |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 23 | HedgeServerID | int | YES | eToro hedge server (300 = IB CFD account). |
| 24 | Exchange | varchar(100) | YES | Trading venue. |
| 25 | ClientAccountID | varchar(30) | YES | IB client account identifier. Primarily "UL1894678". |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_EODRecon](Dealing_Duco_EODRecon.md) | HedgeServerID + Date |
| Sibling (equity EOD) | [Dealing_IBRecon_EODHoldings](Dealing_IBRecon_EODHoldings.md) | Same SP, equity accounts |
| Sibling (CFD trades) | [Dealing_IBRecon_Trades_CFD](Dealing_IBRecon_Trades_CFD.md) | Same SP, CFD trades |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_IB_Recon` |
| **Schedule** | Daily (SB_Daily); not registered in OpsDB independently |
| **OpsDB** | NOT registered |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_EODRecon (HS 300) |
| **LP Source** | Dealing_staging.LP_IB_I1893329_Open_Positions |
