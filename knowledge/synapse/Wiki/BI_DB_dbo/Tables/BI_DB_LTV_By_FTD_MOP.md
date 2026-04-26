# BI_DB_dbo.BI_DB_LTV_By_FTD_MOP

> 41,513-row customer lifetime value (LTV) table sliced by first-time deposit (FTD) method of payment. One row per valid depositor with FTD in the last 2 years (Apr 2024 -- Apr 2026). Includes current demographics + FTD-time demographics (point-in-time snapshot), FTD payment method/provider, revenue windows (30/60/90/180/360 days), and 8-year LTV. CreditCard is the dominant FTD method (76%). Daily TRUNCATE+INSERT via SP_LTV_By_FTD_MOP.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Finance Analytics -- LTV by FTD Method of Payment) |
| **Production Source** | DWH dimensions/facts + BI_DB analytics tables by SP_LTV_By_FTD_MOP |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_LTV_By_FTD_MOP` enables **LTV analysis segmented by first-time deposit payment method**. The table answers questions like "Do customers who deposit via CreditCard have higher LTV than PayPal users?" and "How does LTV vary by regulation and FTD method?"

Each row is one customer who made their first deposit within the last 2 years. The SP builds this in 3 steps:

1. **Step 1**: Extract FTD customers from Dim_Customer (IsValidCustomer=1, IsDepositor=1, FTD within 2 years). Get current demographics (country, club, regulation, region, blocked/risk status).
2. **Step 2**: Get point-in-time demographics at FTD date from Fact_SnapshotCustomer (the customer's country, club, regulation at the time they first deposited -- which may differ from current). Get FTD method (FundingType) and provider (BillingDepot) from Fact_BillingDeposit WHERE IsFTD=1.
3. **Step 3**: LEFT JOIN BI_DB_First5Actions for early revenue windows and BI_DB_LTV_BI_Actual for 8-year LTV.

---

## 2. Business Logic

### 2.1 Current vs FTD-Time Demographics

**What**: Each customer has TWO sets of demographics -- current and at-FTD-time.
**Columns Involved**: Current_Country vs FTD_Country, Current_Club vs FTD_Club, Current_Regulation vs FTD_Regulation, Current_Region vs FTD_Region
**Rules**:
- Current_*: From Dim_Customer's current state
- FTD_*: From Fact_SnapshotCustomer at the FTD date (using Dim_Range for SCD lookup)
- A customer may have moved countries, changed regulation, or leveled up since FTD

### 2.2 Blocked and Risk Indicators

**What**: Flags whether the customer is currently blocked or high-risk.
**Columns Involved**: Is_Currently_BlockedInd, Currently_HighRiskInd
**Rules**:
- Is_Currently_BlockedInd = 1 if PlayerStatusID IN (2=Blocked, 4=Blocked, 14=Block_Deposit_Trading, 15=Block_Deposit_Trading)
- Currently_HighRiskInd = 1 if BI_DB_RiskClassification.RiskScoreName = 'High'

### 2.3 Revenue Windows

**What**: Cumulative revenue at different time horizons after FTD.
**Columns Involved**: Revenue30days, Revenue60days, Revenue90days, Revenue180days, Revenue360days
**Rules**:
- Sourced from BI_DB_First5Actions (LEFT JOIN -- NULL if not available)
- Measures revenue generated within N days of FTD
- Useful for cohort analysis and early revenue prediction

### 2.4 LTV Metrics

**What**: Long-term lifetime value calculations.
**Columns Involved**: Current_LTV, Current_LTV_NoExtreme
**Rules**:
- Current_LTV: Revenue8Y_LTV_New from BI_DB_LTV_BI_Actual -- full 8-year LTV
- Current_LTV_NoExtreme: Revenue8Y_LTV_NoExtreme_New -- LTV with extreme outliers removed
- LEFT JOIN -- NULL if LTV not yet calculated

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Small table (41K rows). Full scans are instant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average LTV by FTD method | `SELECT [FTD Method], AVG(Current_LTV) GROUP BY [FTD Method]` |
| Revenue90days by regulation | `SELECT Current_Regulation, AVG(Revenue90days) GROUP BY Current_Regulation` |
| FTD provider performance | `SELECT [FTD Provider], COUNT(*), AVG(Current_LTV) GROUP BY [FTD Provider]` |
| Blocked customer LTV | `WHERE Is_Currently_BlockedInd = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_First5Actions | CID = RealCID | Detailed first actions data |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | CID = RealCID | Detailed LTV components |

