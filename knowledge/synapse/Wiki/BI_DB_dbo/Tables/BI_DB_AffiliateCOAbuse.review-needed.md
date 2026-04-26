# Review Needed — BI_DB_dbo.BI_DB_AffiliateCOAbuse

**Generated**: 2026-04-23
**Batch**: 55
**Quality Score**: 9.2 / 10

---

## Items for Human Review

### 1. "COAbuse" Business Definition

The table name says "COAbuse" but the SP logic captures ALL customers who opened their first position in the prior month under an affiliate that has an AffiliateWiz CPA record — regardless of whether any abuse was actually detected. **Verify with Affiliate team**: is this table a raw data feed used upstream in an abuse-detection workflow (with a separate scoring/filtering step), or does appearing in this table itself indicate a confirmed or suspected abuse case?

### 2. BI_DB_FirstTimeRev10 Vestigial Join

The SP joins `BI_DB_FirstTimeRev10` (as `Rev10`) in the `#ThisMonthOpenPos` step but uses no columns from it in the final INSERT. **Verify with data engineering**: is this join intentionally retained for a potential future column addition, or is it safe to remove? If the table is large, this join may impact SP performance unnecessarily.

### 3. AffWizID Offset Permanence

The `AffWizID = OriginalCID + 17` offset is hardcoded as a magic number with no comment explaining its origin. Live data confirms it works (offset verified at +17), but if the AffiliateWiz system ever changes its CID namespace, this join will silently break. **Verify**: is the +17 offset documented anywhere in the fiktivo/AffiliateWiz system? Is it guaranteed stable?

### 4. RealizedEquity Timing and Analytical Intent

`RealizedEquity` is snapshotted at EOMONTH of the prior month — the end-of-month equity position from V_Liabilities. For customers who opened their first position in late January (e.g., Jan 28), the equity is captured just 3 days later (Jan 31). **Verify with Affiliate team**: is this short window (days to weeks) intentional for abuse detection (detecting rapid equity drop after FPO), or should it be a later snapshot (e.g., 30 or 90 days after FPO)?

### 5. ReportDateID Data Type Inconsistency

`ReportDateID` is `varchar(8)` in this table while most other date partition columns in BI_DB_dbo use `int`. This prevents direct int comparison and JOIN efficiency. **Verify**: was this intentional (perhaps for string sorting), or an oversight? Should it be an `int` to match the rest of the schema?
