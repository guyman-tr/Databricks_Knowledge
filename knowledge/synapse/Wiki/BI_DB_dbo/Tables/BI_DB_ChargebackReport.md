# BI_DB_dbo.BI_DB_ChargebackReport

| Property | Value |
|----------|-------|
| **Object Type** | TABLE |
| **Schema** | BI_DB_dbo |
| **Row Count** | ~25,170 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Source System** | `Fact_CustomerAction` + `Fact_BillingWithdraw` + `DepositRollbackTracking` (production) |
| **Writer SP** | `SP_ChargebackReport` |
| **ETL Pattern** | DELETE-INSERT per @DateFirst (daily incremental, keeps history) |
| **Refresh** | Daily (SB_Daily, Priority 20) |

## 1. Business Meaning

`BI_DB_ChargebackReport` is a finance/risk table that tracks chargeback and refund events on the eToro platform. It combines two distinct event streams into a unified report:

1. **Chargebacks/Refunds (deposit path)**: When a payment processor reverses a customer deposit (ActionTypeID 11=Chargeback, 12=Refund, 13=RefundAsChargeback), the rollback amount and associated loss are recorded.
2. **Cashout refunds (withdrawal path)**: When a rejected customer (AcceptanceStatusID=2 in BackOffice) has a completed cashout via ACH or PWMB, this is treated as a refund event.

The table calculates financial exposure: CHB Loss (actual chargeback loss based on account balance at event time), CHB Loss by Risk USE (simplified risk metric), and Final (net credit change from prior month). Each row represents a chargeback/refund event at the customer × date × payment-status level.

**Key business use cases:**
- Monthly chargeback reporting by regulation, country, and funding type
- Risk exposure analysis: identifying customers with negative balances after chargebacks
- Fraud pattern detection via CHB Reason (Attack, Fraud, Lost Funds, etc.)
- Payment method risk profiling

## 2. Business Logic

### 2.1 ETL Pattern — Incremental with History

Unlike most BI_DB tables, this SP uses `DELETE WHERE Occurred = @DateFirst` + `INSERT` — not TRUNCATE. Each daily run adds/replaces one day's chargeback events, preserving historical data. History starts from 2022-06-08.

### 2.2 Dual Source Paths

**Path 1 — Deposit chargebacks** (`#deposits`):
- Source: `Fact_CustomerAction` (ActionTypeID IN 11,12,13, Amount < 0)
- Rollback amounts from `External_etoro_Billing_DepositRollbackTracking` (PaymentStatusID IN 11,12,26, IsCanceled=0)
- Filters: `IsValidCustomer=1`, `PlayerLevelID != 4`, `LabelID != 26`

**Path 2 — Cashout refunds** (`#cashouts`):
- Source: `Fact_BillingWithdraw` (CashoutStatusID=3 for both funding and withdraw)
- Only for rejected customers (`AcceptanceStatusID=2` in BackOfficeCustomer history)
- Only ACH (FundingTypeID=29) and PWMB (FundingTypeID=32)
- PaymentStatus hardcoded to 'Refund'

### 2.3 CHB Loss Calculation

```sql
-- CHB Loss: actual loss to company
CASE WHEN Balance <= 0 AND PaymentStatus IN ('Chargeback','RefundAsChargeback') THEN Balance
     WHEN Balance > 0 AND PaymentStatus IN ('Chargeback','RefundAsChargeback') THEN 0
     ELSE Balance END

-- CHB Loss by Risk USE: simplified risk metric
CASE WHEN Balance < 0 THEN ROUND(Balance, 0) ELSE 0 END

-- Final: net credit change
CASE WHEN LastMonthCredit < 0 THEN Credit - LastMonthCredit
     WHEN LastMonthCredit >= 0 THEN Credit
     ELSE 0 END
```

### 2.4 Regulation Remapping

`ASIC & GAML` is collapsed to `ASIC` in the output.

## 3. Query Advisory

### 3.1 Distribution & Index Strategy

- **ROUND_ROBIN** + **HEAP** — no optimization. Acceptable for a 25K-row table.
- No indexes needed at this scale.

### 3.2 Recommended Patterns

