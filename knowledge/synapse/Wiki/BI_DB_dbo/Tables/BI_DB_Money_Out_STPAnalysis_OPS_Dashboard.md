# BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard

> 4.17M-row operations dashboard table tracking completed withdrawal (cashout) straight-through-processing (STP) metrics, covering Oct 2025 to present (7-month rolling window). Each row represents one processed withdrawal payment leg with approval workflow flags (OPS, Risk, Trading, AML, Administrators), execution method, preparation mode, and funding type. Refreshed daily by SP_H_Money_Out_STPAnalysis_OPS_Dashboard via DELETE+INSERT on the daily window.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Withdraw + Billing.vWithdrawToFunding + BackOffice.WithdrawApproval via SP_H_Money_Out_STPAnalysis_OPS_Dashboard |
| **Refresh** | Daily (DELETE matching rows + INSERT + purge >7 months) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, daily) |

---

## 1. Business Meaning

This table is an Operations STP (Straight-Through Processing) dashboard for withdrawal (Money Out) transactions. It tracks every completed withdrawal payment leg — specifically those with `CashoutStatusID=3` (Processed) — and breaks down whether each step of the withdrawal pipeline was automated or required manual intervention.

The table answers the key operations question: **"What percentage of our withdrawals are fully automated (STP) vs. requiring manual touchpoints?"**

Each row represents one payment leg (`WithdrawPaymentID` from `Billing.WithdrawToFunding`) for a processed withdrawal request. The SP joins withdrawal requests with their payment execution legs, enriches with approval workflow data from `BackOffice.WithdrawApproval`, and flags which back-office groups (OPS, Risk, Trading, AML, Administrators) manually approved each withdrawal (excluding auto-approvals).

Key findings from live data:
- **97.6%** of withdrawals are auto-approved (no manual approval needed)
- **91%** use Auto Execute for execution
- **96.6%** use Auto Create for payment preparation
- **84%** of withdrawals are sent via eToroMoney, followed by WireTransfer (6.8%) and CreditCard (5.5%)
- **98.6%** of rows have all five approval flags = 0 (fully STP, no manual group approval)

The SP uses a daily window (`@PrevDate` to `@CurDate`) for DELETE+INSERT and purges data older than 7 months.

Note: The SP creates a `#FINAL` temp table that enriches with PlayerLevel and Regulation from Dim_Customer, but the actual INSERT reads from `#billing` — making the `#FINAL` enrichment dead code.

---

## 2. Business Logic

### 2.1 STP Approval Classification

**What**: Each withdrawal is classified as auto-approved or manually approved based on the approval comments in BackOffice.WithdrawApproval.
**Columns Involved**: AutoApproval, OPSApproved, RiskApproved, TradingApproved, AMLApproved, AmdinistratorsApproved
**Rules**:
- AutoApproval = 'Auto Approval' or 'Cleared - Auto Approval' if the Comment field matches those strings; otherwise 'Manual'
- Each group flag (OPSApproved, etc.) = 1 only when that UserGroupID has Approved=1 AND the Comment is NOT one of the auto-approval strings
- UserGroupID mapping: 2=OPS, 3=Risk, 6=Trading, 36=AML, 1=Administrators
- A withdrawal can have multiple group approvals — flags are independent

### 2.2 Execution Method Classification

**What**: Tracks how the payment execution was initiated.
**Columns Involved**: ExecutionApproval
**Rules**:
- Resolved from Dictionary.ExecuteEntryMethod via RequestExecuteEntryMethodId on WithdrawToFunding
- Values: Auto Execute (91%), Manually Updated (6.8%), Manual Execute (2.1%), empty (0.08%)

### 2.3 Preparation Mode

**What**: How the payment leg was prepared (created).
**Columns Involved**: Preparation
**Rules**:
- Resolved from Dim_CashoutMode.CashoutModeName via CashoutModeID on WithdrawToFunding
- Values: Auto Create (96.6%), Mass Auto Create (2%), empty (0.95%), Manual (0.47%)

### 2.4 Data Window and Purge

