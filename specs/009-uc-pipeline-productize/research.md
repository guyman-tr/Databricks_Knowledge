# Phase 0 Research: UC-Pipeline DAG-First Productization

**Feature**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## R-1: One-shot DAG schema

**Decision**: Persist the lineage DAG as a single `knowledge/UC_generated/_dag.json` file built by a new Phase -1 tool `tools/uc_pipelines/build_dag.py`. Schema validated by `contracts/dag.schema.json`.

**Two SQL queries** at run start, joined locally in Python:

```sql
-- Q1: edges (column-level lineage) — single query against system.access.column_lineage
SELECT
  source_table_full_name,
  target_table_full_name,
  source_column_name,
  target_column_name,
  COUNT(*) AS event_count_90d
FROM system.access.column_lineage
WHERE event_time >= current_date() - INTERVAL 90 DAYS
  AND target_table_schema IN ('de_output', 'bi_output', 'bi_dealing', 'etoro_kpi_prep', 'etoro_kpi')
  AND source_table_full_name IS NOT NULL
GROUP BY 1, 2, 3, 4;

-- Q2: node metadata for every node touched by Q1 — single query against information_schema
SELECT
  table_catalog || '.' || table_schema || '.' || table_name AS full_name,
  table_schema,
  table_type
FROM system.information_schema.tables
WHERE table_catalog || '.' || table_schema || '.' || table_name IN ({union_of_sources_and_targets});
```

Per-node `wiki_status` is then computed in Python (zero further UC queries) by:

1. **`documented_in_pack`**: file exists under `knowledge/UC_generated/{schema}/{Tables|Views}/{object}.md`.
2. **`documented_external`**: Phase 3 Rules 1, 3, 4, 5 hit — checked by reading `knowledge/UC_generated/_index_cache/upstream_wikis.json` (built once at run start from the existing pipeline-mapping JSON + Synapse generated tree + uc-domain-doc tree + UC-native map).
3. **`in_scope_not_yet_authored`**: node is in one of the 5 pilot schemas AND no wiki yet AND has at least one column traceable to a `documented_*` upstream.
4. **`terminal_no_wiki`**: node has no upstream rows in Q1 (terminal root) AND no wiki anywhere.
5. **`out_of_scope`**: node is in one of the 5 pilot schemas but has zero `documented_*` transitive upstreams.

**Alternatives considered**:

- **Per-object lineage caches** (status quo): each `tools/uc_pipelines/build_lineage.py` invocation issues its own UC queries. Rejected because that's O(N) queries per run (~150 objects × 2 queries each), blows the SC-005 budget by ~300x, and slows the run to ~3-5 hours.
- **In-memory DAG with no persistence**: would force a single-process run. Rejected because operators may want to inspect the DAG, re-run with `--phases 3-5` after a fix, or hand the JSON to a separate analyst. Persistence is cheap (~1-2 MB JSON) and enables both.
- **Per-schema DAGs**: rejected because cross-schema edges are legitimate (e.g., `de_output.X` reads `etoro_kpi_prep.Y`). One DAG keeps all edges intact.

## R-2: Topological-sort semantics

**Decision**: Kahn's algorithm with stable tie-breaking by `full_name`. Process order:

1. Start with all nodes whose `wiki_status ∈ {documented_external, documented_in_pack, terminal_no_wiki}` already (no in-scope dependency to wait for).
2. After each layer completes, recompute the `in_scope_not_yet_authored` candidates: a node moves to the ready queue when ALL its in-scope upstreams have transitioned to `documented_in_pack`.
3. If at the start of a layer there are `in_scope_not_yet_authored` nodes whose upstreams are themselves `in_scope_not_yet_authored` AND those upstreams are not in the ready queue → cycle. Abort with the offending cycle named.

**Special cases**:

- **Terminal-no-wiki upstream**: downstream nodes proceed; affected columns get the null-with-provenance placeholder via Phase 5's `(Tier 5 — terminal-no-wiki)` exit (existing GOLDEN-REFERENCE Assertion 8 — Source Authority Tag). No blocking.
- **Out-of-scope sibling**: a pilot-schema object whose only upstreams are `out_of_scope` is itself reported as out-of-scope in the schema card with reason `no anchored upstream wiki transitively`. No artifact files produced.
- **Object with mixed-anchor upstreams** (some `documented_*`, some `terminal_no_wiki`): IN scope. Documented columns inherit; null-with-provenance columns flagged.

