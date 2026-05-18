---
description: "Task list for feature 009-uc-pipeline-productize"
---

# Tasks: UC-Pipeline DAG-First Productization

**Input**: Design documents from `specs/009-uc-pipeline-productize/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: This feature opts for VALIDATOR tasks rather than unit tests. Validator tasks are explicit (see Phase 6) because FR-009 (quality preservation) and SC-003 (zero inference) demand mechanical post-write checks. No request for traditional TDD unit tests in the spec; we ship validators that gate every produced artifact.

**Organization**: Tasks are grouped by user story. US1 (headless batch run) is the MVP; US2 (no-inference contract) hardens US1; US3 (operator handoff) productionizes the deploy surface.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no in-flight dependencies)
- **[Story]**: User story label — [US1], [US2], [US3]. Setup/Foundational/Polish have no story label.
- Every task names exact file paths.

## Path Conventions

Single-project layout. Code under `tools/uc_pipelines/`, rules under `.cursor/rules/uc-pipeline-doc/`, generated artifacts under `knowledge/UC_generated/`, spec artifacts under `specs/009-uc-pipeline-productize/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the existing toolchain is healthy on this branch before any new code lands.

- [X] T001 Verify `tools/uc_pipelines/` Python modules import cleanly on `009-uc-pipeline-productize` branch by running `python -c "import tools.uc_pipelines.discover_schema, tools.uc_pipelines.build_lineage, tools.uc_pipelines.cache_upstream_wikis, tools.uc_pipelines.build_deploy_index, tools.uc_pipelines.validate_pipeline_wiki"`. No new files created.
- [X] T002 Verify `databricks-sql-connector`, `databricks-sdk`, `sqlglot`, `pyyaml` are in [requirements.txt](../../requirements.txt) at the pinned versions used by the existing pack. Add nothing new.
- [X] T003 [P] Confirm the existing 3-object pilot wikis (`v_fact_customeraction_enriched.md`, `v_fact_customeraction_w_metrics.md`, `de_output_etoro_kpi_fact_customeraction_w_metrics.md`) still pass [tools/uc_pipelines/validate_pipeline_wiki.py](../../tools/uc_pipelines/validate_pipeline_wiki.py) baseline. This is the regression line: if it fails now, productization is paused until baseline is green.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Three rule-file deltas + the cached upstream-wiki index. Every user story reads from these.

**⚠️ CRITICAL**: No user story work can begin until Phase 2 completes — US1 reads the index, US2 enforces the new rules, US3 reports against the new statuses.

