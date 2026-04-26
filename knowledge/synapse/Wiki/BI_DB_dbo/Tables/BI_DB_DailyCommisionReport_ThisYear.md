# BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear

**Schema**: BI_DB_dbo | **Type**: Table | **Batch**: 22 | **Generated**: 2026-04-22

---

## 1. Object Summary

`BI_DB_DailyCommisionReport_ThisYear` is a **year-to-date (YTD) commission aggregation** that summarises commission and fee revenue from the current calendar year. It is written daily by `SP_DailyCommisionReport` via TRUNCATE + INSERT, drawing from the parent table `BI_DB_dbo.BI_DB_DailyCommisionReport` and grouping by customer-year granularity.

**Key characteristics**:
- Holds current calendar-year data only; TRUNCATE clears all prior rows on each run
- Coarser grain than Yesterday or ThisMonth — no Club or Country dimension, no daily/monthly date column
- `RealCID` is `bigint` here; all other DailyCommisionReport satellites use `int` — a DDL-level type inconsistency
- `CommissionInRisk` is present in DDL but excluded from all SP INSERT lists (ghost column, always NULL)
- Year-start edge case: if SP runs on Jan 1, scope captures the prior year's full data rather than an empty 1-day window

**Grain**: One row per (RealCID × Manager × Region × UserName × Regulation × Mifid × InstrumentType × IsValidCustomer × IsCreditReportValidCB × IsDLTUser × IsMarginTrade) within the current calendar year.

**Live snapshot** (sampled 2026-04-22): 2,649,516 rows | Year = 2026 | 1,371,482 distinct CIDs.

---

## 2. Schema / DDL

**Distribution**: ROUND_ROBIN  
**Index**: CLUSTERED INDEX on `RealCID ASC`  
**DDL source**: `BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisYear]
(
    [RealCID]              [bigint]       NULL,   -- NOTE: bigint; all other satellites use int
    [Manager]              [varchar](100) NULL,
    [Region]               [varchar](100) NULL,
    [Year]                 [int]          NULL,
    [UserName]             [varchar](100) NULL,
    [Commissions]          [money]        NULL,
    [FullCommissions]      [money]        NULL,
    [CommissionInRisk]     [money]        NULL,   -- GHOST: DDL only; never populated by SP
    [UpdateDate]           [datetime]     NULL,
    [Regulation]           [varchar](50)  NULL,
    [Mifid]                [varchar](50)  NULL,
    [InstrumentType]       [varchar](100) NULL,
    [IsValidCustomer]      [bit]          NULL,
    [IsCreditReportValidCB][bit]          NULL,
    [IsDLTUser]            [int]          NULL,
    [RollOverFee]          [money]        NULL,
    [TicketFee]            [money]        NULL,
    [TicketFeeByPercent]   [money]        NULL,
    [AdminFee]             [money]        NULL,
    [SpotAdjustFee]        [money]        NULL,
    [InvestedAmountOpen]   [money]        NULL,
    [CountUU]              [int]          NULL,
    [IsMarginTrade]        [int]          NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED INDEX ([RealCID] ASC)
)
```

**Column count**: 23 DDL columns (22 active + 1 ghost: `CommissionInRisk`)

**Notable absences vs siblings**:
- No `Club` or `Country` (present in Yesterday, ThisMonth)
- No `FullDate` (Yesterday-only), no `Month` (ThisMonth-only), no `weeknum` (MonthlyData-only)
- `Year` is a plain int derived via `YEAR(FullDate)` — not an encoded composite like `Month`

---

## 3. Volume & Freshness

| Metric | Value |
|--------|-------|
| Row count (live) | 2,649,516 |
| Distinct CIDs | 1,371,482 |
| Year scope | 2026 (current calendar year) |
| Sample date | 2026-04-22 (~112 trading days YTD) |
| Refresh cadence | Daily — TRUNCATE + INSERT via SP_DailyCommisionReport |
| Freshness | Current as of yesterday's close (DATEADD(DAY,-1,GETDATE())) |
| Backup table | None found in SSDT repo |

**Year-start edge case**: When `SP_DailyCommisionReport` runs on 1 January, `@Dateyear` is set to the first day of the prior year. The WHERE filter `DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 0` on Jan 1 therefore captures the entire prior calendar year, preventing an empty table.

---

## 4. Business Logic & ETL

### 4.1 Writer Stored Procedure

**SP**: `BI_DB_dbo.SP_DailyCommisionReport` (lines 1498–1568 in SSDT repo)  
**Parent table**: `BI_DB_dbo.BI_DB_DailyCommisionReport` (documented in Batch 20)

### 4.2 ETL Flow

