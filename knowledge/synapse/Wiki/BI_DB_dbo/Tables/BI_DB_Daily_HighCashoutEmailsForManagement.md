# BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement

> Daily high-cashout alert table (TRUNCATE+INSERT) listing withdrawal requests >= $50,000 from the previous day (or last 3 days on Mondays), enriched with AML/risk comments, selfie verification, account manager contact status, compensation history, and equity/balance context. Typically 20-30 rows per day. Refreshed daily by SP_Daily_HighCashoutEmailsForManagement.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw (cashouts >= $50K) + DWH_dbo.Dim_Customer + multiple AML/compliance sources via SP_Daily_HighCashoutEmailsForManagement |
| **Refresh** | Daily (SB_Daily, Priority 0). TRUNCATE → INSERT yesterday's high cashouts (Monday: last 3 days) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Pavlina Masuora (2021-05-17) |

---

## 1. Business Meaning

`BI_DB_Daily_HighCashoutEmailsForManagement` is a daily operational alert table that surfaces all withdrawal requests of $50,000 or more for management review. It is designed to support the daily high-cashout email sent to management, combining withdrawal details with customer risk context: AML/risk comments from BackOffice, selfie verification status, whether the customer was contacted in the last 12 months (SalesForce), expired POI (Proof of Identity), historical compensation amounts, and current equity/balance.

The table is TRUNCATED and rebuilt daily — it contains only the most recent day's high cashouts (or last 3 days on Mondays to cover the weekend). The grain is per withdrawal (WithdrawID), with the `CO Amount` column showing the CID-level total (sum across all withdrawals for the CID that day), while `Amount_Withdraw` shows the per-withdrawal amount.

Cashouts are filtered to: FundingTypeID_Withdraw<>27 (excluding a specific funding type) and CashoutStatusID_Withdraw NOT IN (3,4) (excluding approved/cancelled — only pending/in-process are shown).

---

## 2. Business Logic

### 2.1 High Cashout Threshold

**What**: Only customers with total daily cashout requests >= $50,000 are included.
**Columns Involved**: `CO Amount`, `Category`
**Rules**:
- SUM(Amount_Withdraw) per CID must be >= $50,000
- Category classification: $50K-$100K = '50K TO 100K', $100K-$250K = '100K to 250k', >= $250K = '>250K'

### 2.2 Weekend Aggregation

**What**: On Mondays, the SP looks back 3 days (Friday+Saturday+Sunday). Other days, it looks at yesterday only.
**Rules**:
- `IF DATENAME(WEEKDAY, GETDATE()) = 'Monday'` → @dayw = GETDATE()-3
- Non-Monday: @day = GETDATE()-1
- Cashouts from either window are included

### 2.3 AML/Risk Context

**What**: Each high-cashout CID is enriched with compliance context.
**Columns Involved**: `AMLComment`, `RiskComment`, `ProvidedSelfie`, `ExpiredPOI`
**Rules**:
- AMLComment/RiskComment: From External_etoro_BackOffice_Customer (empty string if NULL)
- ProvidedSelfie: 'Yes' if customer has a DocumentTypeID=15 (selfie) in CustomerDocument
- ExpiredPOI: 'yes' if Dim_Customer.IsIDProofExpiryDate <= GETDATE()

### 2.4 Account Manager & Contact Status

**What**: Shows whether the customer was contacted by their account manager in the last 12 months.
**Columns Involved**: `WasContactedLast12Months`, `Account Manager`
**Rules**:
- WasContactedLast12Months: 'yes' if BI_DB_UsageTracking_SF has a Phone_Call_Succeed__c action in last 12 months
- Account Manager: Preferably from the SF contact record, fallback to Dim_Customer.AccountManagerID → Dim_Manager

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no index. Table is very small (typically 20-30 rows) so no optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's high cashouts | `SELECT * ORDER BY [CO Amount] DESC` |
| Pending high cashouts by regulation | `SELECT Regulation, COUNT(*), SUM([CO Amount]) GROUP BY Regulation` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Extended customer profile |

