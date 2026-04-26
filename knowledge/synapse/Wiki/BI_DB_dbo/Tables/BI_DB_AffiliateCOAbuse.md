# BI_DB_dbo.BI_DB_AffiliateCOAbuse

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AffiliateCOAbuse |
| **SP Author** | Unknown (no author comment) |
| **Refresh Pattern** | DELETE WHERE FirstPosOpenDate in prior-month range + INSERT; monthly-only guard: `IF DATEPART(DAY,@FirstDayofCurrentMonth)=1` |
| **Frequency** | Monthly (1st of month only) |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (ReportDateID ASC, AffiliateID ASC, CID ASC, AffWizID ASC) |
| **Row Count** | 1,603,310 rows; Jan 2019 – Jan 2026; 9,487 distinct affiliates; 1,601,194 distinct CIDs |
| **Columns** | 23 |

---

## Summary

Monthly affiliate cash-out abuse monitoring table. Each row = one customer who opened their **first trading position in the prior calendar month** and was acquired under an affiliate. Used to assess whether affiliates earned CPA commissions for customers who subsequently exhibited low-value or suspicious behavior.

The table joins eToro customer data (Dim_Customer, BI_DB_CIDFirstDates) with AffiliateWiz (fiktivo) CPA commission records to show per-customer deposit behavior, trading activity, and realized equity — enabling comparison of what the affiliate was paid vs. the actual customer value.

Grain: one row per customer × reporting month cohort (keyed via ReportDateID = FirstPosOpenDate as YYYYMMDD). History accumulates; only the prior month's first-position cohort is replaced per run.

---

## Business Context

**CO Abuse** = affiliate partners who repeatedly refer customers that deposit minimally, claim bonuses, and cash out (cash-out abuse). The table supports the Affiliate team's monthly review of:
- Customers who triggered CPA commission payments to affiliates (`AW_CPA > 0`)
- Whether those customers actually traded (`TotalPositionCount`) and retained equity (`RealizedEquity`)
- Country discrepancies between eToro registration (DB_CountryName) and AffiliateWiz (AffWiz_CountryName) — a potential geo-misattribution fraud signal

**AffWizID namespace offset**: AffiliateWiz assigns its own CID space with a fixed +17 offset from eToro's OriginalCID. The SP hardcodes `AffWizID = OriginalCID + 17` to bridge the two systems. Verified from live data: OriginalCID 47608948 → AffWizID 47608965 (Δ=17 ✓).

**Monthly-only SP**: The SP only executes when called with the 1st day of the current month as input. If called on any other day, the `IF @run = 1` guard exits silently with no data changes.

**Channel/expense filter**: Only affiliates with `MarketingExpenseID NOT IN (3,4,5,6,9)` are included. Excluded: Direct (3), SEO (4), SEM (5), SMM (6), RAF/Friend Referral (9). Only paid external affiliate channels appear.

---

## ETL / Refresh

**Input window**: Customers with `FirstPosOpenDate >= @ReportDate AND FirstPosOpenDate <= EOMONTH(@Date)` — the entire prior calendar month. Run on April 1st processes March cohort.

**Pattern**: DELETE WHERE FirstPosOpenDate in the prior-month range + INSERT. Re-running for the same month replaces that cohort cleanly.

**RealizedEquity snapshot**: Taken at EOMONTH of the prior month (end-of-month equity from DWH_dbo.V_Liabilities). Reflects equity status at month-end, not at position-open time.