### 3.4 Gotchas

- **2-year rolling window**: Only customers with FTD in the last 2 years are included. Older depositors are excluded even if they have high LTV
- **Column names with spaces**: `[FTD Method]` and `[FTD Provider]` require square brackets
- **NULL LTV**: Current_LTV and Current_LTV_NoExtreme are NULL when BI_DB_LTV_BI_Actual has no entry for the CID
- **NULL Revenue windows**: Revenue30/60/90/180/360days are NULL when BI_DB_First5Actions has no entry
- **Current_Club = PlayerLevel**: The "Club" columns actually contain PlayerLevel names (Standard, Silver, Gold, etc.)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID. One row per customer. FK to Dim_Customer.RealCID. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 2 | FTDDate | date | YES | First-time deposit date. CAST to DATE from Dim_Customer.FirstDepositDate. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 3 | FTDDateTime | datetime | YES | First-time deposit date with time component. From Dim_Customer.FirstDepositDate. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 4 | FTDDateID | int | YES | FTD date as YYYYMMDD integer. CAST(CONVERT(VARCHAR(8), FirstDepositDate, 112) AS INT). (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 5 | Current_Country | varchar(50) | YES | Customer's current country. From Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 6 | Current_Club | varchar(20) | YES | Customer's current player level (misleadingly named "Club"). From Dim_PlayerLevel.Name. Values: Standard, Silver, Gold, Platinum, Diamond, Popular Investor. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 7 | Current_Regulation | varchar(20) | YES | Customer's current regulation. From Dim_Regulation.Name. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 8 | Current_Region | varchar(50) | YES | Customer's current marketing region. From Dim_Country.MarketingRegionManualName. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 9 | Is_Currently_BlockedInd | int | YES | Whether the customer is currently blocked. 1 if PlayerStatusID IN (2, 4, 14, 15), 0 otherwise. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 10 | Currently_HighRiskInd | int | YES | Whether the customer is currently high-risk. 1 if BI_DB_RiskClassification.RiskScoreName = 'High', 0 otherwise. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 11 | FTD_Country | varchar(50) | YES | Customer's country at the time of FTD. From Fact_SnapshotCustomer → Dim_Country at FTD date. May differ from Current_Country. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 12 | FTD_Club | varchar(20) | YES | Customer's player level at the time of FTD. From Fact_SnapshotCustomer → Dim_PlayerLevel at FTD date. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 13 | FTD_Regulation | varchar(20) | YES | Customer's regulation at the time of FTD. From Fact_SnapshotCustomer → Dim_Regulation at FTD date. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 14 | FTD_Region | varchar(50) | YES | Customer's marketing region at the time of FTD. From Fact_SnapshotCustomer → Dim_Country at FTD date. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 15 | FTD Method | varchar(50) | YES | Payment method used for the first deposit. From Dim_FundingType.Name via Fact_BillingDeposit WHERE IsFTD=1. Top: CreditCard (76%), eToroMoney, PayPal, iDEAL, WireTransfer. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 16 | FTD Provider | varchar(50) | YES | Payment provider used for the first deposit. From Dim_BillingDepot.Name via Fact_BillingDeposit WHERE IsFTD=1. (Tier 2 -- SP_LTV_By_FTD_MOP) |
| 17 | Revenue30days | money | YES | Cumulative revenue within 30 days of FTD. From BI_DB_First5Actions. In USD. NULL if not available. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_First5Actions) |
| 18 | Revenue60days | money | YES | Cumulative revenue within 60 days of FTD. From BI_DB_First5Actions. In USD. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_First5Actions) |
| 19 | Revenue90days | money | YES | Cumulative revenue within 90 days of FTD. From BI_DB_First5Actions. In USD. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_First5Actions) |
| 20 | Revenue180days | money | YES | Cumulative revenue within 180 days of FTD. From BI_DB_First5Actions. In USD. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_First5Actions) |
| 21 | Revenue360days | money | YES | Cumulative revenue within 360 days of FTD. From BI_DB_First5Actions. In USD. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_First5Actions) |
| 22 | Current_LTV | money | YES | Current 8-year lifetime value. From BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New. In USD. NULL if not yet calculated. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_LTV_BI_Actual) |
| 23 | Current_LTV_NoExtreme | money | YES | Current 8-year LTV with extreme outliers removed. From BI_DB_LTV_BI_Actual.Revenue8Y_LTV_NoExtreme_New. In USD. (Tier 2 -- SP_LTV_By_FTD_MOP via BI_DB_LTV_BI_Actual) |
| 24 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted. Set to GETDATE(). (Tier 5 -- SP_LTV_By_FTD_MOP) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| RealCID, FTDDate/DateTime/DateID | DWH_dbo.Dim_Customer | RealCID, FirstDepositDate | Passthrough / CAST |
| Current_* demographics | DWH_dbo.Dim_Customer → Dim_Country/PlayerLevel/Regulation | Name columns | Current state JOINs |
| FTD_* demographics | Fact_SnapshotCustomer → Dim_Country/PlayerLevel/Regulation | Name columns | Point-in-time at FTD |
| FTD Method, FTD Provider | Fact_BillingDeposit → Dim_FundingType/BillingDepot | Name | WHERE IsFTD=1 |
| Revenue*days | BI_DB_First5Actions | Revenue*days | LEFT JOIN |
| Current_LTV, Current_LTV_NoExtreme | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New/NoExtreme | LEFT JOIN |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1, FTD within 2 years)
  + DWH_dbo.Dim_Country, Dim_PlayerLevel, Dim_Regulation (current demographics)
  + BI_DB_dbo.BI_DB_RiskClassification (risk flag)
    |-- Step 1: #ftds_current_data ---------------------------------|
    v
