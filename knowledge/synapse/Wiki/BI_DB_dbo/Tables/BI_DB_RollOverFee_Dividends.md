# BI_DB_dbo.BI_DB_RollOverFee_Dividends

## 1. Overview

Daily **roll-over fee** and **dividend** cash flows aggregated by instrument, hedge server, settlement mode (Real vs CFD), and customer segmentation. Combines `Fact_CustomerAction` roll-over fee rows (`ActionTypeID=35`, `IsFeeDividend=1`) with dividend rows from `BI_DB_DailyDividendsByPosition` joined to `etoro_Trade_IndexDividends`. Used by finance reporting for per-instrument fee/dividend exposure and eligible-unit context.

**Row grain**: One row per **DateID + HedgeServerID + InstrumentType + InstrumentID + IsSettled + PaymentType + EventType + DividendID** (dividend side includes `DividendID`; roll-over side uses `NULL` dividend key) **+ IsValidCustomer + PlayerLevel + PlayerStatus + IsComputeForHedge** (GROUP BY dimensions in `#FCA`).

---

## 2. Business Context

**Roll-over fees** are overnight financing charges on open positions. The SP selects same-day `Fact_CustomerAction` rows, enriches with customer and position dimensions, resolves **settled vs CFD** using `Dim_PositionChangeLog` when a post-run-date change exists, and sums **negated** `Amount` so stored amounts align with reporting sign convention.

**Dividends** use `BI_DB_DailyDividendsByPosition` for position-level dividend amounts on `@DateID`, joined to `etoro_Trade_IndexDividends` for payment dates, ex-dates, raw event type, and `DividendValueInCurrency`. Event types are **normalized** into a smaller set of labels (e.g. "Cash Dividend", "Spin Off") via `CASE` on `EventType` text.

**Eligible units** for dividends come from `BI_DB_PositionPnL` on the **calendar day before ex-date** (loop per distinct `ExDateID`). Roll-over **units** prefer prior-day `BI_DB_PositionPnL`, with fallbacks for positions closed or opened around the boundary dates per change history comments in the SP.

