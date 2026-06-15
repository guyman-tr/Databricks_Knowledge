# BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks

> Rolling two-week customer-weekly commission aggregation. Each row summarises all commission and fee revenue for a single customer (RealCID) within a single calendar week, within a single InstrumentType × Regulation × Mifid × Club × Country segment, covering the last ~14 days of trading activity. Holds ~861K rows spanning 2 weeks (202615–202616 as of 2026-04-22) across ~521K unique CIDs. Fully replaced daily by SP_DailyCommisionReport via TRUNCATE+INSERT from the parent BI_DB_DailyCommisionReport. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DailyCommisionReport — reads BI_DB_dbo.BI_DB_DailyCommisionReport |
| **Refresh** | Daily full replace: TRUNCATE then INSERT from rolling 2-week window |
| **Window** | DateID >= Sunday two calendar weeks before the run date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **Row Count** | ~861K rows (as of 2026-04-22, 2 weeks: 202615–202616, ~521K CIDs) |
| **Grain** | RealCID × Week × InstrumentType × Regulation × Mifid × Club × Manager × Country × Region × UserName × IsValidCustomer × IsCreditReportValidCB × IsDLTUser × IsMarginTrade |
| **Documented** | 2026-04-22, Batch 21 |

---

## 1. Business Meaning

`BI_DB_DailyCommisionReport_Last2weeks` is the rolling weekly view of the Daily Commission Report pipeline. It collapses daily parent-table rows into weekly totals per customer×segment, covering a rolling window of the last two calendar weeks (current partial week plus the most recently completed week). The CID-level grain is retained — unlike the Instrument_Agg satellite which removes the CID — making this table suitable for per-customer weekly revenue reporting, customer-facing dashboards, and account manager performance tracking.

The table is fully replaced every day: SP_DailyCommisionReport truncates the entire table and re-inserts all rows from the parent `BI_DB_DailyCommisionReport` where the date falls within the rolling two-week window (defined as `DateID >= Sunday two weeks before @Date`). As a result, the table always reflects the most recent two weeks; no historical data beyond that window is retained here (see the parent table or Instrument_Agg for longer history).

The GROUP BY dimensions are: RealCID, Club, Manager, Country, Region, UserName, Regulation, Mifid, InstrumentType, IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade — grouped per calendar week (DATEPART(WEEK, FullDate) + YEAR(FullDate) × 100). The Week column encodes both the year and week number as a single integer (e.g., 202615). The weeknum column carries only the week-of-year number.

**The `IsThisWeek` column** distinguishes the current in-progress week (1) from the most recently completed prior week (0). It is stored as `[money]` type despite being a 0/1 flag — an artefact of the money-typed parent column ecosystem.

**1 of 27 DDL columns is always NULL**: `CommissionInRisk` is in the DDL but absent from the SP INSERT column list. It is a ghost column that was never activated. Confirmed via live data sampling (100% NULL).

---

## 2. Business Logic

### 2.1 Full Replace Load Pattern

**What**: Unlike the incremental DELETE+INSERT used by Instrument_Agg, this satellite uses a daily TRUNCATE+INSERT. The entire table content is replaced on every SP run. There is no row-level idempotency — running the SP twice in one day produces duplicate rows.

**Columns Involved**: All columns

**Rules**:
- `TRUNCATE TABLE BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks`
- `INSERT INTO ... SELECT ... FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK) WHERE DateID >= [Sunday 2 weeks before @Date] GROUP BY ...`
- The window always starts on a Sunday — partial current week rows from Monday of the current week through the run date are included
- Do not run SP_DailyCommisionReport multiple times on the same day without manual cleanup of this table

### 2.2 Rolling 2-Week Window

**What**: The date filter anchors to the Sunday two calendar weeks before the run date, computed within the SP. This means the window always covers at most two complete ISO weeks plus a partial current week fragment.

**Columns Involved**: DateID (filter applied to source), Week, weeknum, IsThisWeek

**Rules**:
- Window start = Sunday of the week two weeks prior to @Date (computed in SP as a date arithmetic expression)
- Window always includes the current partial week (days of the current week up to and including @Date)
- As the run date advances, the window shifts forward and older data drops out of the table
- For historical two-week views, use the parent table `BI_DB_DailyCommisionReport` with explicit date range filters

### 2.3 Week Encoding — Week vs weeknum

**What**: The SP encodes calendar weeks in two columns using different representations of the same underlying DATEPART(WEEK, FullDate) value.

**Columns Involved**: Week, weeknum

