# BI_DB_dbo.BI_DB_HighCOsAndRedeemsWithSF

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Writer SP** | BI_DB_dbo.SP_HighCOsAndRedeemsWithSF |
| **ETL Pattern** | TRUNCATE + INSERT (full reload, @day = GETDATE()-1) |
| **OpsDB Priority** | 20 |
| **Frequency** | Daily |
| **Row Estimate** | Low (only customers exceeding large-transaction thresholds) |
| **UC Target** | Not Migrated |

## Overview

AML/compliance monitoring table identifying customers with unusually large cashout or crypto redeem requests, enriched with Salesforce account manager contact history. Used by Account Managers and Compliance teams to identify high-value transactions requiring customer outreach or regulatory review.

**"HighCOs"** = High Cash Outs (large withdrawal requests). **"Redeems"** = large crypto position redemptions. **"WithSF"** = enriched with Salesforce CRM data showing whether the customer has been contacted by phone in the past 12 months.

Each row represents one customer × one request date × one transaction type. The table is refreshed daily as a full snapshot (TRUNCATE + INSERT); no historical rows are retained beyond the current snapshot of pending high-value transactions.

## ETL Summary

```
Fact_BillingWithdraw (pending cashouts, status=1, daily SUM ≥ $200K)
  ↓
#CASHOUTS → Type='Cashout', Amount = SUM(Amount_Withdraw)

External_etoro_Billing_Redeem (pending redeems, status=1)
  JOIN Dim_GetSpreadedPriceCandle60MinSplitted (yesterday's BidLast price)
  → ValueEOD = Units × BidLast
  ↓
#redeems → Type='Redeem', Amount = SUM(ValueEOD) where SUM > $50K

UNION → #all (all high-value cashout + redeem rows)

JOIN BI_DB_UsageTracking_SF → #SF (most recent phone call per CID, last 12 months)
JOIN Dim_Customer + Dim_Manager (age check, account manager name)

Final filter: (age > 70 AND Amount > 50,000) OR Amount > 100,000
→ TRUNCATE BI_DB_HighCOsAndRedeemsWithSF → INSERT
```

**Age-adjusted threshold**: Customers older than 70 are subject to a lower reporting threshold ($50K vs $100K). This reflects increased regulatory scrutiny for elderly account holders under AML frameworks.

## Column Reference

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within eToro DB. Used as the universal customer identifier across all tables. | Tier 1 — Dim_Customer.RealCID |
| 2 | RequestDate | date | YES | Date the cashout or redeem was requested. CAST from RequestDate datetime to DATE. Used as the grouping key for daily aggregation. | Tier 2 |
| 3 | Amount | money | YES | Daily aggregated transaction amount. For cashouts: SUM(Amount_Withdraw) in the cashout currency. For redeems: SUM(Units × BidLast) — end-of-day marked value of redeemed positions (priced at yesterday's close). | Tier 2 |
| 4 | Type | nvarchar(1000) | YES | Transaction type. Values: 'Cashout' (from Fact_BillingWithdraw, large pending withdrawals) or 'Redeem' (from External_etoro_Billing_Redeem, crypto position redemptions). | Tier 2 |
| 5 | WasContactedLast12Months | nvarchar(1000) | YES | Salesforce contact indicator. 'yes' if the customer received a successful phone call (ActionName='Phone_Call_Succeed__c') from an Account Manager in the 12 months preceding the ETL run; 'no' otherwise. Based on the single most recent qualifying phone contact. | Tier 2 |
| 6 | Account Manager | nvarchar(1000) | YES | Full name (FirstName + LastName) of the Account Manager assigned to this customer. Resolved in priority order: (1) manager who made the most recent SF phone contact; (2) fallback to Dim_Customer.AccountManagerID → Dim_Manager. Column name contains a space — requires bracket-quoting in SQL: `[Account Manager]`. | Tier 2 |
| 7 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last refreshed by the ETL pipeline (GETDATE() at INSERT time). | ETL_METADATA |

## Business Logic: Threshold Rules

| Customer Segment | Transaction Type | Threshold |
|-----------------|-----------------|-----------|
| Age ≤ 70 | Cashout or Redeem | Amount > $100,000 |
| Age > 70 | Cashout or Redeem | Amount > $50,000 |
| Any age | Cashout (pre-filter) | Daily SUM ≥ $200,000 (applied before age check) |
| Any age | Redeem (pre-filter) | Daily SUM > $50,000 (applied before age check) |

The pre-filter (HAVING clause) is applied during aggregation. The age-adjusted final filter then refines the set. A >70-year-old customer with a $75K daily redeem passes the pre-filter (>50K) and passes the final filter (>50K for age>70). A 65-year-old with a $75K daily redeem passes the pre-filter but fails the final filter (<100K threshold for age ≤ 70).

## Upstream Dependencies

| Upstream Object | Type | Role |
|----------------|------|------|
| DWH_dbo.Fact_BillingWithdraw | Table | Cashout/withdrawal requests (CashoutStatusID_Withdraw=1 = Pending) |
| BI_DB_dbo.External_etoro_Billing_Redeem | External Table | Crypto/position redeem requests (etoro.Billing.Redeem source) |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Table | End-of-day instrument prices (BidLast at DateTo = yesterday) |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Table | Salesforce CRM phone contact history |
| DWH_dbo.Dim_Customer | Table | BirthDate (age calculation) + AccountManagerID |
| DWH_dbo.Dim_Manager | Table | Manager name resolution |

## Data Quality Notes

- **Pending-only scope**: Both cashouts (CashoutStatusID_Withdraw=1 = Pending) and redeems (RedeemStatusID=1) filter for pending requests. Processed, cancelled, or in-progress transactions are excluded. The table captures the compliance review backlog, not completed transactions.
- **End-of-day redeem valuation**: Redeem amounts are priced at yesterday's market close (BidLast). This means a volatile position's reported Amount can differ from the actual settlement value if prices move significantly overnight.
- **No historical retention**: TRUNCATE + INSERT means only today's snapshot is visible. If a customer's transaction clears or is cancelled between runs, it disappears from the table. The table cannot be used for trend analysis.
- **NOLOCK hint**: The SP uses `WITH (NOLOCK)` on `BI_DB_UsageTracking_SF`. Contact history may occasionally reflect uncommitted reads; dirty reads are unlikely to materially affect the 'yes'/'no' flag.
- **Space-containing column names**: `[Account Manager]` requires bracket-quoting in all SQL references.

## UC Target

Not Migrated. No `.alter.sql` generated (wiki-only batch).
