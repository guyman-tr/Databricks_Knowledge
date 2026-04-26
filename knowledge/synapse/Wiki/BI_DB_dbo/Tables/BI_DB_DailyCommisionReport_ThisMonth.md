# BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth

> Month-to-date commission rollup for the current calendar month (April 2026: 877,614 rows, 563,770 distinct CIDs) that re-aggregates the parent BI_DB_DailyCommisionReport from the first day of the current month to the most recent run date. Fully replaced (TRUNCATE+INSERT) on each daily SP run — always reflects the current month's MTD totals. Grain: customer × Month × instrument type × customer dimensions. Contains CommissionInRisk ghost column (DDL only, always NULL).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_DailyCommisionReport WHERE DateID>=first-of-month (via SP_DailyCommisionReport) |
| **Refresh** | TRUNCATE + INSERT (full replace daily; always contains current month MTD) |
| **Row Count** | 877,614 rows (April 2026 MTD as of 2026-04-13; ~800K–1.5M typical month) |
| **Date Range** | Single month: 202604 (April 2026 MTD); updated daily |
| **Distinct CIDs** | 563,770 (April 2026 MTD) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Writer SP** | SP_DailyCommisionReport |

---

## 1. Business Meaning

BI_DB_DailyCommisionReport_ThisMonth provides the current-month-to-date commission summary, collapsed to the coarsest time grain in the DailyCommisionReport satellite family (month level, no week breakdown). It aggregates all trading activity from the first of the current month through the most recent SP run date, grouped by customer, month, instrument type, regulation, club, and other customer dimensions.

**Each row represents**: one customer's total commission and fees for the entire month-to-date period, broken down by instrument type, regulation, club, and account manager. A customer active in 4 asset classes during April 2026 produces 4 rows.

**Load pattern**: TRUNCATE then INSERT FROM BI_DB_DailyCommisionReport WHERE DateID >= FORMAT(@DateMonth, 'yyyyMMdd'). The @DateMonth variable has special handling for month-start edge case: if the SP runs on day 1 of a month (before the prior month is complete), @DateMonth is set to the first day of the prior month — ensuring continuity.

**Key distinction from MonthlyData**: ThisMonth has no weeknum breakdown (all month-to-date data merged into a single Month value per grain). ThisMonth is coarser but simpler to query for "how is this month going?" analytics.

**Backup history**: A backup snapshot existed as of 2024-11-14 (ThisMonth_Backup_20241114 DDL in SSDT repo), indicating a structural migration around that date.

---

## 2. Business Logic

### 2.1 Month Encoding

**What**: Month is encoded as an integer combining year and month.
**Columns Involved**: Month
**Rules**:
- Formula: `MONTH(FullDate) + YEAR(FullDate)*100`
- Example: April 2026 → 202604
- Since TRUNCATE+INSERT replaces all data, only one Month value will ever be present at any time

### 2.2 Month-Start Edge Case Handling

**What**: The SP handles the month boundary to avoid an empty or partial result on the first day of a new month.
**Columns Involved**: Month, UpdateDate
**Rules**:
- SP logic: `DECLARE @DateMonth DATE = CASE WHEN DAY(GETDATE()) = 1 THEN DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE())-1, 0) ELSE DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE()), 0) END`
- If SP runs on day 1 (e.g., May 1): @DateMonth = April 1 → table shows all of April
- If SP runs on any other day (e.g., April 13): @DateMonth = April 1 → table shows April 1–12 MTD
- This creates a one-day overlap: on day 1 of month N, the table holds all of month N-1 rather than a single-row month N

### 2.3 CommissionInRisk Ghost Column

**What**: CommissionInRisk is in the DDL but never populated.
**Columns Involved**: CommissionInRisk
**Rules**:
- DDL: `[CommissionInRisk] [money] NULL` (column 10 in DDL order)
- SP INSERT list (lines 1424–1449) does not include CommissionInRisk
- Always NULL — confirmed from live sample (April 2026: all CommissionInRisk = NULL)
- Pattern consistent with Yesterday, Last2weeks, and LastYear satellites
- Do NOT use this column — it has no data

