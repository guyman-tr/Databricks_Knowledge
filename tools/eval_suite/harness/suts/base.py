"""SUT (system-under-test) interface.

Every backend (Genie Code, custom Databricks MCP, mock, direct_sql) implements
the same `ask(question, case)` method and returns a SUTResponse. The runner is
agnostic to which SUT it's calling.

Two-method contract because the SUT is allowed to inspect the case for routing
hints (e.g. the schema/table FQNs in skill_coverage.fqns_referenced) — but the
agent under test in production WOULD only see the natural-language question
plus the same schema-discovery tools the user has. Production SUTs (genie_code,
databricks_mcp) MUST ignore the case argument and use only `question`. Test
SUTs (mock, direct_sql) MAY use `case` because they're control groups.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass

from ..schema import CaseV1


@dataclass
class SUTResponse:
    """What the SUT returned for one question.

    `numeric_answer` is what the harness scores against ground truth. It must
    be a single scalar; tiles that fundamentally have multiple measures are
    intentionally excluded from v1 (per the user's "one per tile" decision).

    `text_answer` is the SUT's full natural-language reply (used for LLM-judge
    secondary scoring; not required to be set).

    `sql_used` is the SUT's generated SQL if available — useful for skill-
    coverage analysis later (did the agent use the canonical SCD-2 join?).
    """
    numeric_answer: float | None
    text_answer: str | None
    sql_used: str | None
    raw: dict   # full provider response, for debugging
    error: str | None = None
    elapsed_ms: int = 0


class SUT(ABC):
    """Abstract SUT. Concrete backends override `ask`."""
    name: str = "abstract"

    @abstractmethod
    def ask(self, question: str, case: CaseV1) -> SUTResponse:
        """Ask the SUT one question. Must not raise; on error, return a SUTResponse with `error` set."""
        ...
