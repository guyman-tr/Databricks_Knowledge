"""Mock SUT: returns the case's pinned UC value verbatim.

Purpose: prove the harness loop end-to-end without any external dependency.
Every case MUST pass when this SUT is selected; if any case fails, the bug is
in the harness (scorer, runner, schema), not in any SUT.

This is a control group, not a real SUT.
"""
from __future__ import annotations

import time

from ..schema import CaseV1
from .base import SUT, SUTResponse


class MockSUT(SUT):
    name = "mock"

    def __init__(self, *, perturb_pct: float = 0.0):
        """If perturb_pct != 0, return value * (1 + perturb_pct/100). Useful
        for sanity-checking that the scorer's tolerance gate actually fires."""
        self.perturb_pct = perturb_pct

    def ask(self, question: str, case: CaseV1) -> SUTResponse:
        t0 = time.time()
        v = case.uc_equivalent.value
        if self.perturb_pct:
            v *= (1.0 + self.perturb_pct / 100.0)
        return SUTResponse(
            numeric_answer=v,
            text_answer=f"The answer is {v:,.4f}.",
            sql_used=case.uc_equivalent.sql,
            raw={"backend": "mock", "perturb_pct": self.perturb_pct},
            elapsed_ms=int((time.time() - t0) * 1000),
        )
