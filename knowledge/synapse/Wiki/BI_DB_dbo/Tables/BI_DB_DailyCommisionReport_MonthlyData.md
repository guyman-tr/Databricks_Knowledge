# BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData

> 321.6M-row month-to-date commission satellite table (Dec 2017–Apr 2026, 101 months, 5.4M CIDs) that re-aggregates the parent BI_DB_DailyCommisionReport by customer × month × ISO week number, retaining the full revenue column set including VolumeOnOpen/Close, RollOverFee_SDRT, and TradingFees absent from other satellites. Each daily SP run deletes the current month's slice and re-inserts month-to-date by week, building a growing MTD view.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_DailyCommisionReport (via SP_DailyCommisionReport) |
| **Refresh** | DELETE WHERE Month=current_month + INSERT (incremental per month; re-aggregates full MTD each run) |
| **Row Count** | 321,587,915 rows (2026-04-13 sample); ~3.2M rows/month |
| **Date Range** | Month 201712 – 202604 (Dec 2017 – Apr 2026; 101 distinct months) |
| **Distinct CIDs** | 5,408,477 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Writer SP** | SP_DailyCommisionReport |

---

## 1. Business Meaning

BI_DB_DailyCommisionReport_MonthlyData is the month-and-week satellite of the DailyCommisionReport family. It re-aggregates the parent table's daily grain (BI_DB_DailyCommisionReport) into a month × ISO week × customer dimension grain. This makes it the richest monthly aggregation in the family — uniquely retaining VolumeOnOpen, VolumeOnClose, RollOverFee_SDRT (UK SDRT), TradingFees, and a weeknum (ISO week number) breakdown absent from other satellites.

**Each row represents**: one customer's commission and fee totals for a specific ISO week within a specific month, broken down by instrument type, regulation, club tier, and account manager. A customer active in 3 instrument types across 2 weeks of April 2026 produces 6 rows in MonthlyData for April.

**Load pattern**: Daily TRUNCATE-and-reinsert at the month level — DELETE WHERE Month = current_month, then re-INSERT all month-to-date data from @BeginMonthDateID (first of month) to @EndMonthDateID (end of month as EOMONTH). Prior-month data is permanent (deleted only when that month is the current month); current-month data grows by one day with each SP run.

**Backup history**: A backup snapshot existed as of 2024-12-16 (MonthlyData_Backup_20241216 DDL present in SSDT repo), suggesting this table has been subject to structural changes requiring rollback capability.

---

## 2. Business Logic

### 2.1 Month Encoding

**What**: Month is encoded as an integer combining year and month components.
**Columns Involved**: Month
**Rules**:
- Formula: `MONTH(FullDate) + YEAR(FullDate) * 100`
- Example: April 2026 → `4 + 2026*100 = 202604`
- This encoding is consistent across all DailyCommisionReport satellite tables that have a Month column

### 2.2 ISO Week Sub-Monthly Granularity

**What**: weeknum adds sub-monthly granularity by grouping data into ISO calendar weeks.
**Columns Involved**: weeknum
**Rules**:
- Formula: `DATEPART(WEEK, FullDate)` — US calendar week numbering (week starts Sunday, week 1 contains Jan 1)
- A month typically spans 4–5 calendar weeks
- April 2026 distribution: week 14 (537K rows), week 15 (785K rows), week 16 (76K rows as of Apr 13)
- weeknum is unique to MonthlyData among all DailyCommisionReport satellites — no other satellite retains week-level breakdown

### 2.3 Month-to-Date Accumulation

**What**: Current-month data accumulates daily; prior months are frozen.
**Columns Involved**: Month, UpdateDate
**Rules**:
- SP deletes the entire current month (WHERE Month = MONTH(@Date) + YEAR(@Date)*100) and re-inserts from day 1 to end-of-month
- Parent BI_DB_DailyCommisionReport only has data through @Date, so MonthlyData always reflects MTD
- UpdateDate (NOT NULL, unlike sibling satellites) confirms the last full-month recalculation timestamp
- Historical months (Month < current) are stable — the DELETE scope is limited to the current month only

### 2.4 Instrument Type Distribution

**What**: InstrumentType segments revenue by asset class.
**Columns Involved**: InstrumentType, IsMarginTrade
**Rules**:
- 2026 YTD values: Stocks (5.6M rows, 0% margin), Crypto Currencies (2.4M), ETF (1.9M), Commodities (1.5M), Indices (814K), Currencies (378K)
- IsMarginTrade=1 rows are rare (<0.1%): Stocks margin (3.3K), ETF margin (56)
- NA appears (~1.5K rows) for edge cases where InstrumentType is undetermined

### 2.5 Regulation and Club Breakdown

