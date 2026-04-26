# BI_DB_CopycatsOfCopyfunds — Review Needed

**Generated**: 2026-04-23  
**Reviewer**: PI Analytics / Data Engineering  

---

## Issues Requiring Human Review

### 1. `% Copying` values far exceed 100% — data quality concern
**Severity**: Medium  
The observed average `% Copying` for Not PI customers is 753,100% (vs expected 80–100%). The SP correctly filters `vl.RealizedEquity > 0` before computing `tm.RealizedEquity / vl.RealizedEquity * 100`, but extreme outliers result from timing differences between Dim_Mirror and V_Liabilities refreshes. When a customer closes most positions intraday (lowering V_Liabilities equity to near zero) but Dim_Mirror still reflects a large open copy equity, the ratio explodes.  
**Recommended action**: Add a cap or sanity filter in the SP (`AND tm.RealizedEquity / vl.RealizedEquity <= 5` or equivalent) to prevent extreme outliers from polluting aggregated reporting.

### 2. CID not unique — table semantics unclear for downstream consumers
**Severity**: Medium  
The table has 234,571 rows but only 74,476 distinct CIDs (~3.1 rows per CID average). The table name "CopycatsOfCopyfunds" implies one row per customer, but the SP generates one row per copy relationship. This design ambiguity can cause double-counting when downstream queries treat CID as a unique key (e.g., `COUNT(DISTINCT CID)` looks reasonable, but `SUM(AccountEquity)` would triple-count equity for multi-copy customers).  
**Recommended action**: Confirm whether the intended grain is one row per customer or one row per copy relationship. If one-per-customer, add deduplication logic in the SP.

### 3. `@Date` parameter incremented by 1 day in SP — unusual design
**Severity**: Low (by-design risk)  
The SP immediately runs `set @Date = DateAdd(Day, 1, @Date)` at the start of the procedure. This means the effective query date is `@Date + 1`. If the orchestration changes to pass today's date (rather than yesterday's), the SP would query tomorrow's data from V_Liabilities (returning no rows). Confirm with the orchestration team that they always pass `GETDATE()-1` to this SP.

### 4. `# of Copiers` and `AUM` are 0 for 99.97% of rows (Not PI customers)
**Severity**: Low (by-design limitation)  
The `#CopyAUM_Data` temp table aggregates copier counts for CopyFunds whose CID appears in `#children`. The join `c.CID = g.ParentCID` only produces matches when the copier's CID is itself a CopyFund manager in `etoroGeneral_History_GuruCopiers` (a ParentCID). For standard retail copiers (Not PI), this never matches, so `# of Copiers = 0` and `AUM = 0` for 99.97% of rows. If the intent was to show the CopyFund's own copier count and AUM (the CopyFund they're investing in), the join logic may be incorrect — it should join on the ParentCID from Dim_Mirror, not on c.CID.  
**Recommended action**: Verify with the Data Engineering team whether `# of Copiers` and `AUM` are intentionally 0 for Not PI customers, or whether the join should be rewritten to use the CopyFund's ParentCID from `#children`.
