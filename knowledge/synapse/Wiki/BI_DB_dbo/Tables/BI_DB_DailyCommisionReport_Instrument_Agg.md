# BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg

> Instrument-level daily aggregation of BI_DB_DailyCommisionReport. Each row summarises all commission, volume, and fee metrics for a single Date × Instrument × CustomerSegment combination — no individual CID present. Holds ~43.9M rows covering 102 trading dates (2026 YTD as of 2026-04-22, ~430K rows/date) and is refreshed daily by SP_DailyCommisionReport via a DELETE WHERE DateID + INSERT pattern (incremental, history preserved). Migrated to Unity Catalog Gold (Append strategy).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DailyCommisionReport — reads BI_DB_dbo.BI_DB_DailyCommisionReport |
| **Refresh** | Daily incremental: DELETE WHERE DateID=@DateID then INSERT grouped rows |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export — Generic Pipeline, Append strategy, daily |
| **Row Count (YTD)** | ~43.9M rows (102 dates as of 2026-04-22; ~430K rows/date) |
| **Grain** | DateID × InstrumentID × Region × Club × FTD_Year × PlayerStatus × AccountType × Label × position-type flags × customer flags |
| **Documented** | 2026-04-22, Batch 21 |

---

## 1. Business Meaning

`BI_DB_DailyCommisionReport_Instrument_Agg` is the instrument-segmented aggregation layer of the Daily Commission Report pipeline. Where the parent table `BI_DB_DailyCommisionReport` records one row per customer per instrument per day (~179K rows/date), this satellite table groups away the CID dimension and adds an FTD Year (first-deposit cohort year) dimension, producing a compact cube over which instrument-level and cohort-level revenue analysis can run without exposing individual customer data.

The table is written in the same SP_DailyCommisionReport execution run that writes the parent, immediately after the parent insert completes. The load pattern is incremental: for the target DateID, all existing rows are deleted and then re-aggregated from the parent. This means historical dates can be corrected by re-running the SP for that date.

The 22 GROUP BY dimensions cover instrument identity (InstrumentID/Type), geography (Region, US_State), customer segmentation (Club, Label, PlayerStatus, AccountType, FTD_Year), position flags (IsBuy, IsLeverage, IsLeverageMoreThen20, IsAirDrop, IsSettled, SettlementTypeID, IsMarginTrade), and customer quality flags (IsValidCustomer, IsCreditReportValidCB, Regulation, IsDLTUser, IsEtoroTradingCID, IsGlenEagleAccount, eToroTradingGroupUser). Every metric column is a SUM() aggregation from the parent.

**14 of the 63 DDL columns are always NULL.** These are Tier 4 legacy stubs inherited from the parent table's DDL history: IsOutlier, Transition, IsGermanBaFIN, RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev, CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission, FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing, UnealizedFullCommissionChange. The SP does not populate them — it SUMs NULL columns from the parent or omits them entirely.

The table is read by SP_EY_Audit_Opened_Positions for UnrealizedCommissionChange aggregation as part of the 2023 EY audit reporting workflow.

---

## 2. Business Logic

### 2.1 Incremental Load Pattern

**What**: For each daily run, the SP deletes all rows where DateID equals the target date, then re-inserts the full aggregation from the parent table for that date. This makes the load idempotent — safe to re-run for any historical date without double-counting.

**Columns Involved**: DateID (delete key and GROUP BY key)

**Rules**:
- `DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID = @DateID`
- `INSERT ... SELECT ... FROM BI_DB_DailyCommisionReport WHERE DateID = @DateID GROUP BY ...`
- Historical rows for prior DateIDs are never touched — only the target date is refreshed

### 2.2 Aggregation Grain — 22 Dimension Keys

**What**: The GROUP BY clause defines the grain: one row per unique combination of all 22 dimension columns. Compared to the parent table, the CID (RealCID) dimension is absent, and FTD_Year (customer cohort year) is added.

**Columns Involved**: InstrumentID, Instrument, InstrumentTypeID, InstrumentType, Region, Club, FullDate, DateID, FTD Year, Label, PlayerStatusID, PlayerStatus, AccountStatusID, AccountStatusName, AccountTypeID, AccountType, IsBuy, IsLeverage, IsLeverageMoreThen20, IsAirDrop, SettlementTypeID, IsSettled, IsValidCustomer, IsCreditReportValidCB, Regulation, IsDLTUser, IsMarginTrade, IsEtoroTradingCID, IsGlenEagleAccount, eToroTradingGroupUser, US_State

