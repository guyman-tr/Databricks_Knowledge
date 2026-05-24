# Authority Hierarchy — Evidence Ranking for Domain Skills

> First-class reference document for every domain skill in `knowledge/skills/`. Every authored `SKILL.md` cites this file (directly or by inheritance) for its conflict-resolution policy. Every staleness report (`_<domain>_staleness.md`) defaults its verdict column to this hierarchy.

## The hierarchy (high → low)

When two evidence sources disagree about a column meaning, a join key, a table grain, a dimensionality, or an operational definition — the higher tier wins by default.

| Tier | Source | Reason | Examples |
|---|---|---|---|
| **1** | etoro_kpi / etoro_kpi_prep view DDL | Production SQL, executed daily. Whatever a KPI view DOES is what the metric MEANS. | `kyc_for_compliance_v`, `mv_revenue_trading`, `ftd_funnel_v` |
| **2** | Genie space configurations | Production-blessed curated table sets owned by domain teams. The fact that a Genie exists for a topic is the strongest signal the topic is a real business concept. | `AML Insights Genie`, `PROD - Compliance Genie`, `ido ezra space` |
| **3** | Confluence canonical pages | Institutional knowledge of the WHY. Stable by selection. Defined as pages with title containing Handbook / Framework / Glossary / Policy / Specification / Reference / Architecture, OR depth ≤ 2 in space tree, OR ≥ 10 backlinks. | (per-domain corpus in `_<domain>_corpus.md`) |
| **4** | Wiki §3.3 Common JOINs | Sampling-derived, captures real join patterns. Drifts with refresh; not always recent. | `knowledge/synapse/Wiki/<schema>/Tables/<obj>.md` |
| **5** | Confluence non-canonical pages | Drafts, Sandbox, personal spaces, recent edits with < 5 backlinks. Useful as evidence but easily wrong. | (filtered out of corpus by selection scorer, but cited in staleness if discrepancy) |
| **6** | Tableau custom SQL | Analyst-authored, often experimental, may not reflect production semantics. Weighted 0.5x in graph merge. | `knowledge/tableau/_workbooks/*.md` |

## How this hierarchy is enforced

### In `tools/skills/merge_graph.py`

Source weights in [`tools/skills/merge_graph.py`](../../tools/skills/merge_graph.py) `SOURCES` array:

| Edge source | Weight | Rationale |
|---|---|---|
| `kpi` | 1.0 | Tier 1 |
| `kpi_prep` | 1.0 | Tier 1 |
| `genie` | 1.0 | Tier 2 |
| `wiki` | 1.0 | Tier 4 — equal-weighted with production because it's exhaustive and the sampling is reasonable in practice |
| `confluence` | 1.0 for canonical, 0.5 for non-canonical | Tiers 3 + 5 split by selection scorer in [`tools/skills/extract_confluence_edges.py`](../../tools/skills/extract_confluence_edges.py) |
| `tableau` | 0.5 | Tier 6 |

Note: weights collapse tier 1+2+4 to a common 1.0 floor for graph clustering purposes because the Louvain partition uses join-co-occurrence, where exhaustiveness matters more than authority. **Authority shows up at INTERPRETATION time** (staleness reports + authored skill `required_tables` ordering), not at clustering time.

### In `_<domain>_staleness.md` reports

Every discrepancy row has a `verdict` column with one of:
- `tier-1-wins` — KPI view DDL says X, contradicts lower tier; trust KPI view.
- `tier-2-wins` — Genie config implies X, contradicts lower tier; trust Genie.
- `tier-3-wins` — Confluence canonical says X, contradicts wiki §3.3; trust Confluence canonical.
- `equal-no-conflict` — sources agree at different levels of detail; no conflict.
- `manual-review` — Tiers above don't decide; human judgment required.

The verdict is computed by `tools/skills/cross_check_staleness.py` (introduced by spec 011-build-domain-compliance-aml).

### In authored `SKILL.md` files

The `required_tables:` front-matter array MUST list (UC-resident only — see Locality section below):
1. KPI view FQNs first (Tier 1)
2. Genie-anchored bronze/gold tables (Tier 2)
3. Wiki-only tables (Tier 4) last
4. Tableau-only or Confluence-only tables (Tier 5/6) — generally excluded from `required_tables` unless the domain has no Tier 1/2 coverage

The optional `external_references:` front-matter array MUST list (one entry per non-UC anchor that the skill teaches knowledge about):
- Synapse-only production tables (`locality: synapse_only`)
- Hybrid Synapse-and-UC tables where the UC bronze is partial (`locality: hybrid_synapse_uc`)
- External-system sources — Actimize / ComplyAdvantage / Salesforce / Tableau workbooks / Excel (`locality: external_system`)
- Procedural knowledge — Synapse stored procs, runbook rules, manual operations (`locality: manual_only`)

Each entry's required keys are `name`, `locality`, `source_system`, `role`. Recommended additional key: `bridge_strategy` — one-line instruction for how a query would reach the data (e.g. "query via the Synapse MCP server `user-synapse_prod_sql`"; "no automated access — read Confluence page X and the source SP `BackOffice.SetRiskClassification_Login`"). Linter validates the shape but does not require the field to exist.

## When a skill must explicitly override the hierarchy

A skill may state "for this column/join/grain, the default hierarchy is wrong" by adding a `## Authority overrides` section to the SKILL.md body. Each override must cite:
- The specific column / join / grain being overridden
- The default tier verdict and why it's wrong
- The chosen alternative and the evidence chain (with dates)
- Sign-off — the human who approved the override

