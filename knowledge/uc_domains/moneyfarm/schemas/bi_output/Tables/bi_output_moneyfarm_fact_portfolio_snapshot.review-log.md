---
object: main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
domain: moneyfarm
log_kind: analyst-review
---

# Review log — `bi_output_moneyfarm_fact_portfolio_snapshot`

Audit trail of analyst-driven corrections / approvals applied on top of the
auto-generated wiki. Each entry promotes a column to **Tier 5
(analyst-reviewed)** in the wiki and (optionally) into the deployable ALTER
script.

The semantics of the actions are defined in
`.cursor/skills/wiki-review/SKILL.md`:

- **approve** — analyst accepts the auto-generated description verbatim;
  T1..T4 → T5; comment becomes deployable.
- **correct** — analyst rewrites the description; T1..T4 → T5; comment becomes
  deployable.
- **dismiss** — analyst decides the column does not warrant a comment;
  description retained in wiki for traceability but no ALTER line emitted.
- **skip** — deferred; no state change.

---

## Entries

### 2026-05-04 — `Current_Market_Value_GBP`

- **Reviewer:** guyman
- **Action:** approve
- **Tier transition:** T4 → T5
- **Deployed to ALTER:** YES (added `COMMENT ON … Current_Market_Value_GBP …`
  under the new `===== Analyst-reviewed (T5) promotions =====` section).
- **Description retained verbatim** — the speculative parts (why so many
  `0.00` rows; `DefaultCurrency=5 ≈ GBP`) were explicitly accepted by the
  reviewer and remain in the comment, with the analyst-review citation appended.
- **Open follow-ups:**
  - The currency-id ⇒ ISO mapping in
    `[Conf/MG/13600227427]` is still not separately verified — if a future
    pass produces a definitive table, drop the "not separately verified"
    caveat from the comment.
  - The `0.00`-rows hypothesis (freshly-created vs NAV-zero) could be
    confirmed by a join against
    `money_farm.silver_moneyfarm_etoro_mf_aum` filtered on the same
    `(GCID, PortfolioID)`; a future enrichment pass should attempt this.

### 2026-05-04 — `UpdateDate`

- **Reviewer:** guyman
- **Action:** soften (correct, mild)
- **Tier transition:** T4 → T5
- **Deployed to ALTER:** YES (moved from the `Tier-1 + Tier-3` block into the
  `===== Analyst-reviewed (T5) promotions =====` section, with the rewritten
  comment text).
- **What changed:**
  - **Before:** "Snapshot timestamp. All sample rows share the same
    `UpdateDate`, confirming this is a **daily-rebuilt snapshot table**
    rather than a slowly-changing dimension — every row in a given day
    shares the same `UpdateDate`."
  - **After:** "Snapshot timestamp. All 5 sampled rows share the same
    `UpdateDate`, consistent with a single daily-write pattern.
    **History-retention semantics not analyst-confirmed** — this column is
    reliable as a row-freshness marker, but before relying on it for
    time-series queries verify the actual range with
    `SELECT COUNT(DISTINCT UpdateDate), MIN(UpdateDate), MAX(UpdateDate);`."
- **Why softened:** the original wording asserted "daily-rebuilt snapshot,
  not a slowly-changing dimension" as a positive design claim; the reviewer
  wanted to preserve the row-freshness observation but stop claiming history
  is not retained, since neither the Genie spaces nor the Confluence
  Tier-1 anchors directly assert this. The rewrite keeps the verifiable part
  (uniform-per-day from sample) and gives the reader a deterministic SQL
  to settle the question.
- **Open follow-ups:**
  - Run the suggested `COUNT(DISTINCT UpdateDate)` query at least once,
    record the result in this log, and if history is in fact NOT retained,
    re-add the "daily-rebuilt snapshot, not SCD" claim with an analyst
    citation.

### 2026-05-04 — Round-2 Confluence re-anchoring (agent-driven, no analyst input)

The reviewer (guyman) flagged that the column-by-column quiz wasn't valuable
because the reviewer is NOT a MoneyFarm domain expert and explicitly asked the
agent to re-read the cached Confluence pages and "do its best" autonomously.
This entry captures the agent-driven corrections that resulted. **No tier was
escalated to T5 in this pass** — promotions are strictly to T1 where a cached
Confluence Tier-1 page directly anchors the claim, otherwise the description is
softened (Tier stays the same) or left alone.