**Rules**:
- All non-metric columns are GROUP BY pass-throughs from the parent
- All metric columns (VolumeOnOpen, VolumeOnClose, Commissions, FullCommissions, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, RollOverFee_SDRT, TradingFees, CommissionOnClose, UnrealizedCommissionChange, FullCommissionOnClose, RealizedFullCommission, InvestedAmountOpen, CountUU) are `SUM(ISNULL(col, 0))` or `SUM(col)` aggregations
- NULL GROUP BY keys form their own group — e.g., US_State=NULL is a separate group from any named state

### 2.3 FTD Year — Customer Cohort Dimension

**What**: `FTD Year` is the year a customer made their first deposit, derived as `YEAR(FirstDepositDate)` from the parent table. It is the only dimension present in this satellite that is not in the parent table's row — it converts a per-customer attribute into a cohort-year GROUP BY key for vintage analysis.

**Columns Involved**: FTD Year

**Rules**:
- Computed as `YEAR(FirstDepositDate)` in the SP SELECT
- Column name contains a space (`[FTD Year]`) — always quote it in SQL: `[FTD Year]` or `"FTD Year"`
- Customers with no first deposit (FTD = NULL) group into FTD_Year = NULL
- Values range from acquisition year of earliest customers through current year

### 2.4 Commission vs FullCommissions

**What**: The table carries two distinct commission figures — Commissions (eToro net revenue) and FullCommissions (gross MIFID regulatory amount). Both are aggregated to this table from the parent.

**Columns Involved**: Commissions, FullCommissions, CommissionOnClose, FullCommissionOnClose, RealizedFullCommission, UnrealizedCommissionChange

**Rules**:
- `Commissions` = net eToro commission (spread-based, net-to-company)
- `FullCommissions` = gross commission including all fees (used for MIFID best execution reporting)
- `CommissionOnClose` = raw commission on positions closed on DateID (float, not money type)
- `FullCommissionOnClose` = gross full commission on closed positions
- `RealizedFullCommission` = gross realized full commission (positions closed)
- `UnrealizedCommissionChange` = daily delta in unrealized spread commission; used by SP_EY_Audit_Opened_Positions

### 2.5 Always-NULL Legacy Columns (14 Tier 4)

**What**: Fourteen columns exist in the DDL but carry no data. They were added to the parent table during historical decomposition attempts (breaking CommissionOnClose into sub-components) or regulatory tracking expansions (RegulationIDPrev, IsCreditReportValidCBPrev) that were never activated. The SP does not populate them.

**Columns Involved**: IsOutlier, Transition, IsGermanBaFIN, RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev, CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission, FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing, UnealizedFullCommissionChange

**Rules**:
- All return NULL for 100% of rows — confirmed via live sampling
- Do not filter or GROUP BY these columns — they add cardinality without meaning
- `UnealizedFullCommissionChange` has a DDL typo (missing 'r' in "Unrealized") — do not correct; it is a persisted production schema name

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no data skew; rows spread evenly across all distributions
- **Clustered Index**: DateID ASC — range scans on DateID are efficient; this is the primary filter pattern
- **Best practice**: Always filter on DateID first. Joining this table to another ROUND_ROBIN table without a DateID filter will trigger a full broadcast or shuffle

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Commission by instrument type for a date range | `WHERE DateID BETWEEN X AND Y GROUP BY InstrumentType` |
| Revenue by customer cohort year | `GROUP BY [FTD Year]` — note bracketed column name |
| Crypto vs non-crypto commission split | `WHERE InstrumentType = 'Crypto Currencies'` vs remainder |
| Leverage vs non-leverage volume | `GROUP BY IsLeverage` or `IsLeverageMoreThen20` |
| Region-level P&L breakdown | `GROUP BY Region, InstrumentType` with SUM(Commissions) |
| Historical date re-run safety check | `SELECT COUNT(*), DateID ... GROUP BY DateID` to verify no duplicate dates |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DailyCommisionReport | `DateID = DateID AND InstrumentID = InstrumentID` | Drill down to individual customer rows from an aggregated result |
| Dim_Instrument (if exists) | `InstrumentID = InstrumentID` | Resolve instrument metadata not in this table (asset class hierarchy) |
| Dim_Date | `DateID = DateID` | Add calendar attributes (month, quarter, fiscal period) |

### 3.4 Gotchas

