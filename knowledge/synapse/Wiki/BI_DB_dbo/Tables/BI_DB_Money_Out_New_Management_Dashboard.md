# BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard

> 4.19M-row withdrawal transaction table for the management dashboard, containing every cashout/withdrawal request with customer geography, regulation, payment status, auto-approval flag, SLA hours, preparation mode, execution type, and crypto redeem indicator — sourced from Fact_BillingWithdraw enriched with 6 dimension tables. Rolling 7-month window. Refreshed daily via SP_Money_Out_New_Management_Dashboard (Adi Meidan, 2022-07-13). SB_Daily, Priority 0.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw + 6 dimension tables via SP_Money_Out_New_Management_Dashboard |
| **Refresh** | Daily DELETE+INSERT by WithdrawID+CID+FundingID, plus DELETE older than 7 months. SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX(UpdateDate ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~4.19M |
| **Date Range** | RequestDate 2025-10-01 to 2026-04-12 (rolling 7-month window) |
| **Author** | Adi Meidan (2022-07-13) |

---

## 1. Business Meaning

This table provides the **Money Out (withdrawals/cashouts) view for the management dashboard**. Each row represents a single withdrawal funding leg (one WithdrawID + FundingID combination per row), enriched with customer geography, cashout processing status, auto-approval classification, SLA measurement, and execution path.

The SP runs daily and processes withdrawals modified in the last 24 hours (ModificationDate between @PrevDate and @CurDate). It uses a **DELETE+INSERT merge** on WithdrawID+CID+FundingID, then purges data older than 7 months.

Key operational metrics:
- **PaymentStatus**: Processed (98%), Canceled (2%), plus smaller statuses (Pending Review, Payment Sent, InProcess, etc.)
- **AutoApproval**: AutoApproval (96%) vs Manual (4%) — based on Comment field containing "Auto Approval"
- **Preparation**: Auto Create (96%), Canceled (2.4%), Mass Auto Create (1%), Manual (0.9%) — from Dim_CashoutMode
- **ExecutionApproval**: AutoExecuted vs Manual — Manual for OnlineBanking, MoneyBookers, UnionPay, Bank Details, WireTransfer

This is the **companion table to BI_DB_Money_In_New_Management_Dashboard** (deposits). Together they provide the complete Money In/Out view for management.

---

## 2. Business Logic

### 2.1 Withdrawal Amount Resolution

**What**: Determines the actual withdrawal amount from the funding leg or withdraw record.
**Columns Involved**: Amount$Withdraw
**Rules**:
- ISNULL(Amount_WithdrawToFunding, Amount_Withdraw) — prefers the WithdrawToFunding leg amount if present
- This handles the dual-leg structure: a withdraw request may split into multiple funding legs

### 2.2 Auto-Approval Classification

**What**: Determines if the withdrawal was auto-approved or required manual review.
**Columns Involved**: AutoApproval
**Rules**:
- Comment LIKE '%Auto Approval%' → 'AutoApproval'
- Else → 'Manual'

### 2.3 Cashout Status Fallback

**What**: Resolves the payment status with fallback from funding-level to withdraw-level.
**Columns Involved**: CashoutStatusID_Funding, PaymentStatus
**Rules**:
- CashoutStatusID_Funding = ISNULL(bw.CashoutStatusID_Funding, bw.CashoutStatusID_Withdraw)
- PaymentStatus = ISNULL(Dim_CashoutStatus via Funding, Dim_CashoutStatus via Withdraw)
- This ensures every row has a status even if the funding leg hasn't been processed yet

### 2.4 Execution Approval Path

**What**: Classifies whether the withdrawal execution is automated or manual.
**Columns Involved**: ExecutionApproval
**Rules**:
- Manual for: OnlineBanking, MoneyBookers, UnionPay, Bank Details, WireTransfer (funding types that require manual bank processing)
- AutoExecuted for all other funding types (eToroMoney, CreditCard, PayPal, etc.)

### 2.5 Crypto Redeem Indicator

**What**: Flags withdrawals to the eToro crypto wallet.
**Columns Involved**: RedeemInd
**Rules**:
- FundingTypeID_Funding = 27 → RedeemInd = 1 (eToro Crypto Wallet redeem)
- Else → RedeemInd = 0

### 2.6 SLA Hours Measurement

**What**: Measures the processing time from request to last modification.
**Columns Involved**: SLAHours
**Rules**:
- DATEDIFF(HOUR, RequestDate, ModificationDate)
- 0 for newly submitted or auto-processed withdrawals

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** + **CLUSTERED INDEX(UpdateDate ASC)**: Efficient for filtering by ETL update recency but not for business date queries.
- For dashboard queries, filter on RequestDate — will require full scan of the ROUND_ROBIN distribution.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily withdrawal volume | `WHERE CAST(RequestDate AS DATE) = @date AND PaymentStatus = 'Processed'` |
| Auto-approval rate | `SELECT AutoApproval, COUNT(*), SUM([Amount$Withdraw]) GROUP BY AutoApproval` |
| SLA breach monitoring | `WHERE SLAHours > 24 AND PaymentStatus NOT IN ('Processed','Canceled')` |
| Crypto wallet redeems | `WHERE RedeemInd = 1` |
| Manual execution queue | `WHERE ExecutionApproval = 'Manual' AND PaymentStatus NOT IN ('Processed','Canceled')` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer attributes |
| BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard | CID | Pair withdrawals with deposits for net flow analysis |
| DWH_dbo.Dim_Country | (via Region/Country text match) | Extended country attributes |

### 3.4 Gotchas

- **7-month rolling window**: Data older than 7 months is deleted daily. For historical analysis, use Fact_BillingWithdraw directly.
- **WithdrawID is NOT unique**: A single withdrawal can have multiple funding legs (FundingID). The unique key is WithdrawID + CID + FundingID.
- **Amount$Withdraw column name**: Contains a `$` character — must be quoted in SQL as `[Amount$Withdraw]`.
- **SLAHours = 0 for pending**: Newly submitted withdrawals have SLAHours=0 (same-hour as request). Don't interpret 0 as "completed instantly" — check PaymentStatus.
- **Preparation = 'Canceled'**: CashoutModeID is NULL for canceled withdrawals, which get ISNULL fallback to 'Canceled'.
- **PaymentStatus cascades**: The status comes from the funding leg first, falling back to the withdraw leg. Both come from Dim_CashoutStatus.
- **Customer attributes are snapshot-based**: Country, Region, Regulation are from Fact_SnapshotCustomer at the time of the withdrawal, not current attributes.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | Standard ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. From Fact_BillingWithdraw.CID. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 2 | Country | varchar(100) | YES | Customer's country name at the time of withdrawal. From Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 3 | Region | varchar(100) | YES | Marketing region name. From Dim_Country.MarketingRegionManualName. E.g., UK, German, French, CEE, Latam, Spain, SEA. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 4 | Regulation | varchar(100) | YES | Regulatory jurisdiction. From Dim_Regulation.Name via Dim_Country.RegulationID. E.g., FCA, CySEC, FSA Seychelles. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 5 | WithdrawID | int | NO | Withdrawal request identifier from Fact_BillingWithdraw. NOT unique per row — a single withdrawal can have multiple funding legs. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 6 | FundingID | int | YES | Funding leg identifier from Fact_BillingWithdraw. Part of the composite key WithdrawID+CID+FundingID. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 7 | FundingTypeID | int | YES | Funding type code from the withdraw record. From Fact_BillingWithdraw.FundingTypeID. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 8 | WithdrawPaymentID | int | YES | Payment processing ID. ISNULL(WithdrawPaymentID, 0) — defaults to 0 when NULL. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 9 | CashoutStatusID_Withdraw | int | YES | Cashout status at the withdraw level. From Fact_BillingWithdraw.CashoutStatusID_Withdraw. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 10 | CashoutStatusID_Funding | int | YES | Cashout status at the funding leg level. Falls back to CashoutStatusID_Withdraw when NULL. ISNULL(CashoutStatusID_Funding, CashoutStatusID_Withdraw). (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 11 | PaymentStatus | varchar(100) | YES | Payment status label. From Dim_CashoutStatus.Name via CashoutStatusID_Funding (primary) or CashoutStatusID_Withdraw (fallback). 13 values: Processed, Canceled, Pending Review, Payment Sent, InProcess, Pending, SentToProvider, RejectedByProvider, Rejected, PendingByProvider, SentToBilling, Under Review, Failed. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 12 | RequestDate | datetime | NO | Withdrawal request date and time. From Fact_BillingWithdraw.RequestDate. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 13 | Amount$Withdraw | money | YES | Withdrawal amount in account currency. ISNULL(Amount_WithdrawToFunding, Amount_Withdraw) — prefers funding leg amount. Note: column name contains `$`. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 14 | Fee | money | YES | Withdrawal fee amount. From Fact_BillingWithdraw.Fee. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 15 | ModificationDate | datetime | YES | Last modification timestamp. From Fact_BillingWithdraw.ModificationDate. Used to filter daily processing window. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 16 | AutoApproval | varchar(100) | YES | Whether the withdrawal was auto-approved. AutoApproval (96%) if Comment contains 'Auto Approval', Manual (4%) otherwise. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 17 | FundingType | varchar(100) | YES | Funding type name. From Dim_FundingType.Name via FundingTypeID_Withdraw. E.g., eToroMoney, CreditCard, WireTransfer, PayPal. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 18 | RedeemInd | int | YES | Crypto wallet redeem indicator. 1 if FundingTypeID_Funding=27 (eToro Crypto Wallet), 0 otherwise. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 19 | SLAHours | int | YES | Hours between request and last modification. DATEDIFF(HOUR, RequestDate, ModificationDate). 0 for same-hour processing or pending requests. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 20 | Preparation | varchar(100) | YES | Cashout preparation mode. From Dim_CashoutMode.CashoutModeName, ISNULL to 'Canceled'. 4 values: Auto Create, Canceled, Mass Auto Create, Manual. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 21 | ExecutionApproval | varchar(100) | YES | Execution path classification. Manual for bank transfer methods (OnlineBanking, MoneyBookers, UnionPay, Bank Details, WireTransfer), AutoExecuted for all others. (Tier 2 — SP_Money_Out_New_Management_Dashboard) |
| 22 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_Money_Out_New_Management_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| CID, WithdrawID, FundingID, FundingTypeID, CashoutStatusID_Withdraw, RequestDate, Fee, ModificationDate | DWH_dbo.Fact_BillingWithdraw | Direct columns | Direct passthrough |
| Country, Region | DWH_dbo.Dim_Country via Fact_SnapshotCustomer | Name, MarketingRegionManualName | Snapshot-based lookup |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Country.RegulationID |
| PaymentStatus | DWH_dbo.Dim_CashoutStatus | Name | Via CashoutStatusID_Funding or _Withdraw |
| FundingType | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID_Withdraw |
| Preparation | DWH_dbo.Dim_CashoutMode | CashoutModeName | Via CashoutModeID |
| AutoApproval, RedeemInd, SLAHours, ExecutionApproval, Amount$Withdraw, WithdrawPaymentID, CashoutStatusID_Funding | Computed | Multiple | CASE/ISNULL/DATEDIFF |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (withdrawal transactions)
  + Dim_Country, Dim_Regulation, Dim_FundingType,
    Dim_CashoutStatus, Dim_CashoutMode, Fact_SnapshotCustomer, Dim_Range
  |-- SP_Money_Out_New_Management_Dashboard @Date ---|
  |   (DELETE matching WithdrawID+CID+FundingID, INSERT, DELETE >7 months)
  v
BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard (4.19M rows, 7-month window)
  |-- Management Dashboard (Money Out view) ---|
  v
Management Dashboard
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw.WithdrawID | Source withdrawal transaction |
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| FundingTypeID | DWH_dbo.Dim_FundingType.FundingTypeID | Funding type dimension |
| CashoutStatusID_Withdraw | DWH_dbo.Dim_CashoutStatus.DWHCashoutStatusID | Status dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard | Companion table — Money In (deposits) for the same dashboard |

---

## 7. Sample Queries

### 7.1 Daily Withdrawal Volume by Status

```sql
SELECT CAST(RequestDate AS DATE) AS withdraw_date,
       PaymentStatus,
       COUNT(*) AS cnt,
       SUM([Amount$Withdraw]) AS total_amount
FROM [BI_DB_dbo].[BI_DB_Money_Out_New_Management_Dashboard]
WHERE RequestDate >= '2026-04-01'
GROUP BY CAST(RequestDate AS DATE), PaymentStatus
ORDER BY withdraw_date DESC, cnt DESC
```

### 7.2 Auto-Approval Rate by Regulation

```sql
SELECT Regulation,
       COUNT(*) AS total,
       SUM(CASE WHEN AutoApproval = 'AutoApproval' THEN 1 ELSE 0 END) AS auto_approved,
       SUM(CASE WHEN AutoApproval = 'AutoApproval' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS auto_pct
FROM [BI_DB_dbo].[BI_DB_Money_Out_New_Management_Dashboard]
WHERE RequestDate >= '2026-04-01'
GROUP BY Regulation
ORDER BY total DESC
```

### 7.3 SLA Monitoring — Pending Withdrawals Over 24 Hours

```sql
SELECT CID, WithdrawID, FundingID, RequestDate, ModificationDate,
       SLAHours, PaymentStatus, FundingType, Preparation
FROM [BI_DB_dbo].[BI_DB_Money_Out_New_Management_Dashboard]
WHERE SLAHours > 24
  AND PaymentStatus NOT IN ('Processed', 'Canceled')
ORDER BY SLAHours DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 1 T5 | Elements: 22/22, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard | Type: Table | Production Source: Fact_BillingWithdraw + 6 dimension tables*
