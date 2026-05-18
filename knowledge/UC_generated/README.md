# `knowledge/UC_generated/` — UC-Pipeline pack output

Documentation for **pure Unity Catalog objects** — tables and views created and managed natively in Databricks, NOT mirrored from Synapse.

This folder is produced by the `uc-pipeline-doc` framework. Source of truth for the framework: [`.cursor/rules/uc-pipeline-doc/`](../../.cursor/rules/uc-pipeline-doc).

---

## What lives here

```
knowledge/UC_generated/
├── _dag.json                          ← global lineage DAG (built once per run)
├── _index_cache/upstream_wikis.json   ← global wiki-routing index (Phase 0)
├── _runs/{ts}/summary.md              ← per-run audit summary
├── {schema}/                          ← per pilot schema
│   ├── _schema_card.md                ← authoritative in-scope object list
│   ├── _deploy-index.md               ← per-schema deploy tracker (Pending → Generated → Deployed → Blocked)
│   ├── _discovery/                    ← Phase 1-3 cached intermediates
│   │   ├── uc_inventory.json
│   │   ├── source_code/{obj}.{sql|py}
│   │   ├── column_lineage/{obj}.json
│   │   ├── upstream_wikis/{fqn}.md    ← cached upstream wiki bodies (verbatim inherit source)
│   │   ├── {obj}.status.json          ← per-object pipeline status sidecar
│   │   └── evaluations/{obj}.json     ← per-object Phase 7 evaluation record
│   ├── Tables/{obj}.md                ← the wiki + .alter.sql + .lineage.md + .review-needed.md
│   └── Views/{obj}.md
```

---

## Pilot schemas (selective rollout)

The framework runs on these 5 schemas only. Adding a new schema is a separate spec.

- `de_output`
- `bi_output`
- `bi_dealing`
- `etoro_kpi_prep`
- `etoro_kpi` (depends on `etoro_kpi_prep`; runs in Wave 2 after the other four)

---

## Headless run (set-and-forget)

```bash
python tools/uc_pipelines/run_pipeline.py \
  --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi
```

Expected wall-clock: 45-60 minutes for the full pilot universe (~80-150 objects).

Default behavior:

- All 8 phases run (`-1, 0, 1, 2, 3, 4, 5, 6, 7`).
- Phase 7 (adversarial evaluator) is **default ON**. Add `--no-evaluate` to skip; `--evaluate-sample N` to spot-check N random objects per schema.
- Schema-level parallelism (`--max-parallelism 4` by default). Wave 1 schemas run concurrently; `etoro_kpi` runs sequentially after Wave 1 completes.
- UC query budget: ≤2 `system.access.*` + ≤2 `system.information_schema.*` queries for the entire run (Phase -1 only).

Smaller runs:

```bash
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep                       # one schema
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --phases 5,6          # re-generate + validate only
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --no-evaluate         # skip Phase 7
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --evaluate-sample 5   # spot-check 5 random objects
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --dry-run             # Phase -1 only
```

---

## Adversarial evaluator (Phase 7)

A separate cognitive pass that grades each generated wiki against its cached source material. Default ON. Catches semantic drift the mechanical no-inference validator cannot.

Six dimensions:

| Dimension | Weight |
|---|---|
| Inheritance Fidelity | 35% |
| Source-Code Narration Accuracy | 25% |
| Null-with-Provenance Correctness | 15% |
| Completeness | 10% |
| Shape Fidelity | 10% |
| Lineage Coherence | 5% |

Pass threshold: weighted score ≥ 7.5 AND both hard gates pass (T1 fidelity table present + no unanchored inferred descriptions).

On FAIL, the worker auto-regenerates that object once and re-evaluates. After a second FAIL the object is marked `Failed (eval)` and excluded from the deploy candidate pool. Detail in [`07-adversarial-evaluation.mdc`](../../.cursor/rules/uc-pipeline-doc/07-adversarial-evaluation.mdc) and [`adversarial_evaluate.py`](../../tools/uc_pipelines/adversarial_evaluate.py).

Standalone use:

```bash
python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep                          # all objects
python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep --object my_view         # one object
python tools/uc_pipelines/adversarial_evaluate.py --wiki path/to/wiki.md                           # arbitrary path
python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep --mode emit-prompt       # write a cognitive-pass prompt for an external LLM
```

---

## Deploy

For each schema with `Generated` rows in its `_deploy-index.md`:

```bash
python tools/deploy_alter_batch.py \
  --deploy-index knowledge/UC_generated/{schema}/_deploy-index.md \
  --schema {schema} \
  --batch-size 5 \
  --deploy-batch 1
```

Increment `--deploy-batch` until every `Generated` row transitions to `Deployed (Batch N)`. The runner correctly skips `Blocked`, `Pending`, `Stub only`, and `Failed` rows.

The same runner is used by `dwh-semantic-doc` and `uc-domain-doc` — no productization-specific flags needed.

---

## Reviewing a run

Audit summary: `knowledge/UC_generated/_runs/{ts}/summary.md` — check these sections:

1. **Per-schema rollup** — counts of Generated / Deployed / Blocked / Failed / Unverified.
2. **Blocked objects by upstream** — which upstream wikis are missing and how many downstream objects each blocks. Highest-impact upstreams are your follow-up backlog.
3. **Phase time breakdown** — where wall-clock went.
4. **Adversarial evaluator** — per-schema pass / fail counts, per-dimension averages, final-FAIL object list with feedback.
5. **Errors** — per-object hard failures (one bullet each).

---

## Operator gotchas

- **DAG build returns 0 nodes for a pilot schema** — schema is empty in UC; confirm with `SHOW TABLES IN main.{schema}`.
- **Phase 7 first-pass FAIL but regen also FAIL** — the deterministic generator produced the same output; root cause is usually a missing upstream wiki cache or genuine source-code inference. Inspect `_discovery/evaluations/{obj}.json` for `regeneration_feedback`.
- **`Blocked` rows in `_deploy-index.md`** — the object's upstream has no wiki under any Phase 3 routing rule. Either author the upstream wiki or accept the `null-with-provenance` column descriptions.
- **Pilot hand-authored wikis show paraphrasing failures** — see [`specs/009-uc-pipeline-productize/research.md` §R-10](../../specs/009-uc-pipeline-productize/research.md). The hand-authored pilots predate the no-inference contract and are expected to fail Phase 7. Regenerate with `--force` to produce contract-compliant output, or accept the pilot baseline.

---

## Where the framework lives

| Artifact | Path |
|---|---|
| Rule pack (LLM-facing) | [`.cursor/rules/uc-pipeline-doc/`](../../.cursor/rules/uc-pipeline-doc) |
| Coordinator | [`tools/uc_pipelines/run_pipeline.py`](../../tools/uc_pipelines/run_pipeline.py) |
| Phase tools | [`tools/uc_pipelines/`](../../tools/uc_pipelines) |
| Specification | [`specs/009-uc-pipeline-productize/`](../../specs/009-uc-pipeline-productize) |
| Quickstart | [`specs/009-uc-pipeline-productize/quickstart.md`](../../specs/009-uc-pipeline-productize/quickstart.md) |