**Distinct customer counts** (`CountCIDs`) are **averages** of pre-aggregated distinct `RealCID` counts: by `InstrumentID` + settled bucket for roll-over, and by `DividendID` + `IsSettled` for dividends.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 21 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as `YYYYMMDD` integer for actions/dividends loaded. (Tier 2 -- SP_RollOverFee_Dividends, Fact_CustomerAction.DateID / BI_DB_DailyDividendsByPosition.DateID) |
| 2 | PaymentDate | date | YES | Dividend payment date from index dividends; null for roll-over fee rows. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.PaymentDate) |
| 3 | InstrumentID | int | YES | Instrument key. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Position.InstrumentID / BI_DB_DailyDividendsByPosition.InstrumentID) |
| 4 | InstrumentName | varchar(50) | YES | Instrument display name. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Instrument.Name) |
| 5 | IsSettled | varchar(20) | YES | Settlement bucket: **Real** when `Dim_Position.IsSettled=1` (with optional `Dim_PositionChangeLog` override), else **CFD**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Position.IsSettled / log) |
| 6 | PaymentType | varchar(20) | YES | **RollOverFee** or **Dividend** to distinguish the two UNION branches. (Tier 2 -- SP_RollOverFee_Dividends, literal in #FCA) |
| 7 | EventType | varchar(50) | YES | **RollOverFee** for fee branch; dividend branch uses classified `etoro_Trade_IndexDividends.EventType`. (Tier 2 -- SP_RollOverFee_Dividends, CASE on etoro_Trade_IndexDividends.EventType) |
| 8 | Amount | money | YES | Sum of **negated** position-level amounts (`SUM(-Amount)`) from FCA or daily dividends. (Tier 2 -- SP_RollOverFee_Dividends, Fact_CustomerAction.Amount / BI_DB_DailyDividendsByPosition.Amount) |
| 9 | DividendValueInCurrency | decimal(16,8) | YES | Per-share dividend value in currency for dividend rows; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.DividendValueInCurrency) |
| 10 | UpdateDate | datetime | YES | Row load timestamp. (Tier 3 -- SP_RollOverFee_Dividends, GETDATE()) |
| 11 | InstrumentType | varchar(50) | YES | Asset class from dimension. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Instrument.InstrumentType) |
| 12 | HedgeServerID | int | YES | Hedge server on the action date: `ISNULL(Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID, Dim_Position.HedgeServerID)`. (Tier 2 -- SP_RollOverFee_Dividends, snapshot / Dim_Position.HedgeServerID) |
| 13 | DividendID | int | YES | Corporate action dividend id for dividend rows; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, BI_DB_DailyDividendsByPosition.DividendID) |
| 14 | CountCIDs | int | YES | **Average** of pre-grouped distinct `RealCID` counts for the instrument/settlement or dividend/settlement slice (not a simple COUNT on the final grain). (Tier 2 -- SP_RollOverFee_Dividends, AVG from #DistinctCIDs_RollOver / #DistinctCIDs_Div) |
| 15 | Date | date | YES | Calendar date parameter `@Date` stored for readability. (Tier 2 -- SP_RollOverFee_Dividends, @Date) |
| 16 | AmountOfUnits | decimal(38,8) | YES | Sum of eligible or roll-over units (`AmountInUnitsDecimal`) from `BI_DB_PositionPnL` / `Dim_Position` logic. (Tier 2 -- SP_RollOverFee_Dividends, #ROF_Units / #Div_EligibleUnits) |
| 17 | ExDate | date | YES | Dividend ex-date; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.ExDate) |
| 18 | IsValidCustomer | int | YES | Customer validity flag from `Dim_Customer` / daily dividends feed. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Customer.IsValidCustomer) |
| 19 | PlayerLevel | varchar(20) | YES | **BVI** for hard-coded CIDs, **Internal** when `PlayerLevelID=4`, else **Other**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Customer / daily dividends) |
| 20 | PlayerStatus | varchar(20) | YES | **Deposit Blocked** when `PlayerStatusID=10`, else **Other**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Customer / daily dividends) |
| 21 | IsComputeForHedge | bit | YES | Whether position is included in hedge computation (`Dim_Position.IsComputeForHedge`). (Tier 2 -- SP_RollOverFee_Dividends, Dim_Position.IsComputeForHedge) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Fact_CustomerAction | DWH_dbo | Roll-over fee actions (`ActionTypeID=35`, `IsFeeDividend=1`, `DateID=@DateID`) |
| Dim_Customer | DWH_dbo | Customer attributes (`IsValidCustomer`, player level/status rules) |
| Dim_Position | DWH_dbo | Position instrument, settlement, hedge flags, units fallback |
| Dim_PositionHedgeServerChangeLog_Snapshot | DWH_dbo | Hedge server as-of `@DateID` (LEFT JOIN) |
| Dim_PositionChangeLog | DWH_dbo | Post-date settlement changes for roll-over `IsSettled` override |
| BI_DB_PositionPnL | BI_DB_dbo | Units for roll-over and dividend eligibility |
| BI_DB_DailyDividendsByPosition | BI_DB_dbo | Daily dividend amounts by position |
| etoro_Trade_IndexDividends | DWH_dbo | Dividend metadata (dates, type, value) |
| Dim_Instrument | DWH_dbo | Instrument type and name |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_RollOverFee_Dividends |
| **Author** | Jenia (header); multiple change authors in history |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Schedule** | Daily (Priority 99 -- FinanceReportSPS) |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE FROM BI_DB_RollOverFee_Dividends WHERE DateID=@DateID` |
| **Logging** | `SP_ProcessStatusLog` Start / Completed |
| **Architecture** | `#HS` roll-over base -> `#ROF_Units`, `#IsSettled_pcl`; `#Div` dividends -> `#Div_EligibleUnits`, distinct CID temps; `#FCA` UNION aggregate -> INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|----------|
| **Filter on DateID** | Clustered index on `DateID`; always constrain `DateID` (or join via `Dim_Date`). |
| **PaymentType** | Filter `RollOverFee` vs `Dividend` before comparing metrics. |
| **Amount sign** | Amounts are stored as **negated** sums of source `Amount`; confirm sign when reconciling to raw FCA. |
| **CountCIDs** | Value is an **average** of group-level distinct counts; do not treat as exact distinct customers at final grain. |
| **HedgeServerID** | Snapshot-driven; can differ from raw `Dim_Position` when overlap window matches. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Positions |
| **Sub-domain** | Roll-over fees and dividends |
| **Sensitivity** | Aggregated instrument-level; customer counts are aggregated (low direct PII) |
| **Owner** | Finance reporting |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
