# Self-service analytics at eToro
### Three acts: what we learned from Anthropic, what we already built, and the roadmap we're proposing
### Executive deck — 2026-06-08 — v2 (three-act restructure)

Source comparison: *How Anthropic enables self-service data analytics with Claude* (Anthropic blog, 2026-06-03), benchmarked against the eToro Data Platform skills + UC + Genie + MCP stack as of today.

Audience: Data leadership / Eng leadership / cross-functional analyst-team leads.
Length: ~10 minutes.

The story we want to tell:

- **Act I (Research)** — what Anthropic's article taught us about doing self-service analytics with an LLM agent.
- **Act II (Comparison)** — where eToro already stands against that framework, including one deliberate non-adoption.
- **Act III (Action Plan)** — the roadmap. Every yellow on the scorecard is already a task family on this list; the work breakdown below is what we're proposing for H2.

---

## Slide 1 — Cover

> **The strategic shift for H2:** stop treating the skill corpus as a static artifact and start running it as a living machine — one that watches every knowledge source in the company, judges itself with telemetry, and updates itself.

**The ask of this deck:**
1. Align on the machine described in Act III.
2. Greenlight the first watchers.
3. Commit a per-domain accuracy floor.
4. Assign the domain owners who staff that floor.

Length: ~10 minutes. Three acts. No effort numbers — task families and sub-tasks only.

---

## Slide 2 — Act I divider

> **Act I — Research**
>
> *What Anthropic's article taught us about how self-service analytics actually works.*

Anthropic just publicly described the architecture behind their analytics agent: **95% of business questions answered automatically, ~95% accurate.** They shipped it on top of the same primitives we have — Claude, MCP, skills, dbt-style modeling, a metric layer — so the methodology transfers. The three slides in this section unpack their framework, their methodology, and the explicit trade-offs they observed.

---

## Slide 3 — Research finding 1: accuracy is a context + verification problem, not a code-generation problem

> *Three failure modes cause almost all the wrong answers.*

| # | Failure mode | Anthropic's observation |
|---|---|---|
| 1 | **Concept ↔ entity ambiguity** | Agent can't map "revenue" / "active user" / "FTD" to the one correct table + filter. |
| 2 | **Data staleness** | Without active maintenance, accuracy drops **95% → 65% in 1 month** as schemas change and definitions drift. |
| 3 | **Retrieval failure** | The right info is in the docs; the agent doesn't find it. Their experiment: giving Claude `grep` over thousands of analyst notebooks moved accuracy **<1 point. Structure beats volume.** |

**Implication for us:** every architectural choice on the next slide attacks one of these three failure modes. If a proposed component doesn't, it's not worth building.

---

## Slide 4 — Research finding 2: the four-layer stack that attacks each failure mode

| Layer | What it does | Attacks | Anthropic's bet |
|---|---|---|---|
| **Data foundations** | Canonical datasets, governance, colocation of skills with models | Ambiguity, staleness | Pre-validated, version-controlled tables — the only ones agents ever touch. |
| **Sources of truth** | Semantic layer first, then lineage, then query corpus, then business context | Ambiguity | Declarative metric layer is *the first move*, not the last. |
| **Skills** | A paired-skills model: **knowledge** skill (router) + **unbook** skill (process + analysis patterns) | Retrieval | Two skill types serve different jobs; structure replaces grep. |
| **Validation** | Offline evals (pinned), ablations, online provenance footer, active correction harvesting | All three | The eval gate (90% per domain) is non-negotiable before any agent ships to that domain's users. |

**The structural innovation we want to flag:** Anthropic uses **two skills per question** — one that routes to the right data (knowledge), one that drives the senior-analyst process (unbook). Most teams ship one. The decomposition itself is part of why their accuracy holds.

---

## Slide 5 — Research finding 3: the methodology and the observed trade-offs

> *The moves they make, and the costs they accept.*

**Methodology — what they do for every domain:**

