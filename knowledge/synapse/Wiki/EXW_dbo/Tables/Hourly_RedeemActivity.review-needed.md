# EXW_dbo.Hourly_RedeemActivity — Review Needed

**Object**: EXW_dbo.Hourly_RedeemActivity  
**Generated**: 2026-04-20  
**Review Priority**: Low (operational KPI table, no downstream SP consumers)

---

## Open Items

### RN-001 — DATEDIFF(DAY, 7, GETDATE()) Window Expression Is Unusual

**Category**: Code clarity / documentation accuracy  
**Severity**: Low

The SP filters: `WHERE tv.TransDate >= Convert(DateTime, DATEDIFF(DAY, 7, GETDATE()))`. The commented-out predecessor was `WHERE tv.TransDate >= GETDATE() - 7`. Both produce a ~7-day lookback, but the replacement expression is non-obvious — `DATEDIFF(DAY, 7, GETDATE())` passes the integer `7` as a date (SQL Server interprets it as 1900-01-08), producing a large day count that Convert(DateTime, ...) maps back to approximately today-7. The data confirms 7-day behavior (MinDate = today-7 in live data), but the code path is fragile.

**Action needed**: Confirm the expression is intentional and stable. Consider adding an inline comment in SP_EXW_Hourly explaining why the original `GETDATE() - 7` was replaced. The wiki documents "effective last 7 days" which is accurate based on observed data.

---

### RN-002 — TransactionTypeId=8 (RedeemAsic) Excluded — Intentional?

**Category**: Business logic validation  
**Severity**: Medium

The SP filters `TransactionTypeId = 0` only. The WalletDB.Wallet.TransactionsView upstream wiki documents TransactionTypeId=8 as "RedeemAsic." These are excluded from Hourly_RedeemActivity. Whether this is intentional (RedeemAsic handled separately) or an oversight is not documented.

**Action needed**: Confirm with EXW team whether RedeemAsic transactions (type 8) should be excluded from redeem volume KPIs. If excluded intentionally, document the business reason. If an oversight, the SP filter should be updated to `TransactionTypeId IN (0, 8)`.

---

### RN-003 — [Date] Reserved Keyword Column Name

**Category**: Usage risk  
**Severity**: Low (documentation)

The first column is named `[Date]`, a SQL Server reserved keyword. While SSDT brackets it correctly in DDL and all SP references use it quoted, ad-hoc queries by analysts may omit the brackets and receive parse errors.

**Action needed**: No schema change needed. The wiki already documents this in both §3.4 Gotchas and the Elements table. Confirm that Tableau connects via a data source that handles the reserved name automatically.

---

### RN-004 — Downstream Tableau Consumers Not Identified

**Category**: Lineage completeness  
**Severity**: Medium (change impact)

No SSDT stored procedures or views reference EXW_dbo.Hourly_RedeemActivity. The specific Tableau workbooks and data sources consuming this table are not identified.

**Action needed**: Identify Tableau workbooks that query EXW_dbo.Hourly_RedeemActivity. Without this, change impact assessment is incomplete when altering the table schema or SP filter logic.

---

### RN-005 — No T1 Columns — All Aggregated

**Category**: Documentation note  
**Severity**: Informational

Unlike Hourly_OmnibusBalances (3 T1 columns from V_BI_WalletBalances) and Hourly_CustomerBalances, Hourly_RedeemActivity has no T1 columns — all 8 are Tier 2 (aggregated or lookup-enriched). This is expected for an aggregation table, but worth noting for anyone auditing tier coverage.

**Action needed**: None. The 0 T1 coverage is structurally correct for this table type.

---

*Review items: 5 | Blocking: 0 | Priority updates: RN-002 (RedeemAsic exclusion validation), RN-004 (Tableau lineage)*
