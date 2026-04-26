# BI_DB_AML_PI_Abuse_FID_Copy_Side — Review Notes

**Generated**: 2026-04-22
**Batch**: 48
**Reviewer action required**: No — low-priority confirmations only

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 9/10 | FundingID (T1 — Billing.Deposit) verbatim from upstream wiki; CID and ParentCID correctly T2 (derived via SP joins to History_GuruCopiers); UpdateDate Propagation |
| Completeness | 10/10 | All 4 DDL columns documented; row count, distinct FundingIDs/copiers/PIs, avg/max/min FundingIDs per copier all captured |
| ETL accuracy | 9/10 | SP fully read; #Copy_FID = DISTINCT (FundingID, CID=copier, ParentCID) from Fact_BillingDeposit; GuruCopiers join at @DateTime documented |
| Grain clarity | 9/10 | One row per (FundingID, CID, ParentCID) unique triple clearly stated; multi-PI copier row multiplication explained |
| Quirk capture | 9/10 | Max 2,185 FundingIDs for one copier, FundingID 1–7 exclusion, historical (no date filter) all documented |
| UC accuracy | 10/10 | Not Migrated confirmed |

**Overall**: 9.3/10 — PASS (threshold: 7.5)

---

## Open Questions

**Q1 (Low priority)**: One copier has 2,185 distinct FundingIDs. Confirm this is expected behavior (e.g., shared/institutional device making many deposits) and not a data quality anomaly.

**Q2 (Low priority)**: FID data uses all historical `Fact_BillingDeposit` records with no date filter. Confirm this is intentional for copiers (consistent with PI-side behavior).

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- Grain: one row per (FundingID, CID=copier, ParentCID=PI) unique triple
- FundingID NOT IN (1,2,3,4,5,6,7) — generic/internal methods excluded by design
- Copiers linked to PI via History_GuruCopiers at @DateTime (point-in-time snapshot)
- PII: LOW — FundingID, CID, ParentCID are all integer IDs only
