# `Credit` column — full propagation chain spot-check

This is the single-column blast-radius walk for `Credit`, used as a worked example before running the full DAG-driven cleanup. It traces the column from its OLTP source-of-truth all the way down through every documented hop to UC live comments.

---

## Chain at a glance

```
OLTP source-of-truth (TRUTH)
  History.ActiveCredit_BIGINT.Credit                                                                  [1 wiki]
  "Customer's total credit balance after this event (running total). …"
  Confidence: VERIFIED
            │
            │ — should be inherited verbatim by SP_Fact_SnapshotEquity step
            ▼
DWH "patient zero" (CORRECTLY tags itself Tier 2 — good)
  Fact_SnapshotEquity.Credit                                                                          [1 wiki]
  "Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day …"
  Tier 2 — SP_Fact_SnapshotEquity         ← introduces "credit/bonus" framing, not in OLTP truth
            │
            ├──────────────────────────────────────────────────────────┐
            ▼                                                          ▼
DWH passthrough view (PROMOTION LIE Tier 2 → T1)                DWH snapshot views (PROMOTION LIE Tier 2 → Tier 1)
  V_Liabilities.Credit                          [1 wiki]          V_Fact_SnapshotEquity.Credit                       [3 wikis]
  | Fact_SnapshotEquity.Credit | Direct | T1 |                    "Outstanding credit/bonus balance … (Tier 1 — inherited from Fact_SnapshotEquity wiki)"
  (no Description col — Source+Formula+Tier layout)               V_Fact_SnapshotEquity_ForDWHRep.Credit
  Audit verdict: not in audit scope (parser skips                 V_Fact_SnapshotEquity_FromDateID.Credit
   tables with no Description col)                                Audit verdict (all 3): FAIL / HIGH / L1-structural promotion lie
            │                                                     Proposed fix: keep text, downgrade tag to (Tier 2 — via Fact_SnapshotEquity)
            ▼
BI_DB downstream — TWO populations
  ┌────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────┐
  │ POPULATION A — author tagged Tier 2 (correctly)            │ POPULATION B — author tagged Tier 1 (PROMOTION LIE)         │
  │  • BI_DB_LimitedAccountsWithReasons.Balance                │  • BI_DB_CIDFirstDates.Credit                              │
  │    (Tier 2 — SP_LimitedAccountsWithReasons)                │    (Tier 1 -- V_Liabilities via Fact_SnapshotEquity)       │
  │  • BI_DB_Investors_Unclustered.Amount / AUM_AUA            │    + adds NEW HALLUCINATION "promotional/bonus credit"     │
  │    (Tier 2 -- SP_InvestorReport)                           │  • BI_DB_MarketingCloudDaily_V.Credit                      │
  │  • BI_DB_CapitalGuarantee_Panel.AvailableBalance           │    (Tier 1 — Fact_SnapshotEquity via V_Liabilities)        │
  │    (Tier 2 — SP_Capital_Guarantee_Panel via V_Liab.Credit) │  • BI_DB_CIDFirstDates_metric_view.Total Credit            │
  │  • BI_DB_Blocked_Customers.Credit                          │    (Tier 1 — Fact_SnapshotEquity via V_Liabilities)        │
  │    (Tier 2 — DWH_dbo.V_Liabilities)                        │  • BI_DB_DDR_Fact_AUM.CreditTP                             │
  │  Verdict: out of Tier-1 audit scope (correctly Tier 2)     │    (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SE.Credit)│
  │  Action: leave alone, narrative wording may still drift    │    + adds NEW HALLUCINATION "Promotional Credit component" │
  │          but is not a tier promotion lie                   │  Audit verdict: would FAIL/HIGH on Phase D BI_DB sweep      │
  └────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────┘
            │                                                                                  │
            └──── correctly stays Tier 2 →                                                     ▼
                                                                              UC_generated inheritance (DOUBLE-TIER-1 STACKING)
                                                                                 • etoro_kpi.cidfirstdates_v.Credit
                                                                                   "… (Tier 1 -- V_Liabilities via Fact_SnapshotEquity)
                                                                                       (Tier 1 — inherited from main.bi_db.…cidfirstdates_masked)"
                                                                                 • etoro_kpi.ddr_aum_v.{BalanceTradingPlatfrom, CreditTP}
                                                                                   "Promotional Credit component … (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SE.Credit)"
                                                                                 • bi_output.bi_output_vg_parentcid.Credit
                                                                                   "Direct passthrough from V_Liabilities.Credit. (Tier 1 — Fact_SnapshotEquity)"
                                                                                 • bi_output.bi_output_vg_aum.BalanceTradingPlatfrom
                                                                                   "Promotional Credit component … (Tier 1 — …Fact_SnapshotEquity.Credit)"
                                                                                            │
                                                                                            ▼
                                                                              UC live column comment (deployed via .alter.sql)
                                                                                 Analyst opens main.etoro_kpi.cidfirstdates_v in Databricks → sees
                                                                                 "Customer credit balance (promotional/bonus credit) …"
                                                                                 → writes WHERE Credit > 0 thinking it's a bonus filter
                                                                                 → reports wrong number to risk/finance
```

