# Feature Specification: Build Domain D — Compliance & AML

**Feature Branch**: `011-build-domain-compliance-aml`
**Created**: 2026-05-24
**Status**: Draft
**Parent Spec**: 007-package-agent-domains
**Template**: [.specify/templates/domain-build-template.md](../../templates/domain-build-template.md)
**Authority**: [knowledge/skills/_AUTHORITY_HIERARCHY.md](../../../knowledge/skills/_AUTHORITY_HIERARCHY.md)
**Note on numbering**: Spec number 011 is aligned with the feature branch name (branch 010 already occupied by `010-uc-domain-doc-framework`). The next sequential number in `.specify/specs/` is 009, but the spec-vs-branch alignment is preserved to make commit messages traceable.

**Input**: Build the D super-domain skill (Compliance & AML), focused narrowly on **AML risk classification and scoring** for v1. Out of scope for v1: KYC screening, tax compliance, regulatory reporting, Tribe audit interpretation. Drive the build from the SEMANTIC MODEL first — production KPI views, Genie spaces, Louvain graph — then make file-shape decisions only after the data is in.

## Why this domain is special

Compliance & AML is the most **churn-heavy** super-domain at the surface (rules change, alerts get added/removed, screening providers swap, sanctions lists rotate weekly). The wikis are usually behind by 3-12 months; some Confluence pages reflect frameworks that are no longer active.

The most-stable evidence is in **production KPI views** that compute the actual numbers eToro uses for compliance reporting (`kyc_for_compliance_v`, `cmp_aml_risk_classification_*` family). The **AML Insights** and **PROD - Compliance** Genie spaces in Databricks reflect what the Compliance team actually queries.

This makes Compliance & AML the **first domain where the Authority Hierarchy is load-bearing**: every conflict resolution rule and stale-doc verdict relies on it. This spec also introduces the Confluence edge extractor (`tools/skills/extract_confluence_edges.py`) and the stale-document cross-check (`tools/skills/cross_check_staleness.py`) — both reusable across future domain builds.

## User Scenarios & Testing

### User Story 1 — AML scoring questions hit production views, not stale docs (Priority: P1)

As an agent answering "what's the AML risk score for a customer cohort?", I need the skill to direct me to `cmp_aml_risk_classification_cid_level` (Tier 1 production view) before any wiki page from 2024 about a now-decommissioned risk framework.

**Why this priority**: AML answers must be defensible to regulators. A stale doc giving the wrong score model is a compliance incident.

**Independent Test**: Pose 5 AML-scoring questions; the skill's `required_tables` must list the production KPI view that computes the answer in 100% of cases.

**Acceptance Scenarios**:

1. **Given** a question about a customer's current AML risk level, **When** the agent loads the D skill, **Then** the answer cites `etoro_kpi.cmp_aml_risk_classification_cid_level` (or its current production successor) as primary source
2. **Given** the wiki's documentation of a deprecated risk framework, **When** the staleness report runs, **Then** the discrepancy is flagged with `tier-1-wins` verdict
3. **Given** the Confluence canonical AML Handbook page, **When** it agrees with the KPI view, **Then** the skill cites both with the Handbook providing the WHY and the KPI view providing the WHAT

---

### User Story 2 — Compliance Genie is the routing anchor (Priority: P1)

As a Compliance analyst already using the **PROD - Compliance** Genie space in Databricks, I need the D skill to know which tables are in that Genie's curated set, so that the agent answers stay consistent with what the analyst sees in Genie.

**Why this priority**: Two different answers from two surfaces destroys trust. The Genie config IS the team's curated view.

**Independent Test**: For every table in the PROD - Compliance and AML Insights Genie space configurations, the table must appear in the D skill's `required_tables` OR be explicitly listed as a "bridge table" routed to a sibling domain.

**Acceptance Scenarios**:

1. **Given** the Genie config for PROD - Compliance, **When** the production-anchor enumerator runs, **Then** every table in `tables` field is in `_compliance_production_anchors.md`
2. **Given** a table that appears in the Compliance Genie but is in the Customer Louvain cluster (1/2/3/10), **When** the embedded-scan runs, **Then** the table is surfaced as a "cross-domain bridge" and either pulled into D or explicitly routed back to B with a documented reason

