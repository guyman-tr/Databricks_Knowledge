# BI_DB_AML_PI_Abuse_FID_PI_Side — Review Notes

**Generated**: 2026-04-22
**Batch**: 48
**Reviewer action required**: No — low-priority confirmations only

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 9/10 | FundingID (T1 — Billing.Deposit via Fact_BillingDeposit) and ParentCID (T1 — Customer.CustomerStatic) verbatim from upstream wikis; UpdateDate correctly classified as Propagation |
| Completeness | 10/10 | All 3 DDL columns documented; row count, distinct PIs, avg/max/min FundingIDs per PI all captured |
| ETL accuracy | 9/10 | SP fully read; #PI_FID = DISTINCT (FundingID, ParentCID) from Fact_BillingDeposit; FundingID NOT IN (1..7) exclusion documented; #pis gate conditions stated |
| Grain clarity | 9/10 | One row per (FundingID, ParentCID) unique pair clearly stated; volume-not-captured behavior documented |
| Quirk capture | 9/10 | FundingID 1–7 exclusion, historical (no date filter unlike DeviceID tables), max 114 FundingIDs per PI all documented |
| UC accuracy | 10/10 | Not Migrated confirmed |

**Overall**: 9.3/10 — PASS (threshold: 7.5)

---

## Open Questions

**Q1 (Low priority)**: The FundingID exclusion list `NOT IN (1,2,3,4,5,6,7)` is hardcoded in the SP. Confirm this list remains current — new internal/generic payment channels (e.g., promotional credits, system transfers) may have been added to `Billing.Funding` since SP inception (2023-10-25).

**Q2 (Low priority)**: FID data uses all historical `Fact_BillingDeposit` records with no date filter (unlike DeviceID tables which use `DateID >= 20240101`). Confirm this is intentional — a PI's payment methods from years-old deposits are included in the abuse analysis.

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- FundingID NOT IN (1,2,3,4,5,6,7) — generic/internal methods excluded by design
- Grain: one row per unique (FundingID, ParentCID) — deposit volume not captured
- Max 114 FundingIDs per PI is expected (high-volume PI with many distinct payment methods)
- PII: LOW — FundingID is an integer instrument ID (not card number); ParentCID is CID only