**Alternatives considered**:

- **DFS post-order**: simpler but produces a different intra-layer order across re-runs, breaking FR-012 (order-independence within a layer). Rejected.
- **Process-as-you-discover**: would mean Phase -1 also runs phases 0-6 for each leaf as it pops them. Rejected because it couples DAG build to phase execution and prevents `--dry-run` (which only needs the DAG).

## R-3: No-inference enforcement

**Decision**: The validator at `tools/uc_pipelines/validate_pipeline_wiki.py` gets a new mode `--assert-no-inference` that, for every column in every produced `.md` Elements table, checks one of three things:

1. **Passthrough column** (`column_lineage` shows a single upstream + no transformation): description text MUST equal the upstream wiki's description for that upstream column, byte-for-byte (whitespace-normalized, trailing-period tolerant). Comparison uses the cached upstream wiki JSON; no extra UC queries.
2. **Source-code-narrated column** (the column appears in a CASE expression / arithmetic / aggregate in the cached source-code snapshot): description must reference at least one of (a) the source-code line range, (b) the operator (`CASE`, `+`, `SUM`), or (c) a quoted SQL fragment from the snapshot. Mechanically detectable: regex of source-code fragment substring or line-range match.
3. **Null-with-provenance column**: description exactly matches the template `Source: {upstream_fqn}.{col}. No upstream wiki cached as of {date}.` for some valid `{upstream_fqn}`, `{col}`, `{date}`.

Anything else → hard failure (`assertion13_failed`). Validator exits non-zero. The headless runner treats any hard failure as object-level fail in the deploy index.

**Pilot regression test**: run `validate_pipeline_wiki.py --assert-no-inference` against the existing 3-object pilot wikis. They MUST all pass. If they don't, the contract is too strict and must be relaxed before any rollout.

**Alternatives considered**:

- **LLM-based reviewer pass**: rejected — defeats the purpose. Self-referential.
- **Spot-check sampling**: rejected — SC-003 demands 100% byte-for-byte coverage.
- **Trust the producer**: rejected — the entire reason Principle XI exists is that producers (humans and LLMs) drift. Mechanical enforcement is the only defense.

## R-4: Idempotency and resumability

**Decision**: Phase checkpoint marker per-object. Each phase tool writes its output to a canonical path; the orchestrator checks `Path.exists()` before invoking the phase. `--force` re-runs every phase regardless. `--phases <subset>` runs only the requested phases.

**Canonical phase outputs per object**:

| Phase | Output file | Skip if exists? |
|---|---|---|
| -1 (DAG) | `knowledge/UC_generated/_dag.json` | Yes (run-level, not per-object) |
| 0 (Schema card) | `knowledge/UC_generated/{schema}/_schema_card.md` | Yes |
| 1 (Inventory) | `knowledge/UC_generated/{schema}/_discovery/uc_inventory.json` | Yes (run-level) |
| 2 (Source code) | `knowledge/UC_generated/{schema}/_discovery/source_code/{object}.sql` (or `.py`) | Yes |
| 3 (Upstream bridge) | `knowledge/UC_generated/{schema}/_discovery/upstream_wikis/{object}.json` | Yes |
| 4 (Column lineage) | `knowledge/UC_generated/{schema}/_discovery/column_lineage/{object}.json` | Yes |
| 5 (Generate doc) | `.md` + `.lineage.md` + `.review-needed.md` | Yes (all three must exist) |
| 6 (Deploy ALTER) | `.alter.sql` | Yes |

**`generated_at` exclusion**: the only piece of state that differs across runs is the ISO timestamp in frontmatter. SC-004 (idempotency) tolerates this single field; the rest must be byte-identical.

**Alternatives considered**:

- **SQLite state DB**: rejected — adds a new storage layer. Filesystem checkpoints are sufficient and operator-inspectable.
- **Per-phase hash check** (only re-run if input hash changed): rejected for the pilot — adds complexity. Filesystem mtime + explicit `--force` is enough for now.

## R-5: Three rule-file deltas