- **`[FTD Year]` column name has a space** — must always be quoted in SQL as `[FTD Year]`; otherwise the parser splits it into two tokens
- **14 columns are always NULL** — IsOutlier, Transition, IsGermanBaFIN, RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev, CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission, FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing, UnealizedFullCommissionChange. Filtering on these returns 0 rows (or all rows for IS NULL)
- **`UnealizedFullCommissionChange` DDL typo** — the column name is permanently missing the 'r' in "Unrealized". It is always NULL anyway, but the name is wrong in schema
- **Commissions vs CommissionOnClose** — `Commissions` is money type; `CommissionOnClose` is float type. They measure different things: Commissions is the net eToro figure, CommissionOnClose is the raw closed-position component
- **CountUU semantics** — this is a SUM of CountUU from the parent, which is itself derived (number of unique users contributing to that parent row). At this aggregation level, CountUU double-counts customers who appear in multiple instrument segments on the same day
- **FTD_Year NULL group** — customers with no first deposit date form a NULL FTD Year group; include `OR [FTD Year] IS NULL` when building cohort-complete totals
- **ROUND_ROBIN with no join key** — joining this table to HASH-distributed tables requires explicit broadcast hints if the table is small enough, or will cause shuffle redistribution

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | ETL-computed by SP_DailyCommisionReport; logic is code-documented in SSDT |
| **Tier 4** | Legacy / deprecated — column exists in DDL but is always NULL; SP does not populate it |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Financial instrument integer key. GROUP BY pass-through. JOIN to Dim_Instrument for instrument metadata. (Tier 2 — SP_DailyCommisionReport) |
| 2 | Instrument | varchar(100) | YES | Instrument name/symbol (e.g., AAPL, BTC/USD, EURUSD). GROUP BY pass-through from parent. (Tier 2 — SP_DailyCommisionReport) |
| 3 | InstrumentTypeID | int | YES | Instrument type integer key. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 4 | InstrumentType | varchar(100) | YES | Instrument type label. Observed values: Currencies, Commodities, Indices, Stocks, Crypto Currencies, ETF. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 5 | Region | varchar(100) | YES | Marketing region label (e.g., Western Europe, LATAM, Asia Pacific). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 6 | Club | varchar(100) | YES | Customer club/tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, etc.) representing trading volume or loyalty tier. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 7 | FullDate | date | YES | Calendar date of the trading activity (YYYY-MM-DD). GROUP BY pass-through; redundant with DateID. (Tier 2 — SP_DailyCommisionReport) |
| 8 | DateID | int | YES | Trading date in YYYYMMDD integer format. Primary clustering key and incremental DELETE key. Always filter on this column for best performance. (Tier 2 — SP_DailyCommisionReport) |
| 9 | FTD Year | int | YES | Year of the customer's first deposit (`YEAR(FirstDepositDate)`). Used as a cohort dimension for vintage revenue analysis. Unique to this satellite — not present in other DailyCommisionReport satellites. **Column name contains a space — always quote as `[FTD Year]`.** (Tier 2 — SP_DailyCommisionReport) |
| 10 | VolumeOnOpen | money | YES | SUM of USD trading volume for positions opened on DateID within this instrument×segment combination. (Tier 2 — SP_DailyCommisionReport) |
| 11 | VolumeOnClose | money | YES | SUM of USD trading volume for positions closed on DateID within this instrument×segment combination. (Tier 2 — SP_DailyCommisionReport) |
| 12 | RollOverFee | money | YES | SUM of overnight rollover / carry fees charged on DateID. Positive = eToro collected; negative = eToro paid. (Tier 2 — SP_DailyCommisionReport) |
| 13 | FullCommissions | money | YES | SUM of gross full commission (net + all fees). Used for MIFID best-execution regulatory reporting. (Tier 2 — SP_DailyCommisionReport) |
| 14 | Commissions | money | YES | SUM of net eToro commission (spread-based revenue, net-to-company). Primary revenue KPI. (Tier 2 — SP_DailyCommisionReport) |
| 15 | UpdateDate | datetime | NO | ETL execution timestamp (`GETDATE()` at SP run time). Marks when this batch was written; not a business date. (Tier 2 — SP_DailyCommisionReport) |
| 16 | Label | varchar(50) | YES | Customer segment label (e.g., 'eToro', 'Proprietary'). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 17 | PlayerStatusID | int | YES | Integer player status key. GROUP BY pass-through. JOIN to a player-status lookup for name resolution. (Tier 2 — SP_DailyCommisionReport) |
| 18 | PlayerStatus | varchar(50) | YES | Player status name (e.g., Normal, Blocked). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 19 | AccountStatusID | int | YES | Integer account status key. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 20 | AccountStatusName | varchar(50) | YES | Account status label. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 21 | AccountTypeID | int | YES | Integer account type key (1=Private, 2=Corporate, 14=SMSF, etc.). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 22 | AccountType | varchar(50) | YES | Account type name (Personal, Corporate, etc.). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 23 | IsOutlier | int | YES | **Always NULL.** Legacy column inherited from parent DDL; statistical outlier flag that was never activated. Do not use. (Tier 4 — Legacy/Deprecated) |
| 24 | Transition | varchar(50) | YES | **Always NULL.** Legacy column inherited from parent DDL; regulatory transition label that was never populated. Do not use. (Tier 4 — Legacy/Deprecated) |
| 25 | IsGermanBaFIN | int | YES | **Always NULL.** Legacy column inherited from parent DDL; BaFIN (German financial regulator) flag superseded by the Regulation dimension. Do not use. (Tier 4 — Legacy/Deprecated) |
| 26 | IsEtoroTradingCID | int | YES | Flag for internal eToro housekeeping / proprietary trading accounts (1=yes). Excludes these from external customer revenue analysis. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 27 | IsGlenEagleAccount | int | YES | Flag for Glen Eagle Securities subsidiary accounts (1=yes). GROUP BY pass-through for regulatory entity separation. (Tier 2 — SP_DailyCommisionReport) |
| 28 | eToroTradingGroupUser | varchar(50) | YES | eToro trading group identifier string for internal group accounts. GROUP BY pass-through. NULL for standard retail customers. (Tier 2 — SP_DailyCommisionReport) |
| 29 | RegulationIDPrev | int | YES | **Always NULL.** Legacy column tracking a customer's prior regulatory jurisdiction ID; never activated. Do not use. (Tier 4 — Legacy/Deprecated) |
| 30 | RegulationPrev | varchar(50) | YES | **Always NULL.** Legacy column tracking a customer's prior regulatory jurisdiction label; never activated. Do not use. (Tier 4 — Legacy/Deprecated) |
| 31 | IsCreditReportValidCBPrev | int | YES | **Always NULL.** Legacy column tracking prior credit bureau validity; never activated. Do not use. (Tier 4 — Legacy/Deprecated) |
| 32 | US_State | varchar(50) | YES | US state or province short name (e.g., 'CA', 'NY'). NULL for non-US customers. GROUP BY pass-through for US state-level regulatory and reporting splits. (Tier 2 — SP_DailyCommisionReport) |
| 33 | CommissionOnClose | float | YES | SUM of raw commission on positions closed on DateID. Float type (not money). Represents the gross spread captured at close before adjustments. (Tier 2 — SP_DailyCommisionReport) |
| 34 | CommissionByUnitsAtClose | float | YES | **Always NULL.** Legacy column from a historical decomposition of CommissionOnClose by unit count; the decomposition was never implemented in the SP. (Tier 4 — Legacy/Deprecated) |
| 35 | UnrealizedCommissionNew | float | YES | **Always NULL.** Legacy column intended to track commission accrued on newly opened positions; never populated. (Tier 4 — Legacy/Deprecated) |
| 36 | UnrealizedCommissionOldClosing | float | YES | **Always NULL.** Legacy column intended to track previously accrued commission released on close; never populated. (Tier 4 — Legacy/Deprecated) |
| 37 | RealizedCommission | float | YES | **Always NULL.** Legacy column for net realized commission decomposition; never activated. Distinct from CommissionOnClose (which is populated). (Tier 4 — Legacy/Deprecated) |
| 38 | UnrealizedCommissionChange | float | YES | SUM of daily delta in unrealized spread commission (change in the mark-to-market commission accrual). Used by SP_EY_Audit_Opened_Positions for EY audit open-position commission reporting. (Tier 2 — SP_DailyCommisionReport) |
| 39 | FullCommissionOnClose | float | YES | SUM of gross full commission on positions closed on DateID (MIFID reporting basis). Float type. (Tier 2 — SP_DailyCommisionReport) |
| 40 | FullCommissionByUnitsAtClose | float | YES | **Always NULL.** Legacy decomposition of FullCommissionOnClose by unit count; never implemented. (Tier 4 — Legacy/Deprecated) |
| 41 | UnrealizedFullCommissionNew | float | YES | **Always NULL.** Legacy column for unrealized full commission on new positions; never populated. (Tier 4 — Legacy/Deprecated) |
| 42 | UnrealizedFullCommissionOldClosing | float | YES | **Always NULL.** Legacy column for unrealized full commission released on close; never populated. (Tier 4 — Legacy/Deprecated) |
| 43 | RealizedFullCommission | float | YES | SUM of gross realized full commission (positions closed on DateID, MIFID basis). (Tier 2 — SP_DailyCommisionReport) |
| 44 | UnealizedFullCommissionChange | float | YES | **Always NULL.** Legacy column for unrealized full commission daily delta; never populated. **DDL typo: column name is "Un*e*alized" (missing 'r') — this is the persisted production schema name.** (Tier 4 — Legacy/Deprecated) |
| 45 | IsBuy | int | YES | Position direction flag. 1=long (buy), 0=short (sell). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 46 | IsLeverage | int | YES | Leverage indicator. 1=position opened with leverage > 1x, 0=1x (no leverage). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 47 | IsLeverageMoreThen20 | int | YES | High-leverage flag. 1=position leverage exceeds 20x. Note spelling: "MoreThen" (not "MoreThan") is the persisted DDL name. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 48 | IsAirDrop | int | YES | Crypto airdrop flag. 1=position was created from a cryptocurrency airdrop event. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 49 | SettlementTypeID | int | YES | Position settlement type. Observed values: 0=CFD, 1=Real asset, 5=Margin trade. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 50 | IsValidCustomer | bit | YES | Valid customer quality flag (1=passes validation criteria for revenue reporting). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 51 | IsCreditReportValidCB | bit | YES | Credit bureau validity flag (1=credit report validated against external credit bureau). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 52 | Regulation | varchar(50) | YES | Regulatory jurisdiction label (e.g., CySEC, FCA, ASIC, FSAS, GLOBAL). GROUP BY pass-through. 12 distinct values observed in 2026 YTD. (Tier 2 — SP_DailyCommisionReport) |
| 53 | IsSettled | int | YES | Settlement completion flag. 1=real/settled position (actual asset transferred), 0=CFD (contract for difference). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 54 | RollOverFee_SDRT | float | YES | SUM of UK Stamp Duty Reserve Tax charged on UK equity positions. Zero for non-UK-equity instruments. Float type. (Tier 2 — SP_DailyCommisionReport) |
| 55 | TradingFees | float | YES | SUM of composite trading fees (AdminFee + SpotAdjustFee + TicketFee + TicketFeeByPercent). Convenience pre-aggregation of the four individual fee components. Float type. (Tier 2 — SP_DailyCommisionReport) |
| 56 | IsDLTUser | int | YES | Distributed ledger technology (DLT) / blockchain user flag (1=yes). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 57 | TicketFee | money | YES | SUM of per-ticket transaction fees (fixed fee per trade). (Tier 2 — SP_DailyCommisionReport) |
| 58 | TicketFeeByPercent | money | YES | SUM of percentage-based ticket fees (fee as percentage of trade value). (Tier 2 — SP_DailyCommisionReport) |
| 59 | AdminFee | money | YES | SUM of administration / Islamic finance fees (Sharia-compliant swap-free account charge). (Tier 2 — SP_DailyCommisionReport) |
| 60 | SpotAdjustFee | money | YES | SUM of spot price adjustment fees (correction applied when the transaction price differs from spot). (Tier 2 — SP_DailyCommisionReport) |
| 61 | InvestedAmountOpen | money | YES | SUM of USD invested amount for positions opened on DateID. Reflects capital deployed (not notional/leveraged amount). (Tier 2 — SP_DailyCommisionReport) |
| 62 | CountUU | int | YES | SUM of unique-user count values from parent rows. Represents total customer-activity events within this instrument×segment combination. Note: customers appearing in multiple segment rows on the same day are counted multiple times at this aggregation level. (Tier 2 — SP_DailyCommisionReport) |
| 63 | IsMarginTrade | int | YES | Margin-funded position flag (1=position funded by eToro margin; SettlementTypeID=5). Added 2025-10-23. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