DWH_dbo.Fact_SnapshotCustomer (SCD at FTD date)
  + DWH_dbo.Dim_Country, Dim_PlayerLevel, Dim_Regulation (FTD demographics)
    |-- Step 2: #ftd_all_cid_data ----------------------------------|
    v
DWH_dbo.Fact_BillingDeposit (IsFTD=1)
  + DWH_dbo.Dim_FundingType, Dim_BillingDepot
  + BI_DB_dbo.BI_DB_First5Actions (revenue windows)
    |-- Step 3: #all_data_with_ftd_method --------------------------|
    v
BI_DB_dbo.BI_DB_LTV_BI_Actual (8-year LTV)
    |-- SP_LTV_By_FTD_MOP (daily, TRUNCATE+INSERT) ----------------|
    v
BI_DB_dbo.BI_DB_LTV_By_FTD_MOP (41,513 rows)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer profile |
| Revenue*days | BI_DB_dbo.BI_DB_First5Actions | Early revenue metrics |
| Current_LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | 8-year LTV data |
| FTD Method | DWH_dbo.Dim_FundingType | Payment method details |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Average LTV by FTD Method

```sql
SELECT [FTD Method],
       COUNT(*) AS customers,
       AVG(Current_LTV) AS avg_ltv,
       AVG(Revenue90days) AS avg_rev90
FROM [BI_DB_dbo].[BI_DB_LTV_By_FTD_MOP]
WHERE Current_LTV IS NOT NULL
GROUP BY [FTD Method]
ORDER BY avg_ltv DESC
```

### 7.2 Regulation Migration Since FTD

```sql
SELECT Current_Regulation, FTD_Regulation,
       COUNT(*) AS customers
FROM [BI_DB_dbo].[BI_DB_LTV_By_FTD_MOP]
WHERE Current_Regulation != FTD_Regulation
GROUP BY Current_Regulation, FTD_Regulation
ORDER BY customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 23 T2, 0 T3, 0 T4, 1 T5 | Elements: 24/24, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_LTV_By_FTD_MOP | Type: Table | Production Source: DWH dimensions/facts + BI_DB analytics*