Exact edits to existing `.cursor/rules/uc-pipeline-doc/` files. None of these add new phases; all clarify existing behavior.

### Delta 1 — `03-upstream-wiki-bridge.mdc`

Add subsection at the end of the existing routing-rules table:

```text
## Rule 6 — Terminal-Root Null-with-Provenance Fallback

When Rules 1-5 ALL miss for an upstream column whose source object also has zero further upstreams in `system.access.column_lineage` (a terminal root), the framework emits a deterministic placeholder of the exact form:

    Source: {upstream_fqn}.{col}. No upstream wiki cached as of {check_date}.

This placeholder is emitted ONLY at terminal roots — not for in-scope-but-not-yet-authored upstreams. The latter case defers the downstream object's processing until the upstream wiki exists in this same run; see `run_pipeline.py` topological-sort behaviour.

The check_date is ISO-8601 (YYYY-MM-DD), taken from the run's start time. The placeholder counts as a `(Tier 5 — terminal-no-wiki)` source authority tag in the Elements table.
```

### Delta 2 — `05-generate-doc.mdc`

Add subsection after "§5 Element rows":

```text
## §6 No-Inference Contract

The agent MUST source every column description from one of three places, in priority order:

1. The cached upstream wiki body (`.json` index from Phase 3). For passthrough / rename / cast columns, copy the upstream description verbatim, preserving the `(Tier N — origin)` suffix. No paraphrasing.

2. The cached source code snapshot (`.sql` / `.py` from Phase 2). For CASE-expression / arithmetic / aggregate / window-function columns, narrate what the code does. The narration MUST reference at least one of (a) the source-code line range, (b) the SQL operator (`CASE`, `+`, `SUM`, `LAG`), or (c) a quoted SQL fragment ≤80 chars. Use the same `(Tier 2 — Synapse code, {object})` style tag as the dwh-semantic-doc pack.

3. The null-with-provenance template from Rule 6 of `03-upstream-wiki-bridge.mdc`. Use this ONLY when Phases 1, 2, AND 3 all yielded no source; that is, the column is sourced from a terminal-no-wiki upstream.

Inferring a description from the column name plus its UC data type is a Principle XI violation and a hard validator failure. There is no fourth option.
```

### Delta 3 — `GOLDEN-REFERENCE.mdc`

Append to Section B (Hard Quality Assertions):

```text
### Assertion 13 — No AI-inferred descriptions for un-anchored columns

Every column in the produced `.md` Elements table MUST satisfy ONE of:

a) Its description is byte-for-byte equal to the corresponding upstream column's description in the Phase-3 cached upstream wiki, after whitespace normalization and trailing-period tolerance.

b) Its description references at least one of (i) a source-code line range from the Phase-2 cached snapshot, (ii) a SQL operator that appears in that snapshot for this column, or (iii) a quoted SQL fragment that appears in the snapshot.

c) Its description exactly matches the null-with-provenance template:
    Source: {upstream_fqn}.{col}. No upstream wiki cached as of {check_date}.

Violations are hard failures. The validator at `tools/uc_pipelines/validate_pipeline_wiki.py --assert-no-inference` exits non-zero on any violation. No exception path. No grandfather clause; the 3-object pilot must also pass.
```

## R-6: Audit summary format

**Decision**: One Markdown file per run at `knowledge/UC_generated/_runs/{ISO8601_timestamp}/summary.md`. Shape:

