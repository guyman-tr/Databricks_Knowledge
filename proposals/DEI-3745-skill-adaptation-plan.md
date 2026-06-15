# DEI-3745: Adapting our skill corpus to the new MCP routing

**Branch read:** `origin/Feature/DEI-3745_adjust_the_mcp_skill_tools_to_work_with_the_new_hierarchy`
**Headline commit:** `74a028b18 feat(skills-mcp, gateway): DEI-3745 sub-skills routing v1 (hub-and-spoke)`
**Source snapshot:** `proposals/DEI-3745-mcp-snapshot/` (12 files dumped via `git show`, not the live checkout)

---

## Scope note (corrected post-review)

The deployed skill corpus that the MCP actually loads lives at
**`DataPlatform/databricks/data-skills/skills/`** (we keep a local clone of that
repo on disk). The MCP's `SKILLS_MCP_URL` points the loader at that directory,
not at this `Databricks_Knowledge` repo. `Databricks_Knowledge/knowledge/skills/`
is our private authoring workspace, and the `_brief_cluster_*.md`,
`_compliance_*.md`, `_AUTHORITY_HIERARCHY.md`, `uc-naming-conventions.md`, etc.
files at its root are local-only working notes that never reach the MCP.

The adaptation surface is therefore strictly the **`domain-*` hubs** — the ones
we author, both deployed (in `data-skills/skills/`) and not-yet-deployed (in this
repo, pending sync). Out of scope: `data-analysis-pattern-library`,
`data-analysis-patterns`, `data-analysis-playbook`, `registration-to-ftd-funnel`,
`skill-creator` — those have other owners.

The original draft's "P0 relocate root files" wedge was a false alarm based on the
wrong directory. The real corpus has no stem-regex violations.

---

## TL;DR — what the new MCP does and where our corpus is broken

The new MCP introduces **two-pass hub-and-spoke retrieval** behind a kill switch
(`SKILLS_SUB_PASS_ENABLED`, default OFF in prod):