Overrides are rare. The hierarchy works well across all 8 super-domains as designed.

## Locality is orthogonal to authority

> Introduced 2026-05-24 by user direction during the D (Compliance & AML) build. Affects all future domain builds.

Authority answers "how much do I trust this source's claim about meaning?" — and is what the table above ranks. **Locality** answers a different question: "where does this object physically live today, and can a Databricks query reach it?". The two are orthogonal:

- A Tier 1 KPI view is normally Lake-resident (`main.etoro_kpi*`).
- A Tier 2 Genie space normally lists UC objects, but a Genie can validly reference a Synapse-only table when the team hasn't migrated yet.
- A Tier 3 Confluence HLD can describe a stored procedure that runs only in Synapse, with no UC counterpart.
- A production AML alert routing table (`BI_DB_dbo.BI_DB_AML_BI_Alerts_New`) is **Tier 1 by authority** (it is the production source of truth for AML alert state) but **Synapse-only by locality** (no UC ingestion as of 2026-05-24).

### The locality enum

Every anchor object cited by a SKILL.md falls into exactly one of these four buckets:

| Locality | Meaning | How a SKILL.md surfaces it |
|---|---|---|
| **UC** (default) | The object exists in Databricks Unity Catalog and a `SELECT * FROM catalog.schema.table` works. | Lists in `required_tables:` (catalog.schema.table). |
| **synapse_only** | The object exists only in the Synapse SQL pool (`sql_dp_prod_we` / `DWH_dbo` / `BI_DB_dbo` / production OLTP DBs / `RiskClassification` / `dealing_dbo` etc.). No UC ingestion (or only a tangential bronze copy). To query it from Databricks today: route the user to Synapse explicitly. | Goes into `external_references:` with `locality: synapse_only`; gets a dedicated `## External Data Sources` section in the body that names the Synapse pool and points to the per-table wiki under `knowledge/synapse/Wiki/...`. |
| **hybrid_synapse_uc** | Both exist: a Synapse OLTP/DWH master, plus a UC bronze copy that may lag, project differently, or omit columns. Often the wide DWH Fact tables are like this. | If the UC bronze is sufficient for the skill's questions → `required_tables:`. If the skill needs columns/grain the bronze drops → `external_references:` with `locality: hybrid_synapse_uc` and the bridge strategy. |
| **external_system** | Lives in a third-party SaaS or analyst-only artifact: Actimize, ComplyAdvantage, Salesforce, an Excel workbook, a Google Sheet, a Tableau workbook custom SQL block. May be indirectly visible via a downstream UC table (e.g. `bronze_fivetran_google_sheets_*`) but the authoring source isn't queryable. | `external_references:` with `locality: external_system`; the `bridge_strategy` field explains how to reach it (which UI, which credential, which approval). |
| **manual_only** | The "object" is procedural knowledge — a Synapse stored proc, a runbook step, a manual ticket-routing rule — not a data table at all. Knowledge worth preserving in the skill, but no query plan can produce it. | `external_references:` with `locality: manual_only`. |

### The NEVER-DROP rule

When Phase A.5c staleness shows that a Confluence-anchored / wiki-anchored object **does not exist in UC**, the default reaction is **NOT** to drop it from the SKILL.md. Drop only if the object is genuinely defunct (replaced, deprecated by the owning team, or never existed). For anything that is still producing value to the business — even if it lives in Synapse, Actimize, Salesforce, or a spreadsheet — annotate locality and **keep the knowledge in the skill**. The user asking "where does AML risk score 200 come from?" still needs the answer even if the source is Actimize and the trigger table is Synapse-only.

This rule is enforced by the harness: `external_references:` is OPTIONAL in the linter (so existing 5 deployed skills don't break), but spec 011 and every successor spec REQUIRES it whenever the staleness report flags any anchor as `STALE-CONF` or `GAP-CONF` or Synapse-only by ground-truth check.

### How the locality enum interacts with the authority tiers

- **Authority hierarchy** still governs CONFLICT RESOLUTION (whose claim about MEANING wins).
- **Locality enum** governs ROUTING (where the agent or user fetches the data).
- A `synapse_only` Tier 1 source still beats a UC-resident Tier 5 source on a meaning conflict; the locality difference is irrelevant to authority.
- The two fields appear side by side in `external_references` entries so a skill consumer can read both at once: "this is the Tier 1 production AML routing table, lives only in Synapse, query via the Synapse MCP server."

## Why this matters (the AML/compliance case)

Compliance & AML is the most churn-heavy domain at the surface (rules change, alerts get added/removed, screening providers swap). The most-stale documents are wikis and Confluence pages. The most-stable evidence is `kyc_for_compliance_v` and `positions_for_compliance_v` and `cmp_aml_risk_classification_*` — production SQL that is executed and consumed every day.

When a wiki says "the AML risk classification has 3 levels" but `cmp_aml_risk_classification_cid_level` shows 5 distinct values today, the production data is right and the wiki is stale. The hierarchy makes this resolution mechanical, not editorial.

## Provenance

- Introduced: spec 011-build-domain-compliance-aml, 2026-05-24
- First applied: D (Compliance & AML) domain build
- Retroactive: applies to all 5 already-deployed domains; their `_*_staleness.md` reports may be generated later if drift becomes a concern
- Constitution reference: this hierarchy supplements `.specify/memory/constitution.md` Principle X (DE skill-creator schema conformance) by adding evidence-ranking as a parallel governance layer
