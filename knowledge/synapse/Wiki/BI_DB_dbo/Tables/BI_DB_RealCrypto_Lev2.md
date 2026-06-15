# BI_DB_dbo.BI_DB_RealCrypto_Lev2

## 1. Overview

Daily **position-level finance extract for real crypto with 2× leverage** (`Leverage = 2`, `IsBuy = 1`, `IsSettled = 1` on `BI_DB_PositionPnL`). Each load stores two logical row types per qualifying position: an **`OpenPosition`** snapshot and zero or more **`RollOverFee`** rows (action type 35 on the report date). **`TotalRollOverFee`** on `OpenPosition` rows is back-filled as the **cumulative rollover fee** for that `PositionID` across all stored `RollOverFee` rows with `Date <= @dd`.

**Row grain**: One row per (`Date`, `PositionID`, `Indicator`) tuple inserted from `#temp`; `OpenPosition` rows pair with aggregated `TotalRollOverFee`.

---

## 2. Business Context

Used by **finance** to monitor **leveraged real crypto** exposure and **loan/credit** style amounts. Population is driven from **`BI_DB_PositionPnL`** (same-day `DateID`) restricted to **`Dim_Instrument.InstrumentTypeID = 10`** (real crypto). Customer attributes (`MiFID`, account type, club, player status, BaFin flag, CB validity) come from the **`Fact_SnapshotCustomer`** slice active on `@dd`.

**Key business rules** (from `SP_RealCrypto_Lev2`):
- **Filters on PositionPnL**: `DateID = @ddINT`, `IsBuy = 1`, `Leverage = 2`, `IsSettled = 1`.
- **Loan-style initial amount**: Start from `PositionPnL.Amount`, then **subtract** the latest cumulative **edit stop loss** impact (`Fact_CustomerAction.ActionTypeID = 32`) through `@ddINT`.
- **Indicators**: `'OpenPosition'` (position state) and `'RollOverFee'` (per-day rollover fee from `ActionTypeID = 35` on `@ddINT`).
- **RollOverFee sign**: `ISNULL(-fca.Amount, 0)` on fee actions.
- **TotalRollOverFee**: `SUM(RollOverFee)` over prior `Indicator = 'RollOverFee'` rows in this table for the same `PositionID` with `Date <= @dd`, written back to `OpenPosition` rows only.
- **Load**: `DELETE WHERE Date = @dd` then `INSERT` from `#temp`; second pass `UPDATE` for `TotalRollOverFee`.

**Related**: `BI_DB_Real_Crypto_Loan` is instrument-level month-end aggregate; this table is **daily position detail** for x2 real crypto.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 30 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date parameter `@dd` applied to every inserted row. (Tier 2 -SP_RealCrypto_Lev2, @dd) |
| 2 | CID | int | YES | Customer ID from the position snapshot. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.CID) |
| 3 | Indicator | varchar(25) | YES | Row role: `OpenPosition` (state) or `RollOverFee` (fee event on report date). (Tier 2 -SP_RealCrypto_Lev2, literal.OpenPosition / RollOverFee) |
| 4 | Regulation | varchar(50) | YES | Customer regulation name from snapshot. (Tier 2 -SP_RealCrypto_Lev2, Dim_Regulation.Name) |
| 5 | Country | varchar(100) | YES | Customer country name. (Tier 2 -SP_RealCrypto_Lev2, Dim_Country.Name) |
| 6 | Region | varchar(100) | YES | Customer region from country dimension. (Tier 2 -SP_RealCrypto_Lev2, Dim_Country.Region) |
| 7 | PositionID | bigint | YES | Platform position identifier. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.PositionID) |
| 8 | OpenPosDate | date | YES | Calendar date of position occurrence from PositionPnL. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.Occurred) |
| 9 | InstrumentID | int | YES | Crypto instrument id; restricted to type 10 in SP. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.InstrumentID) |
| 10 | InstrumentDisplayName | varchar(250) | YES | Instrument display label. (Tier 2 -SP_RealCrypto_Lev2, Dim_Instrument.InstrumentDisplayName) |
| 11 | Units | decimal(16,6) | YES | Position size in units (`AmountInUnitsDecimal`). (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 12 | Leverage | smallint | YES | Always **2** in filter; passthrough from PositionPnL. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.Leverage) |
| 13 | InitialAmount | money | YES | Starting from `PositionPnL.Amount`, reduced by cumulative **edit stop loss** adjustments (`ActionTypeID = 32`) through report date. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.Amount minus Fact_CustomerAction.ActionTypeID=32) |
| 14 | Amount | money | YES | Position amount from `BI_DB_PositionPnL.Amount`; **not** reduced by the edit stop-loss adjustment (only `InitialAmount` is updated). (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.Amount) |
| 15 | PositionPnL | money | YES | Mark-to-market PnL from PositionPnL. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.PositionPnL) |
| 16 | NOP | money | YES | Net open position metric from PositionPnL. (Tier 2 -SP_RealCrypto_Lev2, BI_DB_PositionPnL.NOP) |
| 17 | ROF_Date | date | YES | Date of rollover fee action; `NULL` on `OpenPosition`, populated on `RollOverFee` from `fca.Occurred`. (Tier 2 -SP_RealCrypto_Lev2, Fact_CustomerAction.Occurred) |
| 18 | RollOverFee | money | YES | Per-row rollover fee (`-Amount` from action 35); `NULL` on `OpenPosition`. (Tier 2 -SP_RealCrypto_Lev2, Fact_CustomerAction.Amount) |
| 19 | TotalRollOverFee | money | YES | On `OpenPosition`: cumulative sum of `RollOverFee` for same `PositionID` with `Indicator='RollOverFee'` and `Date <= @dd`; `NULL` on insert, set by `UPDATE`. (Tier 2 -SP_RealCrypto_Lev2, SUM(BI_DB_RealCrypto_Lev2.RollOverFee)) |
| 20 | UpdateDate | datetime | YES | Row load timestamp. (Tier 3 -SP_RealCrypto_Lev2, GETDATE()) |
| 21 | MifidCategorizationID | int | YES | MiFID categorization id from customer snapshot. (Tier 2 -SP_RealCrypto_Lev2, Fact_SnapshotCustomer.MifidCategorizationID) |
| 22 | MifidCategorization | char(50) | YES | MiFID categorization name. (Tier 2 -SP_RealCrypto_Lev2, Dim_MifidCategorization.Name) |
| 23 | AccountTypeID | int | YES | Account type id. (Tier 2 -SP_RealCrypto_Lev2, Fact_SnapshotCustomer.AccountTypeID) |
| 24 | AccountType | char(50) | YES | Account type name. (Tier 2 -SP_RealCrypto_Lev2, Dim_AccountType.Name) |
| 25 | PlayerLevelID | int | YES | Player level / club tier id. (Tier 2 -SP_RealCrypto_Lev2, Fact_SnapshotCustomer.PlayerLevelID) |
| 26 | Club | char(50) | YES | Club name from player level dimension. (Tier 2 -SP_RealCrypto_Lev2, Dim_PlayerLevel.Name) |
| 27 | PlayerStatusID | int | YES | Player status id. (Tier 2 -SP_RealCrypto_Lev2, Fact_SnapshotCustomer.PlayerStatusID) |
| 28 | PlayerStatus | char(50) | YES | Player status name. (Tier 2 -SP_RealCrypto_Lev2, Dim_PlayerStatus.Name) |
| 29 | IsGermanBaFin | bit | YES | `1` when customer appears in `V_GermanBaFin` for `@ddINT`. (Tier 2 -SP_RealCrypto_Lev2, V_GermanBaFin.CID) |
| 30 | IsCreditReportValidCB | bit | YES | Credit report validity flag from customer snapshot (`Fact_SnapshotCustomer.IsCreditReportValidCB`). (Tier 2 -SP_RealCrypto_Lev2, Fact_SnapshotCustomer.IsCreditReportValidCB) |

