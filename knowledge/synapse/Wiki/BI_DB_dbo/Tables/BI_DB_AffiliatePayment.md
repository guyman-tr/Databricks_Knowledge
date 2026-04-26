# BI_DB_dbo.BI_DB_AffiliatePayment

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AffiliatePaymentsReport |
| **SP Author** | Unknown (no author comment; @CalcFrom = 2013-01-01 suggests original data from 2013) |
| **Refresh Pattern** | DELETE WHERE MonthPeriod=@MonthPeriod + INSERT; monthly-only guard: `IF DATEPART(DAY,@ReportDate)=1` |
| **Frequency** | Monthly (1st of month only) |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (MonthPeriod ASC) |
| **Row Count** | 151,226 rows; Dec 2015 – Mar 2026; 8,180 distinct affiliates; 7,855 distinct trading account CIDs |
| **Columns** | 49 |

---

## Summary

Monthly affiliate payment report. Each row = one affiliate's commission payment summary for one prior calendar month. Contains all commission components (RevShare/Sales, CPA, Chargebacks, Leads, Registrations, eCost, Tier 2/3), affiliate metadata, and a deep link to the AffiliateWiz payment adjustment tool.

Only affiliates with `CurrentPayment > 0` (positive unpaid commission balance) appear. Excludes direct/SEO/SEM/SMM/RAF channels.

**16 funnel columns (Registrations through ActiveUserOutOfFTDs3M) are hardcoded NULL** for all rows since the `#InfoData` section of the SP was commented out. Live data confirms: 67.6% of rows have NULL Registrations (102,232 / 151,226). Historic rows (pre-~2021) may contain values.

---

## Business Context

Used by the Affiliate team for monthly commission payment processing and performance tracking. Key use cases:
- Review and approve affiliate commissions before payment (CurrentPayment = total outstanding unpaid amount)
- Analyze commission composition: RevShare vs. CPA vs. Chargebacks vs. CPL/CPR
- Detect self-trading affiliates (`SelfTrading=1` — affiliate referring their own eToro account)
- Multi-level affiliate structure tracking via Tier2Commition and Tier3Commition

**CurrentPayment is cumulative (all unpaid since 2013)**: The SP aggregates commissions from `@CalcFrom = 2013-01-01` forward where `Paid=0`. `CurrentPayment` is the total unpaid commission liability as of report date — not just the current month's earnings. Affiliates with old unpaid commissions carry them forward each month until paid.

**Excluded channels**: MarketingExpenseID IN (3=Direct, 4=SEO, 5=SEM, 6=SMM, 9=RAF) are excluded. Only external paid affiliates and certain non-direct channels appear.

**SelfTrading detection**: `SelfTrading=1` if the affiliate's own eToro trading account (resolved from their AffiliateWiz login name) appears in Dim_Customer with the same AffiliateID (indicating the affiliate referred themselves).

---

## ETL / Refresh

**MonthPeriod**: `YEAR(DATEADD(dd,-1,@ReportDate))*100 + MONTH(DATEADD(dd,-1,@ReportDate))`. For @ReportDate=2026-04-01, MonthPeriod=202603 (March 2026).

