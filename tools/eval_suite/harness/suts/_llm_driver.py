"""Pluggable LLM driver for the direct-MCP SUT.

The DirectMcpSUT needs ONE LLM operation: "given a grounded prompt
(user question + skill body_markdown + example_sql), return SQL adapted
to the question." That's it. No agent loop, no tool calling — just a
single completion against a chat endpoint.

Two backends supported. Both expose the same `complete(messages, ...)`
interface so the SUT doesn't care which one is wired up.

  1. CURSOR API
     - Endpoint: https://api.cursor.com/v0/chat/completions (OpenAI-compatible)
     - Auth: `Bearer ${CURSOR_API_KEY}`
     - Models: same slugs the cursor-agent CLI accepts ("sonnet-4-5", "gpt-5", ...)
     - Use for local development on Windows where Databricks OAuth is flaky.

  2. DATABRICKS FOUNDATION MODEL
     - Endpoint: <workspace>/serving-endpoints/<endpoint_name>/invocations
     - Auth: Databricks SDK credentials (PAT or OAuth profile)
     - Models: typically "databricks-claude-sonnet-4", "databricks-meta-llama-3-1-70b-instruct"
     - Use when running INSIDE a Databricks notebook (auth is automatic) or
       when local OAuth is fresh.

Selection: by default we try Cursor (since it has a stable API key in the
environment) and let the user override with `LLMDriverConfig`. The harness
CLI exposes a `--llm-backend` flag.
"""
from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass, field
from typing import Any, Literal

import urllib.request
import urllib.error


class LLMError(RuntimeError):
    """Anything that goes wrong with an LLM completion."""


@dataclass
class LLMResponse:
    """One completion response, with provenance for telemetry.

    `tool_calls` carries OpenAI-format tool calls if the model invoked any.
    Each item is a dict ``{id, type, function: {name, arguments}}`` where
    ``arguments`` is a JSON-encoded string. The caller is responsible for
    parsing the arguments (we keep it as a string to preserve the model's
    exact output for telemetry).

    `finish_reason` lets the caller distinguish "model wants to call tools"
    (`"tool_calls"`) from "model is done" (`"stop"`).
    """
    text: str
    model: str
    backend: str
    elapsed_ms: int
    input_tokens: int | None = None
    output_tokens: int | None = None
    raw: dict | None = None
    tool_calls: list[dict] | None = None
    finish_reason: str | None = None


# ---------------------------------------------------------------------------
# Base interface
# ---------------------------------------------------------------------------

class LLMDriver:
    """Abstract base. One method: complete().

    `tools` and `tool_choice` follow the OpenAI schema. When provided, the
    model may return ``tool_calls`` instead of (or in addition to) text.
    Drivers that don't support tools should silently ignore the args and
    document that limitation.
    """
    backend_name: str = "abstract"
    default_model: str = ""

    def complete(
        self,
        messages: list[dict],
        *,
        model: str | None = None,
        max_tokens: int = 2048,
        temperature: float = 0.0,
        timeout_s: float = 60.0,
        tools: list[dict] | None = None,
        tool_choice: str | dict | None = None,
    ) -> LLMResponse:
        raise NotImplementedError


# ---------------------------------------------------------------------------
# Cursor API driver  (default for local dev)
# ---------------------------------------------------------------------------

