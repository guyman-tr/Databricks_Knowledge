"""FastMCP gateway entry point.

This module wires the upstream proxies and middleware stack into a single
parent :class:`FastMCP` server. Boot sequence:

1. Load :class:`Settings` from env (validates SSRF allow-list as a side
   effect).
2. Construct the parent :class:`FastMCP` server with :data:`SYSTEM_HINT`
   as ``instructions``. **No** ``auth=`` is set Γאפ Databricks Apps'
   ``user_authorization`` runs the user through workspace SSO at the
   platform layer and forwards their U2M token via
   ``X-Forwarded-Access-Token``. We trust the platform for auth and
   forward the header verbatim to upstream MCPs.
3. Install the middleware stack (audit, rate-limit, skills-first,
   client-info, forward-auth) and the global log-redaction filter.
4. For each upstream, build a :class:`FastMCPProxy` with a request-scoped
   client factory and mount it under its namespace.
5. Expose the result as an ASGI app at ``/mcp``.

Everything else Γאפ schemas, ACLs, embeddings Γאפ lives in Server 2 and the
managed MCPs. The Gateway stays a thin, predictable composition layer.

Reference: ``mcp-ai-dev-kit/server_http.py`` follows the same pattern
(read ``X-Forwarded-Access-Token`` per request, forward to the
underlying Databricks call). We mirror that here for our four upstreams.
"""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastmcp import FastMCP

from .instructions import SYSTEM_HINT
from .middleware import (
    AuditMiddleware,
    ClientInfoMiddleware,
    ForwardUpstreamAuthMiddleware,
    RateLimitMiddleware,
    SkillsFirstMiddleware,
    ToolDescriptionRewriterMiddleware,
    ToolHidingMiddleware,
    _TriggeringSkillsCache,
    install_log_redaction,
)
from .settings import Settings
from .upstream import build_proxies

logger = logging.getLogger(__name__)


# Attribute name used to stash the optional DeltaAuditHandler on the
# FastMCP gateway instance. Kept as a constant so tests and operators
# can reach in without duplicating the string. The lifespan owns the
# actual shutdown call; setattr here is for introspection only.
_DELTA_AUDIT_HANDLER_ATTR = "_delta_audit_handler"
_DELTA_HEALTH_HANDLER_ATTR = "_delta_health_handler"


def _make_shutdown_lifespan(handlers: list[logging.Handler]):
    """Return a FastMCP/Starlette lifespan that closes ``handlers`` on exit.

    The handler list is captured by reference: it is empty at the
    moment :class:`FastMCP` is constructed (the lifespan must be
    passed to the constructor) but is mutated in place when audit
    handlers attach later in :func:`build_gateway`. By the time the
    lifespan's ``finally:`` runs at process shutdown, the list holds
    every handler we need to close.

    Close order is the reverse of registration order: the audit
    handler closes first so its final ``drop_summary`` log record (if
    any) can still land in the table via the health handler. Per-handler
    ``close()`` failures are logged and swallowed so one broken handler
    cannot keep the others from draining Γאפ audit must never block
    normal shutdown.

    The lifespan is intentionally tiny (no startup work) because
    FastMCP's own internal HTTP-app lifespan handles the MCP
    StreamableHTTP session manager. FastMCP composes the user-supplied
    lifespan with its own; we only need the shutdown teardown hook.
    """

    @asynccontextmanager
    async def lifespan(_server: Any) -> AsyncIterator[None]:
        try:
            yield
        finally:
            for h in reversed(handlers):
                try:
                    h.close()
                except Exception:  # noqa: BLE001 Γאפ shutdown must drain every handler
                    logger.exception("audit handler close failed: %s", type(h).__name__)

    return lifespan