### 3.4 Gotchas

- **Column names with spaces**: `[CO Amount]`, `[Account Manager]` must be bracket-quoted in queries.
- **TRUNCATE+INSERT**: The table is wiped daily — it only shows the most recent day's data. No history is retained.
- **CO Amount vs Amount_Withdraw**: `CO Amount` is the CID-level total (sum), `Amount_Withdraw` is the per-WithdrawID amount. Same CID appears on multiple rows if they have multiple withdrawal requests.
- **RequestorComments**: Column exists in DDL but is NOT populated by the SP — always NULL.
- **Monday 3-day window**: On Mondays, weekend cashouts are included. The Date column shows the actual request date.
- **Pending cashouts only**: CashoutStatusID_Withdraw NOT IN (3=Approved, 4=Cancelled) — this table shows PENDING requests, not approved ones.
- **PII data**: AMLComment and RiskComment contain sensitive compliance notes including customer investigation details.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Date of the cashout request. CAST(RequestDate AS DATE) from Fact_BillingWithdraw. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 2 | CID | int | YES | Customer ID making the high-value withdrawal. FK to Dim_Customer.RealCID. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 3 | WithdrawID | bigint | YES | Unique identifier for the individual withdrawal request. Passthrough from Fact_BillingWithdraw. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 4 | CO Amount | money | YES | Total cashout amount for this CID across all withdrawal requests on this day. SUM(Amount_Withdraw) per CID. Threshold: >= $50,000. Must be bracket-quoted in queries. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 5 | ClientWithdrawReason | varchar(100) | YES | Reason provided by the client for the withdrawal. From Dim_ClientWithdrawReason.ClientWithdrawReasonName. ISNULL default: 'n/a'. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 6 | RequestorComments | varchar(1000) | YES | Comments from the requestor. Column exists in DDL but is NOT populated by the SP — always NULL. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 7 | Category | varchar(100) | YES | Cashout amount bracket. Values: '50K TO 100K', '100K to 250k', '>250K'. CASE-computed from SUM(Amount_Withdraw). (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 8 | Country | varchar(50) | YES | Customer's country name. From Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement via Dim_Country) |
| 9 | Age | int | YES | Customer's age in years. DATEDIFF(year, Dim_Customer.BirthDate, GETDATE()). (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 10 | Regulation | varchar(100) | YES | Regulatory entity governing the customer. From Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 11 | AMLComment | varchar(8000) | YES | AML compliance comment for the customer from BackOffice. Contains investigation notes, case references, and AML analyst actions. PII/sensitive data. ISNULL default: empty string. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 12 | RiskComment | varchar(8000) | YES | Risk assessment comment for the customer from BackOffice. Contains risk analyst notes. PII/sensitive data. ISNULL default: empty string. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 13 | ProvidedSelfie | varchar(50) | YES | Whether the customer has provided a selfie document. Values: 'Yes', 'No'. Checked against BackOffice.CustomerDocument DocumentTypeID=15. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 14 | WasContactedLast12Months | varchar(50) | YES | Whether the customer was contacted via a successful phone call in the last 12 months. Values: 'yes', 'no'. From BI_DB_UsageTracking_SF (ActionName='Phone_Call_Succeed__c'). (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 15 | Account Manager | varchar(100) | YES | Name of the customer's account manager (FirstName + LastName). Prioritizes the SF contact record; falls back to Dim_Customer.AccountManagerID → Dim_Manager. Must be bracket-quoted in queries. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 16 | NWA | money | YES | Net Worth Adjustment — customer's bonus credit balance. From V_Liabilities.BonusCredit. ISNULL default: 0. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 17 | Revenues | money | YES | Total revenues generated by the customer (sum of all closing commissions). SUM(Dim_Position.CommissionOnClose). ISNULL default: 0. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 18 | CustomerStatus | varchar(50) | YES | Customer account status. From Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID (e.g., Normal, Blocked). (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 19 | Verification | varchar(50) | YES | Customer verification status. Values: 'Verified' (VerificationLevelID=3), 'Not Verified' (all others). (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 20 | ExpiredPOI | varchar(50) | YES | Whether the customer's Proof of Identity document has expired. Values: 'yes' (IsIDProofExpiryDate <= GETDATE()), 'no'. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 21 | CompensationAmount | money | YES | Total compensation ever paid to the customer. SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=36. ISNULL default: 0. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 22 | UpdateDate | date | YES | ETL metadata: date when this row was created. GETDATE() truncated to date. (Tier 5 — Propagation) |
| 23 | Amount_Withdraw | money | YES | Individual withdrawal amount for this specific WithdrawID. Passthrough from Fact_BillingWithdraw.Amount_Withdraw. Distinct from CO Amount which is the CID-level total. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 24 | Equity | money | YES | Customer's current equity. Computed: V_Liabilities.Liabilities + V_Liabilities.ActualNWA at @dayID. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 25 | Balance | money | YES | Customer's current credit balance. From V_Liabilities.Credit at @dayID. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 26 | FundingType | varchar(50) | YES | Withdrawal funding method name. From Dim_FundingType.Name via FundingTypeID_Withdraw. Added 2022-02-10. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |
| 27 | CashoutReason | varchar(50) | YES | Cashout reason classification. From Dim_CashoutReason.Name via CashoutReasonID (e.g., 'Requested by User'). Added 2022-07-28. (Tier 2 — SP_Daily_HighCashoutEmailsForManagement) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Passthrough |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Passthrough |
| CO Amount | DWH_dbo.Fact_BillingWithdraw | Amount_Withdraw | SUM per CID (>= $50K) |
| Country | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryID |
| Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(year) |
| AMLComment | External_etoro_BackOffice_Customer | AMLComment | Passthrough |
| Revenues | DWH_dbo.Dim_Position | CommissionOnClose | SUM per CID |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Computed sum |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw
  (RequestDate >= yesterday, FundingTypeID<>27, CashoutStatusID NOT IN 3,4)
  |-- #cashouts (individual withdrawals) ---|
  v
  |-- #cashouts1 (SUM per CID, HAVING >= $50K, Category CASE) ---|
  v
  |-- #cashouts2 (per-withdraw detail + FundingType + CashoutReason) ---|
  v
  + DWH_dbo.Dim_Customer (Country, Age, Regulation, Verification, ExpiredPOI)
  + DWH_dbo.V_Liabilities (NWA, Equity, Balance)
  + DWH_dbo.Dim_Position (Revenues = SUM CommissionOnClose)
  + DWH_dbo.Fact_CustomerAction (CompensationAmount: ActionTypeID=36)
  + External_BackOffice_Customer (AMLComment, RiskComment)
  + External_BackOffice_CustomerDocument (ProvidedSelfie: DocumentTypeID=15)
  + BI_DB_UsageTracking_SF (WasContactedLast12Months: Phone_Call_Succeed__c)
  + DWH_dbo.Dim_Manager (Account Manager)
  |-- #clients ---|
  v
BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement (TRUNCATE+INSERT)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Withdrawal fact |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Today's High Cashout Summary

```sql
SELECT CID, [CO Amount], Category, Country, Regulation,
       [Account Manager], Verification, AMLComment
FROM BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement
ORDER BY [CO Amount] DESC
```

### 7.2 High Cashouts with Risk Flags

```sql
SELECT CID, [CO Amount], Category,
       ExpiredPOI, ProvidedSelfie, WasContactedLast12Months,
       CASE WHEN AMLComment <> '' THEN 'Has AML Notes' ELSE 'Clean' END AS aml_status
FROM BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement
WHERE ExpiredPOI = 'yes' OR ProvidedSelfie = 'No'
ORDER BY [CO Amount] DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 1 T5 | Elements: 27/27, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement | Type: Table | Production Source: Fact_BillingWithdraw + multiple AML/compliance sources via SP_Daily_HighCashoutEmailsForManagement*