All 63 columns originate from `BI_DB_dbo.BI_DB_DailyCommisionReport` via `SP_DailyCommisionReport`. 49 columns are Tier 2 (populated). 14 columns are Tier 4 (always NULL — legacy stubs in DDL, never inserted by the SP). See `BI_DB_DailyCommisionReport_Instrument_Agg.lineage.md` for the full per-column lineage table.

| Synapse Column | Source Table | Transform |
|---------------|-------------|-----------|
| DateID, FullDate, InstrumentID … (22 GROUP BY dims) | BI_DB_dbo.BI_DB_DailyCommisionReport | GROUP BY pass-through |
| FTD Year | BI_DB_dbo.BI_DB_DailyCommisionReport.FirstDepositDate | YEAR(FirstDepositDate) |
| Commissions, FullCommissions, VolumeOnOpen … (15 metrics) | BI_DB_dbo.BI_DB_DailyCommisionReport | SUM(ISNULL(col, 0)) or SUM(col) |
| UpdateDate | — | GETDATE() at SP execution |
| 14 Tier 4 columns | — | Always NULL — SP does not insert |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (@DateID)
  — customer×instrument×position grain — ~179K rows/date
  |
  | SP_DailyCommisionReport @Date
  |   (same execution, runs immediately after parent insert)
  |
  |   DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID = @DateID
  |   INSERT INTO BI_DB_DailyCommisionReport_Instrument_Agg (...)
  |     SELECT ... SUM(commissions/volumes/fees)
  |     FROM BI_DB_dbo.BI_DB_DailyCommisionReport
  |     WHERE DateID = @DateID
  |     GROUP BY InstrumentID, Instrument, ..., YEAR(FirstDepositDate), ..., IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
  (~430K rows/date | 2026 YTD: 43.9M rows | CLUSTERED INDEX DateID | ROUND_ROBIN)
  |
  |-- Generic Pipeline (Append, daily delta) ---|
  v
