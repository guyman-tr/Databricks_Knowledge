"""Smoke-test the Databricks LLM driver: list LLM endpoints + one completion.

Goals:
  1. Confirm Databricks OAuth profile `guyman` is fresh (auth call succeeds).
  2. Enumerate serving endpoints that look like LLMs (claude, llama, etc.).
  3. Pick one and send a trivial completion to verify the driver works.

If step 1 or 2 fails, the user needs `databricks auth login --profile guyman`.
If step 3 fails, the picked endpoint is wrong — print all candidates and let
the user pick.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))


def main() -> int:
    print("[1/3] Databricks SDK auth check (profile=guyman)")
    try:
        from databricks.sdk import WorkspaceClient
    except ImportError as e:
        print(f"  FAIL: databricks-sdk not installed: {e}")
        return 1
    try:
        w = WorkspaceClient(profile="guyman")
        host = w.config.host
        # Force token resolution
        _ = w.config.authenticate()
        print(f"  OK — host={host}")
    except Exception as e:
        print(f"  FAIL: {type(e).__name__}: {e}")
        print(f"  Run: databricks auth login --profile guyman")
        return 1

    print(f"\n[2/3] Listing serving endpoints (looking for LLMs)")
    t0 = time.monotonic()
    try:
        endpoints = list(w.serving_endpoints.list())
    except Exception as e:
        print(f"  FAIL listing endpoints: {e}")
        return 1
    dt = time.monotonic() - t0
    print(f"  OK — {len(endpoints)} total endpoints in {dt:.1f}s")

    # Filter to LLM-looking ones, including the standard Databricks foundation slugs
    llm_keywords = (
        "claude", "sonnet", "opus", "haiku",
        "gpt", "llama", "meta",
        "mistral", "mixtral", "dbrx", "gemma",
        "foundation", "pay-per-token",
    )
    candidates = []
    for e in endpoints:
        name = (e.name or "").lower()
        if any(k in name for k in llm_keywords):
            candidates.append(e)
    print(f"  Found {len(candidates)} LLM-looking endpoints:")
    for e in candidates:
        ready = e.state.ready if e.state else "?"
        print(f"    - {e.name:60s}  ready={ready}")

    if not candidates:
        print(f"  FAIL: no LLM endpoints visible. Listing first 30 names so")
        print(f"        we can identify which one to use:")
        for e in endpoints[:30]:
            print(f"    {e.name}")
        return 1

    # Pick the most appealing endpoint:
    # 1. anything containing "claude" + "sonnet" with explicit version preference
    # 2. anything explicitly "claude"
    # 3. anything explicitly "llama" 70b+
    # 4. first ready candidate
    def score(name: str) -> tuple:
        n = name.lower()
        return (
            "claude" in n and "sonnet" in n,
            "claude-sonnet-4" in n,
            "claude" in n,
            "llama" in n and ("70b" in n or "405b" in n),
            "llama" in n,
        )
    candidates.sort(key=lambda e: score(e.name or ""), reverse=True)
    picked = candidates[0]
    print(f"\n  Picked: {picked.name!r}")

    print(f"\n[3/3] Sending one completion to {picked.name!r}")
    from tools.eval_suite.harness.suts._llm_driver import DatabricksLLMDriver
    drv = DatabricksLLMDriver(endpoint_name=picked.name, profile="guyman")
    try:
        resp = drv.complete(
            messages=[
                {"role": "system", "content": "You answer with exactly one word."},
                {"role": "user", "content": "What is 2+2?"},
            ],
            max_tokens=20,
            temperature=0.0,
            timeout_s=60,
        )
    except Exception as e:
        print(f"  FAIL: {type(e).__name__}: {e}")
        print(f"\n  Other LLM endpoints to try:")
        for e2 in candidates[1:8]:
            print(f"    - {e2.name}")
        return 1

    print(f"  OK — backend={resp.backend} model={resp.model}")
    print(f"      elapsed_ms={resp.elapsed_ms}")
    print(f"      input_tokens={resp.input_tokens}  output_tokens={resp.output_tokens}")
    print(f"      text={resp.text!r}")
    print(f"\nSmoke green. Endpoint to use: {picked.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