def build_gateway(settings: Settings | None = None) -> FastMCP:
    """Build the parent gateway :class:`FastMCP` instance.

    Tests pass an explicit ``settings`` to avoid env reads; production calls
    this with ``None`` so :meth:`Settings.from_env` does the validation.

    When ``settings.audit_delta_table`` is set, attaches a
    :class:`DeltaAuditHandler` to the ``databricks-mcp-gateway.audit``
    logger so each tool call's audit JSON is mirrored as a typed row in
    a Unity Catalog Delta table, plus a sibling :class:`DeltaHealthHandler`
    on the ``databricks-mcp-gateway.audit_sink`` logger for boot-probe
    and drop-summary rows. Both handlers are registered with a lifespan
    closure so Starlette closes them (i.e. flushes their drain threads)
    during graceful shutdown. When the env var is unset, this whole code
    path is skipped and behaviour matches the previous stdout-only audit.
    """
    settings = settings or Settings.from_env()
    install_log_redaction()
    logging.basicConfig(level=getattr(logging, settings.log_level.upper(), logging.INFO))

    # Handlers attached below are appended to this list; the lifespan
    # closure captures the list reference and closes each handler on
    # shutdown. Empty list = lifespan is a no-op.
    handlers_to_close: list[logging.Handler] = []

    gateway = FastMCP(
        name="databricks-mcp-gateway",
        instructions=SYSTEM_HINT,
        lifespan=_make_shutdown_lifespan(handlers_to_close),
    )

    # Middleware order (FastMCP runs first-added outermost):
    #   AuditMiddleware -> RateLimitMiddleware -> SkillsFirstMiddleware ->
    #   ToolHidingMiddleware -> ToolDescriptionRewriterMiddleware ->
    #   ClientInfoMiddleware -> ForwardUpstreamAuthMiddleware -> handler
    # SkillsFirstMiddleware and ToolHidingMiddleware both sit INSIDE
    # audit + rate-limit so their rejections are still audited and
    # counted against the rate-limit bucket. ToolHidingMiddleware sits
    # OUTSIDE the description rewriter so the rewriter doesn't waste
    # work rewriting descriptions for tools we're about to drop from
    # the list. Both sit OUTSIDE Forward (which only hooks on_request
    # and is irrelevant to the on_call_tool guard path).
    # ClientInfoMiddleware only fires on on_initialize (NOT on the
    # tool-call hot path), so its placement in the stack is
    # informational Γאפ it just needs to be registered. The shared
    # instance is passed into AuditMiddleware so the audit row can
    # attribute the call to a client name/version.
    client_info_mw = ClientInfoMiddleware()
    # Triggering-skills context cache: owned by AuditMiddleware, sized
    # and TTL'd from Settings. One instance per process; rebooting
    # the app clears it (acceptable Γאפ the cache is forensic
    # convenience, not correctness).
    triggering_skills_cache = _TriggeringSkillsCache(
        ttl_s=settings.audit_triggering_skill_ttl_s,
        max_users=settings.audit_triggering_skill_max_users,
    )
    gateway.add_middleware(
        AuditMiddleware(
            client_info_mw=client_info_mw,
            triggering_skills_cache=triggering_skills_cache,
        )
    )
    gateway.add_middleware(RateLimitMiddleware(calls_per_minute=settings.rate_limit_per_minute))
    if settings.skills_first_enforcement_mode == "on":
        gateway.add_middleware(
            SkillsFirstMiddleware(
                idle_timeout_s=settings.skills_first_idle_timeout_s,
                max_calls_per_grant=settings.skills_first_max_calls_per_grant,
            )
        )
    # Always installed; empty hide-list = identity behaviour on both
    # hooks. Empty default is the codebase-wide "feature off until
    # opted in" pattern (mirrors SkillsFirstMiddleware's default off).
    gateway.add_middleware(ToolHidingMiddleware(settings.gateway_hidden_tools))
    gateway.add_middleware(ToolDescriptionRewriterMiddleware())
    gateway.add_middleware(client_info_mw)
    gateway.add_middleware(ForwardUpstreamAuthMiddleware())

    for namespace, proxy in build_proxies(settings):
        gateway.mount(proxy, namespace=namespace)
        logger.info("mounted upstream %s -> %s", namespace, proxy.name)

    # Single opt-in (``AUDIT_DELTA_TABLE``) drives both the tool-call
    # sink and the sink-health sink Γאפ they share one Delta table,
    # distinguished by ``event_type``. Order matters: attach the
    # health handler FIRST so the audit handler's own boot-probe
    # records (emitted during its __init__) land in the table.
    # Close order at shutdown is the reverse (audit Γזע health), set
    # by ``_make_shutdown_lifespan``.
    if settings.audit_delta_table:
        h_health = _attach_delta_health_handler(gateway, settings)
        if h_health is not None:
            handlers_to_close.append(h_health)
        h_audit = _attach_delta_audit_handler(gateway, settings)
        if h_audit is not None:
            handlers_to_close.append(h_audit)

    return gateway