```
SP_DailyCommisionReport
  │
  ├── TRUNCATE BI_DB_DailyCommisionReport_ThisYear
  │
  ├── @Dateyear = CASE
  │     WHEN DAY(GETDATE())=1 AND MONTH(GETDATE())=1
  │       THEN DATEADD(YEAR, DATEDIFF(YEAR,0,GETDATE())-1, 0)   -- Jan 1: prior year
  │     ELSE DATEADD(YEAR, DATEDIFF(YEAR,0,GETDATE()), 0)        -- else: current year start
  │   END
  │
  └── INSERT INTO BI_DB_DailyCommisionReport_ThisYear
        SELECT ... FROM BI_DB_DailyCommisionReport WITH (NOLOCK)
        WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 0
        GROUP BY RealCID, YEAR(FullDate), UserName, Region, Manager,
                 Regulation, Mifid, InstrumentType,
                 IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade
```

### 4.3 Year Encoding

`Year` = `YEAR(FullDate)` — a plain four-digit integer (e.g., 2026). Unlike `Month` in ThisMonth (which encodes as `YYYYMM`), this is unambiguous.

### 4.4 Date Filter

`WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 0`

This uses DATEDIFF with YEAR granularity — it is equivalent to "FullDate is in the same calendar year as yesterday." For the first 112 days of 2026, this captures all 2026 data from Jan 1 through yesterday.

### 4.5 Ghost Column

`CommissionInRisk` appears in the DDL but is absent from the SP INSERT at lines 1504–1527. It is never populated. This pattern is consistent across Yesterday, ThisMonth, ThisYear, Last2weeks, and LastYear. `CommissionInRisk` was removed from MonthlyData DDL entirely.

### 4.6 Differences vs Yesterday and ThisMonth

| Feature | Yesterday | ThisMonth | ThisYear |
|---------|-----------|-----------|----------|
| Time grain | Single date | Current month MTD | Current year YTD |
| Date dim column | FullDate (date) | Month (int YYYYMM) | Year (int YYYY) |
| Club column | Yes | Yes | **No** |
| Country column | Yes | Yes | **No** |
| RealCID type | int | int | **bigint** |
| Refresh | TRUNCATE + INSERT | TRUNCATE + INSERT | TRUNCATE + INSERT |
| Edge case | None | Day=1 → prior month | Jan 1 → prior year |

---

## 5. Column Dictionary

All columns are **Tier 2** (BI_DB intermediate layer, sourced from parent `BI_DB_DailyCommisionReport`), except `CommissionInRisk` which is **Tier 4** (ghost).

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | RealCID | bigint | NULL | T2 | Customer ID. **bigint here; all sibling tables use int.** Type inconsistency — JOIN with other tables requires explicit CAST. |
| 2 | Manager | varchar(100) | NULL | T2 | Account manager name assigned to this customer. Year-level aggregation retains manager. |
| 3 | Region | varchar(100) | NULL | T2 | Geographic sales region. Examples: EMEA, LATAM, APAC, US. |
| 4 | Year | int | NULL | T2 | Calendar year derived via `YEAR(FullDate)`. Four-digit integer (e.g., 2026). Single value per run = current year. |
| 5 | UserName | varchar(100) | NULL | T2 | Account username / login identifier for the customer. |
| 6 | Commissions | money | NULL | T2 | `SUM(ISNULL(Commissions,0))` YTD. Net commission revenue earned from this customer for the current year. |
| 7 | FullCommissions | money | NULL | T2 | `SUM(ISNULL(FullCommissions,0))` YTD. Gross commission before adjustments or rebates. |
| 8 | CommissionInRisk | money | NULL | **T4** | **GHOST COLUMN.** Present in DDL; absent from SP INSERT (lines 1504–1527). Always NULL. Never populated. |
| 9 | UpdateDate | datetime | NULL | T2 | `GETDATE()` at SP execution time. Timestamp of the most recent TRUNCATE + INSERT. Nullable unlike MonthlyData. |
| 10 | Regulation | varchar(50) | NULL | T2 | Regulatory framework governing the customer. Values: `ASIC`, `CYSEC`, `FCA`, `FSAS`, `FSA`, `FinCEN`, `GFSC`, `MFSA`, `NBRB`, `SFSA`, `VIRTUAL`. |
| 11 | Mifid | varchar(50) | NULL | T2 | MiFID classification. Values: `Retail`, `Retail Pending`, `Professional`, `Professional Pending`, `Pending`. |
| 12 | InstrumentType | varchar(100) | NULL | T2 | Asset class of the traded instrument. Values: `Stocks`, `Crypto`, `ETF`, `Commodities`, `Indices`, `Currencies`, `Other`. |
| 13 | IsValidCustomer | bit | NULL | T2 | 1 = customer meets validity criteria (KYC/AML). Passthrough from parent. |
| 14 | IsCreditReportValidCB | bit | NULL | T2 | 1 = credit bureau report on file and valid. Passthrough from parent. |
| 15 | IsDLTUser | int | NULL | T2 | Flag indicating if customer is a DLT (Distributed Ledger Technology) participant. 0/1 as int. |
| 16 | RollOverFee | money | NULL | T2 | `SUM(ISNULL(RollOverFee,0))` YTD. Overnight financing/rollover fees collected. |
| 17 | TicketFee | money | NULL | T2 | `SUM(ISNULL(TicketFee,0))` YTD. Fixed per-trade ticket fee. |
| 18 | TicketFeeByPercent | money | NULL | T2 | `SUM(ISNULL(TicketFeeByPercent,0))` YTD. Percentage-based trade fee component. |
| 19 | AdminFee | money | NULL | T2 | `SUM(ISNULL(AdminFee,0))` YTD. Administrative fee. |
| 20 | SpotAdjustFee | money | NULL | T2 | `SUM(ISNULL(SpotAdjustFee,0))` YTD. Spot price adjustment fee for certain instrument types. |
| 21 | InvestedAmountOpen | money | NULL | T2 | `SUM(InvestedAmountOpen)` YTD. No ISNULL wrapper — treat NULL in parent as meaningful (no open positions). |
| 22 | CountUU | int | NULL | T2 | `SUM(CountUU)` YTD. Unique unit count — trade count metric. |
| 23 | IsMarginTrade | int | NULL | T2 | 0 = cash trade, 1 = margin trade. Passthrough from parent. |

