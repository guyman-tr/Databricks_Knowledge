# BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear

> Annual customer-level commission aggregation covering the prior complete calendar year. Each row summarises all commission, fee, and investment metrics for a single customer (RealCID) × calendar year × Region × Manager × InstrumentType × Regulation × Mifid segment. Holds ~6.48M rows for Year=2025 across ~2.19M unique CIDs as of 2026-04-22. Fully replaced daily by SP_DailyCommisionReport via TRUNCATE+INSERT using a `DATEDIFF(YEAR, FullDate, yesterday) = 1` filter. No Club, Country, or week dimensions. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DailyCommisionReport — reads BI_DB_dbo.BI_DB_DailyCommisionReport |
| **Refresh** | Daily full replace: TRUNCATE then INSERT from last calendar year's data |
| **Window** | `DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1` — previous full calendar year |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **Row Count** | ~6.48M rows (Year=2025, ~2.19M CIDs as of 2026-04-22) |
| **Grain** | RealCID × Year × Region × Manager × UserName × InstrumentType × Regulation × Mifid × IsValidCustomer × IsCreditReportValidCB × IsDLTUser × IsMarginTrade |
| **Documented** | 2026-04-22, Batch 21 |

---

## 1. Business Meaning

`BI_DB_DailyCommisionReport_LastYear` is the annual customer-level view of the Daily Commission Report pipeline. It aggregates an entire calendar year of trading activity into one row per customer×segment, covering the prior complete year (not the current in-progress year). This makes it the primary table for year-over-year commission comparisons, annual customer revenue reviews, and regulatory annual reporting.

The table is written by SP_DailyCommisionReport in the same daily execution run that writes the parent table and the other satellites. The date filter is `DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1`, which selects all parent rows where the trading date falls in the calendar year preceding yesterday. As of 2026-04-22, this means FullDate is in 2025. On January 1, 2027, the table will roll over to cover 2026 data.

Compared to `Last2weeks`, this table has a narrower set of GROUP BY dimensions — no Club, Country, Label, or Week columns. The grain is RealCID × YEAR(FullDate) × Region × Manager × UserName × InstrumentType × Regulation × Mifid × customer flags. This means a customer can appear in multiple rows if they traded across multiple instrument types, regulations, or regions during the year.

The table is fully replaced on every SP run (TRUNCATE+INSERT). Like `Last2weeks`, it carries no history before the current "last year" window; in January the window shifts and the prior year's data disappears from this table (it remains in the parent).

**1 of 23 DDL columns is always NULL**: `CommissionInRisk` is in the DDL but absent from the SP INSERT column list. Confirmed ghost column via cross-referencing the SP code.

---

## 2. Business Logic

### 2.1 Full Replace Load Pattern

**What**: The table is completely rebuilt on every SP run. TRUNCATE removes all rows, then a single INSERT adds all last-year rows from the parent. The table content is always exactly one year's worth of aggregated data.

**Columns Involved**: All columns

**Rules**:
- `TRUNCATE TABLE BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear`
- `INSERT INTO ... SELECT ... FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK) WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1 GROUP BY ...`
- Running the SP multiple times in one day without a manual truncation will produce duplicate rows
- NOLOCK hint is applied to the source read — uncommitted parent rows can be included

### 2.2 Last Calendar Year Window

**What**: The year filter uses `DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1` — this computes the year difference between the trading date and yesterday, selecting exactly those rows where the result is 1 (i.e., one year gap in calendar years).

**Columns Involved**: Year (derived GROUP BY key), source DateID/FullDate

**Rules**:
- `DATEDIFF(YEAR, '2025-12-31', '2026-04-21') = 1` → row included (FullDate in 2025)
- `DATEDIFF(YEAR, '2024-12-31', '2026-04-21') = 2` → excluded (2024 data not included)
- `DATEDIFF(YEAR, '2026-01-01', '2026-04-21') = 0` → excluded (current year not included)
- The window does NOT shift mid-year — it always covers the prior complete calendar year (Jan 1 to Dec 31)
- On January 1 of each year, the table rolls over to the new "last year" — data for the just-completed year replaces data for the year before

