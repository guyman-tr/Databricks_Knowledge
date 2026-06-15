# From static corpus to living business brain
### Self-service analytics at eToro — where we stand vs Anthropic, and how we build the machine
### Executive deck — 2026-06-04 (rev 5)

Source comparison: *How Anthropic enables self-service data analytics with Claude* (Anthropic blog, 2026-06-03), benchmarked against the eToro Data Platform skills + UC + Genie + MCP stack as of today.

Audience: Data leadership / Eng leadership / cross-functional analyst-team leads.
Length: ~10 minutes.

---

## Slide 1 — Why this matters

- Anthropic just publicly described the architecture behind their analytics agent: **95% of business questions answered automatically, ~95% accurate.**
- They shipped this on top of the same primitives we have: Claude, MCP, skills, dbt-style modeling, a metric layer.
- We've built **~80% of the same stack** already — including two assets most teams would need to build from scratch.
- **The strategic shift for H2: stop treating the skill corpus as a static artifact and start running it as a living machine — one that watches every knowledge source in the company, judges itself with telemetry, and updates itself.**
- **The ask of this deck: align on the machine we're building + commit to a measurable accuracy floor.**

---

## Slide 2 — Anthropic's framework

> Self-service analytics accuracy is **a context + verification problem, not a code-generation problem.**

**Three failure modes** that cause almost all wrong answers:

1. **Concept ↔ entity ambiguity** — agent can't map "revenue" / "active user" / "FTD" to the one correct table + filter.
2. **Data staleness** — schemas change, definitions drift, docs rot. Anthropic measured a **95% → 65% accuracy drop in 1 month** without active maintenance.
3. **Retrieval failure** — the right info is in the docs, agent doesn't find it. Their experiment: giving Claude grep over thousands of analyst notebooks moved accuracy <1 point. **Structure beats volume.**

**Four-layer stack** that attacks each:

| Layer | Attacks | Anthropic's bet |
|---|---|---|
| Data foundations | Ambiguity, staleness | Canonical datasets, enforced governance, colocation |
| Sources of truth | Ambiguity | **Semantic layer FIRST**, then lineage, then query corpus, then business context |
| Skills | Retrieval | Pairwise: **knowledge** skill (router) + **unbook** skill (process + analysis patterns) |
| Validation | All three | Offline evals (pinned), ablations, online provenance + correction harvesting |

---

## Slide 3 — Our scorecard

| Anthropic layer | eToro today | H2 priority |
|---|---|---|
| Canonical datasets | 🟡 `etoro_kpi` views own MIMO/AUM/PFOF; other domains route through overlapping views + DDR + Synapse TVFs | Med |
| Skills + models colocation | 🟡 both live in `DataPlatform`; missing CI hook that *enforces* skill-touch on model PRs | **High** |
| UC metadata as product | 🟢 column-level descriptions deployed across 6 domains; ambivalent on retrieval lift | Low |
| Semantic layer (declarative) | 🟡 no declarative metric layer — *but* skills route to `etoro_kpi` canonical views first, so ambiguity-collapse is partially realized | **High** |
| Lineage + table ranking | 🟢 Genie Code has UC lineage access | — |
| Query corpus | 🟡 captured (MCP + Genie gateway); distillation manual today | Med |
| Business context | 🟡 SME / TVF docs in Synapse Wiki + Confluence; not piped to agents | Low |
| **Skills (knowledge router)** | 🟢 hub-and-spoke; ~13 entry + 45 sub-skills; MCP-served, CI-validated | Maintain |
| **Skills (unbook / process)** | 🟡 substance authored (3-skill triple in prod: playbook + patterns + pattern-library) — by-design **analyst-triggered today**, not auto-fired on every question. Open H2 design decision: which minimal element to promote to auto-fire. | Open |
| Offline evals | 🔴 none today — *but* `/feedback` app already captures graded Q&A in production | **Highest** |
| Ablation methodology | 🔴 none | Build with evals |
| Provenance footer | 🔴 none on Genie / MCP responses | **High** |
| Adversarial review on every answer | 🔴 deliberately **not adopted** — +32% tokens / +72% latency / +6% accuracy doesn't pencil at current model costs. Pattern exists in library for analyst-triggered use. | **Reject** |
| Passive monitoring | 🟢 `genie_audit_events` + MCP gateway logs live | Enrich + dashboard |
| Active correction harvesting | 🟡 substrate exists (`/feedback` app + MCP user-message logs); missing scheduled classifier + PR-draft agent | **High** |