**Rules**:
- `Week` = `DATEPART(WEEK, FullDate) + YEAR(FullDate) * 100` — a composite integer: year × 100 + week number. Example: week 15 of 2026 = 202615. Use for cross-year comparisons and as a GROUP BY key
- `weeknum` = `DATEPART(WEEK, FullDate)` — week-of-year number only (1–53). Drops year context; ambiguous across year boundaries
- `DATEPART(WEEK, ...)` follows the session's `SET DATEFIRST` setting — typically Sunday-anchored in this environment
- Both columns are GROUP BY keys; the table grain is at the Week level, not weeknum

### 2.4 IsThisWeek Flag

**What**: A row-level flag that marks whether the week in question is the current in-progress week of the SP run date. Enables quick separation of complete-week totals from the partial current-week accumulation.

**Columns Involved**: IsThisWeek, Week

**Rules**:
- `CASE WHEN DATEPART(WEEK,FullDate)+YEAR(FullDate)*100 = DATEPART(WEEK,@Date)+YEAR(@Date)*100 THEN 1 ELSE 0 END`
- 1 = rows belong to the current (in-progress) week; 0 = rows belong to the prior complete week
- **Stored as `[money]` type** despite being a 0/1 flag — consistent with other flag columns that were typed money in earlier schema iterations
- Filter `WHERE IsThisWeek = 0` to analyse only the last complete week; `WHERE IsThisWeek = 1` for current-week partial accumulation

### 2.5 CommissionInRisk — Ghost Column

**What**: `CommissionInRisk` exists in the DDL but is never written by SP_DailyCommisionReport. It is absent from the INSERT column list, so the column remains NULL for every row.

**Columns Involved**: CommissionInRisk

**Rules**:
- Always NULL — confirmed via live sampling (100% of ~861K rows)
- Do not use in any filter or aggregation
- The column name suggests a commission-at-risk metric (potentially planned for margin risk reporting) that was never implemented

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no data skew; rows spread across all distributions
- **Clustered Index**: RealCID ASC — efficient lookup and range scans by customer ID; JOIN to customer dimension tables benefits from this clustering
- **No partition**: The rolling 2-week window is enforced by the ETL, not by table partitioning; there is no benefit from partition elimination since the full table is always the 2-week set

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Last complete week revenue by region | `WHERE IsThisWeek = 0 GROUP BY Region` |
| Customer weekly commission for account manager review | `WHERE Manager = 'X' ORDER BY Commissions DESC` |
| Current week vs prior week commission comparison | `GROUP BY IsThisWeek, Regulation` |
| Per-regulation weekly totals | `GROUP BY Week, Regulation, SUM(Commissions)` |
| High-value customers in current rolling window | `WHERE IsThisWeek IN (0,1) AND Commissions > X ORDER BY Commissions DESC` |
| Crypto revenue share of weekly total | `WHERE InstrumentType = 'Crypto Currencies'` vs total |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DailyCommisionReport | `RealCID = RealCID AND DateID within window` | Drill down from weekly totals to daily/trade-level detail |
| Dim_Customer (if exists) | `RealCID = CID` | Add customer attributes not in this table |
| BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear | `RealCID = RealCID AND Regulation = Regulation` | Year-over-year comparison at customer level |

### 3.4 Gotchas