---

## 5. Relationships

### Source tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary position state for `@ddINT`; filters buy/settled/leverage=2 |
| Dim_Instrument | DWH_dbo | `InstrumentTypeID = 10`; display name |
| Fact_SnapshotCustomer | DWH_dbo | Customer attributes; joined on `RealCID` |
| Dim_Range | DWH_dbo | Snapshot window for `@ddINT` |
| Dim_Country | DWH_dbo | Country and region |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_MifidCategorization | DWH_dbo | MiFID label |
| Dim_AccountType | DWH_dbo | Account type label |
| Dim_PlayerLevel | DWH_dbo | Club name |
| Dim_PlayerStatus | DWH_dbo | Status label |
| V_GermanBaFin | BI_DB_dbo | Optional BaFin flag by CID and `DateID` |
| Fact_CustomerAction | DWH_dbo | Action 32 (stop loss edits), action 35 (rollover fees) |
| BI_DB_RealCrypto_Lev2 | BI_DB_dbo | Self-aggregation for `TotalRollOverFee` |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_RealCrypto_Lev2 |
| **Author** | Amir Gurewitz (2019-07-21); extensive change history in SP |
| **ETL Pattern** | DELETE by `Date` -- INSERT from `#temp` -- UPDATE `TotalRollOverFee` on `OpenPosition` |
| **Grain** | `Date` × `PositionID` × `Indicator` (plus fee rows) |
| **Schedule** | Daily, Priority 99, FinanceReportSPS (OpsDB) |
| **Parameter** | `@dd` (DATE); internal `@ddINT` and `@ReportDate` (`@dd+1`) declared |

---

## 7. Query Advisory

| Consideration | Guidance |
|---------------|----------|
| **Indicator filter** | For position counts use `Indicator = 'OpenPosition'`; fee analysis uses `RollOverFee`. |
| **Depends on PositionPnL** | Must run after `BI_DB_PositionPnL` is populated for `@dd`. |
| **Cumulative fee** | `TotalRollOverFee` is historical sum in this table through `@dd` -- not only the current day fee. |
| **Duplicate semantic rows** | Multiple `RollOverFee` rows per position/day are possible if multiple actions exist (verify business expectation). |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Real Crypto Leverage |
| **Sensitivity** | Position-level customer detail |
| **Quality Score** | 9.0 |

---

## 9. Sample values (Synapse)

| Check | Status |
|-------|--------|
| TOP 5 row sanity | **Not run** -- `synapse_sql` MCP unavailable in this agent session; run `SELECT TOP 5 * FROM BI_DB_dbo.BI_DB_RealCrypto_Lev2 ORDER BY [Date] DESC, PositionID, Indicator` and attach notes to the review sidecar if needed. |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
