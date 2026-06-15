# BI_DB_dbo.BI_DB_AggMobileAcquisitionMonthly

> **DORMANT -- 0 rows, no writer SP, fully orphaned.** 28-column monthly mobile app acquisition funnel table designed to track install-to-FTD conversion by affiliate, platform (iOS/Android), country, and CPA plan at monthly granularity. Includes fraud detection (FraudFTDs), 3-level KYC verification tracking, 8-year LTV metrics (with/without outliers), and financial amounts. ROUND_ROBIN with CLUSTERED INDEX on YearMonth. No stored procedure in Synapse SSDT reads or writes this table. Monthly sibling of BI_DB_AggMobileAcquisitionDaily (also 0-row dormant). Note: column typo "Cocntact" (should be Contact).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown -- no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** -- no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (YearMonth ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AggMobileAcquisitionMonthly` was designed as a **monthly mobile app acquisition funnel** table tracking the full journey from app install through registration, verification, first deposit, first trade, and redeposit -- sliced by affiliate, platform (iOS/Android), country, CPA plan, and desk.

Key design characteristics:
- **Monthly grain**: Each row = one affiliate x platform x country x CPA plan x month (YearMonth varchar(7), e.g. "2024-03")
- **Full acquisition funnel**: Installs -> Registrations -> Verification(1/2/3) -> FTDs -> FTDEs -> FirstAction -> ReDeposit
- **Fraud detection**: FraudFTDs column to exclude fraudulent first deposits from commission calculations
- **LTV analytics**: Rev8Y_LTV and Rev8Y_LTV_NoExtreme (8-year revenue lifetime value, with and without extreme outliers)
- **Cost tracking**: CPA (per-acquisition cost), Cost (total spend), FTDAmount, RedepositsAmount

The table is currently **empty (0 rows)** and **fully orphaned** -- no stored procedure reads or writes it. This is the monthly aggregation sibling of `BI_DB_AggMobileAcquisitionDaily` (also 0-row dormant). Both were likely legacy on-prem BI_DB mobile marketing reports that either:
1. Were migrated to Databricks/BigQuery for the mobile analytics team
2. Were replaced by AppsFlyer/Adjust attribution platform exports
3. Were a custom development that was never completed in Synapse

Note the **typo "Cocntact"** (should be "Contact") -- this persisted because the table was never actively used.

---

## 2. Business Logic

### 2.1 Mobile Acquisition Funnel (Inferred)

**What**: Full install-to-trade funnel for mobile app users by affiliate at monthly granularity.
**Columns Involved**: Installs, Registrations, FTDs, FraudFTDs, FTDEs, Verification1/2/3, FirstAction, ReDeposit
**Rules**:
- Installs -> Registrations (install-to-registration conversion)
- Registrations -> Verification1 -> Verification2 -> Verification3 (KYC progression)
- Registrations -> FTDs (registration-to-FTD conversion)
- FTDs - FraudFTDs = valid FTDs for commission
- FTDEs = normalized FTD count (currency-adjusted equivalent)
- FirstAction = first trade after deposit
- ReDeposit = subsequent deposits after FTD

### 2.2 Country Tiering (Inferred)

**What**: Countries classified into revenue tiers for CPA differentiation.
**Columns Involved**: Country, TierCountry
**Rules**:
- TierCountry is an integer classification (likely 1-3 or 1-5) used to set different CPA rates per country group
- Higher-tier countries (e.g., US, UK, Australia) command higher CPA payouts

### 2.3 LTV with Outlier Handling (Inferred)

**What**: Two LTV variants to handle extreme revenue outliers.
**Columns Involved**: Rev8Y_LTV, Rev8Y_LTV_NoExtreme
**Rules**:
- Rev8Y_LTV = raw 8-year projected lifetime value (revenue over customer lifetime)
- Rev8Y_LTV_NoExtreme = same metric with statistical outlier removal (whale/test account filtering)
- Both are numeric(38,6) for high precision in financial calculations

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN -- no natural distribution key for this aggregate table
- **Index**: CLUSTERED INDEX on YearMonth -- optimized for time-range scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly install-to-FTD conversion by platform | `GROUP BY YearMonth, Platform` with `SUM(Installs), SUM(FTDs)` |
| Affiliate cost efficiency | `WHERE AffiliateID = @id` then `SUM(Cost) / NULLIF(SUM(FTDs), 0)` |
| Country tier breakdown | `GROUP BY TierCountry` with funnel aggregates |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| N/A | N/A | Table is dormant with 0 rows -- no active join patterns |

### 3.4 Gotchas

- **0 rows**: Table has never been populated in Synapse -- all queries will return empty
- **Column typo**: "Cocntact" should be "Contact" -- will cause confusion in ad-hoc queries
- **Daily sibling**: BI_DB_AggMobileAcquisitionDaily has the same columns with DateID/Date grain instead of YearMonth -- also empty
- **NOT NULL columns**: Cocntact, AffiliatesGroupsName, PaymentTrigger, CPA_Plan, Desk, Region, Country, Platform are NOT NULL despite table being empty

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki verbatim | Highest -- production-documented |
| Tier 2 | SP code analysis | High -- code is king |
| Tier 3 | Live data evidence | Medium -- empirical |
| Tier 4 | Inferred from column name/type/context | Low -- best guess |
| Tier 5 | ETL metadata (canonical) | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | YearMonth | varchar(7) | YES | Month identifier in "YYYY-MM" format. Defines the monthly grain of this acquisition funnel. (Tier 4 -inferred from name and type) |
| 2 | AffiliateID | int | NO | Affiliate partner identifier. FK to fiktivo affiliate system. Identifies the marketing affiliate driving mobile installs. (Tier 4 -inferred from name) |
| 3 | Cocntact | nvarchar(1000) | NO | Affiliate contact name or email. **Typo** -- should be "Contact". (Tier 4 -inferred from name) |
| 4 | AffiliatesGroupsName | nvarchar(50) | NO | Name of the affiliate group or network this affiliate belongs to. (Tier 4 -inferred from name) |
| 5 | PaymentTrigger | nvarchar(30) | NO | Event that triggers affiliate payment (e.g., FTD, Registration, Deposit). Determines when the CPA payout is activated. (Tier 4 -inferred from name) |
| 6 | CPA_Plan | nvarchar(11) | NO | Cost-per-acquisition plan code governing the payout structure for this affiliate. (Tier 4 -inferred from name) |
| 7 | Desk | nvarchar(50) | NO | Internal sales/support desk assignment for the affiliate's customers. (Tier 4 -inferred from name) |
| 8 | Region | nvarchar(50) | NO | Geographic marketing region grouping (e.g., Europe, APAC, LATAM). (Tier 4 -inferred from name) |
| 9 | Country | nvarchar(50) | NO | Country name or code where the mobile install originated. (Tier 4 -inferred from name) |
| 10 | TierCountry | int | YES | Country tier classification for CPA rate differentiation. Higher tiers typically command higher payouts. (Tier 4 -inferred from name) |
| 11 | Platform | nvarchar(10) | NO | Mobile platform identifier -- expected values: iOS, Android. (Tier 4 -inferred from name) |
| 12 | Installs | int | YES | Count of mobile app installs for this affiliate/platform/country/month. Top of the acquisition funnel. (Tier 4 -inferred from name) |
| 13 | Registrations | int | YES | Count of user registrations from mobile installs. Second stage of the funnel. (Tier 4 -inferred from name) |
| 14 | FTDs | int | YES | Count of first-time deposits (FTD). Key conversion event for affiliate commissions. (Tier 4 -inferred from name) |
| 15 | FraudFTDs | int | YES | Count of FTDs flagged as fraudulent. Subtracted from FTDs for valid commission calculation. (Tier 4 -inferred from name) |
| 16 | Verification1 | int | YES | Count of users passing KYC verification level 1 (identity document upload). (Tier 4 -inferred from name) |
| 17 | Verification2 | int | YES | Count of users passing KYC verification level 2 (proof of address). (Tier 4 -inferred from name) |
| 18 | Verification3 | int | YES | Count of users passing KYC verification level 3 (enhanced due diligence). (Tier 4 -inferred from name) |
| 19 | FTDEs | int | YES | First-time deposit equivalents -- normalized FTD count adjusted for currency or value thresholds. (Tier 4 -inferred from name) |
| 20 | FirstAction | int | YES | Count of users who executed their first trade after depositing. Measures activation post-FTD. (Tier 4 -inferred from name) |
| 21 | ReDeposit | int | YES | Count of subsequent deposits after the initial FTD. Measures retention and re-engagement. (Tier 4 -inferred from name) |
| 22 | UpdateDate | datetime | YES | Timestamp of last row update. (Tier 5 -ETL metadata) |
| 23 | Rev8Y_LTV | numeric(38,6) | YES | Projected 8-year revenue lifetime value for the cohort. Raw calculation including all customers. (Tier 4 -inferred from name) |
| 24 | Rev8Y_LTV_NoExtreme | numeric(38,6) | YES | Projected 8-year revenue lifetime value with statistical outlier removal (whale/test account filtering). (Tier 4 -inferred from name) |
| 25 | CPA | int | YES | Cost per acquisition -- the agreed payout amount per qualifying event for this affiliate/plan. (Tier 4 -inferred from name) |
| 26 | Cost | int | YES | Total marketing cost (spend) for this affiliate/platform/country/month. (Tier 4 -inferred from name) |
| 27 | FTDAmount | int | YES | Total monetary amount of first-time deposits for this cohort. (Tier 4 -inferred from name) |
| 28 | RedepositsAmount | int | YES | Total monetary amount of subsequent deposits for this cohort. (Tier 4 -inferred from name) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Unknown | Unknown | No writer SP found -- fully orphaned |

### 5.2 ETL Pipeline

```
(Unknown production source -- likely on-prem BI_DB)
  |-- (No Generic Pipeline mapping found)
  v
BI_DB_dbo.BI_DB_AggMobileAcquisitionMonthly (0 rows -- DORMANT)
  |-- (No UC migration -- _Not_Migrated)
  v
(not exported)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | fiktivo affiliate system | FK to affiliate partner (inferred -- no SP to confirm) |
| TierCountry | Country tier lookup | Classification tier (inferred) |

### 6.2 Referenced By (other objects point to this)

No objects in the Synapse SSDT reference this table.

---

## 7. Sample Queries

### 7.1 Check Table Status

```sql
-- Verify the table is still empty
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_AggMobileAcquisitionMonthly];
```

### 7.2 Monthly Funnel Conversion (if populated)

```sql
-- Monthly install-to-FTD conversion by platform
SELECT
    YearMonth,
    Platform,
    SUM(Installs) AS total_installs,
    SUM(FTDs) AS total_ftds,
    SUM(FraudFTDs) AS fraud_ftds,
    CAST(SUM(FTDs) AS FLOAT) / NULLIF(SUM(Installs), 0) AS ftd_rate
FROM [BI_DB_dbo].[BI_DB_AggMobileAcquisitionMonthly]
GROUP BY YearMonth, Platform
ORDER BY YearMonth DESC;
```

### 7.3 Affiliate LTV Analysis (if populated)

```sql
-- Top affiliates by LTV (excluding outliers)
SELECT
    AffiliateID,
    Cocntact AS Contact,
    SUM(FTDs) AS total_ftds,
    SUM(Rev8Y_LTV_NoExtreme) AS total_ltv,
    SUM(Cost) AS total_cost,
    SUM(Rev8Y_LTV_NoExtreme) / NULLIF(SUM(Cost), 0) AS ltv_to_cost_ratio
FROM [BI_DB_dbo].[BI_DB_AggMobileAcquisitionMonthly]
GROUP BY AffiliateID, Cocntact
ORDER BY total_ltv DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. Mobile acquisition analytics may be documented under the Marketing or Growth team spaces.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 27 T4, 1 T5 | Elements: 28/28, Logic: 6/10, Lineage: 3/10*
*Object: BI_DB_dbo.BI_DB_AggMobileAcquisitionMonthly | Type: Table | Production Source: Unknown (dormant)*