**Key join path**: The CPA match requires both the AffWizID (OriginalCID+17) and AffiliateID to match between #ThisMonthOpenPos and #AllFTDs. Customers without a CPA commission record in AffiliateWiz do not appear.

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | AffiliateID | int NULL | T1 — Customer.CustomerStatic | Affiliate ID in eToro DB — the affiliate who referred this customer. FK to Dim_Affiliate and AffiliateWiz. From Dim_Customer.AffiliateID. |
| 2 | Contact | nvarchar(500) NOT NULL | T1 — Dim_Affiliate | Affiliate's contact name or legal entity name. From DWH_dbo.Dim_Affiliate.Contact. |
| 3 | AffiliatesGroupsName | nvarchar(500) NOT NULL | T1 — Dim_Affiliate | Affiliate group/program name (e.g., 'Sam Kershner- UK'). From DWH_dbo.Dim_Affiliate.AffiliatesGroupsName. |
| 4 | AffID | int NULL | T2 — SP_AffiliateCOAbuse | AffiliateID from fiktivo CreditCommission table. Should always equal AffiliateID — both reference the same eToro affiliate via the cross-system CPA join. Stored separately for audit. |
| 5 | CID | int NOT NULL | T1 — Customer.CustomerStatic | Customer's eToro RealCID. Platform internal primary key. Part of clustered index. |
| 6 | OriginalCID | int NULL | T2 — Dim_Customer | Customer's original registration CID (pre-copy/merge). Base for computing AffWizID. From Dim_Customer.OriginalCID. |
| 7 | AffWizID | int NULL | T2 — SP_AffiliateCOAbuse | AffiliateWiz customer ID: OriginalCID + 17. Hardcoded offset bridges eToro and AffiliateWiz CID namespaces. Used as the join key to fiktivo commission tables. Part of clustered index. |
| 8 | RegisteredReal | datetime NULL | T1 — Customer.CustomerStatic | Date and time the customer's real (funded) account was registered. From Dim_Customer.RegisteredReal. |
| 9 | FirstPosOpenDate | datetime NULL | T2 — SP_CIDFirstDates | Date and time of the customer's first trading position open. The monthly filter applies to this date — only customers whose first position was in the prior month appear. |
| 10 | FirstDepositDate | datetime NULL | T2 — SP_CIDFirstDates | Date and time of the customer's first deposit in eToro. May differ from FTD_Date (AffiliateWiz tracks separately with potential tracking lag). From BI_DB_CIDFirstDates. |
| 11 | FTD_Date | date NULL | T2 — SP_AffiliateCOAbuse | First deposit date as recorded in AffiliateWiz: MIN(CAST(CreditCommission.TrackingDate AS date)) for CreditTypeID=1 per AffID+AffWizID. May differ slightly from FirstDepositDate. |
| 12 | FirstDepositAmount | money NULL | T2 — SP_CIDFirstDates | USD amount of the customer's first deposit. From BI_DB_CIDFirstDates.FirstDepositAmount. |
| 13 | TotalPositionCount | bigint NULL | T2 — External source | Lifetime total number of trading positions opened by this customer. From External_etoro_BackOffice_CustomerAllTimeAggregatedData. |
| 14 | TotalDeposit | money NULL | T2 — External source | Lifetime total deposit amount (USD) by this customer. From External_etoro_BackOffice_CustomerAllTimeAggregatedData. |
| 15 | RealizedEquity | money NULL | T2 — V_Liabilities | Customer's realized equity at end of the prior month (EOMONTH snapshot). Sourced from DWH_dbo.V_Liabilities at DateID = EOMONTH(@Date). |
| 16 | Channel | nvarchar(500) NOT NULL | T2 — SP_CIDFirstDates | Acquisition channel for this customer (e.g., 'Affiliate'). From BI_DB_CIDFirstDates.Channel. Reflects eToro attribution, not AffiliateWiz. |
| 17 | AW_CPA | float NULL | T2 — SP_AffiliateCOAbuse | Total CPA commission (USD) paid to the affiliate for this customer in AffiliateWiz. SUM(External_fiktivo_AffiliateCommission_CreditCommission.Commission WHERE CreditTypeID=1) per AffID+AffWizID pair. |
| 18 | DB_CountryID | int NULL | T1 — Customer.CustomerStatic | Customer's country ID in eToro DB. From Dim_Customer.CountryID. |
| 19 | DB_CountryName | varchar(50) NOT NULL | T2 — Dim_Country | Country name from eToro DB. DWH_dbo.Dim_Country.Name via DB_CountryID. |
| 20 | AffWiz_CountryID | int NULL | T2 — SP_AffiliateCOAbuse | Country ID from AffiliateWiz. From External_fiktivo_AffiliateCommission_Credit.CountryID. May differ from DB_CountryID — discrepancy is a potential fraud signal. |
| 21 | AffWiz_CountryName | varchar(50) NOT NULL | T2 — Dim_Country | Country name from AffiliateWiz. DWH_dbo.Dim_Country.Name via AffWiz_CountryID. |
| 22 | ReportDateID | varchar(8) NULL | T2 — SP_AffiliateCOAbuse | Partition key for monthly DELETE/INSERT: CONVERT(VARCHAR(8), CAST(FirstPosOpenDate AS date), 112) — YYYYMMDD string (e.g., '20260128'). Clustered index leading column. Note: varchar, not int. |
| 23 | UpdateDate | datetime NOT NULL | Propagation | ETL metadata: insertion timestamp (GETDATE() at INSERT time). |

---

## Data Quality / Known Issues

### AffiliateID vs AffID — Expected Identical

`AffiliateID` (from Dim_Customer) and `AffID` (from fiktivo CreditCommission) both reference the same eToro affiliate. The SP joins on both fields simultaneously (`a.AffiliateID = b.AffID` AND `a.AffWizID = b.AffWizID`), so mismatches cannot exist in the output — but they are stored as separate columns for auditability. Use `WHERE AffiliateID <> AffID` as a sanity check if needed.

### DB_CountryName vs AffWiz_CountryName May Differ

The two country name columns are resolved from independently maintained systems. Discrepancies between them (same customer, different country) are analytically significant and may indicate geo-misattribution abuse.

### BI_DB_FirstTimeRev10 Is Joined but Not Used

The SP joins `BI_DB_FirstTimeRev10` (as `Rev10`) in the `#ThisMonthOpenPos` step but no columns from it appear in the final INSERT. This is a vestigial join with no current effect on the output.

### ReportDateID Is varchar(8), Not int

Unlike most date partition columns across the schema (typically int), this column is `varchar(8)` — e.g., `'20260128'`. String comparisons and filtering must use string literals, not integer literals.

---

## Lineage

Full column-level lineage: [BI_DB_AffiliateCOAbuse.lineage.md](./BI_DB_AffiliateCOAbuse.lineage.md)

**Tier Summary**: 6 Tier 1, 16 Tier 2, 1 Propagation

**Upstream sources**:
- `DWH_dbo.Dim_Customer` → AffiliateID, CID, OriginalCID, RegisteredReal, DB_CountryID
- `DWH_dbo.Dim_Affiliate` → Contact, AffiliatesGroupsName
- `BI_DB_dbo.BI_DB_CIDFirstDates` → FirstPosOpenDate, FirstDepositDate, FirstDepositAmount, Channel
- `DWH_dbo.V_Liabilities` → RealizedEquity (end-of-month snapshot)
- `BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData` → TotalPositionCount, TotalDeposit
- `BI_DB_dbo.External_fiktivo_AffiliateCommission_CreditCommission` → AW_CPA, AffID
- `BI_DB_dbo.External_fiktivo_AffiliateCommission_Credit` → FTD_Date, AffWiz_CountryID
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_Affiliates` → channel/expense type filter
- `DWH_dbo.Dim_Country` → DB_CountryName, AffWiz_CountryName