- **Pin every eval to a snapshot date.** Write it against a stable fact table, or have the grader judge the agent's *query shape* — not its number — so refreshes don't break evals.
- **Ship a provenance footer on every answer.** Source tier (semantic layer › curated view › raw exploration), freshness, owner, skill+sha. Silent wrong answers are the highest-risk failure mode and the footer is what makes the silent default safe.
- **Active correction harvesting.** A scheduled agent reads Slack / feedback channels every few hours for correction language ("that's the wrong table"), drafts a one-line markdown fix, opens a PR tagged to the domain owner.
- **90% per-domain accuracy floor before announcement.** A domain owner *cannot* announce the agent to their stakeholders until their slice of the eval set clears the threshold.
- **Skill-touch CI hook.** 90% of their data-model PRs include a skill-file change in the same diff, enforced by CI.

**One trade-off they took and quantified:**

| Move | Observed lift | Observed cost |
|---|---|---|
| Mandatory adversarial review ("Challenge the Solution") on every answer | **+6% accuracy** | **+32% tokens / +72% latency** |

We carry this number into Act II — it's the basis for our one deliberate non-adoption.

---

## Slide 6 — Act II divider

> **Act II — Comparison**
>
> *Where eToro already stands against the Act I framework.*

Most of the build is done. The next three slides give the scorecard, the seven assets we already have, and the one deliberate non-adoption. The headline number: **5 green / 6 in-motion / 4 roadmap (1 of which is intentional non-adoption).**

---

## Slide 7 — How our stack maps to Anthropic's framework

| Anthropic layer | eToro today | Where it lives in the Act III roadmap |
|---|---|---|
| Canonical datasets | 🟢 `etoro_kpi` views own MIMO/AUM/PFOF; other domains route through canonical prep views + DDR | — |
| Skills + models colocation | 🟡 both live in `DataPlatform`; CI-enforcement hook in roadmap | Task family 2 — Model-Change Watcher |
| UC metadata as product | 🟢 column-level descriptions deployed across 6 domains | — |
| Semantic layer (declarative) | 🟡 not declarative yet — skills route to `etoro_kpi` canonical views, so ambiguity-collapse partially realized | Task family 6 — open decision |
| Lineage + table ranking | 🟢 Genie Code has UC lineage access | — |
| Query corpus | 🟡 captured (MCP + Genie gateway); distillation manual today | Task family 4 — Multi-Source Watcher Fleet |
| Business context | 🟡 SME / TVF docs in Synapse Wiki + Confluence; not piped to agents | Task family 4 — Multi-Source Watcher Fleet |
| **Skills (knowledge router)** | 🟢 hub-and-spoke; ~13 entry + 45 sub-skills; MCP-served, CI-validated | — |
| **Skills (unbook / process)** | 🟡 substance authored (3-skill triple in prod) — analyst-triggered today | Task family 6 — open decision |
| Offline evals | 🔴 not yet — but `/feedback` app already captures graded Q&A in production | Task family 1 — Truth Sensor |
| Ablation methodology | 🔴 not yet | Task family 1 + 5 |
| Provenance footer | 🔴 not yet on Genie / MCP responses | Task family 3 — Output Contract |
| Adversarial review on every answer | 🔴 **deliberate non-adoption** (see Slide 9) | Reject — semi-annual revisit only |
| Passive monitoring | 🟢 `genie_audit_events` + MCP gateway logs live | — |
| Active correction harvesting | 🟡 substrate ready (`/feedback` + MCP user-message logs) | Task family 4 — Multi-Source Watcher Fleet |

**Score: 5 green / 6 in-motion / 4 roadmap.** The roadmap reds are the *only* missing pieces; the green and in-motion items are the foundation everything else stands on.

---

## Slide 8 — What we already built that maps cleanly to Anthropic's framework

> *The seven assets we already have — including two that most teams would need to build from scratch.*