general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg
  (Unity Catalog Gold — delta format)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| All columns | BI_DB_dbo.BI_DB_DailyCommisionReport | Immediate source table; all rows aggregated from the parent by SP_DailyCommisionReport |
| FTD Year | BI_DB_dbo.BI_DB_DailyCommisionReport.FirstDepositDate | YEAR() derivation of the customer first deposit date |

### 6.2 Referenced By

| Object | Type | Usage |
|--------|------|-------|
| SP_EY_Audit_Opened_Positions | Stored Procedure | Reads `UnrealizedCommissionChange` from this table (SUM grouped by date/instrument) for EY audit open-position commission reconciliation (2023 audit workflow) |
| general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg | UC Gold Table | Downstream Unity Catalog destination — Append pipeline writes daily increments |

---

## 7. Sample Queries

### Daily commission revenue by instrument type and regulation

```sql
SELECT
    DateID,
    InstrumentType,
    Regulation,
    SUM(Commissions)     AS TotalCommissions,
    SUM(FullCommissions) AS TotalFullCommissions,
    SUM(VolumeOnOpen)    AS TotalVolumeOpened
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
WHERE DateID >= 20260101
  AND DateID <= 20260131
GROUP BY DateID, InstrumentType, Regulation
ORDER BY DateID, TotalCommissions DESC;
```

