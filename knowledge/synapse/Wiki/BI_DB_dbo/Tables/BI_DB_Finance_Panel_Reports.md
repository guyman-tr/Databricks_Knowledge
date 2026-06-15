# BI_DB_dbo.BI_DB_Finance_Panel_Reports

## 1. Overview

Daily **position-level extract for UK FCA panel reporting** on **GB/GI-listed equity-like instruments** (Dim_Instrument `InstrumentTypeID IN (5,6)` with `ISINCountryCode IN ('GB','GI')`). Rows combine **opens**, **closes**, and **same-day IsSettled flips** (ChangeTypeID 13, leverage 1) into one table. Only rows where **stamp duty or main-portfolio (non-copy) logic applies** are persisted (`Is_Stamp_Duty = 1 OR Is_MP = 1`).

**Row grain**: One row per qualifying position event phase per `DateID` (open snapshot, close snapshot, or settlement-change row).

---

## 2. Business Context

Supports **UK regulatory panel** submissions: multi-currency notionals (USD/GBP/EUR), settlement flags at open vs close, regulation at open vs close, copy-trading (`MirrorID`), and **stamp duty** eligibility plus hedge-server-specific duty rates (125/126).

**Key business rules** (from `SP_Finance_Panel_Reports`):
- **Customer slice**: `Fact_SnapshotCustomer.IsCreditReportValidCB = 1` and snapshot date in `Dim_Range` for `@Date`.
- **Open path**: `Dim_Position.OpenDateID = @DateID`, not a partial-close child, instrument types 5/6, GB/GI ISIN country.
- **Close path**: `Dim_Position.CloseDateID = @DateID`, same instrument/geo filters.
- **IsSettled change path**: `Dim_PositionChangeLog` on `@Date`, `ChangeTypeID = 13`, `PreviousIsSettled = 0`, `Leverage = 1`, types 5/6, GB/GI; enriches from `Fact_CustomerAction` and applies stamp-duty dedupe against prior open rows in this table.
- **Prices**: `Fact_CurrencyPriceWithSplit` for instruments 1, 2, 666 on `@DateID` for GBP/EUR conversions.
- **Load**: `DELETE` by `DateID`, then `INSERT` from `#Open_Positions_Phase`, `#Change_Positions_Phase`, `#Close_Positions_Phase` (filtered).

