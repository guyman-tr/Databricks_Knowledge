from .base import SUT, SUTResponse
from .mock import MockSUT
from .direct_sql import DirectSQLSUT

__all__ = ["SUT", "SUTResponse", "MockSUT", "DirectSQLSUT"]


def get_sut(name: str, **kwargs) -> SUT:
    """Factory used by run_harness.py CLI. Add backends here as we wire them up."""
    if name == "mock":
        return MockSUT(**kwargs)
    if name == "direct_sql":
        return DirectSQLSUT(**kwargs)
    if name == "direct_mcp":
        # The real Databricks-MCP eval SUT: spawns mcp-remote, drives the
        # canonical skills_find -> skills_get -> LLM -> execute_sql flow.
        from .direct_mcp_sut import DirectMcpSUT
        return DirectMcpSUT(**kwargs)
    if name == "databricks_mcp":
        from .databricks_mcp import DatabricksMcpSUT
        return DatabricksMcpSUT(**kwargs)
    if name == "genie_code":
        from .genie_code import GenieCodeSUT
        return GenieCodeSUT(**kwargs)
    if name == "cursor_agent":
        # DEPRECATED 2026-06-14: does not exercise the MCP. Kept as a
        # no-MCP control SUT only. See tools/eval_suite/harness/suts/cursor_agent.py
        from .cursor_agent import CursorAgentSUT
        return CursorAgentSUT(**kwargs)
    raise ValueError(f"unknown SUT backend: {name!r}")