---

### User Story 3 — Confluence churn is captured but stability is weighted higher (Priority: P2)

As a knowledge engineer aware that Compliance Confluence pages change frequently, I need the Confluence corpus selection to favor stable foundational pages (Handbook / Framework / Glossary / Policy) over recently edited drafts and sandboxes.

**Why this priority**: Recent edits in a churn-heavy domain are usually drafts, not policy. Foundational pages reflect what the business has actually committed to.

**Independent Test**: Inspect `_confluence_corpus.md`; ≥70% of selected pages must have stability score ≥ 0.6 (computed from depth, backlinks, title pattern, last-edit recency).

**Acceptance Scenarios**:

1. **Given** the corpus crawl query terms (AML/Compliance/Risk/KYC/PEP/Sanctions/Watchlist), **When** the selection scorer runs, **Then** pages with "Handbook" or "Framework" titles appear in the top 20 by score regardless of last-edit date
2. **Given** a Confluence page edited 3 days ago with 2 backlinks, **When** the scorer runs, **Then** it ranks below a page edited 18 months ago with 50 backlinks
3. **Given** the corpus, **When** the extractor runs, **Then** `_edges_confluence.csv` has the same schema as `_edges_tableau.csv` (parallel structure for `merge_graph.py` consumption)

---

### User Story 4 — Build pipeline is reusable for future domains (Priority: P2)

As a future author building domain E / F / G, I need every tool from spec 011 to run with `--domain <name>` and a seed YAML, so that I don't fork-and-edit the Payments-specific tools again.

**Why this priority**: Per-domain script forking caused drift between the first 5 deployed domains. Continuing it would make the 8-domain set unmaintainable.

**Independent Test**: Run `tools/skills/summarize_subgraph.py --domain payments --seed tools/skills/_seeds/payments.yaml` and confirm output equals the existing `_payments_subgraph.md` (modulo formatting). Then run with `--domain compliance --seed tools/skills/_seeds/compliance.yaml` and confirm a structurally identical output for D.

**Acceptance Scenarios**:

1. **Given** existing 5 deployed domains, **When** I backfill seed YAMLs and run the generic tools, **Then** the existing semantic outputs (`_payments_subgraph.md` etc.) regenerate without diffs
2. **Given** the D seed YAML, **When** generic tools run, **Then** they produce structurally identical outputs for D
3. **Given** a future domain E, **When** I author only its seed YAML, **Then** the same tools produce all semantic outputs for E with zero code changes

---

### Edge Cases

