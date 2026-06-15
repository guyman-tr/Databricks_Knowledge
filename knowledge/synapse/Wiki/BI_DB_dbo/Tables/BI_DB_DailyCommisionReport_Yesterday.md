# BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday

> Single-day commission snapshot for the most recent reporting date (2026-04-12: 76,089 rows, 70,131 distinct CIDs) that re-aggregates yesterday's data from the parent BI_DB_DailyCommisionReport by customer × InstrumentType dimension. Fully replaced (TRUNCATE+INSERT) on each daily SP run — contains exactly one FullDate value at all times. Narrowest member of the DailyCommisionReport satellite family (25 active + 1 ghost column).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_DailyCommisionReport WHERE DateID=@DateID (via SP_DailyCommisionReport) |
| **Refresh** | TRUNCATE + INSERT (full replace daily; always contains exactly one date = yesterday) |
| **Row Count** | 76,089 rows (2026-04-12 sample; ~70–80K rows per typical trading day) |
| **Date Range** | Single date: 2026-04-12 (replaced on each run — always "yesterday") |
| **Distinct CIDs** | 70,131 (2026-04-12 sample) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Writer SP** | SP_DailyCommisionReport |

---

## 1. Business Meaning

BI_DB_DailyCommisionReport_Yesterday is the single-day snapshot satellite of the DailyCommisionReport family. It captures the previous business day's commission and fee totals re-aggregated from the parent table by customer × date × instrument type (and other customer dimension columns). Unlike the parent's daily rolling accumulation, this table always holds exactly one day's data — it is truncated and fully rebuilt on every SP run.

**Each row represents**: one customer's total commission and fees for yesterday, broken down by instrument type, regulation, club tier, account manager, and country. A customer trading in 3 asset classes on a given day produces 3 rows.

**Load pattern**: TRUNCATE TABLE then INSERT FROM BI_DB_DailyCommisionReport WHERE DateID=@DateID. Always single-date output — all rows share the same FullDate value (the @Date parameter). This is the simplest satellite in the family.

**InstrumentType distribution** (2026-04-12): Crypto Currencies (40,381 rows, 53%), Commodities (27,082, 36%), Indices (6,826, 9%), Currencies (1,430, 2%), Stocks (370, 0.5%).

**Ghost column**: CommissionInRisk is present in the DDL but the SP INSERT list (lines 1265–1289) never includes it — always NULL. This matches the ghost column pattern in Last2weeks and LastYear satellites.

---

## 2. Business Logic

### 2.1 Single-Day Snapshot Pattern

**What**: The table contains exactly one date value at all times — yesterday's date as of the SP run.
**Columns Involved**: FullDate, UpdateDate
**Rules**:
- WHERE DateID = @DateID in the SELECT from parent
- FullDate is a date column (not an integer DateID): e.g., 2026-04-12
- TRUNCATE removes all prior-day data before INSERT
- After each run, the table reflects the previous trading day only

### 2.2 CommissionInRisk Ghost Column

**What**: CommissionInRisk exists in DDL but is never populated.
**Columns Involved**: CommissionInRisk
**Rules**:
- DDL: `[CommissionInRisk] [money] NULL` (column 10 in DDL order)
- SP INSERT list (lines 1265–1289): CommissionInRisk is explicitly absent
- Result: always NULL in every row
- Consistent with DailyCommisionReport_Last2weeks and _LastYear ghost column pattern
- Do NOT use CommissionInRisk — query the parent BI_DB_DailyCommisionReport for any commission-at-risk metric

### 2.3 Instrument Type Breakdown

**What**: InstrumentType segments yesterday's revenue by asset class.
**Columns Involved**: InstrumentType, IsMarginTrade
**Rules**:
- 2026-04-12 distribution: Crypto Currencies (40K), Commodities (27K), Indices (7K), Currencies (1.4K), Stocks (370)
- Notably: Stocks are far less common in Yesterday vs. MonthlyData (0.5% vs. 46%) — Stocks volume is driven by US market hours and may be low on specific dates
- IsMarginTrade: Yesterday 2026-04-12 shows no margin trades (all IsMarginTrade=0)

### 2.4 MiFID Category Distribution

