# BI_DB_CID_BalanceDays — Items Requiring Review

## RN-1 — NULL Ambiguity: Milestone Not Reached vs. Zero Activity

**Issue**: All metric columns (Revenue{N}days, Deposit{N}days, Equity{N}days) are NULL until the corresponding milestone cohort fires. However, a customer who genuinely generated $0 revenue or made no deposits in the period will also produce a 0 after the UPDATE runs — not NULL. There is no flag to distinguish "milestone not yet run" from "milestone ran and was zero."

**Impact**: Queries filtering for `IS NOT NULL` to find "matured" customers will include zero-activity customers. Queries computing averages over non-NULL values will be accurate, but time-to-maturity analyses need to account for the cohort fire schedule (only fires for customers whose DATEDIFF falls in the allowed set on a given run date).

**Action**: Confirm whether downstream consumers (BI_DB_First5Actions, BI_DB_Revenue14DaysToBigQuery) handle NULL vs. 0 distinction correctly.

---

## RN-2 — Equity365days Zero-Default Inconsistency

**Issue**: `Equity365days` is the only column with `ISNULL(Equity365days, 0)` applied at the D+364 UPDATE pass, meaning it defaults to 0 if V_Liabilities returns no row for the customer. All other Equity{N}days columns remain NULL if V_Liabilities has no snapshot for that day.

**Impact**: `Equity365days` = 0 could mean genuine zero equity or a missing snapshot, while `Equity1day` = NULL at D+364 means the 1-day milestone did fire but V_Liabilities had no data. This asymmetry can skew longitudinal equity analyses that compare multiple milestones.

**Action**: Confirm whether the ISNULL(0) was intentional (e.g., to avoid NULL in a downstream BigQuery sink) or an artifact of the D+364 code branch. Consider applying consistently or documenting explicitly.

---

## RN-3 — V_Liabilities Not Documented

**Issue**: The equity columns source from `DWH_dbo.V_Liabilities` (specifically `Liabilities + ActualNWA`). This view is not yet documented in the wiki, so the exact definition of equity components (TotalRealStocks, TotalRealCrypto, TotalCash, InProcessCashouts, CFD positions, etc.) cannot be verified from wiki alone.

**Impact**: It is unknown whether V_Liabilities includes unrealized CFD P&L, margin requirements, or crypto open positions for the equity snapshot. The column description notes "account equity = all asset classes" but this is unverified.

**Action**: Document DWH_dbo.V_Liabilities. Until then, treat Equity{N}days as "total account equity per V_Liabilities definition as of FTD+N-1 day."

---

## RN-4 — BI_DB_DailyCommisionReport Not Documented

**Issue**: All Revenue{N}days columns source from `BI_DB_dbo.BI_DB_DailyCommisionReport` (FullCommissions + RollOverFee), but this table is not yet documented in the wiki. The IsMirror and InstrumentTypeID filter logic is present in the SP, but the semantic meaning of FullCommissions vs. gross spread vs. net revenue is not verified from an upstream wiki definition.

**Impact**: Revenue{N}days interpretation (net revenue? gross spread? commission-only?) depends on BI_DB_DailyCommisionReport semantics, which are currently opaque.

**Action**: Document BI_DB_DailyCommisionReport. Verify whether FullCommissions represents net platform revenue or gross trading commission (pre-IB split).

---

## RN-5 — CopyTrading Revenue Inclusion (IsMirror=1)

**Issue**: The revenue formula includes ALL trades where `IsMirror=1` (CopyTrading) regardless of InstrumentTypeID, but restricts direct trades to InstrumentTypeID IN (1,2,4,5,6,10). This means a CopyTraded CFD position generates revenue in these columns, whereas a directly-placed CFD trade does not.

**Impact**: Revenue{N}days for heavy CopyTrading users may be higher than for equivalent direct traders. Cross-customer comparisons of revenue should account for trading style.

**Action**: Confirm this asymmetry is intentional product logic (CopyTrading revenue is always counted; direct CFD revenue is excluded). Document in any report using these columns for cohort comparisons.

---

## RN-6 — Row Count Not Obtained

**Issue**: DMV query (`sys.dm_pdw_nodes_db_partition_stats`) returned permission error. Total table size unknown. Based on the depositor population (IsDepositor=1, IsValidCustomer=1 in Dim_Customer), estimated at several million rows.

**Action**: Request row count from DBA or estimate via `SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_CID_BalanceDays`.