- **Pass 1**: cosine-rank hub `SKILL.md` files (today's behaviour).
- **Pass 2**: for each candidate hub, cosine-rank its **declared sub-skills**, then
  bubble the hub up by `effective_score = max(hub_score, best_child_score)`.

A hub's children are **only loaded** if the hub's frontmatter explicitly lists them
in a `sub_skills:` array. Auto-discovery from sibling `.md` files is **intentionally
NOT done** — children that aren't listed are treated as "supplementary reference
content" and silently ignored.

### The headline gap

**0 of 7 deployed `domain-*` hubs declare `sub_skills:`.** Every single one of the
45 sub-skill `.md` files in `data-skills/skills/domain-*/` is currently invisible
to the new MCP routing. When the kill switch flips to `on`, our domain hubs
would return zero matched children for every query.

Same gap in our local-only authoring workspace: 4 newly-built domains
(`domain-marketing-and-acquisition`, `domain-ops-and-onboarding`,
`domain-product-analytics`, `domain-staking`) with 14 child files between them
also need `sub_skills:` declarations before they sync to the deployed repo.

11 hubs / 59 children total.

### What works as-is

- All 65+ child file stems under `domain-*/` are already valid kebab-case.
- Hub descriptions are long, dense, and front-loaded with anchor tables — exactly
  what the embedder wants (first ~200 tokens dominate; description is the lead
  signal).
- The folder layout (`<stem>/SKILL.md` + siblings) matches what the loader expects.
- The kill switch is OFF by default, so flipping the new MCP on the dev cluster
  changes nothing for our existing hubs — they keep returning today's response
  shape until we explicitly wire the children.

---

## The new schema contract, fully decoded

### Hub `Skill` (in `SKILL.md` frontmatter)

Required: `version` (int ≥1), `owner`, `description` (≥10 chars), AND one of
`example_sql` (≥10 chars) or `body_markdown` (≥50 chars, comes from the markdown
body after the closing `---` fence).

Optional and used by the embedder / matcher:
- `name`, `domain_tags`, `triggers`, `sample_questions` — recall boosters.
- `unity_catalog_assets` (or alias `required_tables`) — list of three-level UC
  names matching `^[a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+$`.
- `column_notes` — dict-of-dicts; **every key must appear in `unity_catalog_assets`**.
- `join_hints`, `common_filters` — passed through to the LLM verbatim.
- `last_validated_at` — date.

**New in DEI-3745:**
- `sub_skills:` — list of bare child filenames (`["mimo-panel-and-ddr.md", ...]`).
  Path separators, parent-traversal, leading dots, and non-`.md` extensions are
  all rejected. Each entry must resolve to a sibling file in the same hub folder
  with a valid SKILL.md frontmatter.

Forbidden:
- `genie_space_id` — reserved for v2; will error.
- `id` — silently dropped (`extra=ignore`); the loader injects it from the path
  stem.

### Child `SubSkill` (in sub-skill `.md` frontmatter)

Same as `Skill` but **without**: `version`, `owner`, `domain_tags`,
`last_validated_at`, `genie_space_id`, `name`. These are all inherited from the
hub or omitted by design. Any of them present in a child's frontmatter is silently
dropped (`extra=ignore`) — no validation error, just lost.

Required: `description` (≥10 chars), plus one of `example_sql` / `body_markdown`.

### Identity rules

- The on-disk stem is the canonical ID (`mimo-panel-and-ddr.md` → `mimo-panel-and-ddr`).
- Hubs and children share **one global keyspace** — a child stem cannot collide
  with a hub stem or another child stem anywhere in the corpus.
- The reserved word `SKILL` is forbidden as a child stem.

### How matching actually scores

```python
hub.embedding_text() = description + body_markdown[:1500] + triggers + sample_questions + domain_tags
sub.embedding_text() = description + body_markdown[:1500] + triggers + sample_questions
```

Both vectors live in the same cosine space (L2-normalised, fed to
`databricks-gte-large-en`). The hub is **scored alongside its children**, and:

- `effective_score = max(hub_score, best_child_score)` — a strong child bubbles
  its whole hub up.
- `matched_sub_skills` (max 3, default 1) are attached to the hub in the response.
- The LLM gets both the hub's `body_markdown` (mental model, warnings, taxonomy)
  AND the matched children's `body_markdown` (specific query patterns).

### ACL is now a strict union

Pre-DEI-3745: the hub's `unity_catalog_assets` were the only check. Our hubs declare
`unity_catalog_assets: []` (empty) so they trivially passed every ACL probe.

Post-DEI-3745, on-path (sub-pass enabled): the hub passes the ACL check iff every
asset in the union of `hub.unity_catalog_assets ∪ matched_children.unity_catalog_assets`
is visible to the caller. **One inaccessible child UC asset hides the whole hub.**

This is intentionally stricter; the gateway commit message calls out the
"audit-log will tell us if it's too strict, and we can soften later" trade-off.

**Practical consequence**: sub-skill `unity_catalog_assets` lists must be
**conservative**. Don't list internal/restricted tables on a child unless we
genuinely want the hub hidden from users who can't see that table.

### Boot-time validation is strict; runtime kill switch is independent

The data-skills CI (`validate_skills.py`) **always** validates sub-skills strictly,
regardless of the runtime `SKILLS_SUB_PASS_ENABLED` flag. So we cannot stage
half-broken children "while the switch is off" — they'll fail PR CI the moment
they land.

The MCP loader's behaviour mirrors the CI under the switch:
- Switch OFF → `sub_skills:` key is silently dropped from each hub, children are
  ignored, off-path response is byte-for-byte identical to pre-DEI-3745.
- Switch ON → children are validated and indexed; one bad child fails the **entire
  hub's** load (the hub is dropped, not just the child) so partial loads can't
  silently surface.

---

## What we need to change, ranked by criticality

### P0 — declare `sub_skills:` on every domain hub that has children

Without this, all 59 children we authored are dead weight under the new routing.
Each hub's frontmatter needs a block like:

```yaml
sub_skills:
  - mimo-panel-and-ddr.md
  - deposits-and-withdrawals.md
  - crypto-wallet.md
  - emoney-accounts-and-cards.md
  - finance-recon-and-balances.md
```

This is a **mechanical** edit — 11 hubs × ~5 lines each. Order in the list does
NOT affect ranking (each child is scored independently), but it sets the
human-readable order in the SKILL.md frontmatter and any code that iterates
`hub.sub_skills`.

**Deployed hubs to update** (in `DataPlatform/databricks/data-skills/skills/`):

| Hub | Children to declare |
|---|---|
| `domain-compliance-and-aml` | `aml-alert-routing.md`, `aml-regtech-pipeline.md`, `aml-risk-scoring.md` |
| `domain-cross` | `crypto-to-fiat.md`, `provider-reconciliation.md`, `recurring-deposit-to-trade.md`, `refund-chargeback-chain.md`, `tribe-emoney-audit.md` |
| `domain-customer-and-identity` | `compliance-customer-snapshot-and-club.md`, `crm-cases-csat-and-churn.md`, `customer-action-audit-trail.md`, `customer-master-record.md`, `customer-models-and-segmentation.md`, `customer-populations-and-lifecycle.md`, `identity-jurisdiction-and-regulation.md`, `oltp-customer-static-and-breaches.md` |
| `domain-payments` | `crypto-wallet.md`, `deposits-and-withdrawals.md`, `emoney-accounts-and-cards.md`, `finance-recon-and-balances.md`, `mimo-panel-and-ddr.md` |
| `domain-revenue-and-fees` | `fees-deposit-withdraw-fx.md`, `fees-misc-dormant-options-interest.md`, `revenue-moneyfarm.md`, `revenue-options-platform.md`, `revenue-spaceship.md`, `revenue-staking-and-share-lending.md`, `trading-revenue-and-fees.md` |
| `domain-spaceship` | `dashboard-queries.md`, `data-patterns.md`, `metric-definitions.md`, `source-tables.md`, `views-architecture.md` |
| `domain-trading` | `best-execution.md`, `broker-and-lp-reconciliation.md`, `copy-trading-and-mirror.md`, `crypto-trading-ops-nixar.md`, `dealing-investigation-and-execution.md`, `hedge-cost-recon.md`, `instruments-and-asset-classes.md`, `lp-contracts-and-cogs.md`, `portfolio-value-aum-pnl.md`, `position-state-and-grain.md`, `pricing-and-currency-history.md`, `trading-volumes.md` |

**Local-only hubs to update** (in `Databricks_Knowledge/knowledge/skills/`, will
ship as part of the next sync to `data-skills/`):

| Hub | Children to declare |
|---|---|
| `domain-marketing-and-acquisition` | `affiliate-and-paid-media.md`, `marketing-comms-and-sfmc.md`, `raf-and-incentives.md` |
| `domain-ops-and-onboarding` | `electronic-verification-and-registration-funnel.md`, `kyc-document-pipeline.md`, `ops-portal-and-alerts.md` |
| `domain-product-analytics` | `ab-testing-and-experimentation.md`, `feed-and-social-analytics.md`, `mixpanel-events-and-pageviews.md` |
| `domain-staking` | `currency-catalog-and-parameters.md`, `distribution-pipeline.md`, `eligibility-and-gates.md`, `rewards-formula-and-calculation.md`, `staking-month-id-and-reruns.md` |

### P1 — verify every child has a SubSkill-compliant frontmatter

When sub-pass turns on, each child gets validated. Frontmatter must:
- Have `description` ≥10 chars.
- Either have a body ≥50 chars after the closing `---` (becomes `body_markdown`)
  OR carry `example_sql` ≥10 chars.
- Use `unity_catalog_assets:` (or `required_tables:`) with three-level lowercase
  names ONLY — no `BI_DB_...`, no backticks, no leading database alias.
- Every `column_notes` key must exist in `unity_catalog_assets`.
- NOT carry `version`, `owner`, `domain_tags`, `last_validated_at`, `genie_space_id`
  (silently dropped, not an error, but misleading to authors).

Spot-checked `domain-payments/mimo-panel-and-ddr.md`: it carries `name:
domain-payments` (same as the hub — silently dropped on the child) and has good
description + body. The asset list needs spot-checking on every child. I'll
script this in a follow-up audit pass.

### P1 — `domain-cross/` is already a hub in deployed (was a false alarm locally)

`domain-cross/` in the deployed `data-skills/skills/` already has a `SKILL.md`
hub plus 5 children. Our local `Databricks_Knowledge/knowledge/skills/domain-cross/`
has the children but no hub — that's a sync drift, not a missing hub. Resolution:
just adapt the deployed hub like the others (add `sub_skills:`).

### P2 — sub-skill UC asset hygiene

Two cleanups under the strict-union ACL semantics:

1. **Audit each child's `unity_catalog_assets`** for tables that are restricted to
   a small audience (e.g. `main.bi_output_stg.bi_output_operations_risk_alert_management_tool`
   in `domain-compliance-and-aml/aml-alert-routing.md`). If the user can't see
   that table, the **entire compliance hub** is filtered out.
2. **Verify the three-level lowercase pattern** on every entry. Anything we listed
   as `BI_DB.MIMO_AllPlatforms` style will fail validation.

This is a mechanical regex sweep + a judgement call on which assets to leave on
the child vs. promote to the hub vs. document but not list.

### P2 — embedding-text optimisation

Only the **first 1500 chars of `body_markdown`** feed the embedder. Our hubs front
with `## When to use` then `## Mental model` — both good, but we should:

- Drop any leading TOC / "see also" preamble before the first business sentence.
- Make sure the first 1500 chars name the anchor tables, the key business terms,
  and at least one trigger phrase inline (the encoder weights co-occurrence
  inside the same window more than scattered token frequency).

Most hubs are already close to ideal here — a 30-min pass per hub.

### P3 — `domain_tags` audit for cross-domain federation

`domain_tags` is the only pre-filter on `find_skills` (callers can pass
`domain_tag="payments"`). We've been inconsistent — some hubs have empty tags,
some have 3-5. Recommend a one-pass cleanup:

- One tag per super-domain (`payments`, `trading`, `revenue`, `marketing`,
  `compliance`, `customer`, `ops`, `product`).
- A hub can carry **multiple** tags when it federates (e.g. `domain-revenue-and-fees`
  could legitimately carry `revenue`, `trading`, `payments` since it touches all
  three).
- Children don't carry domain_tags — they inherit via the hub's match.

### P3 — gateway-side awareness

Two gateway behaviours that affect how the LLM uses our skills:

1. **`ToolDescriptionRewriterMiddleware`** rewrites the `find_skills` tool
   description before showing it to the LLM. Our skills don't need to change
   for this, but if we ever wanted to surface the sub-skill mechanism to the LLM
   we'd do it via that middleware, not via skill content.
2. **`SkillsFirstMiddleware`** (optional, env-gated) grants the LLM "unlimited
   guarded calls until 10-min idle" after a successful `find_skills`. Our skills
   don't need to know about this, but our docs / cursor rules that mention the
   tool should call it by its **gateway-prefixed name** `skills_find_skills`,
   not the underlying `find_skills`.

### P3 — global glossary / cross-references

The strict global stem keyspace means we cannot have two skills (anywhere) with
the same kebab name. Our current corpus is clean, but the **glossary / cross-
reference text inside hubs** still routes by section pointer ("see
`domain-customer-and-identity/customer-master-record.md`"). We should add the
sub-skill stem alongside, so the LLM can also call `get_skill(id=
"customer-master-record")` directly. Future-proofs the wiring.

---

## Execution wedges (corrected scope)

Approved scope from the user: **P0 + P1**. **Done.**

### What was changed

**Deployed corpus** (`DataPlatform/databricks/data-skills/skills/`) — 7 hubs touched:

| Hub | Children declared | Notes |
|---|---:|---|
| `domain-compliance-and-aml` | 3 | clean |
| `domain-cross` | 5 | clean |
| `domain-customer-and-identity` | 8 | clean |
| `domain-payments` | 5 | clean |
| `domain-revenue-and-fees` | 7 | clean |
| `domain-spaceship` | 5 | authored full SubSkill frontmatter for all 5 sibling reference files (`dashboard-queries.md`, `data-patterns.md`, `metric-definitions.md`, `source-tables.md`, `views-architecture.md`); each ships with a dense description, 25-35 triggers, 5 sample questions, and the actual `required_tables` it touches |
| `domain-trading` | 12 | clean |

**Local working corpus** (`Databricks_Knowledge/knowledge/skills/`) — mirror of the
7 deployed edits above + the 4 not-yet-deployed new domains:

| Hub | Children declared | Notes |
|---|---:|---|
| `domain-marketing-and-acquisition` | 3 | clean |
| `domain-ops-and-onboarding` | 3 | clean |
| `domain-product-analytics` | 3 | clean |
| `domain-staking` | 5 | one fix: 4 triggers were unquoted year integers (`2024100`, `2025030`, `202503`, `202410`) which YAML parsed as ints; quoted them as strings to satisfy `triggers: list[str]` |

Plus the same `sub_skills:` declarations applied to the 5 local mirror hubs
(`domain-compliance-and-aml`, `domain-customer-and-identity`, `domain-payments`,
`domain-revenue-and-fees`, `domain-spaceship`, `domain-trading`) so a future
local→deployed sync doesn't regress the change. `domain-cross` mirror: no
`SKILL.md` exists locally — the deployed copy is canonical.

### Validation

Ran the DEI-3745 validator (`proposals/DEI-3745-mcp-snapshot/validate_skills.py`,
725 lines vs. dev's 473) against both corpora:

- **Deployed corpus**: `validated 12 skill(s), 0 error(s), 0 warning(s)`. **45**
  sub-skills attached across the 7 hubs we own (was 40 before the spaceship
  P1.5 follow-up — see below). The 5 hubs we don't own
  (`data-analysis-pattern-library`, `data-analysis-patterns`,
  `data-analysis-playbook`, `registration-to-ftd-funnel`, `skill-creator`) have
  0 sub-skills declared and validate clean.
- **Local working corpus**: 54 sub-skills attached across 10 `domain-*` hubs.
  44 errors remain — all from local-only `_*.md` working files at the root
  (`_brief_cluster_*.md`, `_compliance_*.md`, `_AUTHORITY_HIERARCHY.md`,
  `_uc_object_map*.md`, `_payments_subgraph.md`, etc.). These are pre-existing
  research notes that don't deploy to `data-skills/`; they're noise from the
  validator running against this private repo.

### When ops flips `SKILLS_SUB_PASS_ENABLED=true`

The 7 `domain-*` hubs in the deployed corpus will start surfacing 45 ranked
sub-skill children on every `find_skills` call (up to 1 per hub by default, max
3 per call via `sub_k`). `effective_score = max(hub_score, best_child_score)`
will pull hubs up when a strong child matches the user's question. Off-path
behaviour is byte-for-byte identical to today, so flipping the switch is the
only operator action required — no schema migration, no corpus reload.

### P1.5 follow-up — spaceship reference files (done)

The 5 `domain-spaceship` sibling files (`dashboard-queries.md`,
`data-patterns.md`, `metric-definitions.md`, `source-tables.md`,
`views-architecture.md`) were originally pure markdown reference content
without YAML frontmatter, so they got excluded from the first P0/P1 pass.
Authored full `SubSkill` frontmatter for all 5: each carries a dense
~1000-1800 char description front-loaded with the file's analytical intent
(dashboard SQL reproduction / reusable CTEs / metric definitions / table
inventory / prep-view architecture), 25-35 hand-picked `triggers` (table
names, dataset IDs, key column names, gotcha keywords like "Super aud_amount
signed" or "5 fixes 2026-04-13"), 5 representative `sample_questions`, and
the actual `required_tables` each file touches. Added the 5 stems to the
hub's `sub_skills:` list (both deployed and local — files were
byte-identical pre-edit). Validator confirms 5/5 children attached, 0 errors.
This brings spaceship from "invisible to Pass-2" to fully indexed, raising
the deployed sub-skill total from 40 → 45.

### Batch 2 — adapt the 4 local-only new domains (done 2026-05-28)

The 4 fully-authored local-only domain hubs — `domain-marketing-and-acquisition`,
`domain-ops-and-onboarding`, `domain-product-analytics`, `domain-staking` — were
audited against the DEI-3745 schema in preparation for deployment.

**Baseline.** All 4 hubs and their 14 children already pass the DEI-3745
validator cleanly. Every file has SubSkill-compliant frontmatter (`description`,
`required_tables`, `triggers`, `sample_questions`). Every hub carries
`## When to Use`, `## Scope` (with `Last verified:` line), and
`## Critical Warnings` body sections. `sub_skills:` is declared on every hub
with correct stems. Sub-skill attachment count via the validator:
marketing 3/3, ops 3/3, product 3/3, staking 5/5 = **14 children** ready to
add to the deployed corpus (which would take the total from 45 → 59).

**P1 mechanical fix applied.** All 4 hubs had `owner: "personal"` (an
author-time placeholder) — flipped to `owner: "dataplatform"` to match the
convention used by the 7 deployed `domain-*` hubs. Zero impact on validation
or routing; pre-empts reviewer pushback on the deployment PR.

**Quality flags raised but NOT mechanically fixed** (editorial change requires
author input):

- `domain-marketing-and-acquisition/SKILL.md` description is 7,576 chars
  (~2,000 tokens) — ~4× the GTE encoder's 512-token budget. Everything past
  the first ~2,000 chars is invisible to Pass-1 matching. The opening
  sentences are well front-loaded so partial truncation is tolerated, but
  tighter rewrite would route better.
- `domain-ops-and-onboarding/SKILL.md` description is 5,251 chars (~3× over).
- `domain-product-analytics/SKILL.md` description is 3,042 chars (~1.6× over).
- `domain-staking/SKILL.md` description is 1,885 chars — within budget.
- 14 sub-skill descriptions all sit in the 1,100-3,600 char range — fine.

These trims should be a focused follow-up pass after first deployment, not a
blocker for the initial PR. The current descriptions are accurate and dense;
they just over-spend the embedding window.

**Status:** ready to ship via the next `/skills-push` round once the user
greenlights. PR will mirror 4 hub directories (18 files total) to
`DataPlatform/databricks/data-skills/skills/` and open a PR against `dev`.

### Deferred (P2+) — opportunistic, low risk

- Sub-skill UC asset hygiene under strict-union ACL semantics: audit each
  child's `required_tables` list for assets that are restricted to a small
  audience (those will hide the entire hub from users who can't read them).
- First-1500-chars body polish per hub (today's leading content is already
  good; opportunistic 30-min pass would tighten it).
- `domain_tags` taxonomy normalisation (per-hub tag set is inconsistent;
  current state still works because `find_skills` rarely passes the optional
  `domain_tag` pre-filter).

---

## Reference dump

The 12 MCP source files I read are in `proposals/DEI-3745-mcp-snapshot/`:

- `schema.py` — `Skill` + `SubSkill` pydantic models (the canonical contract).
- `loader.py` — file discovery, `_resolve_sub_skills`, the path-derived ID rule.
- `index.py` — FAISS hub index + per-hub child matrices.
- `tools.py` — `find_skills` / `list_skills` / `get_skill` — the matching pass.
- `acl.py` — `filter_by_acl_with_subs` strict union semantics.
- `embedder.py` — composition shape (already mirrored in `embedding_text()`).
- `app_mcp.py`, `settings.py` — server wiring and env vars
  (`SKILLS_SUB_PASS_ENABLED`, `SKILLS_SUB_K_DEFAULT`, `SKILLS_MIN_SCORE`).
- `gateway_app.py`, `gateway_settings.py` — gateway composition, audit sink,
  `SkillsFirstMiddleware`.
- `gateway_instructions.py` — `SYSTEM_HINT` (the v5 description-led routing).
- `validate_skills.py` — the data-skills CI gate (mirrors `schema.py` + `loader.py`).

Keep this folder out of the MCP loader's path (it's under `proposals/`, not
`knowledge/skills/`, so safe by construction).