### 2.4 Instrument Type Distribution

**What**: InstrumentType segments MTD revenue by asset class.
**Columns Involved**: InstrumentType, IsMarginTrade
**Rules**:
- April 2026 MTD: Stocks (369K rows, 42%), Crypto Currencies (195K, 22%), ETF (131K, 15%), Commodities (102K, 12%), Indices (62K, 7%), Currencies (18K, 2%)
- IsMarginTrade=1: Stocks margin (460 rows), all others 0 — rare
- NA (158 rows) for edge cases where instrument type is undetermined

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on RealCID. Table size (~877K rows for a partial month) is moderate — most queries are fast without needing partition filtering. No Month WHERE clause needed since only one month exists.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| MTD commission by regulation | `SELECT Regulation, SUM(Commissions) GROUP BY Regulation ORDER BY 2 DESC` |
| MTD active customers by club | `SELECT Club, COUNT(DISTINCT RealCID) FROM ... GROUP BY Club` |
| MTD revenue by asset class | `SELECT InstrumentType, SUM(Commissions), SUM(RollOverFee) GROUP BY InstrumentType` |
| Compare MTD vs. full last month | JOIN to MonthlyData WHERE Month = prior month |
| MTD breakdown by account manager | `GROUP BY Manager, Region ORDER BY SUM(Commissions) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON dc.RealCID = t.RealCID | Enrich with additional customer attributes |
| BI_DB_DailyCommisionReport_MonthlyData | ON m.RealCID = t.RealCID AND m.Month = t.Month | Compare to week-level breakdown |
| BI_DB_DailyCommisionReport | ON p.DateID between month-start and latest | Back-join for daily granularity within month |

### 3.4 Gotchas

- **CommissionInRisk always NULL**: Do not use — ghost column, never populated. All 877K rows have CommissionInRisk = NULL.
- **TRUNCATE pattern**: The entire table is rebuilt daily. Never assume historical values persist — only current month MTD is present.
- **Month-start edge case**: On the 1st day of each month, the table actually contains the entire previous month's data (not the current month's day 1). Check UpdateDate to understand what date range is represented.
- **No weeknum**: Unlike MonthlyData, there is no week-level breakdown. For week analysis, use MonthlyData or the parent BI_DB_DailyCommisionReport.
- **Stocks dominance**: Stocks (42%) is the largest InstrumentType in April 2026 MTD — quite different from the Yesterday snapshot (Crypto dominant at 53%). Daily vs. monthly mix can differ significantly.
- **Backup table**: `BI_DB_DailyCommisionReport_ThisMonth_Backup_20241114` exists in SSDT repo — do not confuse with live table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from BI_DB_DailyCommisionReport (SP_DailyCommisionReport ETL logic) |
| Tier 4 | Ghost column — in DDL but never populated; confirmed from SP code and live data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID via parent BI_DB_DailyCommisionReport. CLUSTERED INDEX key. (Tier 2 — SP_DailyCommisionReport) |
| 2 | Club | varchar(100) | YES | Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, Internal) as of the reporting period. From BI_DB_Client_Balance_CID_Level_New.Club via parent. (Tier 2 — SP_DailyCommisionReport) |
| 3 | Manager | varchar(100) | YES | Account manager full name — Dim_Manager.FirstName + ' ' + LastName via Fact_SnapshotCustomer.AccountManagerID, propagated from parent. (Tier 2 — SP_DailyCommisionReport) |
| 4 | Country | varchar(100) | YES | Full country name from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name) via parent. (Tier 2 — SP_DailyCommisionReport) |
| 5 | Region | varchar(100) | YES | Marketing region label from Dim_Country.MarketingRegionManualName. NOT geographic region — eToro marketing territory classification (UK, Italian, German, Arabic, CEE, SEA, Latam, etc.). (Tier 2 — SP_DailyCommisionReport) |
| 6 | Month | int | YES | Year-month integer: MONTH(FullDate) + YEAR(FullDate)*100. E.g., April 2026 = 202604. Always a single value in the table (TRUNCATE+INSERT). GROUP BY dimension for monthly aggregation. (Tier 2 — SP_DailyCommisionReport) |
| 7 | UserName | varchar(100) | YES | Customer username from Dim_Customer.UserName as of the reporting period. (Tier 2 — SP_DailyCommisionReport) |
| 8 | Commissions | money | YES | Net commission — SUM(ISNULL(Commissions,0)) from parent BI_DB_DailyCommisionReport for month-to-date. From Function_Revenue_Commissions. Commission on opens + close adjustment. (Tier 2 — SP_DailyCommisionReport) |
| 9 | FullCommissions | money | YES | Gross full commission — SUM(ISNULL(FullCommissions,0)) from parent for month-to-date. From Function_Revenue_FullCommissions. Used for MiFID regulatory revenue reporting. (Tier 2 — SP_DailyCommisionReport) |
| 10 | CommissionInRisk | money | YES | **Ghost column — always NULL.** Present in DDL but excluded from SP INSERT list (lines 1424–1449 of SP_DailyCommisionReport.sql). Do not use. Consistent ghost column pattern across Yesterday, Last2weeks, and LastYear satellites. (Tier 4 — Legacy/Ghost) |
| 11 | UpdateDate | datetime | YES | GETDATE() at ETL execution time. Reflects timestamp of the daily SP run. (Tier 2 — SP_DailyCommisionReport) |
| 12 | Regulation | varchar(50) | YES | Regulatory jurisdiction label: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, BVI, MAS, ASIC, eToroUS, NYDFS+FINRA. From BI_DB_Client_Balance_CID_Level_New.ToRegulation. (Tier 2 — SP_DailyCommisionReport) |
| 13 | Mifid | varchar(50) | YES | MiFID categorization label: Retail, Retail Pending, Pending, Elective professional, Professional. From BI_DB_Client_Balance_CID_Level_New.MifidCategory. (Tier 2 — SP_DailyCommisionReport) |
| 14 | InstrumentType | varchar(100) | YES | Instrument type label: Stocks, Crypto Currencies, ETF, Commodities, Indices, Currencies, NA. April 2026 MTD: Stocks 42%, Crypto 22%, ETF 15%, Commodities 12%, Indices 7%, Currencies 2%. (Tier 2 — SP_DailyCommisionReport) |
| 15 | IsValidCustomer | bit | YES | 1 if customer meets eToro's valid customer criteria (non-demo, depositor, active) as of the reporting period. From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 16 | IsCreditReportValidCB | bit | YES | Credit report validity flag for US credit bureau reporting. From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 17 | IsDLTUser | int | YES | Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added to parent 2024-07-30. (Tier 2 — SP_DailyCommisionReport) |
| 18 | RollOverFee | money | YES | Daily overnight rollover/carry fee — SUM(ISNULL(RollOverFee,0)) from parent for month-to-date. From Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight. (Tier 2 — SP_DailyCommisionReport) |
| 19 | TicketFee | money | YES | Per-ticket transaction fee — SUM(ISNULL(TicketFee,0)) from parent for month-to-date. From Function_Revenue_TicketFee. Fixed fee per trade. (Tier 2 — SP_DailyCommisionReport) |
| 20 | TicketFeeByPercent | money | YES | Percentage-based ticket fee — SUM(ISNULL(TicketFeeByPercent,0)) from parent for month-to-date. From Function_Revenue_TicketFeeByPercent. (Tier 2 — SP_DailyCommisionReport) |
| 21 | AdminFee | money | YES | Islamic finance / administration fee — SUM(ISNULL(AdminFee,0)) from parent for month-to-date. From Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover. (Tier 2 — SP_DailyCommisionReport) |
| 22 | SpotAdjustFee | money | YES | Spot price adjustment fee — SUM(ISNULL(SpotAdjustFee,0)) from parent for month-to-date. From Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing. (Tier 2 — SP_DailyCommisionReport) |
| 23 | InvestedAmountOpen | money | YES | USD invested amount for positions opened month-to-date — SUM(InvestedAmountOpen) from parent. From Function_Trading_Volume. (Tier 2 — SP_DailyCommisionReport) |
| 24 | CountUU | int | YES | Sum of unique-user count from parent rows — SUM(CountUU). Represents total unique-user contribution weight for the dimension grain month-to-date. (Tier 2 — SP_DailyCommisionReport) |
| 25 | IsMarginTrade | int | YES | 1 if SettlementTypeID=5 (margin-funded position). Added to parent 2025-10-23. April 2026 MTD: IsMarginTrade=1 only for Stocks (460 rows) — <0.1% of total. (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Intermediate Source | Source Column | Transform |
|---------------|--------------------|-----------|----|
| All active columns | BI_DB_DailyCommisionReport | Various | GROUP BY aggregation (SUM for metrics, passthrough for dims; DateID >= first-of-month) |
| Month | BI_DB_DailyCommisionReport.FullDate | FullDate | MONTH(FullDate) + YEAR(FullDate)*100 |
| CommissionInRisk | — | — | Ghost — DDL only, never populated |
| UpdateDate | ETL runtime | — | GETDATE() |

### 5.2 ETL Pipeline

```
eToro production DBs (Trade, BackOffice, Billing, etc.)
  |-- Generic Pipeline (Bronze exports) --|
  v