Score: **5 green / 6 yellow / 4 red.**
*1 red is a deliberate non-adoption with rationale, not a gap.*

---

## Slide 4 — What we're doing RIGHT

1. **Knowledge skill corpus.** Hub-and-spoke routing (`domain-*` hubs + `<hub>-<topic>.md` sub-skills), CI-enforced frontmatter / kebab-case names / required body sections. Identical shape to the Anthropic appendix skeleton.

2. **Unbook *substance* in production — decomposed even better than Anthropic's.** The three-skill triple on Databricks Assistant (`data-analysis-playbook` + `data-analysis-patterns` + `data-analysis-pattern-library`) splits process from routing from detail, lazy-loading only the pattern-library entries the controller selects. **Caveat:** this is by-design analyst-triggered (expert keywords + `team-analytics` owner). Anthropic's lift comes from auto-firing on every question; that decision is open for us. See Slide 7.

3. **Skills + models in the same repo.** Both live in `DataPlatform`; skills are CI-deployed. Same colocation principle Anthropic endorses — what's still needed is the enforcement hook.

4. **Cross-surface portability.** Same skill served via MCP gateway → Cursor IDE, Genie Code, standalone agents.

5. **Telemetry foundations live.** `genie_audit_events` + `monitoring_mcp_logs_mcp_gateway` capture skill loads, NL prompts, generated SQL, query history joins.

6. **🚀 `/feedback` Databricks app — strategic asset.** Every Genie answer can be one-click graded by the user, capturing NL question + skills loaded + generated query + numbers + grade + free-text comment, landed in `main.de_output.de_output_genie_code_skill_feedback`. **Fastest path to a labeled eval set in the industry** — Anthropic synthesizes evals by hand; we harvest them in production with grades.

7. **UC as documented warehouse.** ~10k+ column comments deployed across 6 domains.

8. **Workspace-level assistant defaults exist.** `.assistant_workspace_instructions.md` at the Databricks workspace root is the lever for cross-Genie-Code behavior — already where the analysis triple is anchored.

---

## Slide 5 — What we're doing WRONG (gaps)

### Gap 1 — We cannot measure our accuracy yet
> "Data teams set up elaborate analytic environments without any process to understand the accuracy of their analytics agents." — Anthropic

**Zero pinned Q&A evals today.** We don't know if our agents are at 21% or 95%. Every gap below is invisible without this number.

*But* — we already capture graded Q&A in production via the `/feedback` app. The path to an eval set is **synthesize from the feedback table**, not author from scratch.

### Gap 2 — Skill ↔ model drift has no CI guard
Anthropic: **90% of their data-model PRs include a skill-file change in the same diff**, enforced by a CI hook. Our skills + models live in the same repo, but no CI rule says *"this PR touches `etoro_kpi.*` — please also touch the matching skill file."* Every canonical-view change silently rots the skill that points at it.

### Gap 3 — No provenance, no online safety net
Every Anthropic response carries a footer: source tier (semantic layer › curated view › raw exploration), freshness, owner, skill used. We ship raw numbers from Genie / MCP with **no signal** about confidence, source, or staleness. **Silent wrong answers are our highest-risk failure mode** and we have no mitigation.

**Key insight:** the `final-answer-assembly` pattern in our existing `data-analysis-pattern-library` already specifies leading-with-the-answer + confidence tag + metric definition. Provenance footer = that pattern, enforced as a mandatory output contract. So Gap 3 + the "unbook auto-fire" decision collapse into one cheap fix. See Slide 9.

### Gap 4 — No active correction loop (yet)
Anthropic has a scheduled agent scanning Slack / feedback channels every few hours for correction language ("that's the wrong table", "you forgot the fraud filter"), drafting one-line markdown fixes, opening PRs tagged to the domain owner.

