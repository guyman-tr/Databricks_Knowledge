"""Environment-driven settings for the Skills MCP.

We deliberately use a tiny pydantic-Settings-style class instead of pulling in
``pydantic-settings``: this server has so few knobs that the dependency cost
isn't justified and it makes the local-dev fallbacks more discoverable.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path


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


def _env_float(name: str, default: float) -> float:
    """Same shape as :func:`_env_int` but for floats.

    Kept tiny on purpose: parse + validate the *range* in
    :meth:`Settings.from_env` so the error message can name the field's
    semantic role rather than just "not a float".
    """
    val = _env(name)
    if val is None:
        return default
    try:
        return float(val)
    except ValueError as e:
        raise RuntimeError(f"env var {name}={val!r} is not a float") from e


def _env_bool(name: str, default: bool) -> bool:
    """Parse a boolean env var with the same explicit-failure shape.

    Accepted truthy: ``true`` / ``1`` / ``yes`` / ``on`` (case-insensitive).
    Accepted falsy: ``false`` / ``0`` / ``no`` / ``off`` / empty.
    Anything else raises so a typo (``SKILLS_SUB_PASS_ENABLED=tru``)
    fails the process at boot instead of silently behaving as ``false``.
    """
    val = _env(name)
    if val is None:
        return default
    lowered = val.strip().lower()
    if lowered in {"true", "1", "yes", "on"}:
        return True
    if lowered in {"false", "0", "no", "off", ""}:
        return False
    raise RuntimeError(
        f"env var {name}={val!r} is not a boolean (expected true/false/1/0/yes/no/on/off)"
    )


@dataclass(frozen=True)
class Settings:
    """Runtime configuration for the Skills MCP."""

    repo_url: str
    repo_ref: str
    repo_subdir: str | None
    local_cache_dir: Path
    refresh_interval_seconds: int
    embedding_endpoint: str
    vector_search_index: str | None
    admin_token: str | None
    databricks_host: str | None
    is_databricks_app: bool

    # Adaptive-K + labelling-floor knobs (see find_skills in tools.py).
    # All three have safe-for-local-dev defaults Γאפ the production values
    # live in app.yaml. The floor is empirical for this corpus +
    # embedding endpoint; the gap-cut defaults are the Adaptive-K paper's
    # published B=5 buffer and top-90% search window (arXiv:2506.08479).
    skills_min_score: float = 0.0
    skills_cutoff_buffer: int = 5
    skills_cutoff_search_window: float = 0.9

    # Sub-skill (hub-and-spoke) second-pass routing knobs. All three are
    # off-by-default so the v1 sub-skills work ships dark until corpus
    # authoring catches up and ops flips the master switch in dev:
    #
    # * ``skills_sub_pass_enabled`` Γאפ master kill switch. When False,
    #   the loader skips ``sub_skills:`` body resolution entirely (the
    #   listed children are dropped exactly like today's "supplementary
    #   reference content"), the index drops to single-vector-per-hub,
    #   and ``find_skills`` returns its pre-v1 payload byte-for-byte.
    #   Operational rollback path that requires zero corpus changes.
    #
    # * ``skills_sub_k_default`` Γאפ how many matched children to attach
    #   per returned hub when the caller doesn't pass ``sub_k``
    #   explicitly. Caps at 3 because the response payload grows
    #   ``hubs * sub_k * body_size`` and we already cap each body
    #   excerpt at ~1500 chars in the embedding step.
    #
    # * ``skills_sub_min_score`` Γאפ labelling floor for sub-skill
    #   matches. Same "label, don't drop" semantics as the hub-level
    #   ``skills_min_score`` (the v6.1 commit) so the LLM sees a
    #   ``match_quality_hint`` on each child instead of an opaque empty
    #   list when nothing clears the floor.
    skills_sub_pass_enabled: bool = False
    skills_sub_k_default: int = 1
    skills_sub_min_score: float = 0.0

    log_level: str = "INFO"

    extra: dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_env(cls) -> Settings:
        # When running locally (no DATABRICKS_APP_NAME), default to a sensible
        # file:// URL pointing at the data-skills folder two levels up Γאפ assumes
        # the typical local-dev cwd is the package root (databricks-skills-mcp/),
        # so ../../data-skills resolves to databricks/data-skills/. Production
        # manifests must override this explicitly via SKILLS_REPO_URL.
        is_app = "DATABRICKS_APP_NAME" in os.environ
        default_repo = "file://../../data-skills" if not is_app else None
        repo_url = _env("SKILLS_REPO_URL", default_repo)
        if not repo_url:
            raise RuntimeError(
                "SKILLS_REPO_URL must be set (file://Γאª for local dev, "
                "https://Γאª for production)."
            )
        # Optional subdir-within-repo. Lets us point SKILLS_REPO_URL at a
        # monorepo (e.g. eToro/DataPlatform) and load the corpus from
        # ``databricks/data-skills`` inside it without forking. Stripped of
        # leading/trailing slashes so users can drop in either form.
        subdir_raw = _env("SKILLS_REPO_SUBDIR")
        repo_subdir = subdir_raw.strip("/") if subdir_raw else None
        # Adaptive-K + labelling-floor knobs. Validate range up front
        # rather than at the call site so misconfiguration fails the
        # process at startup with a clear message Γאפ silently clipping
        # would hide the operator's intent and complicate audit
        # interpretation later.
        skills_min_score = _env_float("SKILLS_MIN_SCORE", 0.0)
        if not 0.0 <= skills_min_score <= 1.0:
            raise RuntimeError(
                f"SKILLS_MIN_SCORE={skills_min_score!r} out of range; "
                "must be in [0.0, 1.0] (cosine similarity)."
            )
        skills_cutoff_buffer = _env_int("SKILLS_CUTOFF_BUFFER", 5)
        if not 0 <= skills_cutoff_buffer <= 50:
            raise RuntimeError(
                f"SKILLS_CUTOFF_BUFFER={skills_cutoff_buffer!r} out of range; "
                "must be in [0, 50]."
            )
        skills_cutoff_search_window = _env_float("SKILLS_CUTOFF_SEARCH_WINDOW", 0.9)
        if not 0.5 <= skills_cutoff_search_window <= 1.0:
            raise RuntimeError(
                f"SKILLS_CUTOFF_SEARCH_WINDOW={skills_cutoff_search_window!r} "
                "out of range; must be in [0.5, 1.0] (fraction of the sorted "
                "score list searched for the largest gap)."
            )

        # Sub-skill (hub-and-spoke) knobs. Same boot-time range check
        # discipline as the Adaptive-K knobs above Γאפ misconfiguration
        # fails the process with a precise message rather than silently
        # clipping (which would hide operator intent and confuse audit
        # interpretation later).
        skills_sub_pass_enabled = _env_bool("SKILLS_SUB_PASS_ENABLED", False)
        skills_sub_k_default = _env_int("SKILLS_SUB_K_DEFAULT", 1)
        if not 0 <= skills_sub_k_default <= 3:
            raise RuntimeError(
                f"SKILLS_SUB_K_DEFAULT={skills_sub_k_default!r} out of range; "
                "must be in [0, 3]. Set to 0 to disable the second pass per "
                "call while leaving the master switch on (e.g. a stricter "
                "client that doesn't want children)."
            )
        skills_sub_min_score = _env_float(
            "SKILLS_SUB_MIN_SCORE", skills_min_score
        )
        if not 0.0 <= skills_sub_min_score <= 1.0:
            raise RuntimeError(
                f"SKILLS_SUB_MIN_SCORE={skills_sub_min_score!r} out of range; "
                "must be in [0.0, 1.0] (cosine similarity)."
            )

        return cls(
            repo_url=repo_url,
            repo_ref=_env("SKILLS_REPO_REF", "main") or "main",
            repo_subdir=repo_subdir or None,
            local_cache_dir=Path(_env("SKILLS_LOCAL_CACHE_DIR", "/tmp/data-skills")),
            refresh_interval_seconds=_env_int("SKILLS_REFRESH_INTERVAL_SECONDS", 0),
            embedding_endpoint=(
                _env("SKILLS_EMBEDDING_ENDPOINT", "databricks-gte-large-en")
                or "databricks-gte-large-en"
            ),
            vector_search_index=_env("SKILLS_VECTOR_SEARCH_INDEX"),
            admin_token=_env("SKILLS_ADMIN_TOKEN"),
            databricks_host=_env("DATABRICKS_HOST"),
            is_databricks_app=is_app,
            skills_min_score=skills_min_score,
            skills_cutoff_buffer=skills_cutoff_buffer,
            skills_cutoff_search_window=skills_cutoff_search_window,
            skills_sub_pass_enabled=skills_sub_pass_enabled,
            skills_sub_k_default=skills_sub_k_default,
            skills_sub_min_score=skills_sub_min_score,
            log_level=_env("LOG_LEVEL", "INFO") or "INFO",
        )
