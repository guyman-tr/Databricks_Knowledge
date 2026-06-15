"""MCP tools exposed by the Skills MCP.

Three tools, each thin: the heavy lifting (loading, embedding, ACL filtering)
lives in dedicated modules so the tool functions stay readable and the seams
are easy to test.

These tools are *advisory only* Γאפ they return metadata. They never execute SQL.
The Gateway's SYSTEM_HINT routes the LLM to call ``databricks_sql_*`` next.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

from .acl import filter_by_acl, filter_by_acl_with_subs
from .embedder import Embedder
from .index import SkillIndex, SubSearchHit
from .schema import Skill, SkillSummary, SubSkill

logger = logging.getLogger(__name__)

# ``find_skills`` retrieval bounds. ``k`` is clamped to ``[_MIN_K, _MAX_K]``
# before any slicing so that:
#   - ``k <= 0`` can't trigger Python's negative-slice semantics
#     (``visible[:-1]`` returns "all but the last 1" Γאפ the opposite of
#     what a top-K retriever should do, and a real footgun for callers
#     that compute ``k`` from arithmetic).
#   - ``k`` very large can't blow up the response payload. With
#     SKILL.md bodies running ~5Γאף10 KB each, an unbounded ``k`` is a
#     soft DoS vector against the LLM context window and the MCP
#     transport. 25 is generous: 5├ק the default, well above the
#     useful recall cliff of vector retrieval (~10), and still bounds
#     a worst-case response to a few hundred KB.
_MIN_K = 1
_MAX_K = 25

# Sub-skill (hub-and-spoke) per-call bounds. ``sub_k`` caps how many
# matched children attach to each returned hub. Same anti-footgun
# clamping discipline as ``_MAX_K`` above Γאפ values outside this range
# are corrected and a warning is logged. 0 is explicitly allowed as
# "skip the second pass for this call" so a stricter client can opt
# out per-request while the master switch stays on.
_MIN_SUB_K = 0
_MAX_SUB_K = 3


@dataclass(frozen=True)
class CutoffPolicy:
    """Knobs for the adaptive cutoff + labelling floor.

    Three settings, grouped because they are always varied together at
    deployment time. Defaults are the Adaptive-K paper's published
    values (B=5 buffer past the knee; gap search restricted to the top
    90% of the sorted list to avoid knees in the irrelevant tail Γאפ
    arXiv:2506.08479 ┬º3.3) plus a *disabled* labelling floor.

    ``min_score = 0.0`` means "labelling off": the gap cut still runs,
    but every per-skill / per-call hint is ``"unknown"`` instead of
    ``"above_floor"`` / ``"below_floor"``. Production deployments set a
    real floor in ``app.yaml`` after observing the audit log's
    ``skills_top_score`` distribution.
    """

    min_score: float = 0.0
    buffer: int = 5
    search_window: float = 0.9


@dataclass(frozen=True)
class SubPassPolicy:
    """Knobs for the v1 sub-skill (hub-and-spoke) second pass.

    Grouped because flipping the master switch (``enabled``) without
    also setting ``k_default`` and ``min_score`` to deployment-appropriate
    values would either produce empty children for every call (k=0 by
    accident) or surface uncalibrated below-floor matches as if they
    were strong hits.

    ``enabled = False`` is the production default. With the switch off
    the second pass is fully short-circuited:

    * The loader silently drops ``sub_skills:`` declarations (Phase 1
      contract).
    * The index never receives ``child_vectors_by_hub`` (Phase 2
      contract).
    * ``find_skills`` returns the pre-v1 response shape byte-for-byte
      (this module's Phase 3 contract).

    Flipping ``enabled`` to ``True`` is the only operator action
    required to activate the second pass once corpus authoring has
    landed; no code change, no schema migration.

    ``k_default`` is the per-call ``sub_k`` ceiling when the caller
    doesn't pass one explicitly. Clamped to ``[_MIN_SUB_K, _MAX_SUB_K]``
    on every call so an out-of-range setting can't slip through.

    ``min_score`` is the labelling floor for matched children Γאפ same
    "label, don't drop" semantics as :attr:`CutoffPolicy.min_score`. A
    child below the floor still appears in the response, tagged with
    ``match_quality_hint = "below_floor"``, so the LLM gets a visible
    "this child is weak" signal rather than an opaque empty list.
    """

    enabled: bool = False
    k_default: int = 1
    min_score: float = 0.0


def register_tools(
    mcp_server,
    *,
    skill_index: SkillIndex,
    embedder: Embedder,
    acl_filter=filter_by_acl,
    acl_filter_with_subs=filter_by_acl_with_subs,
    cutoff_policy: CutoffPolicy | None = None,
    sub_pass_policy: SubPassPolicy | None = None,
) -> None:
    """Attach all three tools to ``mcp_server``.

    ``acl_filter`` / ``acl_filter_with_subs`` are injected so tests can
    replace ACL behaviour without monkey-patching module globals. The
    two are kept separate so the off-path can use the unchanged
    pre-v1 hub-only filter and the on-path can use the union variant
    Γאפ there's no "smart dispatch" inside :func:`find_skills`.

    ``cutoff_policy`` controls the Adaptive-K gap cutoff and labelling
    floor. ``None`` -> use the safe defaults (paper's B=5 / top-90%
    window, no labelling floor). Production wiring threads the values
    from ``Settings``; tests typically leave it at ``None`` so the
    pre-existing call sites stay unchanged.

    ``sub_pass_policy`` controls the v1 sub-skill second pass. ``None``
    -> safe defaults (master switch off; the rest is irrelevant when
    off). When ``enabled=False``, :func:`find_skills` returns the same
    payload shape as before Γאפ the new keys (``matched_sub_skills``,
    ``effective_score``, ``sub_skill_top_score``) are deliberately
    absent so off-path callers see no observable change.
    """

    policy = cutoff_policy or CutoffPolicy()
    sub_policy = sub_pass_policy or SubPassPolicy()

    @mcp_server.tool
    def find_skills(
        question: str,
        k: int = 5,
        domain_tag: str | None = None,
        sub_k: int | None = None,
    ) -> dict:
        """Find the top-K skills for a natural-language eToro business question.

        USE FIRST when the user asks a business question about eToro data
        (metrics, KPIs, trends, accounts, deposits, fees, GLA, GMV, regions,
        instruments). Adapt the returned `body_markdown` / `example_sql` to
        the user's question, then run via `databricks_sql_execute_sql`.

        SKIP for raw SQL execution, schema browsing (SHOW/DESCRIBE/EXPLAIN),
        Unity Catalog navigation, or SQL syntax help Γאפ call `databricks_sql_*`
        directly in those cases.

        Returns *advisory* metadata only Γאפ never executes SQL, never returns rows.

        Args:
            question: A natural-language question, e.g. "what is our open
                pipeline by region this quarter?".
            k: Maximum number of skills to return (default 5). Clamped to
                ``[1, 25]`` Γאפ values outside that range are corrected and
                a warning is logged. Non-positive values would otherwise
                trigger negative-slice semantics ("all but the last N");
                very large values would let a caller request the whole
                corpus and stuff the LLM context window.
            domain_tag: Optional pre-filter by domain tag (e.g. "sales").
            sub_k: Maximum number of matched child topics (sub-skills) to
                attach to each returned hub. Defaults to the deployment's
                ``SKILLS_SUB_K_DEFAULT`` (1). Clamped to ``[0, 3]``.
                ``sub_k = 0`` is the per-call escape hatch: the second
                pass is skipped entirely for this request even when the
                master switch is on. Has no effect when
                ``SKILLS_SUB_PASS_ENABLED`` is ``false`` (the response
                shape is the pre-v1 payload regardless of ``sub_k``).

        Returns:
            A dict with keys:

            - ``skills``: list of skills the calling user can query.
              Each entry includes (when set on the skill): ``id``,
              ``name``, ``description``, ``score`` (cosine similarity),
              ``match_quality_hint`` (per-skill verdict; see below),
              ``unity_catalog_assets``, ``triggers``, ``domain_tags``,
              ``column_notes``, ``join_hints``, ``common_filters``,
              ``example_sql``, ``body_markdown``, ``last_validated_at``,
              ``owner``, ``version``. ``body_markdown`` carries the full
              business glossary for SKILL.md-format skills (revenue
              definitions, segment hierarchies, etc.) and is the primary
              grounding source when present.
            - ``filtered_count``: how many skills were filtered out by ACL.
            - ``top_score``: raw best cosine similarity among ACL'd
              candidates *before* the gap cut and floor split, or
              ``None`` if no candidates were returned. Even when every
              survivor is below the calibrated floor, this carries the
              raw best so operators can recalibrate from the audit log.
            - ``match_quality_hint``: per-call verdict Γאפ one of
              ``"above_floor"`` (at least one survivor clears the
              ``SKILLS_MIN_SCORE`` floor), ``"below_floor"`` (everything
              we returned is below floor Γאפ surfaced as fallback
              context), ``"unknown"`` (no floor configured for this
              deployment), or ``"none"`` (empty result).
            - ``all_below_floor``: derived boolean Γאפ ``True`` exactly
              when the floor is configured *and* every returned skill
              has ``score < SKILLS_MIN_SCORE``. Exists so LLM clients
              can branch on it without parsing the hint enum string.
            - ``advisory``: a dynamic one-line advisory keyed by the
              per-call ``match_quality_hint``. Always reminds the LLM
              that this MCP does not execute SQL.
        """
        none_advisory = _ADVISORY_BY_HINT["none"]
        if not question or not question.strip():
            return _empty_response(none_advisory)

        clamped_k = max(_MIN_K, min(_MAX_K, k))
        if clamped_k != k:
            logger.warning(
                "find_skills: k=%r out of bounds [%d, %d]; clamped to %d",
                k, _MIN_K, _MAX_K, clamped_k,
            )
            k = clamped_k

        corpus = skill_index.snapshot()
        candidates = (
            [s for s in corpus if domain_tag in s.domain_tags]
            if domain_tag
            else corpus
        )

        if not candidates:
            return _empty_response(none_advisory)

        # Choose how widely to search before ACL + tag filtering. Two
        # different recall traps to dodge:
        #
        # 1. ACL drop: ``k=5`` might shrink to 1 after the user's UC
        #    permissions are applied, so we ask FAISS for several times
        #    ``k`` upfront and trim later.
        # 2. Tag drop: when ``domain_tag`` is set, the FAISS index still
        #    ranks across the *full* corpus Γאפ it doesn't know about tags.
        #    If the tagged subset is sparse (e.g. 5 skills with the
        #    requested tag in a 100-skill corpus), the global top-``k*4``
        #    can easily contain zero tagged hits, and we'd return an
        #    empty result even though several tagged skills exist. The
        #    fix is to search broadly enough that all tagged candidates
        #    are *eligible* to surface, then post-filter them. With
        #    FAISS IndexFlatIP over Γיñ5k vectors a full scan is
        #    microseconds Γאפ cheaper than the embedding RTT we already
        #    paid for the query vector.
        if domain_tag:
            wide_k = len(corpus)
        else:
            wide_k = min(max(k * 4, k + 5), len(corpus))
        query_vec = embedder.embed_one(question)
        hits = skill_index.search(query_vec, wide_k)

        # Post-search tag filter: keep the relative ranking from FAISS
        # but drop hits outside the requested domain_tag.
        if domain_tag:
            allowed_ids = {s.id for s in candidates}
            hits = [h for h in hits if h.skill.id in allowed_ids]

        ranked_skills = [h.skill for h in hits]
        hub_scores = {h.skill.id: h.score for h in hits}

        # Resolve the per-call ``sub_k`` early Γאפ the result decides
        # which branch we take below. ``sub_k=None`` means "use the
        # deployment default"; the clamp pins it to [0, 3] so callers
        # can't request more children than the policy allows.
        if sub_k is None:
            sub_k = sub_policy.k_default
        clamped_sub_k = max(_MIN_SUB_K, min(_MAX_SUB_K, sub_k))
        if clamped_sub_k != sub_k:
            logger.warning(
                "find_skills: sub_k=%r out of bounds [%d, %d]; clamped to %d",
                sub_k, _MIN_SUB_K, _MAX_SUB_K, clamped_sub_k,
            )
            sub_k = clamped_sub_k

        # Branch: when the master switch is off OR ``sub_k=0`` for
        # this call, run the pre-v1 single-pass path with its exact
        # response shape preserved. The on-path is the union ACL +
        # second pass + effective-score additions.
        if not sub_policy.enabled or sub_k <= 0:
            return _build_hub_only_response(
                ranked_skills=ranked_skills,
                hub_scores=hub_scores,
                acl_filter=acl_filter,
                k=k,
                policy=policy,
                embedder=embedder,
            )

        # Second pass: for each candidate hub, fetch its top-``sub_k``
        # children via the per-hub numpy dot in ``search_subs_under``.
        # This is bounded: ``wide_k * sub_k`` numpy ops, each on a
        # Γיñ10-row matrix Γאפ measured in microseconds for the v1
        # corpus sizes.
        per_hub_subs: list[tuple[Skill, list[SubSearchHit]]] = []
        for hub in ranked_skills:
            sub_hits = skill_index.search_subs_under(hub.id, query_vec, sub_k)
            per_hub_subs.append((hub, sub_hits))

        # ACL union: each hub passes iff every asset in the union of
        # (hub.unity_catalog_assets Γט¬ matched-children's assets) is
        # visible to the caller. See ``filter_by_acl_with_subs`` for
        # the rationale on the strictness trade-off.
        items_for_acl = [
            (hub, [hit.sub_skill for hit in subs])
            for hub, subs in per_hub_subs
        ]
        acl_visible = acl_filter_with_subs(items_for_acl)
        filtered_count = len(per_hub_subs) - len(acl_visible)
        visible_hub_ids = {hub.id for hub, _ in acl_visible}

        # Re-pair the surviving hubs with their FULL SubSearchHit list
        # (the ACL helper only needed the SubSkill bodies, not the
        # scores). Order is preserved by ``filter_by_acl_with_subs``.
        ranked = [
            (hub, sub_hits)
            for hub, sub_hits in per_hub_subs
            if hub.id in visible_hub_ids
        ]

        # Apply the sub-skill labelling floor Γאפ same "label, don't
        # drop" semantics as the hub-level floor. Below-floor children
        # are kept in the response payload with
        # ``match_quality_hint = "below_floor"`` so the LLM gets the
        # visible weakness signal instead of an opaque empty list.

        # Compute effective score per hub: max(hub_score, best_child_score).
        # The hub bubbles up if any of its children matches strongly,
        # which is the "score parent by best child" rule from
        # small-to-big RAG. Raw hub_score and per-child scores both
        # stay in the payload so the LLM can disambiguate.
        scored_effective: list[tuple[Skill, float, list[SubSearchHit]]] = []
        sub_skill_top_score: float | None = None
        for hub, sub_hits in ranked:
            hub_score = hub_scores[hub.id]
            best_child = max((h.score for h in sub_hits), default=None)
            if best_child is not None:
                sub_skill_top_score = (
                    best_child if sub_skill_top_score is None
                    else max(sub_skill_top_score, best_child)
                )
            effective = max(hub_score, best_child) if best_child is not None else hub_score
            scored_effective.append((hub, effective, sub_hits))

        # Sort by effective_score descending so the gap-cut + floor
        # split operate on the right axis. FAISS ordering was by raw
        # hub_score; the second pass can reorder.
        scored_effective.sort(key=lambda t: t[1], reverse=True)

        top_score_raw: float | None = (
            hub_scores[scored_effective[0][0].id] if scored_effective else None
        )
        effective_top: float | None = (
            scored_effective[0][1] if scored_effective else None
        )

        # Reuse the existing gap-cut and floor-split helpers by
        # projecting to ``(skill, score)`` first, then re-attaching
        # children by hub_id afterwards. Keeps the labelling
        # behaviour identical to the off-path so audit baselines
        # don't shift.
        projected: list[tuple[Skill, float]] = [
            (hub, eff) for hub, eff, _ in scored_effective
        ]
        projected = _largest_gap_cut(
            projected,
            search_window=policy.search_window,
            buffer=policy.buffer,
        )

        floor = policy.min_score
        if floor > 0 and projected:
            above = [pair for pair in projected if pair[1] >= floor]
            if above:
                projected = above

        projected = projected[:k]
        kept_ids = {hub.id for hub, _ in projected}
        kept_eff: list[tuple[Skill, float, list[SubSearchHit]]] = [
            t for t in scored_effective if t[0].id in kept_ids
        ]
        # ``projected`` order is authoritative after the gap cut /
        # floor split, so re-impose it on ``kept_eff``.
        eff_by_id = {hub.id: (hub, eff, subs) for hub, eff, subs in kept_eff}
        kept_eff = [eff_by_id[hub.id] for hub, _ in projected]

        call_hint = _per_call_hint(projected, floor)
        all_below = bool(
            floor > 0 and projected and all(sc < floor for _, sc in projected)
        )

        skills_payload = []
        for hub, eff, sub_hits in kept_eff:
            d = _skill_to_dict(
                hub,
                score=hub_scores[hub.id],
                hint=_per_skill_hint(hub_scores[hub.id], floor),
            )
            d["effective_score"] = eff
            d["matched_sub_skills"] = [
                _sub_skill_to_dict(
                    hit.sub_skill,
                    score=hit.score,
                    hint=_per_skill_hint(hit.score, sub_policy.min_score),
                )
                for hit in sub_hits
            ]
            skills_payload.append(d)

        return {
            "skills": skills_payload,
            "filtered_count": filtered_count,
            "top_score": top_score_raw,
            "effective_top_score": effective_top,
            "sub_skill_top_score": sub_skill_top_score,
            "match_quality_hint": call_hint,
            "all_below_floor": all_below,
            "advisory": _ADVISORY_BY_HINT[call_hint],
            # OpenAI-shape usage block. The gateway audit middleware reads
            # this via ``usage.total_tokens`` to populate the audit table's
            # ``total_tokens`` column. ``0`` when the embedding was served
            # from cache or the endpoint did not report a usage block.
            "usage": {"total_tokens": embedder.last_usage_total_tokens},
        }

    @mcp_server.tool
    def list_skills(domain_tag: str | None = None) -> dict:
        """List every skill in the corpus (authoring / debug aid).

        Not ACL-filtered Γאפ this is a directory of *what skills exist*, not a
        statement about who can query what. Use ``find_skills`` for the
        ACL-filtered, ranked view.

        Args:
            domain_tag: Optional filter by domain tag.

        Returns:
            ``{"skills": [SkillSummary, ...], "count": int}``.
        """
        all_skills = skill_index.snapshot()
        if domain_tag:
            all_skills = [s for s in all_skills if domain_tag in s.domain_tags]
        summaries = [SkillSummary.from_skill(s).model_dump(mode="json") for s in all_skills]
        return {"skills": summaries, "count": len(summaries)}

    @mcp_server.tool
    def get_skill(id: str) -> dict:
        """Fetch one skill by id, including its full body / example SQL.

        Args:
            id: The skill or sub-skill slug (e.g.
                ``"sales-pipeline-by-region"``, ``"revenue-business-logic"``,
                or ``"mimo-panel-and-ddr"``). Hubs and sub-skills share
                one keyspace under the loader's union uniqueness check,
                so a single lookup can resolve either.

        Returns:
            A dict with the full skill record (including ``body_markdown``
            for SKILL.md-format skills and ``example_sql`` for YAML-format
            skills), or ``{"error": "not_found"}`` if no skill with that id
            exists. When the slug resolves to a sub-skill, the dict
            includes a ``parent_skill_id`` field naming the owning hub
            and a ``kind: "sub_skill"`` discriminator so the LLM (and
            the audit row) can tell the two cases apart.
        """
        skill = skill_index.get(id)
        if skill is not None:
            return _skill_to_dict(skill, score=None)

        # Fall through to the global sub-skill lookup. Only reachable
        # when sub-pass is on AND the loader actually attached
        # children Γאפ when off, ``index.get_sub_skill`` is empty by
        # construction and this returns ``not_found`` just like the
        # pre-v1 path.
        resolved = skill_index.get_sub_skill(id)
        if resolved is None:
            return {"error": "not_found", "id": id}
        hub_id, sub = resolved
        out = _sub_skill_to_dict(sub, score=None)
        out["kind"] = "sub_skill"
        out["parent_skill_id"] = hub_id
        return out


_ADVISORY_BY_HINT: dict[str, str] = {
    "above_floor": (
        "Top match clears the calibrated relevance floor. Ground the SQL in "
        "the skill's body_markdown / example_sql (do not invent schema), and "
        "sanity-check that unity_catalog_assets match the user's actual "
        "domain before grounding. This MCP does not execute SQL."
    ),
    "below_floor": (
        "No skill matched the calibrated relevance threshold. The returned "
        "candidates are below threshold and surfaced only as fallback "
        "context Γאפ they are unlikely to be a good match for the question. "
        "Tell the user that no matching skill was found; prefer asking them "
        "to clarify, narrow the question, or name a target table rather "
        "than grounding SQL in these results. This MCP does not execute SQL."
    ),
    "unknown": (
        "No calibrated relevance floor configured for this corpus + "
        "embedding endpoint. Results are gap-trimmed but their absolute "
        "relevance is uncertified Γאפ sanity-check description and "
        "unity_catalog_assets against the question. This MCP does not "
        "execute SQL."
    ),
    "none": (
        "No skills available (corpus empty or all candidates ACL-filtered). "
        "This MCP does not execute SQL."
    ),
}


def _empty_response(advisory: str) -> dict:
    """Canonical empty-result response, kept consistent across the early
    exits so clients see the same key set regardless of which branch
    bailed out. ``usage.total_tokens`` is always 0 here because every
    early-exit happens before any embedding call."""
    return {
        "skills": [],
        "filtered_count": 0,
        "top_score": None,
        "match_quality_hint": "none",
        "all_below_floor": False,
        "advisory": advisory,
        "usage": {"total_tokens": 0},
    }


def _largest_gap_cut(
    scored: list[tuple[Skill, float]],
    *,
    search_window: float,
    buffer: int,
) -> list[tuple[Skill, float]]:
    """Return the prefix of ``scored`` up to the largest score gap, plus
    ``buffer`` extra items.

    Adaptive-K cutoff per arXiv:2506.08479 ┬º3.3. ``scored`` is assumed
    sorted descending by score (FAISS returns hits this way and the
    ACL filter is order-preserving). The knee Γאפ the steepest drop in
    consecutive scores Γאפ is the natural cut between "relevant" and
    "noise" *for this query's distribution*, which is why this is
    encoder-agnostic.

    We search only within the top ``search_window`` fraction of the
    list. The paper finds that a gap deep in the irrelevant tail can
    accidentally win when the relevant cluster is small, dragging in
    most of the noise. ``buffer`` retrieves an additional ``B``
    documents past the knee to absorb relevant hits that fall just
    past the cliff.

    Returns a new list; never mutates ``scored``.
    """
    n = len(scored)
    if n <= 1:
        return list(scored)

    # Need at least 2 indices to form a gap; clamp to ``[2, n]``. With
    # search_window=0.9, n=10 gives window=9 (gaps[0..7]); with n=3
    # and the same window the rounding would give 3 and we'd compute
    # gaps[0..1] Γאפ the natural behaviour for small lists.
    window = max(2, min(n, int(round(n * search_window))))
    gaps = [scored[i][1] - scored[i + 1][1] for i in range(window - 1)]
    if not gaps:
        return list(scored)

    knee_idx = max(range(len(gaps)), key=gaps.__getitem__)
    keep_through = min(n, knee_idx + 1 + buffer)
    return list(scored[:keep_through])


def _per_skill_hint(score: float, min_score: float) -> str:
    """Per-skill heuristic verdict Γאפ what to call THIS skill in isolation.

    Three values: ``unknown`` (no floor configured for this deployment),
    ``above_floor``, ``below_floor``. We intentionally do not split
    above-floor into strong/plausible/weak Γאפ the raw ``score`` in the
    per-skill dict already lets the LLM make that judgement, and any
    headroom-based bands would be encoder-coupled magic numbers. Less
    magic, less to recalibrate, additive to extend later.
    """
    if min_score <= 0:
        return "unknown"
    return "above_floor" if score >= min_score else "below_floor"


def _per_call_hint(scored: list[tuple[Skill, float]], min_score: float) -> str:
    """Per-call verdict Γאפ keys ``_ADVISORY_BY_HINT``.

    Special case: if the floor is configured and EVERY survivor is
    below it, the call hint is ``below_floor`` regardless of which
    skill happens to be on top. That's the "no good match" branch the
    product decision is built around Γאפ the LLM gets told explicitly
    and the advisory directs it to ask for clarification.
    """
    if not scored:
        return "none"
    if min_score <= 0:
        return "unknown"
    if all(sc < min_score for _, sc in scored):
        return "below_floor"
    return "above_floor"


def _skill_to_dict(skill: Skill, *, score: float | None, hint: str | None = None) -> dict:
    out = skill.model_dump(mode="json")
    if score is not None:
        out["score"] = score
    if hint is not None:
        out["match_quality_hint"] = hint
    return out


def _sub_skill_to_dict(
    sub: SubSkill, *, score: float | None, hint: str | None = None
) -> dict:
    """Serialise a :class:`SubSkill` for the v1 response payload.

    Same envelope as :func:`_skill_to_dict` for the hub Γאפ same key
    names (``score``, ``match_quality_hint``) so the LLM doesn't have
    to learn two schemas. The hub-only fields (``version``, ``owner``,
    ``domain_tags``, ``last_validated_at``, ``genie_space_id``) are
    omitted because :class:`SubSkill` doesn't carry them; the LLM gets
    them from the parent hub.
    """
    out = sub.model_dump(mode="json")
    if score is not None:
        out["score"] = score
    if hint is not None:
        out["match_quality_hint"] = hint
    return out


def _build_hub_only_response(
    *,
    ranked_skills: list[Skill],
    hub_scores: dict[str, float],
    acl_filter,
    k: int,
    policy: CutoffPolicy,
    embedder,
) -> dict:
    """The pre-v1 ``find_skills`` body, extracted verbatim.

    Called when ``SKILLS_SUB_PASS_ENABLED`` is ``false`` OR the caller
    passes ``sub_k=0``. The off-path is byte-for-byte identical to
    what the tool returned before v1 Γאפ same key set, same ordering,
    same hint labels Γאפ so audit baselines, LLM prompt caches, and
    downstream automation stay untouched until ops flips the master
    switch.

    Kept as a free function (not a closure) so it's trivially unit-
    testable in isolation; the equivalent on-path lives in
    :func:`find_skills`'s body because it needs the per-call
    ``query_vec`` + ``sub_k`` arguments and the live ``skill_index``.
    """
    visible = acl_filter(ranked_skills)
    filtered_count = len(ranked_skills) - len(visible)

    scored: list[tuple[Skill, float]] = [(s, hub_scores[s.id]) for s in visible]

    top_score_raw: float | None = scored[0][1] if scored else None

    scored = _largest_gap_cut(
        scored,
        search_window=policy.search_window,
        buffer=policy.buffer,
    )

    floor = policy.min_score
    if floor > 0 and scored:
        above = [pair for pair in scored if pair[1] >= floor]
        if above:
            scored = above

    scored = scored[:k]

    call_hint = _per_call_hint(scored, floor)
    all_below = bool(floor > 0 and scored and all(sc < floor for _, sc in scored))

    return {
        "skills": [
            _skill_to_dict(s, score=sc, hint=_per_skill_hint(sc, floor))
            for s, sc in scored
        ],
        "filtered_count": filtered_count,
        "top_score": top_score_raw,
        "match_quality_hint": call_hint,
        "all_below_floor": all_below,
        "advisory": _ADVISORY_BY_HINT[call_hint],
        # OpenAI-shape usage block. Mirrors the on-path return so the
        # gateway audit middleware's ``usage.total_tokens`` extractor
        # works the same way regardless of which branch ran. ``0`` when
        # the embedding was served from cache or the endpoint did not
        # report a usage block.
        "usage": {"total_tokens": embedder.last_usage_total_tokens},
    }
