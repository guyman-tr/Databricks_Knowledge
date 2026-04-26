# BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis

> 17,925-row historical archive of high-value cashout alerts (>=$50K) from 2024-07-19 to present, tracking 9,046 distinct customers across 3 amount brackets (50K-100K, 100K-250K, >250K). Each row snapshots a day's high-cashout email data and is enriched with withdrawal lifecycle status from Fact_BillingWithdraw and Salesforce contact attempt counts. Refreshed daily via SP_BI_DB_High_Cashout_Emails_For_Management_Analysis (SB_Daily).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_Daily_HighCashoutEmailsForManagement + Fact_BillingWithdraw + BI_DB_UsageTracking_SF via SP_BI_DB_High_Cashout_Emails_For_Management_Analysis |
| **Refresh** | Daily (SB_Daily, DELETE yesterday + INSERT + UPDATE enrichment) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_High_Cashout_Emails_For_Management_Analysis` is a daily historical archive that tracks high-value cashout requests (>=$50,000) flagged for management attention. It serves as the analysis layer for the "High Cashout Emails For Management" operational workflow, preserving daily snapshots of cashout alerts and enriching them with withdrawal lifecycle data and Salesforce contact tracking.

Each row represents a single withdrawal request (WithdrawID) on a specific snapshot date. The table accumulates history — unlike the daily email table (`BI_DB_Daily_HighCashoutEmailsForManagement`) which is truncated daily, this table retains all historical snapshots since 2024-07-19.

The SP operates in two phases:
1. **INSERT phase**: Copies yesterday's data from `BI_DB_Daily_HighCashoutEmailsForManagement` with "Snapshot_" prefix on column names (25 columns capturing the customer profile at alert time: amount bracket, country, regulation, AML/risk comments, verification status, account manager, NWA, revenues, etc.)
2. **UPDATE phase**: Enriches ALL rows (not just newly inserted) with current withdrawal status from `Fact_BillingWithdraw` (RequestDate, ModificationDate, CashoutStatus, CashoutStatusID_Withdraw) and Salesforce contact attempt counts from `BI_DB_UsageTracking_SF` (phone calls, emails attempted/completed within the request-to-resolution window)

The 3 amount brackets: 50K TO 100K (65%), 100K to 250k (27%), >250K (8%). Most cashouts resolve to Processed (94.3%) or Canceled (5.3%), with a small tail of Pending/InProcess (0.4% combined).

Created by Jan Iablunovskey (Insights Team) on 2024-07-16. Contact tracking columns (Completed_Email, Attemp_Phone_Call, Attemp_Email) added 2024-08-11.

---

## 2. Business Logic

### 2.1 Daily Snapshot Accumulation

**What**: Each day, yesterday's high-cashout alerts are archived into this table.
**Columns Involved**: `Snapshot_Date`, all `Snapshot_*` columns
**Rules**:
- DELETE existing rows for GETDATE()-1 (idempotent re-run protection)
- INSERT from BI_DB_Daily_HighCashoutEmailsForManagement — all rows, no filter
- Snapshot columns preserve the state at the time of the daily email alert

### 2.2 Withdrawal Lifecycle Enrichment

**What**: All rows (not just new ones) are updated with the current withdrawal status.
**Columns Involved**: `RequestDate`, `ModificationDate`, `Max_UpdateDate_BillingWithdraw`, `CashoutStatus`, `CashoutStatusID_Withdraw`
**Rules**:
- JOIN to Fact_BillingWithdraw on WithdrawID
- CashoutStatus resolved via Dim_CashoutStatus.Name
- Max_UpdateDate_BillingWithdraw is a global scalar: MAX(Fact_BillingWithdraw.UpdateDate) — same value for all rows in a given run

### 2.3 Contact Tracking Window

**What**: Salesforce contact attempts are counted within the request-to-resolution window.
**Columns Involved**: `Phone_Calls`, `Completed_Email`, `Attemp_Phone_Call`, `Attemp_Email`
**Rules**:
- For processed/canceled cashouts (CashoutStatusID IN 3,4): window = RequestDate to ModificationDate
- For still-pending cashouts: window = RequestDate to Max_UpdateDate_BillingWithdraw
- Phone_Calls = SUM of Phone_Call_Succeed__c actions
- Completed_Email = SUM of Completed_Contact_Email__c actions
- Attemp_Phone_Call = SUM of Contacted__c actions (includes unsuccessful)
- Attemp_Email = SUM of Outbound_Email__c actions
- ISNULL default: 0 for all contact counts

### 2.4 Amount Brackets

**What**: Cashouts are categorized by total CID-level daily amount.
**Columns Involved**: `Snapshot_Category`, `Snapshot_CO Amount`
**Rules**:
- '50K TO 100K': SUM(Amount_Withdraw) >= $50,000 and < $100,000
- '100K to 250k': >= $100,000 and < $250,000
- '>250K': >= $250,000

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with HEAP — optimized for CID-level joins and grouping. No clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many high-cashout alerts per day? | `SELECT Snapshot_Date, COUNT(*) FROM ... GROUP BY Snapshot_Date ORDER BY 1 DESC` |
| Cashout resolution rate by category | `SELECT Snapshot_Category, CashoutStatus, COUNT(*) FROM ... GROUP BY 1,2` |
| Contact effectiveness for pending cashouts | `SELECT * FROM ... WHERE CashoutStatusID_Withdraw IN (1,2) AND (Phone_Calls > 0 OR Completed_Email > 0)` |
| Trend of high-value cashouts by regulation | `SELECT Snapshot_Regulation, YEAR(Snapshot_Date), MONTH(Snapshot_Date), COUNT(*) FROM ... GROUP BY 1,2,3` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | Dim_Customer.RealCID = CID | Additional customer attributes |
| DWH_dbo.Fact_BillingWithdraw | Fact_BillingWithdraw.WithdrawID = WithdrawID | Full withdrawal details |

### 3.4 Gotchas

- **Column names have spaces and special characters**: `[Snapshot_CO Amount]`, `[Snapshot_Account Manager]` — always use bracket notation
- **Snapshot_RequestorComments is always NULL**: Column exists in DDL but is NOT populated by the SP
- **Typo in column name**: `Attemp_Phone_Call` and `Attemp_Email` — missing 't' (should be "Attempt")
- **Contact counts update retroactively**: The UPDATE phase enriches ALL rows, so Phone_Calls/email counts increase over time as more contacts happen
- **Max_UpdateDate_BillingWithdraw is the same for all rows**: It's a global scalar (MAX(UpdateDate) from Fact_BillingWithdraw), not per-row
- **Duplicate rows possible**: If the same WithdrawID appears in the daily email table on multiple days, it will have multiple rows with different Snapshot_Date values

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (Fact_BillingWithdraw — verbatim from Billing.Withdraw) | Highest |
| Tier 2 | SP code analysis + BI_DB_Daily_HighCashoutEmailsForManagement wiki | High |
| Tier 5 | ETL metadata (GETDATE) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Snapshot_Date | date | YES | Date of the cashout request. CAST(RequestDate AS DATE) from Fact_BillingWithdraw. Renamed from Date in source table. Passthrough from BI_DB_Daily_HighCashoutEmailsForManagement. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 2 | CID | int | YES | Customer ID making the high-value withdrawal. FK to Dim_Customer.RealCID. Passthrough from BI_DB_Daily_HighCashoutEmailsForManagement. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 3 | WithdrawID | bigint | YES | Unique identifier for the individual withdrawal request. Passthrough from Fact_BillingWithdraw. Passthrough from BI_DB_Daily_HighCashoutEmailsForManagement. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 4 | Snapshot_CO Amount | money | YES | Total cashout amount for this CID across all withdrawal requests on this day. SUM(Amount_Withdraw) per CID. Threshold: >= $50,000. Must be bracket-quoted in queries. Renamed from CO Amount. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 5 | Snapshot_ClientWithdrawReason | varchar(100) | YES | Reason provided by the client for the withdrawal. From Dim_ClientWithdrawReason.ClientWithdrawReasonName. ISNULL default: 'n/a'. Renamed from ClientWithdrawReason. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 6 | Snapshot_RequestorComments | varchar(1000) | YES | Comments from the requestor. Column exists in DDL but is NOT populated by the SP — always NULL. Renamed from RequestorComments. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 7 | Snapshot_Category | varchar(100) | YES | Cashout amount bracket. Values: '50K TO 100K', '100K to 250k', '>250K'. CASE-computed from SUM(Amount_Withdraw). Renamed from Category. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 8 | Snapshot_Country | varchar(50) | YES | Customer's country name. From Dim_Country.Name via Dim_Customer.CountryID. Renamed from Country. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement via Dim_Country) |
| 9 | Snapshot_Age | int | YES | Customer's age in years. DATEDIFF(year, Dim_Customer.BirthDate, GETDATE()). Renamed from Age. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 10 | Snapshot_Regulation | varchar(100) | YES | Regulatory entity governing the customer. From Dim_Regulation.Name via Dim_Customer.RegulationID. Renamed from Regulation. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 11 | Snapshot_AMLComment | varchar(8000) | YES | AML compliance comment for the customer from BackOffice. Contains investigation notes, case references, and AML analyst actions. PII/sensitive data. ISNULL default: empty string. Renamed from AMLComment. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 12 | Snapshot_RiskComment | varchar(8000) | YES | Risk assessment comment for the customer from BackOffice. Contains risk analyst notes. PII/sensitive data. ISNULL default: empty string. Renamed from RiskComment. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 13 | Snapshot_ProvidedSelfie | varchar(50) | YES | Whether the customer has provided a selfie document. Values: 'Yes', 'No'. Checked against BackOffice.CustomerDocument DocumentTypeID=15. Renamed from ProvidedSelfie. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 14 | Snapshot_WasContactedLast12Months | varchar(50) | YES | Whether the customer was contacted via a successful phone call in the last 12 months. Values: 'yes', 'no'. From BI_DB_UsageTracking_SF (ActionName='Phone_Call_Succeed__c'). Renamed from WasContactedLast12Months. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 15 | Snapshot_Account Manager | varchar(100) | YES | Name of the customer's account manager (FirstName + LastName). Prioritizes the SF contact record; falls back to Dim_Customer.AccountManagerID → Dim_Manager. Must be bracket-quoted in queries. Renamed from Account Manager. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 16 | Snapshot_NWA | money | YES | Net Worth Adjustment — customer's bonus credit balance. From V_Liabilities.BonusCredit. ISNULL default: 0. Renamed from NWA. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 17 | Snapshot_Revenues | money | YES | Total revenues generated by the customer (sum of all closing commissions). SUM(Dim_Position.CommissionOnClose). ISNULL default: 0. Renamed from Revenues. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 18 | Snapshot_CustomerStatus | varchar(50) | YES | Customer account status. From Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID (e.g., Normal, Blocked). Renamed from CustomerStatus. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 19 | Snapshot_Verification | varchar(50) | YES | Customer verification status. Values: 'Verified' (VerificationLevelID=3), 'Not Verified' (all others). Renamed from Verification. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 20 | Snapshot_ExpiredPOI | varchar(50) | YES | Whether the customer's Proof of Identity document has expired. Values: 'yes' (IsIDProofExpiryDate <= GETDATE()), 'no'. Renamed from ExpiredPOI. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 21 | Snapshot_CompensationAmount | money | YES | Total compensation ever paid to the customer. SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=36. ISNULL default: 0. Renamed from CompensationAmount. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 22 | Snapshot_Amount_Withdraw | money | YES | Individual withdrawal amount for this specific WithdrawID. Passthrough from Fact_BillingWithdraw.Amount_Withdraw. Distinct from Snapshot_CO Amount which is the CID-level total. Renamed from Amount_Withdraw. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 23 | Snapshot_Equity | money | YES | Customer's current equity. Computed: V_Liabilities.Liabilities + V_Liabilities.ActualNWA at @dayID. Renamed from Equity. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 24 | Snapshot_Balance | money | YES | Customer's current credit balance. From V_Liabilities.Credit at @dayID. Renamed from Balance. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 25 | Snapshot_FundingType | varchar(50) | YES | Withdrawal funding method name. From Dim_FundingType.Name via FundingTypeID_Withdraw. Renamed from FundingType. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 26 | Snapshot_CashoutReason | varchar(50) | YES | Cashout reason classification. From Dim_CashoutReason.Name via CashoutReasonID (e.g., 'Requested by User'). Renamed from CashoutReason. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 27 | RequestDate | datetime2(7) | YES | Timestamp when the customer submitted the withdrawal request. Enrichment column from Fact_BillingWithdraw via JOIN on WithdrawID. (Tier 1 — Billing.Withdraw) |
| 28 | ModificationDate | datetime2(7) | YES | UTC timestamp of the most recent status change or update on the withdrawal request. Enrichment column from Fact_BillingWithdraw via JOIN on WithdrawID. (Tier 1 — Billing.Withdraw) |
| 29 | Max_UpdateDate_BillingWithdraw | datetime2(7) | YES | Global scalar: MAX(Fact_BillingWithdraw.UpdateDate). Same value for all rows in a given SP run. Used as the "current time" proxy for pending cashouts when computing contact tracking windows. (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |
| 30 | CashoutStatus | varchar(50) | YES | Cashout status name resolved from Dim_CashoutStatus via Fact_BillingWithdraw.CashoutStatusID_Withdraw. Values: Pending (1), InProcess (2), Processed (3), Canceled (4). (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis via Dim_CashoutStatus) |
| 31 | CashoutStatusID_Withdraw | int | YES | Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.Withdraw) |
| 32 | Phone_Calls | int | YES | Count of successful phone calls (Phone_Call_Succeed__c in Salesforce) between RequestDate and cashout resolution date. From BI_DB_UsageTracking_SF. ISNULL default: 0. (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |
| 33 | UpdateDate | date | YES | ETL metadata: date when this row was last updated by the SP. GETDATE(). Set during both INSERT and UPDATE phases. (Tier 5 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |
| 34 | Completed_Email | int | YES | Count of completed contact emails (Completed_Contact_Email__c in Salesforce) between RequestDate and cashout resolution date. From BI_DB_UsageTracking_SF. ISNULL default: 0. Added 2024-08-11. (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |
| 35 | Attemp_Phone_Call | int | YES | Count of phone call attempts (Contacted__c in Salesforce) between RequestDate and cashout resolution date. Includes both successful and unsuccessful attempts. From BI_DB_UsageTracking_SF. ISNULL default: 0. Added 2024-08-11. Note: column name has typo ("Attemp" instead of "Attempt"). (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |
| 36 | Attemp_Email | int | YES | Count of outbound email attempts (Outbound_Email__c in Salesforce) between RequestDate and cashout resolution date. From BI_DB_UsageTracking_SF. ISNULL default: 0. Added 2024-08-11. Note: column name has typo ("Attemp" instead of "Attempt"). (Tier 2 — SP_BI_DB_High_Cashout_Emails_For_Management_Analysis) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| Snapshot_* (25 cols) | BI_DB_Daily_HighCashoutEmailsForManagement | Various | Rename with Snapshot_ prefix. Passthrough. |
| RequestDate | Billing.Withdraw (via Fact_BillingWithdraw) | RequestDate | Passthrough |
| ModificationDate | Billing.Withdraw (via Fact_BillingWithdraw) | ModificationDate | Passthrough |
| Max_UpdateDate_BillingWithdraw | Fact_BillingWithdraw | UpdateDate | MAX() aggregate |
| CashoutStatus | Dim_CashoutStatus | Name | Lookup |
| CashoutStatusID_Withdraw | Billing.Withdraw (via Fact_BillingWithdraw) | CashoutStatusID | Passthrough (renamed) |
| Phone_Calls | BI_DB_UsageTracking_SF | Phone_Call_Succeed__c | SUM(CASE) |
| Completed_Email | BI_DB_UsageTracking_SF | Completed_Contact_Email__c | SUM(CASE) |
| Attemp_Phone_Call | BI_DB_UsageTracking_SF | Contacted__c | SUM(CASE) |
| Attemp_Email | BI_DB_UsageTracking_SF | Outbound_Email__c | SUM(CASE) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (active, etoroDB-REAL)
  |-- Generic Pipeline (Override, delta) ---|
  v
DWH_dbo.Fact_BillingWithdraw
  |                                         |
  v                                         |
BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement (daily TRUNCATE)
  |                                         |
  +--- SP_BI_DB_High_Cashout_Emails... ----|
  |    Phase 1: DELETE yesterday + INSERT   |
  |    Phase 2: UPDATE with:               |
  |      - Fact_BillingWithdraw (status)   |
  |      - Dim_CashoutStatus (name)        |
  |      - BI_DB_UsageTracking_SF (contact)|
  v
BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis (17.9K rows, accumulating)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (via RealCID) |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Withdrawal fact (enrichment JOIN) |
| CashoutStatusID_Withdraw | DWH_dbo.Dim_CashoutStatus | Cashout status dimension |
| Snapshot_* columns | BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement | Source daily email table |

### 6.2 Referenced By (other objects point to this)

No other BI_DB_dbo objects reference this table. It is a leaf analysis table consumed by the Insights team dashboard.

---

## 7. Sample Queries

### 7.1 High-cashout resolution rate by amount bracket

```sql
SELECT
    [Snapshot_Category],
    CashoutStatus,
    COUNT(*) AS AlertCount,
    SUM([Snapshot_CO Amount]) AS TotalAmount
