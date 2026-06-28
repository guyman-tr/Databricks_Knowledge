"""Score how well the current skill corpus covers each intent cluster.

PRIMARY signal: the local trigger router (tools/routing_inventory/smoke_test).
  Run the denoised intent text + top examples through score_query() to simulate
  whether a skill WOULD fire. This is authoritative -- it reflects what is
  actually in the skill corpus, independent of MCP telemetry quality.

SECONDARY (notes only, not score): MCP gateway telemetry (skills_top_score,
  skills_match_quality_hint). Treated as weak corroboration. MCP sessions are
  unreliable and their telemetry is NOT a coverage oracle.

INTENTIONALLY EXCLUDED from coverage scoring:
  - Genie failure rate (message_status != COMPLETED). This measures Genie SQL
    generation quality, not skill coverage. A skill can be perfect while Genie
    still fails to generate the right SQL.
  - thumb_down. Satisfaction signals are too noisy as coverage proxies.

Classification thresholds (tunable via env):
  well_covered  : router score >= ROUTE_WELL  (confident unique skill match)
  partial       : router score in [ROUTE_PARTIAL, ROUTE_WELL)
  underserved   : router score <  ROUTE_PARTIAL (no confident match)
"""
from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from tools.auto_kb.questions.normalize import Cluster

REPO_ROOT = Path(__file__).resolve().parents[3]

# Router score thresholds (sum of length-weighted trigger matches).
# Score = sum of (1/sharing_hubs * trigger_word_count) over matched triggers.
# A single exclusive 2-word trigger scores ~2.0; multi-word exclusive triggers more.
ROUTE_WELL = float(os.environ.get("QUESTIONS_ROUTE_WELL", "3.0"))
ROUTE_PARTIAL = float(os.environ.get("QUESTIONS_ROUTE_PARTIAL", "1.0"))

# How many example prompts to also run through the router (best-of).
EXAMPLE_PROBE_COUNT = 3

_ROUTER_INDEX: Optional[dict] = None
_ROUTER_OK = True


def _router_index() -> Optional[dict]:
    """Lazily build the local trigger index; degrade gracefully if unavailable."""
    global _ROUTER_INDEX, _ROUTER_OK
    if _ROUTER_INDEX is not None or not _ROUTER_OK:
        return _ROUTER_INDEX
    try:
        routing_dir = REPO_ROOT / "tools" / "routing_inventory"
        if str(routing_dir) not in sys.path:
            sys.path.insert(0, str(routing_dir))
        import smoke_test  # type: ignore

        _ROUTER_INDEX = smoke_test.build_trigger_index()
    except Exception:  # noqa: BLE001
        _ROUTER_OK = False
        _ROUTER_INDEX = None
    return _ROUTER_INDEX


def local_route(text: str) -> tuple[Optional[str], float, list[str]]:
    """Return (top_hub, score, matched_triggers) from the local trigger router."""
    index = _router_index()
    if not index:
        return None, 0.0, []
    try:
        import smoke_test  # type: ignore
        ranked = smoke_test.score_query(text, index)
    except Exception:  # noqa: BLE001
        return None, 0.0, []
    if not ranked:
        return None, 0.0, []
    hub, score, matches = ranked[0]
    return hub, float(score), list(matches)


@dataclass
class Coverage:
    coverage_status: str
    coverage_score: float  # 0-100, router-derived
    top_skill: str
    route_hub: str
    route_score: float      # raw router score (not scaled)
    priority: float
    rationale: str          # human-readable explanation


def _probe_texts(cluster: Cluster) -> list[str]:
    """Build a small set of texts to probe: intent keywords + top example prompts."""
    texts: list[str] = []
    # 1. Plain intent text: metrics + classifiers
    parts = list(cluster.metrics) + list(cluster.classifiers) + list(cluster.other)
    if parts:
        texts.append(" ".join(parts))
    # 2. Top denoised example prompts
    for text, _ in cluster.examples.most_common(EXAMPLE_PROBE_COUNT):
        if text and text not in texts:
            texts.append(text)
    return texts or ["unknown"]


def classify_cluster(cluster: Cluster) -> Coverage:
    reasons: list[str] = []

    # --- Primary: router simulation over intent + example prompts ---
    best_hub: Optional[str] = None
    best_score: float = 0.0
    best_matches: list[str] = []

    for text in _probe_texts(cluster):
        hub, score, matches = local_route(text)
        if score > best_score:
            best_hub, best_score, best_matches = hub, score, matches

    if best_hub:
        reasons.append(f"router->{best_hub} (score={best_score:.2f}, triggers={best_matches[:3]})")
    else:
        reasons.append("router: no trigger match across intent + examples")

    # --- Secondary: MCP telemetry as a note only ---
    if cluster.mcp_total > 0:
        avg_top = sum(cluster.top_scores) / len(cluster.top_scores) if cluster.top_scores else None
        below_frac = cluster.mcp_below_floor / cluster.mcp_total
        note = f"mcp-telemetry avg_top={avg_top:.2f}" if avg_top is not None else "mcp-telemetry no score"
        if below_frac > 0:
            note += f" below_floor_frac={below_frac:.2f} (informational only)"
        reasons.append(note)

    # --- Classify purely on router score ---
    if best_score >= ROUTE_WELL:
        status = "well_covered"
        # Scale router score to 75-100 range
        cov = min(100.0, 75.0 + (best_score - ROUTE_WELL) * 5.0)
    elif best_score >= ROUTE_PARTIAL:
        status = "partial"
        # Scale to 40-74 range
        cov = 40.0 + (best_score / ROUTE_WELL) * 34.0
    else:
        status = "underserved"
        cov = max(0.0, best_score * 40.0)

    # Determine top_skill: prefer MCP returned IDs, fall back to router hub
    if cluster.returned_skill_ids:
        top_skill = cluster.returned_skill_ids.most_common(1)[0][0]
    else:
        top_skill = best_hub or ""

    weight = {"underserved": 1.0, "partial": 0.5, "well_covered": 0.0}[status]
    priority = cluster.count * max(cluster.distinct_users, 1) * weight

    return Coverage(
        coverage_status=status,
        coverage_score=round(cov, 1),
        top_skill=top_skill,
        route_hub=best_hub or "",
        route_score=round(best_score, 3),
        priority=round(priority, 2),
        rationale="; ".join(reasons),
    )
