---
id: {kebab-case-skill-id}
name: "{Human Readable Title}"
description: "{Third-person summary, ≥30 chars. Explain WHAT the skill covers
  (objects, metrics, fee types, business concepts) AND WHEN it should trigger
  (paraphrases, jargon, view names). List adjacent phrasings a user might say.
  Slightly pushy to combat under-triggering. Cover edge cases where the user
  doesn't name the domain explicitly.}"
triggers:
  - {keyword or phrase 1}
  - {keyword or phrase 2}
  - {object or view name}
  - {business jargon / acronym}
required_tables:
  # Single-domain (shape A): list the canonical UC objects in this domain only.
  # Cross-domain (shape B): list canonical UC objects from EACH super-domain
  # the skill spans, in the order a query would join them.
  # ONLY UC FQNs go here. Non-UC anchors go in external_references below.
  - {catalog}.{schema}.{table_or_view}
  - {catalog}.{schema}.{table_or_view}
external_references:                    # optional; required when the skill teaches
                                        # knowledge about Synapse-only / hybrid /
                                        # external-system / procedural anchors.
                                        # See knowledge/skills/_AUTHORITY_HIERARCHY.md
                                        # "Locality is orthogonal to authority".
  - name: "{Schema.Object or system identifier}"   # NOT a UC FQN (would belong in required_tables)
    locality: "{synapse_only | hybrid_synapse_uc | external_system | manual_only}"
    source_system: "{sql_dp_prod_we | Actimize | ComplyAdvantage | Salesforce | etc.}"
    role: "{one-line description of what the object IS / does in the domain}"
    bridge_strategy: "{one-line instruction for how a query reaches this object today}"
sample_questions:                       # optional but strongly recommended
  - "{natural-language paraphrase 1}"
  - "{natural-language paraphrase 2}"
domain_tags:                            # optional; lowercase, short
  - {tag1}
  - {tag2}
version: 1
owner: "dataplatform"
last_validated_at: "{YYYY-MM-DD today}"
# column_notes / join_hints / common_filters are optional — add only when prose
# in the body would be insufficient. See skill-schema.md for the full grammar.
---

<!--
SKILL TEMPLATE — DE-format compliant.

Source schema:  .specify/memory/skill-schema.md (mirrored from DE skill-creator)
Constitution:   Principle X (NON-NEGOTIABLE)
Linter:         python tools/skills/lint_skill.py <path-to-skill.md>   (must exit 0)

Two skill shapes — pick ONE and delete the other:
  A) Single-domain skill (one super-domain — payments / revenue / instruments / ...)
  B) Cross-domain skill  (spans 2+ super-domains; filename and `id` use `cross-` prefix;
     `required_tables` lists ≥1 UC object from EACH super-domain spanned)

NOTHING else changes between shapes — only `id`/`name` prefix and how
`required_tables` is populated. Both must pass the same DE CI checks.
-->

# {Human Readable Title}

## When to Use

Load when users ask about {primary subject}, including paraphrases:
{trigger phrase 1}, {trigger phrase 2}, {jargon}, {acronym}.

Load also when {edge-case scenario where the domain is implicit but not named}.

Do NOT load for {clearly out-of-scope topic that a sibling skill owns}.

<!--
DE CI check DOMAIN-004: this section must exist and be non-empty.
-->

## Scope

In scope: {explicit list of tables, views, metrics, fee types, business concepts owned by this skill}
Out of scope: {what belongs to sibling skills — name them — and the user-facing boundary}
Last verified: {YYYY-MM-DD today}

<!--
DE CI checks DOMAIN-001 / 002 / 003 — all three lines mandatory and exactly in
this order. Last verified date must be ISO and ≤90 days old at the time of
deployment to the DBX workspace.
-->

## Critical Warnings

1. **Tier 1 — silent wrong numbers:** {missing filter, wrong join key, or
   wrong aggregation that produces inflated/depressed totals without raising
   any error. Be explicit: state the filter, the column, and the SQL fragment
   that prevents the failure.}
2. **Tier 2 — aggregate inflation:** {summing snapshot data across dates,
   double-counting via M:N joins, mixing daily and lifetime metrics, etc.}