**What**: Customer regulatory jurisdiction and club tier are preserved as dimension columns.
**Columns Involved**: Regulation, Club
**Rules**:
- 2026 Regulation distribution: CySEC (7.7M), FCA (3.0M), FSA Seychelles (902K), ASIC & GAML (498K), FSRA (455K), FinCEN+FINRA (88K), BVI (26K), others
- Club distribution: Bronze (6.0M), Gold (2.1M), Silver (1.8M), Platinum (1.3M), Platinum Plus (1.2M), Diamond (164K), Internal (32K)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on RealCID. For month-level aggregations across many customers, this is reasonable — but the 321M-row count means full-table scans are expensive. Always filter on Month first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly commission totals by regulation | `WHERE Month = 202604 GROUP BY Regulation` |
| Week-over-week revenue trend within month | `WHERE Month = 202604 GROUP BY weeknum, InstrumentType` |
| Customer's year-to-date Commissions | `WHERE Month >= 202601 AND RealCID = @cid GROUP BY Month, weeknum` |
| Full month comparison (April vs March) | `WHERE Month IN (202604, 202603) GROUP BY Month, InstrumentType` |
| Prior-months query (stable data) | `WHERE Month < 202604` — safe, no MTD variability |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON dc.RealCID = t.RealCID | Enrich with email, birth date, etc. |
| DWH_dbo.Dim_Instrument | ON di.InstrumentType = t.InstrumentType | Add instrument type ID |
| BI_DB_DailyCommisionReport | ON p.DateID BETWEEN BeginMonth AND EndMonth | Back-join to daily grain |

### 3.4 Gotchas