---

## 6. Sample Distributions

### 6.1 InstrumentType (YTD 2026, ~2.65M rows)

| InstrumentType | % of Rows |
|---------------|-----------|
| Stocks | 39% |
| Crypto | 28% |
| ETF | 15% |
| Commodities | 10% |
| Indices | 5% |
| Currencies + Other | ~3% |

*Note: Stocks dominant at yearly grain vs Crypto dominant in Yesterday. Year-long accumulation levels out crypto activity.*

### 6.2 Mifid (approximate, consistent with Yesterday sibling)

| Mifid | Approx % |
|-------|----------|
| Retail | ~66% |
| Retail Pending | ~33% |
| Professional / Pending | <1% |

### 6.3 Year

Single value: `2026`. On Jan 1 edge case, this would hold `2025` for one execution cycle.

---

## 7. Query Advisory & Gotchas

### 7.1 RealCID Type Mismatch

`RealCID` is `bigint` in this table and `int` in all siblings (Yesterday, ThisMonth, MonthlyData, Last2weeks, LastYear). JOINs to customer dimension tables or sibling reports may require explicit `CAST(RealCID AS int)` — or the reverse — depending on the join target.

```sql
-- Safe cross-table join:
SELECT ty.RealCID, tm.Commissions AS MonthCommissions, ty.Commissions AS YearCommissions
FROM   BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear  ty
JOIN   BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth tm
    ON CAST(ty.RealCID AS int) = tm.RealCID
WHERE  ty.Year = 2026;
```

### 7.2 TRUNCATE + INSERT — Single Year Only

The table always holds exactly one year's data. There is no historical accumulation. For multi-year analysis, use `BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData` (which holds all months from Dec 2017).

### 7.3 Date Filter Side Effect

`DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE()))=0` captures everything from Jan 1 of the current year through yesterday. The parent table `BI_DB_DailyCommisionReport` may contain today's partial data if it runs intraday, but ThisYear will not include it until the next SP execution.

### 7.4 No Club / Country Dimension

If segmentation by Club tier or Country is required at yearly grain, the analyst must JOIN to `BI_DB_DailyCommisionReport_MonthlyData` or another dimension table. ThisYear has dropped these GROUP BY keys relative to Yesterday and ThisMonth.

### 7.5 CommissionInRisk is Always NULL

Do not use `CommissionInRisk` in analysis or aggregations. It will always be NULL.

### 7.6 Large Table — Scan Cost

At 2.65M rows for ~112 days, a full year (365 days) projects to ~8.6M rows. Always filter by `InstrumentType`, `Regulation`, or `IsMarginTrade` where possible to avoid full-table scans.

---

## 8. Downstream Consumers

No downstream consumers found in the SSDT repository (no views, SPs, or functions referencing `BI_DB_DailyCommisionReport_ThisYear`). Likely consumed directly by reporting tools (SSRS, Power BI, or ad-hoc queries).

**UC Target**: `_Not_Migrated` — no Unity Catalog target exists for this object.

---

## 9. Open Questions / Review Flags

See `BI_DB_DailyCommisionReport_ThisYear.review-needed.md` for full list.

1. **CommissionInRisk ghost**: Always NULL — confirm no planned population.
2. **RealCID bigint**: Why bigint here vs int in all siblings? Type migration planned?
3. **No Club/Country**: Was dropping these dimensions intentional at year grain?
4. **Jan 1 edge case**: Is prior-year data captured at year-start ever referenced downstream?

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 11/14*
*Tiers: 0 T1, 22 T2, 0 T3, 1 T4, 0 T5 | Elements: 23/23 (1 ghost: CommissionInRisk)*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear | Type: Table | Production Source: BI_DB_dbo.BI_DB_DailyCommisionReport via SP_DailyCommisionReport*