**`Position_Phase` values**: `Open_Position`, `Close_Position` (not generic Open/Close labels).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 38 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Position_Phase | varchar(50) | YES | Event class: `Open_Position` (opens + settlement-change rows) or `Close_Position`. (Tier 2 -SP_Finance_Panel_Reports, literal.Open_Position / Close_Position) |
| 2 | DateID | int | YES | Reporting date as `YYYYMMDD` int; aligns to open, close, or change date per phase. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.OpenDateID / CloseDateID or #IsSettled_Changes_Final.ChangedDateID) |
| 3 | EOW | date | YES | Week-ending date derived from the phase `Occurred` date (`OpenOccurred`, `CloseOccurred`, or `ChangedOccurred`). (Tier 2 -SP_Finance_Panel_Reports, computed from Dim_Position / ChangeLog occurred) |
| 4 | EOM | date | YES | Calendar month-end date (`EOMONTH`) for the phase occurred date. (Tier 2 -SP_Finance_Panel_Reports, computed.EOMONTH) |
| 5 | HedgeServerID | int | YES | Execution/hedge server on the position; drives stamp-duty multiplier (125/126). (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.HedgeServerID) |
| 6 | ISINCountryCode | varchar(50) | YES | Parsed ISO segment from `Dim_Instrument.ISINCode` (2- or 3-char); `'-'` when ISIN missing/too short. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.ISINCode) |
| 7 | InstrumentTypeID | int | YES | Instrument type; filtered to 5 and 6 in SP. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.InstrumentTypeID) |
| 8 | InstrumentTypeName | varchar(50) | YES | Instrument type label. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.InstrumentType) |
| 9 | InstrumentID | int | YES | Instrument identifier. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.InstrumentID) |
| 10 | InstrumentName | varchar(50) | YES | Instrument display name. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.Name) |
| 11 | CID | bigint | YES | Customer ID on the position. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.CID) |
| 12 | PositionID | bigint | YES | Platform position identifier. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.PositionID) |
| 13 | IsSettled_OnOpen | int | YES | 1 = real asset, 0 = CFD asset; `-1` when not applicable. From `Fact_CustomerAction` for open-day actions (types 1–3). (Tier 5 — Expert Review) |
| 14 | IsSettled_OnClose | int | YES | 1 = real asset, 0 = CFD asset; `-1` when not applicable. From `Dim_Position` on close rows. (Tier 5 — Expert Review) |
| 15 | Leverage | int | YES | Position leverage from `Dim_Position` (change path may join position for consistency). (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.Leverage) |
| 16 | SellCurrencyID | int | YES | Quote/sell currency id for FX conversion routing. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.SellCurrencyID) |
| 17 | SellCurrency | varchar(50) | YES | Sell currency code/name from dimension. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.SellCurrency) |
| 18 | Amount_OnOpen_USD | money | YES | Open notional in USD: `InitialAmountCents/100` on opens; change path uses `NewAmount` from change log; zero on pure closes. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.InitialAmountCents / Dim_PositionChangeLog.NewAmount) |
| 19 | Amount_OnOpen_GBP | money | YES | Open amount converted to GBP via instrument 2 ask when `SellCurrencyID` in (666,3); else 0. (Tier 2 -SP_Finance_Panel_Reports, #Prices.Ask where InstrumentID=2) |
| 20 | Amount_OnOpen_EUR | money | YES | Open amount converted to EUR via instrument 1 ask when `SellCurrencyID` = 2; else 0. (Tier 2 -SP_Finance_Panel_Reports, #Prices.Ask where InstrumentID=1) |
| 21 | Notional_Value | money | YES | Open: `AmountInUnitsDecimal / InitForexRate` (zero if `InitForexRate` = 0); close: `AmountInUnitsDecimal * EndForexRate`; change: open USD × leverage. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.AmountInUnitsDecimal / InitForexRate / EndForexRate) |
| 22 | Amount_OnClose_USD | money | YES | Close-row USD amount from `Dim_Position.Amount`; zero on open/change rows. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.Amount) |
| 23 | Amount_OnClose_GBP | money | YES | Close amount in GBP via instrument 2 ask when `SellCurrencyID` in (666,3). (Tier 2 -SP_Finance_Panel_Reports, #Prices.Ask InstrumentID=2) |
| 24 | Amount_OnClose_EUR | money | YES | Close amount in EUR via instrument 1 ask when `SellCurrencyID` = 2. (Tier 2 -SP_Finance_Panel_Reports, #Prices.Ask InstrumentID=1) |
| 25 | RegulationID_OnOpen | int | YES | Regulation at open from `Dim_Position.RegulationIDOnOpen`; `-1` on closes. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.RegulationIDOnOpen) |
| 26 | RegulationName_OnOpen | varchar(50) | YES | Regulation name for open; `'N/A'` when not applicable. (Tier 2 -SP_Finance_Panel_Reports, Dim_Regulation.Name) |
| 27 | RegulationID_OnClose | int | YES | On closes: `Fact_SnapshotCustomer.RegulationID`; `-1` on opens/changes. (Tier 2 -SP_Finance_Panel_Reports, Fact_SnapshotCustomer.RegulationID) |
| 28 | RegulationName_OnClose | varchar(50) | YES | Regulation name on close from customer snapshot; `'N/A'` when not applicable. (Tier 2 -SP_Finance_Panel_Reports, Dim_Regulation.Name) |
| 29 | Is_Copy | int | YES | `1` if `MirrorID <> 0` (copy/mirror position), else `0`. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.MirrorID) |
| 30 | Position_Quantity | int | YES | Always `1` in SP (one logical position row per event). (Tier 2 -SP_Finance_Panel_Reports, literal.1) |
| 31 | Is_Stamp_Duty | int | YES | Flag when stamp-duty conditions met (settlement + instrument types 5/6, with extra guards on change path vs prior rows). (Tier 2 -SP_Finance_Panel_Reports, computed from IsSettled / InstrumentTypeID) |
| 32 | Is_MP | int | YES | `1` for main portfolio (`MirrorID` null or 0), else `0`. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.MirrorID) |
| 33 | UpdateDate | datetime | YES | Row load timestamp. (Tier 3 -SP_Finance_Panel_Reports, GETDATE()) |
| 34 | DateOccurred | date | YES | Calendar date of open, close, or settlement change. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.OpenOccurred / CloseOccurred / Dim_PositionChangeLog.Occurred) |
| 35 | ISINCode | char(30) | YES | Raw ISIN from instrument dimension. (Tier 2 -SP_Finance_Panel_Reports, Dim_Instrument.ISINCode) |
| 36 | Units_OnOpen | decimal(16,6) | YES | Units at open: `InitialUnits` on opens/changes; `0` on closes. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.InitialUnits / Dim_PositionChangeLog path AmountInUnits) |
| 37 | Units_OnClose | decimal(16,6) | YES | Units at close: `AmountInUnitsDecimal` on closes; `0` on opens/changes. (Tier 2 -SP_Finance_Panel_Reports, Dim_Position.AmountInUnitsDecimal) |
| 38 | Total_Stamp_Duty | money | YES | Stamp duty estimate: `0.005` × amount × multiplier 3 (server 126) or 2 (server 125), else 0. (Tier 2 -SP_Finance_Panel_Reports, computed from Dim_Position.HedgeServerID and InitialAmountCents or Amount) |