### 2.3 Year as GROUP BY Key

**What**: The `Year` column = `YEAR(FullDate)`. It is a GROUP BY dimension — all rows in this table currently have the same Year value (the prior calendar year), so it is effectively a constant. Its inclusion in the GROUP BY preserves the column for year-over-year joins and allows for future multi-year configurations.

**Columns Involved**: Year

**Rules**:
- `Year` = `YEAR(FullDate)` computed in the SP SELECT
- As of 2026-04-22, all rows have Year=2025
- Do not filter on Year (it's a constant in this table) — use it for labelling only
- For multi-year analysis, query the parent `BI_DB_DailyCommisionReport` with explicit year filters

### 2.4 CommissionInRisk — Ghost Column

**What**: `CommissionInRisk` exists in the DDL but is never written by SP_DailyCommisionReport. It is absent from the INSERT column list, so it remains NULL for every row.

**Columns Involved**: CommissionInRisk

**Rules**:
- Always NULL — confirmed via SP code inspection (column absent from INSERT list)
- Same ghost column pattern as in Last2weeks (identical column name and type)
- Do not use in any filter or aggregation

### 2.5 Narrower Dimension Set vs Last2weeks

**What**: LastYear has fewer GROUP BY dimensions than Last2weeks. Club, Country, Label, Week, weeknum, and IsThisWeek are all absent. The resulting rows are aggregated over a broader segment cut.

**Columns Involved**: (absent) Club, Country, Label, Week, weeknum, IsThisWeek

**Rules**:
- Without Club or Country, revenue cannot be broken down by tier or geography from this table alone
- For Club/Country-level last-year analysis, query the parent table with `WHERE YEAR(FullDate) = YEAR(GETDATE())-1`
- Year-over-year at instrument type × regulation grain is well-supported

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no data skew; rows spread across all distributions
- **Clustered Index**: RealCID ASC — efficient customer-ID-level lookups; JOIN to customer dimension tables benefits from clustering
- **No date filter needed**: The table only contains last year's data; no DateID filter is required (the entire table is the relevant window)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Annual commission by regulation | `GROUP BY Regulation, SUM(Commissions)` — no date filter needed |
| Year-over-year customer comparison | JOIN this table to current-year data from the parent on RealCID |
| Per-manager annual revenue | `GROUP BY Manager, SUM(Commissions)` |
| Crypto share of annual revenue | `WHERE InstrumentType = 'Crypto Currencies'` vs total |
| Customer annual fee breakdown | `WHERE RealCID = X, SELECT SUM(RollOverFee), SUM(TicketFee), ...` |
| Annual revenue by instrument and region | `GROUP BY InstrumentType, Region, SUM(Commissions)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DailyCommisionReport | `RealCID = RealCID AND YEAR(FullDate) = YEAR(GETDATE())-1` | Drill down from annual totals to daily/trade detail |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks | `RealCID = RealCID AND Regulation = Regulation` | Compare last year's annual performance to the current 2-week run rate |
| Dim_Customer (if exists) | `RealCID = CID` | Enrich with Club, Country attributes not in this table |

### 3.4 Gotchas

- **CommissionInRisk is always NULL** — do not filter or aggregate; it was never populated
- **Year is always a single value** — as of 2026-04-22, every row has Year=2025. Do not GROUP BY Year expecting multiple values; the table has only one year's data
- **No Club or Country columns** — these dimensions were not included in LastYear's GROUP BY; use the parent table for Club/Country-level last-year breakdowns
- **NOLOCK on source read** — same risk as Last2weeks: uncommitted parent rows may be captured mid-ETL
- **TRUNCATE+INSERT atomicity** — if the SP fails between TRUNCATE and INSERT, the table is left empty; monitor ETL completion before consuming
- **Annual roll-over on Jan 1** — on January 1 each year, this table's content shifts to the new prior year. Historical last-year snapshots are not retained here

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | ETL-computed by SP_DailyCommisionReport; logic is code-documented in SSDT |
| **Tier 4** | Legacy / deprecated — column exists in DDL but is always NULL; SP does not insert it |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer integer ID. Clustering key. Individual customer retained at this aggregation level for year-over-year customer revenue analysis. (Tier 2 — SP_DailyCommisionReport) |
| 2 | Manager | varchar(100) | YES | Account manager name. GROUP BY pass-through. Used for annual account manager performance reporting. (Tier 2 — SP_DailyCommisionReport) |
| 3 | Region | varchar(100) | YES | Marketing region label. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 4 | Year | int | YES | Calendar year of the trading data: `YEAR(FullDate)`. As of 2026-04-22, all rows have Year=2025 (last calendar year). GROUP BY key. (Tier 2 — SP_DailyCommisionReport) |
| 5 | UserName | varchar(100) | YES | Customer username string. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 6 | Commissions | money | YES | SUM of net eToro commission (spread-based, net-to-company) for the full prior calendar year within this customer×segment combination. (Tier 2 — SP_DailyCommisionReport) |
| 7 | FullCommissions | money | YES | SUM of gross full commission (MIFID best-execution reporting basis) for the full prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 8 | CommissionInRisk | money | YES | **Always NULL — ghost column.** Present in DDL but absent from the SP INSERT column list; never populated. Same ghost as in Last2weeks — likely a planned commission-at-risk metric that was never implemented. (Tier 4 — Legacy/Deprecated) |
| 9 | UpdateDate | datetime | YES | ETL execution timestamp (`GETDATE()` at SP run time). Marks when this batch was written; not a business date. (Tier 2 — SP_DailyCommisionReport) |
| 10 | Regulation | varchar(50) | YES | Regulatory jurisdiction label (CySEC, FCA, ASIC, FSAS, GLOBAL, etc.). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 11 | Mifid | varchar(50) | YES | MiFID classification label (e.g., 'MIFID', 'Non-MIFID'). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 12 | InstrumentType | varchar(100) | YES | Instrument type name (Currencies, Commodities, Indices, Stocks, Crypto Currencies, ETF). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 13 | IsValidCustomer | bit | YES | Valid customer quality flag (1=passes validation criteria for revenue reporting). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 14 | IsCreditReportValidCB | bit | YES | Credit bureau validity flag (1=credit report validated against external credit bureau). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 15 | IsDLTUser | int | YES | Distributed ledger technology (DLT) / blockchain user flag (1=yes). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 16 | RollOverFee | money | YES | SUM of overnight rollover/carry fees charged over the full prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 17 | TicketFee | money | YES | SUM of per-ticket transaction fees for the full prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 18 | TicketFeeByPercent | money | YES | SUM of percentage-based ticket fees for the full prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 19 | AdminFee | money | YES | SUM of Islamic finance / administration fees for the full prior calendar year (Sharia-compliant swap-free account charge). (Tier 2 — SP_DailyCommisionReport) |
| 20 | SpotAdjustFee | money | YES | SUM of spot price adjustment fees for the full prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 21 | InvestedAmountOpen | money | YES | SUM of USD invested amount for positions opened during the prior calendar year. (Tier 2 — SP_DailyCommisionReport) |
| 22 | CountUU | int | YES | SUM of unique-user count values from parent rows for the year. At this aggregation level, customers trading multiple instrument types are counted per segment row. (Tier 2 — SP_DailyCommisionReport) |
| 23 | IsMarginTrade | int | YES | Margin-funded position flag (1=position funded by eToro margin; SettlementTypeID=5). Added 2025-10-23. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

All 23 columns originate from `BI_DB_dbo.BI_DB_DailyCommisionReport` via `SP_DailyCommisionReport`. 22 columns are Tier 2 (populated). 1 column is Tier 4 (CommissionInRisk — ghost, always NULL). See `BI_DB_DailyCommisionReport_LastYear.lineage.md` for the full per-column lineage table.

| Synapse Column | Source Table | Transform |
|---------------|-------------|-----------|
| RealCID, Manager, Region, UserName, Regulation, Mifid, InstrumentType, IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade | BI_DB_dbo.BI_DB_DailyCommisionReport | GROUP BY pass-through |
| Year | BI_DB_dbo.BI_DB_DailyCommisionReport.FullDate | YEAR(FullDate) |
| Commissions, FullCommissions, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, InvestedAmountOpen, CountUU | BI_DB_dbo.BI_DB_DailyCommisionReport | SUM() aggregations |
| UpdateDate | — | GETDATE() at SP execution |
| CommissionInRisk | — | Always NULL — not in INSERT list |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (last calendar year)
  — customer×instrument×position grain
  — WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 1
    (FullDate in 2025 as of 2026-04-22)
  |
  | SP_DailyCommisionReport @Date
  |   (runs after Last2weeks insert in the same execution)
  |
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_LastYear
  |   INSERT INTO BI_DB_DailyCommisionReport_LastYear (22 columns)
  |     SELECT ... SUM(Commissions/FullCommissions/fees)
  |     FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK)
  |     WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1
  |     GROUP BY RealCID, YEAR(FullDate), UserName, Region, Manager,
  |              Regulation, Mifid, InstrumentType,
  |              IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear
  (~6.48M rows | Year=2025 | ~2.19M CIDs | CLUSTERED INDEX RealCID | ROUND_ROBIN)
  |
  |-- NOT migrated to Unity Catalog ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| All columns | BI_DB_dbo.BI_DB_DailyCommisionReport | Immediate source — last calendar year date filter applied to parent |
| Year | BI_DB_dbo.BI_DB_DailyCommisionReport.FullDate | YEAR() derivation of trading date |

### 6.2 Referenced By

| Object | Type | Usage |
|--------|------|-------|
| BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks | Table (sister satellite) | Analysts compare weekly totals in Last2weeks to annual totals here for run-rate analysis; not a formal SQL dependency |

---

## 7. Sample Queries

### Annual commission by regulation and instrument type (last year)

```sql
SELECT
    Regulation,
    InstrumentType,
    SUM(Commissions)     AS AnnualCommissions,
    SUM(FullCommissions) AS AnnualFullCommissions,
    SUM(RollOverFee)     AS AnnualRolloverFees,
    COUNT(DISTINCT RealCID) AS CustomerCount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear
WHERE IsValidCustomer = 1
GROUP BY Regulation, InstrumentType
ORDER BY AnnualCommissions DESC;
```

### Top customers by annual commission for account manager review

```sql
SELECT TOP 200
    RealCID,
    UserName,
    Manager,
    Region,
    SUM(Commissions)         AS AnnualCommissions,
    SUM(FullCommissions)     AS AnnualFullCommissions,
    SUM(RollOverFee)         AS AnnualRolloverFees,
    SUM(InvestedAmountOpen)  AS AnnualInvested
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear
WHERE IsValidCustomer = 1
GROUP BY RealCID, UserName, Manager, Region
ORDER BY AnnualCommissions DESC;
```

### Year-over-year run-rate: last year annual vs current 2-week commission pace

```sql
-- Last year annualised (from LastYear)
SELECT
    InstrumentType,
    SUM(Commissions) / 52.0          AS WeeklyRunRate_LastYear,
    SUM(Commissions)                  AS Annual_LastYear
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear
WHERE IsValidCustomer = 1
GROUP BY InstrumentType

UNION ALL

-- Current 2-week pace (from Last2weeks — complete week only)
SELECT
    InstrumentType,
    SUM(Commissions)                  AS WeeklyRunRate_Current,
    NULL
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
WHERE CAST(IsThisWeek AS int) = 0
  AND IsValidCustomer = 1
GROUP BY InstrumentType
ORDER BY InstrumentType;
```

---

## 8. Atlassian Knowledge Sources

No Jira tickets or Confluence pages were found specifically for this satellite table. Context for the parent pipeline is documented in `BI_DB_DailyCommisionReport` (Batch 20). The annual window definition and TRUNCATE+INSERT pattern are defined exclusively in SP_DailyCommisionReport (SSDT).

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 22 T2, 0 T3, 1 T4 | Elements: 23/23, Logic: 8/10, Coverage: 10/10*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear | Type: Table | Production Source: SP_DailyCommisionReport*