1. **Knowledge skill corpus.** Hub-and-spoke routing (`domain-*` hubs + `<hub>-<topic>.md` sub-skills), CI-enforced frontmatter, kebab-case names, required body sections. Identical shape to the Anthropic appendix skeleton.

2. **🚀 Unbook substance — decomposed better than Anthropic's.** The three-skill triple on Databricks Assistant (`data-analysis-playbook` + `data-analysis-patterns` + `data-analysis-pattern-library`) splits process from routing from detail, lazy-loading only the pattern-library entries the controller selects. Analyst-triggered today; auto-fire promotion is an open design decision (Task family 6).

3. **Skills + models in the same repo.** Both live in `DataPlatform`; skills are CI-deployed. Same colocation principle Anthropic endorses.

4. **Cross-surface portability.** Same skill served via MCP gateway → Cursor IDE, Genie Code, standalone agents.

5. **Telemetry foundations live.** `genie_audit_events` + `monitoring_mcp_logs_mcp_gateway` capture skill loads, NL prompts, generated SQL, query history joins.

6. **🚀 `/feedback` Databricks app — strategic asset.** Every Genie answer can be one-click graded by the user, capturing NL question + skills loaded + generated query + numbers + grade + free-text comment, landed in `main.de_output.de_output_genie_code_skill_feedback`. **The fastest path to a labeled eval set in the industry** — Anthropic synthesizes evals by hand; we harvest them in production with grades.

7. **UC as documented warehouse.** ~10k+ column comments deployed across 6 domains. Workspace-level assistant defaults (`.assistant_workspace_instructions.md`) anchor cross-Genie-Code behavior.

---

## Slide 9 — Our one deliberate non-adoption

> *Mandatory adversarial review on every answer — chosen against, with rationale and revisit cadence.*

**The Anthropic move:** enforce a *Challenge the Solution* sub-agent call on every analytical answer. Reported lift: **+6% accuracy / +32% tokens / +72% latency.**

**Why we're not adopting it:** the economics don't pencil at current model costs. A nearly-doubled response time on every Genie / MCP query — for a 6-point accuracy lift that's likely smaller for our use case because most of our questions are KPI-style rather than open-ended diagnostics — is not a trade users will accept on day-to-day questions.

**What we keep:** the *Challenge the Solution* pattern stays in `data-analysis-pattern-library` and is invoked **manually** by analysts on high-stakes analyses — board metrics, regulator-facing numbers, model-validation work. Same procedure, applied where the latency cost is justified.

**Revisit cadence:** every 6 months as model cost / latency curves move. If Claude latency drops 3x, or eval data shows our domain accuracy is below 80%, this becomes a "yes."

**Everything else on the roadmap is something we plan to do — this is the one item we chose not to do.**

---

## Slide 10 — Act III divider

> **Act III — Action Plan**
>
> *The roadmap. Everything we plan to do, broken into task families and sub-tasks.*

This is not a gap list. Every item below is a planned task family for H2 — a component of the autonomous system on Slide 11 that we're proposing to build. The roadmap is structured so that each task family is independently shippable and independently valuable, but the full set is what produces "the machine."

---

## Slide 11 — The machine: from static corpus to living business brain

> *The point of H2 is not to ship more skills. It's to stop authoring skills as one-off artifacts and start running them as the output of an autonomous system.*

**The shape of the machine:**