- What if a table is in the Compliance Genie AND the Customer Genie? → Surface in both `required_tables`; the D skill calls it a "bridge to B" and B's skill (when next refreshed) gets a cross-ref pointer to D.
- What if the AML core Louvain cluster (35) is much smaller than expected (e.g., < 5 nodes)? → Phase B decision gate: file shape becomes "atomic-pair" (D hub + 1 sub-skill `aml-risk-scoring`) rather than the Payments-style hub-with-5-subskills.
- What if a Confluence page references a table that doesn't exist in `system.information_schema`? → Flagged in `_compliance_staleness.md` as "dead reference"; the verdict is "Confluence stale".
- What if the wiki §3.3 JOIN section is empty for an AML core table? → Note in staleness report; rely on KPI view DDL alone for that table.
- What if Tableau has heavy AML coverage Louvain missed because of the 0.5x weighting? → Tableau fly-over (Phase A.4) is explicit; under-weighted nodes are pulled in manually with citation.

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST produce `knowledge/skills/_compliance_production_anchors.md` enumerating every table referenced by `tools/skills/_seeds/compliance.yaml`'s `kpi_seeds` (Tier 1) and `genie_seeds` (Tier 2), with tier annotation per row.
- **FR-002**: System MUST produce `knowledge/skills/_brief_cluster_35.md` (the AML-core Louvain brief) using existing `tools/skills/extract_subdomain_brief.py --cluster 35`.
- **FR-003**: System MUST produce `knowledge/skills/_aml_embedded_members.md` enumerating AML-pattern-matching nodes (name regex from seed YAML) that Louvain assigned to clusters 1/2/3/10 (Customer/snapshot family), with the underlying join-graph reason from `_join_graph.json` for each.
- **FR-004**: System MUST produce `knowledge/skills/_compliance_subgraph.md` using a generic `tools/skills/summarize_subgraph.py --domain compliance` seeded by the union of (a) `kpi_seeds` (b) `genie_seeds` (c) `hub_tables` (d) embedded-member finds. Output MUST include intra-D edges plus cross-edges to B (Customer family) and C.3 (eMoney Tribe).
- **FR-005**: System MUST produce `knowledge/skills/_compliance_tableau_flyover.md` by grepping `knowledge/tableau/_index/{workbooks.csv,custom_sql.csv,calc_fields.csv}` and the 2 DDR workbook markdowns for AML/compliance/risk_class/sanctions/PEP terms; missed-by-Louvain hits are flagged for manual inclusion.
- **FR-006**: System MUST build `tools/skills/extract_confluence_edges.py` parallel to `extract_tableau_edges.py`. The extractor crawls Confluence via `plugin-atlassian-atlassian` MCP, parses SQL blocks + inline code refs + linked Genie/wiki references, and emits all-pairs co-occurrence edges with the same CSV schema as `_edges_tableau.csv`.
- **FR-007**: System MUST run the Confluence extractor on a D-scoped corpus (~10-15 queries × 1-hop link expansion) with **stability-weighted page selection**: pages scoring high on (depth ≤ 2 in space tree) + (title contains Handbook/Framework/Glossary/Policy/Specification) + (≥ 10 backlinks) + (last-edit ≥ 6 months ago) are favored. Output: `_edges_confluence.csv` + `_confluence_corpus.md` with selection rationale.
- **FR-008**: System MUST fold Confluence edges into the partition via **additive overlay** (pin existing Louvain cluster assignments, merge new edges) rather than full re-cluster — to preserve cluster IDs across the 5 deployed domains. A separate future spec MAY trigger a full re-cluster once all 8 domains are built.
- **FR-009**: System MUST produce `knowledge/skills/_compliance_staleness.md` via a new `tools/skills/cross_check_staleness.py` that compares Confluence claims, wiki §3.3 JOINs, and UC `system.information_schema.tables`. Each discrepancy row has a verdict per Authority Hierarchy tiers.
- **FR-010**: System MUST gate Phase B (file-shape partition decision) on completion of FRs 001-009. Candidate shapes: (a) full hub + N sub-skills (Payments style), (b) single overlay skill embedded in B's compliance-customer-snapshot-and-club, (c) standalone D hub with 1-2 sub-skills, (d) atomic-pair. The choice MUST cite the semantic-model outputs.
- **FR-011**: System MUST validate every node in the final scope against `system.information_schema.tables` via `user-databricks_sql` MCP and update `knowledge/skills/_uc_object_map.action_required.md` for any unmapped node.
- **FR-012**: System MUST author whatever file shape Phase B chose, conforming to spec 007 FR-009 (DataPlatform DE skill-creator schema; `lint_skill.py` exit 0; cross-reference to `_AUTHORITY_HIERARCHY.md` from the SKILL.md).
- **FR-013**: System MUST update the dwh-domain top-level router and the B-side `compliance-customer-snapshot-and-club.md` cross-ref to reflect that D is built.
- **FR-014**: System MUST sync the new skill to Databricks via `sync_to_databricks.py --only domain-compliance-and-aml`, after explicit confirmation of `--workspace-base` with the user. Verification: `databricks workspace list /Workspace/databricks/data-skills/skills/` includes the new folder.
- **FR-015**: System MUST commit on the feature branch with one commit per phase (Phase 0 governance, reusability tooling, semantic outputs, Confluence build, staleness cross-check, author/format, glue/deploy). Never `git add .`; stage only files this spec produces.

