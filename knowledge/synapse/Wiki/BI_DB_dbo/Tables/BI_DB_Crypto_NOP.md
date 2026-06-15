# BI_DB_dbo.BI_DB_Crypto_NOP

## 1. Overview

Daily **instrument-level crypto net open position (NOP)** and related units, equity, and customer-segment dimensions. Rows aggregate all open crypto positions (`InstrumentTypeID = 10` via `BI_DB_PositionPnL` / `Dim_Instrument`) across customers for each combination of regulation, label, instrument, buy direction, leverage, MiFID bucket, account type, player level, status, country, new-user flag, Tangany custodian status, and DLT flag. Used for finance reporting on crypto exposure by instrument and regulatory slice.

**Row grain**: One row per `Date` + `Regulation` + `Label` + `InstrumentID` + `IsBuy` + `Leverage` + customer-classification dimensions + `CountryName` + `NewUsers` + `TanganyStatus` + `IsDLTUser` (see `GROUP BY` in `#NOP_1` / `#NOP_2` in `SP_Crypto_NOP`).

**Live check (prod Synapse `sql_dp_prod_we`, 2026-03-20)**: `SELECT TOP 5 * ... ORDER BY Date DESC` shows latest `Date` **2026-03-19** with pairs such as **STRK/USD**, **BONKxM/USD**; recent samples often show **CFD_NOP** = 0 and **TRS_NOP** / **TRS_Units** = 0 when positions are fully real-settled with no TRS leg. **Total_NOP_ReversedUnits** is frequently **NULL** when the reversed-pair **BidSpreaded** join does not produce a price. Table row count **~289.8M** (`COUNT(*)`). Seven-day Regulation volume is dominated by **CySEC**, then **FCA**, **FSA Seychelles**, **ASIC & GAML**, etc. **TanganyStatus** is mostly **NULL** in the window; common non-null values include **Inactive**, **MicaCustomer**, **Customer**, **Internal**, **ConsentCustomer**. **IsBuy** = 1 rows far outnumber **IsBuy** = 0 in the last seven days.

---

## 2. Business Context

- **NOP**: Net open position in notional terms. **Real_NOP** / **CFD_NOP** / **TRS_NOP** split by settlement: settled real (`IsSettled = 1`), CFD (`IsSettled = 0`), TRS (`SettlementTypeID = 2`). **Total_NOP** in the NOP table is `CFD_NOP + Real_NOP` (TRS is tracked separately in TRS_* columns).
- **Units**: **Real_Units**, **CFD_Units**, **TRS_Units**, **Total_Units** sum `AmountInUnitsDecimal` under the same settlement rules as NOP.
- **Equity***: **EquityReal**, **EquityCFD**, **EquityTRS** are rounded sums of position amount + P&amp;L from open positions as of `@Date`.
- **ETH/USD staking split**: Non-ETH instruments use **#opt_out_general** (staking waiver / opt-out program) for **Real_Units_Staking_OptIn** vs **Real_Units_Staking_OptOut**; ETH/USD uses **#opt_in_ETH** with inverted opt-in/opt-out assignment (see SP branches `#NOP_1` vs `#NOP_2`).
- **Total_NOP_ReversedUnits**: NOP expressed in “reversed” quote units using **BidSpreaded** from the **#reversed_units** join (USD/crypto pair) when `InstrumentTypeID = 10`, else 0; live samples often **NULL** when no matching reversed price row exists.
- **NewUsers**: Customers with `Dim_Customer.RegisteredReal` on or after `2022-02-08` (regulatory cutoff in SP).
- **IsDLTUser**: `1` when `Fact_SnapshotCustomer.DltStatusID = 4`, else `0`; live 7-day counts show **IsDLTUser** = 1 as a minority slice.