| Use Case | Pattern |
|----------|---------|
| Monthly summary | `WHERE YearMonth = 202603` |
| Chargebacks only | `WHERE [Refund / CHB] = 'CHB'` |
| Refunds only | `WHERE [Refund / CHB] = 'Refund'` |
| Negative balance exposure | `WHERE [CHB Loss by Risk USE] < 0` |
| By payment method | `GROUP BY [Method Of Payment]` |

### 3.3 Performance Notes

- **25K rows** — trivially small. Full table scan is fast.
- Column names contain spaces and special characters — always use brackets: `[CHB/Refund $ Amount]`.
- `RN` column = ROW_NUMBER per CID — use `WHERE RN = 1` for latest event per customer.

### 3.4 Data Freshness

| Metric | Value |
|--------|-------|
| First data | 2022-06-08 |
| Last loaded | 2026-03-11 |
| Refresh frequency | Daily (incremental) |
| Latency | Previous day's chargebacks/refunds |

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer Real account ID. From Dim_Customer.RealCID (deposits) or Fact_BillingWithdraw.CID (cashouts). (Tier 1 — Dim_Customer) |
| 2 | Club Level | varchar(100) | YES | Customer tier at event time. From Dim_PlayerLevel.Name via CC.PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Diamond. Excludes PlayerLevelID=4. (Tier 1 — Dictionary.PlayerLevel, join-enriched) |
| 3 | Regulation | varchar(100) | YES | Customer regulation at event time. From Dim_Regulation.Name, with "ASIC & GAML" remapped to "ASIC". (Tier 1 — Dictionary.Regulation, join-enriched, ETL-remapped) |
| 4 | Balance | money | YES | Account balance at chargeback date. `V_Liabilities.Liabilities + ActualNWA` at @day. Negative = customer owes; positive = customer has funds. (Tier 2 — SP_ChargebackReport, ETL-computed from V_Liabilities) |
| 5 | CHB/Refund $ Amount | money | YES | Absolute chargeback/refund amount in USD. `ABS(SUM(RollbackAmountInUSD))` from DepositRollbackTracking. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 6 | Country By Reg Form | varchar(100) | YES | Country of residence from registration form. From Dim_Country.Name via CC.CountryID. (Tier 1 — Dictionary.Country, join-enriched) |
| 7 | Refund / CHB | varchar(100) | YES | Simplified event category. 2-value enum: "CHB" (Chargeback/RefundAsChargeback) or "Refund" (all others). (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 8 | CHB Reason | varchar(100) | YES | Chargeback/refund reason. From Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. Examples: Attack, Fraud, Lost Funds, Fraud CHBK. (Tier 2 — SP_ChargebackReport, join-enriched) |
| 9 | Method Of Payment | varchar(100) | YES | Payment method used for the original deposit or withdrawal. From Dim_FundingType.Name. Examples: CreditCard, ACH, PWMB, PayPal, Wire. (Tier 2 — SP_ChargebackReport, join-enriched from Dim_FundingType) |
| 10 | Month of CHB in BO | int | YES | Month number (1-12) when the chargeback/refund occurred. `MONTH(Occurred)`. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 11 | CHB/ Refund $ Ammount * (-1) | money | YES | Signed rollback amount. `(-1) * SUM(RollbackAmount)`. Column name contains typo ("Ammount"). (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 12 | CHB Loss | money | YES | Chargeback loss to the company. For CHB events: balance if balance ≤ 0 (company lost money), 0 if balance > 0 (customer had funds). For refunds: balance as-is. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 13 | CHB Loss by Risk USE | money | YES | Simplified risk loss metric. `ROUND(Balance, 0)` if balance < 0; 0 otherwise. Ignores payment status distinction. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 14 | Final | money | YES | Net credit change from prior month. If last month's credit was negative: current credit minus last month's credit (measures recovery). If positive: current credit. Based on Fact_SnapshotEquity. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 15 | RN | int | YES | Row number per customer within the dataset. `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY CID DESC)`. Use `WHERE RN=1` for latest event per customer. (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 16 | UpdateDate | date | YES | ETL execution date. `GETDATE()` cast to date. Different per daily load (incremental pattern). (Tier 2 — SP_ChargebackReport, ETL-computed) |
| 17 | Occurred | date | YES | Date when the chargeback/refund event occurred. From Fact_CustomerAction.Occurred (deposits) or Fact_BillingWithdraw.ModificationDate (cashouts). Cast to DATE. (Tier 2 — SP_ChargebackReport) |
| 18 | PaymentStatus | varchar(max) | YES | Detailed payment status. From Dim_ActionType.Name for deposits (Chargeback, Refund, RefundAsChargeback); hardcoded 'Refund' for cashout path. (Tier 2 — SP_ChargebackReport, join-enriched) |
| 19 | YearMonth | int | YES | Year-month identifier in YYYYMM format. `CONVERT(VARCHAR(6), @Date, 112)`. Used for monthly grouping. (Tier 2 — SP_ChargebackReport, ETL-computed) |

## 5. Lineage

| Source | Relationship | Objects |
|--------|-------------|---------|
| **DWH_dbo.Fact_CustomerAction** | Primary — chargeback/refund events | `RealCID`, `Amount`, `Occurred`, `ActionTypeID`, `DepositID`, `CompensationReasonID` |
| **DWH_dbo.Fact_BillingWithdraw** | Primary — cashout refunds for rejected customers | `CID`, `WithdrawID`, `ModificationDate`, `Amount_WithdrawToFunding` |
| **External_etoro_Billing_DepositRollbackTracking** | Rollback amounts | `DepositID`, `RollbackAmountInUSD`, `PaymentStatusID` |
| **DWH_dbo.Fact_BillingDeposit** | Deposit details + funding type | `DepositID`, `FundingTypeID` |
| **DWH_dbo.V_Liabilities** | Account balance at event date | `Liabilities`, `ActualNWA` |
| **DWH_dbo.Fact_SnapshotEquity** | Prior month credit for loss calculation | `Credit`, `DateRangeID` |
| **DWH_dbo.Dim_Customer** | Customer demographics | `RealCID`, `CountryID`, `RegulationID`, `PlayerLevelID`, `PlayerStatusReasonID` |
| **general.etoro_History_BackOfficeCustomer** | Rejected account dates | `CID`, `ValidFrom`, `AcceptanceStatusID` |

Full column-level lineage: [BI_DB_ChargebackReport.lineage.md](BI_DB_ChargebackReport.lineage.md)

## 6. Relationships

| Related Object | Join Condition | Purpose |
|---------------|----------------|---------|
| DWH_dbo.Fact_CustomerAction | `ON RealCID = hc.RealCID` | Source: chargeback events |
| DWH_dbo.Fact_BillingWithdraw | `ON CID = Withdraw.CID` | Source: cashout refunds |
| DWH_dbo.Dim_Customer | `ON RealCID = CC.RealCID` | Customer enrichment |
| DWH_dbo.V_Liabilities | `ON CID = vl.CID AND DateID = @day` | Balance at event date |
| DWH_dbo.Fact_SnapshotEquity | `ON CID = hc.CID` (with Dim_Range) | Credit history for loss calc |

## 7. Sample Queries

```sql
-- Monthly chargeback summary by type and regulation
SELECT  YearMonth,
        [Refund / CHB],
        Regulation,
        COUNT(*) AS EventCount,
        SUM([CHB/Refund $ Amount]) AS TotalAmount,
        SUM([CHB Loss by Risk USE]) AS TotalRiskLoss
FROM    BI_DB_dbo.BI_DB_ChargebackReport
GROUP BY YearMonth, [Refund / CHB], Regulation
ORDER BY YearMonth DESC;

-- Top chargeback reasons by country
SELECT  [Country By Reg Form],
        [CHB Reason],
        COUNT(*) AS Events,
        SUM([CHB/Refund $ Amount]) AS TotalUSD
FROM    BI_DB_dbo.BI_DB_ChargebackReport
WHERE   [Refund / CHB] = 'CHB'
GROUP BY [Country By Reg Form], [CHB Reason]
ORDER BY TotalUSD DESC;
```

## 8. Atlassian Knowledge Sources

_No specific Confluence/Jira pages found for the chargeback report table. The SP header credits Pavlina Masoura with creation date 2021-06-08 and multiple iterations through 2023-09._

---

| Metric | Value |
|--------|-------|
| **Quality Score** | 8.5 / 10 |
| **Tier 1 Elements** | 4 / 19 (21%) |
| **Tier 2 Elements** | 15 / 19 (79%) |
| **Tier 4 Elements** | 0 |
| **Confidence** | HIGH — SP code fully analyzed, dual source paths documented |
