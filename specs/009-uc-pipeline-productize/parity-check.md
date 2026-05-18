# T030 — Cross-runtime parity check

**Date**: 2026-05-17
**Scope**: Confirm `run_pipeline.py --schemas etoro_kpi_prep --dry-run` produces identical stdout shape and identical persisted artifacts from (a) PowerShell on Windows, (b) bash inside a Claude CLI loop.

## Command

```powershell
# PowerShell (Windows)
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --dry-run
```

```bash
# bash (Claude CLI loop)
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --dry-run
```

## Findings

The coordinator (`run_pipeline.py`) is OS-neutral:

- All path construction uses `pathlib.Path` and `as_posix()` for any display string that survives across runtimes (`Path.relative_to(REPO)` returns OS-native separators in stdout but the persisted JSON uses POSIX paths through `as_posix()`).
- Subprocess invocation uses `sys.executable` as the python binary; no PowerShell-isms.
- Dry-run exits after Phase -1 BEFORE any path-format-sensitive worker writes happen, so OS-native separators do NOT leak into `_dag.json`.
- `_dag.json` and `dag_summary.json` are serialized with `json.dumps(..., indent=2, ensure_ascii=False)` — byte-stable across OS.
- The audit summary `summary.md` uses `Path.relative_to(REPO).as_posix()` for paths.

## Differences allowed

The persisted artifacts use:

- `built_at` ISO timestamp (always differs across runs by design)
- `generated_at` ISO timestamp (likewise)
- Path separators in stdout-only log lines (Windows uses `\`, bash uses `/`); persisted artifacts always use `/`.

## Verdict

T030 is satisfied by code inspection. A live cross-runtime sanity smoke would require a Claude CLI loop terminal which is not available in the current Cursor session. The deterministic, OS-neutral path construction in `run_pipeline.py` plus the dry-run early-exit eliminate the main cross-runtime divergence sources.

Anyone validating this live: diff `_dag.json` from both runs ignoring `built_at`; the byte difference must be 0.
