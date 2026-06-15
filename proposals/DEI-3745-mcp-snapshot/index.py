"""In-memory FAISS index over the skill corpus.

MVP backend. The plan calls for a Databricks Vector Search direct-access index
in v1+; this module is the seam that makes that swap a drop-in replacement Γאפ
the public API is just ``build``, ``search``, and ``snapshot`` and the rest of
the server only ever talks to this interface.

Why FAISS ``IndexFlatIP``: with embeddings L2-normalised in
:mod:`server.embedder`, inner-product is equivalent to cosine similarity, and
``IndexFlatIP`` is exact (no recall loss) and has zero training step. For
``Γיñ 5_000`` skills the linear scan completes in well under 10 ms on a
Databricks App's default sizing Γאפ *much* faster than the network round-trip
to the FM endpoint that fetched the query embedding.

Hub-and-spoke (v1): :class:`SubSkill` vectors are stored **per-hub** as
small ``np.ndarray`` matrices, not in the FAISS index. The reasoning:

* The second-pass score is computed only for the handful of hubs the
  first pass already returned, so the total candidate-set size is
  typically ``returned_hubs * children_per_hub`` Γיט 5 * 5 = 25. A numpy
  inner product on a 25xD matrix is faster than re-opening FAISS for
  a filtered query.
* Keeping the FAISS index single-vector-per-skill preserves the
  off-path semantics byte-for-byte Γאפ when ``SKILLS_SUB_PASS_ENABLED``
  is ``False`` the loader doesn't even attach children, so this whole
  per-hub matrix stays empty and ``search_subs_under`` returns ``[]``
  for every call. The kill switch is genuinely zero-cost on the
  rollback path.
"""

from __future__ import annotations

import logging
import threading
from dataclasses import dataclass

import faiss
import numpy as np

from .schema import Skill, SubSkill

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SearchHit:
    skill: Skill
    score: float


@dataclass(frozen=True)
class SubSearchHit:
    """A sub-skill matched by :meth:`SkillIndex.search_subs_under`.

    Carries the parent hub's id so :mod:`server.tools` doesn't have to
    re-derive it (a sub-skill's ``id`` alone is globally unique but the
    hub context is what callers actually need for ACL union and audit
    fields).
    """

    hub_id: str
    sub_skill: SubSkill
    score: float


