# Column Lineage — BI_DB_dbo.BI_DB_Outliers_New
<!-- batch 61 | 2026-04-23 -->

**Writer SP**: `BI_DB_dbo.SP_Outliers_New` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by DateID (daily, per processing date)
**Population Filter**: Customers whose `IsCreditReportValidCB` changed between yesterday and today (CurrStat ≠ PrevStat). All regulations included.
**Sign Convention**: When `CreditReportValid = 0` (customer became invalid), all financial amounts are negated (×−1).
**Financial Amounts**: Cumulative lifetime totals up to the day before the transition (DateID ≤ @ld_t2), not that day's amount.

---

## Source Tables

| Source | Role | Join Path |
|--------|------|-----------|
| DWH_dbo.Fact_SnapshotCustomer (today) | Current-day credit valid status + RegulationID | DateKey = @ld_t via Dim_Range/Dim_Date |
| DWH_dbo.Fact_SnapshotCustomer (yesterday) | Previous-day credit valid status + PlayerStatusID | DateKey = @ld_t2 via Dim_Range/Dim_Date |
| DWH_dbo.Dim_Regulation | Regulation name | reg.ID = a.RegulationID |
| DWH_dbo.Dim_Range | Date range bridge | a.DateRangeID = dr.DateRangeID |
| DWH_dbo.Dim_Date | Date key lookup | dr.FromDateID ≤ dd.DateKey ≤ dr.ToDateID |
| DWH_dbo.Fact_CustomerAction | All financial action amounts (deposits, cashouts, compensations, etc.) | RealCID join, DateID ≤ @ld_t2, ActionTypeID filter |
| DWH_dbo.V_Liabilities | Negative balance detection (ChargebackLoss, OtherNegative) | CID = RealCID, DateID = @ld_t2 |
| DWH_dbo.Fact_CustomerUnrealized_PnL | CommissionOnOpen (fetched but not used in final INSERT) | CID join, DateModified = @ld_t2 |

---

## Column-Level Lineage

