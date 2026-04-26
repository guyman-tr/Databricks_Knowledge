# Wiki Post-Run Auditor

A read-only auditor that compares each documented column against its upstream
lineage and proposes merged descriptions where the downstream wiki is
mechanically correct but business-blind.

This tool was built in response to the `BI_DB_DepositWithdrawFee.PIPsCalculation`
example: the downstream described local SP mechanics
(`ABS(PIPsInUSD) at insert; signed by direction rules`), but never inherited the
upstream business meaning
(`conversion-fee revenue in USD = original amount × spread between base/effective
rate, per FC playbook`). Phase 10.5b of the doc pipeline is supposed to enforce
Tier 1 / Tier 4-Confluence inheritance — this tool finds and patches the gaps
it misses.

## Quick start

```powershell
# Dry-run on 15 random objects from BI_DB_dbo with a fixed seed
python tools/wiki-auditor/audit.py --schema BI_DB_dbo --sample 15 --seed 42 --dry-run

# Audit a specific object
python tools/wiki-auditor/audit.py --schema BI_DB_dbo --objects BI_DB_DepositWithdrawFee --dry-run

# Audit the whole schema (slow on first run -- one Claude call per object with candidates)
python tools/wiki-auditor/audit.py --schema BI_DB_dbo --all --dry-run

# Heuristic-only run (no Claude calls -- useful for fast iteration on rule tuning)
python tools/wiki-auditor/audit.py --schema BI_DB_dbo --sample 15 --seed 42 --no-llm --dry-run
```

Outputs land in `audits/`:
- `wiki_audit_run_{YYYYMMDD_HHMMSS}.md` — human-readable concentrated report (one
  file per run, all objects together)
- `wiki_audit_run_{YYYYMMDD_HHMMSS}.diffs.json` — machine-readable diffs, used
  by the (deferred) `apply.py` patcher

## Pipeline

```
Sample N objects --> Stage 1 (heuristics) --> Stage 2 (LLM merger) --> Stage 3 (report)
```

Stage 4 (apply patches) is deferred until the dry-run output looks good.

### Stage 1 — Heuristic scanner (`heuristics.py`)

Per column, runs four cheap rules. Any rule firing makes the column a
**candidate**; severity = number of rules fired.

| Rule | When it triggers |
|---|---|
| `TIER_GAP` | Downstream Tier 2/3 + upstream Tier 1 (verbatim) or Tier 4-Confluence |
| `MECH_ONLY` | Downstream description is dominated by SP-mechanical verbs (`ABS`, `ISNULL`, `at insert`, etc.) and contains zero business nouns. Only fires when an upstream is available to inherit from. |
| `CONFLUENCE_GAP` | Upstream column itself is sourced from Confluence; downstream column is not. Column-level — does not fire just because the upstream wiki has Confluence links anywhere. |
| `LENGTH_GAP` | Upstream description has ≥2× the word count of downstream **and** introduces ≥1 new business noun (from `knowledge/glossary.md` plus a built-in baseline). |

Lineage resolution priority for each downstream column:
1. Structured `<Object>.lineage.md` (preferred — `Source Table` / `Source Column` columns)
2. Inline `(Tier X -- {table}.{column})` suffix in the element row description
3. Multi-source rows (`Fact_*_State`) — wildcard expanded across all matching upstream wikis; the candidate with the **highest tier authority** wins (Tier 1 > Tier 4-Confluence > Tier 2 > Tier 3 > Tier 5).

### Stage 2 — LLM merger (`llm_merger.py`)

Only fires for objects with at least one candidate. One Claude CLI call per
object containing all flagged columns batched together. The prompt asks for a
JSON array with one verdict per column:

```json
{
  "column": "PIPsCalculation",
  "recommendation": "PROMOTE" | "SKIP" | "CONFLICT",
  "merged_desc": "...preserves both business meaning and local mechanics...",
  "attribution": "(Tier 1 - Fact_Deposit_State.PIPsInUSD; Tier 2 - SP_DepositWithdrawFee for ABS/sign logic)",
  "notes": "short justification"
}
```

The LLM is encouraged to vote `SKIP` if the upstream isn't actually better
(this catches false positives from the heuristic stage).

If the Claude CLI is missing, rate-limited, or returns unparsable output, the
auditor falls back to a deterministic stub merger (concatenate upstream +
downstream) so the dry-run still produces a usable report. Stub fallbacks are
flagged in the report and the JSON.

To override the Claude binary location set `WIKI_AUDITOR_CLAUDE` in the env.

### Stage 3 — Concentrated audit report (`audit.py`)

A single markdown file per run. Layout:

1. **Run metadata** — schema, sample size, seed, mode, repo root
2. **Summary counts** — objects scanned / with candidates / total candidates / PROMOTE / SKIP / CONFLICT / stub fallbacks
3. **Per-object summary table**
4. **Top findings** — severity ≥ 3 (3-4 rules fired on the same column)
5. **Per-candidate diffs** — current text → upstream text → proposed merge → rules → patch target line

The diffs.json is a flat list — one record per candidate column — with the
exact line number to patch in the source wiki, ready for Stage 4 to consume.

## Files

- `audit.py` — orchestrator + CLI
- `wiki_parser.py` — element table + lineage parsing, tier-suffix balanced-paren parser
- `heuristics.py` — 4 rules + mechanical-verb wordlist + glossary loader
- `llm_merger.py` — Claude CLI subprocess wrapper + stub fallback
- `audits/` — output folder (created on first run)

## Known limits (v1)

- **Single-hop only** — downstream → immediate upstream wiki. Multi-hop chases (passthrough through staging tables) deferred.
- **Tables only by design** — views also work but were not the original target.
- **No glossary write-back** — if the LLM discovers a new business term, it ends up in the merged description but doesn't auto-update `knowledge/glossary.md`. Manual curation.
- **No mutation** — Stage 4 (apply patches) is intentionally a separate script that doesn't yet exist. Dry-run output is the only artifact.

## CLI reference

| Flag | Default | Notes |
|---|---|---|
| `--schema` | _required_ | Schema folder under `knowledge/synapse/Wiki/` (e.g. `BI_DB_dbo`). |
| `--sample N` | 15 | Random sample size. Ignored when `--all` or `--objects` is set. |
| `--seed N` | none | Fix random sample for reproducibility. |
| `--objects A,B,C` | — | Audit explicit named objects only. |
| `--all` | off | Audit every primary `.md` in the schema (skip sampling). |
| `--no-llm` | off | Skip Claude CLI; use deterministic stub merger only. Fast for rule tuning. |
| `--llm-timeout N` | 240 | Per-object Claude call timeout (seconds). |
| `--dry-run` | on | v1 is dry-run only. Flag retained for forward compatibility with `apply.py`. |
| `--repo-root PATH` | auto | Override the inferred repo root. |
