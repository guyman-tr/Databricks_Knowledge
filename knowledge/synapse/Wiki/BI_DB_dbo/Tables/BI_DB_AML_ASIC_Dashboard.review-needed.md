# Review Needed: BI_DB_AML_ASIC_Dashboard

**Generated**: 2026-04-22  
**Batch**: 44  
**Reviewer**: Domain SME (AML compliance / ASIC reporting team)

---

## 1. VERIFY — `Has_Open_AML_Case` is 0 for all rows

**Priority**: INFO  
At time of documentation, `Has_Open_AML_Case = 0` for all 4,307 rows. This could mean:
1. The ASIC high-risk population genuinely has no open AML cases right now (expected if cases were recently resolved)
2. `BI_DB_SF_Cases_Panel` is out of date or the filter conditions are too restrictive

Confirm whether `Has_Open_AML_Case = 0` is the expected current state, or if the Salesforce case matching logic (ActionType_AtOpen LIKE '%AML%') may be missing cases with different action type labeling.

---

## 2. VERIFY — `RiskScoreName` column is always 'High'

**Priority**: LOW  
The population filter `JOIN … ON RiskScoreName = 'High'` means this column has no analytical variation (always 'High'). If the intent is to show the risk score that earned the customer a place in this dashboard, the column is correct. But if the intent was to show their *current* risk score (which may have changed since the JOIN), it may be stale. Confirm if 'High' here reflects a point-in-time risk classification or always the current one.

---

## 3. VERIFY — Regulation change filter excludes BVI and None

**Priority**: LOW  
The regulation change pipeline (`#status03`) explicitly excludes previous regulations of 'BVI', 'None', 'ASIC', and 'ASIC & GAML'. This means customers who came to ASIC directly from BVI (or with no prior regulation) are NOT flagged with `Has_Changed_Regulation = 1`. Confirm this is intentional — if BVI customers also require enhanced review, the filter should be expanded.

---

## 4. VERIFY — `Equity` uses V_Liabilities (yesterday)

**Priority**: INFO  
`Equity = Liabilities + ActualNWA` from `V_Liabilities` where `DateID = GETDATE()-1`. This means the equity shown is **yesterday's** balance. Confirm if this is the expected latency (T-1 equity for same-day AML decisions) or if it should use a more recent snapshot.

---

## 5. VERIFY — `Total_Deposits` uses Fact_CustomerAction, not Fact_BillingDeposit

**Priority**: INFO  
Total deposits here sum `Fact_CustomerAction.Amount WHERE ActionTypeID = 7`. Other AML tables in this schema (e.g., BI_DB_AMLPeriodicReview_PostReview) use `Fact_BillingDeposit.AmountUSD WHERE PaymentStatusID = 2`. Confirm that `Fact_CustomerAction` deposits (ActionTypeID=7) are equivalent to approved billing deposits, or whether there is a meaningful difference in what each source captures.
