"""FastMCP + FastAPI entrypoint for the Skills MCP.

Composition:

- ``mcp_server`` Γאפ the FastMCP instance with the three skill tools registered.
- ``app`` Γאפ a sibling FastAPI for the ``/admin/refresh`` admin endpoint.
- ``asgi_app`` Γאפ combined ASGI app (MCP routes + admin route + header capture).

Lifespan: on startup we sync the data-skills repo, validate the corpus, embed,
and build the FAISS index. The admin endpoint and the optional periodic poll
both call into the same ``rebuild_index`` coroutine Γאפ atomic swap inside the
``SkillIndex`` keeps reads consistent.
"""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from fastmcp import FastMCP

from .auth import capture_headers_to_contextvar, get_app_workspace_client
from .embedder import Embedder
from .git_sync import sync as git_sync
from .index import SkillIndex
from .loader import load_skills
from .settings import Settings
from .tools import CutoffPolicy, SubPassPolicy, register_tools

logger = logging.getLogger(__name__)


_settings: Settings = Settings.from_env()
_skill_index = SkillIndex()
_embedder = Embedder(
    endpoint_name=_settings.embedding_endpoint,
    client_factory=get_app_workspace_client,
)
_rebuild_lock = asyncio.Lock()
_periodic_task: asyncio.Task | None = None


async def rebuild_index() -> dict:
    """Sync the corpus, validate, embed, and atomically swap the index.

    Idempotent. Holds an asyncio lock so concurrent triggers (admin POST +
    periodic poll) don't double-embed.
    """
    async with _rebuild_lock:
        loop = asyncio.get_running_loop()
        # Synchronous git + FAISS work is offloaded to the default executor
        # so the event loop stays responsive for in-flight tool calls.
        repo_dir = await loop.run_in_executor(
            None,
            git_sync,
            _settings.repo_url,
            _settings.repo_ref,
            _settings.local_cache_dir,
        )
        # Apply ``SKILLS_REPO_SUBDIR`` so monorepo layouts (e.g.
        # eToro/DataPlatform Γזע databricks/data-skills) can point at a folder
        # inside the cloned repo instead of the repo root.
        corpus_root = (
            repo_dir / _settings.repo_subdir if _settings.repo_subdir else repo_dir
        )
        # ``functools.partial`` keeps ``run_in_executor``'s positional-args
        # contract while letting us pass the kill-switch as a keyword.
        # Phase-1 sub-skill body resolution is gated on this Γאפ when the
        # setting is ``False`` the loader behaves identically to the
        # pre-v1 path (no second-pass machinery, no per-child files
        # read), which is the operational rollback contract.
        from functools import partial

        skills = await loop.run_in_executor(
            None,
            partial(
                load_skills,
                corpus_root,
                sub_pass_enabled=_settings.skills_sub_pass_enabled,
            ),
        )

        # Gather hub texts plus each hub's child texts into one flat
        # batch. A single embed() call is dramatically faster than
        # per-hub calls Γאפ the FM endpoint amortises model load over
        # the whole batch, and the network round-trip dominates per
        # call. The ``offsets`` book lets us slice the result back
        # into hub-vectors and per-hub child matrices below.
        #
        # When the kill switch is off, ``skill.sub_skills`` is always
        # empty (the loader silently dropped the ``sub_skills:`` keys
        # for us) Γאפ so this branch-free code naturally degrades to
        # "hub vectors only" with zero per-child cost.
        texts: list[str] = []
        offsets: list[tuple[int, int, int]] = []  # (hub_idx, child_start, child_end)
        for hub_idx, hub in enumerate(skills):
            texts.append(hub.embedding_text())
            child_start = len(texts)
            for sub in hub.sub_skills:
                texts.append(sub.embedding_text())
            offsets.append((hub_idx, child_start, len(texts)))

        all_vectors = await loop.run_in_executor(None, _embedder.embed, texts)

        hub_vectors = all_vectors[: len(skills)]
        child_vectors_by_hub: dict = {}
        for hub_idx, child_start, child_end in offsets:
            if child_end > child_start:
                child_vectors_by_hub[skills[hub_idx].id] = all_vectors[
                    child_start:child_end
                ]

        await loop.run_in_executor(
            None,
            partial(
                _skill_index.build,
                skills,
                hub_vectors,
                child_vectors_by_hub=child_vectors_by_hub,
            ),
        )

        sub_skill_count = sum(len(s.sub_skills) for s in skills)
        return {
            "status": "ok",
            "skills_loaded": len(skills),
            "sub_skills_loaded": sub_skill_count,
        }