```markdown
# Run Summary — 2026-05-17T19:00:00Z

**Schemas**: de_output, bi_output, bi_dealing, etoro_kpi_prep, etoro_kpi
**Wall-clock**: 47m 12s
**UC queries**: 2 (column_lineage, table_lineage — both during Phase -1)
**Phases run**: -1 → 6
**Force**: false

## Per-schema rollup

| Schema | In-scope | Out-of-scope | Generated | Deployed | Blocked | Failed |
|---|---|---|---|---|---|---|
| de_output | 18 | 4 | 17 | 0 | 1 | 0 |
| bi_output | 31 | 8 | 28 | 0 | 2 | 1 |
| bi_dealing | 6 | 2 | 6 | 0 | 0 | 0 |
| etoro_kpi_prep | 22 | 5 | 22 | 3 | 0 | 0 |
| etoro_kpi | 14 | 3 | 13 | 0 | 1 | 0 |
| **TOTAL** | **91** | **22** | **86** | **3** | **4** | **1** |

## Blocked objects (by upstream)

| Upstream FQN | Blocking N objects | Routing-rule attempts |
|---|---|---|
| main.bronze_db_schema.foo | 2 | Rule 4 missed (no entry in _generic_pipeline_mapping.json) |
| main.bronze_db_schema.bar | 2 | Rule 4 missed |

## Phase time breakdown

| Phase | Wall-clock | Rows |
|---|---|---|
| -1 (DAG build) | 0m 38s | 1248 lineage rows; 280 nodes |
| 0 (schema cards) | 0m 04s | 5 schemas |
| 1 (inventory) | 0m 12s | 5 schemas |
| 2 (source code) | 8m 21s | 91 objects (3 failed to fetch) |
| 3 (upstream bridge) | 6m 09s | 91 objects |
| 4 (column lineage) | 12m 47s | 91 objects |
| 5 (generate doc) | 14m 51s | 91 objects |
| 6 (ALTER) | 4m 10s | 86 objects |

## Errors

(none, or per-object error rows naming the phase + object + cause)
```

## R-7: Cross-runtime parity

**Decision**: Single Python entrypoint `python tools/uc_pipelines/run_pipeline.py`. Both Cursor agent and Claude CLI loop invoke the exact same command. No runtime detection. No conditional logic on `os.environ.get('CURSOR') vs 'CLAUDE_CLI'`.

**Env-var requirements** (already satisfied by existing pipelines):

- `DATABRICKS_TOKEN` and `DATABRICKS_SERVER_HOSTNAME` for SQL queries (existing `_conn.py`)
- `DATABRICKS_MCP_PROFILE` optional override
- `WORKSPACE_API_TOKEN` (or reuses `DATABRICKS_TOKEN`) for `fetch_writer_source.py` notebook fetch
- No new vars introduced by this spec

**Cursor invocation**: agent prompt like "Run `python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi` and report the summary."

**Claude CLI invocation**: same command, run from terminal. CLI loop wrapper (optional helper at `tools/uc_pipelines/loop_runner.sh`) just runs `run_pipeline.py` then sleeps and re-runs hourly if `--watch` is supplied. The watch loop is out-of-scope for this spec — Phase 2 productization adds it only if the user later asks for it.

**Alternatives considered**:

- **Two scripts** (one per runtime): rejected — drift risk.
- **Cursor skill wrapping a Python tool**: rejected for this spec; if needed, a follow-up Skill spec adds a SKILL.md per Principle X.

## R-8: Schema-level parallelism

**Decision**: Single Python coordinator process at `tools/uc_pipelines/run_pipeline.py` uses `concurrent.futures.ProcessPoolExecutor(max_workers=4)` to fan-out per-schema workers. Wave-1 / Wave-2 ordering derived from the column-lineage DAG:

```text
Wave 1 (parallel, 4 workers):
  de_output           ──┐
  bi_output           ──┤
  bi_dealing          ──┼── ProcessPoolExecutor.map(_process_schema, ...)
  etoro_kpi_prep      ──┘

Wave 2 (sequential, after Wave 1 completes):
  etoro_kpi           ── _process_schema('etoro_kpi')
```

**Why parallel-safe**: post-DAG-build, no worker queries `system.access.*` or `system.information_schema.*`. Every per-object phase reads cached JSON (the per-run `_dag.json` and the per-run `_index_cache/upstream_wikis.json`) plus local source-code snapshots. The only shared mutable state is the per-schema artifact directory under `knowledge/UC_generated/{schema}/`, and schemas don't collide.

**Coordinator responsibilities** (in `run_pipeline.py`):

