# Skill curation pass — NL + queries — 2026-05-31

**Scope**: SEMANTIC DOMAIN skills only. The `data-analysis-*` family (approach/methodology helpers that ride alongside every query) is intentionally out of scope and not analyzed here.

Evidence base:
- **MCP gateway** (`main.config.monitoring_mcp_logs_mcp_gateway`), 30 days, 2,336 calls, 44 users, 8 client surfaces.
- **Genie gateway** (`main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway`), 7 days, 1,225 messages, 1,197 NL prompts, 524 generated SQL, 470 fully joined to `system.query.history`.

## Headline

- **The 4 new semantic domains aren't ghosts — they're a deploy backlog.** `domain-marketing-and-acquisition`, `domain-ops-and-onboarding`, `domain-product-analytics`, `domain-staking` are sitting in DataPlatform PR #3855 (`DA-76_deploy_4_new_domain_hubs`), **OPEN + MERGEABLE + all CI green + REVIEW_REQUIRED**. They got 0 hits in 30 days because they're not in the MCP corpus yet, not because the descriptions are bad. Action = nudge DE to review/merge; nothing to author. The 5th of that batch, `domain-spaceship`, was pushed earlier and is now live (8 hits since merge; 168 historical hits on the old `spaceship` ID pre-rename).
- **Customer Support, KYC questionnaire, document pipeline, A/B-tests, SFMC, position lifecycle** all have heavy NL traffic with no semantic sub-skill that catches them — the matcher dumps these into `domain-customer-and-identity` and the agent walks away with weak context.
- The Genie space `PROD - DDR` dominates traffic (331 msgs / 23 users) and is **127 SQL refs deep into one single table** (`main.etoro_kpi.ddr_customer_snapshot_scd_v`) — verify this is in `mimo-panel-and-ddr.required_tables`.

---

## P0 — Critical findings

### F1. RESOLVED — the 4 "ghost" domains are a deploy backlog, not a quality issue

**Diagnosis (2026-05-31)**:

| Skill | Returned-list hits (30d) | Live in DataPlatform `dev`? | Status |
|---|---|---|---|
| `domain-marketing-and-acquisition` | 0 | NO — sits in open PR #3855 | merge pending |
| `domain-ops-and-onboarding` | 0 | NO — sits in open PR #3855 | merge pending |
| `domain-product-analytics` | 0 | NO — sits in open PR #3855 | merge pending |
| `domain-staking` | 0 | NO — sits in open PR #3855 | merge pending |
| `domain-spaceship` | 8 | YES (merged ~2026-05-28) | active |
| `spaceship` (renamed → `domain-spaceship`) | 168 | NO (gone) | historical only |

PR #3855 (`DA-76_deploy_4_new_domain_hubs`) state at 2026-05-31 06:01 UTC: **OPEN, MERGEABLE, all CI green, `mergeStateStatus = BEHIND` (needs rebase), `reviewDecision = REVIEW_REQUIRED`**. The 4 new hubs got 0 hits in 30 days because they aren't in the MCP corpus yet — not because descriptions are weak, not because embeddings are stale.

The NL-prompt evidence below is now **future validation**: once PR #3855 merges and the MCP `POST /admin/refresh` (5-min poll) picks up the new corpus, re-measure these 8 prompts and confirm they route correctly.

| User | NL prompt (truncated) | Expected after merge |
|---|---|---|
| thomasba@ | "Marketing campaigns, events, webinars, attendance, RM/AM client touchpoints, VIP outreach, roadshows…" | `domain-marketing-and-acquisition` |
| thomasba@ | "tables in main.crm, main.crm_stg, main.sfmc, and main.marketing? Salesforce Campaign, CampaignMember, Contact, Lead, Marketing Cloud event/journey/subscriber" | `domain-marketing-and-acquisition` |
| pinikr@ | "SFMC marketing email report query" | `domain-marketing-and-acquisition` |
| pinikr@ | "email click distribution per user, high engagers, marketing campaign analysis" | `domain-marketing-and-acquisition` |
| pavlinama@ | "UAE V3 drop - document upload gap and risk alert screening backlog funnel analysis" | `domain-ops-and-onboarding` |
| pavlinama@ | "UAE document rejection reasons breakdown and POA gap analysis" | `domain-ops-and-onboarding` |
| guyve@ | "staking pool: staked units, eligible units, opted-in units and opted-out per crypto asset…" | `domain-staking` |
| guyve@ | "crypto staking LUKKA eligible units holdings by regulation and asset" | `domain-staking` |

**Action**: nudge DE reviewer on PR #3855. Re-run this audit ~24 hours after merge to confirm matching works. If any of the 8 prompts above still miss after merge + refresh, *then* re-open as a description-quality issue.

### F2. RESOLVED — `domain-compliance-and-aml` local-vs-deployed frontmatter drift