### Key Entities

- **AML Risk Classification Family**: The `cmp_aml_risk_classification_*` view family and the `kyc_for_compliance_v` view — the production semantic model for AML risk scoring.
- **PROD - Compliance Genie / AML Insights Genie**: The two Databricks Genie spaces with production blessing for the D domain. Tables in these Genies' configs are Tier 2 authority.
- **Compliance Confluence Canonical Corpus**: Stability-weighted subset of Confluence (Handbook/Framework/Glossary pages, ≥10 backlinks, depth ≤2 in space tree).
- **Louvain Cluster 35**: The AML core cluster from spec 007's clustering pass. Small (per `_domain_candidates.md`) but coherent.
- **Embedded AML Members**: Nodes name-matching AML patterns that Louvain placed in clusters 1/2/3/10 (Customer family) due to dominant join evidence to Customer rather than to other AML nodes. The AML purpose is still real and these are pulled into D.
- **Staleness Report**: `_compliance_staleness.md` — the audit trail of conflict resolutions per Authority Hierarchy.

## Clarifications

### Session 2026-05-24

- Q: KYC, tax, regulatory reporting, Tribe audit interpretation — in scope for v1? → A: No. AML risk classification + scoring only for v1. Other compliance sub-topics are deferred to follow-up specs.
- Q: How deep should Confluence integration go? → A: DEEP — dedicated extractor parallel to Tableau, stability-weighted corpus selection, full staleness cross-check. Confluence is a first-class signal source, not a fly-over.
- Q: Tableau weight in graph? → A: Stays at 0.5x (Tableau changes less often than other surfaces, but is analyst-experimental). Tableau fly-over (Phase A.4) captures anything Louvain missed.
- Q: How are production Databricks artifacts (KPI views, Genie spaces) weighted vs Confluence? → A: First-class. KPI views = Tier 1, Genie configs = Tier 2, Confluence = Tier 3 (canonical) / Tier 5 (non-canonical). See `_AUTHORITY_HIERARCHY.md`.
- Q: How to fold Confluence edges into the partition? → A: Additive overlay (FR-008). Preserves Louvain cluster IDs across already-deployed domains.
- Q: How is reusability ensured for future domains E/F/G? → A: All tools introduced here are generic, parameterized via `tools/skills/_seeds/<domain>.yaml`. Existing 5 domains get seed YAMLs backfilled so the same tools regenerate their semantic outputs.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `_compliance_production_anchors.md` exists and lists every table from every Genie/KPI view in the seed YAML.
- **SC-002**: `_compliance_subgraph.md` enumerates every node touched by the PROD - Compliance and AML Insights Genie spaces.
- **SC-003**: `_aml_embedded_members.md` lists AML-pattern nodes embedded in non-AML Louvain clusters with documented graph-edge reasons.
- **SC-004**: `_edges_confluence.csv` ≥ 50 rows; `_confluence_corpus.md` ≥ 10 pages, ≥70% with stability score ≥ 0.6.
- **SC-005**: `_compliance_staleness.md` flags ≥ 3 discrepancies (this domain has churn — finding zero would be suspicious).
- **SC-006**: `tools/skills/lint_skill.py` exits 0 on every authored skill file.
- **SC-007**: `tools/skills/summarize_subgraph.py --domain payments` regenerates `_payments_subgraph.md` byte-equivalent (modulo timestamp) to the deployed version.
- **SC-008**: The D skill folder is visible in `/Workspace/databricks/data-skills/skills/domain-compliance-and-aml/` (or the user-chosen `--workspace-base`).
- **SC-009**: Feature branch has ≥ 5 commits, one per phase, each with a clear `feat(skills)` / `feat(skills/tools)` / `feat(spec)` prefix.
- **SC-010**: At least one regulatory-defensible answer can be cited: posing "show me AML risk distribution across CIDs" must trigger the D skill and route the agent to `cmp_aml_risk_classification_cid_level` (or its current production successor) with the KPI view DDL as ground truth.