- [X] T004 Edit [.cursor/rules/uc-pipeline-doc/03-upstream-wiki-bridge.mdc](../../.cursor/rules/uc-pipeline-doc/03-upstream-wiki-bridge.mdc) to append Rule 6 (Terminal-Root Null-with-Provenance Fallback) — exact text in [research.md §R-5 Delta 1](./research.md#delta-1--03-upstream-wiki-bridgemdc).
- [X] T005 Edit [.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc](../../.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc) to append §6 No-Inference Contract — exact text in [research.md §R-5 Delta 2](./research.md#delta-2--05-generate-docmdc).
- [X] T006 Edit [.cursor/rules/uc-pipeline-doc/GOLDEN-REFERENCE.mdc](../../.cursor/rules/uc-pipeline-doc/GOLDEN-REFERENCE.mdc) to append Assertion 13 under Section B — exact text in [research.md §R-5 Delta 3](./research.md#delta-3--golden-referencemdc).
- [X] T007 Create new tool [tools/uc_pipelines/build_upstream_wiki_index.py](../../tools/uc_pipelines/build_upstream_wiki_index.py) that scans existing wiki trees (`knowledge/DWH_dbo/`, `knowledge/BI_DB/`, `knowledge/general/`, `knowledge/UC_generated/`, `knowledge/uc-domain-doc/`, the bronze/prod-DB trees referenced by Phase 3 Rule 4) and emits the cached `knowledge/UC_generated/_index_cache/upstream_wikis.json` whose schema is documented in [data-model.md "Cached upstream wiki entry"](./data-model.md#entity-cached-upstream-wiki-entry). Single function; ~150 LOC; no UC calls.
- [X] T008 [P] Add a `--write-cache` flag to [tools/uc_pipelines/cache_upstream_wikis.py](../../tools/uc_pipelines/cache_upstream_wikis.py) that delegates to `build_upstream_wiki_index.py` when invoked at run-start. Preserves the existing per-object cache call signature. ~30 LOC delta.

**Checkpoint**: Rule deltas in place. Upstream wiki cache builds successfully. User stories can begin.

---

## Phase 3: User Story 1 — Headless batch run across 5 schemas (Priority: P1) 🎯 MVP

**Goal**: Single command at `python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi` produces a per-schema deploy index + per-object 4-file artifact set for every DAG-anchored in-scope object, plus a per-run audit summary, with no interactive prompts.

**Independent Test**: Run the command on a fresh checkout. Verify (1) `knowledge/UC_generated/_dag.json` exists and validates against [contracts/dag.schema.json](./contracts/dag.schema.json); (2) every DAG-anchored object has 4 artifact files; (3) per-schema `_deploy-index.md` exists; (4) `_runs/{ts}/summary.md` exists with non-empty per-schema rollup.

### Implementation for User Story 1

- [X] T009 [P] [US1] Create [tools/uc_pipelines/build_dag.py](../../tools/uc_pipelines/build_dag.py) — Phase -1 entrypoint. Issues the two SQL queries from [research.md §R-1](./research.md#r-1-one-shot-dag-schema) (one to `system.access.column_lineage`, one to `system.information_schema.tables`+`columns` join), computes `wiki_status` per node by consulting `knowledge/UC_generated/_index_cache/upstream_wikis.json`, computes `topological_layer` via Kahn's algorithm, writes `knowledge/UC_generated/_dag.json` validating against [contracts/dag.schema.json](./contracts/dag.schema.json). ~250 LOC.
- [X] T010 [P] [US1] Create [tools/uc_pipelines/run_pipeline.py](../../tools/uc_pipelines/run_pipeline.py) — the **coordinator**. Reads `--schemas`, validates pilot universe, invokes `build_dag.py` (Phase -1), invokes `build_upstream_wiki_index.py` (Phase 0 cache), computes Wave 1 / Wave 2 schema assignment from the DAG. Wave 1: `concurrent.futures.ProcessPoolExecutor(max_workers=min(4, --max-parallelism))` fan-out to `_process_schema()` workers. Wave 2: sequential `_process_schema('etoro_kpi')` after Wave 1 completes (skipped if `etoro_kpi_prep` failed in Wave 1). Stitched audit summary at end. Implements exit-code matrix from [contracts/cli.contract.md](./contracts/cli.contract.md#exit-codes). ~250 LOC.
- [X] T011 [US1] Implement `_process_schema(schema)` worker function inside `run_pipeline.py` (depends on T010). Pure function — takes schema name, returns per-schema result dict. Reads `_dag.json` + `_index_cache/upstream_wikis.json` lazily. Runs phases 0-6 for every in-scope object in that schema, in topological order within the schema. Writes artifacts under `knowledge/UC_generated/{schema}/`. Stdout prefixed with `[{schema}]` for interleaved log readability. Implements the per-phase checkpoint skip per [research.md §R-4](./research.md#r-4-idempotency-and-resumability). ~200 LOC.
- [X] T012 [US1] Add `--phases`, `--force`, `--max-parallelism`, `--max-objects-per-schema` flag handling to `run_pipeline.py` (depends on T010+T011). Default phases `-1,0,1,2,3,4,5,6,7`. `--max-parallelism` defaults to 4; `0` or `1` forces sequential. `--force` skips the `Path.exists()` checks per-phase.
- [X] T013 [US1] Implement Phase 5 (generate-doc) wiki authoring as a module function in `tools/uc_pipelines/generate_wiki.py` — reads the per-object `.lineage.md` + cached upstream wiki + source code snapshot, emits `.md`, `.lineage.md` (sanity check; copies from Phase 4), `.review-needed.md`. Calls into the existing `generate_uc_object.py` / `build_alter_from_wiki.py` logic but with the DAG-aware "verbatim from upstream" enforcement per [research.md §R-3](./research.md#r-3-no-inference-enforcement). ~300 LOC; this is the heaviest single task.
- [X] T014 [US1] Implement the per-run audit summary writer in `tools/uc_pipelines/write_audit_summary.py` — consumes the in-memory coordinator state at run completion (per-schema worker results from `ProcessPoolExecutor.map` returns), writes `knowledge/UC_generated/_runs/{ts}/summary.md` per the exact shape in [research.md §R-6](./research.md#r-6-audit-summary-format). Includes Wave 1 / Wave 2 timing breakdown. ~150 LOC.
- [X] T015 [US1] Add stdout progress logging to `run_pipeline.py` matching the format in [contracts/cli.contract.md](./contracts/cli.contract.md#stdout-shape-normal-path) — coordinator-level lines + per-worker `[{schema}]` interleaved lines + Wave start/end summaries + final stitched summary + EXIT line. `--verbose` adds per-object lines.

**Checkpoint**: A headless run on the 5 pilot schemas terminates with EXIT 0 (or EXIT 1 if any object failed), produces all artifact files via Wave 1 parallel + Wave 2 sequential fan-out, and emits a complete audit summary. US1 is independently demoable here.

---

## Phase 4: User Story 2 — Honest gap reporting (Priority: P1)

**Goal**: Every produced wiki passes mechanical no-inference checks; every column description is either verbatim-from-upstream, source-code-narrated, or the deterministic null-with-provenance placeholder. Zero AI guesses.

**Independent Test**: Run `python tools/uc_pipelines/validate_pipeline_wiki.py --assert-no-inference --wiki <any produced .md>`. Exits 0. For the existing 3-object pilot, all three must also pass — the rule-file deltas in T004-T006 are designed to be backward-compatible.

### Implementation for User Story 2

- [X] T016 [P] [US2] Add `--assert-no-inference` mode to [tools/uc_pipelines/validate_pipeline_wiki.py](../../tools/uc_pipelines/validate_pipeline_wiki.py). For each column row in the Elements table of the target `.md`, classify the description into (a) verbatim upstream, (b) source-code-narrated, or (c) null-with-provenance placeholder. Implementation per [research.md §R-3](./research.md#r-3-no-inference-enforcement). Hard-fail exit on first unclassifiable column. ~200 LOC delta.
- [X] T017 [US2] Add null-with-provenance emission to `generate_wiki.py` (depends on T013). For any column whose Phase 4 column-lineage JSON shows `wiki_status = terminal_no_wiki` on its terminal upstream AND no source-code narration is possible, emit the exact template `Source: {upstream_fqn}.{col}. No upstream wiki cached as of {check_date}.` with `(Tier 5 — terminal-no-wiki)` source-authority tag.
- [X] T018 [US2] Add blocked-object handling to worker `_process_schema()` (depends on T011). When the worker reaches an in-scope node whose at-least-one upstream is `in_scope_not_yet_authored` AND that upstream hasn't yet been processed in this run, defer the node and re-queue it within the same schema's topological loop. If after all intra-schema topological layers complete the node is still deferred (upstream is cross-schema and failed in a sibling worker), emit a `Blocked` row in the deploy index per the existing format in [contracts/deploy-index.schema.md](./contracts/deploy-index.schema.md). Never AI-author.
- [X] T019 [P] [US2] Regression-test the existing 3-object pilot. Run `validate_pipeline_wiki.py --assert-no-inference` on each. If any fails, treat as a contract-too-strict signal; document the gap in `specs/009-uc-pipeline-productize/research.md` and relax accordingly before merging.
- [X] T020 [US2] Extend [tools/uc_pipelines/validate_pipeline_wiki.py](../../tools/uc_pipelines/validate_pipeline_wiki.py) to enforce all 12 existing assertions PLUS Assertion 13 by default when called without a flag. Update CLI help to document this.

**Checkpoint**: A run completes; every produced wiki passes Assertion 13; blocked objects are correctly enumerated in the deploy index with cause text. US2 is independently demoable.

---

## Phase 5: User Story 3 — Operator handoff to existing deploy tooling (Priority: P2)

**Goal**: Per-schema `_deploy-index.md` includes a `Blocked (upstream wiki missing: <fqn>)` row class. `tools/deploy_alter_batch.py` ignores `Blocked` rows by construction (existing behavior — `Blocked` doesn't match `Generated`). Audit summary tallies Blocked-by-upstream so the operator can prioritize follow-up upstream wiki authoring by impact.

**Independent Test**: After a run that produced at least one `Blocked` row, open the schema's `_deploy-index.md` — rollup row count for `Blocked` matches table row count. Open the run summary — `Blocked objects (by upstream)` table sums to the same total. Operator can find the highest-impact missing upstream in under 30 seconds.

### Implementation for User Story 3

- [ ] T021 [P] [US3] Edit [tools/uc_pipelines/build_deploy_index.py](../../tools/uc_pipelines/build_deploy_index.py) to emit `Blocked (upstream wiki missing: <fqn>)` rows when the worker passes a deferred-and-not-resolved object. Updates the rollup-counts header to include `Blocked` column. ~60 LOC delta.
- [ ] T022 [US3] In `write_audit_summary.py` (depends on T014), aggregate the Blocked rows across all 5 schemas into a single `Blocked objects (by upstream)` table sorted descending by `Blocking N objects`. Include `Routing-rule attempts` per upstream (read from the per-worker per-attempt log captured during Phase 3 lookup, serialized to disk by each worker and re-read by the coordinator at run end).
- [ ] T023 [US3] Verify [tools/deploy_alter_batch.py](../../tools/deploy_alter_batch.py) correctly ignores `Blocked` rows. No code change expected — the existing status-filter loop matches `Generated` only — but confirm with a smoke test (run the deploy runner against a deploy index with a known `Blocked` row, observe that it logs `skipping <fqn> (status: Blocked …)` and exits 0).
- [ ] T024 [P] [US3] Update [tools/uc_pipelines/validate_pipeline_wiki.py](../../tools/uc_pipelines/validate_pipeline_wiki.py) (depends on T016) to also validate the per-schema `_deploy-index.md` rollup-vs-row-count invariant from [contracts/deploy-index.schema.md "Validation rules"](./contracts/deploy-index.schema.md#validation-rules-mechanically-checked-by-fr-009-validator). ~40 LOC delta.

**Checkpoint**: All three user stories independently functional. Deploy handoff is byte-compatible with the existing `dwh-semantic-doc` pack. Operator can answer "what's blocked, by which upstream?" in 30 seconds.

---

## Phase 5.5: Adversarial Evaluation (Cross-Cutting Quality Gate, default ON)

**Purpose**: Independent cognitive pass at Phase 7 per object, mirroring `dwh-semantic-doc/16-adversarial-evaluation.mdc` but adapted to UC's lighter context. Catches semantic drift the mechanical Assertion 13 validator cannot. Default ON for the pilot universe to harden the first full run.

**Goal of this phase**: every produced wiki carries a recorded `weighted_score >= 7.5` (after at most one regeneration retry) before being marked `Generated` in its deploy index.

**Independent test**: run `python tools/uc_pipelines/adversarial_evaluate.py --wiki <path>` against any produced `.md`. Returns a JSON evaluation record validating against the schema in [data-model.md "Per-object adversarial evaluation record"](./data-model.md#entity-per-object-adversarial-evaluation-record). Verdict PASS for the existing 3-object pilot is the regression baseline.

### Implementation for Adversarial Evaluation

- [ ] T025 [P] Create new rule file [.cursor/rules/uc-pipeline-doc/07-adversarial-evaluation.mdc](../../.cursor/rules/uc-pipeline-doc/07-adversarial-evaluation.mdc) — adapts `dwh-semantic-doc/16-adversarial-evaluation.mdc` to UC. Six dimensions (Inheritance Fidelity 35%, Source-Code Narration Accuracy 25%, Null-with-Provenance Correctness 15%, Completeness 10%, Shape Fidelity 10%, Lineage Coherence 5%), the two hard gates (T1 Upstream Fidelity table mandatory; no-AI-inference cross-check), output format (structured JSON + Markdown report), and integration contract (when called, what it sees, how regeneration is triggered). See [research.md §R-9](./research.md#r-9-adversarial-evaluation-phase-7) for the full rubric. ~400 lines of rule file.
- [ ] T026 [P] Create [tools/uc_pipelines/adversarial_evaluate.py](../../tools/uc_pipelines/adversarial_evaluate.py) — Phase 7 tool. Inputs: object FQN, paths to `.md`, `.lineage.md`, cached upstream wiki JSON, cached source-code snippet. Loads the rule file and constructs an isolated evaluator prompt (no generator context, no other phase outputs). Invokes the LLM, parses the structured output, writes the evaluation record to `knowledge/UC_generated/{schema}/_discovery/evaluations/{object}.json`. Returns verdict + (if FAIL) regeneration feedback. ~250 LOC.
- [ ] T027 Integrate Phase 7 into the worker `_process_schema()` (depends on T011, T013, T026). After Phase 6 (ALTER) completes per object, run `adversarial_evaluate.py`. If PASS → mark `Generated`. If FAIL on attempt 1 → re-run Phase 5 (generate-doc) + Phase 6 (ALTER) with the regeneration feedback as additional context, then re-evaluate. If FAIL on attempt 2 → mark `Failed (eval)` in the deploy index; preserve the second-pass score for the audit summary; the object's `.alter.sql` is NOT a deploy candidate. Cap attempts at 2.
- [ ] T028 Add `--evaluate` / `--no-evaluate` / `--evaluate-sample N` flag handling to `run_pipeline.py` (depends on T010, T027). Default ON. `--no-evaluate` skips Phase 7 entirely. `--evaluate-sample N` runs Phase 7 for only N random in-scope objects per schema (still enforced as gate for those N; the unsampled objects mark `Generated` without eval). Aggregate Phase 7 stats into the audit summary (first-pass PASS, regen-PASS, final-FAIL, average weighted score, per-dimension averages) — depends on T014/T022.

**Checkpoint**: Every produced wiki carries an evaluation record. Final-FAIL rows are surfaced in the audit summary. Operator can answer "did any wiki silently drift?" by reading the audit summary's adversarial-eval section.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression coverage, cross-runtime parity check, decide-runner decision, branch hygiene.

- [ ] T029 Pilot regression: run the productized pack on the existing 3-object DAG (`v_fact_customeraction_enriched`, `v_fact_customeraction_w_metrics`, `de_output_etoro_kpi_fact_customeraction_w_metrics`) with `--force --evaluate` and diff the produced artifacts against the existing pilot output. Allowed delta: `generated_at` + evaluator score records (new artifact). Any other byte-level difference in `.md` / `.lineage.md` / `.alter.sql` is a regression — fix before any other schema runs. Also assert evaluator verdict PASS for all three.
- [ ] T030 [P] Cross-runtime parity check: run `python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --dry-run` from (a) a PowerShell terminal locally, and (b) a bash terminal in a Claude CLI loop (or simulate by `bash -c`). Confirm identical stdout shape and identical produced `_dag.json` (modulo `built_at`). Document the comparison in `specs/009-uc-pipeline-productize/parity-check.md` (delete after the first sign-off).
- [ ] T031 [P] Idempotency check: run the full pipeline twice in a row with no `--force`. Assert the second run completes in under 60 seconds (skip-all path; bumped from 30s to accommodate evaluator skip-check) and produces only a new `_runs/{ts}/summary.md` (no other file changes). Document in `specs/009-uc-pipeline-productize/idempotency-check.md`.
- [ ] T032 [P] UC query-budget check: instrument `_conn.py` to count `system.access.*` and `system.information_schema.*` queries during a full run. Assert ≤2 of each. Workers MUST issue zero UC queries (only coordinator queries). Persist the count in `_runs/{ts}/summary.md` (already specified in [research.md §R-6](./research.md#r-6-audit-summary-format)).
- [ ] T033 [P] Parallelism smoke test: run on Wave 1 with `--max-parallelism 4` and again with `--max-parallelism 1`. Assert (a) identical artifacts (modulo `generated_at`), (b) parallel run is at least 2x faster than sequential, (c) interleaved stdout is correctly schema-prefixed. Document in `specs/009-uc-pipeline-productize/parallelism-check.md`.
- [ ] T034 Decide-runner decision: based on T029-T033 results, decide whether `/speckit.implement` runs from inside this Cursor session or from a Claude CLI loop terminal. Record the decision in `specs/009-uc-pipeline-productize/runner-decision.md` with a one-paragraph rationale. (Cursor agent wins for low-volume runs; Claude CLI loop wins for batch runs >2 hours where Cursor session might time out.)
- [ ] T035 Update [knowledge/UC_generated/README.md](../../knowledge/UC_generated/README.md) (or create if missing) with a one-page "what this folder contains" + the headless command + the deploy command + a note about Phase 7 adversarial evaluator default-on behavior, mirroring [quickstart.md](./quickstart.md). Operator's entry point when they revisit in 3 months.
- [ ] T036 Run `python tools/uc_pipelines/validate_pipeline_wiki.py --batch knowledge/UC_generated/*/Tables knowledge/UC_generated/*/Views` against every produced wiki at the end of the implementation. Zero hard failures permitted before merge. Also assert every wiki has a corresponding evaluation record with verdict PASS.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup. Blocks ALL user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational. Internal: T009 ║ T010 (different files), T011 depends on T010, T012 depends on T010+T011, T013 depends on T010, T014 depends on T010+T013, T015 depends on T010+T011+T014.
- **User Story 2 (Phase 4)**: Depends on Foundational AND on T010+T011+T013 (cannot enforce the no-inference contract until there is a wiki to validate). Internal: T016 ║ T019 (different files; T019 is a regression check). T017 depends on T013. T018 depends on T011. T020 depends on T016.
- **User Story 3 (Phase 5)**: Depends on Foundational AND on T011+T014 (deploy index emission is downstream of the worker). Internal: T021 ║ T024 (different files). T022 depends on T014+T021. T023 has no code-change but blocks on T021 existing.
- **Adversarial Eval (Phase 5.5)**: Depends on US1+US2+US3 (eval needs produced wikis to evaluate, no-inference contract enforced first, deploy-index format settled). Internal: T025 ║ T026 (different files). T027 depends on T011+T013+T026. T028 depends on T010+T027 and integrates with T014+T022.
- **Polish (Phase 6)**: Depends on all five preceding phases. T029 ║ T030 ║ T031 ║ T032 ║ T033 (independent checks). T034 depends on the five checks. T035 depends on US1 having shipped wikis. T036 is the final gate.

### Within Each User Story

- US1: T009 ║ T010 (parallel) → T011 → T012 → T013 → T014 → T015.
- US2: T016 ║ T019 (parallel) → T017 → T018 → T020.
- US3: T021 ║ T024 (parallel) → T022 → T023.
- Phase 5.5: T025 ║ T026 (parallel) → T027 → T028.

### Parallel Opportunities

- Phase 1: T003 [P] parallel to T001+T002 sequential.
- Phase 2: T007 ║ T008 (parallel after T004-T006 done; T004-T006 are pure documentation edits and can also be parallel-ish).
- Phase 3: T009 ║ T010 at the start.
- Phase 4: T016 ║ T019 at the start.
- Phase 5: T021 ║ T024 at the start.
- Phase 5.5: T025 ║ T026 at the start.
- Phase 6: Five checks T029-T033 in parallel.

---

## Parallel Example: User Story 1 kickoff

```bash
# After Foundational (T004-T008) is done, launch the two big modules together:
Task: "T009 [P] [US1] Create build_dag.py in tools/uc_pipelines/"
Task: "T010 [P] [US1] Create run_pipeline.py coordinator in tools/uc_pipelines/"
```

Both are net-new files; they share no in-flight dependencies.

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1 + Phase 2 complete — foundational rule deltas + upstream wiki index.
2. Phase 3 (US1) — headless batch run plumbing with Wave 1 / Wave 2 fan-out.
3. STOP and VALIDATE: run on `etoro_kpi_prep` (smallest schema with prior pilot coverage), `--no-evaluate --max-parallelism 1` for first smoke. Confirm artifacts exist, summary writes, exit code 0.
4. At this point the pack RUNS — but without Assertion 13 enforcement AND without the adversarial evaluator, it might still emit inferred descriptions. Acceptable as a debugging MVP; NOT acceptable to ship.

### Incremental Hardening (Add US2)

5. Phase 4 (US2) — no-inference mechanical contract.
6. Re-run on `etoro_kpi_prep`. Confirm zero inference per mechanical validator. Confirm 3-object pilot still passes (T019).

### Operational Polish (Add US3)

7. Phase 5 (US3) — Blocked-row visibility + audit summary tally.
8. Operator's deploy surface is now complete.

### Quality Gate (Add Phase 5.5)

9. Phase 5.5 — adversarial evaluator. Default ON.
10. Re-run on `etoro_kpi_prep`. Confirm evaluator verdict PASS for every object. Confirm 3-object pilot still PASS (T029).
11. This is the SHIPPABLE MVP — operator can run end-to-end and trust the output mechanically AND semantically.

### Cross-cutting + Decide-runner

12. Phase 6 — regression + parity + idempotency + query budget + parallelism + runner decision.
13. Merge once T036 (final validator + evaluator sweep) passes.

---

## Notes

- [P] tasks = different files, no dependencies in flight.
- [Story] label maps task to a user story for traceability.
- Each user story should be independently completable and demoable.
- The pack is documentation-pure on Phase 2 (rule files) and code-pure on Phases 3-5 (Python tools). Keep those concerns separated in commits — easier to revert.
- Avoid: vague tasks, same-file conflicts within a parallel block, cross-story dependencies that break independence.
- Decide-runner (T028) is the only task that defers to a non-Cursor environment. Everything else should run identically in either runtime.
