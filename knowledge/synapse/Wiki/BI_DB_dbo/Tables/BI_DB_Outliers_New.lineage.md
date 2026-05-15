# Column Lineage — BI_DB_dbo.BI_DB_Outliers_New
<!-- speckit refresh 2026-05-14 | PHASE 10B lineage input for P11 -->

**Writer SP**: `BI_DB_dbo.SP_Outliers_New` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by DateID (daily, per processing date)
**Population Filter**: Customers whose `IsCreditReportValidCB` changed between yesterday and today (CurrStat ≠ PrevStat). These rows are treated as **outliers** vs stable credit-report-valid customers — finance adjusts client-balance aggregates so intra-day transitions do not distort headline BI metrics (“no outlier gaps” when reconciling validity flips vs full customer history).
**Sign Convention**: When `CreditReportValid = '0'` (customer became invalid on the snapshot date), all financial amounts are negated (×−1).
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
| DWH_dbo.Fact_CustomerUnrealized_PnL | CommissionOnOpen | Joined into SP temp `#CommissionOnOpen`; **current** INSERT path sets `[Unrealized Commission Change]` to NULL — legacy rows retain historic non-null values |

---

## Column-Level Lineage

### A. Identity & Classification

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| RealCID | Fact_SnapshotCustomer (#cid) | RealCID | Passthrough snapshot key (`Customer.CustomerStatic`-origin via Dim_Customer) |
| Regulation | Dim_Regulation (reg) | Name | `Dictionary.Regulation` passthrough name |
| CreditReportValid | Fact_SnapshotCustomer (#cid) | IsCreditReportValidCB | Stored as `'0'`/`'1'` varchar |
| Transition | computed (#cid) | CurrStat vs PrevStat | CASE flip labels (`Invalid to Valid`, `Valid To Invalid`) |
| Date | computed | `@ld` | Business processing date |
| DateID | computed | `@ld` | `CONVERT`/YYYYMMDD int |

### B. Lifetime financial aggregates (Fact_CustomerAction + V_Liabilities)

All measures below accumulate `Fact_CustomerAction.DateID ≤ @ld_t2` unless noted; negate when `CreditReportValid='0'`.

| BI_DB Column | ActionTypeID / source | CompensationReasonID / note |
|---------------|----------------------|----------------------------|
| Deposit Amounts | 7 | — |
| Compensation Deposit | 36 | 7 |
| GivenBonus | 9 | — |
| Compensation | 36 | Excludes enumerated reasons documented in wiki §2 historical batch |
| Compensation PI | 36 | 41 |
| Compensation To Affiliates | 36 | IN (8,51,52) |
| Negative Refill Compensation | 36 | 11 *(DDL ordinal 29; SP uses named INSERT)* |
| Cashout Amounts | 8 | LEFT JOIN ⇒ NULL vs 0 semantics |
| Compensation Cashouts | 36 | 33 |
| Cashout Fee | 30 | Uses Commission × −1 in inner aggregate |
| Chargeback | 11,13 | — |
| Refund | 12 | — |
| ClientBalanceCommission | 4,5,6,28,40 | CommissionOnClose × −1 |
| Over The Weekend Fee | 35 | — |
| Chargeback Loss | V_Liabilities | Liabilities<0 ∧ PlayerStatusID ∉ (1,3,5,7) |
| Other Negative | V_Liabilities | Liabilities<0 ∧ PlayerStatusID ∈ (1,3,5,7) |
| Compensation PnL Adjustment | 36 | 22 |
| Compensation DormantFee | 36 | 30 |
| ClientBalance Realized PnL | 4,5,6,28,40 | NetProfit |
| Foreclosure | 36 | 32 |
| Lost Debt | 36 | 31 |
| Unrealized Commission Change | Fact_CustomerUnrealized_PnL (optional legacy) | **Current SP inserts explicit NULL.** Historical non-null tails exist (sparse; see live distribution §3). |
| Cycle Calculation | computed | Algebraic sum of the 20 money columns (Unrealized often NULL ⇒ treated as additive NULL in SQL semantics) |

### C. Metadata

| BI_DB Column | Source | Logic |
|-------------|--------|-------|
| UpdateDate | ETL runtime | `CONVERT(VARCHAR(50), GETDATE(), ...) ` per SP — stored varchar in DDL |

---

## ETL Flow Diagram

```
Fact_SnapshotCustomer (today @ld_t)    ─┐
Fact_SnapshotCustomer (yesterday @ld_t2)─┤ (WHERE CurrStat ≠ PrevStat)
Dim_Regulation                          ─┘
    ↓
  #cid (transition customers + Regulation)
    ↓ LEFT JOIN aggregates
Fact_CustomerAction ──→ #Deposit…#ClientBalanceRealizedPnL
V_Liabilities       ──→ #Liabilities
Fact_CustomerUnrealized_PnL ──→ #CommissionOnOpen (legacy / unused insert path)
    ↓
  #out (sign-flip when CreditReportValid='0')
DELETE FROM BI_DB_Outliers_New WHERE DateID=@ld_t
INSERT INTO BI_DB_Outliers_New ← #out
```

---

## Notes

- SR-281275 removed obsolete DLT transition logic (comment-only remnants may remain inside SP SSDT snapshot).
- Confluence excerpt (BIA blog *Client Balance and Gaps masterclass*, Oct 2023) explains `IsCreditReportValidCB` filters out transition-day distortions—“no outlier gaps” phrasing aligns with reconciliation purpose.