class CursorLLMDriver(LLMDriver):
    """Cursor's OpenAI-compatible chat-completions endpoint.

    Endpoint reference: https://docs.cursor.com/api/chat-completions
    Auth: Bearer token in CURSOR_API_KEY env var (or constructor arg).

    Why this is a good fit:
      - User already pays for Cursor; no extra LLM bill.
      - Same model surface as cursor-agent CLI (`sonnet-4-5`, `gpt-5`, etc.) —
        keeps the eval comparable across Cursor IDE / CLI / direct-MCP SUT.
      - Stable HTTPS endpoint; no OAuth dance, no expiring refresh tokens.
    """
    backend_name = "cursor"
    default_model = "sonnet-4-5"
    BASE_URL = "https://api.cursor.com/v0/chat/completions"

    def __init__(self, *, api_key: str | None = None) -> None:
        self.api_key = api_key or os.environ.get("CURSOR_API_KEY")
        if not self.api_key:
            raise LLMError(
                "CursorLLMDriver requires an API key. Set CURSOR_API_KEY in "
                "the environment or pass api_key= to the constructor."
            )

    def complete(
        self,
        messages: list[dict],
        *,
        model: str | None = None,
        max_tokens: int = 2048,
        temperature: float = 0.0,
        timeout_s: float = 60.0,
        tools: list[dict] | None = None,
        tool_choice: str | dict | None = None,
    ) -> LLMResponse:
        body = {
            "model": model or self.default_model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if tools is not None:
            body["tools"] = tools
        if tool_choice is not None:
            body["tool_choice"] = tool_choice
        data = json.dumps(body).encode("utf-8")
        req = urllib.request.Request(
            self.BASE_URL,
            data=data,
            method="POST",
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
        )
        t0 = time.monotonic()
        try:
            with urllib.request.urlopen(req, timeout=timeout_s) as resp:
                body_text = resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            err_body = ""
            try:
                err_body = e.read().decode("utf-8", errors="replace")
            except Exception:  # noqa: BLE001
                pass
            raise LLMError(
                f"Cursor API HTTP {e.code}: {e.reason}\nBody: {err_body[:500]}"
            ) from e
        except urllib.error.URLError as e:
            raise LLMError(f"Cursor API network error: {e.reason}") from e

        elapsed_ms = int((time.monotonic() - t0) * 1000)
        try:
            payload = json.loads(body_text)
        except json.JSONDecodeError as e:
            raise LLMError(
                f"Cursor API returned non-JSON body: {body_text[:500]}"
            ) from e

        choices = payload.get("choices") or []
        if not choices:
            raise LLMError(f"Cursor API returned no choices: {payload}")
        first = choices[0]
        msg = first.get("message") or {}
        text = msg.get("content") or ""
        usage = payload.get("usage") or {}
        return LLMResponse(
            text=text,
            model=payload.get("model") or body["model"],
            backend=self.backend_name,
            elapsed_ms=elapsed_ms,
            input_tokens=usage.get("prompt_tokens"),
            output_tokens=usage.get("completion_tokens"),
            raw=payload,
            tool_calls=msg.get("tool_calls") or None,
            finish_reason=first.get("finish_reason"),
        )


# ---------------------------------------------------------------------------
# Databricks foundation model driver  (notebook / production)
# ---------------------------------------------------------------------------

class DatabricksLLMDriver(LLMDriver):
    """Databricks serving-endpoint chat-completions API.

    Spec: <host>/serving-endpoints/<endpoint>/invocations
    The Databricks Foundation-Model endpoints accept OpenAI-style
    `messages` payloads (see databricks-ai-bridge / databricks-genai docs).

    Auth: uses the Databricks SDK's credential resolution (env vars,
    `~/.databrickscfg`, OAuth, PAT). When run inside a Databricks notebook
    the runtime injects a token automatically.
    """
    backend_name = "databricks"
    # Smoke-verified 2026-06-14 on workspace adb-5142916747090026 (profile=guyman):
    # responds to OpenAI-style chat-completions in <2s. Override per-call via
    # the constructor's ``endpoint_name`` if you want a different model.
    default_model = "databricks-claude-sonnet-4-6"

    def __init__(
        self,
        *,
        endpoint_name: str | None = None,
        profile: str = "guyman",
    ) -> None:
        try:
            from databricks.sdk import WorkspaceClient  # type: ignore
        except ImportError as e:
            raise LLMError(
                "DatabricksLLMDriver requires the `databricks-sdk` package."
            ) from e
        try:
            self._w = WorkspaceClient(profile=profile)
            # Trigger auth resolution NOW so we fail fast with a clear error
            # instead of mid-eval when a credential refresh fails.
            self._host = self._w.config.host.rstrip("/")
            _ = self._w.config.authenticate()
        except Exception as e:
            raise LLMError(
                f"DatabricksLLMDriver failed auth (profile={profile!r}): {e}\n"
                f"If your refresh token is expired, run:\n"
                f"  databricks auth login --profile {profile}\n"
            ) from e
        self.endpoint_name = endpoint_name or self.default_model

    def complete(
        self,
        messages: list[dict],
        *,
        model: str | None = None,
        max_tokens: int = 2048,
        temperature: float = 0.0,
        timeout_s: float = 60.0,
        tools: list[dict] | None = None,
        tool_choice: str | dict | None = None,
    ) -> LLMResponse:
        endpoint = model or self.endpoint_name
        url = f"{self._host}/serving-endpoints/{endpoint}/invocations"
        body: dict = {
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if tools is not None:
            body["tools"] = tools
        if tool_choice is not None:
            body["tool_choice"] = tool_choice
        data = json.dumps(body).encode("utf-8")
        # Pull a fresh bearer for THIS request (SDK handles refresh).
        headers = self._w.config.authenticate()
        headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=data, method="POST",
                                     headers=headers)
        t0 = time.monotonic()
        try:
            with urllib.request.urlopen(req, timeout=timeout_s) as resp:
                body_text = resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            err_body = ""
            try:
                err_body = e.read().decode("utf-8", errors="replace")
            except Exception:  # noqa: BLE001
                pass
            raise LLMError(
                f"Databricks endpoint {endpoint!r} HTTP {e.code}: {e.reason}\n"
                f"Body: {err_body[:500]}"
            ) from e

        elapsed_ms = int((time.monotonic() - t0) * 1000)
        payload = json.loads(body_text)
        choices = payload.get("choices") or []
        if not choices:
            raise LLMError(f"Databricks endpoint returned no choices: {payload}")
        first = choices[0]
        msg = first.get("message") or {}
        text = msg.get("content") or ""
        usage = payload.get("usage") or {}
        return LLMResponse(
            text=text,
            model=endpoint,
            backend=self.backend_name,
            elapsed_ms=elapsed_ms,
            input_tokens=usage.get("prompt_tokens"),
            output_tokens=usage.get("completion_tokens"),
            raw=payload,
            tool_calls=msg.get("tool_calls") or None,
            finish_reason=first.get("finish_reason"),
        )


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

def get_llm_driver(
    backend: Literal["cursor", "databricks"] = "cursor",
    **kwargs: Any,
) -> LLMDriver:
    if backend == "cursor":
        return CursorLLMDriver(**kwargs)
    if backend == "databricks":
        return DatabricksLLMDriver(**kwargs)
    raise ValueError(f"unknown LLM backend: {backend!r}")
