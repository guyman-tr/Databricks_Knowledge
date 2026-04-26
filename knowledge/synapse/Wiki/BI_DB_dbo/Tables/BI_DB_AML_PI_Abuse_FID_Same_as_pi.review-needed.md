# BI_DB_AML_PI_Abuse_FID_Same_as_pi — Review Notes

**Generated**: 2026-04-22
**Batch**: 48
**Reviewer action required**: No — quirks are documented; low-priority confirmations only

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 9/10 | Both ParentCID and SameFID_AS_PI correctly T2 (derived by SP aggregation over #PI_FID JOIN #Copy_FID); UpdateDate Propagation |
| Completeness | 10/10 | All 3 DDL columns documented; 431 rows, 352 PIs, min/max/avg captured; multi-row-per-PI behavior quantified |
| ETL accuracy | 9.5/10 | SP fully read; cross-PI join semantics (FundingID only — no ParentCID restriction) identified and documented; SELECT DISTINCT fan-out mechanism explained |
| Grain clarity | 9/10 | Non-obvious multi-row grain (431 rows / 352 PIs) explained with root cause (distinct SameFID_AS_PI values per copier grouping) |
| Quirk capture | 9.5/10 | Cross-PI join design, 91% PI absence, multi-row fan-out, formula=0 for single-match, NOT NULL DDL all documented |
| UC accuracy | 10/10 | Not Migrated confirmed |

**Overall**: 9.5/10 — PASS (threshold: 7.5)

---

## Open Questions

**Q1 (Low priority)**: The cross-PI JOIN (FundingID only, no ParentCID restriction) is an unusual design that compares a PI's FundingIDs against ALL copiers of ALL PIs, not just their own copiers. Confirm this is the intended cross-network detection logic vs. a potential join condition omission.

**Q2 (Low priority)**: 91% of PIs (3,502 of 3,854) produce zero cross-PI FID matches and are absent from this table. Confirm downstream consumers handle the LEFT JOIN NULL correctly (i.e., absent = 0, not unknown).

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- Cross-PI JOIN: #PI_FID JOIN #Copy_FID ON FundingID only (no ParentCID filter)
- Multiple rows per PI are expected when different copier groupings produce distinct SameFID_AS_PI values
- Only 352 of ~3,854 PIs appear (9%) — absent PIs have zero cross-network FID matches
- NOT NULL on SameFID_AS_PI and UpdateDate (consistent with FID_Same_Copy DDL pattern)
- Formula: COUNT(*) - COUNT(DISTINCT pf.FundingID) per (PI, copier) pair
- PII: LOW — ParentCID is CID only; SameFID_AS_PI is aggregate integer
