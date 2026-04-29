# BI_DB_dbo.BI_DB_AggMobileAcquisitionDaily

> **DORMANT — 0 rows, no writer SP, fully orphaned.** 29-column daily mobile app acquisition funnel table tracking install-to-FTD conversion by affiliate, platform (iOS/Android), country, and CPA plan. Includes fraud detection (FraudFTDs), 3-level KYC verification tracking, 8-year LTV metrics (with/without outliers), and financial amounts. ROUND_ROBIN with CLUSTERED INDEX on DateID + NCI on Date. No stored procedure in Synapse SSDT reads or writes this table. Note: column typo "Cocntact" (should be Contact).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** — no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC), NCI (Date ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AggMobileAcquisitionDaily` was designed as a **daily mobile app acquisition funnel** table tracking the full journey from app install through registration, verification, first deposit, first trade, and redeposit — sliced by affiliate, platform (iOS/Android), country, CPA plan, and desk.

Key design characteristics:
- **Daily grain**: Each row = one affiliate × platform × country × CPA plan × day
- **Full acquisition funnel**: Installs → Registrations → Verification(1/2/3) → FTDs → FTDEs → FirstAction → ReDeposit
- **Fraud detection**: FraudFTDs column to exclude fraudulent first deposits from commission calculations
- **LTV analytics**: Rev8Y_LTV and Rev8Y_LTV_NoExtreme (8-year revenue lifetime value, with and without extreme outliers)
- **Cost tracking**: CPA (per-acquisition cost), Cost (total spend), FTDAmount, RedepositsAmount

The table is currently **empty (0 rows)** and **fully orphaned** — no stored procedure reads or writes it. This was likely a mobile marketing team report that either:
1. Was migrated to Databricks/BigQuery for the mobile analytics team
2. Was replaced by AppsFlyer/Adjust attribution platform exports
3. Was a custom development that was never completed in Synapse

Note the **typo "Cocntact"** (should be "Contact") — this persisted because the table was never actively used.

---

## 2. Business Logic

### 2.1 Mobile Acquisition Funnel (Inferred)

**What**: Full install-to-trade funnel for mobile app users by affiliate.
**Columns Involved**: Installs, Registrations, FTDs, FraudFTDs, FTDEs, Verification1/2/3, FirstAction, ReDeposit
**Rules**:
- Installs → Registrations (install-to-registration conversion)
- Registrations → Verification1 → Verification2 → Verification3 (KYC progression)
- Registrations → FTDs (registration-to-FTD conversion)
- FTDs - FraudFTDs = valid FTDs for commission
- FTDEs = normalized FTD count (currency-adjusted equivalent)
- FirstAction = first trade after deposit
- ReDeposit = subsequent deposits after FTD

### 2.2 Country Tiering (Inferred)

**What**: Countries classified into revenue tiers.
**Columns Involved**: Country, TierCountry
**Rules**:
- TierCountry likely 1/2/3 (Tier 1 = highest value markets like UK/Germany, Tier 3 = lower value)
- Affects CPA pricing — higher tier countries command higher CPA rates

### 2.3 LTV Metrics (Inferred)

**What**: 8-year revenue lifetime value for acquired customers.
**Columns Involved**: Rev8Y_LTV, Rev8Y_LTV_NoExtreme
**Rules**:
- Rev8Y_LTV = full 8-year projected revenue LTV including all customers
- Rev8Y_LTV_NoExtreme = same metric but excluding extreme outliers (whale traders)
- Used for ROI calculation: LTV vs CPA/Cost

### 2.4 CPA Economics (Inferred)

**What**: Cost per acquisition and total spend tracking.
**Columns Involved**: CPA, Cost, CPA_Plan, PaymentTrigger
**Rules**:
- CPA = cost per acquisition rate (what eToro pays per FTD)
- Cost = total marketing spend (CPA * valid FTDs, or actual cost)
- CPA_Plan = pricing tier/plan (varchar(11), e.g., "Standard", "Premium", "Custom")
- PaymentTrigger = event that triggers commission payment (e.g., FTD, Verification, FirstAction)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with dual indexing: CLUSTERED INDEX on DateID (efficient for date-range scans with integer comparison) + NCI on Date (for natural date filtering).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily mobile acquisition metrics | Table is empty — check if mobile analytics moved to Databricks or attribution platform |
| Affiliate mobile ROI | Table is empty — alternative source unknown |

### 3.3 Common JOINs

None active — table is fully orphaned.

### 3.4 Gotchas

- **Table is empty and fully orphaned**: 0 rows, no SP references
- **Column typo**: `Cocntact` should be `Contact` — never fixed because table was never used
- **Financial columns as int**: CPA, Cost, FTDAmount, RedepositsAmount stored as int (whole units, no decimals)
- **Platform column**: nvarchar(10) — likely iOS/Android only
- **CPA_Plan**: nvarchar(11) — very constrained width, limited to short plan codes

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from column names, types, and mobile acquisition domain knowledge | Medium |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Calendar date of the acquisition metrics. Daily grain. (Tier 4 — inferred from column name and type) |
| 2 | DateID | int | NO | Integer date key in YYYYMMDD format. CLUSTERED INDEX column for efficient range scans. (Tier 4 — inferred from naming convention) |
| 3 | AffiliateID | int | NO | Affiliate partner identifier from the fiktivo system. One of the dimension keys for this aggregate. (Tier 4 — inferred from column name) |
| 4 | Cocntact | nvarchar(1000) | NO | Affiliate manager contact name. **TYPO**: should be "Contact" — never corrected because table was never populated. (Tier 4 — inferred from column name with typo) |
| 5 | AffiliatesGroupsName | nvarchar(50) | NO | Affiliate group/tier classification (e.g., VIP, Standard, Premium). (Tier 4 — inferred from column name) |
| 6 | PaymentTrigger | nvarchar(30) | NO | Event that triggers affiliate commission payment (e.g., FTD, Verification, FirstAction, ReDeposit). (Tier 4 — inferred from column name) |
| 7 | CPA_Plan | nvarchar(11) | NO | Cost-per-acquisition pricing plan/tier code. Short codes (max 11 chars). (Tier 4 — inferred from column name and type) |
| 8 | Desk | nvarchar(50) | NO | Account management desk responsible for this affiliate (e.g., APAC Desk, EU Desk, VIP Desk). (Tier 4 — inferred from column name) |
| 9 | Region | nvarchar(50) | NO | Geographic marketing region. (Tier 4 — inferred from column name) |
| 10 | Country | nvarchar(50) | NO | Customer's country of registration. (Tier 4 — inferred from column name) |
| 11 | TierCountry | int | YES | Country revenue tier classification (1=highest value, 2=medium, 3=lowest). Affects CPA pricing. (Tier 4 — inferred from column name) |
| 12 | Platform | nvarchar(10) | NO | Mobile platform: iOS or Android. (Tier 4 — inferred from column name and type) |
| 13 | Installs | int | YES | Number of mobile app installs attributed to this affiliate for this day/country/platform. (Tier 4 — inferred from column name) |
| 14 | Registrations | int | YES | Number of account registrations following app install. (Tier 4 — inferred from column name) |
| 15 | FTDs | int | YES | Number of first-time deposits from this cohort. Primary CPA trigger metric. (Tier 4 — inferred from column name) |
| 16 | FraudFTDs | int | YES | Number of first-time deposits flagged as fraudulent. Excluded from valid FTD count for commission. (Tier 4 — inferred from column name) |
| 17 | Verification1 | int | YES | Number of customers completing KYC Level 1 verification (email/phone). (Tier 4 — inferred from column name) |
| 18 | Verification2 | int | YES | Number of customers completing KYC Level 2 verification (document upload). (Tier 4 — inferred from column name) |
| 19 | Verification3 | int | YES | Number of customers completing KYC Level 3 verification (full identity confirmation). (Tier 4 — inferred from column name) |
| 20 | FTDEs | int | YES | First-time deposit equivalents — currency-normalized FTD count for cross-country comparison. (Tier 4 — inferred from column name) |
| 21 | FirstAction | int | YES | Number of customers who performed their first trade after depositing. (Tier 4 — inferred from column name) |
| 22 | ReDeposit | int | YES | Number of customers who made a subsequent deposit after their FTD. Retention indicator. (Tier 4 — inferred from column name) |
| 23 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated. (Tier 5 — standard ETL metadata) |
| 24 | Rev8Y_LTV | numeric(38,6) | YES | 8-year projected revenue lifetime value for customers in this cohort. Includes all customers. (Tier 4 — inferred from column name) |
| 25 | Rev8Y_LTV_NoExtreme | numeric(38,6) | YES | 8-year projected revenue LTV excluding extreme outliers (whale traders) for more stable forecasting. (Tier 4 — inferred from column name) |
| 26 | CPA | int | YES | Cost per acquisition rate in whole currency units. What eToro pays per valid FTD to this affiliate. (Tier 4 — inferred from column name) |
| 27 | Cost | int | YES | Total marketing cost/spend for this affiliate/day/country/platform. Stored as whole units. (Tier 4 — inferred from column name) |
| 28 | FTDAmount | int | YES | Total monetary value of first-time deposits from this cohort. Stored as whole currency units. (Tier 4 — inferred from column name) |
| 29 | RedepositsAmount | int | YES | Total monetary value of redeposits from this cohort. Stored as whole currency units. (Tier 4 — inferred from column name) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No ETL exists — fully orphaned table |

### 5.2 ETL Pipeline

```
Unknown Production Sources (likely aggregation of:
  - Mobile attribution platform (AppsFlyer/Adjust) → Installs
  - fiktivo affiliate system → AffiliateID, Contact, Channel, Contract
  - Customer registration system → Registrations, Verification levels
  - Billing system → FTDs, FTDAmount, ReDeposit, RedepositsAmount
  - Fraud detection system → FraudFTDs
  - LTV model → Rev8Y_LTV, Rev8Y_LTV_NoExtreme
  - Finance/cost system → CPA, Cost)
  |-- [NO ETL PIPELINE EXISTS — FULLY ORPHANED] ---|
  v
BI_DB_dbo.BI_DB_AggMobileAcquisitionDaily (0 rows — DORMANT)

NOTE: Column typo "Cocntact" persists because table was never used.
      Mobile acquisition analytics likely moved to Databricks or
      attribution platform dashboards (AppsFlyer/Adjust).
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| AffiliateID | fiktivo affiliate system | Affiliate identifier (theoretical) |
| Country | DWH_dbo.Dim_Country | Country dimension (theoretical) |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_AggMobileAcquisitionDaily]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 28 T4, 1 T5 | Elements: 29/29, Logic: 5/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_AggMobileAcquisitionDaily | Type: Table | Production Source: Unknown (dormant, orphaned)*