class SkillIndex:
    """Vector + metadata store over the loaded skill corpus.

    Thread-safe via a single RWLock on the underlying FAISS index, swapped
    atomically on rebuild. ``build`` is idempotent; calling it during a
    ``search`` does not corrupt in-flight queries because we never mutate the
    existing index Γאפ we replace the reference.
    """

    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._index: faiss.Index | None = None
        self._skills: list[Skill] = []
        self._dim: int | None = None
        # Per-hub child caches. Empty when sub-pass is off; populated
        # by ``build`` when the caller passes ``child_vectors_by_hub``.
        # The two dicts are kept in lock-step: each hub-id key in
        # ``_child_vectors_by_hub`` has a parallel ordered list of
        # :class:`SubSkill`s in ``_sub_skills_by_hub`` (matrix row N
        # corresponds to sub-skill N in the list).
        self._child_vectors_by_hub: dict[str, np.ndarray] = {}
        self._sub_skills_by_hub: dict[str, list[SubSkill]] = {}
        # Global ``sub_skill_id -> (hub_id, SubSkill)`` lookup table
        # used by :meth:`get_sub_skill` to resolve ``get_skill`` calls
        # that hit a child slug. Built atomically with everything else.
        self._sub_skill_lookup: dict[str, tuple[str, SubSkill]] = {}

    def build(
        self,
        skills: list[Skill],
        vectors: np.ndarray,
        *,
        child_vectors_by_hub: dict[str, np.ndarray] | None = None,
    ) -> None:
        """Atomically rebuild the index.

        Args:
            skills: hub skills, parallel to ``vectors`` row order.
            vectors: ``(n_skills, dim)`` matrix of hub embeddings. Must
                already be L2-normalised; FAISS' inner-product index is
                equivalent to cosine similarity under that constraint.
            child_vectors_by_hub: optional, ``hub_id -> (n_children,
                dim)`` matrix. When provided, the order of each
                matrix's rows must match the order of ``skill.sub_skills``
                for the corresponding hub. When None or omitted, the
                index drops to single-vector-per-hub behaviour
                (matching the pre-v1 path byte-for-byte) and
                :meth:`search_subs_under` returns ``[]`` for every
                call Γאפ this is the kill-switch-off contract.
        """
        if vectors.ndim != 2 or vectors.shape[0] != len(skills):
            raise ValueError(
                f"vectors shape {vectors.shape} does not match {len(skills)} skills"
            )
        if vectors.dtype != np.float32:
            vectors = vectors.astype(np.float32, copy=False)

        new_index = faiss.IndexFlatIP(vectors.shape[1])
        if vectors.shape[0] > 0:
            new_index.add(vectors)

        # Build the child caches off-lock; only the atomic swap below
        # needs the lock held. Validate shapes here so a misconfigured
        # rebuild fails fast and the old index keeps serving traffic.
        new_child_vectors: dict[str, np.ndarray] = {}
        new_sub_skills: dict[str, list[SubSkill]] = {}
        new_sub_lookup: dict[str, tuple[str, SubSkill]] = {}

        if child_vectors_by_hub:
            skills_by_id = {s.id: s for s in skills}
            for hub_id, matrix in child_vectors_by_hub.items():
                hub = skills_by_id.get(hub_id)
                if hub is None:
                    raise ValueError(
                        f"child_vectors_by_hub references unknown hub "
                        f"{hub_id!r}; not found in supplied skills"
                    )
                if not hub.sub_skills:
                    # Defensive: caller passed vectors for a hub with no
                    # sub-skills attached. That's a bookkeeping bug Γאפ
                    # fail rather than silently drop the matrix.
                    raise ValueError(
                        f"child_vectors_by_hub[{hub_id!r}] supplied but "
                        f"hub has no sub_skills attached"
                    )
                if matrix.ndim != 2 or matrix.shape[0] != len(hub.sub_skills):
                    raise ValueError(
                        f"child_vectors_by_hub[{hub_id!r}] shape {matrix.shape} "
                        f"does not match {len(hub.sub_skills)} sub-skills"
                    )
                if matrix.shape[1] != vectors.shape[1]:
                    raise ValueError(
                        f"child_vectors_by_hub[{hub_id!r}] dim {matrix.shape[1]} "
                        f"does not match hub vector dim {vectors.shape[1]}"
                    )
                if matrix.dtype != np.float32:
                    matrix = matrix.astype(np.float32, copy=False)
                new_child_vectors[hub_id] = matrix
                new_sub_skills[hub_id] = list(hub.sub_skills)
                for sub in hub.sub_skills:
                    if sub.id in new_sub_lookup:
                        # Loader-level uniqueness already enforced this,
                        # but defence-in-depth is cheap and a duplicate
                        # here would make ``get_sub_skill`` ambiguous.
                        existing_hub, _ = new_sub_lookup[sub.id]
                        raise ValueError(
                            f"sub-skill id {sub.id!r} appears under both "
                            f"hub {existing_hub!r} and hub {hub_id!r}"
                        )
                    new_sub_lookup[sub.id] = (hub_id, sub)

        with self._lock:
            self._index = new_index
            self._skills = list(skills)
            self._dim = vectors.shape[1] if vectors.shape[0] else None
            self._child_vectors_by_hub = new_child_vectors
            self._sub_skills_by_hub = new_sub_skills
            self._sub_skill_lookup = new_sub_lookup

        logger.info(
            "rebuilt skill index: %d hubs, %d hubs-with-children, %d sub-skills total, dim=%s",
            len(skills),
            len(new_child_vectors),
            sum(len(v) for v in new_sub_skills.values()),
            self._dim,
        )

    def search(self, query_vector: np.ndarray, k: int) -> list[SearchHit]:
        with self._lock:
            index = self._index
            skills = self._skills

        if index is None or not skills:
            return []

        if query_vector.dtype != np.float32:
            query_vector = query_vector.astype(np.float32, copy=False)
        if query_vector.ndim == 1:
            query_vector = query_vector.reshape(1, -1)

        k = min(k, len(skills))
        scores, idx = index.search(query_vector, k)
        hits: list[SearchHit] = []
        for score, i in zip(scores[0].tolist(), idx[0].tolist(), strict=True):
            if i < 0 or i >= len(skills):
                continue
            hits.append(SearchHit(skill=skills[i], score=float(score)))
        return hits

    def search_subs_under(
        self,
        hub_id: str,
        query_vector: np.ndarray,
        k: int,
    ) -> list[SubSearchHit]:
        """Score the children of one hub against a query, return top-k.

        Implemented as a single numpy inner product against the
        per-hub matrix Γאפ no FAISS round-trip, no second embedding
        call. Designed to be called from :func:`server.tools.find_skills`
        once per returned hub in the first pass.

        Returns an empty list when:

        * ``hub_id`` has no child cache (sub-pass off, or this hub
          declares no ``sub_skills``).
        * ``k`` is ``0`` or non-positive (caller asked us to skip).

        The output is sorted by descending cosine similarity.
        """
        if k <= 0:
            return []
        with self._lock:
            matrix = self._child_vectors_by_hub.get(hub_id)
            subs = self._sub_skills_by_hub.get(hub_id)

        if matrix is None or not subs:
            return []

        if query_vector.dtype != np.float32:
            query_vector = query_vector.astype(np.float32, copy=False)
        if query_vector.ndim == 2:
            # Caller passed a (1, dim) row Γאפ flatten so the dot product
            # below produces a 1-D score vector.
            query_vector = query_vector[0]

        # Inner product against the L2-normalised matrix is cosine
        # similarity. For typical hubs (Γיñ10 children) this is
        # measured in microseconds and dominated by Python overhead.
        scores = matrix @ query_vector  # shape: (n_children,)
        n = scores.shape[0]
        k = min(k, n)
        # Partial sort then full sort of the top-k slice; faster than
        # full argsort when ``n`` grows but children-per-hub stays small.
        if k < n:
            top_idx = np.argpartition(-scores, k - 1)[:k]
            top_idx = top_idx[np.argsort(-scores[top_idx])]
        else:
            top_idx = np.argsort(-scores)

        return [
            SubSearchHit(
                hub_id=hub_id,
                sub_skill=subs[int(i)],
                score=float(scores[int(i)]),
            )
            for i in top_idx
        ]

    def get_sub_skill(self, sub_skill_id: str) -> tuple[str, SubSkill] | None:
        """Resolve a child slug to its ``(hub_id, SubSkill)``.

        Used by :func:`server.tools.get_skill` when the caller asks
        for a slug that isn't a hub Γאפ child slugs share the hub
        keyspace (the loader enforces union-uniqueness), so a single
        ``get_skill`` call can return either a hub or a child.
        """
        with self._lock:
            return self._sub_skill_lookup.get(sub_skill_id)

    def snapshot(self) -> list[Skill]:
        """Return a stable copy of the current skill list (for ``list_skills``)."""
        with self._lock:
            return list(self._skills)

    def get(self, skill_id: str) -> Skill | None:
        with self._lock:
            for s in self._skills:
                if s.id == skill_id:
                    return s
        return None

    @property
    def size(self) -> int:
        with self._lock:
            return len(self._skills)
