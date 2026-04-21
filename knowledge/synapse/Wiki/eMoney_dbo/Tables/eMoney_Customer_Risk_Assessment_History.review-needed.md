# eMoney_Customer_Risk_Assessment_History — Review Needed

> Sidecar checklist for wiki reviewer. All wiki content is in `eMoney_Customer_Risk_Assessment_History.md`.

## Open Questions

| # | Column / Topic | Question | Priority |
|---|---------------|----------|---------|
| 1 | Score-change rows (2025-02-25 → 2025-03-12) | Do any downstream reports consume History row counts as a proxy for class-transition frequency? If so, the inflated rows during this 16-day window (score-change trigger) would distort those metrics. | High |
| 2 | History maximum rows per CID (387) | The max of 387 History rows for a single CID suggests either very frequent class oscillation or a remnant of the 2025-02-25 score-change period. Confirm whether this outlier is expected or a data quality flag. | Medium |
| 3 | CID IS NOT NULL in DDL | The DDL marks CID NOT NULL. Confirm no orphan CID=0 rows exist in History (cancelled accounts). The population comes from eMoney_Dim_Account which may include GCID=0 rows. | Low |
| 4 | Self-referential read timing | Step 27 reads History BEFORE Step 30-31 truncates/rebuilds CRA. This is correct. Confirm no race condition risk if SP runs concurrently with any direct reads of History. | Low |
| 5 | All open questions from CRA sidecar | Questions 1-11 in eMoney_Customer_Risk_Assessment.review-needed.md apply equally to History (same schema, same SP). See CRA sidecar for full list. | Various |

## Tier 1 Copy Verification

*Identical to eMoney_Customer_Risk_Assessment — all five Tier 1 columns (CID, GCID, VerificationLevelID, DateOfBirth, DateOfReg) use verbatim upstream descriptions per cross-object consistency rule.*

| Column | Upstream Source | Stripped Items | Status |
|--------|----------------|----------------|--------|
| CID | Dim_Customer.md (RealCID) — Customer.CustomerStatic | None; DWH rename note appended | IDENTICAL to CRA |
| GCID | Dim_Customer.md — Customer.CustomerStatic | None | IDENTICAL to CRA |
| VerificationLevelID | Dim_Customer.md — BackOffice.Customer | Stats stripped: "(34.2%)", "(12.4%)", "(6.2%)", "(47.1%)" | IDENTICAL to CRA |
| DateOfBirth | Dim_Customer.md (BirthDate) — Customer.CustomerStatic | None; DWH CAST+rename note appended | IDENTICAL to CRA |
| DateOfReg | Dim_Customer.md (RegisteredReal) — Customer.CustomerStatic | None; DWH CAST+rename note appended | IDENTICAL to CRA |

## Items Confirmed by Reviewer

- [ ] Score-change rows (2025-02-25 → 2025-03-12) assessed for downstream impact
- [ ] Max 387 rows per CID confirmed as expected/anomaly
- [ ] CID NOT NULL confirmed — no GCID=0 / cancelled-account rows in History
- [ ] All CRA review items confirmed (same schema)

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Business Meaning | 9.5 | Audit log purpose clear; class-change vs score-change distinction documented; self-referential loop explained; anomaly period noted |
| Grain & Lifecycle | 9.5 | Append-only, multi-row per CID, insert condition explicit, no TRUNCATE confirmed |
| Technical Accuracy | 9.0 | Step 32 logic matches SP code exactly; WHERE clause reproduced; timing of Step 27 read documented |
| Column Completeness | 8.5 | All 120 columns documented with cross-object consistency note; same P32/section order cosmetic note |
| Tier Accuracy | 9.0 | 5 Tier 1 verified verbatim; 115 Tier 2; cross-object consistency rule applied |
| Gotchas & Flags | 9.5 | No grain constraint (multi-row per CID); score-change anomaly window; P10 NULL; UpdateDate not business date; PreviousClientRisk semantics |
| **Average** | **9.2** | **PASS (≥7.5 threshold)** |
