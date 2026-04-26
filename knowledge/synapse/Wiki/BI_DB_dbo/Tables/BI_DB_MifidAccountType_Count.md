# BI_DB_dbo.BI_DB_MifidAccountType_Count

> 7.96M-row MiFID II compliance monitoring table. Daily snapshot of customer counts grouped by MiFID classification tier, account type, country, marketing region, desk, and regulation. One row per dimension combination per run date. Designed as a rolling 30-day window (DELETE 30-days-ago + INSERT) but in practice retains 5+ years of history (2020-09-22 to 2026-04-13, 2029 distinct run dates). Population: all IsValidCustomer=1 customers with no IsDepositor or verification-level restriction.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + DWH_dbo.Dim_MifidCategorization + DWH_dbo.Dim_AccountType + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation via SP_MifidAccountType_Count |
| **Refresh** | Daily (SB_Daily, Priority 20). DELETE WHERE Date = 30 days ago + INSERT today's snapshot. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Copy Strategy** | — |
| **Business Group** | compliance / MiFID II |

---

## 1. Business Meaning

`BI_DB_MifidAccountType_Count` provides a daily snapshot of how eToro's active customer base is distributed across MiFID II classification tiers, account types, countries, marketing regions, and regulatory frameworks. Each row represents a unique dimension combination and holds the customer count (`Count`) for that group on the run date.

The table supports MiFID II compliance monitoring: MiFID II (Markets in Financial Instruments Directive II) is the EU regulatory framework governing retail and professional financial clients. A customer's `MifidCategorization` determines their leverage limits, margin requirements, negative balance protection eligibility, and disclosure obligations. This table provides a historical record of how classification counts have evolved over time — useful for detecting changes in the retail/professional mix and for regulatory reporting.

Unlike the AML report tables (`BI_DB_M_AML_Report`), the population here includes ALL valid customers (`IsValidCustomer=1`) with no depositor or KYC verification level filter. This means BVI-regulated and eToroUS customers are included, and the total customer count reflects the full platform, not just the AML-reportable scope.

As of 2026-04-13 (latest run): 3,836 dimension groups. Private account type dominates (>99% of customers). BVI is the largest regulation by raw customer count (due to broad IsValidCustomer=1 scope). MifidCategorization split: Retail (1,856 groups), Retail Pending (1,453), Pending (448), Elective Professional (67), Professional (10), None (2).

---

## 2. Business Logic

### 2.1 Source and Grouping

The SP reads `DWH_dbo.Dim_Customer` (filter: `IsValidCustomer=1`) and JOINs to four dimension tables to resolve text labels. Then groups by all six dimension columns and counts `RealCID` per group. No date parameter is accepted — `GETDATE()` is used as the snapshot date.

**GROUP BY key**: MifidCategorization, AccountType, Country, Region, Desk, Regulation  
**Measure**: `COUNT(RealCID)` stored as `Count`  
**Run date**: `GETDATE()` at execution time, stored as `Date` (cast to date type)

### 2.2 Load Pattern: Rolling 30-Day Window Design

The SP executes:
1. `DELETE FROM BI_DB_MifidAccountType_Count WHERE [Date] = DATEADD(DAY, -30, GETDATE())` — removes the snapshot from exactly 30 days ago
2. `INSERT` today's ~3,800 rows

**Design intent**: maintain a rolling 30-day history (yesterday + 29 prior days). **Actual behavior**: as of 2026-04-13, the table retains 2029 distinct dates going back to 2020-09-22. The rolling window design has not been effective — likely because the SP has not run continuously every day since 2020, leaving older dates undeleted. See Section 8 for details.

### 2.3 Population Scope (Broader Than AML Tables)

Unlike `BI_DB_M_AML_Report` and `BI_DB_LimitedAccountsWithReasons`, this table does NOT filter on:
- `IsDepositor` (includes non-depositors)
- `VerificationLevelID` (includes all KYC levels 0–3)
- Regulation exclusions (BVI, NFA, eToroUS are included)

This makes the customer counts in this table higher than those in AML-scoped tables and not directly comparable.

### 2.4 MiFID II Classification Tiers

MifidCategorization values (from Dim_MifidCategorization, 6 rows):
- **Retail** (default): full investor protection, default for most customers
- **Elective Professional**: customer-requested reclassification (reduced protection)
- **Professional**: institutional/professional investor (reduced protection)
- **Retail Pending**: retail classification in progress
- **Pending**: categorization assessment incomplete
- **None**: typically non-EU customers under non-MiFID jurisdictions

### 2.5 Desk vs. Region

Both come from `Dim_Country`:
- `Region`: marketing region label (from Dictionary.MarketingRegion, 22 values)
- `Desk`: sales/support desk assignment (from Ext_Dim_Country_Region_Desk via MarketingRegionID; can be NULL for unmapped regions)

In the sample data, Region and Desk often match (both "German", "South & Central America") but can differ (Desk="ROW" while Region="Russian").

---

