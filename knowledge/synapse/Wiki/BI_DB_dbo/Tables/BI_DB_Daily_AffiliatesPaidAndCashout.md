# BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout

> 831K-row affiliate cashout tracking table matching approved withdrawal transactions (CashoutStatusID=3) to paid affiliates for 2,475 distinct CIDs across March 2021 to March 2026. Refreshed daily by SP_AffiliatesPaidAndCashout via DELETE+INSERT for the previous month.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_MarketingMonthlyRawData (affiliate costs) + DWH_dbo.Fact_BillingWithdraw (cashouts) + DWH_dbo.Dim_Affiliate (affiliate details) via SP_AffiliatesPaidAndCashout |
| **Refresh** | Daily (SB_Daily, Priority 0). DELETE previous month's YearMonth → INSERT matched cashouts |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_Daily_AffiliatesPaidAndCashout` tracks cashout (withdrawal) transactions by customers who were acquired through paid affiliate channels. The table joins approved withdrawals from `Fact_BillingWithdraw` (CashoutStatusID=3 on both funding and withdraw sides) with affiliate cost data from `BI_DB_MarketingMonthlyRawData` (Channel='Affiliate', TotalCost<>0), matching on the affiliate's TradingAccount_RealCID.

The grain is per withdrawal transaction (WithdrawID). Each row represents one approved cashout by an affiliate-acquired customer in a given month. Affiliate metadata (group name, contact, website, email) is enriched from `Dim_Affiliate`.

This table supports affiliate fraud detection, cost-of-acquisition analysis, and cashout-to-cost ratio monitoring for the affiliate marketing program.

---

## 2. Business Logic

### 2.1 Affiliate-Customer Matching

**What**: Cashouts are matched to affiliates based on the affiliate's trading account CID.
**Columns Involved**: `CID`, `AffiliateID`
**Rules**:
- BI_DB_MarketingMonthlyRawData.AffiliateID → Dim_Affiliate.TradingAccount_RealCID = Fact_BillingWithdraw.CID
- AND same YearMonthID (YYYYMM) for the cashout and the affiliate cost record
- Only Channel='Affiliate' records are considered
- Only affiliates with TotalCost<>0 (i.e., actually paid) are included

### 2.2 Cashout Approval Filter

**What**: Only fully approved cashouts are included.
**Rules**:
- CashoutStatusID_Funding=3 (approved on funding side)
- CashoutStatusID_Withdraw=3 (approved on withdraw side)
- IsValidCustomer=1 (valid customer)

### 2.3 Monthly Partitioning

