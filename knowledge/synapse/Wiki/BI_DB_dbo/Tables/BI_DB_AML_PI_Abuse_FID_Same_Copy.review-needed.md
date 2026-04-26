# BI_DB_AML_PI_Abuse_FID_Same_Copy — Review Notes

**Generated**: 2026-04-22
**Batch**: 48
**Reviewer action required**: No — low-priority confirmations only

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 9/10 | Both ParentCID and Same_FID_Copier correctly T2 (no T1 passthrough — values derived by SP aggregation); UpdateDate Propagation |
| Completeness | 10/10 | All 3 DDL columns documented; row count, distinct PIs, min/max/avg Same_FID_Copier captured; one-row-per-PI grain noted |
| ETL accuracy | 9/10 | SP fully read; COUNT(*)-COUNT(DISTINCT FundingID) formula and its semantics documented; source as #Copy_FID GROUP BY ParentCID stated |
| Grain clarity | 9/10 | One row per PI (ParentCID) confirmed by live data (total_rows = distinct_pis = 3,849) |
| Quirk capture | 9/10 | Formula semantics (non-unique count, not distinct-shared-FID count), NOT NULL DDL change from other satellite tables, max 402 documented |
| UC accuracy | 10/10 | Not Migrated confirmed |

**Overall**: 9.3/10 — PASS (threshold: 7.5)

---

## Open Questions

**Q1 (Low priority)**: `Same_FID_Copier = 402` for one PI is the highest cross-copier FID sharing in the suite. Confirm this PI is under active investigation or flagged in the AML workflow.

**Q2 (Low priority)**: The `COUNT(*) - COUNT(DISTINCT FundingID)` formula counts "extra" rows rather than "shared FundingIDs". For example, if 3 copiers share 1 FundingID, the value is 2 (not 1 and not 3). Confirm analysts interpreting this column understand the semantics correctly.

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- One row per PI (ParentCID) — confirmed by live data (3,849 rows = 3,849 distinct PIs)
- Formula: COUNT(*) - COUNT(DISTINCT FundingID) over #Copy_FID GROUP BY ParentCID
- FundingID NOT IN (1..7) exclusion inherited from #Copy_FID source
- NOT NULL on Same_FID_Copier and UpdateDate (different from FID_PI_Side DDL)
- PII: LOW — ParentCID is CID only; Same_FID_Copier is aggregate integer
