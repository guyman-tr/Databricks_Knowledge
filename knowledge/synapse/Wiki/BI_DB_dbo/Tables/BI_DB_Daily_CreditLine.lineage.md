# Column Lineage -- BI_DB_dbo.BI_DB_Daily_CreditLine

**Writer SP**: `BI_DB_dbo.SP_Daily_CreditLine` (Priority 99 -- FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by DateID (with MERGE accumulation)
**Architecture**: #snap (prev day) MERGE #bonus (today) -> #lastexceeded -> #insert -> final INSERT

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| BI_DB_dbo.BI_DB_Daily_CreditLine | (self) | Previous day snapshot (base for accumulation) |
| DWH_dbo.Fact_CustomerAction | (none) | New credit line actions (ActionTypeID=9, BonusTypeID=71) |
| DWH_dbo.V_Liabilities | vl / v | Liabilities for CLRatio |
| BI_DB_dbo.BI_DB_CreditLine_Amounts | t | Fee tier lookup |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- multi-step MERGE + temp table pipeline.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| RealCID | #insert (a) | RealCID | From #snap (previous day) or #bonus (new action). Originally Fact_CustomerAction.RealCID |
| Date | #insert (a) | Date | @ds parameter |
| DateID | #insert (a) | DateID | CAST(CONVERT(VARCHAR(8), @ds, 112) AS INT) |
| TotalCLAmount | #snap (a) | TotalCLAmount | Carried from previous day. MERGE adds today's bonus amount |
| MonthlyTableFeeCost | BI_DB_CreditLine_Amounts (t) | Cost | LEFT JOIN on TotalCLAmount = CreditLine tier |
| DailyFee | computed | MonthlyTableFeeCost | t.Cost / DAY(EOMONTH(@ds)). Pro-rated daily |
| Liabilities | V_Liabilities (v) | Liabilities | LEFT JOIN on RealCID + DateID |
| CLRatio | computed | TotalCLAmount, Liabilities | TotalCLAmount / CASE WHEN Liabilities=0 THEN 1 ELSE Liabilities END |
| IsExceeded | computed | CLRatio | CASE WHEN CLRatio > 0.5 THEN 1 ELSE 0 END |
| ExceedingDaysCount | #lastexceeded (le) | ExceedingDaysCount | Previous day's count + 1 if still exceeded, else 0 |
| DateReceive | #bonus (b) | DateReceive | CASE WHEN SUM(Amount) > 0 THEN @ds. Only on action day |
| DateDeduct | #bonus (b) | DateDeduct | CASE WHEN SUM(Amount) < 0 THEN @ds. Only on action day |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