**Commission pipeline (all 6 types UNION ALL'd into #CommissionCurrentMonth)**:
1. **Sales** (→ RevShare_Comm): `Ext_Affiliate_Payments_Report_Closed_Position` — closed position revenue share
2. **Chargebacks**: `External_fiktivo_AffiliateCommission_CreditCommission` WHERE CreditTypeID IN (4,5)
3. **CPA** (→ CPA_Comm): Same CreditCommission table WHERE CreditTypeID=1 AND Valid!=0
4. **Leads** (→ CPL_Comm): `External_fiktivo_dbo_tblaff_Leads_Commissions` + Leads table
5. **Regs** (→ CPR_Comm): `External_fiktivo_AffiliateCommission_RegistrationCommission` + Registration table
6. **eCost**: `External_fiktivo_dbo_tblaff_eCost_Commissions` + eCost table

Only `Paid=0` and `Commission != 0.00` entries included. Aggregated per affiliate with `HAVING SUM > 0`.

**Pattern**: DELETE WHERE MonthPeriod=@MonthPeriod + INSERT. Running for the same month replaces cleanly.

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | YEAR | int NULL | T2 — SP param | Calendar year of the prior month (YEAR(DATEADD(dd,-1,@ReportDate))). |
| 2 | MONTH | int NULL | T2 — SP param | Calendar month number (1–12) of the prior month. |
| 3 | MonthPeriod | int NULL | T2 — SP param | YYYYMM integer of the prior month (e.g., 202603 = March 2026). Clustered index key. |
| 4 | AffiliateID | int NULL | T1 — fiktivo affiliate | Affiliate's primary key in AffiliateWiz and eToro systems. FK to DWH_dbo.Dim_Affiliate. |
| 5 | TradingAccount_RealCID | int NULL | T2 — SP_AffiliatePaymentsReport | eToro RealCID of the affiliate's own trading account. Resolved by matching affiliate login usernames against Dim_Customer.UserName (COALESCE across 3 payment detail usernames + LoginName). NULL if no matching account found. |
| 6 | TradingAccount_UserName | varchar(20) NULL | T2 — SP_AffiliatePaymentsReport | eToro username of the affiliate's own trading account. May be masked or hashed in display contexts. |
| 7 | SelfTrading | int NULL | T2 — SP_AffiliatePaymentsReport | Flag: 1 if the affiliate's own eToro trading account (TradingAccount_RealCID) exists in Dim_Customer with the same AffiliateID — indicates self-referral. 0 otherwise. |
| 8 | DateCreated | datetime NOT NULL | T1 — Dim_Affiliate | Date the affiliate account was created in AffiliateWiz. From DWH_dbo.Dim_Affiliate.DateCreated. |
| 9 | AW_UserName | nvarchar(150) NULL | T2 — External_fiktivo | Affiliate's login name in AffiliateWiz (= tblaff_Affiliates.LoginName). |
| 10 | CompanyName | nvarchar(255) NULL | T2 — External_fiktivo | Affiliate's company name from fiktivo tblaff_Affiliates. May be masked in some display contexts. |
| 11 | Country | varchar(50) NULL | T2 — Dim_Country | Affiliate's home country name. DWH_dbo.Dim_Country.Name via tblaff_Affiliates.CountryID. |
| 12 | AffiliatesGroupsName | nvarchar(50) NULL | T1 — Dim_Affiliate | Affiliate group/program name (e.g., 'Sam Kershner- UK'). From DWH_dbo.Dim_Affiliate.AffiliatesGroupsName. |
| 13 | Channel | nvarchar(100) NOT NULL | T1 — Dim_Channel | Marketing channel (e.g., 'Affiliate', 'Media Performance', 'Content Partnerships'). From DWH_dbo.Dim_Channel.Channel. Excludes Direct/SEO/SEM/Friend Referral. |
| 14 | SubChannel | varchar(100) NOT NULL | T1 — Dim_Channel | Sub-channel classification. From DWH_dbo.Dim_Channel.SubChannel. |
| 15 | PaymentUrl | varchar(170) NULL | T2 — SP_AffiliatePaymentsReport | Deep link to AffiliateWiz payment adjustment tool. Hardcoded template: `'http://affiliatewiz-globaltrad.msappproxy.net/Tools_Adjust.aspx?AffiliateID='` + AffiliateID + `&StartDate=2013-01-01&EndDate=` + (ReportDate - 1 day). Internal intranet URL. |
| 16 | LastPaymentProcess | datetime NULL | T2 — External_fiktivo | Most recent approved payment date for this affiliate: MAX(ApprovalDate WHERE Approved=1) from fiktivo tblaff_PaymentHistory. |
| 17 | CurrentPayment | float NOT NULL | T2 — SP_AffiliatePaymentsReport | Total unpaid commission amount (USD) for this affiliate as of report date: SUM of all commission types where Paid=0 and Commission!=0 from 2013-01-01. Cumulative unpaid balance, not just current month. |
| 18 | RevShare_Comm | float NULL | T2 — External source | Revenue share commission from closed positions (Sales type). From Ext_Affiliate_Payments_Report_Closed_Position. |
| 19 | Bonuses | float NULL | Propagation — dead column | Always 0. Bonuses commission type — the Bonuses UNION branch in the SP is commented out. Do not use. |
| 20 | Chargebacks | float NULL | T2 — External_fiktivo | Chargeback deductions: SUM of CreditTypeID IN (4,5) from External_fiktivo_AffiliateCommission_CreditCommission. Typically negative values reducing CurrentPayment. |
| 21 | CPA_Comm | float NULL | T2 — External_fiktivo | Cost Per Acquisition commission. CreditTypeID=1 entries where credit is Valid and Paid=0. |
| 22 | CPL_Comm | float NULL | T2 — External_fiktivo | Cost Per Lead commission. From fiktivo tblaff_Leads_Commissions. |
| 23 | CPR_Comm | float NULL | T2 — External_fiktivo | Cost Per Registration commission. From fiktivo AffiliateCommission_RegistrationCommission. |
| 24 | eCost | float NULL | T2 — External_fiktivo | External cost commission. From fiktivo tblaff_eCost_Commissions. |
| 25 | Tier2Commition | float NULL | T2 — SP_AffiliatePaymentsReport | Tier 2 sub-affiliate commission: SUM(Commission WHERE Tier=2) across all types. Multi-level affiliate structure. Note: column name has a typo ('Commition' not 'Commission'). |
| 26 | Tier3Commition | float NULL | T2 — SP_AffiliatePaymentsReport | Tier 3 sub-affiliate commission: SUM(Commission WHERE Tier=3). Same typo as Tier2Commition. |
| 27 | ContractType | nvarchar(100) NULL | T2 — External_fiktivo | Affiliate's contract description (e.g., 'CPA $300 (Shad FP)', 'Terminated - $0 CPA FTDE'). From fiktivo tblaff_AffiliateTypes.Description via AffiliateTypeID. |
| 28 | MinCommToCPA | float NULL | T2 — External_fiktivo | Minimum commission threshold to trigger CPA payment. From fiktivo tblaff_AffiliateTypes.MinimumCommission. |
| 29 | PaymentMethod | varchar(50) NULL | T2 — External_fiktivo | Affiliate's preferred payment method name. From fiktivo Dictionary_PaymentMethods via tblaff_PaymentDetails.PaymentMethodID. |
| 30 | Registrations | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Registrations in the current month. The #InfoData section is commented out. Historic rows (pre-~2021) may have values. |
| 31 | Registrations3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Registrations in prior 3 months. |
| 32 | FTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). First-time depositors in the current month. |
| 33 | FTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). First-time depositors in prior 3 months. |
| 34 | FTDAmount | money NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Total FTD deposit amount for the current month. |
| 35 | FTDAmount3M | money NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Total FTD deposit amount for prior 3 months. |
| 36 | Reaching10Dollars | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Customers reaching $10 revenue milestone in current month. |
| 37 | Reaching10Dollars3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same milestone, prior 3 months. |
| 38 | Reaching10DollarsOutOfFTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). FTDs who also reached $10 milestone in current month. |
| 39 | Reaching10DollarsOutOfFTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same, prior 3 months. |
| 40 | VerificationLevel2OutOfFTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). FTDs with KYC VerificationLevelID=2 in current month. |
| 41 | VerificationLevel2OutOfFTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same, prior 3 months. |
| 42 | VerificationLevel3OutOfFTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). FTDs with KYC VerificationLevelID=3 in current month. |
| 43 | VerificationLevel3OutOfFTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same, prior 3 months. |
| 44 | ActiveTradersOutOfFTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). FTDs who were active traders in current month. |
| 45 | ActiveTradersOutOfFTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same, prior 3 months. |
| 46 | ActiveUserOutOfFTDs | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). FTDs who were active users (broader than traders) in current month. |
| 47 | ActiveUserOutOfFTDs3M | int NULL | Propagation — NULL hardcoded | **Always NULL** (since ~2021). Same, prior 3 months. |
| 48 | ReportDate | datetime NULL | T2 — SP param | First day of the current month (@ReportDate = run date). Identifies the reporting period. Format: YYYY-MM-01 00:00:00. |
| 49 | UpdateDate | datetime NOT NULL | Propagation | ETL metadata: UTC timestamp of INSERT execution (`getUTCdate()`). Note: UTC, not local time — unlike most other BI_DB tables which use GETDATE(). |

