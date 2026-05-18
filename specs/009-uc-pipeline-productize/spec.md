# Feature Specification: UC-Pipeline DAG-First Productization

**Feature Branch**: `009-uc-pipeline-productize`
**Created**: 2026-05-17
**Status**: Draft
**Input**: User description: "Productize the uc-pipeline-doc framework as a DAG-anchored headless batch documentation pack for pure Unity Catalog objects across 5 schemas (`de_output`, `bi_output`, `bi_dealing`, `etoro_kpi_prep`, `etoro_kpi`). Document objects in topological order bottom-up; build the lineage DAG once per run and persist it locally; never AI-author column descriptions when no upstream wiki is reachable through the existing Phase 3 routing rules (Synapse gold-mirror wikis, prior UC_generated wikis, uc-domain-doc wikis, bronze-pure-ingest → production-DB wikis, UC-native map). When an upstream is itself in scope, document it first. When an upstream is a terminal root outside our coverage, leave the UC comment null-with-provenance rather than guess. Pack runs unattended from either a Cursor agent loop or a Claude CLI loop."

## Clarifications

### Session 2026-05-17

- Q: Pilot scope across 5 schemas — all in-scope objects, DAG-anchored only, lighthouse-N, or one-schema-first? → A: DAG-anchored only — every in-scope object must trace at least one column transitively to an upstream UC object whose wiki is locatable via Phase 3 Routing Rules 1-5.
- Q: When a column traces to an upstream with no wiki, what's the framework's behaviour — strict null (omit), null-with-provenance, Tier-4 stub, or block-the-object? → A: Block-the-object + bottom-up DAG processing. Walk the DAG ONCE up front, persist it locally, process objects in topological order. Null is acceptable only at terminal roots (no further upstream + no wiki under any rule); never AI-author when an upstream is reachable but undocumented.
- Q: "Anchored upstream" / "documented Tier 1 source" — does this mean the literal Tier 1 etoro production database only? → A: No. It means any wiki body locatable via the existing Phase 3 Rules 1-5 — Synapse gold-mirror wikis, prior UC_generated wikis, uc-domain-doc wikis, bronze-pure-ingest → production-DB wikis (Bonnie's `ProdSchemas/` / `DB_Schema/` coverage), or the UC-native map. The `(Tier N — origin)` column-tag suffix is a separate concept (the deep origin of the description) and is inherited verbatim regardless of which routing rule located the wiki.
- Q: Pilot schemas — final list? → A: `de_output`, `bi_output`, `bi_dealing`, `etoro_kpi_prep`, `etoro_kpi`. (`dealing_output` was on an earlier draft but does not exist in UC; `bi_dealing` is the correct name.)
- Q: Headless runner priority — Cursor agent inside IDE, Claude CLI loop terminal, or both? → A: Both. The entrypoint must work unattended from either, with no productization-specific flags beyond `--schemas`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Headless batch run across 5 schemas (Priority: P1)

The data engineer kicks off a single command (or a Cursor agent prompt) that documents every DAG-anchored Unity Catalog object across the five named schemas. The run completes unattended. Each object that has a documentable upstream gets a four-file artifact set (`.md`, `.lineage.md`, `.review-needed.md`, `.alter.sql`) under `knowledge/UC_generated/{schema}/{Tables|Views}/`. Each schema gets a `_deploy-index.md`. The engineer comes back later, reviews the deploy indexes, and hands off batches to the existing deploy runner.

**Why this priority**: This is the entire reason to productize. The 3-object pilot already proved the per-object framework works; the gap is making it scale unattended to ~80-150 objects without operator babysitting.

**Independent Test**: Run the headless entrypoint with `--schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi` and verify (1) the run terminates, (2) every DAG-anchored object has its four artifact files, (3) every wiki passes the existing twelve hard quality assertions, (4) per-schema deploy indexes exist and tally correctly.

**Acceptance Scenarios**:

1. **Given** none of the five schemas has been documented yet, **When** the operator invokes the headless entrypoint, **Then** the run produces a persistent DAG file, processes objects bottom-up, and emits a four-file artifact set plus per-schema deploy indexes for every DAG-anchored object — terminating with a final summary line that names total / completed / blocked / failed counts.
2. **Given** a prior partial run that completed phases 0-4 for half the universe before terminating, **When** the operator re-runs the headless entrypoint, **Then** the second run reuses cached phase outputs, only re-runs the missing phases for the remaining objects, and converges to the same final-state artifacts.
3. **Given** any single object fails at any phase, **When** the run continues, **Then** the failure is captured in the per-schema deploy index with a one-line cause, downstream objects that depend on the failed object are marked `Blocked (upstream wiki missing)`, and unrelated objects still complete.

---

### User Story 2 — Honest gap reporting when upstream coverage is incomplete (Priority: P1)

The data engineer trusts that when an object's wiki ships, every column description is grounded in a real upstream wiki — never invented from the column name + type. If an upstream object truly has no wiki anywhere reachable through Phase 3 Rules 1-5, the framework either (a) documents that upstream first (if it is itself in scope) or (b) produces a deterministic null-with-provenance comment that names the upstream and the date checked, never a guess.

**Why this priority**: User has flagged "no AI inference slop" as a hard requirement. Without this contract, the whole productized pack loses its trust property and becomes another lossy semantic layer.

**Independent Test**: Construct a test scenario where an in-scope object's upstream has no wiki under any of Rules 1-5. Verify that (1) the framework either authored the upstream first or blocked the downstream, (2) any null-with-provenance comments contain the exact upstream FQN + check date and nothing else, (3) zero columns receive an LLM-authored "best guess" description — verifiable by diffing the produced descriptions against the upstream wiki text for passthrough columns and confirming byte-for-byte equality.

**Acceptance Scenarios**:

1. **Given** an object whose primary upstream is a UC sibling that has no wiki yet AND is itself in scope, **When** the topological run reaches the downstream object, **Then** the downstream is deferred until the upstream wiki has been authored — the upstream's wiki is authored first in the same run.
2. **Given** an object whose only upstream is a bronze-pure-ingest table for which Phase 3 Rule 4 cannot locate any wiki (no row in `_generic_pipeline_mapping.json`, no fallback wiki under any prod-DB repo), **When** the framework reaches that object, **Then** the affected column gets a deterministic null-with-provenance comment of the exact form `Source: {upstream_fqn}.{col}. No upstream wiki cached as of {date}.` — and the gap is logged once at the schema level for follow-up.
3. **Given** any column whose upstream resolves to a known wiki, **When** Phase 5 emits the description, **Then** the description text matches the upstream wiki's description for the same column byte-for-byte (existing Quality Assertion 11 from GOLDEN-REFERENCE), and the AI never adds, removes, or paraphrases the upstream's content for passthrough columns.

---

### User Story 3 — Operator handoff to existing deploy tooling (Priority: P2)

After a headless run, the operator inspects per-schema `_deploy-index.md` files, picks the rows whose status is `Generated`, and runs the existing `tools/deploy_alter_batch.py` to apply UC comments. The deploy runner's contract is unchanged — only the indexes feeding it change: they now include a `Blocked (upstream wiki missing: <fqn>)` row class so the operator can see exactly which objects are waiting on which upstreams.

**Why this priority**: Reuses already-working deploy plumbing. The productized pack must not require operators to learn a new deploy command — it just feeds the existing one cleanly.

**Independent Test**: After a headless run completes, verify that (1) `_deploy-index.md` exists under every documented schema, (2) status counts in each index match the tally of artifact files on disk, (3) calling `tools/deploy_alter_batch.py --deploy-index ...` against any of the indexes succeeds and produces the same `Deployed (Batch N)` row updates that the existing pilot's deploy index supports.

**Acceptance Scenarios**:

1. **Given** a freshly completed headless run, **When** the operator opens any per-schema `_deploy-index.md`, **Then** the index lists every in-scope object with one of these statuses — `Pending`, `Generated`, `Deployed (Batch N)`, `Failed (...)`, `Blocked (upstream wiki missing: <fqn>)`, or `Stub only` — and the header rollup counts match the rows.
2. **Given** the existing `deploy_alter_batch.py` runner, **When** invoked against a produced deploy index, **Then** it picks up `Generated` rows exactly as it does for the dwh-semantic-doc pack — no productization-specific flags needed.

---

### Edge Cases

- **Terminal root with no wiki anywhere**: Column gets the deterministic `Source: {fqn}.{col}. No upstream wiki cached as of {date}.` placeholder. The schema-level gap is logged. The operator's follow-up is to either author that upstream's wiki (outside this pack) or accept the null-with-provenance form indefinitely.
- **DAG cycle detected during topological sort**: The run aborts at DAG-build with a clear error naming the cycle. UC's `system.access.table_lineage` should never produce cycles, but if a self-join or recursive CTE somehow surfaces one, we fail loud rather than silently process the wrong order.
- **Schema gains or loses an object mid-run**: The DAG snapshot taken at run start is authoritative for the entire run. Changes to UC during a run are picked up on the next run.
- **Mid-run failure (network, auth, transient SQL error)**: Phase output is persisted to disk after each phase per-object. Re-running the entrypoint skips phases whose outputs exist and resumes from the first missing one. Operator never has to "rewind" manually.
- **Object whose lineage is entirely opaque**: a JOB-written EXTERNAL Delta whose source code is not fetchable AND whose `system.access.column_lineage` rows are empty. Object is skipped with a sidecar entry. Schema card lists it as out-of-scope with reason `no lineage signal available`.
- **An in-scope object's wiki already exists from a previous run**: Idempotent skip. The existing wiki passes through to the deploy index as `Generated` if not yet deployed, or `Deployed (Batch N)` if a prior deploy ran.
- **Pilot object set is small in some schemas**: That's fine. The pack does not require a minimum object count per schema; even a schema with 2 DAG-anchored objects gets its `_deploy-index.md` and its artifact files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Pilot universe)**: The pack MUST restrict its processing to the five named UC schemas — `de_output`, `bi_output`, `bi_dealing`, `etoro_kpi_prep`, `etoro_kpi`. No object outside these schemas is documented by this pack, regardless of its lineage.
- **FR-002 (DAG-anchored scope rule)**: An object in one of the five schemas is *in scope* if and only if at least one of its columns traces transitively to an upstream UC object whose wiki can be located via Phase 3 Routing Rules 1-5 (Synapse gold-mirror, UC_generated sibling, uc-domain-doc, bronze pure-ingest → production-DB wiki, or UC-native map). Objects with zero anchored upstreams MUST be logged as `out-of-scope: no anchored upstream wiki` in the schema card and not processed further.
- **FR-003 (One-shot DAG build)**: The framework MUST compute the column-lineage DAG once per run by querying `system.access.column_lineage` and `system.access.table_lineage` ONCE at run start. The DAG MUST be persisted to disk as a structured JSON artifact (one per run or one global, plus per-schema views). Phases 0-6 MUST NOT issue further queries against `system.access.*` tables during the same run.
- **FR-004 (Topological bottom-up processing)**: For each schema in scope, in-scope objects MUST be processed in topological order, with upstreams processed before their downstreams. When an upstream is itself in scope but not yet documented, the downstream MUST be deferred until the upstream wiki is authored. Failed upstreams MUST mark their downstream subtree as `Blocked (upstream wiki missing: <fqn>)` in the deploy index.
- **FR-005 (Zero-inference contract)**: The framework MUST NOT generate column descriptions from the column name + type alone. For every column, the description text MUST come from one of three sources: (a) verbatim inheritance from an existing upstream wiki (passthrough / rename / cast columns); (b) deterministic narration of source code that exists locally (CASE / arithmetic / aggregate columns whose view DDL or notebook body is in the source-code snapshot); (c) a deterministic null-with-provenance placeholder of the exact form `Source: {fqn}.{col}. No upstream wiki cached as of {date}.` when neither (a) nor (b) is satisfiable. This requirement MUST be enforceable by a validator pass with zero false positives on the existing 3-object pilot.
- **FR-006 (Headless entrypoint)**: The pack MUST expose a single command that runs phases 0-6 end-to-end across all five schemas in one invocation, with no required interactive prompts during normal-path execution. The entrypoint MUST work when invoked from a Claude CLI loop terminal as well as from a Cursor agent prompt. Authentication MUST piggy-back on the existing `DATABRICKS_TOKEN` / `DATABRICKS_MCP_PROFILE` mechanisms; no new auth surface.
- **FR-007 (Phase idempotency)**: Every phase MUST persist its output to disk before yielding to the next phase. Re-running the entrypoint MUST detect existing phase outputs and skip those phases for the affected objects unless a `--force` flag is supplied. The same input MUST produce the same output bytes across runs (modulo `generated_at` timestamps).
- **FR-008 (Per-schema deploy indexes)**: Each of the five schemas MUST produce a `_deploy-index.md` that lists every in-scope object with one of these status classes — `Pending`, `Generated`, `Deployed (Batch N) — YYYY-MM-DD`, `Failed (deploy Batch N)`, `Blocked (upstream wiki missing: <fqn>)`, or `Stub only`. Header rollup counts MUST match the per-row tally. The format MUST be byte-compatible with the existing `tools/deploy_alter_batch.py` runner — no new flags required.
- **FR-009 (Quality-assertion preservation)**: Every produced `.md` wiki file MUST pass all twelve hard quality assertions defined in `.cursor/rules/uc-pipeline-doc/GOLDEN-REFERENCE.mdc` Section B. A thirteenth assertion MUST be added and enforced: "every passthrough column with no upstream wiki has either been omitted from `.alter.sql` or carries the deterministic null-with-provenance placeholder; no LLM-authored description for an un-anchored column exists anywhere in the produced `.md` files."
- **FR-010 (Sidecar gap log)**: For every column where the framework had to fall back to null-with-provenance, the corresponding `.review-needed.md` sidecar MUST log the gap with the upstream FQN and the routing-rule attempts made. For every object marked `out-of-scope: no anchored upstream wiki`, the schema card MUST log the object name and the reason. The operator's follow-up backlog MUST be derivable mechanically from these two artifacts (no hidden gaps).
- **FR-011 (Audit summary)**: At the end of each headless run, the entrypoint MUST emit a one-page summary to stdout (also persisted as a Markdown file under `knowledge/UC_generated/_runs/{timestamp}/summary.md`) listing per-schema counts for in-scope, out-of-scope, generated, deployed, blocked, and failed objects, plus the total wall-clock time, the number of `system.access.*` queries issued (target: 1), and any unresolved errors. The operator MUST be able to judge run health by reading the summary alone.
- **FR-012 (Order independence within a topological layer)**: Within a single topological layer (objects whose upstreams are all already documented or out of scope), processing order MUST NOT affect output content. Two runs that process the same layer in different intra-layer orders MUST produce the same final artifact bytes (modulo `generated_at`).

### Key Entities

- **Pilot universe**: The closed set of UC schemas in scope — `de_output`, `bi_output`, `bi_dealing`, `etoro_kpi_prep`, `etoro_kpi`.
- **Lineage DAG**: Directed acyclic graph where nodes are UC objects (both in-scope and their transitive upstreams) and edges are column-lineage relationships. Persisted as a single structured artifact with one node entry per UC object and per-node `wiki_status` of `documented_external` (Phase 3 Rules 1, 3, 4, 5 — wiki exists outside this pack), `documented_in_pack` (Phase 3 Rule 2 — wiki already authored by this pack), `in_scope_not_yet_authored` (will be authored later in the same run), `terminal_no_wiki` (no upstream and no wiki — null-with-provenance candidate), or `out_of_scope` (no anchored upstream).
- **In-scope object**: A node belonging to one of the five schemas with at least one column whose ultimate upstream has `wiki_status` in `{documented_external, documented_in_pack, in_scope_not_yet_authored}`.
- **Anchored upstream wiki**: Any wiki body located by Phase 3 Rules 1-5 — distinct from the `(Tier N — origin)` column tag suffix, which is inherited verbatim from the upstream wiki regardless of which routing rule found the wiki.
- **Terminal root**: An upstream UC object with no further upstream and no wiki under any of Phase 3 Rules 1-5. Columns sourced from it get the null-with-provenance placeholder.
- **Blocked object**: An in-scope object whose at least one upstream is also in scope but has not yet been documented in the current run. Stays in `Blocked` state until the upstream wiki ships, then re-enters the processing queue automatically.
- **Per-schema deploy index**: One `_deploy-index.md` per documented schema; the operator's single source of truth for what to deploy and what is waiting on what.
- **Audit run summary**: One Markdown file per run under `knowledge/UC_generated/_runs/{timestamp}/summary.md` that captures the entire run's tally and any errors. Lets the operator answer "did this work?" in under a minute.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (Coverage)**: At least 80% of DAG-anchored objects across the five schemas complete phases 0-5 within one headless run. The remaining ≤20% are explicitly explainable (failed dependency, transient error, deferred for follow-up) and listed in the audit summary.
- **SC-002 (Quality preservation)**: 100% of completed wikis pass all twelve hard quality assertions from `GOLDEN-REFERENCE.mdc` plus the new Assertion 13 (no AI-inferred descriptions for un-anchored columns). A pre-deploy validator pass MUST return zero hard failures across the entire pilot universe before any deploy is attempted.
- **SC-003 (Zero inference)**: For every passthrough column in every produced wiki, the description text matches the corresponding upstream wiki's description for the same column byte-for-byte. For every un-anchored column, the description is either absent from `.alter.sql` or matches the exact null-with-provenance placeholder template. Both are mechanically verifiable.
- **SC-004 (Idempotency)**: A second run of the headless entrypoint with the same scope and the same UC state produces a byte-identical artifact set against the first run, modulo `generated_at` timestamps and modulo the audit-run-summary path. Verifiable by `diff -r` comparison.
- **SC-005 (UC query budget)**: Across one full headless run, the framework issues at most one `system.access.column_lineage` query and one `system.access.table_lineage` query — both during the DAG-build phase. Verifiable from a Databricks `query_history` audit on the warehouse used.
- **SC-006 (Operator simplicity)**: A new operator can complete a full headless run + deploy of one schema using only the existing `tools/deploy_alter_batch.py` runner and the new headless entrypoint, with no productization-specific flags beyond `--schemas`. Measurable by walking a new operator through the flow start-to-finish in under 15 minutes of guidance.
- **SC-007 (Gap visibility)**: After a run, the operator can answer "which objects are blocked, on which upstreams?" in under 30 seconds by reading per-schema `_deploy-index.md` files alone. The audit-run summary MUST tally Blocked objects per upstream FQN so the operator can prioritize follow-up upstream wiki authoring by impact.
- **SC-008 (Wall-clock)**: One full headless run across all five schemas completes within a wall-clock budget appropriate to the DAG size — soft target: under one hour for ~100 objects given typical UC query latency. The audit summary breaks down time spent per phase so regressions are visible.

## Assumptions

- The five named schemas are the chosen pilot universe; expansion to more schemas is explicitly a follow-up spec.
- Existing Phase 3 routing rules (Rules 1-5) at `.cursor/rules/uc-pipeline-doc/03-upstream-wiki-bridge.mdc` are correct and complete for the pilot universe; no new routing rules are introduced in this spec.
- The existing twelve hard quality assertions in `.cursor/rules/uc-pipeline-doc/GOLDEN-REFERENCE.mdc` Section B remain the quality bar; this spec adds Assertion 13 but does not soften any existing assertion.
- The existing `tools/deploy_alter_batch.py` runner is the deploy mechanism; this spec does NOT introduce a new deploy tool.
- The existing 3-object pilot (`v_fact_customeraction_enriched`, `v_fact_customeraction_w_metrics`, `de_output_etoro_kpi_fact_customeraction_w_metrics`) is the reference implementation; the productized pack must produce equivalent-quality output for that DAG as a regression test.
- Authentication uses the existing `DATABRICKS_TOKEN` / `DATABRICKS_MCP_PROFILE` mechanisms; no new auth surface.
- The pack is a solo workload — only one headless run executes at a time per repo checkout; concurrent-run coordination is not required.

## Out of Scope

- Schemas other than the five named ones (e.g. `dwh`, `bi_db`, `general`, acquired-company schemas owned by `uc-domain-doc`).
- Bronze-tier or production-DB wiki *authoring* (the pack consumes those wikis but never authors them).
- Synapse mirror or pure-DWH-family object documentation (already covered by `dwh-semantic-doc`).
- Cross-pack enrichment — for example, automatic downstream comment propagation from a UC_generated wiki into a Synapse mirror — is explicitly deferred to a follow-up spec.
- New routing rules in Phase 3 — if the pilot run surfaces routing gaps, fixes go into the existing `03-upstream-wiki-bridge.mdc` under a separate change request, not into this spec.
- A new deploy tool — the existing `tools/deploy_alter_batch.py` is the contract.
- Real-time / streaming refresh of UC comments — this pack is a batch documentation tool, not a continuous-sync mechanism.
