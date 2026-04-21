---
object: v_eMoney_Card_Instance_Summary
schema: eMoney_dbo
review_date: 2026-04-19
batch: 5
---

# Review Needed — v_eMoney_Card_Instance_Summary

## Tier 4 Items

None — all 17 columns are direct passthroughs from the base table; descriptions and tier assignments inherited verbatim.

## Open Questions

| # | Question | Priority |
|---|----------|----------|
| 1 | SP_eMoney_Card_Monthly_Snapshot (primary consumer of card instance data) references `eMoney_Card_Instance_Summary`. Confirm whether it should reference this view instead, or whether it intentionally queries the base table to access MaskedPAN or other excluded columns. | Low |
| 2 | MaskedPAN exclusion is implemented via a commented-out column in the DDL rather than a column-level masking policy or row-level security rule. Is this the intended data governance approach, or should a formal masking/access-control policy be applied at the base table level? | Low |

## Tier 2 Items for Verification

None beyond those already documented in `eMoney_Card_Instance_Summary.review-needed.md`. All open questions on base table columns carry over to this view.

## Phase 16 Adversarial Evaluation

| Dimension | Weight | Score | Contribution |
|-----------|--------|-------|-------------|
| Tier Accuracy | 30% | 9.0 | 2.70 |
| Upstream Fidelity | 25% | 9.5 | 2.375 |
| Completeness | 20% | 9.0 | 1.80 |
| Business Meaning | 15% | 9.0 | 1.35 |
| Shape Fidelity | 10% | 9.0 | 0.90 |
| **Total** | | **9.1** | |

**Result**: PASS (threshold 7.5)

**Notes**: View documentation is accurate, concise, and correctly frames this as a thin wrapper with no added logic. Tier assignments faithfully inherited from base table. Upstream Fidelity slightly elevated because the base table (the direct upstream) was documented in the same batch — no ambiguity in column provenance. The only documentation gap is confirming whether SP_eMoney_Card_Monthly_Snapshot uses the view or the base table.

## Sign-off Checklist

- [ ] Data Engineering: Confirm SP_eMoney_Card_Monthly_Snapshot references view vs base table for card instance data
- [ ] Data Governance: Confirm MaskedPAN exclusion approach (DDL comment vs formal masking policy) meets current data classification requirements
