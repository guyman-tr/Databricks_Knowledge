---
table: BI_DB_dbo.BI_DB_VerificationStatus
type: review-needed
batch: 37
---

# Review Notes: BI_DB_VerificationStatus

## Phase 16 Adversarial Evaluation

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.0 | 11 passthrough Dim columns correctly T1 from DWH wiki; 6 SP-computed columns correctly T2; VerificationDate/PVDate/Verified/DidCO/CO T2 correct |
| Upstream Fidelity | 20% | 9.0 | Verbatim copy from Dim_Customer, Dim_Channel, Dim_Country wiki entries for passthrough columns |
| Completeness | 20% | 9.0 | All 19 columns documented; rolling window semantics documented; 15-day lag explained; both hourly sibling and SELECT DISTINCT issue called out |
| Business Meaning | 15% | 9.0 | KYC verification cohort use case clearly explained; PVDate vs VerificationDate distinction documented; PlayerStatusID=13 resolved |
| Data Evidence | 10% | 9.0 | 223,915 rows confirmed, FTD window 2025-10-01–2026-04-07, 96.6% verified rate, 41.4% cashout rate from live data |
| Shape Fidelity | 10% | 9.5 | ROUND_ROBIN + HEAP correctly documented; no distribution key noted |

**Weighted Score: 9.0 / 10.0 ✅ PASS (threshold: 7.5)**

---

## Items Requiring Human Review

### HIGH: SELECT DISTINCT fan-out risk
The final INSERT uses `SELECT DISTINCT RealCID, ...` from a multi-way LEFT JOIN involving `#data`, `DWH_dbo.Dim_Customer`, `#co`, `#uploaded`, `#fca`, and `#t`. The `#fca` LEFT JOIN is not aggregated before the final join, which can create fan-out (one customer × many #fca rows = many rows before DISTINCT collapses them). This means:
- `CO` and `First14DaysDeposit` may be coming from `#co` and `#t` (which are properly aggregated) not from the raw #fca rows
- BUT the LEFT JOIN to raw `#fca` in the final SELECT is puzzling — it may exist for legacy reasons or as a population guard
**Action**: Verify with SP author whether the `LEFT JOIN #fca f ON f.RealCID = p.RealCID` in the final INSERT serves any purpose beyond historical reasons. If the DISTINCT is the only safeguard, consider whether a proper GROUP BY would be cleaner.

### MEDIUM: VerificationDate can precede FirstDepositDate
The SP joins `Fact_SnapshotCustomer` for the full CID history, not just post-FTD. Customers who verified (VerificationLevelID=3) before making a first deposit will have `VerificationDate < FirstDepositDate`. In the sample data, one row shows VerificationDate='2025-08-07' while FirstDepositDate='2025-11-04'. This is logically valid (pre-deposit KYC) but may surprise analysts using this as a "time to verify after deposit" metric.
**Action**: Document explicitly for analytics consumers that `VerificationDate` can predate `FirstDepositDate`.

### MEDIUM: Cashout window matches @ftd_sd but not per-customer FTD date
The cashout filter uses `ca.DateID >= @ftd_sdID` (start of the 6-month window for all customers), not `ca.DateID >= individual customer's FTD date`. This means a customer who deposited recently could theoretically have cashouts counted from months before their FTD if the cashout date is after @ftd_sd. In practice this is unlikely (customers don't cashout before their FTD), but it's a logical gap in the SP design.

### LOW: Region values confirmed as marketing regions not geographic
`Region` = `Dim_Country.Region` = marketing region from Dictionary.MarketingRegion. Confirmed 22 distinct values including "Arabic GCC", "German", "Italian", "Australia", "ROW" etc. This is not a geographic continent — analysts should not use it for geographic aggregation. The Dim_Country wiki documents this correctly; the BI_DB wiki description mirrors it.