```
   INPUTS (sensors)                      ORCHESTRATION (judges + routers)              OUTPUTS (actions)
   ────────────────                     ──────────────────────────                     ──────────────────
   New Confluence docs       ─┐                                                  ┌──>  Draft skill PRs
   New SharePoint docs       ─┤                                                  │     (auto-tagged to
   UC schema changes         ─┤        ┌─────────────────────────┐               │      domain owner)
   (information_schema +     ─┼───>    │  Scheduled LLM           │      ────>   │
    UC lineage events)       ─┤        │  classifiers + routers   │              ├──>  Eval-set additions
   DataPlatform PRs touching ─┤        │                          │              │     (from /feedback +
    canonical models         ─┤        │  Eval gate (90% per      │              │      synthesized Q&A)
   MCP query telemetry       ─┤        │  domain) — accuracy SLA  │              │
   Genie audit events        ─┤        │                          │              ├──>  Schema-drift alerts
   /feedback 1–2★ + comments ─┘        │  Skill-touch CI hook     │              │     (to domain owner)
                                       │                          │              │
                                       │  Frequency-weighted      │              ├──>  Stale-skill flags
                                       │  Q-cluster prioritizer   │              │     (when source doc
                                       │                          │              │      deprecated / table
                                       └─────────────────────────┘               │      retired)
                                                                                 │
                                                                                 └──>  Accuracy dashboard
                                                                                       per domain owner
```

**Three rules of the machine:**

1. **Every input becomes a trigger.** A new Confluence page on KYC isn't a doc to be read — it's a signal to verify whether `domain-customer-and-identity` has the right routing.
2. **Every trigger becomes a PR or an eval.** No human-in-the-loop reading required to *detect* drift; humans review the draft PR or adjudicate the eval result. The machine does the boring work.
3. **The eval gate is the brain.** Nothing ships to a domain's stakeholders unless that domain's eval slice clears 90%. Skill quality is measured, not asserted.

**Five task families build this machine.** Slides 12–16 walk each one as a discrete component with sub-tasks.

---

## Slide 12 — Roadmap overview: six task families

| # | Task family | What it produces | First sub-task we'd ship |
|---|---|---|---|
| 1 | **Truth Sensor** — eval substrate | Pinned canonical Q&A set + per-domain accuracy dashboard | Synthesize the first eval slice from `/feedback` 4★+5★ submissions |
| 2 | **Model-Change Watcher** — skill-touch CI hook | Blocks canonical-view PRs that don't touch a skill | Single PR adding the CI rule on `DataPlatform` |
| 3 | **Output Contract** — provenance footer (= `final-answer-assembly` enforced) | Every MCP and Genie Code answer carries source tier + freshness + owner + skill@sha + confidence | MCP gateway middleware injection |
| 4 | **Multi-Source Watcher Fleet** *(the heart of the machine)* | Confluence / SharePoint / UC schema / UC lineage / MCP-correction watchers → draft skill PRs | MCP correction harvester (logs are live; lowest friction) |
| 5 | **Ablation-grade telemetry** | Per-skill / per-model / per-query observability that makes "did skill X help?" a SQL query | Enrich `monitoring_mcp_logs_mcp_gateway` schema |
| 6 | **Open design decisions** *(parked, not stuck)* | Resolved when the data justifies the choice | Promote `final-answer-assembly` to default output contract on `domain-*` hub queries |

Slides 13–15 detail the three task families with the most sub-task depth (Truth Sensor, Output Contract, Multi-Source Watcher Fleet). Task families 2 and 5 are small enough to ship in a single PR each; task family 6 is a list of open design decisions to resolve in H2 planning.

---

## Slide 13 — Task family 1: Truth Sensor (the eval substrate)

> *"Data teams set up elaborate analytic environments without any process to understand the accuracy of their analytics agents." — Anthropic*

**What it produces:** a pinned canonical Q&A eval set, run on every skill PR, gated at 90% per domain before an agent is announced to that domain.

**Why this task family ships first:** the `/feedback` app is already harvesting graded Q&A in production. The labeled data is already arriving every day. The substrate is the hardest part of Anthropic's methodology turned into our easiest part.

**Sub-tasks (in build order):**

