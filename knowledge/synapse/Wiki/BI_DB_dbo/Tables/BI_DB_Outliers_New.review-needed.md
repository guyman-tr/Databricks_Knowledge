# Review Sidecar — BI_DB_dbo.BI_DB_Outliers_New
<!-- speckit 2026-05-14 -->

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 30 cols parsed from wiki Elements for UC regen |
| Synapse row range | ✅ | Count=6,555 (2015-01-12 → 2026-04-25) |
| Transition cardinality | ✅ | Only `Valid To Invalid` / `Invalid to Valid` (4769 / 1786) |
| Unrealized NULL mix | ✅ | 6,513 NULL vs 42 non-null — doc updated for legacy tail |
| FinanceReportSPS lane | ✅ | SP_Outliers_New @ P99 |

## Items for Human Review

| # | Topic | Question |
|---|-------|----------|
| 1 | Legacy unrealized values | Confirm whether historical 42-row tail should be purged / backfilled to NULL for regulatory cleanliness. |
| 2 | PlayerStatusID timing | Still need confirmation whether liabilities split should read current-day vs prior-day status (sidecar item carried from 2026-04-23). |
| 3 | Negative Refill Compensation ordering | DDL vs logical ordering mismatch remains cosmetic—flag if Power BI semantic model depends on ordinal layout. |

## Adversarial evaluation (Phase 16, 2026-05-14)

Strengths — live counts, CompensationReason enumerations grounded in longstanding lineage markdown, verbatim Dim tiering on RealCID/Regulation, Confluence link explaining credit-valid outliers.

Residual risk — Synapse withheld `OBJECT_DEFINITION`; view body reconstructed via column-diff vs base table only. Recommendation score **8.2/10**.