@asynccontextmanager
async def lifespan(_app: FastAPI):
    logging.basicConfig(level=_settings.log_level)
    logger.info(
        "starting Skills MCP: repo=%s ref=%s endpoint=%s",
        _settings.repo_url, _settings.repo_ref, _settings.embedding_endpoint,
    )
    try:
        result = await rebuild_index()
        logger.info("initial corpus load: %s", result)
    except Exception as e:  # noqa: BLE001
        # We deliberately fail loud on startup rather than serving an empty
        # index Γאפ an empty Skills MCP would silently degrade every chat.
        logger.exception("initial corpus load failed: %s", e)
        raise

    if _settings.refresh_interval_seconds > 0:
        global _periodic_task
        _periodic_task = asyncio.create_task(
            _periodic_refresh(_settings.refresh_interval_seconds)
        )

    yield

    if _periodic_task is not None:
        _periodic_task.cancel()
        try:
            await _periodic_task
        except (asyncio.CancelledError, Exception):
            pass


async def _periodic_refresh(interval_seconds: int) -> None:
    while True:
        try:
            await asyncio.sleep(interval_seconds)
            result = await rebuild_index()
            logger.info("periodic refresh: %s", result)
        except asyncio.CancelledError:
            raise
        except Exception as e:  # noqa: BLE001
            # Never crash the loop; just log and try again next tick.
            logger.warning("periodic refresh failed (will retry): %s", e)


mcp_server = FastMCP(
    name="databricks-skills-mcp",
    instructions=(
        "Curated Databricks data skills retrieval MCP. Call find_skills with a "
        "natural-language question to get the top-K skills the calling user can "
        "actually query (filtered by Unity Catalog ACL). Each skill carries "
        "Unity Catalog table names plus business grounding Γאפ typically a "
        "body_markdown glossary (revenue definitions, customer segments, etc.) "
        "and/or an advisory example_sql. Use whichever the skill provides as "
        "the source of truth for table choices, joins, and filters. This MCP "
        "does NOT execute SQL Γאפ to run the query, use the upstream "
        "databricks_sql_* / databricks_uc_* / databricks_genie_* tools."
    ),
)

register_tools(
    mcp_server,
    skill_index=_skill_index,
    embedder=_embedder,
    cutoff_policy=CutoffPolicy(
        min_score=_settings.skills_min_score,
        buffer=_settings.skills_cutoff_buffer,
        search_window=_settings.skills_cutoff_search_window,
    ),
    sub_pass_policy=SubPassPolicy(
        enabled=_settings.skills_sub_pass_enabled,
        k_default=_settings.skills_sub_k_default,
        min_score=_settings.skills_sub_min_score,
    ),
)

mcp_app = mcp_server.http_app(path="/mcp", stateless_http=True)


@asynccontextmanager
async def _combined_lifespan(app: FastAPI):
    async with lifespan(app):
        async with mcp_app.lifespan(app):
            yield


app = FastAPI(
    title="databricks-skills-mcp",
    description="Skills MCP Γאפ embedding-based retrieval over the data-skills corpus.",
    version="0.1.0",
    lifespan=_combined_lifespan,
)


@app.post("/admin/refresh", include_in_schema=True)
async def admin_refresh(
    authorization: str | None = Header(default=None),
) -> JSONResponse:
    """Force a re-pull + revalidate + re-embed + atomic-swap of the index.

    Auth: ``Authorization: Bearer $SKILLS_ADMIN_TOKEN`` is required when the
    setting is configured. In local dev (no admin token configured) the
    endpoint is open Γאפ use a firewall or don't expose it.
    """
    if _settings.admin_token:
        if authorization != f"Bearer {_settings.admin_token}":
            raise HTTPException(status_code=401, detail="unauthorized")

    try:
        result = await rebuild_index()
        return JSONResponse(result)
    except Exception as e:  # noqa: BLE001
        logger.exception("admin refresh failed")
        raise HTTPException(status_code=500, detail=str(e)) from e


@app.get("/healthz", include_in_schema=False)
async def healthz() -> dict:
    return {"status": "ok", "skills_loaded": _skill_index.size}


# Combine MCP + admin routes into a single ASGI app for Uvicorn.
asgi_app = FastAPI(
    title="databricks-skills-mcp (combined)",
    routes=[*mcp_app.routes, *app.routes],
    lifespan=_combined_lifespan,
)


@asgi_app.middleware("http")
async def _capture_headers(request: Request, call_next):
    """Pop the request headers into a contextvar so downstream tools / ACL
    code can read ``x-forwarded-access-token`` without it ever appearing in
    logs or function signatures."""
    token = capture_headers_to_contextvar(dict(request.headers))
    try:
        return await call_next(request)
    finally:
        # Reset so a subsequent request on the same task doesn't see stale
        # headers in the unlikely event the worker reuses the contextvar
        # snapshot.
        from .auth import header_store
        header_store.reset(token)
