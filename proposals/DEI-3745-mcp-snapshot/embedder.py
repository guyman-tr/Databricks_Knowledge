"""Embedding client for the Databricks Foundation Model serving endpoint.

We hit the endpoint via the OpenAI-compatible interface
``{host}/serving-endpoints/{name}/invocations`` (works for any embedding
endpoint Databricks ships, including ``databricks-gte-large-en`` and
``databricks-bge-large-en``).

Auth uses the WorkspaceClient's existing config so the same code works in
three modes:

- Local dev (``WorkspaceClient()`` with ~/.databrickscfg).
- Databricks App service-principal (auto).
- Tests (mocked via dependency injection of ``client_factory``).

We L2-normalise vectors here so the FAISS index can use ``IndexFlatIP``
(cosine similarity = inner product on unit vectors).
"""

from __future__ import annotations

import logging
from collections.abc import Callable, Iterable
from typing import Any

import numpy as np
from cachetools import TTLCache
from databricks.sdk import WorkspaceClient

logger = logging.getLogger(__name__)


class EmbeddingError(RuntimeError):
    pass


class Embedder:
    """Thin wrapper around a Databricks FM endpoint.

    Args:
        endpoint_name: serving-endpoint name, e.g. ``"databricks-gte-large-en"``.
        client_factory: callable returning a :class:`WorkspaceClient`. Defaulted
            to ``WorkspaceClient`` for production; tests inject a stub.
        cache_size: number of (text -> vector) entries to cache.
        cache_ttl_seconds: TTL for the LRU cache. 60 s is enough to dedupe
            within a single user's chat without holding stale embeddings
            across deployments.
    """

    def __init__(
        self,
        endpoint_name: str,
        client_factory: Callable[[], WorkspaceClient] = WorkspaceClient,
        cache_size: int = 4096,
        cache_ttl_seconds: int = 60,
    ) -> None:
        self.endpoint_name = endpoint_name
        self._client_factory = client_factory
        self._cache: TTLCache[str, np.ndarray] = TTLCache(
            maxsize=cache_size, ttl=cache_ttl_seconds
        )
        # Tokens consumed by serving-endpoint calls during the most recent
        # ``embed()`` invocation. 0 when the call was fully served from cache
        # or the endpoint didn't report usage. Read by ``tools.find_skills``
        # to populate the audit ``usage.total_tokens`` column.
        self.last_usage_total_tokens: int = 0

    def embed(self, texts: Iterable[str]) -> np.ndarray:
        """Embed an iterable of strings; returns an (N, D) float32 ndarray.

        Vectors are L2-normalised so they can be compared with inner-product.
        """
        self.last_usage_total_tokens = 0
        text_list = [t for t in texts]
        if not text_list:
            return np.zeros((0, 0), dtype=np.float32)

        cached: dict[int, np.ndarray] = {}
        to_embed: list[tuple[int, str]] = []
        for i, t in enumerate(text_list):
            v = self._cache.get(t)
            if v is not None:
                cached[i] = v
            else:
                to_embed.append((i, t))

        new_vectors: dict[int, np.ndarray] = {}
        if to_embed:
            vectors, usage_tokens = self._call_endpoint([t for _, t in to_embed])
            self.last_usage_total_tokens += usage_tokens
            for (i, t), vec in zip(to_embed, vectors, strict=True):
                v = _normalise(vec)
                self._cache[t] = v
                new_vectors[i] = v

        merged = {**cached, **new_vectors}
        ordered = [merged[i] for i in range(len(text_list))]
        return np.stack(ordered).astype(np.float32, copy=False)

    def embed_one(self, text: str) -> np.ndarray:
        return self.embed([text])[0]

    def _call_endpoint(self, texts: list[str]) -> tuple[list[list[float]], int]:
        """Call the FM endpoint via the WorkspaceClient.

        We use ``serving_endpoints.query`` which speaks both the OpenAI-style
        and the legacy MLflow-style payloads. Recent SDKs accept ``input``
        for embeddings; we wrap it minimally and unpack the response in the
        format the OpenAI-compatible serving endpoints emit.

        Returns ``(vectors, usage_total_tokens)``. ``usage_total_tokens`` is
        ``0`` when the endpoint did not report a ``usage`` block (e.g. the
        legacy MLflow-style ``{"predictions": [...]}`` shape).
        """
        client = self._client_factory()
        try:
            response = client.serving_endpoints.query(  # type: ignore[attr-defined]
                name=self.endpoint_name,
                input=texts,
            )
        except Exception as e:  # noqa: BLE001 Γאפ surface upstream error verbatim
            raise EmbeddingError(
                f"embedding call to {self.endpoint_name} failed: {e}"
            ) from e

        return _extract_payload(response, expected_count=len(texts))


def _extract_payload(response: Any, expected_count: int) -> tuple[list[list[float]], int]:
    """Tolerate the few shapes the Databricks SDK returns for embeddings.

    Returns ``(vectors, usage_total_tokens)``. The OpenAI-style payload
    includes a ``usage`` block with ``total_tokens``; we surface that for
    cost attribution. Legacy MLflow shapes have no usage and report ``0``.
    """
    payload: Any = response
    # SDK objects expose ``as_dict`` (preferred) or ``__dict__``.
    if hasattr(payload, "as_dict"):
        payload = payload.as_dict()
    if hasattr(payload, "__dict__") and not isinstance(payload, dict):
        payload = payload.__dict__

    if isinstance(payload, dict):
        usage_tokens = _usage_total_tokens(payload.get("usage"))
        # OpenAI style: {"data": [{"index": 0, "embedding": [...]}, ...]}
        if "data" in payload and isinstance(payload["data"], list):
            data = payload["data"]
            data_sorted = sorted(data, key=lambda e: e.get("index", 0))
            vecs = [e["embedding"] for e in data_sorted]
            if len(vecs) != expected_count:
                raise EmbeddingError(
                    f"endpoint returned {len(vecs)} embeddings for "
                    f"{expected_count} inputs"
                )
            return vecs, usage_tokens
        # MLflow legacy: {"predictions": [[...], [...]]}
        if "predictions" in payload and isinstance(payload["predictions"], list):
            return payload["predictions"], usage_tokens

    raise EmbeddingError(
        f"could not interpret embedding response shape {type(response).__name__}: "
        f"keys={list(payload.keys()) if isinstance(payload, dict) else 'n/a'}"
    )


def _usage_total_tokens(usage: Any) -> int:
    """Best-effort int extraction of ``usage.total_tokens``. Defaults to 0.

    Defensive on shape: missing key, non-dict, non-numeric, or coercion
    failure all map to 0 rather than raising Γאפ usage telemetry must
    never break an embed call.
    """
    if not isinstance(usage, dict):
        return 0
    value = usage.get("total_tokens")
    try:
        return int(value) if value is not None else 0
    except (TypeError, ValueError):
        return 0


def _normalise(vec: list[float] | np.ndarray) -> np.ndarray:
    arr = np.asarray(vec, dtype=np.float32)
    norm = float(np.linalg.norm(arr))
    if norm == 0.0:
        return arr
    return arr / norm