#### `PortfolioID` — T3 → T1 (Confluence anchor)
- **Anchor:** `Confluence/XP/13551468545 §General Flow` shows the exact event
  payload `"portfolioId":"4e6e39c9-1698-4b98-952e-d35f069ed097"` — UUID v4.
- **Fix:** changed "UUID identifying" → "UUID v4 (8-4-4-4-12 with hyphens)
  identifying"; added the snake_case ↔ camelCase note (`Portfolio_Id` ↔
  `PortfolioID`); added explicit Confluence citation alongside the Genie one.
- **Removed claim:** earlier internal speculation that values follow ULID format
  was incorrect — the deposit-event sample is standard UUID v4, not ULID.

#### `Source_Type` — T3 → T1 (Confluence anchor)
- **Anchor:** `Confluence/XP/13551468545 §General Flow + §Rollout Info` defines
  the streaming pipeline (`compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts`
  → `sub-accounts-experience-worker` → `payments-metrics` SB) and the event
  filter (`MoneyfarmEventHubEventTypes = [USER_CASH_ACCOUNT_ACTIVATED,
  PORTFOLIO_DEPOSIT]`).
- **Fix:** rewrote the `Live Event` description to spell out the exact pipeline
  the row was streamed through, replacing the previous one-line summary.

#### `GCID` — T1 (already T1; tightened citation)
- **Anchor:** same page, event sample shows `"gcid": 20620608` — confirms LONG
  numeric type matches the upstream event schema.
- **Fix:** added the explicit sample value to the description; corrected the
  section reference from `§"GCID Source"` (no such section in the page) to
  `§"General Flow" event sample`.

#### `Product_Name` — T1 (already T1; tightened citation)
- **Anchor:** `Confluence/CS/13209534657` (CS operational guide titled
  "Individual Savings Account (ISA) - MoneyFarm").
- **Fix:** added the CS-page citation to confirm the ISA family designation
  alongside the existing HLD anchor; tightened the section reference on the HLD
  to `§"High Level Design"`.

#### `Product_Onboarding_Date` — T4 (softened)
- **No Confluence anchor.** Sample says all 5 rows are 2025-2026; V2 HLD
  itself is dated 2024-01-28.
- **Fix:** dropped the over-confident "consistent with the MoneyFarm V2 rollout
  window" framing; replaced with explicit acknowledgment that the column's
  provenance (eToro-side V2-onboarding-date vs MoneyFarm-side
  portfolio-open-date) cannot be disambiguated from the sample alone, and that
  pre-V2 MoneyFarm customers — if they exist — are not represented in this
  slice.

#### `Portfolio_Risk_Level` — T4 (softened, claim retracted)
- **No Confluence anchor.** The previous wiki text linked
  `https://app.moneyfarm.com/` for the P0=Cash / P7=Equity-heavy mapping —
  external link to MoneyFarm's public site, not eToro-authored.
- **Fix:** dropped the band-semantics claim entirely. The new wording lists
  observed values (`P0`, `P7`, `NULL`) and explicitly tells readers not to rely
  on any band ordering until confirmed with the MoneyFarm team.

#### `Last_Risk_Level_Change_Date` — T4 (softened)
- **No Confluence anchor.** All sample rows NULL.
- **Fix:** sharpened the "format unknown" caveat — previously implied ISO 8601;
  now says the format cannot be confirmed because no live sample is available.

#### `Previous_Risk_Level` — T4 (softened)
- **No Confluence anchor.** All sample rows NULL.
- **Fix:** parallel sharpening to its companion column.

#### Tier breakdown after this pass
- T1: 4 (GCID, PortfolioID, Product_Name, Source_Type)
- T2: 0
- T3: 0 (both former T3 columns promoted to T1)
- T4: 4 (Product_Onboarding_Date, Portfolio_Risk_Level, Last_Risk_Level_Change_Date, Previous_Risk_Level)
- T5: 2 (Current_Market_Value_GBP — approved; UpdateDate — softened)
- UNVERIFIED: 0
- Total: 10

#### Audit-trail policy note
This pass is explicitly **agent-driven**, not analyst-driven. Tier 5 is
reserved for human/domain-expert sign-off. Round-2 promotions to Tier 1 are
based purely on cached Confluence Tier-1 pages already discovered in P2 — they
re-tier without claiming analyst review.
