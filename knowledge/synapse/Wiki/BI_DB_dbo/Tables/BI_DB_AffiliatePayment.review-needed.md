# Review Needed — BI_DB_dbo.BI_DB_AffiliatePayment

**Generated**: 2026-04-23
**Batch**: 55
**Quality Score**: 8.5 / 10

---

## Items for Human Review

### 1. Are the 16 NULL Funnel Columns Permanently Disabled?

Columns 30–47 (Registrations through ActiveUserOutOfFTDs3M) are hardcoded NULL since the `#InfoData` section was commented out. The commented code references `BI_DB_CIDFirstDates`, `Dim_Customer`, `BI_DB_FirstTimeRev10`, and `BI_DB_CID_MonthlyPanel_FullData`. Live data: 67.6% NULL (102,232 / 151,226). **Verify with Affiliate team**: was the decision to disable permanent (columns should be dropped from the DDL), or is there a plan to restore the funnel metrics with updated source tables?

### 2. CurrentPayment Semantics — Cumulative vs Monthly

The SP aggregates commissions from `@CalcFrom = 2013-01-01` where `Paid=0`. `CurrentPayment` is the total unpaid commission balance, not the current month's earnings. **Verify with Affiliate Finance**: is `CurrentPayment` interpreted correctly by stakeholders and downstream dashboards? If some consumers expect "this month's commission," the column is semantically misunderstood and should be renamed or a separate monthly column added.

### 3. Bonuses Column Always 0 — Intended Permanent?

The Bonuses UNION branch (`tblaff_Bonuses_Commissions`) is commented out alongside `#InfoData`. `Bonuses` has always been 0 for the entire table history based on the commented code. **Verify**: is the Bonuses commission type permanently discontinued in AffiliateWiz, or is this another deferred restoration item?

### 4. Historic Funnel Data Cutoff Date

The documentation states funnel columns were disabled "since ~2021" but the exact date is unknown. Live data shows 48,994 rows with non-NULL Registrations. **Verify**: what is the exact date when `#InfoData` was commented out? This matters for analysts trying to use historic funnel data — rows before that date have values; rows after do not.

### 5. PaymentUrl Internal Tool Validity

`PaymentUrl` points to `affiliatewiz-globaltrad.msappproxy.net` — an internal AzureAD App Proxy URL. **Verify**: is this proxy URL still active and accessible? The URL template uses `@CalcFrom=2013-01-01` as a hardcoded start date in every row — if the payment window semantics have changed, the URLs may be misleading.

### 6. Tier 2/3 Commission Structure Clarification

`Tier2Commition` and `Tier3Commition` aggregate across all commission types (Sales, CPA, Chargebacks, etc.) where `Tier=2` or `Tier=3`. The business meaning of multi-tier commissions in AffiliateWiz was not fully traced. **Verify**: do Tier 2/3 affiliates refer to sub-affiliates (affiliate networks), or something else? Are both tiers still active in the current affiliate program?
