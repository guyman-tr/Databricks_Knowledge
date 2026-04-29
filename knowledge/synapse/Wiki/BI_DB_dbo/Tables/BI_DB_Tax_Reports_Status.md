# BI_DB_dbo.BI_DB_Tax_Reports_Status

> 121K-row tax report status monitoring table aggregating daily report generation counts by country, status (Completed/Failed/Pending), and tax year from FinanceReports.Reports.Report via SP_TaxReports. Covers 26 countries from 2024-02-20 to present with country-specific fiscal year validation. Daily DELETE+INSERT refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | FinanceReports.Reports.Report via SP_TaxReports (author: Adi Meidan, maintained by Lior Ben Dor) |
| **Refresh** | Daily (DELETE+INSERT by @Date via OpsDB Service Broker, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not in Generic Pipeline mapping — may not be exported to UC_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Tax_Reports_Status` is a daily monitoring table that tracks the generation status of tax reports across 26 countries. Each row represents a daily snapshot of how many tax report requests exist per country, per report status (Completed, Failed, Pending), per tax year, and per date range. The data is used to monitor the tax reporting pipeline and identify countries where report generation has failed or is stuck in pending state.

The table contains 121K rows spanning from February 2024 to April 2026. Top countries by row volume: United Kingdom (26K), Australia (8.6K), France (6.0K), Italy (6.0K), United States (5.9K). Report status distribution: Completed (59K), Failed (38K), Pending (24K).

The ETL logic in `SP_TaxReports`:
1. Reads from `External_FinanceReports_Reports_Report` (the FinanceReports service's report request table)
2. Validates tax year date ranges per country — different countries have different fiscal years (UK: Apr 6 - Apr 5, Australia: Jul 1 - Jun 30, New Zealand: Apr 1 - Mar 31, all others: Jan 1 - Dec 31)
3. Filters to only valid full-year tax reports (Ind_Correct=1)
4. Computes TaxYear label ('2023' for calendar year, '2022/2023' for cross-year fiscal years)
5. Maps ReportStatusID to human-readable status: 5 or 6 → 'Completed', 7 → 'Failed', else → 'Pending'
6. Aggregates COUNT(RequestID) by Country, ReportStatus, TaxYear, FromUtc, TillUtc
7. DELETE+INSERT by @Date for daily partition management

---

## 2. Business Logic

### 2.1 Country-Specific Fiscal Year Validation

**What**: Different countries have different tax year boundaries. Only full tax year reports are included.
**Columns Involved**: `FromUtc`, `TillUtc`, `TaxYear`, `Country`
**Rules**:
- **United Kingdom** (CountryID 218): Apr 6 to Apr 5 next year
- **Australia** (CountryID 12): Jul 1 to Jun 30 next year
- **New Zealand** (CountryID 146): Apr 1 to Mar 31 next year
- **All other countries**: Standard calendar year (Jan 1 to Dec 31)
- Reports not matching these patterns are excluded (Ind_Correct=0)

### 2.2 Report Status Classification

**What**: Numeric ReportStatusID mapped to three human-readable categories.
**Columns Involved**: `ReportStatus`
**Rules**:
- ReportStatusID 5 or 6 → 'Completed'
- ReportStatusID 7 → 'Failed'
- All other ReportStatusID values → 'Pending'

### 2.3 Tax Year Label Format

**What**: Computed label showing the tax year or fiscal year range.
**Columns Involved**: `TaxYear`
**Rules**:
- If FromUtc year = TillUtc year → 'YYYY' (e.g., '2023')
- If FromUtc year ≠ TillUtc year → 'YYYY/YYYY' (e.g., '2022/2023')

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP (no clustered index). Small table — full scans are acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Latest report status by country | `WHERE Date = (SELECT MAX(Date) FROM BI_DB_Tax_Reports_Status)` |
| Failed reports trend | `WHERE ReportStatus = 'Failed' ORDER BY Date` |
| Report count by tax year | `GROUP BY TaxYear, ReportStatus` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | Country = Name | Additional country attributes (region, regulation) |

### 3.4 Gotchas

- **Date is the SP execution date**, not the report creation date — it represents "as of this date, here are the counts"
- **TillUtc exclusive boundary**: For calendar year reports, TillUtc is Jan 1 of the NEXT year (not Dec 31)
- **No CID/GCID granularity**: This table is aggregated — individual report requests are not stored
- **Country filter changes over time**: SP has been updated multiple times to add countries (Poland, Philippines in 2024; Slovenia, Czech Republic in 2025; all countries in 2026)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | SP execution date — the daily snapshot date. Set to @Date parameter from OpsDB scheduler. Used as partition key for DELETE+INSERT. (Tier 2 — SP_TaxReports) |
| 2 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 3 | ReportStatus | varchar(10) | YES | Report generation status. ETL-computed from ReportStatusID: 5 or 6='Completed', 7='Failed', else='Pending'. 3 distinct values. (Tier 2 — SP_TaxReports) |
| 4 | TaxYear | varchar(20) | YES | Tax year label. Same-year='YYYY' (e.g., '2023'), cross-year='YYYY/YYYY' (e.g., '2022/2023' for UK/AU/NZ fiscal years). ETL-computed from FromUtc/TillUtc year components. (Tier 2 — SP_TaxReports) |
| 5 | FromUtc | datetime | YES | Tax year start date (UTC). Country-specific: Jan 1 for calendar year, Apr 6 for UK, Jul 1 for Australia, Apr 1 for NZ. Passthrough from FinanceReports.Reports.Report (filtered to valid full-year ranges only). (Tier 2 — SP_TaxReports) |
| 6 | TillUtc | datetime | YES | Tax year end date (UTC, exclusive). Country-specific: Jan 1 next year for calendar year, Apr 5 for UK, Jun 30 for Australia, Mar 31 for NZ. Passthrough from FinanceReports.Reports.Report (filtered to valid full-year ranges only). (Tier 2 — SP_TaxReports) |
| 7 | Report_Count | int | YES | Number of tax report requests matching this Country + ReportStatus + TaxYear + date range combination. ETL-computed as COUNT(RequestID) from FinanceReports.Reports.Report. (Tier 2 — SP_TaxReports) |
| 8 | UpdateDate | date | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | (SP parameter) | @Date | SP input parameter |
| Country | DWH_dbo.Dim_Country (← Dictionary.Country) | Name | Dim-lookup passthrough |
| ReportStatus | FinanceReports.Reports.Report | ReportStatusID | CASE mapping to 3 categories |
| TaxYear | FinanceReports.Reports.Report | FromUtc, TillUtc | CASE: same-year vs cross-year label |
| FromUtc | FinanceReports.Reports.Report | FromUtc | Passthrough (filtered) |
| TillUtc | FinanceReports.Reports.Report | TillUtc | Passthrough (filtered) |
| Report_Count | FinanceReports.Reports.Report | RequestID | COUNT() aggregation |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
FinanceReports.Reports.Report (production OLTP, tax report requests)
  |-- Generic Pipeline (Bronze export) --|
  v
BI_DB_dbo.External_FinanceReports_Reports_Report (External table)
  + DWH_dbo.Dim_Country (CountryID→Name)
  |-- SP_TaxReports @Date --|
  |-- Step 1: Filter valid full-year tax reports (country-specific fiscal years) --|
  |-- Step 2: Compute TaxYear label --|
  |-- Step 3: Map ReportStatusID → 'Completed'/'Failed'/'Pending' --|
  |-- Step 4: Aggregate COUNT(RequestID) by Country+Status+TaxYear+dates --|
  |-- Step 5: DELETE+INSERT by @Date --|
  v
BI_DB_dbo.BI_DB_Tax_Reports_Status (121K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country (Name) | Country dimension for additional attributes |

### 6.2 Referenced By (other objects point to this)

No consumer SPs found referencing this table.

---

## 7. Sample Queries

### 7.1 Latest report status by country

```sql
SELECT Country, ReportStatus, TaxYear, Report_Count
FROM BI_DB_dbo.BI_DB_Tax_Reports_Status
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_Tax_Reports_Status)
ORDER BY Country, TaxYear
```

### 7.2 Failed report trend over time

```sql
SELECT Date, Country, TaxYear, Report_Count
FROM BI_DB_dbo.BI_DB_Tax_Reports_Status
WHERE ReportStatus = 'Failed'
ORDER BY Date DESC, Report_Count DESC
```

### 7.3 Total reports by tax year and status

```sql
SELECT TaxYear, ReportStatus, SUM(Report_Count) AS total_reports
FROM BI_DB_dbo.BI_DB_Tax_Reports_Status
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_Tax_Reports_Status)
GROUP BY TaxYear, ReportStatus
ORDER BY TaxYear, ReportStatus
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 6 T2, 0 T3, 0 T4, 1 T5 | Elements: 8/8, Logic: 8/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_Tax_Reports_Status | Type: Table | Production Source: FinanceReports.Reports.Report via SP_TaxReports*