def _attach_delta_audit_handler(gateway: FastMCP, settings: Settings) -> logging.Handler | None:
    """Wire the Delta audit sink onto the audit logger.

    Import is deferred so unit tests that build a gateway without the
    sink don't pay the ``databricks-sdk`` import cost (and so a missing
    SDK install doesn't break those tests). Any failure here is logged
    and swallowed Γאפ the gateway must keep serving even if the audit
    sink fails to attach. Returns the constructed handler (or ``None``
    on failure) so :func:`build_gateway` can register it for shutdown
    cleanup.
    """
    try:
        from .audit_sink import DeltaAuditHandler

        handler = DeltaAuditHandler(settings)
    except Exception:  # noqa: BLE001 Γאפ boot must not crash the gateway
        logger.exception("failed to construct DeltaAuditHandler; continuing with stdout-only audit")
        return None
    audit_logger = logging.getLogger("databricks-mcp-gateway.audit")
    audit_logger.addHandler(handler)
    setattr(gateway, _DELTA_AUDIT_HANDLER_ATTR, handler)
    return handler


def _attach_delta_health_handler(gateway: FastMCP, settings: Settings) -> logging.Handler | None:
    """Wire the Delta health sink onto the audit_sink logger.

    Same fail-degraded posture as the audit handler: any construction
    failure is logged and swallowed so the gateway still serves.
    Returns the handler (or ``None`` on failure) so :func:`build_gateway`
    can register it for shutdown cleanup.
    """
    try:
        from .audit_sink import DeltaHealthHandler

        handler = DeltaHealthHandler(settings)
    except Exception:  # noqa: BLE001 Γאפ boot must not crash the gateway
        logger.exception(
            "failed to construct DeltaHealthHandler; continuing with stdout-only sink diagnostics"
        )
        return None
    audit_sink_logger = logging.getLogger("databricks-mcp-gateway.audit_sink")
    audit_sink_logger.addHandler(handler)
    setattr(gateway, _DELTA_HEALTH_HANDLER_ATTR, handler)
    return handler


def build_asgi_app():
    """Return the ASGI app for ``uvicorn`` / Databricks Apps.

    The optional :class:`DeltaAuditHandler` / :class:`DeltaHealthHandler`
    cleanup is wired into FastMCP's lifespan context manager (see
    :func:`_make_shutdown_lifespan` and :func:`build_gateway`), which
    Starlette runs after all in-flight requests drain during graceful
    shutdown. This is more reliable than :func:`atexit` on Databricks
    Apps, which may SIGKILL after a deploy roll. No post-hoc event-handler
    wiring is required here Γאפ ``http_app`` inherits the lifespan from
    the FastMCP constructor.
    """
    gateway = build_gateway()
    return gateway.http_app(path="/mcp", stateless_http=True)


asgi_app = None  # populated lazily by main(); kept exportable for tooling


def get_app():
    """Lazy ASGI app for ``uvicorn server.app:get_app``-style imports."""
    global asgi_app
    if asgi_app is None:
        asgi_app = build_asgi_app()
    return asgi_app