1. **Harvest 4★ + 5★ submissions** from `main.de_output.de_output_genie_code_skill_feedback` → graded-correct canonical Q&A pairs. Pin each to the `created_at` snapshot. Grader checks SQL shape (canonical tables + canonical filters present), not the number.
2. **Harvest 1★ + 2★ submissions with free-text corrections** → active-correction stream. Each is a candidate skill-file edit (feeds task family 4).
3. **LLM-cluster the NL questions** per domain. Frequency-weighted Pareto — the top 30 question clusters per domain cover the long tail; build eval slices around them.
4. **Land all eval runs as telemetry** in a Delta table: `eval_id, skill_version_sha, model_id, run_ts, passed_bool, per_assertion_json, token_in/out, latency_ms`. "Did skill X help?" becomes a SQL query.
5. **Wire into CI** on every skill PR — run only the eval slice affected by the diff.
6. **Gate at 90%** per domain before announcing the agent to that domain's stakeholders.

**Dependencies:** none — the substrate is live. This task family is the foundation everything else measures against.

---

## Slide 14 — Task family 3: Output Contract (provenance footer)

> *Implementation = the `final-answer-assembly` pattern in our existing `data-analysis-pattern-library`, enforced at the output layer rather than analyst-invoked.*

**What it produces:** every user-facing answer carries a contract footer:

```
Source: semantic layer / curated view / raw exploration
Freshness: data through YYYY-MM-DD
Owner: <team>
Skill used: <skill_id>@<commit_sha>
Confidence: H / M / L
```

**Why this task family ships in parallel with the eval substrate:** silent wrong answers are the highest-risk failure mode. The footer is the online safety net while the eval gate is being built.

**Sub-tasks, by surface:**

| Surface | How | Status |
|---|---|---|
| **MCP gateway responses** | Append footer in the gateway middleware; we own the layer end-to-end. | One PR |
| **Genie Code (Databricks Assistant in notebooks)** | Two paths: (a) add the mandate to `.assistant_workspace_instructions.md` at workspace root — applies globally; or (b) push a dedicated `final-answer-assembly` skill into `/.assistant/skills/` so the Assistant always loads it. | Choose one of (a) / (b) |
| ~~Cursor IDE~~ | Skip — only our custom MCP sees skill-load context, so this is covered by the MCP row. | Covered |
| ~~Classic Genie Space~~ | Skip — no skill / instruction injection point yet; Databricks-controlled response surface. | Wait for Databricks |

**Adjacent design decision** (resolves into Task family 6): promote the same `final-answer-assembly` pattern to the default output mode for `domain-*` hub queries — the cheapest minimal-unbook auto-fire candidate. Three candidates ordered by cost: (a) `final-answer-assembly` alone (~+5–10% tokens, negligible latency); (b) +`metric-definition-check` (~+10–15% tokens, +5–10s); (c) +`question-framing` at intake (~+15–25% tokens, +10–20s on ambiguous questions). Recommendation: start with (a), let the eval gate justify (b) / (c).

---

## Slide 15 — Task family 4 (the heart of the machine): Multi-Source Watcher Fleet

> *The difference between a corpus authored once and forgotten and a corpus that continuously re-validates itself against every knowledge source in the company.*

**What it produces:** five parallel watchers, each sharing the same PR-draft framework, each turning a different signal into a domain-tagged draft skill PR.

**Sub-tasks — one strand per knowledge source:**

| Watcher | Trigger | Action |
|---|---|---|
| **MCP correction harvester** | Scheduled scan of `monitoring_mcp_logs_mcp_gateway` user messages for correction language ("that's wrong", "you forgot", "the right table is") + `/feedback` 1★/2★ comments | LLM classifier → domain-tagged draft PR with proposed skill-file edit |
| **Confluence new-page watcher** | Confluence webhook / scheduled diff on tagged spaces | LLM classifier asks: "does this change the routing for `domain-X`?" → draft PR if yes |
| **SharePoint new-doc watcher** | Scheduled scan of mapped SharePoint folders (the post-Fivetran source of truth for ops-authored reference data) | Same pattern as Confluence |
| **UC schema-delta watcher** | Daily diff on `system.information_schema.tables` + `.columns` | Renamed / dropped / added column → flag the skill(s) whose `required_tables` include that table |
| **UC lineage-delta watcher** | Daily diff on `system.access.column_lineage` | Upstream change → flag downstream skills' `required_tables` for review |