---

## Hop-by-hop detail

### Hop 0 — OLTP source-of-truth (the canonical answer)

  - **File**: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ActiveCredit_BIGINT.md` (line 150)
  - **Confidence**: VERIFIED
  - **Description**:

    > Customer's total credit balance after this event (running total). Represents the new account balance in monetary units. See TotalCash for the liquid component breakdown.

  - **Key facts**:
    - It's the **running balance after the event** (cumulative), not a bonus/promotional bucket.
    - Liquid breakdown lives on a separate column (`TotalCash`).
    - `Credit = previous Credit + Payment`.

  - **Why this matters**: nothing downstream should redefine `Credit` as "promotional/bonus" — that's a different concept entirely (which is what `BonusCredit` is for).

### Hop 1 — DWH patient zero (`Fact_SnapshotEquity.Credit`)

  - **File**: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotEquity.md` (line 159)
  - **Tier tag**: `(Tier 2 — SP_Fact_SnapshotEquity)` ✓ (correctly self-identifies as Tier 2)
  - **Current text**:

    > Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations.

  - **Audit verdict**: not flagged (correctly Tier 2 → not in Tier-1 audit scope).
  - **But subtly wrong wording**: introduces "**credit/bonus** balance" framing that doesn't exist in OLTP truth. This single word becomes the root of every downstream hallucination. The cleanup should:
    - Keep the Tier 2 tag (correct).
    - Rewrite to: *"Customer's total credit balance after the last credit event for this CID on this date (running total per History.ActiveCredit, selected via ROW_NUMBER over CID ORDER BY Occurred DESC, CreditID DESC). Same semantics as History.ActiveCredit.Credit. Negative values indicate net debt."*
  - **Why narrative review is needed here, not auto-apply**: this is the kind of correction that should be flagged `narrative_review_needed=True` in `_tier1_truth_corrections.csv` per the plan — the audit caught the *promotion lies it caused*, but the underlying wording defect is a Tier-2 row our audit didn't visit. Phase E `harden_generator` is what prevents future Tier-2 wording from drifting.

### Hop 2 — DWH passthrough view (`V_Liabilities.Credit`)

  - **File**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md` (line 104)
  - **Layout**: this wiki uses `| # | Column | Source | Formula | Tier |` (no Description col), so the tier-1 audit parser correctly skips it.
  - **Row**: `| 12 | Credit | Fact_SnapshotEquity.Credit | Direct | T1 |`
  - **Issue**: claims `T1` for a column whose source is Tier 2 — silent promotion lie at the lineage-table layer.
  - **Cleanup action**: parser extension to handle `| Column | Source | Formula | Tier |` layout, OR explicit handling in `apply_corrections.py` that knows to flip `T1 → T2` for passthrough rows whose source is Tier 2+.
  - **Downstream impact**: every BI_DB wiki that cites `V_Liabilities.Credit` as "(Tier 1 — via V_Liabilities)" inherits a chain that's structurally weak at this link too.