**What**: The SP processes the previous month's data.
**Columns Involved**: `YearMonth`
**Rules**:
- @SDate = first day of previous month
- DELETE WHERE YearMonth=@SDateID (YYYYMM format)
- INSERT cashouts from @SDate to @EDate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no index optimization. For large aggregate queries, filter by YearMonth.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total cashout by affiliate group | `SELECT AffiliatesGroupsName, SUM(Amount_WithdrawToFunding) GROUP BY AffiliatesGroupsName` |
| Monthly cashout trend | `SELECT YearMonth, SUM(Amount_WithdrawToFunding) GROUP BY YearMonth ORDER BY YearMonth` |
| Top cashout affiliates | `SELECT AffiliateID, Contact, SUM(Amount_WithdrawToFunding) GROUP BY AffiliateID, Contact ORDER BY 3 DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| DWH_dbo.Dim_Affiliate | AffiliateID = AffiliateID | Extended affiliate details |

### 3.4 Gotchas

- **PII data**: Contact, WebSiteURL, Email contain real affiliate partner contact information.
- **nvarchar(max) columns**: AffiliatesGroupsName, Contact, WebSiteURL, Email are unbounded — watch for query performance on aggregations.
- **CID not RealCID**: Uses CID column name (not RealCID) consistent with Fact_BillingWithdraw source.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | bigint | YES | Unique identifier for the withdrawal transaction. Passthrough from Fact_BillingWithdraw. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 2 | CID | int | YES | Customer ID who made the cashout. Matched to the affiliate's TradingAccount_RealCID. FK to Dim_Customer.RealCID. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 3 | WithdrawPaymentID | bigint | YES | Payment ID for the withdrawal funding transaction. Passthrough from Fact_BillingWithdraw. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 4 | Amount_WithdrawToFunding | money | YES | Withdrawal amount funded to the customer. Passthrough from Fact_BillingWithdraw.Amount_WithdrawToFunding. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 5 | FTFundingType | varchar(1000) | YES | Funding type name for the withdrawal method (e.g., WireTransfer). From Dim_FundingType.Name via FundingTypeID_Funding JOIN. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 6 | AccountType | varchar(1000) | YES | Account type name (e.g., Affiliate Corporate Account, Affiliate Private Account). From Dim_AccountType.Name via Dim_Customer.AccountTypeID. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 7 | YearMonth | int | YES | Year-month of the cashout in YYYYMM integer format (e.g., 202109). Derived from CONVERT(VARCHAR(6), ModificationDate, 112). Used for DELETE+INSERT partitioning. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 8 | AffiliateID | bigint | YES | Unique identifier of the affiliate partner. Passthrough from BI_DB_MarketingMonthlyRawData via the affiliate match. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 9 | AffiliatesGroupsName | nvarchar(max) | YES | Name of the affiliate group (e.g., UK Affiliates, Nimrod Burla Global). Passthrough from Dim_Affiliate.AffiliatesGroupsName. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 10 | Contact | nvarchar(max) | YES | Contact name or company for the affiliate partner. Passthrough from Dim_Affiliate.Contact. PII data. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 11 | WebSiteURL | nvarchar(max) | YES | Affiliate partner website URL(s). May contain multiple comma-separated URLs. Passthrough from Dim_Affiliate.WebSiteURL. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 12 | Email | varchar(max) | YES | Affiliate partner email address. PII data. Passthrough from Dim_Affiliate.Email. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 13 | Country | varchar(50) | YES | Country name associated with the affiliate marketing cost record. From Dim_Country.Name via MarketingMonthlyRawData.CountryID. (Tier 2 — SP_AffiliatesPaidAndCashout) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Passthrough |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Passthrough |
| Amount_WithdrawToFunding | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding | Passthrough |
| AffiliateID | BI_DB_MarketingMonthlyRawData | AffiliateID | Passthrough |
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (Channel='Affiliate', TotalCost<>0)
  + DWH_dbo.Dim_Affiliate (affiliate details)
  + DWH_dbo.Dim_Country (country name)
  |-- #affiliatesPaid (paid affiliates with TradingAccount_RealCID) ---|
  v
DWH_dbo.Fact_BillingWithdraw (CashoutStatusID=3, IsValidCustomer=1)
  + DWH_dbo.Dim_FundingType (funding type name)
  + DWH_dbo.Dim_AccountType (account type name)
  |-- #allcashouts (matched to affiliate period) ---|
  v
  + #affiliatesPaid (enrich with affiliate metadata)
  |-- #client ---|
  v
BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout (DELETE+INSERT by YearMonth)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate dimension |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Withdrawal fact |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Monthly Affiliate Cashout Volume

```sql
SELECT YearMonth,
       COUNT(DISTINCT CID) AS clients,
       COUNT(*) AS withdrawals,
       SUM(Amount_WithdrawToFunding) AS total_amount
FROM BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout
GROUP BY YearMonth
ORDER BY YearMonth DESC
```

### 7.2 Top Affiliate Groups by Cashout Amount

```sql
SELECT AffiliatesGroupsName,
       COUNT(DISTINCT CID) AS clients,
       SUM(Amount_WithdrawToFunding) AS total_cashout
FROM BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout
WHERE YearMonth >= 202601
GROUP BY AffiliatesGroupsName
ORDER BY total_cashout DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout | Type: Table | Production Source: MarketingMonthlyRawData + Fact_BillingWithdraw via SP_AffiliatesPaidAndCashout*