**Diagnosis**: local `knowledge/skills/domain-compliance-and-aml/SKILL.md` had stale frontmatter (`id: domain-compliance-and-aml` + `name: "Compliance & AML Super-Domain"`) from before the May 2026 DD-1747 schema reshape. The deployed copy at `DataPlatform/databricks/data-skills/skills/domain-compliance-and-aml/SKILL.md` was already correct (`name: domain-compliance-and-aml`, no `id:`).

The MCP corpus was never affected — this was strictly local source drift.

**Action**: applied 2026-05-31. Local frontmatter now matches deployed. No push needed.

---

## P1 — Missing sub-skills (with evidence)

### NS1. Tune `crm-cases-csat-and-churn` (already exists but never returned)

The sub-skill exists and gets 4 trigger-word hits in 30 days, but it never makes it into `returned_skill_ids` top-N for the 20+ Salesforce-case NL prompts (eleftheriats@, kostasha@, christosts@, dianada@, barryco@, rebeccamie@…).

**Evidence — NL phrases:**
- "Salesforce cases in Routing status with CS General support and Premium skill"
- "Salesforce cases handled by an agent this month"
- "CaseSkills LIKE '%General Support%' THEN 'General Support'…"
- "CSAT survey low score chat case origin agent handle time messaging session"
- "messaging session transfers case events routing agentwork accept time"
- "case details emails comments history audit trail export"
- "CaseOwnerTitle = 'OPS'… number of SF tickets created for FCMU"
- "Tmail / IsOfficialComplaint"

**Action**: re-anchor description and add these literal triggers: `Salesforce case`, `CaseSkills`, `CaseOwnerTitle`, `CSAT`, `Tmail`, `IsOfficialComplaint`, `messaging session`, `agentwork`, `case origin Manual / BO`, `FCMU`, `Premium support`, `General Support`, `skillset`, `case handling time`. Add `silver_crm_case`, `silver_crm_messagingsession`, `etoro_kpi.crm_case_v` to `required_tables`.

### NS2. New: `kyc-questionnaire-and-suitability` (under `domain-customer-and-identity` or `domain-compliance-and-aml`)

13 SQL refs to `main.etoro_kpi.kyc_for_compliance_v` (top compliance table). 8+ NL prompts in Compliance Genie about KYC question text/IDs/answers/scoring.

**Evidence:**
- "please show me all kyc questions - text and question ID"
- "Restricted investor questions… how many answered Yes"
- "Provide answers and scoring CID 3973273 achieved as part of the experience and objectives questionnaire"
- "Show me all KYC questions - text and question ID - and answers for CID 3973273"
- "passed appropriateness/suitability questions"

### NS3. New: `position-lifecycle-and-duration` (under `domain-trading`)

7 refs to `etoro_kpi.positions_for_compliance_v`, 6 refs to `data_rooms.vw_dim_position`. 6+ "median duration of positions in days" prompts.

### NS4. New: `document-pipeline-and-vendors` (under `domain-ops-and-onboarding`)

5 refs to `bi_output_stg.bi_output_operations_documentanalysis`. Multiple NL prompts about Onfido / Sumsub / AI / POI / POA / system-classified vs user-uploaded documents / V2→V3.

**Evidence:**
- "how many documents in % are sent to AI vs different vendors? AI Error rate"
- "since 12th May how many documents were sent to vendors from Germany, UK, Italy and France"
- "how many POI and POA documents were uploaded in total in May for Verification level 2 and level 3 clients"
- "give a few CIDs where the Proof of address document is classified by 'System'"
- "UAE — V2→V3: 18.9% vs 20.8% — POA is the problem"

**Bonus**: this would also wake `domain-ops-and-onboarding` by giving it a strong matched child.

### NS5. New: `abtoro-experiments` (under `domain-product-analytics`)

18 SQL refs across `product_analytics_stg.bi_output_product_analytics_abtoro_*` tables (3 distinct). ABtoro Genie space had 17 messages.

**Bonus**: wakes `domain-product-analytics`.

### NS6. New: `sfmc-email-campaigns` (under `domain-marketing-and-acquisition`)

3 refs to `sfmc.silver_sfmc_clicks` + `bi_output.bi_output_marketing_sfmc_sfmc_report`. SFMC space "SFMC Campaign Engagement & Conversion Analysis" had 5 messages.

**Evidence:**
- "SFMC marketing email report query"
- "analyze marketing email campaign clickers from SFMC report"
- "email click distribution per user, high engagers, marketing campaign analysis"

**Bonus**: wakes `domain-marketing-and-acquisition`.

### NS7. New: `bounced-email-and-case-comments-forensics` (under `crm-cases-csat-and-churn` or sibling)

8+ kostasha@ + eleftheriats@ queries about mailer-daemon bounces, mail delivery system errors in cases, case-comment-text content classification.

**Evidence:**
- "bounce email mailer-daemon case agent manager desk full list"
- "Find Salesforce cases that received Mail Delivery System errors, with case number, status, owner, and error details from email bounce backs" (asked 2x)
- "email message text body bounce error" (5 variants)
- "case comments history email messages related cases"

---

## P2 — Existing hub tuning

### TT1. `customer-populations` is a sponge (over-matched)

