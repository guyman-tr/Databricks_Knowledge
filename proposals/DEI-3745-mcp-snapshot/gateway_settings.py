"""Environment-driven settings for the Gateway.

Mirrors the shape of ``databricks-skills-mcp/server/settings.py`` Γאפ same
dataclass-from-env approach, no extra deps. Both servers' settings classes
deliberately stay independent so a change to one doesn't ripple silently.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass, field
from typing import Literal
from urllib.parse import urlparse


def _env(name: str, default: str | None = None) -> str | None:
    val = os.environ.get(name)
    return val if (val is not None and val != "") else default


def _env_int(name: str, default: int) -> int:
    val = _env(name)
    if val is None:
        return default
    try:
        return int(val)
    except ValueError as e:
        raise RuntimeError(f"env var {name}={val!r} is not an integer") from e


def _require(name: str) -> str:
    val = _env(name)
    if not val:
        raise RuntimeError(f"required env var {name} is not set")
    return val


# Allow-list of upstream URL host patterns. Anything outside this set is
# rejected at boot to prevent SSRF via a malicious config (e.g. pointing the
# gateway at the cloud-metadata service or an internal admin endpoint). The
# allow-list deliberately enumerates the *Databricks*-controlled domains plus
# localhost for local development.
ALLOWED_UPSTREAM_HOST_PATTERNS = (
    re.compile(r"^https://[A-Za-z0-9.-]+\.cloud\.databricks\.com($|/)"),
    re.compile(r"^https://[A-Za-z0-9.-]+\.azuredatabricks\.net($|/)"),
    re.compile(r"^https://[A-Za-z0-9.-]+\.gcp\.databricks\.com($|/)"),
    re.compile(r"^https://[A-Za-z0-9.-]+\.databricksapps\.com($|/)"),
    re.compile(r"^https://[A-Za-z0-9.-]+\.staging\.cloud\.databricks\.com($|/)"),
    re.compile(r"^https://localhost(:\d+)?($|/)"),
    re.compile(r"^http://localhost(:\d+)?($|/)"),
    re.compile(r"^https://127\.0\.0\.1(:\d+)?($|/)"),
)


def _validate_upstream_url(url: str, label: str) -> str:
    """Reject any upstream URL outside the allow-list. SSRF prophylaxis."""
    if not any(p.match(url) for p in ALLOWED_UPSTREAM_HOST_PATTERNS):
        raise RuntimeError(
            f"upstream URL for {label} ({url!r}) is not in the allow-list. "
            "Allowed hosts: *.cloud.databricks.com, *.azuredatabricks.net, "
            "*.gcp.databricks.com, *.databricksapps.com, localhost. "
            "If this is a legitimate Databricks-controlled host, extend "
            "ALLOWED_UPSTREAM_HOST_PATTERNS in server/settings.py."
        )
    parsed = urlparse(url)
    if not parsed.hostname:
        raise RuntimeError(f"upstream URL for {label} has no hostname: {url!r}")
    return url


# Fixed path suffix for the audit external table; the storage account name
# comes from AKV via ``DL_STORAGE_ACCOUNT_NAME`` (see app.yaml).
_AUDIT_DELTA_LOCATION_PATH = "Monitoring/mcp_logs/mcp_gateway"


def _audit_location_from_storage_account(account: str) -> str:
    """Build the external-table ABFSS URL from a storage account name."""
    name = account.strip()
    if not name:
        raise RuntimeError("DL_STORAGE_ACCOUNT_NAME is set but empty")
    return f"abfss://config@{name}.dfs.core.windows.net/{_AUDIT_DELTA_LOCATION_PATH}"


def _env_float(name: str, default: float) -> float:
    val = _env(name)
    if val is None:
        return default
    try:
        return float(val)
    except ValueError as e:
        raise RuntimeError(f"env var {name}={val!r} is not a float") from e


def _env_str_set(name: str) -> frozenset[str]:
    """Parse a comma-separated env var into a ``frozenset[str]``.

    Whitespace around each entry is stripped; empty entries (e.g. from
    trailing commas or accidental double-separators) are dropped. The
    matching contract downstream is exact-match, case-sensitive,
    namespace-prefixed tool names Γאפ we intentionally do NOT normalise
    case here so an operator typo can be spotted as "tool not hidden"
    rather than silently matching the wrong tool.

    Returns an empty frozenset when ``name`` is unset or empty so the
    consumer can treat "no hide-list configured" as the zero-cost
    identity case without a separate ``None`` check.
    """
    val = _env(name)
    if not val:
        return frozenset()
    parts = [p.strip() for p in val.split(",")]
    return frozenset(p for p in parts if p)


@dataclass(frozen=True)
class Settings:
    """Gateway runtime settings.

    Auth deliberately *isn't* in this struct Γאפ the gateway no longer runs
    its own OAuth flow. Instead it relies on Databricks Apps'
    ``user_authorization`` mechanism (declared in :file:`app.yaml`), which
    runs the user through workspace SSO at the platform layer and forwards
    each request's user OAuth token via the ``X-Forwarded-Access-Token``
    HTTP header. :class:`server.middleware.ForwardUpstreamAuthMiddleware`
    reads that header per call. Same pattern ``mcp-ai-dev-kit`` uses.

    Optional ``audit_delta_*`` fields enable the unified Delta audit
    table (see :mod:`server.audit_sink`). When ``audit_delta_table``
    is unset, neither the tool-call audit sink nor the sink-health
    sink is constructed and the gateway behaves exactly as before Γאפ
    local development, CI, and any deploy that opts out stay on the
    working stdout-only audit path.

    The table is a tagged union over ``event_type``
    (``tool_call`` / ``drop_summary`` / ``boot_probe``). Two views
    over the same physical table give the typed surfaces analytics
    queries actually want Γאפ see ``docs/LOGGING.md``.
    """

    databricks_host: str

    ai_dev_kit_mcp_url: str
    skills_mcp_url: str
    managed_mcp_functions_path: str  # e.g. "main/default" Γזע /api/2.0/mcp/functions/main/default

    rate_limit_per_minute: int

    is_databricks_app: bool
    log_level: str = "INFO"

    skills_first_enforcement_mode: Literal["off", "on"] = "off"
    skills_first_idle_timeout_s: float = 600.0
    skills_first_max_calls_per_grant: int = 50

    # Unified Delta audit sink (opt-in). When ``audit_delta_table`` is
    # set, ``audit_sql_warehouse_id`` is required and validated at boot.
    # Both the tool-call sink AND the sink-health sink attach when set;
    # leaving it unset disables both.
    audit_delta_table: str | None = None
    audit_sql_warehouse_id: str | None = None
    audit_batch_size: int = 50
    audit_flush_interval_s: float = 5.0
    # When set, the audit table is created EXTERNAL at this storage path
    # via a ``LOCATION '<url>'`` clause. Survives a ``DROP TABLE`` (only
    # the metadata is removed; re-running boot probe re-binds to the
    # existing Delta files at the path). When unset, the table is
    # managed by UC (data files live in UC's managed storage and are
    # deleted on ``DROP TABLE`` Γאפ the original behaviour).
    audit_delta_table_location: str | None = None

    # Triggering-skills context cache (see
    # ``server.middleware._TriggeringSkillsCache``). The cache holds
    # the latest ``skills_find_skills`` candidates per user so the
    # audit row for each *subsequent* tool call can carry them in
    # the ``triggering_skill_ids`` column Γאפ the closest proxy the
    # gateway has to "which find_skills the LLM acted on with this
    # call?". TTL is the question-and-answer thread window; max_users
    # caps the per-process memory footprint.
    audit_triggering_skill_ttl_s: float = 600.0
    audit_triggering_skill_max_users: int = 1000

    # Tool-hiding hide-list. Populated from the ``GATEWAY_HIDDEN_TOOLS``
    # env var (comma-separated, exact-match, namespace-prefixed tool
    # names). Consumed by :class:`server.middleware.ToolHidingMiddleware`
    # to drop entries from ``tools/list`` and reject direct
    # ``tools/call`` requests for the same names. The default is
    # empty so an unset env var is a behaviour-preserving no-op.
    # Operators iterate the list at runtime via
    # ``databricks apps update --env GATEWAY_HIDDEN_TOOLS="..."`` Γאפ
    # no source change required.
    gateway_hidden_tools: frozenset[str] = field(default_factory=frozenset)

    extra: dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_env(cls) -> Settings:
        databricks_host = _require("DATABRICKS_HOST").rstrip("/")

        ai_dev_kit_mcp_url = _validate_upstream_url(
            _require("AI_DEV_KIT_MCP_URL"), "AI_DEV_KIT_MCP_URL"
        )
        skills_mcp_url = _validate_upstream_url(_require("SKILLS_MCP_URL"), "SKILLS_MCP_URL")
        _validate_upstream_url(databricks_host, "DATABRICKS_HOST")

        audit_delta_table = _env("AUDIT_DELTA_TABLE")
        audit_sql_warehouse_id = _env("AUDIT_SQL_WAREHOUSE_ID")
        audit_delta_table_location = _env("AUDIT_DELTA_TABLE_LOCATION")
        dl_storage_account = _env("DL_STORAGE_ACCOUNT_NAME")
        if not audit_delta_table_location and dl_storage_account and audit_delta_table:
            audit_delta_table_location = _audit_location_from_storage_account(
                dl_storage_account
            )
        # Fail loud at boot, not at first request: if an operator turned
        # the sink on they almost certainly meant to set both vars, and
        # discovering the typo via "no rows in the audit table after a
        # week" would be miserable.
        if audit_delta_table and not audit_sql_warehouse_id:
            raise RuntimeError(
                "AUDIT_DELTA_TABLE is set but AUDIT_SQL_WAREHOUSE_ID is missing Γאפ "
                "the Delta audit sink needs both. Unset AUDIT_DELTA_TABLE to disable."
            )
        # An external location without a target table is meaningless and
        # almost certainly an operator error Γאפ fail loud rather than
        # silently dropping the location.
        if audit_delta_table_location and not audit_delta_table:
            raise RuntimeError(
                "AUDIT_DELTA_TABLE_LOCATION is set but AUDIT_DELTA_TABLE is missing Γאפ "
                "an external storage path only makes sense for a configured table."
            )
        # Shape-check the URL now (rather than letting the DDL fail at
        # first request) so a typo is visible in the boot log line. We
        # use the same allow-list grammar the audit sink enforces in
        # ``_validate_location``; importing audit_sink here keeps the
        # validation rule single-sourced.
        if audit_delta_table_location:
            from .audit_sink import _validate_location

            audit_delta_table_location = _validate_location(audit_delta_table_location)

        enforcement_mode = (_env("SKILLS_FIRST_ENFORCEMENT_MODE", "off") or "off").lower()
        if enforcement_mode not in ("off", "on"):
            raise RuntimeError(
                f"SKILLS_FIRST_ENFORCEMENT_MODE={enforcement_mode!r} is invalid; "
                "allowed values: off, on"
            )

        # Triggering-skills cache knobs. Validation is strict at the
        # extremes only: TTL=0 would mean "never carry context" and is
        # better expressed by NOT wiring the cache at all (so we
        # reject); excessively long TTL or huge cache sizes are silent
        # footguns, so we bound them too.
        triggering_ttl = _env_float("AUDIT_TRIGGERING_SKILL_TTL_S", 600.0)
        if triggering_ttl <= 0 or triggering_ttl > 24 * 3600:
            raise RuntimeError(
                f"AUDIT_TRIGGERING_SKILL_TTL_S={triggering_ttl} is out of bounds; "
                "expected (0, 86400] seconds"
            )
        triggering_max_users = _env_int("AUDIT_TRIGGERING_SKILL_MAX_USERS", 1000)
        if triggering_max_users < 1 or triggering_max_users > 100_000:
            raise RuntimeError(
                f"AUDIT_TRIGGERING_SKILL_MAX_USERS={triggering_max_users} is out of bounds; "
                "expected [1, 100000]"
            )

        return cls(
            databricks_host=databricks_host,
            ai_dev_kit_mcp_url=ai_dev_kit_mcp_url,
            skills_mcp_url=skills_mcp_url,
            managed_mcp_functions_path=(
                _env("MANAGED_MCP_FUNCTIONS_PATH", "main/default") or "main/default"
            ),
            rate_limit_per_minute=_env_int("RATE_LIMIT_PER_MINUTE", 240),
            skills_first_enforcement_mode=enforcement_mode,  # type: ignore[arg-type]
            skills_first_idle_timeout_s=_env_float("SKILLS_FIRST_IDLE_TIMEOUT_S", 600.0),
            skills_first_max_calls_per_grant=_env_int(
                "SKILLS_FIRST_MAX_CALLS_PER_GRANT", 50
            ),
            is_databricks_app="DATABRICKS_APP_NAME" in os.environ,
            log_level=_env("LOG_LEVEL", "INFO") or "INFO",
            audit_delta_table=audit_delta_table,
            audit_sql_warehouse_id=audit_sql_warehouse_id,
            audit_batch_size=_env_int("AUDIT_BATCH_SIZE", 50),
            audit_flush_interval_s=_env_float("AUDIT_FLUSH_INTERVAL_S", 5.0),
            audit_delta_table_location=audit_delta_table_location,
            audit_triggering_skill_ttl_s=triggering_ttl,
            audit_triggering_skill_max_users=triggering_max_users,
            gateway_hidden_tools=_env_str_set("GATEWAY_HIDDEN_TOOLS"),
        )