**Shared infrastructure (one build, five reuses):**
- LLM classifier with per-watcher prompts
- PR-draft framework (writes the edit, opens the PR, applies the domain-owner label)
- Domain-owner routing table (maps signal → owner)
- Suppression rules to avoid spammy PR storms on bulk events (schema migrations, etc.)

**Build order — easiest signal first:**
1. **MCP correction harvester** — logs live today, lowest friction, immediate ROI.
2. **UC schema-delta watcher** — `information_schema` is a 3-line query; alert-on-drift is the simplest possible classifier.
3. **Confluence / SharePoint watchers** — require API wiring but follow the same template.
4. **UC lineage-delta watcher** — most complex (lineage edges are sparse and noisy); ship last.

**Why this task family is the centerpiece:** task families 1 + 2 + 3 + 5 are operating-system infrastructure. Task family 4 is what makes the system *autonomous*. Without it, we still depend on a human noticing that a skill needs updating.

---

## Slide 16 — Task families 2, 5, 6: smaller scopes + open design decisions

**Task family 2 — Model-Change Watcher (skill-touch CI hook).** One PR. Detects PRs that modify canonical tables (`etoro_kpi.*`, DDR family, `bi_db_*` gold tables) and requires the diff to also touch the matching skill file. Auto-tags the domain owner if it doesn't. Anthropic's number for adoption rate: 90% of model PRs include a skill diff. **Stops silent skill rot the day it ships.**

**Task family 5 — Ablation-grade telemetry.** Enrich `monitoring_mcp_logs_mcp_gateway` and the Genie sibling logging table with:
- `skill_version_sha` (which exact version of the skill served the answer)
- `model_id` (which Claude / GPT / DBR-model produced it)
- `token_in` / `token_out` / `latency_ms`
- `correction_flag` (was a correction issued in the same session?)

Plus a `metric_flow_id` on the query history that ties together the eval run, the production answer, and the correction (if any). Makes the question *"is the new skill version better than the old one?"* a SQL query against telemetry, not an A/B study.

**Task family 6 — Open design decisions in the roadmap (parked, not stuck):**

| Decision | Recommendation | Resolution path |
|---|---|---|
| **Unbook auto-fire** — promote which minimal subset to auto-fire on every question? | Start with `final-answer-assembly` (candidate (a) on Slide 14); promote to `metric-definition-check` or `question-framing` only if the eval gate data justifies | Resolved by Truth Sensor data |
| **10-KPI UC-metric-view pilot** — declarative semantic layer wrapper on top of `etoro_kpi` canonical views? | Pilot 10 KPIs (FTD, MIMO net, AUM, NOP, daily volumes, registration funnel conversion, RAF success rate, options PFOF, fee revenue, refund chain) | H2 planning decision |
| **Adversarial review on every answer** — does the trade-off math change? | Hold the deliberate non-adoption; revisit semi-annually | Model cost / latency curves + per-domain accuracy data |

---

## Slide 17 — Asks of executive

### 1. (PRIMARY) Assign domain owners + commit them to the eval gate
The machine on Slide 11 has one human-in-the-loop role that **cannot be automated**: the domain owner who adjudicates ground truth for their slice of the eval set. Per Anthropic: *"A domain owner can't announce the agent to their stakeholders until their slice of the eval set clears some threshold."* Non-negotiable.

- **Internal teams** (Data Analytics, Product Analytics — already inside our org): can be **mandated**. We assign domain ownership, they sign off on the eval slice. No external dependency.
- **Cross-functional business domains** (Marketing, Trading Ops, Payments, US Ops, Compliance, etc.): needs leadership-level comms. The message: *"the machine will give your users wrong answers in your domain unless your team owns the eval slice. We build the substrate; you adjudicate ground truth."* Without this, we get to 75% on the four teams we own and stall.

