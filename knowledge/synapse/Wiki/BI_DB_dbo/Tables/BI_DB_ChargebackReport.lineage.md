# Column Lineage: BI_DB_dbo.BI_DB_ChargebackReport

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_ChargebackReport` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Fact_CustomerAction` (chargebacks/refunds) + `DWH_dbo.Fact_BillingWithdraw` (cashout refunds) |
| **ETL SP** | `SP_ChargebackReport` |
| **Secondary Sources** | `Dim_Customer`, `Dim_Regulation` (×2), `Dim_Country`, `Dim_PlayerLevel`, `Dim_PlayerStatusSubReasons`, `Dim_FundingType`, `Dim_ActionType`, `Fact_BillingDeposit`, `V_Liabilities`, `Fact_SnapshotEquity`, `Dim_Range`, `External_etoro_Billing_DepositRollbackTracking` |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
Path 1 — Chargebacks/Refunds (Deposits):
    DWH_dbo.Fact_CustomerAction (ActionTypeID IN 11,12,13)
    + DWH_dbo.Fact_BillingDeposit (deposit details)
    + External_etoro_Billing_DepositRollbackTracking (rollback amounts)
    → #deposits

Path 2 — Refunds (Cashouts for rejected customers):
    DWH_dbo.Fact_BillingWithdraw (completed cashouts)
    + general.etoro_History_BackOfficeCustomer (rejected accounts)
    → #cashouts

Both paths enriched with:
    + Dim_Customer + Dim_Country + Dim_Regulation ×2 + Dim_PlayerLevel
    + Dim_FundingType + Dim_PlayerStatusReasons + Dim_PlayerStatusSubReasons
    + V_Liabilities (balance at @day)
    │
    └─ SP_ChargebackReport @DateFirst
        ├─ #Customers: SUM chargebacks for month from Fact_CustomerAction
        ├─ #LastCredit: Previous month credit from Fact_SnapshotEquity
        ├─ #LostDebt: Lost debt from Fact_CustomerAction (CompensationReasonID=31)
        ├─ #chbkloss: CHB loss calculation (credit < 0 accounts)
        ├─ #rollbackAmount: Rollback amounts from DepositRollbackTracking
        ├─ #deposits: Chargeback/refund deposits with enrichment
        ├─ #refunds: Rejected customer dates from BackOfficeCustomer
        ├─ #cashouts: Cashout refunds for rejected customers (ACH/PWMB only)
        ├─ #union: UNION of #deposits + #cashouts
        ├─ #final: Final assembly with CHB Loss calculations
        ├─ DELETE WHERE Occurred = @DateFirst
        └─ INSERT → BI_DB_dbo.BI_DB_ChargebackReport
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | Via Fact_CustomerAction.RealCID or Fact_BillingWithdraw.CID | Customer Real account ID |
| Club Level | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | `plevel.Name` via `CC.PlayerLevelID` | Renamed to "Club Level" |
| Regulation | DWH_dbo.Dim_Regulation (dr) | Name | ETL-computed | `CASE WHEN Regulation = 'ASIC & GAML' THEN 'ASIC' ELSE Regulation END` | ASIC & GAML collapsed to ASIC |
| Balance | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ETL-computed | `vl.Liabilities + vl.ActualNWA` at @day | Account balance at chargeback date |
| CHB/Refund $ Amount | External_etoro_Billing_DepositRollbackTracking | RollbackAmountInUSD | ETL-computed | `ABS(SUM(RollBackAmount))` | Absolute chargeback/refund amount |
| Country By Reg Form | DWH_dbo.Dim_Country | Name | join-enriched | `country.Name` via `CC.CountryID` | Country of registration |
| Refund / CHB | — | — | ETL-computed | `CASE WHEN PaymentStatus IN ('Chargeback','RefundAsChargeback') THEN 'CHB' ELSE 'Refund'` | Simplified category |
| CHB Reason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | join-enriched | `dpssr.PlayerStatusSubReasonName` via CC | E.g. Attack, Fraud, Lost Funds |
| Method Of Payment | DWH_dbo.Dim_FundingType | Name | join-enriched | `FundingType.Name` via FundingTypeID | E.g. CreditCard, ACH, PWMB |
| Month of CHB in BO | — | — | ETL-computed | `MONTH(Occurred)` | Month component of chargeback date |
| CHB/ Refund $ Ammount * (-1) | External_etoro_Billing_DepositRollbackTracking | RollbackAmountInUSD | ETL-computed | `(-1) * SUM(RollBackAmount)` | Signed rollback amount |
| CHB Loss | — | — | ETL-computed | CASE: balance ≤ 0 AND CHB type → balance; balance > 0 AND CHB → 0; else balance | CHB loss by payment status |
| CHB Loss by Risk USE | — | — | ETL-computed | `CASE WHEN Balance < 0 THEN ROUND(Balance, 0) ELSE 0` | Simplified risk loss |
| Final | DWH_dbo.Fact_SnapshotEquity | Credit | ETL-computed | `IF lastMonthCredit < 0: Credit - LastMonthCredit; ELSE Credit` | Net credit change from prior month |
| RN | — | — | ETL-computed | `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY CID DESC)` | Row sequence per customer |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |
| Occurred | Fact_CustomerAction / Fact_BillingWithdraw | Occurred / ModificationDate | rename | Cast to DATE | Event date |
| PaymentStatus | DWH_dbo.Dim_ActionType | Name | join-enriched | `dat.Name` for deposits; `'Refund'` literal for cashouts | Chargeback / Refund / RefundAsChargeback |
| YearMonth | — | — | ETL-computed | `CONVERT(VARCHAR(6), @Date, 112)` → YYYYMM int | Year-month bucket |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **Join-enriched** | 5 |
| **ETL-computed** | 12 |
| **Total** | 19 |