### Hop 3 — DWH SnapshotEquity views (3 PROMOTION LIES — all caught)

  | File | Line | Current claim | Audit verdict |
  |---|---|---|---|
  | `DWH_dbo/Views/V_Fact_SnapshotEquity.md` | 42 | (Tier 1 — inherited from Fact_SnapshotEquity wiki) | FAIL / HIGH / L1-structural |
  | `DWH_dbo/Views/V_Fact_SnapshotEquity_ForDWHRep.md` | 46 | (Tier 1 — inherited from Fact_SnapshotEquity wiki) | FAIL / HIGH / L1-structural |
  | `DWH_dbo/Views/V_Fact_SnapshotEquity_FromDateID.md` | 49 | (Tier 1 — inherited from Fact_SnapshotEquity wiki) | FAIL / HIGH / L1-structural |

  - **Proposed fix (mechanical, no LLM)**: keep the description text, swap the tier tag to `(Tier 2 — via Fact_SnapshotEquity)`. Same text content because the description is already a faithful copy of the Tier-2 source; only the provenance claim is wrong.
  - **Files modified per row**: 1 `.md` + 1 `.alter.sql` per wiki = 6 file edits.

### Hop 4 — BI_DB downstream (mixed: half correctly Tier 2, half PROMOTION LIE)

  **Population A — correctly Tier 2 (no action needed by this audit; flag for narrative review only)**:

  | File | Column | Tag |
  |---|---|---|
  | `BI_DB_LimitedAccountsWithReasons.md:188` | `Balance` | (Tier 2 — SP_LimitedAccountsWithReasons) |
  | `BI_DB_Investors_Unclustered.md:137-138` | `Amount`, `AUM_AUA` | (Tier 2 -- SP_InvestorReport) |
  | `BI_DB_CapitalGuarantee_Panel.md:221` | `AvailableBalance` | (Tier 2 — SP_Capital_Guarantee_Panel via V_Liabilities.Credit) |
  | `BI_DB_Blocked_Customers.md:174` | `Credit` | (Tier 2 — DWH_dbo.V_Liabilities) |

  **Population B — claimed Tier 1, will FAIL Phase D BI_DB audit**:

  | File | Column | Current wording (start) | Tag |
  |---|---|---|---|
  | `BI_DB_CIDFirstDates.md:288` | `Credit` | "Customer credit balance (**promotional/bonus credit**). …" | (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
  | `BI_DB_MarketingCloudDaily_V.md:114` | `Credit` | "Credit projected from BI_DB_MarketingCloudDaily …" | (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
  | `BI_DB_CIDFirstDates_metric_view.md:97` | `Total Credit` | "Metric alias of `Credit`: nightly ISNULL(V_Liabilities.Credit, 0) snapshot …" | (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
  | `BI_DB_DDR_Fact_AUM.md:171` | `CreditTP` | "**Promotional `Credit` component** from VL …" | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) |

  **Population B is the propagated corruption**: each invents fresh "promotional/bonus" framing that's not in the OLTP truth, then stamps it Tier 1. Two of the four (`BI_DB_CIDFirstDates`, `BI_DB_DDR_Fact_AUM`) add NEW invented words that didn't exist in `Fact_SnapshotEquity` either — this is the chain accumulating hallucinations, not just propagating one.

### Hop 5 — UC_generated inheritance (DOUBLE-TIER-1 STACKING)

  | File | Column | Wording snippet | Tags |
  |---|---|---|---|
  | `UC_generated/etoro_kpi/Views/cidfirstdates_v.md:115` | `Credit` | "Customer credit balance (promotional/bonus credit). …" | `(Tier 1 -- V_Liabilities via Fact_SnapshotEquity)` **AND** `(Tier 1 — inherited from main.bi_db.…cidfirstdates_masked)` |
  | `UC_generated/etoro_kpi/Views/ddr_aum_v.md:113, 149` | `BalanceTradingPlatfrom`, `CreditTP` | "Promotional Credit component …" | `(Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit)` |
  | `UC_generated/bi_output/Views/bi_output_vg_parentcid.md:210` | `Credit` | "Direct passthrough from V_Liabilities.Credit." | `(Tier 1 — Fact_SnapshotEquity)` |
  | `UC_generated/bi_output/Views/bi_output_vg_aum.md:249` | `BalanceTradingPlatfrom` | "Promotional Credit component …" | `(Tier 1 — …Fact_SnapshotEquity.Credit)` |

  - **The DOUBLE-tag stacking** on `cidfirstdates_v.Credit` shows what `cache_upstream_wikis.py` does when it inherits from a wiki that already had a Tier 1 claim — it APPENDS its own Tier 1 inheritance tag instead of verifying the existing one. So one wrong claim at hop 4 becomes a multi-tag claim at hop 5, each layer of which "corroborates" the lie.
  - **Live UC impact**: each `.alter.sql` matching these wikis has a `COMMENT '...'` line carrying the corrupt text. An analyst opening `main.etoro_kpi.cidfirstdates_v` in the Databricks catalog sees the official UC column comment containing "promotional/bonus credit" — and trusts it.

### Old judge cache for this column

  - `knowledge/_dwh_llm_judge_cache/Fact_SnapshotEquity.json` exists but only has WRONG verdicts for `DateRangeID` (about the YYYYMMDDMMDD vs YYYYMMDDYYYY pattern). The previous LLM judge **did NOT flag the Credit wording**.
  - That's why this case slipped through: the previous judge was checking semantic accuracy against Confluence/live-data but not flagging the "credit/bonus" wording, AND it had no structural-tier-promotion check. My new audit's Layer 1 promotion-lie detector is what newly surfaces this.

---

## Total cleanup scope for this one column

  | Layer | Files to edit | Type of edit |
  |---|---|---|
  | DWH `.md` | 3 (V_Fact_SnapshotEquity{, _ForDWHRep, _FromDateID}.md) | swap tier tag (mechanical) |
  | DWH `.alter.sql` | 3 (matching alter.sql) | regen from corrected `.md` |
  | BI_DB `.md` | 4 (Population B above) | swap tier tag + remove invented "promotional/bonus" framing |
  | BI_DB `.alter.sql` | 4 | regen |
  | UC_generated `.md` | 4 | swap tier tag + remove invented framing |
  | UC_generated `.alter.sql` | 4 | regen |
  | UC live `COMMENT` deploys | ~11 ALTER COLUMN statements | run uc-deploy-comments skill |
  | **Total** | **≈22 file edits + 11 UC ALTERs** | for ONE column's blast radius |

  Plus a separate, manually-curated narrative-review entry for the underlying Tier-2 wording in `Fact_SnapshotEquity.Credit` itself (the Hop-1 root cause).

## What this spot-check confirms about the plan

  1. **Layer 1 promotion-lie detection works** — caught all 3 DWH-view lies in DWH_dbo and would catch the 4 BI_DB lies in Phase D.
  2. **DAG-driven Phase D ordering is essential** — if BI_DB is audited *before* the DWH layer is corrected, the 4 BI_DB Population-B wikis will be compared against the still-wrong DWH text and the judge will give noisy/inconsistent verdicts. Audit upstreams first → audit downstream against TRUTH.
  3. **`propagation_map.py` must use column_lineage edges, not name matching** — searching for `V_Liabilities.Credit` as a substring across BI_DB MDs accidentally surfaces correctly-tagged Tier-2 rows (Population A) as well as the wrong Tier-1 ones (Population B). The DAG-edge approach (which UC column lineage was actually recorded between objects, with `event_count > 0`) discriminates between "this column is computed from V_Liabilities.Credit" vs "this column just mentions it in a narrative".
  4. **There's a Tier-2 wording bug at Hop 1** that this audit doesn't fix — it's outside the Tier-1 scope but it's the root cause of all downstream hallucinations. Phase E `harden_generator` is what prevents future Tier-2 rows from drifting from their OLTP source-of-truth.
  5. **The "double tier tag" stacking at Hop 5** is a separate generator bug (`cache_upstream_wikis.py` appending instead of verifying). Worth a sub-task under Phase E `harden_generator` to fix the inheritance writer.