---

## 5. Relationships

### Source tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dim_Position | DWH_dbo | Open/close facts, amounts, units, regulation-on-open, mirror, hedge server |
| Dim_Instrument | DWH_dbo | Type, ISIN, sell currency, name |
| Fact_SnapshotCustomer | DWH_dbo | Valid CB customers, regulation-on-close via range |
| Dim_Range | DWH_dbo | Snapshot window for `@DateID` |
| Dim_Regulation | DWH_dbo | Regulation names |
| Fact_CustomerAction | DWH_dbo | `IsSettled_OnOpen` for action types 1–3 |
| Fact_CurrencyPriceWithSplit | DWH_dbo | `#Prices` for FX legs (instruments 1, 2, 666) |
| Dim_PositionChangeLog | DWH_dbo | Same-day settlement changes (type 13) |
| BI_DB_Finance_Panel_Reports | BI_DB_dbo | Self-reference on change path to avoid duplicate stamp-duty rows |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Panel_Reports |
| **Author** | Adi Meidan (2023-11-01); change history in SP header |
| **ETL Pattern** | DELETE by `DateID` then INSERT (union of three temp phases, filtered) |
| **Grain** | Position event × phase per `DateID` (filtered) |
| **Schedule** | Daily, Priority 99, FinanceReportSPS (OpsDB) |
| **Parameter** | `@Date` (DATE) |

---

## 7. Query Advisory

| Consideration | Guidance |
|---------------|----------|
| **Subset table** | Rows exist only when `Is_Stamp_Duty = 1` OR `Is_MP = 1`; not full universe of GB/GI equities. |
| **Sentinel -1** | `-1` on settlement/regulation fields means “not applicable” for that phase. |
| **Depends on prices** | GBP/EUR columns require same-day `#Prices` rows for instruments 1 and 2. |
| **Order vs downstream** | Runs after dimensions and customer snapshot for `@Date`; coordinate with `Fact_CustomerAction` freshness. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Regulatory (UK FCA panel) |
| **Sensitivity** | Position-level customer and instrument detail |
| **Quality Score** | 9.0 |

---

## 9. Sample values (Synapse)

| Check | Status |
|-------|--------|
| TOP 5 row sanity | **Not run** -- `synapse_sql` MCP unavailable in this agent session; run `SELECT TOP 5 * FROM BI_DB_dbo.BI_DB_Finance_Panel_Reports ORDER BY DateID DESC, PositionID` and attach notes to the review sidecar if needed. |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