**What**: Rolling 7-month window of processed withdrawals.
**Columns Involved**: ModificationDate
**Rules**:
- Daily load: DELETE WHERE matching WithdrawID+CID+WithdrawPaymentID from today's extraction, then INSERT fresh data
- Purge: DELETE WHERE ModificationDate < 7 months before end of current month
- Only CashoutStatusID=3 (Processed) withdrawals are included

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key optimization. For JOINs on WithdrawID or CID, expect data movement. Suitable for dashboard-style full-scan aggregation queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What % of withdrawals are fully STP? | `SELECT AutoApproval, COUNT(*) FROM ... GROUP BY AutoApproval` |
| Which funding types have highest manual rate? | `SELECT FundingType_Sent, AVG(CASE WHEN AutoApproval='Manual' THEN 1.0 ELSE 0 END) FROM ... GROUP BY FundingType_Sent` |
| Daily STP rate trend | `SELECT CAST(ModificationDate AS DATE), SUM(CASE WHEN AutoApproval LIKE '%Auto%' THEN 1 ELSE 0 END)*100.0/COUNT(*) FROM ... GROUP BY CAST(ModificationDate AS DATE)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | Dim_Customer.RealCID = CID | Customer attributes (regulation, country, player level) |
| DWH_dbo.Dim_FundingType | Dim_FundingType.Name = FundingType_Sent | Funding type hierarchy |

### 3.4 Gotchas

- **AmdinistratorsApproved** — typo in column name (should be "Administrators"). Baked into DDL.
- **Amount$Withdraw** — dollar sign in column name requires bracket quoting: `[Amount$Withdraw]`
- **#FINAL dead code** — the SP creates a #FINAL temp table with PlayerLevel and Regulation enrichment, but the actual INSERT reads from #billing. These columns are not in the target table.
- **All approval flags = 0 does NOT mean "not approved"** — it means no manual group approval was required (auto-approved). The withdrawal is still processed (CashoutStatusID=3).
- **ModificationDate is from WithdrawToFunding**, not from Billing.Withdraw. It tracks the payment leg modification, not the request modification.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 3 | Distribution analysis | Medium — inferred from live data patterns |
| Tier 4 | Best available knowledge | Lower — limited upstream documentation |
| Tier 5 | Propagation canonical | Standard ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | bigint | YES | References the parent withdrawal request in Billing.Withdraw. No explicit FK constraint. Multiple rows share a WithdrawID (one per approval group). Part of DELETE+INSERT key alongside CID and WithdrawPaymentID. (Tier 1 — Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. Identifies the customer who submitted the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 3 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 4 | Amount$Withdraw | money | YES | Payout amount in process currency. MONEY type (4 decimal places). For refunds, this is the amount being refunded to the card/instrument. Renamed from Billing.WithdrawToFunding.Amount. (Tier 1 — Billing.WithdrawToFunding) |
| 5 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change on the payment leg. Used for daily window extraction and 7-month purge boundary. (Tier 1 — Billing.WithdrawToFunding) |
| 6 | ExecutionApproval | varchar(max) | YES | How the payment execution was initiated. Resolved from Dictionary.ExecuteEntryMethod.DisplayName via WithdrawToFunding.RequestExecuteEntryMethodId. Auto Execute, Manually Updated, Manual Execute, or empty. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 7 | AutoApproval | varchar(max) | YES | Whether the withdrawal was auto-approved or required manual approval. CASE on BackOffice.WithdrawApproval.Comment: 'Auto Approval' or 'Cleared - Auto Approval' if Comment matches those strings, else 'Manual'. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 8 | Preparation | varchar(max) | YES | Payment leg preparation mode. Resolved from Dim_CashoutMode.CashoutModeName via WithdrawToFunding.CashoutModeID. Auto Create, Mass Auto Create, Manual, or empty. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 10 | WithdrawPaymentID | bigint | YES | Payment leg ID from Billing.WithdrawToFunding (Billing.WithdrawToFunding.ID). Identifies the specific payment execution leg for this withdrawal. Part of DELETE+INSERT key. (Tier 1 — Billing.WithdrawToFunding) |
| 11 | FundingType_Sent | varchar(max) | YES | Payment method used for the payout. Resolved via JOIN chain: WithdrawToFunding.FundingID → Billing.Funding_Datafactory.FundingTypeID → Dim_FundingType.Name. 13 distinct values: eToroMoney, WireTransfer, CreditCard, PayPal, eToroCryptoWallet, EtoroOptions, iDEAL, PWMB, MoneyBookers, Przelewy24, Trustly, Neteller, OnlineBanking. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 12 | OPSApproved | int | YES | 1 if the OPS team (UserGroupID=2) manually approved this withdrawal (Approved=1 and Comment not in auto-approval strings), 0 otherwise. Derived from BackOffice.WithdrawApproval via MAX(CASE). (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 13 | RiskApproved | int | YES | 1 if the Risk team (UserGroupID=3) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 14 | TradingApproved | int | YES | 1 if the Trading team (UserGroupID=6) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 15 | AMLApproved | int | YES | 1 if the AML team (UserGroupID=36) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |
| 16 | AmdinistratorsApproved | int | YES | 1 if the Administrators group (UserGroupID=1) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. Column name is a typo — should be "AdministratorsApproved". (Tier 2 — SP_H_Money_Out_STPAnalysis_OPS_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| WithdrawID | Billing.Withdraw | WithdrawID | Passthrough |
| CID | Billing.Withdraw | CID | Passthrough |
| RequestDate | Billing.Withdraw | RequestDate | Passthrough |
| Amount$Withdraw | Billing.WithdrawToFunding | Amount | Rename |
| ModificationDate | Billing.WithdrawToFunding | ModificationDate | Passthrough |
| ExecutionApproval | Dictionary.ExecuteEntryMethod | DisplayName | JOIN lookup |
| AutoApproval | BackOffice.WithdrawApproval | Comment | CASE classification |
| Preparation | Dim_CashoutMode | CashoutModeName | JOIN lookup |
| UpdateDate | ETL | GETDATE() | Generated |
| WithdrawPaymentID | Billing.WithdrawToFunding | ID | Rename |
| FundingType_Sent | Dim_FundingType | Name | JOIN chain via Funding |
| OPSApproved | BackOffice.WithdrawApproval | UserGroupID+Approved+Comment | MAX(CASE) UserGroupID=2 |
| RiskApproved | BackOffice.WithdrawApproval | UserGroupID+Approved+Comment | MAX(CASE) UserGroupID=3 |
| TradingApproved | BackOffice.WithdrawApproval | UserGroupID+Approved+Comment | MAX(CASE) UserGroupID=6 |
| AMLApproved | BackOffice.WithdrawApproval | UserGroupID+Approved+Comment | MAX(CASE) UserGroupID=36 |
| AmdinistratorsApproved | BackOffice.WithdrawApproval | UserGroupID+Approved+Comment | MAX(CASE) UserGroupID=1 |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (CashoutStatusID=3, production)
etoro.Billing.vWithdrawToFunding (view, production)
etoro.BackOffice.WithdrawApproval (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
BI_DB_dbo.External_etoro_Billing_Withdraw
BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding
BI_DB_dbo.External_etoro_BackOffice_WithdrawApproval
  + DWH_dbo.Dim_CashoutMode (Preparation)
  + DWH_dbo.Dim_FundingType (FundingType_Sent)
  + BI_DB_dbo.External_etoro_Dictionary_ExecuteEntryMethod (ExecutionApproval)
  + BI_DB_dbo.External_etoro_Billing_Funding_Datafactory (bridge)
  |-- SP_H_Money_Out_STPAnalysis_OPS_Dashboard @Date ---|
  v
BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard (4.17M rows)
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WithdrawID | Billing.Withdraw | Parent withdrawal request |
| CID | Customer.CustomerStatic | Customer who submitted the withdrawal |
| WithdrawPaymentID | Billing.WithdrawToFunding (ID) | Specific payment execution leg |
| FundingType_Sent | Dim_FundingType (Name) | Payment method name |
| Preparation | Dim_CashoutMode (CashoutModeName) | Preparation mode name |

### 6.2 Referenced By (other objects point to this)

No known consumers in the BI_DB_dbo or DWH_dbo schemas. This table is a terminal dashboard output.

---

## 7. Sample Queries

### 7.1 Daily STP Rate

```sql
SELECT
    CAST(ModificationDate AS DATE) AS ProcessDate,
    COUNT(*) AS TotalWithdrawals,
    SUM(CASE WHEN AutoApproval IN ('Auto Approval','Cleared - Auto Approval') THEN 1 ELSE 0 END) AS AutoApproved,
    SUM(CASE WHEN AutoApproval = 'Manual' THEN 1 ELSE 0 END) AS ManualApproved,
    SUM(CASE WHEN AutoApproval IN ('Auto Approval','Cleared - Auto Approval') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS STPRate
FROM [BI_DB_dbo].[BI_DB_Money_Out_STPAnalysis_OPS_Dashboard]
GROUP BY CAST(ModificationDate AS DATE)
ORDER BY ProcessDate DESC
```

### 7.2 Manual Approval Breakdown by Group

```sql
SELECT
    SUM(OPSApproved) AS OPS_Manual,
    SUM(RiskApproved) AS Risk_Manual,
    SUM(TradingApproved) AS Trading_Manual,
    SUM(AMLApproved) AS AML_Manual,
    SUM(AmdinistratorsApproved) AS Admin_Manual,
    COUNT(*) AS Total
FROM [BI_DB_dbo].[BI_DB_Money_Out_STPAnalysis_OPS_Dashboard]
WHERE AutoApproval = 'Manual'
```

### 7.3 STP Rate by Funding Type

```sql
SELECT
    FundingType_Sent,
    COUNT(*) AS Total,
    SUM(CASE WHEN AutoApproval IN ('Auto Approval','Cleared - Auto Approval') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS STPRate
FROM [BI_DB_dbo].[BI_DB_Money_Out_STPAnalysis_OPS_Dashboard]
GROUP BY FundingType_Sent
ORDER BY Total DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search access denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 5 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard | Type: Table | Production Source: Billing.Withdraw + Billing.WithdrawToFunding + BackOffice.WithdrawApproval*