## 3. Data Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | AccountType | varchar(50) | YES | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Dominant: Private (>99% of customers). (Tier 1 — Dictionary.AccountType) |
| 2 | Country | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name. (Tier 1 — Dictionary.Country) |
| 3 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., ROW, Africa, French, Arabic Other). Used for marketing campaign grouping. Passthrough from Dim_Country.Region. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 4 | Desk | varchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: ROW, Other EU, Arabic, USA. NULL if no desk mapping for this marketing region. Passthrough from Dim_Country.Desk. (Tier 3 — Ext_Dim_Country_Region_Desk via SP) |
| 5 | Regulation | varchar(50) | YES | Regulatory framework name text. Sourced from Dim_Regulation via Dim_Customer.RegulationID. All regulations included (BVI, eToroUS, NFA not excluded). (Tier 2 — SP_MifidAccountType_Count) |
| 6 | Count | int | YES | Number of IsValidCustomer=1 customers in this dimension group on the run date. This is a customer COUNT, not a customer ID. Use SUM(Count) for totals across groups. (Tier 2 — SP_MifidAccountType_Count) |
| 7 | Date | date | YES | Run date: GETDATE() cast to date at SP execution time. Serves as the time dimension key. CLUSTERED INDEX on this column enables efficient date-range queries. Range: 2020-09-22 to 2026-04-13 (2029 distinct dates). (Tier 5 — ETL metadata) |
| 8 | UpdateDate | datetime | YES | ETL insert timestamp (GETDATE() at run time). All rows in a given day's run share the same UpdateDate value. (Tier 5 — ETL metadata) |
| 9 | MifidCategorization | varchar(50) | YES | Human-readable classification label. Used in compliance dashboards and regulatory reports. Values: Retail, Professional, Elective professional, Retail Pending, Pending, None. Sourced from Dim_MifidCategorization.Name via Dim_Customer.MifidCategorizationID. (Tier 1 — Dictionary.MifidCategorization) |

---

## 4. Sample Rows

Sample from live data (mixed run dates):

| AccountType | Country | Region | Desk | Regulation | Count | Date | MifidCategorization |
|-------------|---------|--------|------|-----------|-------|------|---------------------|
| Affiliate Corporate Account | Honduras | South & Central America | South & Central America | BVI | 1 | 2023-05-20 | Retail |
| Private | Switzerland | German | German | FCA | 65 | 2022-01-07 | Retail |
| Private | Norway | North Europe | Other EU | CySEC | 406 | 2023-06-01 | Pending |
| Joint Account | Denmark | North Europe | Other EU | CySEC | 3 | 2020-09-28 | Retail |

_Count = number of customers per group. 2026-04-13 (latest date): 3,836 groups. AccountType distribution: Private dominates (~46M customers in BVI alone on latest run date)._

---

## 5. Lineage at a Glance

See `BI_DB_MifidAccountType_Count.lineage.md` for full column-level lineage.

**ETL Summary:**
- Writer SP: `BI_DB_dbo.SP_MifidAccountType_Count`
- Pattern: DELETE WHERE Date = 30 days ago + INSERT (rolling window design)
- No date parameter — runs on GETDATE()
- 5 source dimension tables from DWH_dbo

---

## 6. Related Objects

| Object | Schema | Relationship |
|--------|--------|-------------|
| SP_MifidAccountType_Count | BI_DB_dbo | Writer SP. No input parameters. |
| Dim_MifidCategorization | DWH_dbo | Source for MifidCategorization text (6 rows). |
| Dim_AccountType | DWH_dbo | Source for AccountType text. |
| Dim_Country | DWH_dbo | Source for Country, Region, Desk. |
| Dim_Regulation | DWH_dbo | Source for Regulation text. |
| Dim_Customer | DWH_dbo | Base: IsValidCustomer=1 population with MifidCategorizationID, AccountTypeID, CountryID, RegulationID. |

---

## 7. Change History

| Date | Author | Change |
|------|--------|--------|
| 2020-09-22 | ETL | Earliest data: first recorded run date. |
| — | — | SP creation date unknown (no DDL comment or author). |
| 2026-04-13 | ETL | Latest run date in current dataset. |

---

## 8. Open Questions / Caveats

1. **Rolling Window Design Not Effective**: The SP deletes Date = DATEADD(DAY, -30, GETDATE()) on each run. Despite this, the table has 2029 distinct dates back to 2020. This suggests the SP has not run daily continuously since 2020, resulting in un-deleted historical rows. The effective history is 5+ years, not 30 days.

2. **Count ≠ Customer ID**: The `Count` column holds `COUNT(RealCID)` per group. It is not a customer identifier. All analysis should aggregate using `SUM(Count)`.

3. **Broader Scope Than AML Tables**: IsValidCustomer=1 with NO IsDepositor/VerificationLevel filter. BVI, eToroUS, and NFA customers are included. Do not compare Count totals directly with BI_DB_M_AML_Report totals.

4. **Date = Run Date, Not Business Date**: `Date` is `GETDATE()` at SP execution time, not a configured business date or end-of-period date. If the SP runs at different times of day, the time component (truncated to date) should be consistent, but the date reflects when the SP ran, not when a business period closed.

5. **Desk Can Be NULL**: Countries without a mapping in Ext_Dim_Country_Region_Desk will have NULL Desk. These are not the same as countries mapped to "ROW" desk — NULL means no mapping exists.