### 2. Greenlight the machine's first watchers
- **Skill-touch CI hook** (Task family 2) on `DataPlatform`: one PR, no product impact, stops silent skill rot on canonical views immediately.
- **MCP correction harvester** (Task family 4, sub-task 1): scheduled job on logs that already exist — ready to start now.

### 3. Commit a baseline accuracy number for H2
Suggested floor: **75% on the top 4 domains by Q3, 90% by Q4** (using the `/feedback`-synthesized eval set). The machine without a target is just plumbing.

### 4. Decision on the 10-KPI UC-metric-view pilot
Yes / no on a thin semantic-layer pilot in H2 (Task family 6). We have the canonical views; this is the declarative wrapper on top.

---

## Slide 18 — One-page summary

**Act I — Research.** Anthropic's article shows that self-service analytics accuracy is a context + verification problem, not a code-generation problem. Three failure modes (ambiguity, staleness, retrieval) and a four-layer stack that attacks them. The methodology = pinned evals, provenance footer, active correction harvesting, 90% per-domain accuracy gate, skill-touch CI hook. Their one heavy trade-off (mandatory adversarial review) costs +32% tokens / +72% latency for +6% accuracy.

**Act II — Comparison.** We've already built most of it. Score: 5 green / 6 in-motion / 4 roadmap. Two strategic assets most teams don't have: the `/feedback` Databricks app (turns Anthropic's hardest problem — building evals — into our easiest), and the three-skill analysis triple (the substance of an unbook, decomposed better than theirs). One deliberate non-adoption: mandatory adversarial review on every answer — economics don't pencil at current model costs.

**Act III — Action Plan.** Build the machine. Six task families:
1. **Truth Sensor** — eval substrate synthesized from `/feedback` + per-domain 90% gate.
2. **Model-Change Watcher** — skill-touch CI hook (one PR).
3. **Output Contract** — provenance footer = `final-answer-assembly` enforced.
4. **Multi-Source Watcher Fleet** *(the heart of the machine)* — MCP corrections + Confluence + SharePoint + UC schema + UC lineage watchers → draft PRs.
5. **Ablation-grade telemetry** — enrich the logs so "did skill X help?" is a SQL query.
6. **Open design decisions** — unbook auto-fire / 10-KPI metric-view pilot / adversarial-review revisit cadence.

**Everything in this roadmap is something we plan to do. The only item we chose not to do is adversarial review on every answer — and that's revisited semi-annually as model cost and latency curves move.**

**The one-line story for execs:** *"We're not asking for budget to write more skills. We're asking for the green light to build the system that writes them — and the domain owners to staff its accuracy gate."*

---

## Appendix — sources

- Article: *How Anthropic enables self-service data analytics with Claude* — claude.com/blog, 2026-06-03.
- eToro internal: `proposals/skill-curation-from-nl-and-queries-2026-05-31.md`; `proposals/skills-mcp-protocol-parity-implementation-2026-06-03.md`; `dab/monitoring-genie-logs/`.
- Skill corpus (knowledge): `databricks/data-skills/skills/domain-*/` on `DataPlatform`.
- Skill corpus (unbook triple): `/.assistant/skills/data-analysis-playbook` + `data-analysis-patterns` + `data-analysis-pattern-library` on the Databricks Assistant workspace.
- Workspace assistant defaults: `/.assistant_workspace_instructions.md`.
- Telemetry: `main.config.monitoring_mcp_logs_mcp_gateway`, `main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway`, `main.monitoring.genie_audit_events`, `main.de_output.de_output_genie_code_skill_feedback`.
- Feedback skill: `knowledge/skills/feedback-command/SKILL.md` (DA-80 PR on `DataPlatform`).
- v1 deck (pre-restructure): `proposals/exec-deck-anthropic-self-service-analytics-2026-06-04.md`.