DWH_dbo dimensions + BI_DB_dbo revenue TVFs
  |-- SP_DailyCommisionReport @Date (daily grain phase) --|
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (rolling 2B+ rows | DateID × RealCID × instrument grain | 2018–2026)
  |-- SP_DailyCommisionReport @Date (ThisMonth satellite phase) --|
  |   @DateMonth = CASE WHEN DAY(GETDATE())=1 THEN prior month start
  |                     ELSE current month start END
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_ThisMonth
  |   INSERT FROM BI_DB_DailyCommisionReport
  |   WHERE DateID >= FORMAT(@DateMonth,'yyyyMMdd')
  |   GROUP BY RealCID, Club, Manager, Country, Region,
  |            MONTH(FullDate)+YEAR(FullDate)*100, UserName,
  |            Regulation, Mifid, InstrumentType,
  |            IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth
  (~877K rows | single-month MTD | 563K CIDs | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Derived from | BI_DB_dbo.BI_DB_DailyCommisionReport | Parent daily commission fact; source of all active metrics |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified in the SSDT repo. Terminal reporting output for BI tool direct consumption.

---

## 7. Sample Queries

### Current Month Commission by Regulation
```sql
SELECT Regulation,
       SUM(Commissions)     AS MTDCommissions,
       SUM(FullCommissions) AS MTDFullCommissions,
       SUM(RollOverFee)     AS MTDRollOver,
       COUNT(DISTINCT RealCID) AS ActiveCIDs
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisMonth]
GROUP BY Regulation
ORDER BY MTDCommissions DESC
```

### MTD Revenue by Club Tier and Asset Class
```sql
SELECT Club, InstrumentType,
       SUM(Commissions)   AS Commissions,
       SUM(TicketFee)     AS TicketFees,
       SUM(AdminFee)      AS AdminFees,
       SUM(RollOverFee)   AS RollOverFees
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisMonth]
WHERE IsValidCustomer = 1
GROUP BY Club, InstrumentType
ORDER BY Commissions DESC
```

### Compare MTD vs. Previous Month (using MonthlyData)
```sql
SELECT 'ThisMonth' AS period, InstrumentType, SUM(Commissions) AS Commissions
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisMonth]
GROUP BY InstrumentType
UNION ALL
SELECT 'LastMonth', InstrumentType, SUM(Commissions)
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_MonthlyData]
WHERE Month = 202603
GROUP BY InstrumentType
ORDER BY period, Commissions DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Context derived from SP code analysis, DDL, live data sampling (April 2026 MTD), and parent table wiki (BI_DB_DailyCommisionReport, Batch 20).

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 11/14*
*Tiers: 0 T1, 24 T2, 0 T3, 1 T4, 0 T5 | Elements: 25/25 (1 ghost: CommissionInRisk)*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth | Type: Table | Production Source: BI_DB_dbo.BI_DB_DailyCommisionReport via SP_DailyCommisionReport*