FROM BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis
GROUP BY [Snapshot_Category], CashoutStatus
ORDER BY [Snapshot_Category], AlertCount DESC
```

### 7.2 Contact effectiveness for pending cashouts

```sql
SELECT
    CID,
    WithdrawID,
    [Snapshot_CO Amount],
    [Snapshot_Category],
    Phone_Calls,
    Completed_Email,
    Attemp_Phone_Call,
    Attemp_Email,
    CashoutStatus,
    RequestDate
FROM BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis
WHERE CashoutStatusID_Withdraw IN (1, 2)  -- Still pending/in-process
ORDER BY [Snapshot_CO Amount] DESC
```

### 7.3 Monthly trend of high-value cashout alerts

```sql
SELECT
    YEAR(Snapshot_Date) AS AlertYear,
    MONTH(Snapshot_Date) AS AlertMonth,
    [Snapshot_Category],
    COUNT(*) AS AlertCount,
    COUNT(DISTINCT CID) AS DistinctCustomers
FROM BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis
GROUP BY YEAR(Snapshot_Date), MONTH(Snapshot_Date), [Snapshot_Category]
ORDER BY 1, 2, 3
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 32 T2, 0 T3, 0 T4, 1 T5 | Elements: 36/36, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis | Type: Table | Production Source: BI_DB_Daily_HighCashoutEmailsForManagement + Fact_BillingWithdraw via SP_BI_DB_High_Cashout_Emails_For_Management_Analysis*