- **CommissionInRisk is always NULL** — this column is in the DDL but the SP never populates it; filtering on it or expecting values will return empty results
- **IsThisWeek is stored as `money` type** — cast to int before using in WHERE or GROUP BY to avoid type surprises: `WHERE CAST(IsThisWeek AS int) = 1`
- **No history beyond 2 weeks** — the table is truncated daily; for anything older than the current rolling window, query the parent `BI_DB_DailyCommisionReport` directly
- **Week encoding spans year boundaries** — `Week` = 202615 correctly encodes the year; `weeknum` alone = 15 is ambiguous (week 15 of any year). Always use `Week` for cross-date comparisons
- **NOLOCK hint in source query** — the SP reads from the parent with `WITH (NOLOCK)`, meaning uncommitted rows from the parent's own ETL run can be included in this table if the SP runs mid-parent-insert
- **TRUNCATE is not transactional with INSERT** — if the SP fails between TRUNCATE and INSERT completion, the table can be left empty; monitor ETL completion status before consuming this table

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | ETL-computed by SP_DailyCommisionReport; logic is code-documented in SSDT |
| **Tier 4** | Legacy / deprecated — column exists in DDL but is always NULL; SP does not insert it |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer integer ID. Clustering key. The individual customer retained at this aggregation level (unlike Instrument_Agg which removes CID). (Tier 2 — SP_DailyCommisionReport) |
| 2 | Club | varchar(100) | YES | Customer club/tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, etc.). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 3 | Manager | varchar(100) | YES | Account manager name. GROUP BY pass-through. Used for account manager performance reporting. (Tier 2 — SP_DailyCommisionReport) |
| 4 | Country | varchar(100) | YES | Customer country name. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 5 | Region | varchar(100) | YES | Marketing region label. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 6 | Week | int | YES | Composite week code: `DATEPART(WEEK, FullDate) + YEAR(FullDate) * 100` (e.g., 202615 = week 15 of 2026). Primary time dimension for this table. Use for cross-year safe week comparisons. (Tier 2 — SP_DailyCommisionReport) |
| 7 | UserName | varchar(100) | YES | Customer username string. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 8 | Commissions | money | YES | SUM of net eToro commission (spread-based revenue, net-to-company) for the week. (Tier 2 — SP_DailyCommisionReport) |
| 9 | FullCommissions | money | YES | SUM of gross full commission (including all fees; MIFID best-execution reporting basis) for the week. (Tier 2 — SP_DailyCommisionReport) |
| 10 | CommissionInRisk | money | YES | **Always NULL — ghost column.** Present in DDL but absent from the SP INSERT column list; never populated. Likely a planned commission-at-risk risk metric that was never implemented. (Tier 4 — Legacy/Deprecated) |
| 11 | weeknum | int | YES | ISO week-of-year number: `DATEPART(WEEK, FullDate)` (1–53). Convenience column; loses year context. Use `Week` for cross-year-safe aggregation. (Tier 2 — SP_DailyCommisionReport) |
| 12 | UpdateDate | datetime | YES | ETL execution timestamp (`GETDATE()` at SP run time). Marks when this batch was written; not a business date. (Tier 2 — SP_DailyCommisionReport) |
| 13 | Regulation | varchar(50) | YES | Regulatory jurisdiction label (CySEC, FCA, ASIC, FSAS, GLOBAL, etc.). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 14 | Mifid | varchar(50) | YES | MiFID classification label (e.g., 'MIFID', 'Non-MIFID'). Separate from Regulation — captures MIFID applicability independently of the regulatory entity. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 15 | InstrumentType | varchar(100) | YES | Instrument type name (Currencies, Commodities, Indices, Stocks, Crypto Currencies, ETF). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 16 | IsValidCustomer | bit | YES | Valid customer quality flag (1=passes validation criteria for revenue reporting). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 17 | IsCreditReportValidCB | bit | YES | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 18 | IsDLTUser | int | YES | Distributed ledger technology (DLT) / blockchain user flag (1=yes). GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |
| 19 | RollOverFee | money | YES | SUM of overnight rollover/carry fees charged to this customer in the week. (Tier 2 — SP_DailyCommisionReport) |
| 20 | TicketFee | money | YES | SUM of per-ticket transaction fees for the week. (Tier 2 — SP_DailyCommisionReport) |
| 21 | TicketFeeByPercent | money | YES | SUM of percentage-based ticket fees for the week. (Tier 2 — SP_DailyCommisionReport) |
| 22 | AdminFee | money | YES | SUM of Islamic finance / administration fees for the week (Sharia-compliant swap-free account charge). (Tier 2 — SP_DailyCommisionReport) |
| 23 | SpotAdjustFee | money | YES | SUM of spot price adjustment fees for the week. (Tier 2 — SP_DailyCommisionReport) |
| 24 | IsThisWeek | money | YES | Current-week flag: 1=row belongs to the in-progress week of the SP run date, 0=row belongs to the prior complete week. Computed as a CASE expression in the SP. **Stored as `money` type despite being a 0/1 flag** — cast to int before filtering. (Tier 2 — SP_DailyCommisionReport) |
| 25 | InvestedAmountOpen | money | YES | SUM of USD invested amount for positions opened within the two-week window. (Tier 2 — SP_DailyCommisionReport) |
| 26 | CountUU | int | YES | SUM of unique-user count values from parent rows within the week. At this aggregation level, customers trading multiple instrument types are counted per segment. (Tier 2 — SP_DailyCommisionReport) |
| 27 | IsMarginTrade | int | YES | Margin-funded position flag (1=position funded by eToro margin; SettlementTypeID=5). Added 2025-10-23. GROUP BY pass-through. (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

All 27 columns originate from `BI_DB_dbo.BI_DB_DailyCommisionReport` via `SP_DailyCommisionReport`. 26 columns are Tier 2 (populated). 1 column is Tier 4 (CommissionInRisk — ghost, always NULL). See `BI_DB_DailyCommisionReport_Last2weeks.lineage.md` for the full per-column lineage table.

| Synapse Column | Source Table | Transform |
|---------------|-------------|-----------|
| RealCID, Club, Manager, Country, Region, UserName, Regulation, Mifid, InstrumentType, IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade | BI_DB_dbo.BI_DB_DailyCommisionReport | GROUP BY pass-through |
| Week | BI_DB_dbo.BI_DB_DailyCommisionReport.FullDate | DATEPART(WEEK, FullDate) + YEAR(FullDate) * 100 |
| weeknum | BI_DB_dbo.BI_DB_DailyCommisionReport.FullDate | DATEPART(WEEK, FullDate) |
| IsThisWeek | BI_DB_dbo.BI_DB_DailyCommisionReport.FullDate | CASE WHEN current_week THEN 1 ELSE 0 END |
| Commissions, FullCommissions, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, InvestedAmountOpen, CountUU | BI_DB_dbo.BI_DB_DailyCommisionReport | SUM() aggregations |
| UpdateDate | — | GETDATE() at SP execution |
| CommissionInRisk | — | Always NULL — not in INSERT list |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (rolling 2-week window)
  — customer×instrument×position grain — dates >= Sunday 2 weeks before @Date
  |
  | SP_DailyCommisionReport @Date
  |   (runs after Instrument_Agg insert in the same execution)
  |
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_Last2weeks
  |   INSERT INTO BI_DB_DailyCommisionReport_Last2weeks (26 columns)
  |     SELECT ... SUM(Commissions/FullCommissions/RollOverFee/...)
  |     FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK)
  |     WHERE DateID >= [Sunday 2 weeks before @Date]
  |     GROUP BY RealCID, Club, Manager, Country, Region,
  |              DATEPART(WEEK,FullDate)+YEAR(FullDate)*100, UserName,
  |              Regulation, Mifid, InstrumentType, IsValidCustomer,
  |              IsCreditReportValidCB, IsDLTUser, IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
  (~861K rows | 2 weeks: 202615-202616 | ~521K CIDs | CLUSTERED INDEX RealCID | ROUND_ROBIN)
  |
  |-- NOT migrated to Unity Catalog ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| All columns | BI_DB_dbo.BI_DB_DailyCommisionReport | Immediate source — rolling 2-week filter applied to parent |