**Sibling table**: `BI_DB_Crypto_NOP_CID` (customer + instrument name grain, same SP).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 38 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | `Date` ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | NO | As-of business date for the load; equals SP parameter `@Date`. Live samples show daily loads through **2026-03-19**. (Tier 2 -SP_Crypto_NOP, @Date) |
| 2 | Regulation | varchar(50) | YES | Regulation name from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID` in `#fsc`. Live 7-day data: highest row counts **CySEC**, **FCA**, **FSA Seychelles**, **ASIC & GAML**, **FSRA**, **FinCEN+FINRA**, **BVI**, **ASIC**, **FinCEN**, **eToroUS**. (Tier 2 -SP_Crypto_NOP, Dim_Regulation.Name) |
| 3 | Label | varchar(50) | NO | Broker / entity label from `Dim_Label.Name` via `Fact_SnapshotCustomer.LabelID`. Live 7-day: **eToro** dominates; smaller volumes include **eToroRussia**, **ILQ**, **Royal-CM**, **JCLyons**, **eToroUSA**, **Dealing**, **ICMarkets**, **eToroChina**, **RetailFX**. (Tier 2 -SP_Crypto_NOP, Dim_Label.Name) |
| 4 | InstrumentID | int | NO | Crypto instrument key; filtered to `Dim_Instrument.InstrumentTypeID = 10` in `#pnl_posDist`. (Tier 2 -SP_Crypto_NOP, Dim_Instrument.InstrumentID) |
| 5 | InstrumentName | varchar(50) | NO | Instrument display name from `BI_DB_PositionPnL` / `Dim_Instrument.Name`. Live 7-day row counts top instruments include **BTC/USD**, **ETH/USD**, **XRP/USD**, **ADA/USD**, **SOL/USD**, **DOGE/USD**, **XLM/USD**, **TRX/USD**, **SHIBxM/USD**, **LINK/USD**. (Tier 2 -SP_Crypto_NOP, Dim_Instrument.Name) |
| 6 | Real_NOP | numeric(38,6) | YES | Sum of NOP on settled real positions (`IsSettled = 1`) from `#pos_new`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 7 | CFD_NOP | numeric(38,6) | YES | Sum of NOP on CFD positions (`IsSettled = 0`). (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 8 | Total_NOP | numeric(38,6) | YES | `SUM(NOP_CFD) + SUM(NOP_Real)` at instrument grain; does not add TRS into this field. (Tier 2 -SP_Crypto_NOP, computed) |
| 9 | Real_Units | decimal(38,6) | YES | Sum of `AmountInUnitsDecimal` where `IsSettled = 1`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 10 | CFD_Units | decimal(38,6) | YES | Sum of `AmountInUnitsDecimal` where `IsSettled = 0`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 11 | Total_Units | decimal(38,6) | YES | Sum of all `AmountInUnitsDecimal` for the grain. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 12 | EOD_Bid_Price | numeric(36,12) | YES | End-of-day bid (spreaded) from `Fact_CurrencyPriceWithSplit.BidSpreaded` for the instrument on `@DateID`; `MAX` in aggregate. (Tier 2 -SP_Crypto_NOP, Fact_CurrencyPriceWithSplit.BidSpreaded) |
| 13 | UpdateDate | datetime | NO | Row load timestamp. `GETDATE()` at insert. (Tier 3 -SP_Crypto_NOP, GETDATE()) |
| 14 | Leverage | int | YES | Position leverage from `BI_DB_PositionPnL` / `#pos`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.Leverage) |
| 15 | EquityCFD | money | YES | Rounded sum of CFD equity (`Amount + PositionPnL` when `IsSettled = 0`). (Tier 2 -SP_Crypto_NOP, computed) |
| 16 | EquityReal | money | YES | Rounded sum of real equity (`Amount + PositionPnL` when `IsSettled = 1`). (Tier 2 -SP_Crypto_NOP, computed) |
| 17 | IsBuy | bit | YES | Position direction from open snapshot (`Dim_Position` / `#pos`). Live 7-day: rows with **IsBuy** = 1 greatly exceed **IsBuy** = 0. (Tier 2 -SP_Crypto_NOP, Dim_Position.IsBuy) |
| 18 | MifidCategorizationID | int | YES | MiFID categorization key from `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.MifidCategorizationID) |
| 19 | MifidCategorization | char(50) | YES | MiFID categorization name from `Dim_MifidCategorization.Name`. (Tier 2 -SP_Crypto_NOP, Dim_MifidCategorization.Name) |
| 20 | AccountTypeID | int | YES | Account type key from `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.AccountTypeID) |
| 21 | AccountType | char(50) | YES | Account type name from `Dim_AccountType.Name`. (Tier 2 -SP_Crypto_NOP, Dim_AccountType.Name) |
| 22 | PlayerLevelID | int | YES | Player level key from `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerLevelID) |
| 23 | Club | char(50) | YES | Club name from `Dim_PlayerLevel.Name`. (Tier 2 -SP_Crypto_NOP, Dim_PlayerLevel.Name) |
| 24 | PlayerStatusID | int | YES | Player status key from `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerStatusID) |
| 25 | PlayerStatus | char(50) | YES | Player status name from `Dim_PlayerStatus.Name`. (Tier 2 -SP_Crypto_NOP, Dim_PlayerStatus.Name) |
| 26 | IsGermanBaFin | bit | YES | `1` if customer appears in `BI_DB_dbo.V_GermanBaFin` for `@DateID`. (Tier 2 -SP_Crypto_NOP, V_GermanBaFin) |
| 27 | IsCreditReportValidCB | bit | YES | Credit report validity flag from `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 28 | Total_NOP_ReversedUnits | decimal(16,6) | YES | `Total_NOP / BidSpreaded` when `Dim_Instrument.InstrumentTypeID = 10`, else 0; **BidSpreaded** from **#reversed_units** (USD leg price). Often **NULL** in live samples when the reversed-pair price is missing. (Tier 2 -SP_Crypto_NOP, computed) |
| 29 | CountryName | varchar(50) | YES | Country from `Dim_Country.Name` via `Fact_SnapshotCustomer.CountryID`. (Tier 2 -SP_Crypto_NOP, Dim_Country.Name) |
| 30 | NewUsers | bit | YES | `1` when `Dim_Customer.RegisteredReal >= '2022-02-08'`, else `0`. (Tier 2 -SP_Crypto_NOP, Dim_Customer.RegisteredReal) |
| 31 | BuyCurrency | varchar(50) | YES | Instrument buy currency from `Dim_Instrument.BuyCurrency` (joined on final insert); live rows show codes such as **STRK**, **BONKxM** aligned to the pair. (Tier 2 -SP_Crypto_NOP, Dim_Instrument.BuyCurrency) |
| 32 | TRS_NOP | money | YES | Sum of NOP where `SettlementTypeID = 2`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 33 | TRS_Units | numeric(16,6) | YES | Sum of units where `SettlementTypeID = 2`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 34 | EquityTRS | money | YES | Rounded sum of TRS equity (`Amount + PositionPnL` when `SettlementTypeID = 2`). (Tier 2 -SP_Crypto_NOP, computed) |
| 35 | TanganyStatus | varchar(20) | YES | Custodian status label from `External_UserApiDB_Dictionary_TanganyStatus.Name` via `Dim_Customer.TanganyStatusID`. Live 7-day: mostly **NULL**; non-null top values **Inactive**, **MicaCustomer**, **Customer**, **Internal**, **ConsentCustomer**. (Tier 2 -SP_Crypto_NOP, External_UserApiDB_Dictionary_TanganyStatus.Name) |
| 36 | Real_Units_Staking_OptIn | decimal(38,6) | YES | Subset of real units per crypto staking enrolment rules (branch differs for ETH/USD vs other pairs); live rows show split vs **Real_Units_Staking_OptOut** summing to **Real_Units** where applicable. (Tier 2 -SP_Crypto_NOP, computed) |
| 37 | Real_Units_Staking_OptOut | decimal(38,6) | YES | Complement slice of real units for staking opt-in/out logic. (Tier 2 -SP_Crypto_NOP, computed) |
| 38 | IsDLTUser | int | YES | DLT user flag: `1` if `DltStatusID = 4` on snapshot customer, else `0`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.DltStatusID) |

---

## 5. Relationships

### Primary upstream objects

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Open crypto positions and NOP/units as of `DateID` |
| Dim_Position | DWH_dbo | Open through `@DateID`, settlement flags, join to position metadata |
| Dim_Instrument | DWH_dbo | Crypto filter, names, currencies |
| Fact_CurrencyPriceWithSplit | DWH_dbo | EOD bid and reversed-pair prices |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, label, MiFID, account, player, country, DLT |
| Dim_Customer | DWH_dbo | Registration date, Tangany status id |
| V_GermanBaFin | BI_DB_dbo | German BaFin customer set |
| External_USABroker_*_UserProgramEnrolment | BI_DB_dbo | Staking opt-in/out programs |

### Sibling table

| Table | Relationship |
|-------|----------------|
| BI_DB_Crypto_NOP_CID | Same SP; grain includes `CID` and `InstrumentName`, adds invested amounts |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_Crypto_NOP` |
| **ETL Pattern** | `DELETE` by `Date`, then `INSERT` |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS (OpsDB) |
| **Parameter** | `@Date` (DATE) |
| **Delete Scope** | `DELETE FROM BI_DB_Crypto_NOP WHERE [Date] = @Date` |
| **Logging** | `SP_ProcessStatusLog` Start / Completed |

---

## 7. Query Advisory

| Topic | Guidance |
|-------|-----------|
| **Filter on Date** | Clustered on `Date`; always constrain `Date` for performance. |
| **Total_NOP vs TRS** | **Total_NOP** is real+CFD NOP only; include **TRS_NOP** / **EquityTRS** for full TRS exposure. |
| **High cardinality** | Many dimensions in the grain; expect wide sparse combinations. |
| **PII / compliance** | Country and segmentation fields are sensitive in aggregate reporting contexts. |
| **Reserved word** | Quote **`[Label]`** in ad-hoc SQL when filtering or grouping. |
| **Row counts** | `COUNT(*)` fits **INT** for this table (~290M); sibling **BI_DB_Crypto_NOP_CID** requires **`COUNT_BIG(*)`** (see sibling wiki). |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Crypto |
| **Sub-domain** | NOP by instrument |
| **Sensitivity** | Aggregated; segment attributes may be regulated |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
