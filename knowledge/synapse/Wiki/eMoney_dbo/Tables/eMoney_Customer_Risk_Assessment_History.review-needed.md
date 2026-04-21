# Review Needed — eMoney_Customer_Risk_Assessment_History

**Generated**: 2026-04-21 | **Batch**: 9 | **Reviewer**: eMoney & Wallet Data Analytics Team

---

## Tier 4 Items (Uncertain — Needs Confirmation)

None. All 120 columns are Tier 1 or Tier 2 (fully confirmed from SP source code and upstream wikis). Column descriptions are verbatim-identical to eMoney_Customer_Risk_Assessment.

---

## Open Questions

| # | Column(s) | Question | Priority |
|---|-----------|----------|----------|
| Q1 | ClientRiskDate | The sample shows 529,939 customers (26.1%) with only 1 History row — their first classification. Do these customers all have PreviousClientRisk=NULL, or are some carrying over from a pre-2024-07-17 system? | Low |
| Q2 | UpdateDate | The sample shows UpdateDate=2026-04-12 06:53:22 for all rows in the latest batch. Does the SP run at a fixed time each day (post-Group-One), or is the schedule flexible? | Low |
| Q3 | (table) | Between 2025-02-25 and 2025-03-12, the trigger was score-change-based. Were any of those excess rows cleaned up, or do they remain in History? This affects how analysts should interpret the row count per CID in that period. | Medium |
| Q4 | (table) | Is there a retention policy for this table? At 8.1M rows growing by ~50K–100K per day (class-change rate), the table will reach significant size within 2–3 years. | Low |

---

## Data Quality Flags (Observed in Phase 2)

| Flag | Detail | Severity |
|------|--------|----------|
| Score-change period (Feb–Mar 2025) | 14 days of score-change-triggered rows exist in History. These rows are indistinguishable by column values from genuine class-change rows. Analysts doing class-change analysis should be aware of this confound. | Medium |
| PreviousClientRisk='None' (NULL) on first rows | First-time History entries have PreviousClientRisk=NULL and PreviousClientRiskDate=NULL. In display tools this renders as 'None'/''. This is expected behavior. | Low |

---

## Reviewer Corrections Log

*Empty — no corrections received yet. Reviewers: add your corrections here with date and initials.*

---

## Phase 16 Adversarial Evaluation

**Evaluator**: Claude Sonnet 4.6 (independent review)
**Date**: 2026-04-21

### Dimension Scores

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.5 | All 120 column tiers identical to CRA snapshot (cross-object consistency enforced). 5 Tier 1 / 115 Tier 2 verified. |
| Upstream Fidelity | 20% | 9.5 | Verbatim-identical descriptions to CRA snapshot. Cross-object consistency declaration included. No paraphrasing introduced. |
| Completeness | 20% | 9.0 | All 120 columns documented. History-specific semantics (append-only, class-change-only, trigger reversion timeline) fully documented in Sections 1–2. Score-change period confound documented. |
| Business Meaning | 15% | 9.0 | Self-referential design (Step 27 reads History, Step 32 writes back) clearly explained. Trigger reversion history and volume constraint context documented. Historical risk distribution vs current snapshot contrast provided. |
| Data Evidence | 10% | 9.0 | Phase 2 live data: 8.1M rows, 2.03M distinct CIDs, date range, rows-per-CID distribution (45.2% have 3-5 rows). Sample showing NULL PreviousClientRisk for new customers confirmed. |
| Shape Fidelity | 10% | 9.5 | 8-section structure, property table (12 rows), 120-row Elements table (all with Tier suffix), ETL diagram with trigger timeline, sample queries. |

**Composite Score**: 9.2 / 10.0

**PASS** (threshold: 7.5)

### Evaluator Notes

- **Strength**: The trigger reversion history (class→score→class) with dates and business reason is a critical non-obvious operational detail, correctly documented.
- **Strength**: The self-referential design (History feeds the snapshot, snapshot writes back to History) is clearly explained in both Business Meaning and the ETL diagram.
- **Strength**: Cross-object consistency correctly enforced — all 120 descriptions verbatim-identical to the CRA snapshot.
- **Minor gap**: The score-change period (Feb–Mar 2025) creates a confound for class-change analysis. This is flagged in the review section but could also appear in Section 3 Query Advisory.