### A. Identity & Classification (6 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| RealCID | Fact_SnapshotCustomer (#cid) | RealCID | Direct. Platform-internal customer primary key |
| Regulation | Dim_Regulation (reg) | Name | Direct. Short code for the regulation (BVI, CySEC, FCA, ASIC, etc.) |
| CreditReportValid | Fact_SnapshotCustomer (#cid) | IsCreditReportValidCB | Direct assignment of current-day value (bit→varchar stored as '0'/'1') |
| Transition | computed (#cid) | CurrStat vs PrevStat | CASE: CurrStat=1 AND PrevStat=0 → 'Invalid to Valid'; CurrStat=0 AND PrevStat=1 → 'Valid To Invalid'; else → 'NA' |
| [Date] | computed | @ld parameter | Direct assignment of SP input date parameter |
| [DateID] | computed | @ld | CONVERT(VARCHAR(8), @ld, 112) — YYYYMMDD integer |

### B. Deposit & Income Columns (7 columns — Fact_CustomerAction derived, negated when invalid)

| BI_DB Column | Action Source | ActionTypeID / Filter | Transform |
|-------------|--------------|----------------------|-----------|
| [Deposit Amounts] | Fact_CustomerAction (#Deposit) | ActionTypeID = 7, DateID ≤ @ld_t2 | CASE CreditReportValid=0 THEN -1×SUM(Amount) ELSE SUM(Amount). NULL when customer has no deposit history |
| [Compensation Deposit] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 7 | Sign-flipped when CreditReportValid=0 |
| GivenBonus | Fact_CustomerAction (#Bonus) | ActionTypeID = 9, DateID ≤ @ld_t2 | Sign-flipped when CreditReportValid=0 |
| [Compensation] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID NOT IN (7,8,11,17,18,22,30,31,32,33,34,36,37,38,40,41,51,52) | General compensation; sign-flipped when invalid |
| [Negative Refill Compensation] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 11 | Sign-flipped when CreditReportValid=0 |
| [Compensation PI] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 41 | Sign-flipped when CreditReportValid=0 |
| [Compensation To Affiliates] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID IN (8, 51, 52) | Sign-flipped when CreditReportValid=0 |

### C. Outflow Columns (5 columns — Fact_CustomerAction derived, negated when invalid)

| BI_DB Column | Action Source | ActionTypeID / Filter | Transform |
|-------------|--------------|----------------------|-----------|
| [Cashout Amounts] | Fact_CustomerAction (#Cashouts) | ActionTypeID = 8, DateID ≤ @ld_t2 | ISNULL(SUM(Amount),0). Sign-flipped when CreditReportValid=0 |
| [Compensation Cashouts] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 33 | Sign-flipped when CreditReportValid=0 |
| [Cashout Fee] | Fact_CustomerAction (#CashoutFee) | ActionTypeID = 30, Commission field, DateID ≤ @ld_t2 | ISNULL(SUM((-1)×Commission), 0) — already negated in SP; sign-flipped again when invalid |
| [Chargeback] | Fact_CustomerAction (#Chargeback) | ActionTypeID IN (11, 13), DateID ≤ @ld_t2 | ISNULL(SUM(Amount),0). Sign-flipped when CreditReportValid=0 |
| [Refund] | Fact_CustomerAction (#Refund) | ActionTypeID = 12, DateID ≤ @ld_t2 | ISNULL(SUM(Amount),0). Sign-flipped when CreditReportValid=0 |

### D. Trading & Position Columns (8 columns)

| BI_DB Column | Source | Filter / Logic | Transform |
|-------------|--------|----------------|-----------|
| [ClientBalanceCommission] | Fact_CustomerAction (#ClientBalanceCommission) | ActionTypeID IN (4,5,6,28,40), CommissionOnClose field | ISNULL(SUM(-1×CommissionOnClose), 0). Sign-flipped when invalid |
| [Over The Weekend Fee] | Fact_CustomerAction (#OverTheWeekendFee) | ActionTypeID = 35, DateID ≤ @ld_t2 | ISNULL(SUM(Amount),0). Sign-flipped when CreditReportValid=0 |
| [Chargeback Loss] | DWH_dbo.V_Liabilities (#Liabilities) | DateID = @ld_t2, Liabilities < 0 AND PlayerStatusID NOT IN (1,3,5,7) | CASE-extracted negative balance for non-standard statuses; sign-flipped when invalid |
| [Other Negative] | DWH_dbo.V_Liabilities (#Liabilities) | DateID = @ld_t2, Liabilities < 0 AND PlayerStatusID IN (1,3,5,7) | CASE-extracted negative balance for standard statuses; sign-flipped when invalid |
| [Compensation PnL Adjustment] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 22 | Sign-flipped when CreditReportValid=0 |
| [Compensation DormantFee] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 30 | Sign-flipped when CreditReportValid=0 |
| [ClientBalance Realized PnL] | Fact_CustomerAction (#ClientBalanceRealizedPnL) | ActionTypeID IN (4,5,6,28,40), NetProfit field | ISNULL(SUM(NetProfit), 0). Sign-flipped when CreditReportValid=0 |
| [Foreclosure] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 32 | Sign-flipped when CreditReportValid=0 |
| [Lost Debt] | Fact_CustomerAction (#Compensation) | ActionTypeID = 36, CompensationReasonID = 31 | Sign-flipped when CreditReportValid=0 |

### E. Summary & Metadata (3 columns)

| BI_DB Column | Source | Logic |
|-------------|--------|-------|
| [Cycle Calculation] | computed from #out | SUM of all 20 financial components above. Sign-flipped when CreditReportValid=0. Represents net balance reconciliation for the transition customer |
| [Unrealized Commission Change] | hardcoded NULL | SP inserts NULL for this column. Fact_CustomerUnrealized_PnL is queried (CommissionOnOpen) but the result is NOT used in the final INSERT. Column is effectively always NULL. |
| UpdateDate | computed | GETDATE() at SP execution time. Stored as varchar(50) — note DDL type is varchar, not datetime |

---

## ETL Flow Diagram

```
Fact_SnapshotCustomer (today @ld_t)    ─┐
Fact_SnapshotCustomer (yesterday @ld_t2)─┤ (WHERE CurrStat ≠ PrevStat)
Dim_Regulation                          ─┘
    ↓
  #cid (transition customers + Regulation)
    ↓ (LEFT JOINs to all temp tables below)
Fact_CustomerAction ──→ #Deposit, #Bonus, #Compensation, #Cashouts,
                        #CashoutFee, #Chargeback, #Refund,
                        #ClientBalanceCommission, #OverTheWeekendFee,
                        #ClientBalanceRealizedPnL
V_Liabilities       ──→ #Liabilities (ChargebackLoss + OtherNegative)
Fact_CustomerUnrealized_PnL ──→ #CommissionOnOpen (queried, NOT used in INSERT)
    ↓
  #out (all components joined; sign-flip applied when CreditReportValid=0)
    ↓
DELETE FROM BI_DB_Outliers_New WHERE DateID = @ld_t
INSERT INTO BI_DB_Outliers_New ← #out
```

---

## Notes

- **DLT outliers removed**: SR-264692 (2024-07-30) added etoro/DLT transition tracking; SR-281275 (2024-11-18) removed it. Commented-out DLT columns remain in SP code.
- **NULL vs 0 semantics**: Financial columns are NULL when customer has no history for that action type (LEFT JOIN miss). 0 means history exists but nets to zero. This is intentional.
- **Cumulative amounts**: All financial columns aggregate DateID ≤ @ld_t2 (day before transition). Not daily delta — full history.
- **`[Unrealized Commission Change]` dead column**: DDL column exists, always NULL in production. The CommissionOnOpen computation runs but is discarded.