### 6.2 Referenced By

| Object | Type | Usage |
|--------|------|-------|
| BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear | Table (sister satellite) | Not a direct dependency, but analysts compare weekly data here against annual totals in LastYear by RealCID |

---

## 7. Sample Queries

### Last complete week commission by regulation and instrument type

```sql
SELECT
    Regulation,
    InstrumentType,
    SUM(Commissions)     AS TotalCommissions,
    SUM(FullCommissions) AS TotalFullCommissions,
    SUM(RollOverFee)     AS TotalRolloverFees,
    COUNT(DISTINCT RealCID) AS CustomerCount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
WHERE CAST(IsThisWeek AS int) = 0   -- prior complete week only
GROUP BY Regulation, InstrumentType
ORDER BY TotalCommissions DESC;
```

### Current week vs prior week revenue comparison by region

```sql
SELECT
    Region,
    SUM(CASE WHEN CAST(IsThisWeek AS int) = 1 THEN Commissions ELSE 0 END) AS CurrentWeek,
    SUM(CASE WHEN CAST(IsThisWeek AS int) = 0 THEN Commissions ELSE 0 END) AS PriorWeek
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
WHERE IsValidCustomer = 1
GROUP BY Region
ORDER BY CurrentWeek DESC;
```

### Top customers by weekly commission for account manager review

```sql
SELECT TOP 100
    RealCID,
    UserName,
    Manager,
    Country,
    Club,
    Week,
    SUM(Commissions)  AS WeeklyCommissions,
    SUM(RollOverFee)  AS WeeklyRollover
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
WHERE CAST(IsThisWeek AS int) = 0
  AND IsValidCustomer = 1
GROUP BY RealCID, UserName, Manager, Country, Club, Week
ORDER BY WeeklyCommissions DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira tickets or Confluence pages were found specifically for this satellite table. Context for the parent pipeline is documented in `BI_DB_DailyCommisionReport` (Batch 20). The rolling two-week window and TRUNCATE+INSERT pattern are defined exclusively in SP_DailyCommisionReport (SSDT).

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 26 T2, 0 T3, 1 T4 | Elements: 27/27, Logic: 8/10, Coverage: 10/10*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks | Type: Table | Production Source: SP_DailyCommisionReport*
