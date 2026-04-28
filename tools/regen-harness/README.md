# Regen Sample Harness

Isolated 25-object regen harness that demonstrates the new pipeline
architecture end-to-end:

1. **Deterministic upstream pre-fetch** (Python, no LLM): resolves upstream
   wikis from the existing `.lineage.md` + DDL into a single bundle file
   handed to the writer.
2. **Writer** (claude #1): runs the standard wiki phases 1-11 for ONE
   object, with the bundle as authoritative Tier 1 source. Cannot skip
   upstream resolution because it's already done.
3. **Adversarial judge** (claude #2, fresh process, separate context):
   grades the wiki against the bundle, DDL, and lineage with the rubric in
   `prompts/judge.md`. Outputs a strict JSON verdict.
4. **Optional retry**: if verdict is FAIL and attempts remain, the runner
   feeds the judge's `regeneration_feedback` back into the writer prompt.
5. **Compare**: runs the same judge against the **current** wiki (the one
   already on `main`) so the comparison is judge-vs-judge, not self-grade
   vs judge.
6. **Summary**: aggregates verdicts across all 25 objects into
   `audits/regen-sample/_summary.md`.

The main wiki tree (`knowledge/synapse/Wiki/`) and `_index.md` are NEVER
modified. Everything lands under `audits/regen-sample/`.

---

## File layout

```
tools/regen-harness/
  pick_sample.py         -- stratified sample selection (5 schemas x 5 buckets = 25)
  preload_upstream.py    -- deterministic upstream resolution + bundle assembly
  build_writer_prompt.py -- composes writer prompt for one attempt
  run_writer.ps1         -- spawns claude #1 (writer)
  run_judge.ps1          -- spawns claude #2 (judge)
  regen_one.ps1          -- single-object orchestrator (preload -> writer -> judge -> retry -> final/)
  compare_one.py         -- runs judge against current/, produces compare.md
  run_all.ps1            -- top-level driver (loops over manifest, then summarize)
  summarize.py           -- aggregates compare.md files into _summary.md
  prompts/
    writer_preamble.md   -- single-object regen-mode preamble (prepended to writer prompt)
    judge.md             -- adversarial judge prompt + JSON contract

audits/regen-sample/      -- runtime artefacts (not in git unless you commit them)
  manifest.csv
  _summary.md             -- final aggregate report
  _summary.csv            -- aggregate report as CSV
  {Schema}/{Object}/
    current/              -- read-only snapshot of the wiki on main
    current_judge/        -- judge_verdict.json + judge_log.md scoring current/
    regen/
      _upstream_bundle.md
      _upstream_resolution.json
      _no_upstream_found.txt    -- only when nothing resolved
      attempt_1/
        writer_prompt.md
        writer_log.md
        writer_summary.json
        writer_raw_stream.jsonl
        {Object}.md
        {Object}.lineage.md
        {Object}.review-needed.md
        judge_verdict.json
        judge_log.md
        judge_raw_stream.jsonl
      attempt_2/                -- only when attempt_1 failed and retry was allowed
      final/                    -- copy of the highest-scoring attempt
      regen_summary.json
    compare.md
```

---

## Running

### One object end-to-end

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\regen_one.ps1 `
    -Schema BI_DB_dbo -ObjectName BI_DB_AdvancedDeposit_Ext -RunCompare
```

`-MaxAttempts 1` skips the retry loop. `-SkipPreload` reuses an existing
`_upstream_bundle.md`. Add `-RunCompare` to also call `compare_one.py` after
the regen.

### Full 25-object run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\run_all.ps1
```

Filtering options:

```powershell
# Only one schema:
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\run_all.ps1 -OnlySchema BI_DB_dbo

# Only the slop bucket across all schemas:
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\run_all.ps1 -OnlyBucket slop

# Resume a partial run, skipping anything that already has regen_summary.json:
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\run_all.ps1 -SkipFinishedObjects

# Resume from a specific manifest row (1-indexed):
powershell -NoProfile -ExecutionPolicy Bypass -File tools\regen-harness\run_all.ps1 -StartAt 12
```

After the loop completes, `run_all.ps1` calls `compare_one.py --all` and
`summarize.py`, which produce `audits/regen-sample/_summary.md` and
`_summary.csv`.

### Re-pick the sample (rare)

```powershell
python tools\regen-harness\pick_sample.py
```

Reads the latest `audits/wiki_health_scan_*.csv`, regenerates
`manifest.csv`, and copies fresh `current/` snapshots.

---

## Cost & timing

Per-object budget:
- Writer: ~30K in / 15K out tokens, 10-20 minutes wall-clock
- Judge: ~20K in / 5K out tokens, 1-3 minutes wall-clock
- Optional retry doubles writer cost; current-judge run adds ~one judge cost

For all 25 objects (no retries, with current-judge): ~$10-25 USD on Sonnet,
~3-5 hours of wall-clock if run sequentially. Set
`-WriterTimeoutSeconds` and `-JudgeTimeoutSeconds` to override the
2400s / 900s defaults.

---

## What this proves

After `_summary.md` is written, decide:

- **22+ of 25 BETTER** -> roll the new architecture (deterministic
  pre-fetch + separate-process judge) into the main loop, rerun the slop
  list (or all 1033) with it.
- **All 5 known-good come back EQUIVALENT** -> no regression on the wikis
  we already trust.
- **Any WORSE** -> open the corresponding `compare.md`. The dimension scores
  table tells you exactly where the regression is.

---

## Troubleshooting

- **Writer fails MCP pre-flight**: check `~/.cursor/synapse-credentials.env`.
  The writer aborts on purpose if Synapse is unreachable -- a wiki without
  Phase 2 (sampling) and Phase 3 (distribution) data will fail the judge
  anyway.
- **Judge writes mojibake into `judge_log.md`**: should not happen any more
  -- `run_judge.ps1` reads `writer_raw_stream.jsonl` with explicit UTF-8.
  If it does, check the system locale of the powershell host.
- **`No <JUDGE_VERDICT>...</JUDGE_VERDICT> markers found`**: claude
  returned text but didn't emit the JSON block. Look at `judge_log.md`,
  re-run with a higher timeout, or relax the prompt (file an issue rather
  than weakening the contract).