3. **Tier 3 — dependencies / edge cases:** {table refresh timing, late-
   arriving rows, cross-region replication lag, deprecated values still in
   live data, etc.}

<!--
DE CI checks DOMAIN-005 / 006 / 007: this section must be a numbered list,
ordered by severity tier with Tier 1 first. At least one Tier 1 entry is
strongly recommended for any skill that exposes aggregations.
-->

## Core Concepts

| Concept | What It Is | Aliases |
| --- | --- | --- |
| **{Concept 1}** | {one-line definition grounded in a source table or view} | {alt name 1}, {alt name 2} |
| **{Concept 2}** | {one-line definition} | {alias} |

<!--
Target 5–15 concepts. If you exceed 15, your skill is probably two skills —
split before shipping. If you have fewer than 5, the skill may be too narrow
to merit retrieval; consider folding into a sibling.
-->

## Query Patterns

### Pattern 1 — {goal in plain English}

```sql
SELECT ...
FROM {catalog}.{schema}.{view}
WHERE {non-negotiable filter}
  AND etr_ymd BETWEEN '{YYYY-MM-DD}' AND '{YYYY-MM-DD}';
```

Use when: "{trigger phrase 1}", "{trigger phrase 2}".

### Pattern 2 — {goal}

```sql
{SQL}
```

Use when: "{trigger}".

### Pattern 3 — {goal}

```sql
{SQL}
```

Use when: "{trigger}".

### Pattern 4 — {goal}

```sql
{SQL}
```

Use when: "{trigger}".

<!--
4 patterns is the DE recommendation. Each pattern: ≤15 lines of SQL, with the
critical filter visible (not hidden behind a CTE the user has to read).
-->

## External Data Sources (optional — include iff `external_references:` is populated)

This section is the human-readable companion to the `external_references:` frontmatter block. Include it whenever any anchor cited by this skill lives outside Databricks UC — Synapse-only tables, hybrid Synapse+UC tables where the UC bronze is partial, external SaaS (Actimize, ComplyAdvantage, Salesforce, Tableau workbooks, spreadsheets), or pure procedural knowledge (stored procs, runbook rules).

> **Locality caveat.** The objects listed here are NOT queryable from a default Databricks notebook today. Each row lists the locality, the source system, the role of the object in this domain, and the bridge strategy — i.e. the one-line instruction for how to reach the data.

| Object | Locality | Source system | Role | Bridge strategy |
|---|---|---|---|---|
| `{Schema.Object}` | `synapse_only` | `sql_dp_prod_we` | {what the object is / does} | Query via the Synapse MCP server `user-synapse_prod_sql` (read-only) / `user-synapse_sql` (write). |
| `{Schema.Object}` | `hybrid_synapse_uc` | `sql_dp_prod_we` ↔ `main.bi_db.{bronze_copy}` | {what's in UC vs what's only in Synapse} | Use UC bronze for {column subset}; reach into Synapse via MCP for {columns / business-day boundary}. |
| `{System.Object}` | `external_system` | `Actimize` / `ComplyAdvantage` / `Salesforce` / Tableau workbook ID | {what role the source plays} | {how to reach it — vendor UI / CSV drop / Fivetran connector / contact owner}. |
| `{StoredProc / Runbook}` | `manual_only` | `BackOffice.{SP}` / Confluence page | {what business logic this encodes} | Read the SP body in `knowledge/synapse/Wiki/...` and the Confluence page; no automated query. |

After the table, add prose paragraphs (one per `external_references` entry) when the bridge strategy needs more than one line — e.g. "the Actimize CDD score is reflected downstream in `BI_DB_dbo.BI_DB_RiskAlertManagementTool.AlertSeverityScore`; for the raw decision and threshold settings, query the Actimize UI directly with credentials from the Compliance Eng team."

<!--
This section is enforced ONLY when external_references is non-empty in frontmatter.
It is the human-readable explanation a consumer reads when they hit a non-UC anchor.
Without it, the agent might dutifully cite the Synapse table name and then fail to
tell the user that the data isn't actually reachable from a UC query.
-->

