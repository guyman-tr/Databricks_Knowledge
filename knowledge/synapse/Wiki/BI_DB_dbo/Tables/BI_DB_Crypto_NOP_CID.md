# BI_DB_dbo.BI_DB_Crypto_NOP_CID

## 1. Overview

Daily **customer-level crypto net open position (NOP)** with **instrument name** on each row, plus invested amounts (initial margin / notional invested) by settlement type. Built from the same open-position pipeline as `BI_DB_Crypto_NOP` but aggregated in `#NOP_CID` so each row ties a **CID** to a crypto **InstrumentName** under a regulation / label and the same customer segmentation dimensions used in the instrument-level table.

**Row grain**: One row per `Date` + `Regulation` + `Label` + `CID` + `IsBuy` + `InstrumentName` + MiFID / account / player / BaFin / credit / Tangany / DLT attributes (see final `GROUP BY` on insert from `#NOP_CID`).

**Live check (prod Synapse `sql_dp_prod_we`, 2026-03-20)**: `SELECT TOP 5 * ... ORDER BY Date DESC` shows **Date** **2026-03-19** with **CID** populated (e.g. 46993470, 46975669), pairs such as **STORJ/USD**, **ANKR/USD**, **BTC/USD**, **ETH/USD**, **XRP/USD**; **`InstrumentName`** is **`char(50)`** and appears **space-padded** in raw results. **Invested** columns align with small retail notionals (e.g. **Real_Invested_Amount** ~10 on sample rows). **TanganyStatus** often **NULL** in samples. **Real_Units_Staking_OptIn** / **OptOut** split matches sibling staking logic (e.g. ANKR row all OptOut, STORJ all OptIn). Row cardinality is very large: plain **`COUNT(*)` overflows SQL Server `int`** on this table; use **`COUNT_BIG(*)`** (live **`COUNT_BIG`** ~ **10,994,496,664** as of verification run). Seven-day Regulation row counts are led by **CySEC**, **FCA**, **FinCEN+FINRA**, **FSA Seychelles**, **ASIC & GAML**, etc.

---

## 2. Business Context

