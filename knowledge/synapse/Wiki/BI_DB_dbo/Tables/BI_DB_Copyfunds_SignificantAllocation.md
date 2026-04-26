# BI_DB_dbo.BI_DB_Copyfunds_SignificantAllocation

**Generated**: 2026-04-23  
**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_Copyfunds_SignificantAllocation  
**Load Pattern**: TRUNCATE + INSERT (daily snapshot — no history)  
**Distribution**: HASH (CID)  
**Index**: CLUSTERED INDEX (CID ASC)  
**Column Count**: 13  
**Row Count**: 24 (daily, highly variable)  
**Priority**: 99 (OpsDB — FinanceReportSPS, runs last)  
**Frequency**: Daily  
**UC Migration**: Not Migrated  

---

## 1. Overview

Daily **operational alert table** identifying customers with significant CopyFund or PI allocation changes. Each row represents one customer who moved **≥$10K net** (or had bilateral flows ≥$200K) in CopyFund add/remove actions yesterday. Account managers receive this as a daily alert list for proactive client outreach.

**Population thresholds** (as of 2025-11-12, latest change):
- `|NetMoneyIn| >= $10,000` — net flow in or out ≥ $10K (threshold raised from $5K in Mar 2025)
- OR `AddMoneyIn >= $200,000 AND AddMoneyOut >= $200,000` — high bilateral activity even when net is low (added Nov 2025)

**Silent filter**: Only customers with at least one Salesforce contact record (`BI_DB_UsageTracking_SF` with `ActionName IN ('Completed_Contact_Email__c', 'Phone_Call_Succeed__c')`) appear in the output. Customers who have never been contacted are excluded via `INNER JOIN #Contact`. This is not an explicit population filter — it's a side effect of the join.

**Observed data** (latest run, 24 rows): PI=11, CopyPortfolio=7, Both=4. Regions: German=5, UK=3, Spain=2, Arabic GCC=2, etc.

---

## 2. Business Logic

### 2.1 ActionTypeID Semantics for CopyFund Flows

| ActionTypeID | Name | Direction |
|---|---|---|
| 15 | Mirror In | Money added to a copy relationship |
| 16 | Mirror Out | Money removed from a copy relationship |
| 17 | New Mirror | Initial investment when starting a copy |
| 18 | UnMirror | Withdrawal when stopping a copy |

In `Fact_CustomerAction`, amounts for money-out flows (ActionTypeID 16, 18) are stored as positive values (money leaving the account). The SP applies `-1 * SUM(Amount)` to all four types, which makes:
- `AddMoneyIn` positive (net funds added to copies)
- `AddMoneyOut` negative (net funds removed from copies — sign-flipped)
- `NetMoneyOut` = net inflow (positive = added more than withdrew)

### 2.2 `NetMoneyOut` Is a Misnomer

The column `NetMoneyOut` stores **net money IN** (not net money out). The SP calculates `NetMoneyIn` in `#NetMoneyIn` and inserts it into the `NetMoneyOut` column without renaming. Positive values = customer added more to CopyFunds than they removed. Negative values = customer withdrew more than they added.

### 2.3 `Balance` Is Cash, Not Total Equity

