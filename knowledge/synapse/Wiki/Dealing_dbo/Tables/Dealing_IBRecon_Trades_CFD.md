# Dealing_dbo.Dealing_IBRecon_Trades_CFD

## 1. Overview

**CFD trade reconciliation** for Interactive Brokers — the trades counterpart to `Dealing_IBRecon_EODHoldings_CFD`. Tracks executed CFD trade activity through IB against eToro hedge trades.

> ⚠️ **Effectively Abandoned**: Contains only **1 row** (a single USD.JPY trade from 2025-03-28). This table was added to `SP_IB_Recon` in February 2025 (SR-302234) but the IB CFD trades feed does not appear to be generating data. Not registered in OpsDB.

**Row grain**: `Date` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

Added as part of SR-302234 (Adar Cahlon, 2025-02-25) when IB CFD reconciliation was introduced. HS 300 became the CFD server after SR-308489 (2025-04-03) replacing initial HS 121. The EOD holdings side (`Dealing_IBRecon_EODHoldings_CFD`) has 538 rows and is near-current; only the trades variant is effectively empty.

**Status**: Stub/placeholder table. The IB CFD trades LP feed (`LP_IB_I1893329_Daily_Trades`) does not appear to be delivering trade confirmation data.

**Data currency**: Last data 2025-03-28. 1 row total.

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
| **Row count** | 1 ⚠️ |
| **Max date** | 2025-03-28 ⚠️ |
| **Content** | Single USD.JPY CFD trade |

---

## 5. Elements

Identical structure to `Dealing_IBRecon_Trades` (columns 1-26 are the same), covering:

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. |
| 2 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument name. |
| 4 | ISINCode | varchar(50) | YES | ISIN. |
| 5 | Buy/Sell | varchar(50) | YES | Trade direction. |
| 6 | CurrencyPrimary | varchar(50) | YES | Local currency (e.g., "JPY" for USD.JPY). |
| 7 | IB_Units | decimal(16,6) | YES | IB reported CFD trade units. |
| 8 | eToro_Units | decimal(16,6) | YES | eToro hedge trade units. |
| 9 | Clients_Units | decimal(16,6) | YES | Client NOP units. |
| 10 | IB-eToro_Units | decimal(16,6) | YES | IB_Units − eToro_Units. |
| 11 | IB-Clients_Units | decimal(16,6) | YES | IB_Units − Clients_Units. |
| 12 | IB_Rate | decimal(16,6) | YES | Trade price per unit. |
| 13 | eToro_Rate | decimal(16,6) | YES | eToro rate per unit. |
| 14 | IB-eToro_Rate | decimal(16,6) | YES | Rate diff. |
| 15 | IB_LocalAmount | money | YES | IB notional in local currency. |
| 16 | eToro_Amount | money | YES | eToro notional in local currency. |
| 17 | Clients_Amount | money | YES | Client notional in local currency. |
| 18 | IB-eToro_Amount | money | YES | IB_LocalAmount − eToro_Amount. |
| 19 | IB-Clients_Amount | money | YES | IB_LocalAmount − Clients_Amount. |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 21 | IB_AmountUSD | money | YES | IB notional in USD. |
| 22 | eToro_AmountUSD | money | YES | eToro notional in USD. |
| 23 | IB-eToro_AmountUSD | money | YES | USD diff. |
| 24 | IB-Clients_AmountUSD | money | YES | IB vs client USD diff. |
| 25 | HedgeServerID | int | YES | eToro hedge server (300 = IB CFD). |
| 26 | Exchange | varchar(100) | YES | Trading venue. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Sibling (CFD EOD) | [Dealing_IBRecon_EODHoldings_CFD](Dealing_IBRecon_EODHoldings_CFD.md) | Same SP, CFD EOD |
| Sibling (equity trades) | [Dealing_IBRecon_Trades](Dealing_IBRecon_Trades.md) | Same SP, equity |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_IB_Recon` |
| **Schedule** | Daily (SB_Daily); NOT registered in OpsDB |
| **Pattern** | DELETE-INSERT by Date |
| **eToro Source** | Dealing_dbo.Dealing_Duco_ActivityRecon |
| **LP Source** | Dealing_staging.LP_IB_I1893329_Daily_Trades |