**What**: Mifid identifies customer regulatory classification for MiFID reporting.
**Columns Involved**: Mifid
**Rules**:
- Yesterday distribution: Retail (50,535 rows, 66%), Retail Pending (24,834, 33%), Pending (664, 0.9%), Elective professional (44), Professional (12)
- Retail + Retail Pending account for 99% of rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on RealCID. With ~76K rows (single-day snapshot), this is a small table — full scans are fast. No need for partition filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Yesterday's total commission by regulation | `GROUP BY Regulation ORDER BY SUM(Commissions) DESC` |
| Yesterday's active customers by club | `SELECT Club, COUNT(DISTINCT RealCID) FROM ... GROUP BY Club` |
| Revenue breakdown by asset class | `SELECT InstrumentType, SUM(Commissions), SUM(RollOverFee) GROUP BY InstrumentType` |
| Compare yesterday vs. prior day | JOIN to parent BI_DB_DailyCommisionReport on @DatePrev |
| Country-level yesterday revenue | `GROUP BY Country, InstrumentType ORDER BY SUM(FullCommissions) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON dc.RealCID = t.RealCID | Enrich with email, account type, etc. |
| BI_DB_DailyCommisionReport | ON p.DateID = @DatePrev | Compare at daily grain (more dimensions available in parent) |

### 3.4 Gotchas

- **CommissionInRisk always NULL**: Do not use this column — it is in the DDL but never populated. The SP INSERT list deliberately excludes it.
- **Single-date content**: The table always holds exactly yesterday's data. Do not attempt to query historical trends — use BI_DB_DailyCommisionReport for multi-day analysis.
- **Instrument distribution varies by day**: Crypto is dominant (53%) on 2026-04-12 but this ratio fluctuates with market activity. Do not assume a fixed ratio.
- **No VolumeOnOpen/VolumeOnClose**: These volume columns from the parent are absent in Yesterday (and all satellites except MonthlyData). Use BI_DB_DailyCommisionReport for position volume metrics.
- **No RollOverFee_SDRT/TradingFees**: Also absent (MonthlyData-only columns).
- **FullDate vs. UpdateDate**: FullDate = trading date (from parent WHERE DateID=@DateID), UpdateDate = GETDATE() at SP runtime. UpdateDate may be early morning of the next business day.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from BI_DB_DailyCommisionReport (SP_DailyCommisionReport ETL logic) |
| Tier 4 | Ghost column — in DDL but never populated; inferred from SP code absence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID via parent BI_DB_DailyCommisionReport. CLUSTERED INDEX key. (Tier 2 — SP_DailyCommisionReport) |
| 2 | Club | varchar(100) | YES | Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, Internal) as of the reporting date. From BI_DB_Client_Balance_CID_Level_New.Club via parent table. (Tier 2 — SP_DailyCommisionReport) |
| 3 | Manager | varchar(100) | YES | Account manager full name — Dim_Manager.FirstName + ' ' + LastName via Fact_SnapshotCustomer.AccountManagerID, propagated from parent. (Tier 2 — SP_DailyCommisionReport) |
| 4 | Country | varchar(100) | YES | Full country name from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name) via parent. (Tier 2 — SP_DailyCommisionReport) |
| 5 | Region | varchar(100) | YES | Marketing region label from Dim_Country.MarketingRegionManualName. NOT geographic region — eToro marketing territory classification (UK, Italian, German, Arabic, CEE, SEA, Latam, etc.). (Tier 2 — SP_DailyCommisionReport) |
| 6 | FullDate | date | YES | Reporting date — the @Date parameter value. All rows share the same FullDate (single day). This is always "yesterday" relative to the SP run. Date type (not integer DateID). (Tier 2 — SP_DailyCommisionReport) |
| 7 | UserName | varchar(100) | YES | Customer username from Dim_Customer.UserName as of the reporting date. (Tier 2 — SP_DailyCommisionReport) |
| 8 | Commissions | money | YES | Net commission — SUM(ISNULL(Commissions,0)) from parent BI_DB_DailyCommisionReport. Commission on opens (ActionTypeID IN 1,2,3,39) + close adjustment. The "net to eToro" commission figure. (Tier 2 — SP_DailyCommisionReport) |
| 9 | FullCommissions | money | YES | Gross full commission — SUM(ISNULL(FullCommissions,0)) from parent. Used for MiFID regulatory revenue reporting. Includes full spread-embedded commission without adjustments. (Tier 2 — SP_DailyCommisionReport) |
| 10 | CommissionInRisk | money | YES | **Ghost column — always NULL.** Present in DDL but excluded from SP INSERT list (lines 1265–1289 of SP_DailyCommisionReport.sql). Do not use. Consistent with ghost column pattern in Last2weeks and LastYear satellites. (Tier 4 — Legacy/Ghost) |
| 11 | UpdateDate | datetime | YES | GETDATE() at ETL execution time. Reflects timestamp of the daily SP run (typically early morning). (Tier 2 — SP_DailyCommisionReport) |
| 12 | Regulation | varchar(50) | YES | Regulatory jurisdiction label as of the reporting date: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, BVI, MAS, ASIC, eToroUS, NYDFS+FINRA. From BI_DB_Client_Balance_CID_Level_New.ToRegulation. (Tier 2 — SP_DailyCommisionReport) |
| 13 | Mifid | varchar(50) | YES | MiFID categorization label: Retail, Retail Pending, Pending, Elective professional, Professional. From BI_DB_Client_Balance_CID_Level_New.MifidCategory. (Tier 2 — SP_DailyCommisionReport) |
| 14 | InstrumentType | varchar(100) | YES | Instrument type label from Dim_Instrument.InstrumentType: Crypto Currencies, Commodities, Indices, Currencies, Stocks, ETF. Propagated from parent. Distribution varies by date — Crypto dominant on 2026-04-12 (53%). (Tier 2 — SP_DailyCommisionReport) |
| 15 | IsValidCustomer | bit | YES | 1 if customer meets eToro's valid customer criteria (non-demo, depositor, active) as of the reporting date. From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 16 | IsCreditReportValidCB | bit | YES | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). From Fact_SnapshotCustomer via parent. (Tier 2 — SP_DailyCommisionReport) |
| 17 | IsDLTUser | int | YES | Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added to parent 2024-07-30. (Tier 2 — SP_DailyCommisionReport) |
| 18 | RollOverFee | money | YES | Daily overnight rollover/carry fee — SUM(ISNULL(RollOverFee,0)) from parent. From Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight. (Tier 2 — SP_DailyCommisionReport) |
| 19 | TicketFee | money | YES | Per-ticket transaction fee — SUM(ISNULL(TicketFee,0)) from parent. From Function_Revenue_TicketFee. Fixed fee per trade. (Tier 2 — SP_DailyCommisionReport) |
| 20 | TicketFeeByPercent | money | YES | Percentage-based ticket fee — SUM(ISNULL(TicketFeeByPercent,0)) from parent. From Function_Revenue_TicketFeeByPercent. (Tier 2 — SP_DailyCommisionReport) |
| 21 | AdminFee | money | YES | Islamic finance / administration fee — SUM(ISNULL(AdminFee,0)) from parent. From Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover. (Tier 2 — SP_DailyCommisionReport) |
| 22 | SpotAdjustFee | money | YES | Spot price adjustment fee — SUM(ISNULL(SpotAdjustFee,0)) from parent. From Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing. (Tier 2 — SP_DailyCommisionReport) |
| 23 | InvestedAmountOpen | money | YES | USD invested amount for positions opened on the reporting date — SUM(InvestedAmountOpen) from parent. From Function_Trading_Volume. (Tier 2 — SP_DailyCommisionReport) |
| 24 | CountUU | int | YES | Sum of unique-user count from parent rows — SUM(CountUU). Represents total unique-user contribution weight for the dimension grain on the reporting date. (Tier 2 — SP_DailyCommisionReport) |
| 25 | IsMarginTrade | int | YES | 1 if SettlementTypeID=5 (margin-funded position) in Fact_CustomerAction. Added to parent 2025-10-23. 0 on 2026-04-12 (no margin trades that day). (Tier 2 — SP_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Intermediate Source | Source Column | Transform |
|---------------|--------------------|-----------|----|
| All active cols | BI_DB_DailyCommisionReport | Various | GROUP BY aggregation (single DateID=@DateID) |
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
  |-- SP_DailyCommisionReport @Date (Yesterday satellite phase) --|
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_Yesterday
  |   INSERT FROM BI_DB_DailyCommisionReport
  |   WHERE DateID = @DateID
  |   GROUP BY RealCID, Club, Manager, Country, Region, FullDate,
  |            UserName, Regulation, Mifid, InstrumentType,
  |            IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday
  (~76K rows | single date | 70K CIDs | ROUND_ROBIN)
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

### Yesterday's Commission by Regulation
```sql
SELECT Regulation,
       SUM(Commissions)     AS TotalCommissions,
       SUM(FullCommissions) AS TotalFullCommissions,
       SUM(RollOverFee)     AS TotalRollOver,
       COUNT(DISTINCT RealCID) AS ActiveCIDs
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Yesterday]
GROUP BY Regulation
ORDER BY TotalCommissions DESC
```

### Yesterday's Revenue by Asset Class and Club
```sql
SELECT InstrumentType, Club,
       SUM(Commissions)      AS Commissions,
       SUM(TicketFee)        AS TicketFees,
       SUM(TicketFeeByPercent) AS PercentFees,
       SUM(AdminFee)         AS AdminFees
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Yesterday]
WHERE IsValidCustomer = 1
GROUP BY InstrumentType, Club
ORDER BY Commissions DESC
```

### Yesterday's Top Countries by FullCommissions
```sql
SELECT Country, Region,
       SUM(FullCommissions) AS GrossRevenue,
       COUNT(DISTINCT RealCID) AS Customers
FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Yesterday]
GROUP BY Country, Region
ORDER BY GrossRevenue DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Context derived from SP code analysis, DDL, live data sampling (2026-04-12 snapshot), and parent table wiki (BI_DB_DailyCommisionReport, Batch 20).

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 11/14*
*Tiers: 0 T1, 24 T2, 0 T3, 1 T4, 0 T5 | Elements: 25/25 active + 1 ghost (CommissionInRisk)*
*Object: BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday | Type: Table | Production Source: BI_DB_dbo.BI_DB_DailyCommisionReport via SP_DailyCommisionReport*