`Balance` = `V_Liabilities.Credit` (the customer's cash balance, i.e., available withdrawal amount), NOT total equity. `RealizedEquity` = total realized account value. These are two separate columns from V_Liabilities.

### 2.4 `Manager` Is the Account Manager, Not the CopyFund Manager

`Manager` = `CONCAT(Dim_Manager.FirstName, ' ', Dim_Manager.LastName)` from `dc.AccountManagerID` — the sales/account manager assigned to look after this customer, NOT the CopyFund or PI they are copying.

### 2.5 Contact Status Logic

`ContactedLastMonth`: CASE based on `DATEDIFF(DAY, LastContactedDate, GETDATE()) > 30`:
- 'Contacted' — last contact was within 30 days of today
- 'Not Contacted' — last contact was more than 30 days ago

Note: GETDATE() is used (not @Date), so the 30-day window is relative to the SP execution time.

### 2.6 No @Date Parameter

The SP has no parameter — it uses `@Date = DATEADD(day, -1, GETDATE())` internally. This means the SP always processes yesterday's data regardless of when it is run. It cannot be re-run for a historical date.

---

## 3. Query Advisory

- **24 rows typical**: This table is tiny — full scans are safe. HASH(CID) distribution is over-engineered for 24 rows.
- **No Date column**: This is a daily snapshot with no date tracking. All rows represent "yesterday" as of the last SP run.
- **`NetMoneyOut` is positive for inflows**: Counter-intuitive naming. Positive = customer added money; negative = customer withdrew.
- **`Balance` ≠ total wealth**: Use `RealizedEquity` for total account value. `Balance` is only cash.
- **`Manager` is sales manager**: Not the CopyFund manager. Use `CopyfundsListing` to see which CopyFunds the customer copied.
- **Silent exclusion**: Customers with no Salesforce contact history do not appear, even if their allocation change meets the threshold. Do not use this table as a complete picture of significant allocation changes.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID of the investor who made the significant allocation change. Customer ID — platform-internal primary key. (Tier 1 — DWH_dbo.Dim_Customer via Fact_CustomerAction) |
| UserName | NULL | varchar(20) | Login username of the investor. From Dim_Customer.UserName. Customer login username — unique (case-insensitive). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| Region | NOT NULL | nvarchar(500) | Geographic region of the customer's registered country. From Dim_Country.Region joined via dc.CountryID. Used for regional account manager routing. (Tier 1 — DWH_dbo.Dim_Country via DWH_dbo.Dim_Customer.CountryID) |
| AddMoneyIn | NOT NULL | decimal(38,2) | Total funds added to CopyFund/PI copy relationships yesterday (ActionTypeID 15=Mirror In, 17=New Mirror). Computed as -1 * SUM(Amount) for these action types; positive value = money entering copies. (Tier 2 — DWH_dbo.Fact_CustomerAction, ActionTypeID IN (15,17)) |
| AddMoneyOut | NOT NULL | decimal(38,2) | Total funds withdrawn from CopyFund/PI copy relationships yesterday (ActionTypeID 16=Mirror Out, 18=UnMirror). Computed as -1 * SUM(Amount); negative value = money leaving copies (amounts stored positive in Fact_CustomerAction, then negated). (Tier 2 — DWH_dbo.Fact_CustomerAction, ActionTypeID IN (16,18)) |
| NetMoneyOut | NOT NULL | decimal(38,2) | NAMING MISMATCH: actually stores net money IN. Computed as -1 * SUM(all 4 ActionTypeID 15-18 amounts). Positive = net inflow (customer added more than withdrew); negative = net outflow (customer withdrew more than added). (Tier 2 — DWH_dbo.Fact_CustomerAction, all ActionTypeID IN (15,16,17,18)) |
| Balance | NOT NULL | money | Customer's cash balance (available for withdrawal) as of yesterday: V_Liabilities.Credit. NOT total equity — use RealizedEquity for that. (Tier 2 — DWH_dbo.V_Liabilities.Credit) |
| RealizedEquity | NOT NULL | money | Customer's total realized account value as of yesterday: V_Liabilities.RealizedEquity. (Tier 2 — DWH_dbo.V_Liabilities.RealizedEquity) |
| Manager | NULL | nvarchar(500) | Sales account manager responsible for this customer: CONCAT(Dim_Manager.FirstName, ' ', LastName). NOT the CopyFund or PI manager — this is the eToro internal relationship manager. (Tier 2 — DWH_dbo.Dim_Manager via Dim_Customer.AccountManagerID) |
| CopyfundsListing | NULL | varchar(4000) | Comma-separated list of CopyFund and PI usernames (ParentUserName) the customer copied in yesterday's allocation actions. Built with STRING_AGG ordered alphabetically by ParentUserName. (Tier 2 — DWH_dbo.Dim_Mirror.ParentUserName via Fact_CustomerAction) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE() at TRUNCATE+INSERT time). (Propagation) |
| ContactedLastMonth | NULL | nvarchar(50) | 'Contacted' if the account manager's last Salesforce contact (phone call or email) was within 30 days of SP execution; 'Not Contacted' if more than 30 days ago. Based on BI_DB_UsageTracking_SF. (Tier 2 — BI_DB_dbo.BI_DB_UsageTracking_SF) |
| PI_CopyPortfolio_ind | NULL | varchar(255) | Type of copy arrangement the customer participated in yesterday: 'PI' (copied a Popular Investor only), 'CopyPortfolio' (copied a CopyPortfolio/Fund only), or 'Both PI and CopyPortfolio' (copied at least one of each). (Tier 2 — derived from Dim_Customer.AccountTypeID and GuruStatusID of copied entities) |

---

## 5. Lineage Summary

| Source | Columns Derived |
|--------|-----------------|
| DWH_dbo.Fact_CustomerAction (ActionTypeID 15-18, yesterday) | AddMoneyIn, AddMoneyOut, NetMoneyOut |
| DWH_dbo.Dim_Customer (copier) | CID, UserName |
| DWH_dbo.Dim_Country | Region |
| DWH_dbo.Dim_Manager | Manager |
| DWH_dbo.Dim_Mirror | CopyfundsListing (via ParentUserName), PI_CopyPortfolio_ind |
| DWH_dbo.V_Liabilities | Balance (Credit), RealizedEquity |
| BI_DB_dbo.BI_DB_UsageTracking_SF | ContactedLastMonth |
| ETL metadata | UpdateDate (= GETDATE()) |

---

## 6. OpsDB Orchestration

| Property | Value |
|---|---|
| OpsDB Priority | 99 (FinanceReportSPS — runs last, depends on all other objects) |
| Frequency | Daily |
| Writer SP | SP_Copyfunds_SignificantAllocation |
| ProcessType | FinanceReportSPS (4) |

---

## 7. Quality Notes

- `NetMoneyOut` column name is incorrect — it stores net money IN. Downstream reports must apply sign-awareness.
- `AddMoneyOut` values are negative in practice (raw DB amounts are positive for withdrawals; SP negates them).
- Silent INNER JOIN to `#Contact` means customers with no Salesforce contact history are silently excluded regardless of allocation size.
- No @Date parameter — cannot be re-run for historical dates. Each run overwrites the table with yesterday's data.
- Threshold history: original $5K → $10K (2025-03-31) → added bilateral $200K/$200K clause (2025-11-12). Earlier data in analytics systems may have used the $5K threshold.