---

## Data Quality / Known Issues

### 16 Funnel Columns Are Hardcoded NULL (Since ~2021)

Columns 30–47 (Registrations through ActiveUserOutOfFTDs3M) are explicitly set to `NULL` in the SP:
```sql
,NULL AS Registrations
,NULL AS Registrations3M
-- ... (16 columns total)
,NULL AS ActiveUserOutOfFTDs3M
```
The `#InfoData` temp table section (which sourced these from BI_DB_CIDFirstDates, Dim_Customer, BI_DB_FirstTimeRev10) is entirely commented out. Live data: 67.6% of rows have NULL Registrations (102,232 / 151,226); the 32.4% with values are historic. Do not use columns 30–47 for current analysis.

### Bonuses Column Always 0

The Bonuses UNION branch (`tblaff_Bonuses_Commissions`) in `#CommissionCurrentMonth` is commented out. `Bonuses` is 0 for all rows regardless of period.

### CurrentPayment Is Cumulative, Not Monthly

`CurrentPayment` aggregates ALL unpaid commissions from 2013-01-01 forward where `Paid=0`. If an affiliate's prior commissions were not marked as paid in AffiliateWiz, they carry forward into every subsequent month. `CurrentPayment` ≠ "commissions earned this month."

### UpdateDate Uses getUTCdate() (Not GETDATE())

