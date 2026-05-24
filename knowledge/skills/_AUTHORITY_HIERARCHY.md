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

The `required_tables:` front-matter array MUST list:
1. KPI view FQNs first (Tier 1)
2. Genie-anchored bronze/gold tables (Tier 2)
3. Wiki-only tables (Tier 4) last
4. Tableau-only or Confluence-only tables (Tier 5/6) — generally excluded from `required_tables` unless the domain has no Tier 1/2 coverage

## When a skill must explicitly override the hierarchy

A skill may state "for this column/join/grain, the default hierarchy is wrong" by adding a `## Authority overrides` section to the SKILL.md body. Each override must cite:
- The specific column / join / grain being overridden
- The default tier verdict and why it's wrong
- The chosen alternative and the evidence chain (with dates)
- Sign-off — the human who approved the override

Overrides are rare. The hierarchy works well across all 8 super-domains as designed.

## Why this matters (the AML/compliance case)

Compliance & AML is the most churn-heavy domain at the surface (rules change, alerts get added/removed, screening providers swap). The most-stale documents are wikis and Confluence pages. The most-stable evidence is `kyc_for_compliance_v` and `positions_for_compliance_v` and `cmp_aml_risk_classification_*` — production SQL that is executed and consumed every day.

When a wiki says "the AML risk classification has 3 levels" but `cmp_aml_risk_classification_cid_level` shows 5 distinct values today, the production data is right and the wiki is stale. The hierarchy makes this resolution mechanical, not editorial.

## Provenance

- Introduced: spec 011-build-domain-compliance-aml, 2026-05-24
- First applied: D (Compliance & AML) domain build
- Retroactive: applies to all 5 already-deployed domains; their `_*_staleness.md` reports may be generated later if drift becomes a concern
- Constitution reference: this hierarchy supplements `.specify/memory/constitution.md` Principle X (DE skill-creator schema conformance) by adding evidence-ranking as a parallel governance layer
