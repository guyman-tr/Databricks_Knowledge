"""ACL pre-check for the Skills MCP.

We never *return data* Γאפ but we do return an `example_sql` string and the
table names a user can query. Returning skills the user has no permission to
read makes the LLM hallucinate "we can answer that" answers and then fail
loudly at execution time. Filtering at retrieval keeps the LLM honest.

Implementation: a fast ``DESCRIBE TABLE`` probe via the official
``databricks-mcp`` Python client against ``/api/2.0/mcp/sql``.
``PERMISSION_DENIED`` and ``NOT_FOUND`` both mean "not visible". Other errors
are treated as transient Γאפ we deliberately do **not** filter on infra
failures so a managed-MCP outage degrades gracefully (a few false positives)
rather than catastrophically (returning zero skills).

Cache: ``(user_id, asset)`` keys with a 60-second TTL on *terminal*
verdicts only Γאפ ``ok``, ``permission_denied``, ``not_found``. Transient
``error`` results are deliberately **not** cached so the next call
re-probes immediately once upstream recovers, instead of serving a stale
fail-open verdict for up to 60 s. The cache is per process; with the
gateway's session-affinity strategy this gives a hit rate of essentially
100% on terminal verdicts within a single chat.
"""

from __future__ import annotations

import logging
import os
from collections.abc import Callable
from dataclasses import dataclass

from cachetools import TTLCache
from databricks.sdk import WorkspaceClient

from .auth import current_user_id, get_user_workspace_client
from .schema import Skill, SubSkill

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class AclProbeResult:
    visible: bool
    """True iff the user could DESCRIBE the table."""

    reason: str
    """Short tag for logs/audit: "ok", "permission_denied", "not_found", "error"."""


# (user_id, asset) -> AclProbeResult
_acl_cache: TTLCache[tuple[str, str], AclProbeResult] = TTLCache(
    maxsize=10_000, ttl=60
)


def _build_sql_mcp_client(ws_client: WorkspaceClient):
    """Construct the SQL MCP client. Imported lazily so tests can stub it."""
    from databricks_mcp import DatabricksMCPClient  # type: ignore[import-not-found]

    host = (ws_client.config.host or os.environ.get("DATABRICKS_HOST") or "").rstrip("/")
    if not host:
        raise RuntimeError(
            "DATABRICKS_HOST is required for the SQL MCP probe; not found on "
            "the WorkspaceClient config or in the environment."
        )
    return DatabricksMCPClient(
        server_url=f"{host}/api/2.0/mcp/sql",
        workspace_client=ws_client,
    )


def probe_asset(
    asset: str,
    *,
    ws_client_factory: Callable[[], WorkspaceClient] | None = None,
    sql_client_builder: Callable[[WorkspaceClient], object] | None = None,
) -> AclProbeResult:
    """Probe one UC asset; return whether the current user can see it."""
    user_id = current_user_id()
    cached = _acl_cache.get((user_id, asset))
    if cached is not None:
        return cached

    factory = ws_client_factory or get_user_workspace_client
    ws_client = factory()
    builder = sql_client_builder or _build_sql_mcp_client
    sql_client = builder(ws_client)

    try:
        sql_client.call_tool(  # type: ignore[attr-defined]
            "execute_sql",
            {"query": f"DESCRIBE TABLE {asset}", "limit": 1},
        )
        result = AclProbeResult(visible=True, reason="ok")
    except Exception as e:  # noqa: BLE001
        msg = str(e).lower()
        access_denied = "access" in msg and "denied" in msg
        if "permission_denied" in msg or "permission denied" in msg or access_denied:
            result = AclProbeResult(visible=False, reason="permission_denied")
        elif "not_found" in msg or "not found" in msg or "does not exist" in msg:
            result = AclProbeResult(visible=False, reason="not_found")
        else:
            # Transient infra error Γאפ fail open so the user still sees the
            # skill, but do NOT cache the result so the next call re-probes
            # immediately once upstream recovers (vs. waiting out the 60s
            # TTL with a stale fail-open verdict).
            logger.warning(
                "ACL probe error for %s (treating as transient): %s",
                asset, _scrub(str(e)),
            )
            return AclProbeResult(visible=True, reason="error")

    _acl_cache[(user_id, asset)] = result
    return result


def filter_by_acl(skills: list[Skill]) -> list[Skill]:
    """Return only skills whose every UC asset is currently visible to the user."""
    if not skills:
        return []

    needed_assets = {a for s in skills for a in s.unity_catalog_assets}
    decisions: dict[str, AclProbeResult] = {}
    for asset in sorted(needed_assets):
        decisions[asset] = probe_asset(asset)

    visible: list[Skill] = []
    for s in skills:
        if all(decisions[a].visible for a in s.unity_catalog_assets):
            visible.append(s)
        else:
            denied = [a for a in s.unity_catalog_assets if not decisions[a].visible]
            logger.debug(
                "skill %s filtered out Γאפ user lacks access to %s",
                s.id, denied,
            )

    return visible


def filter_by_acl_with_subs(
    items: list[tuple[Skill, list[SubSkill]]],
) -> list[tuple[Skill, list[SubSkill]]]:
    """ACL-union variant for the hub-and-spoke second pass.

    Each input is a ``(hub, matched_sub_skills)`` pair. The hub passes
    iff EVERY asset in the union of (hub's own ``unity_catalog_assets``
    Γט¬ the matched children's ``unity_catalog_assets``) is currently
    visible to the caller.

    Rationale: today's hubs declare ``unity_catalog_assets: []`` and
    let the children carry the table anchors, so the pre-v1
    "hub-only" ACL check trivially passed every hub regardless of
    whether the caller could actually read the underlying tables.
    Union ACL closes that leak. See ┬º8.1 of the routing proposal and
    the reviewer's confirmation in the design call.

    Note: this is intentionally STRICTER than the previous behaviour
    for hubs with matched children Γאפ a hub with one inaccessible
    child fails entirely. That's the safer side of the trade-off
    while the corpus and audit baseline are still settling. If the
    audit log shows excessive over-filtering once sub-pass is on in
    dev, the rule can be softened to "drop the inaccessible children
    individually" without breaking the public response shape.

    Returns the input order preserved, with non-passing hubs removed.
    """
    if not items:
        return []

    needed_assets: set[str] = set()
    for hub, subs in items:
        needed_assets.update(hub.unity_catalog_assets)
        for sub in subs:
            needed_assets.update(sub.unity_catalog_assets)

    decisions: dict[str, AclProbeResult] = {}
    for asset in sorted(needed_assets):
        decisions[asset] = probe_asset(asset)

    visible: list[tuple[Skill, list[SubSkill]]] = []
    for hub, subs in items:
        composite = set(hub.unity_catalog_assets)
        for sub in subs:
            composite.update(sub.unity_catalog_assets)
        if all(decisions[a].visible for a in composite):
            visible.append((hub, subs))
        else:
            denied = sorted(a for a in composite if not decisions[a].visible)
            logger.debug(
                "hub %s (with %d matched sub-skill(s)) filtered out Γאפ user "
                "lacks access to %s",
                hub.id, len(subs), denied,
            )

    return visible


def _scrub(s: str) -> str:
    """Strip Databricks tokens from a string before logging it."""
    import re

    s = re.sub(r"dapi[A-Za-z0-9_-]{20,}", "dapi***REDACTED***", s)
    s = re.sub(r"eyJ[A-Za-z0-9_.-]{20,}", "eyJ***REDACTED***", s)
    return s


def clear_cache() -> None:
    """Test hook Γאפ wipe the cache between tests."""
    _acl_cache.clear()