Unlike most BI_DB tables that use `GETDATE()` (local server time), this table uses `getUTCdate()` — a UTC timestamp. This is an offset from local time.

### Tier2/Tier3 Column Name Typo

Columns 25–26 are named `Tier2Commition` and `Tier3Commition` (missing 'ss'). The typo is baked into the DDL. Downstream queries must use the misspelled names.

---

## Lineage

Full column-level lineage: [BI_DB_AffiliatePayment.lineage.md](./BI_DB_AffiliatePayment.lineage.md)

**Tier Summary**: 5 Tier 1, 25 Tier 2, 19 Propagation

**Upstream sources**:
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_Affiliates` → AW_UserName, CompanyName, AffiliateTypeID
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_PaymentDetails` → PaymentMethodID
- `BI_DB_dbo.External_fiktivo_fiktivo_Dictionary_PaymentMethods` → PaymentMethod
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_PaymentHistory` → LastPaymentProcess
- `BI_DB_dbo.Ext_Affiliate_Payments_Report_Closed_Position` → RevShare_Comm
- `BI_DB_dbo.External_fiktivo_AffiliateCommission_CreditCommission` → CPA_Comm, Chargebacks
- `BI_DB_dbo.External_fiktivo_AffiliateCommission_Credit` → CPA/chargeback date lookup
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_Leads_Commissions` + `External_fiktivo_dbo_tblaff_Leads` → CPL_Comm
- `BI_DB_dbo.External_fiktivo_AffiliateCommission_RegistrationCommission` + `External_fiktivo_AffiliateCommission_Registration` → CPR_Comm
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_eCost_Commissions` + `External_fiktivo_dbo_tblaff_eCost` → eCost
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_AffiliateTypes` → ContractType, MinCommToCPA
- `DWH_dbo.Dim_Customer` → TradingAccount_RealCID, TradingAccount_UserName, SelfTrading
- `DWH_dbo.Dim_Affiliate` → DateCreated, AffiliatesGroupsName
- `DWH_dbo.Dim_Channel` → Channel, SubChannel
- `DWH_dbo.Dim_Country` → Country (affiliate home country)