- **NOP and units**: **Real_NOP**, **CFD_NOP**, **TRS_NOP**, **Total_NOP** (real+CFD), **Real_Units**, **CFD_Units**, **TRS_Units**, **Total_Units** follow the same settlement rules as `BI_DB_Crypto_NOP` (`IsSettled`, `SettlementTypeID`).
- **Invested amounts**: **Real_Invested_Amount**, **CFD_Invested_Amount**, **TRS_Invested_Amount**, **Total_Invested_Amount** sum `Dim_Position.InitialAmountCents/100` (`InitialAmount` in `#pos`) under the same settlement splits.
- **Equity***: **EquityReal**, **EquityCFD**, **EquityTRS** are rounded sums of position equity components for the grain.
- **ETH/USD staking**: Same dual-branch logic as the instrument table (**#NOP_CID_1** vs **#NOP_CID_2**) with **#opt_out_general** vs **#opt_in_ETH**.
- **Delete scope**: Only `WHERE [Date] = @Date` (historical rows are no longer purged on a 7-day rule per SP change log).

**Sibling table**: `BI_DB_Crypto_NOP` (instrument-level aggregate across customers).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 36 |
| **Distribution** | HASH(`CID`) |
| **Clustered Index** | `Date` ASC, `CID` ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | NO | As-of business date; SP `@Date`. Live samples **2026-03-19**. (Tier 2 -SP_Crypto_NOP, @Date) |
| 2 | Regulation | varchar(50) | YES | Regulation name from `Dim_Regulation.Name` via `#fsc`. Live 7-day: **CySEC**, **FCA**, **FinCEN+FINRA**, **FSA Seychelles**, **ASIC & GAML** lead by row count. (Tier 2 -SP_Crypto_NOP, Dim_Regulation.Name) |
| 3 | Label | varchar(50) | NO | Label from `Dim_Label.Name` via `#fsc`. (Tier 2 -SP_Crypto_NOP, Dim_Label.Name) |
| 4 | CID | int | YES | Customer identifier (`Fact_SnapshotCustomer` / position `CID`). Live samples show populated integer **CID** values. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.CID) |
| 5 | Real_NOP | numeric(38,6) | YES | Sum of NOP for settled real positions. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 6 | CFD_NOP | numeric(38,6) | YES | Sum of NOP for CFD positions. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 7 | Total_NOP | numeric(38,6) | YES | `SUM(NOP_CFD) + SUM(NOP_Real)`; TRS held in **TRS_NOP**. (Tier 2 -SP_Crypto_NOP, computed) |
| 8 | Real_Units | decimal(38,6) | YES | Real units (`IsSettled = 1`). (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 9 | Real_Invested_Amount | money | YES | Sum of `InitialAmount` where `IsSettled = 1`. (Tier 2 -SP_Crypto_NOP, Dim_Position.InitialAmountCents) |
| 10 | CFD_Invested_Amount | money | YES | Sum of `InitialAmount` where `IsSettled = 0`. (Tier 2 -SP_Crypto_NOP, Dim_Position.InitialAmountCents) |
| 11 | Total_Invested_Amount | money | YES | Sum of `InitialAmount` across settlement types at grain. (Tier 2 -SP_Crypto_NOP, Dim_Position.InitialAmountCents) |
| 12 | UpdateDate | datetime | NO | `GETDATE()` on insert. (Tier 3 -SP_Crypto_NOP, GETDATE()) |
| 13 | IsBuy | bit | YES | Position direction. (Tier 2 -SP_Crypto_NOP, Dim_Position.IsBuy) |
| 14 | EquityReal | money | YES | Rounded sum of real equity. (Tier 2 -SP_Crypto_NOP, computed) |
| 15 | EquityCFD | money | YES | Rounded sum of CFD equity. (Tier 2 -SP_Crypto_NOP, computed) |
| 16 | InstrumentName | char(50) | YES | Crypto pair name from position / `Dim_Instrument`; **fixed width** -- expect trailing spaces in raw T-SQL output and trim in consuming apps. (Tier 2 -SP_Crypto_NOP, Dim_Instrument.Name) |
| 17 | MifidCategorizationID | int | YES | From `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.MifidCategorizationID) |
| 18 | MifidCategorization | char(50) | YES | From `Dim_MifidCategorization.Name`. (Tier 2 -SP_Crypto_NOP, Dim_MifidCategorization.Name) |
| 19 | AccountTypeID | int | YES | From `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.AccountTypeID) |
| 20 | AccountType | char(50) | YES | From `Dim_AccountType.Name`. (Tier 2 -SP_Crypto_NOP, Dim_AccountType.Name) |
| 21 | PlayerLevelID | int | YES | From `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerLevelID) |
| 22 | Club | char(50) | YES | From `Dim_PlayerLevel.Name`. (Tier 2 -SP_Crypto_NOP, Dim_PlayerLevel.Name) |
| 23 | PlayerStatusID | int | YES | From `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerStatusID) |
| 24 | PlayerStatus | char(50) | YES | From `Dim_PlayerStatus.Name`. (Tier 2 -SP_Crypto_NOP, Dim_PlayerStatus.Name) |
| 25 | IsGermanBaFin | bit | YES | German BaFin flag from `V_GermanBaFin`. (Tier 2 -SP_Crypto_NOP, V_GermanBaFin) |
| 26 | IsCreditReportValidCB | bit | YES | From `Fact_SnapshotCustomer`. (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 27 | TRS_NOP | money | YES | NOP where `SettlementTypeID = 2`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.NOP) |
| 28 | TRS_Units | numeric(16,6) | YES | Units where `SettlementTypeID = 2`. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 29 | TRS_Invested_Amount | money | YES | Sum of `InitialAmount` for TRS. (Tier 2 -SP_Crypto_NOP, Dim_Position.InitialAmountCents) |
| 30 | EquityTRS | money | YES | Rounded sum of TRS equity. (Tier 2 -SP_Crypto_NOP, computed) |
| 31 | CFD_Units | numeric(16,6) | YES | CFD units. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 32 | Total_Units | numeric(16,6) | YES | All units. (Tier 2 -SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 33 | TanganyStatus | varchar(20) | YES | Tangany dictionary label via `Dim_Customer.TanganyStatusID`; frequently **NULL** in live samples. (Tier 2 -SP_Crypto_NOP, External_UserApiDB_Dictionary_TanganyStatus.Name) |
| 34 | Real_Units_Staking_OptIn | decimal(38,6) | YES | Staking opt-in slice of real units (ETH vs non-ETH branch); live rows show complement vs **Real_Units_Staking_OptOut**. (Tier 2 -SP_Crypto_NOP, computed) |
| 35 | Real_Units_Staking_OptOut | decimal(38,6) | YES | Staking opt-out slice of real units. (Tier 2 -SP_Crypto_NOP, computed) |
| 36 | IsDLTUser | int | YES | DLT flag from snapshot (`DltStatusID = 4`). (Tier 2 -SP_Crypto_NOP, Fact_SnapshotCustomer.DltStatusID) |

---

## 5. Relationships

### Primary upstream objects

Same core chain as `BI_DB_Crypto_NOP`: `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`, `Fact_SnapshotCustomer` and related dims, `Dim_Customer`, `V_GermanBaFin`, staking enrolment tables, Tangany dictionary.

### Sibling table

| Table | Relationship |
|-------|----------------|
| BI_DB_Crypto_NOP | Instrument-level rollup; no `CID`; adds EOD price, leverage, reversed NOP, `BuyCurrency`, `CountryName`, `NewUsers` at instrument grain |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_Crypto_NOP` |
| **ETL Pattern** | `DELETE` by `Date`, then `INSERT` |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS (OpsDB) |
| **Parameter** | `@Date` (DATE) |
| **Delete Scope** | `DELETE FROM BI_DB_Crypto_NOP_CID WHERE [Date] = @Date` |

---

## 7. Query Advisory

| Topic | Guidance |
|-------|-----------|
| **Distribution** | HASH(`CID`) -- filter or join on `CID` when possible for colocation. |
| **Clustered index** | Lead with `Date`, then `CID` for typical “one customer, one day” pulls. |
| **PII** | **CID** is direct customer id -- restrict access. |
| **InstrumentName** | Same customer can have multiple rows per day (one per instrument + direction + segment combo). Trim **`RTRIM(InstrumentName)`** for comparisons because type is **`char(50)`**. |
| **Row counts** | Use **`COUNT_BIG(*)`** -- `COUNT(*)` can raise **arithmetic overflow** to `int` on full table scans due to cardinality. |
| **Reserved word** | Quote **`[Label]`** in ad-hoc SQL when grouping or filtering. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Crypto |
| **Sub-domain** | NOP by customer and instrument |
| **Sensitivity** | **CID** present -- PII |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