### FTD Year cohort commission analysis for a single instrument

```sql
SELECT
    [FTD Year],           -- Note: column name has a space — must be bracketed
    SUM(Commissions)      AS Commissions,
    SUM(VolumeOnOpen)     AS VolumeOpened,
    SUM(CountUU)          AS ActivityEvents
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
WHERE DateID >= 20260101
  AND Instrument = 'AAPL'
  AND IsValidCustomer = 1
GROUP BY [FTD Year]
ORDER BY [FTD Year];
```

### Leverage vs non-leverage split for high-value clubs

```sql
SELECT
    Club,
    InstrumentType,
    IsLeverage,
    IsLeverageMoreThen20,
    SUM(Commissions)         AS Commissions,
    SUM(RollOverFee)         AS RolloverFees,
    SUM(InvestedAmountOpen)  AS InvestedAmount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
WHERE DateID = 20260420
  AND Club IN ('Diamond', 'Platinum Plus', 'Platinum')
GROUP BY Club, InstrumentType, IsLeverage, IsLeverageMoreThen20
ORDER BY Club, Commissions DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira tickets or Confluence pages were found specifically for this satellite table. Context for the parent pipeline can be found in documentation for `BI_DB_DailyCommisionReport` (Batch 20). The EY audit usage of `UnrealizedCommissionChange` was identified via SP_EY_Audit_Opened_Positions code inspection.

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 49 T2, 0 T3, 14 T4 | Elements: 63/63, Logic: 8/10, Coverage: 10/10*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg | Type: Table | Production Source: SP_DailyCommisionReport*