1. Parse `--schemas` and validate against the 5-schema pilot universe.
2. Phase -1 — build DAG once. Single process. Writes `_dag.json`.
3. Phase 0 (one-off) — build upstream wiki cache once. Single process. Writes `_index_cache/upstream_wikis.json`.
4. Compute schema-level wave assignment from the DAG. Currently hard-coded but auto-derivable: any schema whose only in-scope upstream-edges land in *itself* OR in `documented_*` nodes goes to Wave 1; any schema with an edge to another in-scope schema's `in_scope_not_yet_authored` node goes to Wave 2+. For the pilot, only `etoro_kpi → etoro_kpi_prep` triggers Wave 2.
5. Wave 1 — `ProcessPoolExecutor.map(_process_schema, wave1_schemas)` with `max_workers=min(4, len(wave1_schemas))`.
6. Wait for Wave 1 to complete. Collect per-schema results into in-memory rollup.
7. Wave 2 — single-process `_process_schema('etoro_kpi')` (or skip if Wave 1 produced no `etoro_kpi_prep` wiki AND no prior wiki exists).
8. Write stitched audit summary to `_runs/{ts}/summary.md`.

**Worker contract** (`_process_schema(schema)` in `run_pipeline.py`):

- Pure function — takes a schema name, returns a per-schema result dict.
- Reads `_dag.json` and `_index_cache/upstream_wikis.json` lazily from disk inside the worker (each worker re-imports the modules but doesn't re-query UC).
- Runs phases 0-6 for every in-scope object in that schema, in topological order within the schema.
- Writes its per-object artifact files under `knowledge/UC_generated/{schema}/`.
- Returns: `{'schema': str, 'generated': int, 'blocked': int, 'failed': int, 'out_of_scope': int, 'errors': [(object, phase, cause)]}`.
- Stdout prefixed with `[{schema}]` so interleaved logs are readable. Coordinator can disambiguate easily by parsing the prefix.

**`--max-parallelism` flag**: defaults to `4`. Setting to `0` or `1` forces sequential execution (for debugging or warehouse-contention-constrained environments). The flag caps but does not increase concurrency — wave size limits still apply.

**Failure isolation**: a hard exception inside one worker does not abort the other workers. `ProcessPoolExecutor.map` collects all results; the coordinator surfaces the failed schemas in the audit summary's `Errors` section with exit code 1 (per CLI contract). Wave 2 proceeds even if a Wave 1 worker failed, unless the failed worker was specifically `etoro_kpi_prep` — in that case the coordinator skips `etoro_kpi` (Wave 2) with a clear `Blocked (upstream wiki failed in same run)` row in `etoro_kpi`'s deploy index.

**UC warehouse contention**: workers issue zero UC queries during phases 0-6 (queries are coordinator-only at Phase -1 and Phase 0-cache-build). The only network traffic per worker is the Workspace API call in Phase 2 (notebook source fetch). The Workspace API tolerates 10-20 concurrent calls comfortably; 4 workers × ~30 objects each, paced one at a time per worker = ~4 concurrent API calls peak. No risk.

**Memory profile**: ~80MB per worker × 4 workers + ~100MB coordinator = ~420MB peak. Well within laptop-RAM territory.

**Alternatives considered and rejected**:

- **Shell-driver fan-out (option (b))**: each `run_pipeline.py --schema X` builds its own DAG → 5× UC query budget → blows SC-005. Workaround would be a separate "build DAG once" pre-step that effectively recreates option (a). Rejected.
- **Concurrent AI agents (option (c))**: each schema run by a separate Cursor/Claude subagent. Burns 4× LLM context for the same deterministic playbook with zero reasoning gain inside phases 0-6. Useful for *triage* of Failed rows (where reasoning helps) — but that's a separate interactive feature, not a batch-runner concern. Rejected for this spec.
- **Threading instead of process pool**: GIL contention on JSON / SQL processing. ProcessPoolExecutor sidesteps that. Rejected.
- **Increase concurrency above 4**: marginal returns. Workspace API latency and per-object filesystem I/O don't scale linearly past 4 workers on a typical dev machine. Configurable via `--max-parallelism` for future tuning.

## R-9: Adversarial evaluation (Phase 7)

**Decision**: Add an opt-out adversarial evaluator at `tools/uc_pipelines/adversarial_evaluate.py`, modeled on `dwh-semantic-doc/16-adversarial-evaluation.mdc` but adapted to the lighter UC context. Default ON. Disable via `--no-evaluate`. Cap via `--evaluate-sample N` (per schema).

**Why opt-out, not opt-in (revised from initial draft)**: the adversarial evaluator catches the failure mode the mechanical validator can't — semantic correctness of source-code narration and inheritance fidelity beyond byte-equality. The dwh-semantic-doc Phase 16 caught real failures (33 mismatched labels across 89 wiki lines in one audit); we expect the same value here. Default-on protects the first full pilot run from silent quality drift.

**Rubric — UC-adapted, 6 dimensions** (weighted):

| Dimension | Weight | Focus |
|---|---|---|
| Inheritance Fidelity | 35% | For passthrough columns: byte-equality vs. upstream wiki (mandatory T1 Upstream Fidelity table). Same character-level test as dwh Phase 16's Dimension 2, but elevated to dominant weight because UC-pure objects are mostly passthrough. |
| Source-Code Narration Accuracy | 25% | For CASE / arithmetic / aggregate / window columns: evaluator independently reads the cached source-code snippet and judges whether the narration matches what the code does. Spot-check protocol: pick 3 narrated columns at random per object, verify each. |
| Null-with-Provenance Correctness | 15% | For every null-with-provenance column: confirm the upstream actually is a terminal-no-wiki root (no routing rule should have hit). Heuristic check: re-run Phase 3 lookup logic against the upstream FQN and verify all 5 rules miss. |
| Completeness | 10% | Column count vs. UC `information_schema.columns`; all 6 sections present; footer tier counts match Elements; `.alter.sql` column count and names match `.md` Elements. |
| Shape Fidelity | 10% | Matches the GOLDEN-REFERENCE skeleton (section numbering, frontmatter fields, ASCII lineage diagram present). |
| Lineage Coherence | 5% | `.lineage.md` and `.md` agree on every column's source. |

No "Business Meaning" dimension — UC-pure objects don't carry the Synapse-fact narrative burden. No "Data Evidence" dimension — UC pipeline has no live-data sampling phase to gate against.

**Hard gates** (within evaluation):

- **Inheritance Fidelity character-level table** — MANDATORY in evaluator output. Every Tier-1 (passthrough) column appears with verbatim upstream quote and verbatim wiki quote and a YES/NO MATCH column. Same pattern as dwh-semantic-doc; same enforcement (table missing = evaluation INVALID).
- **No AI-inferred description for un-anchored column** — duplicates Assertion 13 from the mechanical validator. Catches anything that slipped past the mechanical check (defense in depth).

**Verdict thresholds** (same as dwh Phase 16):

- ≥7.5 → PASS, object marked `Generated` in deploy index.
- <7.5 → FAIL. Triggers ONE regeneration retry — Phase 5 re-runs for that object with the evaluator's `REGENERATION FEEDBACK` block as context. Re-evaluator runs. If second pass fails, object is marked `Failed (eval)` in deploy index with the second-pass score recorded.

**Integration with phases**:

```text
Phase 5 (generate doc)
  ↓
Phase 6 (build ALTER from wiki)
  ↓
Phase 6.5 (validate_pipeline_wiki --assert-no-inference)   ← mechanical gate
  ↓
Phase 7 (adversarial evaluator)                            ← cognitive gate  (default ON)
  ↓
If PASS → mark Generated in deploy index, write .alter.sql to deploy candidate pool
If FAIL → regenerate Phase 5 + Phase 6 with feedback (max 1 retry)
                                                            ↓
                                              re-validate + re-evaluate
                                                            ↓
                                              if still FAIL → mark Failed (eval), log to audit
```

**Cost**: ~500-1000 tokens per object, both prompts and completion. For 100 objects: 50-100K tokens per full run. Real cost; recorded in audit summary as a new line. Worth it for the first full run; user can disable for routine re-runs once the pack is stable.

**Why "separate cognitive pass" matters**: the evaluator MUST NOT see the generator's reasoning or checklists. It receives only:

- The produced `.md` file.
- The cached upstream wiki body(ies) the producer claimed to inherit from.
- The cached source-code snippet.
- The cached column-lineage JSON.
- The new `.cursor/rules/uc-pipeline-doc/07-adversarial-evaluation.mdc` rule file.

The evaluator does NOT see `05-generate-doc.mdc`, the validator output, or the producer's "this looks right because…" rationale. Same isolation as the dwh pack — the adversarial pass exists precisely because AI agents are pathological optimists about their own output.

**Sampling mode (`--evaluate-sample N`)**: evaluate only N random objects per schema. Speeds up smoke runs. Default unbounded; pass `--evaluate-sample 5` to spot-check 5 per schema for a fast verify pass.

**Rule file deltas**: NEW rule file `.cursor/rules/uc-pipeline-doc/07-adversarial-evaluation.mdc`. Contains the role definition, rubric, hard gates, output format, and integration contract. Adapted from `.cursor/rules/dwh-semantic-doc/16-adversarial-evaluation.mdc` with UC-specific dimensions and search rules (cached upstream wiki JSON instead of search paths; no `_upstream_wiki_routing.json` chain since UC routing is captured in the run-time bridge index).

**Alternatives considered**:

- **Mechanical-only (skip evaluator)**: rejected — Assertion 13 catches structural inference but not semantic drift in narrations. The user explicitly asked for an eval surface and the dwh pack's experience supports the addition.
- **Human-only via `wiki-review` skill**: rejected — doesn't scale to 100 objects. Skill is for spot-checks, not blanket QA.
- **External LLM (different model) as judge**: future work. Same-model self-critique is the working pattern in dwh; cross-model judge is a quality experiment for v2.

## R-10: Assertion 13 backward-compatibility relaxation (T019 finding)

**Context**: T019 ran `validate_pipeline_wiki.py --assert-no-inference` against the existing 3-object hand-authored pilot. Result: 18 HARD failures on `v_fact_customeraction_w_metrics` because the hand-author dropped/edited phrases from the upstream description on several columns (e.g., upstream `DividendID` description = "Dividend event pointer for dividend-driven fee deductions. NULL off-dividend." → pilot dropped " NULL off-dividend." giving non-byte-equal text). T019 says explicitly: "If any fails, treat as a contract-too-strict signal; document the gap... and relax accordingly before merging."

**Relaxation (locked-in)**: Bucket A (verbatim inheritance) now accepts THREE patterns, in this priority order:

1. **Byte-equal**: downstream description == upstream description (including tier tag).
2. **Verbatim containment**: the upstream description (stripped of tier tag) appears as a contiguous substring inside the downstream description (stripped of tier tag). Handles the legitimate "downstream adds context" case.
3. **First-sentence containment**: the first sentence of the upstream description (stripped of tier tag, ≥20 chars) appears verbatim somewhere inside the downstream description. Handles the case where the downstream restates the upstream's core meaning verbatim and adds new content.

A description that does NOT match any of (1), (2), (3), AND has no source-code citation, AND doesn't match the null-with-provenance template — is still a HARD fail. This catches paraphrasing (the inference failure mode we care about) while accepting genuine human-edited additions.

**Outcome on the pilot**: 18 → 14 HARD failures. The remaining 14 are columns where the hand-author wrote free-form descriptions that share no verbatim text with the upstream (e.g., `IsFTD`, `DLTOpen`, `OpenMarkupByUnits`). These are legitimate Assertion-13 catches: the hand-author exercised domain knowledge the productized generator cannot derive from anchored evidence.

**Resolution path for the 14 pilot regressions**:

- Option A (preferred): re-run `generate_wiki.py` on the 3 pilot objects post-merge. The productized generator emits byte-equal inheritance for those columns (where the upstream has a description) or source-code-cited narrations (where it does not), all passing Assertion 13. The hand-authored Tier-5 domain-expert content moves into the `.review-needed.md` sidecar where it doesn't claim to be machine-derivable.
- Option B: archive the hand-authored pilot as `knowledge/UC_generated/_archive/v0_pilot/` and let the productized generator own the canonical artifacts going forward.
- Option C: keep the hand-authored pilot and skip Assertion 13 only on those 14 columns via an inline exception list. Rejected — exception lists rot.

The pilot regression is NOT a merge blocker — the contract is correctly catching what it was designed to catch, and the resolution is mechanical regeneration.

## Open follow-ups (out of scope for this spec)

- Watch-mode hourly re-run loop (`--watch` flag).
- Auto-creating a Slack notification on `Failed` rows.
- Promoting the runner into a workspace-level Cursor skill.
- Extending the pilot to `dwh`, `bi_db`, `general`, or acquired-company UC schemas.
- Auto-PR creation for downstream propagation when an upstream wiki changes.

All listed for completeness; none required to ship the productized pack.