251 returned-list hits, returns even for KYC/Cyprus regulation, Salesforce cases, NOP positions. Tighten the description to **only** population-definition questions (V1/V2/V3, valid users, registration cohorts, lifecycle states).

### TT2. `registration-to-ftd-funnel` over-matched for payment questions

196 hits, returns for "FTD by payment method", "withdrawal categorization" — but those are payment-side queries that belong to `domain-payments`. Sharpen the boundary in the description.

### TT3. `instruments` matches too narrowly

78 hits, fires almost only when the literal phrase "instrument ID" appears. Broaden triggers to include `asset`, `ticker`, `symbol`, `asset class`, `crypto pair`, `CFD`, `equity`, `commodity`, `FX pair`, `index`.

### TT4. `domain-compliance-and-aml` under-matches the compliance Genie space

36 hits in 30d vs the Compliance Genie space alone having 76 NL prompts in 7 days. The hub description leans AML-heavy; the actual traffic is regulator-scoped customer/position population queries (FCA / CySEC / ASIC / MAS / BVI / appropriateness / suitability / restricted investor).

**Action**: rewrite description to include regulator names and "regulatory reporting" / "restricted investor" / "appropriateness" / "suitability".

---

## P2 — UC table coverage audit

Top-19 most-queried tables in the Genie 7-day window. Verify each is claimed in the right skill's `required_tables`:

| UC table | Refs | Should be claimed by |
|---|---|---|
| `main.etoro_kpi.ddr_customer_snapshot_scd_v` | 128 | `mimo-panel-and-ddr` |
| `main.etoro_kpi.ddr_revenue_v` | 54 | `trading-revenue-and-fees` |
| `main.etoro_kpi.ddr_customer_dailystatus` | 42 | `customer-populations` |
| `main.etoro_kpi.vg_dealing_clicks_openclose_breakdown` | 29 | `dealing-investigation-and-execution` |
| `main.etoro_kpi.ddr_mimo_v` | 25 | `mimo-panel-and-ddr` |
| `main.etoro_kpi.kyc_for_compliance_v` | 13 | **NS2 (new)** |
| `main.etoro_kpi.vg_customer_customer_first_dates` | 10 | `customer-populations` |
| `main.etoro_kpi.ddr_trading_volumes_and_amounts_v` | 9 | `trading-volumes` |
| `main.etoro_kpi.ftd_funnel_v` | 9 | `registration-to-ftd-funnel` |
| `main.product_analytics_stg.bi_output_product_analytics_abtoro_experiment_participants` | 9 | **NS5 (new)** |
| `main.etoro_kpi.customer_snapshot_v` | 8 | `customer-populations` |
| `main.etoro_kpi.cfd_statusinfo_v` | 7 | `domain-trading` / compliance |
| `main.etoro_kpi.positions_for_compliance_v` | 7 | **NS3 (new)** |
| `main.etoro_kpi.ddr_aum_v` | 7 | `portfolio-value` (aum/pnl) |
| `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie` | 7 | eMoney sub-skill (verify exists) |
| `main.product_analytics_stg.bi_output_product_analytics_abtoro_storage_experiments_md` | 7 | **NS5 (new)** |
| `main.bi_output.vg_emoney_card_instance_summary` | 6 | `domain-payments` / eMoney sub |
| `main.data_rooms.vw_dim_position` | 6 | `domain-trading` |
| `main.bi_output_stg.bi_output_operations_documentanalysis` | 5 | **NS4 (new)** |

---

## Recommended order of operations

P0 status as of 2026-05-31:
- **F1 = unblocked by external action.** Nothing for us to do until PR #3855 merges. Re-measure ~24h after merge.
- **F2 = applied.** Local file fixed; deployed file was already correct.

Remaining work:

1. **Author NS4, NS5, NS6** in that order — each one ALSO seeds a sub-skill under one of the 4 dormant new domain hubs (NS4 → ops-and-onboarding, NS5 → product-analytics, NS6 → marketing-and-acquisition), so they're well-positioned to ship in a follow-up PR right behind #3855.
2. **Author NS1 description tuning + NS2, NS3, NS7** — addresses the heaviest underserved traffic (CS + compliance + position lifecycle).
3. **TT1-TT4** existing-hub tuning — last, because it's a sharpening pass that needs to land after the new sub-skills are in place (otherwise the now-deflected traffic has nowhere to go).
4. **UC table coverage audit** — bottom-up cross-check.

---

## Caveats

- **30d MCP traffic** is biased toward power users (44 distinct emailers). Some skills may legitimately be lightly used because their domain is light. Don't kill anything based on low usage alone; check trend over a longer window when the index has accumulated more data.
- **`skills_top_score` is NULL on most rows even when matches succeeded** — the score field doesn't seem to be persisted by the gateway writer for the multi-skill return path. This is a logging bug, not a matcher bug. Worth filing separately.
- **Genie's `client_application = 'DatabricksGenie'` (agent mode) does NOT route through MCP**, so there's no skill-matching telemetry for those 369 captured agent-mode messages. The NL signal is still usable for trigger-word mining though.