We have the **substrate**: the `/feedback` app captures explicit corrections; MCP user-message logs contain implicit corrections. What's missing is the scheduled classifier + PR-draft agent on top. **MCP harvest is ready to start today**; Genie Code via our enrichment pipeline; classic Genie Space waits for Databricks to ship logs (currently no log surface — outside our control).

---

## Slide 6 — What we're DELIBERATELY NOT adopting

### Mandatory adversarial review on every answer
Anthropic enforces a *Challenge the Solution* sub-agent call on every analytical answer. Their reported lift: **+6% accuracy / +32% tokens / +72% latency.**

**Our position:** the economics don't pencil at current model costs. A nearly-doubled response time on every Genie / MCP query — for a 6-point accuracy lift that's likely smaller for our use case because most of our questions are KPI-style, not open-ended diagnostics — is not a trade users will accept on day-to-day questions.

**What we keep:** the *Challenge the Solution* pattern stays in `data-analysis-pattern-library` and is invoked **manually** by analysts on high-stakes analyses (board metrics, regulator-facing numbers, model-validation work). Same procedure, applied where the latency cost is justified.

**Revisit:** every 6 months as model cost / latency curves move. If Claude latency drops 3x or eval data shows our domain accuracy is below 80%, this becomes a "yes."

---

## Slide 7 — The open H2 design decision

> *Anthropic's unbook fires on every question. Ours is analyst-triggered. Should we promote a minimal subset to auto-fire?*

**Three candidates, ordered by cost:**

| Candidate | What it does | Token cost | Latency cost | What it buys |
|---|---|---|---|---|
| **(a) `final-answer-assembly`** | Mandatory output template: lead with answer + confidence H/M/L + metric definition + (eventually) provenance footer | ~+5–10% | negligible | Subsumes Gap 3. Cheapest. |
| **(b) `metric-definition-check` + `final-answer-assembly`** | At deliver-time: re-state the metric the query computes; flag if it diverges from the user's likely intent. | ~+10–15% | +5–10s | Attacks ambiguity (Anthropic's failure mode #1) at output time, not just at planning time. |
| **(c) `question-framing` at intake + `final-answer-assembly` at deliver** | At first turn: surface ambiguous terms ("last week"? "active"? "users"?) and ask one targeted clarifying question. At end: assembly contract. | ~+15–25% | +10–20s on ambiguous questions | Maps closest to Anthropic's pattern — clarify before answering. |

**Recommendation:** start with (a), measure via the eval gate (Slide 8), promote to (b) or (c) only if the data justifies it. **The fix is small** — `data-analysis-patterns` already has a "Communication-only" output mode that's basically (a); making it the default for `domain-*` hub queries is a routing change, not a content-authoring effort.

**Why this matters now:** the 7-step heavyweight loop stays where it should — analyst-triggered for non-trivial analyses. We're not asking every user question to compile through a senior-analyst process; we're asking every *answer* to ship in a known shape.

---

## Slide 8 — The shortcut: synthesize evals from the `/feedback` app

> "Pin every eval to a snapshot date, write it against a stable fact table, or have the grader judge the agent's *query* rather than its number." — Anthropic

**Why this is the single biggest H2 win:**

The `/feedback` app already captures, per submission:
- NL question
- Skills the agent loaded
- SQL the agent generated
- Numeric result
- User grade (1–5 ★)
- Optional free-text correction

Pareto eval-set construction:

1. **Take all 4★ + 5★ submissions** → graded-correct canonical Q&A pairs. Pin each to the `created_at` snapshot. Grader checks SQL shape (canonical tables + canonical filters present), not number.
2. **Take all 1★ + 2★ submissions with corrections** → active-correction-harvest source. Each is a candidate skill-file edit.
3. **Frequency-weight by NL-question similarity** (LLM clustering on the NL field) — the top 30 question clusters per domain cover the long tail; build eval slices around them.
4. **Land all eval runs as telemetry** in a Delta table: `eval_id, skill_version_sha, model_id, run_ts, passed_bool, per_assertion_json, token_in/out, latency_ms`. "Did skill X help?" becomes a SQL query.
5. **Wire into CI** on every skill PR — run only the eval slice affected by the diff.
6. **Gate at 90%** per domain (Anthropic's threshold) before announcing the agent to that domain's stakeholders.

This collapses the "build an eval harness from nothing" effort because the labeled data is already arriving every day.

---

## Slide 9 — Provenance footer — surfaces in scope

Anthropic appends a footer to every user-facing answer:
```
Source: semantic layer / curated view / raw exploration
Freshness: data through YYYY-MM-DD
Owner: <team>
Skill used: <skill_id>@<commit_sha>
```

**Our implementation = the `final-answer-assembly` pattern enforced** (Slide 7 candidate **(a)**). Same pattern that's already documented in `data-analysis-pattern-library`; just made mandatory at the output layer rather than analyst-invoked.

| Surface | How | Status |
|---|---|---|
| **MCP gateway responses** | Append footer in the gateway middleware; we own the layer end-to-end. | Easy, one PR |
| **Genie Code (Databricks Assistant in notebooks)** | Two options: (a) add the mandate to `.assistant_workspace_instructions.md` at workspace root — applies globally; or (b) push a dedicated `final-answer-assembly` skill into `/.assistant/skills/` so the Assistant always loads it. | Medium |
| ~~Cursor IDE~~ | Skip — only our custom MCP sees skill-load context anyway, so this is covered by the MCP row. | n/a |
| ~~Classic Genie Space~~ | Skip — no skill / instruction injection point yet; Databricks-controlled response surface. Wait for product. | Out of scope |

---

## Slide 10 — The machine: from static corpus to living business brain

> *The point of H2 is not to "ship more skills." It's to stop authoring skills as one-off artifacts and start running them as the output of an autonomous system.*

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

**What this changes in practice:**

- Today: domain owner authors a skill, it ships, it rots silently until someone notices a wrong answer.
- Machine: skill goes out, every input source (docs, schema, telemetry) continuously probes it, drift opens a PR within hours, the eval gate refuses to publish a regression.

---

## Slide 11 — H2 plan: building the machine, component by component

Each H2 priority is **one component** of the machine on Slide 10:

| # | Component | What it does | Status today |
|---|---|---|---|
| 1 | **Truth sensor — Eval substrate** | Synthesize eval set from `/feedback` (4★+5★ → canonical pairs; 1★+2★ → corrections). CI gate at 90% per domain. | Substrate live in `/feedback` app; harvester + gate logic to be built. |
| 2 | **Model-change watcher — Skill-touch CI hook** | Block any `DataPlatform` PR that changes canonical tables / prep views without touching the matching skill file. | New, single PR. |
| 3 | **Output contract — Provenance footer = `final-answer-assembly` enforced** | Every answer ships with confidence + metric definition + source tier + skill_id@sha (MCP + Genie Code via assistant instructions). | Pattern authored in library; routing change only. |
| 4 | **Multi-source watcher fleet** — *the big one* | Scheduled jobs that watch and trigger: (a) MCP user-message logs + `/feedback` 1–2★ for correction language; (b) new Confluence pages tagged to a domain; (c) new SharePoint docs in mapped folders; (d) UC schema changes via `system.information_schema` + `system.access.column_lineage` deltas. Each watcher → LLM classifier → draft skill-file PR tagged to domain owner. | New. MCP-correction strand can start now (logs are live); Confluence + SharePoint + UC strands require new harvesters but reuse the same PR-draft framework. |
| 5 | **Ablation-grade telemetry** *(bonus)* | Enrich `monitoring_mcp_logs_mcp_gateway` + Genie sibling table with `skill_version_sha`, `model_id`, `token_in/out`, `latency_ms`. | New columns + writer changes. |
| OPEN | **10-KPI UC-metric-view pilot** | Yes / no on a thin declarative semantic layer on top of `etoro_kpi`. Decision in H2 planning. | Open. |

**Component #4 is the heart of the machine** — it's the difference between a corpus that's authored once and forgotten and a corpus that re-validates itself against every knowledge source in the company.

**Not on the list:**
- Adversarial review enforcement on every answer (Slide 6 — deliberate non-adoption).
- Promoting the full unbook triple to auto-fire (Slide 7 — open beyond candidate (a)).

---

## Slide 12 — Asks of leadership

### 1. (THE PRIMARY ASK) Assign domain owners + commit them to the eval gate
The machine on Slide 10 has one human-in-the-loop role that **cannot be automated**: the domain owner who adjudicates ground truth for their slice of the eval set. Per Anthropic: *"A domain owner can't announce the agent to their stakeholders until their slice of the eval set clears some threshold."* Non-negotiable.

- **Internal teams** (Data Analytics, Product Analytics — already inside our org): can be **mandated**. We assign domain ownership, they sign off on the eval slice. No external dependency.
- **Cross-functional business domains** (Marketing, Trading Ops, Payments, US Ops, Compliance, etc.): needs leadership-level comms. The message: *"the machine will give your users wrong answers in your domain unless your team owns the eval slice. We build the substrate; you adjudicate ground truth."* Without this, we get to 75% on the four teams we own and stall.

### 2. Greenlight the machine's first watchers
- **Skill-touch CI hook** on `DataPlatform`: one PR, no product impact, stops silent skill rot on canonical views immediately.
- **MCP correction harvester**: scheduled job on logs that already exist — ready to start now.

### 3. Commit a baseline accuracy number for H2
Suggested floor: **75% on the top 4 domains by Q3, 90% by Q4** (using the `/feedback`-synthesized eval set). The machine without a target is just plumbing.

### 4. Decision on the 10-KPI UC-metric-view pilot
Yes / no on a thin semantic-layer pilot in H2. We have the canonical views; this is the declarative wrapper on top.

---

## Slide 13 — One-page summary

**The big idea**: We're done authoring skills as static artifacts. H2 is about building **the machine** — an autonomous knowledge system that watches Confluence, SharePoint, UC schema, MCP/Genie telemetry, and `/feedback` grades, and turns every signal into a draft skill PR or an eval-set entry, gated by a per-domain accuracy SLA.

**Where we are**: 5 green / 6 yellow / 4 red against Anthropic's framework — and one of the reds is a deliberate non-adoption. Skills (knowledge + unbook substance) + telemetry + repo colocation + the `/feedback` app are the real strengths.

**Two assets most teams don't have**:
- The `/feedback` Databricks app — turns the hardest part of Anthropic's methodology (eval-building) into our easiest part.
- The three-skill analysis triple — the *substance* of an unbook, decomposed better than Anthropic's. Analyst-triggered today; we may promote one cheap subset (`final-answer-assembly`) to auto-fire.

**One thing we're rejecting on purpose**: mandatory adversarial review on every answer — economics don't pencil. Pattern stays for manual high-stakes use.

**The machine has five components (Slide 11)**:
1. Truth sensor (eval substrate from `/feedback`)
2. Model-change watcher (skill-touch CI hook)
3. Output contract (`final-answer-assembly` enforced)
4. **Multi-source watcher fleet** (MCP corrections + Confluence + SharePoint + UC schema deltas → draft PRs) — the heart of the machine
5. Ablation-grade telemetry

**Open**: 10-KPI UC-metric-view pilot.

**The one-line story for execs**: *"We're not asking for budget to write more skills. We're asking for the green light to build the system that writes them — and the domain owners to staff its accuracy gate."*

---

## Appendix — sources

- Article: *How Anthropic enables self-service data analytics with Claude* — claude.com/blog, 2026-06-03.
- eToro internal: `proposals/skill-curation-from-nl-and-queries-2026-05-31.md`; `proposals/skills-mcp-protocol-parity-implementation-2026-06-03.md`; `dab/monitoring-genie-logs/`.
- Skill corpus (knowledge): `databricks/data-skills/skills/domain-*/` on `DataPlatform`.
- Skill corpus (unbook triple): `/.assistant/skills/data-analysis-playbook` + `data-analysis-patterns` + `data-analysis-pattern-library` on the Databricks Assistant workspace.
- Workspace assistant defaults: `/.assistant_workspace_instructions.md`.
- Telemetry: `main.config.monitoring_mcp_logs_mcp_gateway`, `main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway`, `main.monitoring.genie_audit_events`, `main.de_output.de_output_genie_code_skill_feedback`.
- Feedback skill: `knowledge/skills/feedback-command/SKILL.md` (DA-80 PR on `DataPlatform`).