- **MTD variability**: Current month data changes every day. Do NOT cache or snapshot without Month filter.
- **weeknum is year-spanning**: ISO week 1 of 2026 may include Dec 2025 days. Cross-month weeks appear in two different Month groups.
- **321M rows**: Unfiltered COUNT(*) or GROUP BY without Month filter is expensive. Always add `WHERE Month = YYYYMM` or `WHERE Month >= YYYYMM`.
- **UpdateDate is NOT NULL** in MonthlyData (unlike sibling satellites which allow NULL) — DDL enforces `NOT NULL` constraint.
- **CommissionInRisk absent**: Unlike Yesterday, ThisMonth, ThisYear satellites which have a ghost CommissionInRisk column (always NULL), MonthlyData DDL does NOT include CommissionInRisk at all.
- **VolumeOnOpen/VolumeOnClose/RollOverFee_SDRT/TradingFees**: These 4 metric columns exist ONLY in MonthlyData among all DailyCommisionReport satellites. Do not expect them in Yesterday, ThisMonth, or ThisYear.
- **Backup table**: `BI_DB_DailyCommisionReport_MonthlyData_Backup_20241216` exists in the SSDT repo — do not confuse with the live table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from BI_DB_DailyCommisionReport (SP_DailyCommisionReport ETL logic) |
| Tier 4 | Inferred from DDL/structural analysis; no SP code or upstream wiki confirmation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID via parent BI_DB_DailyCommisionReport. CLUSTERED INDEX key for date-range scans. (Tier 2 — SP_DailyCommisionReport) |
| 2 | Club | varchar(100) | YES | Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, Internal) as of the reporting date. From BI_DB_Client_Balance_CID_Level_New.Club via parent table. (Tier 2 — SP_DailyCommisionReport) |
| 3 | Manager | varchar(100) | YES | Account manager full name — Dim_Manager.FirstName + ' ' + LastName via Fact_SnapshotCustomer.AccountManagerID, propagated from parent. (Tier 2 — SP_DailyCommisionReport) |
| 4 | Country | varchar(100) | YES | Full country name sourced from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name) via parent table. (Tier 2 — SP_DailyCommisionReport) |
| 5 | Region | varchar(100) | YES | Marketing region label from Dim_Country.MarketingRegionManualName. NOT geographic region — uses eToro marketing territory classification (UK, Italian, German, Arabic, CEE, SEA, Latam, etc.). (Tier 2 — SP_DailyCommisionReport) |
| 6 | Month | int | YES | Year-month integer combining month and year: MONTH(FullDate) + YEAR(FullDate)*100. E.g., April 2026 = 202604. GROUP BY dimension replacing FullDate/DateID for monthly grain. (Tier 2 — SP_DailyCommisionReport) |
| 7 | UserName | varchar(100) | YES | Customer username from Dim_Customer.UserName as of the reporting period. (Tier 2 — SP_DailyCommisionReport) |
| 8 | Commissions | money | YES | Net commission — SUM(ISNULL(Commissions,0)) from parent BI_DB_DailyCommisionReport. Sum of Function_Revenue_Commissions output for the week×month grain. Commission on opens + close adjustment. (Tier 2 — SP_DailyCommisionReport) |
| 9 | FullCommissions | money | YES | Gross full commission — SUM(ISNULL(FullCommissions,0)) from parent. Sum of Function_Revenue_FullCommissions for MiFID regulatory revenue reporting. (Tier 2 — SP_DailyCommisionReport) |
| 10 | weeknum | int | YES | ISO calendar week number within the year: DATEPART(WEEK, FullDate). Provides sub-monthly granularity unique to this satellite — other satellites do not retain week breakdown. Week starts Sunday (US calendar). April 2026: weeks 14–16. (Tier 2 — SP_DailyCommisionReport) |
| 11 | UpdateDate | datetime | NO | GETDATE() at ETL execution time. NOT NULL constraint (unique among DailyCommisionReport satellites; siblings allow NULL). Indicates timestamp of last full-month recalculation. (Tier 2 — SP_DailyCommisionReport) |
| 12 | Regulation | varchar(50) | YES | Regulatory jurisdiction label as of the reporting date: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, BVI, MAS, ASIC, eToroUS, NYDFS+FINRA. From BI_DB_Client_Balance_CID_Level_New.ToRegulation. (Tier 2 — SP_DailyCommisionReport) |
| 13 | Mifid | varchar(50) | YES | MiFID categorization label: Retail, Retail Pending, Pending, Elective professional, Professional. From BI_DB_Client_Balance_CID_Level_New.MifidCategory. (Tier 2 — SP_DailyCommisionReport) |
| 14 | VolumeOnOpen | money | YES | USD trading volume for positions opened — SUM(ISNULL(VolumeOnOpen,0)) from parent. From Function_Trading_Volume. Unique to MonthlyData among all DailyCommisionReport satellites. (Tier 2 — SP_DailyCommisionReport) |
| 15 | VolumeOnClose | money | YES | USD trading volume for positions closed — SUM(ISNULL(VolumeOnClose,0)) from parent. From Function_Trading_Volume. Unique to MonthlyData among all DailyCommisionReport satellites. (Tier 2 — SP_DailyCommisionReport) |
| 16 | RollOverFee | money | YES | Daily overnight rollover/carry fee — SUM(ISNULL(RollOverFee,0)) from parent. From Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight. (Tier 2 — SP_DailyCommisionReport) |
| 17 | InstrumentType | varchar(100) | YES | Instrument type label from Dim_Instrument.InstrumentType: Stocks, Crypto Currencies, ETF, Commodities, Indices, Currencies, NA. Propagated from parent BI_DB_DailyCommisionReport. (Tier 2 — SP_DailyCommisionReport) |
| 18 | IsValidCustomer | bit | YES | 1 if customer meets eToro's valid customer criteria (non-demo, depositor, active) as of the reporting date. From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 19 | IsCreditReportValidCB | bit | YES | Credit report validity flag for US credit bureau reporting. From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 20 | RollOverFee_SDRT | float | YES | UK Stamp Duty Reserve Tax — SUM(ISNULL(RollOverFee_SDRT,0)) from parent. From Function_Revenue_SDRT. Applies to UK equity transactions. Added to parent 2023-10-31. Unique to MonthlyData among all DailyCommisionReport satellites. (Tier 2 — SP_DailyCommisionReport) |
| 21 | TradingFees | float | YES | Composite trading fee total — SUM(ISNULL(TradingFees,0)) from parent. Equals ISNULL(AdminFee,0)+ISNULL(SpotAdjustFee,0)+ISNULL(TicketFee,0)+ISNULL(TicketFeeByPercent,0) at daily level. Unique to MonthlyData among all DailyCommisionReport satellites. (Tier 2 — SP_DailyCommisionReport) |
| 22 | IsDLTUser | int | YES | Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added to parent 2024-07-30. (Tier 2 — SP_DailyCommisionReport) |
| 23 | TicketFee | money | YES | Per-ticket transaction fee — SUM(ISNULL(TicketFee,0)) from parent. From Function_Revenue_TicketFee. Fixed fee per trade. (Tier 2 — SP_DailyCommisionReport) |
| 24 | TicketFeeByPercent | money | YES | Percentage-based ticket fee — SUM(ISNULL(TicketFeeByPercent,0)) from parent. From Function_Revenue_TicketFeeByPercent. Alternative percentage fee structure. (Tier 2 — SP_DailyCommisionReport) |
| 25 | AdminFee | money | YES | Islamic finance / administration fee — SUM(ISNULL(AdminFee,0)) from parent. From Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover. (Tier 2 — SP_DailyCommisionReport) |
| 26 | SpotAdjustFee | money | YES | Spot price adjustment fee — SUM(ISNULL(SpotAdjustFee,0)) from parent. From Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing. (Tier 2 — SP_DailyCommisionReport) |
| 27 | InvestedAmountOpen | money | YES | USD invested amount for positions opened — SUM(InvestedAmountOpen) from parent. From Function_Trading_Volume. (Tier 2 — SP_DailyCommisionReport) |
| 28 | CountUU | int | YES | Sum of unique-user count from parent rows — SUM(CountUU). In parent, CountUU = COUNT(DISTINCT CID) per grain; in this satellite, SUM gives total unique-user contribution weight for the week×month grain. (Tier 2 — SP_DailyCommisionReport) |
| 29 | IsMarginTrade | int | YES | 1 if SettlementTypeID=5 (margin-funded position). From parent BI_DB_DailyCommisionReport. Added to parent 2025-10-23. IsMarginTrade=1 rows are rare (<0.1%): Stocks margin (3.3K in 2026 YTD), ETF margin (56). (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Intermediate Source | Source Column | Transform |
|---------------|--------------------|--------------| ---------|
| All columns | BI_DB_DailyCommisionReport | Various | GROUP BY aggregation (SUM for metrics, passthrough for dimensions) |
| Month | BI_DB_DailyCommisionReport.FullDate | FullDate | MONTH(FullDate) + YEAR(FullDate)*100 |
| weeknum | BI_DB_DailyCommisionReport.FullDate | FullDate | DATEPART(WEEK, FullDate) |
| UpdateDate | ETL runtime | — | GETDATE() |

### 5.2 ETL Pipeline

```
eToro production DBs (Trade, BackOffice, Billing, etc.)
  |-- Generic Pipeline (Bronze exports) --|
  v
DWH_dbo dimensions (Dim_Customer, Dim_Manager, Dim_Country, Dim_Instrument, etc.)
  + BI_DB_dbo revenue TVFs (Function_Revenue_*, Function_Trading_Volume)
    |-- SP_DailyCommisionReport @Date (Phase 1 of pipeline) --|
    v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (321M+ rows total | daily grain | DateID × RealCID × instrument dims)
    |-- SP_DailyCommisionReport @Date (Phase N of same SP run) --|
    |   DELETE WHERE Month = MONTH(@Date) + YEAR(@Date)*100
    |   INSERT FROM BI_DB_DailyCommisionReport
    |   WHERE DateID BETWEEN @BeginMonthDateID AND @EndMonthDateID
    |   GROUP BY RealCID, Club, Manager, Country, Region,
    |            MONTH(FullDate)+YEAR(FullDate)*100, UserName,
    |            DATEPART(WEEK,FullDate), Regulation, Mifid,
    |            InstrumentType, IsValidCustomer, IsCreditReportValidCB,
    |            IsDLTUser, IsMarginTrade
    v
BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData
  (321.6M rows | Month+weeknum grain | Dec 2017–Apr 2026 | 101 months | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Derived from | BI_DB_dbo.BI_DB_DailyCommisionReport | Parent daily commission fact; source of all metrics and dimensions |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified in the SSDT repo. Terminal reporting output, consumed directly by BI tools.

---

## 7. Sample Queries

### Monthly Revenue by Regulation (Current Month)
```sql
SELECT Regulation, InstrumentType,
       SUM(Commissions) AS TotalCommissions,
       SUM(FullCommissions) AS TotalFullCommissions,
       SUM(RollOverFee) AS TotalRollOver
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_MonthlyData]
WHERE Month = 202604
GROUP BY Regulation, InstrumentType
ORDER BY TotalCommissions DESC
```

### Week-over-Week Trend Within Month
```sql
SELECT weeknum, InstrumentType,
       SUM(Commissions) AS WeekCommissions,
       SUM(VolumeOnOpen) AS WeekVolumeOpen,
       COUNT(DISTINCT RealCID) AS ActiveCustomers
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_MonthlyData]
WHERE Month = 202604
GROUP BY weeknum, InstrumentType
ORDER BY weeknum, WeekCommissions DESC
```

### YTD Commission Rollup by Club
```sql
SELECT Club, Month,
       SUM(Commissions) AS MonthlyCommissions,
       SUM(TradingFees) AS MonthlyTradingFees
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_MonthlyData]
WHERE Month >= 202601
GROUP BY Club, Month
ORDER BY Month, Club
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Context derived from SP code, DDL, live data sampling, and parent table wiki (BI_DB_DailyCommisionReport, Batch 20).

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 11/14*
*Tiers: 0 T1, 29 T2, 0 T3, 0 T4, 0 T5 | Elements: 29/29, Logic: 5/10*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData | Type: Table | Production Source: BI_DB_dbo.BI_DB_DailyCommisionReport via SP_DailyCommisionReport*
