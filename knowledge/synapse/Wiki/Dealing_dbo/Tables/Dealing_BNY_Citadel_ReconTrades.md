# Dealing_dbo.Dealing_BNY_Citadel_ReconTrades

## 1. Overview

**Daily trade reconciliation** comparing executed trade activity across three counterparties — BNY Mellon (BNY), Citadel Securities, and eToro's hedge positions — for Real Stocks instruments. Each row represents a single instrument-direction-date combination, placing the LP-reported units/amounts side-by-side with eToro internal data and computing arithmetic differences.

**Row grain**: `Date` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_BNY_VIRTU_Recon` (Author: Gili Goldbaum, 2023-11-06) is the shared writer for all four BNY/VIRTU/Citadel reconciliation output tables. It runs every weekday (skips Saturday) via the **SB_Daily** Service Broker pipeline.

**Reconciliation flow**:

1. **eToro side** — pulled from `Dealing_Duco_ActivityRecon` (trades) for HedgeServerIDs mapped to BNY accounts via `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` (liquidity_provider LIKE '%-BNY').
2. **BNY side** — from `Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions` (BNY trade reports).
3. **Citadel side** — from `Dealing_staging.LP_Citadel_eToro_Confirm` (Citadel trade confirmations).
4. **Join key**: ISIN + currency + Buy/Sell direction.
5. **Output**: Three-way comparison with diff columns `{LP}-eToro_`* and `{LP}-Clients_*`.

**Business rules**:

- Runs Monday–Friday only; Sunday triggers Friday date fallback (DATEADD logic).
- GBX instruments: LocalAmount divided by 100 to normalise to GBP.
- DELETE-INSERT by date — idempotent daily reload.
- Scope: Real Stocks only (`activity = 'Stocks - Real'`).

**Data currency**: Active daily as of 2026-03-10.

---

## 3. Structure


| Property            | Value       |
| ------------------- | ----------- |
| **Schema**          | Dealing_dbo |
| **Object Type**     | USER_TABLE  |
| **Columns**         | 41          |
| **Distribution**    | ROUND_ROBIN |
| **Clustered Index** | Date ASC    |


---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.


| Check          | Result                                       |
| -------------- | -------------------------------------------- |
| **Row count**  | ~97,357                                      |
| **Date range** | Active and current (most recent: 2026-03-10) |
| **Activity**   | 100% "Stocks - Real"                         |


---

## 5. Elements


| #   | Column                    | Type          | Nullable | Description                                                                                                                        |
| --- | ------------------------- | ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Date                      | date          | YES      | Report date — the trade activity date being reconciled. (Tier 2 — SP_BNY_VIRTU_Recon, @TotalDate)                                  |
| 2   | Account_Number            | int           | YES      | BNY custodian account number (from LP file). NULL when record originates from eToro side only.                                     |
| 3   | InstrumentID              | int           | YES      | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument.                                                                          |
| 4   | InstrumentDisplayName     | varchar(100)  | YES      | Human-readable instrument name (e.g., "NaaS Technology Inc"). Populated from eToro side; falls back to LP side when eToro is NULL. |
| 5   | Symbol                    | varchar(250)  | YES      | Ticker symbol (e.g., "NAAS"). Preferentially populated from eToro side.                                                            |
| 6   | ISINCode                  | varchar(250)  | YES      | International Securities Identification Number. Primary join key used to match BNY/Citadel data to eToro records.                  |
| 7   | Buy/Sell                  | varchar(100)  | YES      | Trade direction: 'Buy' or 'Sell'. Inherited from eToro side; falls back to LP side.                                                |
| 8   | CurrencyPrimary           | varchar(50)   | YES      | Instrument local currency. GBX instruments are normalised to 'GBP' in amounts.                                                     |
| 9   | Exchange                  | varchar(80)   | YES      | Trading venue/exchange (e.g., "Nasdaq", "FRA").                                                                                    |
| 10  | BNY_Units                 | decimal(16,6) | YES      | Trade units reported by BNY. Positive = buy; negative = sell. (Tier 2 — LP_BNY_Custody_Security_Transactions)                      |
| 11  | Citadel_Units             | decimal(16,6) | YES      | Trade units reported by Citadel Securities. (Tier 2 — LP_Citadel_eToro_Confirm)                                                    |
| 12  | eToro_Units               | decimal(16,6) | YES      | Trade units recorded in eToro's hedge activity (Duco ActivityRecon). (Tier 1 — Dealing_Duco_ActivityRecon.eToro_Units)             |
| 13  | Clients_Units             | decimal(16,6) | YES      | Aggregated client NOP units from eToro internal systems. (Tier 1 — Dealing_Duco_ActivityRecon.ClientUnits)                         |
| 14  | BNY-eToro_Units           | decimal(16,6) | YES      | **Reconciliation diff**: BNY_Units − eToro_Units. Zero = perfect match; non-zero = discrepancy requiring investigation.            |
| 15  | BNY-Clients_Units         | decimal(16,6) | YES      | BNY_Units − Clients_Units. Compares LP reported trade against client-side activity.                                                |
| 16  | Citadel-eToro_Units       | decimal(16,6) | YES      | Citadel_Units − eToro_Units. Reconciliation diff for Citadel counterparty.                                                         |
| 17  | Citadel-Clients_Units     | decimal(16,6) | YES      | Citadel_Units − Clients_Units.                                                                                                     |
| 18  | BNY_LocalAmount           | money         | YES      | Trade notional in local currency as reported by BNY.                                                                               |
| 19  | Citadel_LocalAmount       | money         | YES      | Trade notional in local currency as reported by Citadel.                                                                           |
| 20  | eToro_LocalAmount         | money         | YES      | eToro's recorded local amount for the trade. GBX normalised ÷100.                                                                  |
| 21  | BNY-eToro_LocalAmount     | money         | YES      | BNY_LocalAmount − eToro_LocalAmount.                                                                                               |
| 22  | Citadel-eToro_LocalAmount | money         | YES      | Citadel_LocalAmount − eToro_LocalAmount.                                                                                           |
| 23  | BNY_AmountUSD             | money         | YES      | Trade notional in USD as reported by BNY.                                                                                          |
| 24  | Citadel_AmountUSD         | money         | YES      | Trade notional in USD as reported by Citadel.                                                                                      |
| 25  | eToro_AmountUSD           | money         | YES      | eToro USD notional.                                                                                                                |
| 26  | Clients_AmountUSD         | money         | YES      | Client position notional in USD.                                                                                                   |
| 27  | BNY-eToro_AmountUSD       | money         | YES      | BNY_AmountUSD − eToro_AmountUSD.                                                                                                   |
| 28  | BNY-Clients_AmountUSD     | money         | YES      | BNY_AmountUSD − Clients_AmountUSD.                                                                                                 |
| 29  | Citadel-eToro_AmountUSD   | money         | YES      | Citadel_AmountUSD − eToro_AmountUSD.                                                                                               |
| 30  | Citadel-Clients_AmountUSD | money         | YES      | Citadel_AmountUSD − Clients_AmountUSD.                                                                                             |
| 31  | BNY_Rate                  | decimal(16,6) | YES      | Trade price per unit as reported by BNY (in local currency).                                                                       |
| 32  | Citadel_Rate              | decimal(16,6) | YES      | Trade price per unit as reported by Citadel.                                                                                       |
| 33  | eToro_Rate                | decimal(16,6) | YES      | eToro average trade rate per unit.                                                                                                 |
| 34  | BNY-eToro_Rate            | decimal(16,6) | YES      | BNY_Rate − eToro_Rate. Price discrepancy between counterparties.                                                                   |
| 35  | Citadel-eToro_Rate        | decimal(16,6) | YES      | Citadel_Rate − eToro_Rate.                                                                                                         |
| 36  | BNY_FXRate                | decimal(16,6) | YES      | FX rate (local → USD) used by BNY for this trade.                                                                                  |
| 37  | Citadel_FXRate            | decimal(16,6) | YES      | FX rate used by Citadel.                                                                                                           |
| 38  | eToro_FXRate              | decimal(16,6) | YES      | FX rate used by eToro.                                                                                                             |
| 39  | BNY-eToro_Rate            | decimal(16,6) | YES      | BNY FX rate − eToro FX rate.                                                                                                       |
| 40  | UpdateDate                | datetime      | YES      | ETL metadata: timestamp when this row was last updated by the ETL pipeline.                                                        |
| 41  | activity                  | varchar(100)  | YES      | Product type tag — always 'Stocks - Real' in this table. Inherited from Fivetran HS mapping.                                       |


---

## 6. Relationships


| Relationship              | Object                                                                           | Join Columns                              |
| ------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------- |
| Upstream (eToro data)     | [Dealing_Duco_ActivityRecon](Dealing_Duco_ActivityRecon.md)                      | HedgeServerID + LiquidityAccountID + Date |
| Upstream (instrument dim) | DWH_dbo.Dim_Instrument                                                           | InstrumentID                              |
| Upstream (LP data)        | Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions | ISINCode                                  |
| Upstream (LP data)        | Dealing_staging.LP_Citadel_eToro_Confirm                                         | ISINCode                                  |
| Sibling (EOD holdings)    | [Dealing_BNY_VIRTU_ReconEODHolding](Dealing_BNY_VIRTU_ReconEODHolding.md)        | Same SP_BNY_VIRTU_Recon                   |
| Sibling (detailed source) | [Dealing_BNY_Detailed](Dealing_BNY_Detailed.md)                                  | Same SP_BNY_VIRTU_Recon                   |


---

## 7. ETL / Lineage


| Property           | Value                                                                                                                                        |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Writer**         | `Dealing_dbo.SP_BNY_VIRTU_Recon`                                                                                                             |
| **Schedule**       | Daily (SB_Daily), weekdays only (not Saturday)                                                                                               |
| **OpsDB Priority** | N/A (not registered individually; runs as part of BNY/VIRTU Recon job)                                                                       |
| **Pattern**        | DELETE-INSERT by Date                                                                                                                        |
| **eToro Source**   | Dealing_dbo.Dealing_Duco_ActivityRecon                                                                                                       |
| **LP Sources**     | Dealing_staging.LP_BNY_Custody_Security_Transactions_CustodySecurityTransactions, LP_Citadel_eToro_Confirm, LP_VIRTU_ETORO_Allocations_Sheet |


---

## 8. Usage Notes

- Use the `{LP}-eToro_`* diff columns to identify reconciliation breaks: a non-zero `BNY-eToro_Units` or `Citadel-eToro_Units` value flags a trade that needs investigation.
- `Account_Number` identifies which BNY custody account (sub-account of the prime brokerage relationship) the LP data came from.
- The three-way structure (BNY, Citadel, eToro) allows the Dealing team to cross-verify LP confirmations: if BNY and Citadel agree but eToro differs, the issue is internal; if both LPs differ, it may be an LP reporting issue.