## Cross-Domain Notes (shape B only — delete this section for single-domain skills)

This skill spans the {Domain A} and {Domain B} super-domains. The bridge is
{join column / referenced entity}. When the question explicitly names only one
domain, prefer the single-domain sibling skill ({sibling-skill-id}); load this
cross-domain skill only when the question requires data from BOTH sides.

Sibling skills this one defers to:
- `{single-domain-skill-id-A}` — owns {Domain A}-only questions
- `{single-domain-skill-id-B}` — owns {Domain B}-only questions

## Additional Context (optional)

Use this space for hierarchies, flag combinations, or domain structure that
doesn't fit the table format above. Keep total file under 500 lines (DE check
QUAL-003).

## Sources Consulted (optional appendix, per `/speckit.skill` Phase 2.5)

Track which sources you actually consulted while authoring this skill. One row
per (anchor, source) pair. `Class` column: S = Synapse-first, L = Lake-first,
H = Hybrid. See Phase 2.5 in `.cursor/commands/speckit.skill.md` for tier
definitions.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| main.dwh.gold_..._dim_position | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md | §2.x reason codes, §3.4 NULL gotchas |
| main.dwh.gold_..._dim_position | S | 1b | UC column comments on main.dwh.gold_..._dim_position | quoted verbatim where used |
| main.dwh.gold_..._dim_position | S | 2 | knowledge/ProdSchemas/.../Trade/Tables/Trade.PositionTbl.md | OLTP truth for OrderID null semantics |
| main.dealing.rnd_output_..._bestexec | L | 1a | /Workspace/Repos/dealing/best-execution/Methodology.py | producing notebook |
| main.dealing.rnd_output_..._bestexec | L | 2 | Genie space "Best Execution Q&A" | analyst-curated joins |
| (any) | - | 4-6 | UC SELECT DISTINCT on `<col>` | verification of enum values |
| (any) | - | 5-7 | Atlassian page `<id>` | gap-fill only |

<!--
Optional appendix; not lint-enforced. Acts as an audit trail for the next
agent and a forcing function against the three Phase 2.5 process anti-patterns
(UC-only on Synapse-first, wiki-only on Lake-first, skipping Step A).
Both wiki paths and lake-side sources (notebook paths, pipeline IDs, Genie
space names, DBSQL query IDs) are first-class.
-->

---

<!--
PRE-COMMIT CHECKLIST (mirrors DE CI):
[ ] Frontmatter has id, name, description (≥30 chars, third-person), triggers,
    required_tables (≥1 fully-qualified UC name), version, owner.
[ ] id matches filename stem (cross-* prefix iff shape B).
[ ] required_tables contains ONLY UC FQNs (catalog.schema.table). Anything that
    lives only in Synapse / Actimize / ComplyAdvantage / Salesforce / Tableau
    custom SQL / a stored proc goes into external_references instead.
[ ] If staleness report flagged any anchor as `STALE-CONF`, `GAP-CONF`,
    `OBSOLETE-OK-BUT-GAP`, or Synapse-only by ground-truth UC check →
    external_references is populated AND ## External Data Sources section
    exists. Do NOT drop the anchor — annotate locality instead (see
    knowledge/skills/_AUTHORITY_HIERARCHY.md "NEVER-DROP rule").
[ ] No secrets, tokens, API keys, connection strings (SEC-001).
[ ] No absolute paths, no backslash paths (QUAL-004 / AUTHOR-001).
[ ] ≤500 lines (QUAL-003), ≤100 KB.
[ ] ## When to Use exists (DOMAIN-004).
[ ] ## Scope has all three lines: In scope / Out of scope / Last verified
    (DOMAIN-001 / 002), with ISO date ≤90 days old (DOMAIN-003).
[ ] ## Critical Warnings is a numbered list, severity-ordered Tier 1 → 3
    (DOMAIN-005 / 006 / 007).
[ ] Mandatory pre-creation overlap check ran against /Workspace/.assistant/skills/*
    (no duplicate triggers / required_tables / domain).
[ ] python tools/skills/lint_skill.py <this-file> exits 0.
-->
