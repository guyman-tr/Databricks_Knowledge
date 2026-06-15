"""Smoke-test the Cursor LLM driver."""
from __future__ import annotations
import os, sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

os.environ.setdefault("CURSOR_API_KEY",
    "crsr_791df85221aff9df65c4d07281649684fcade1235649caf3a16f5f57a3c191ea")

from tools.eval_suite.harness.suts._llm_driver import CursorLLMDriver

drv = CursorLLMDriver()
resp = drv.complete([
    {"role": "system", "content": "You answer with a single word."},
    {"role": "user", "content": "What is 2+2?"},
], max_tokens=50, temperature=0.0)

print(f"backend:       {resp.backend}")
print(f"model:         {resp.model}")
print(f"elapsed_ms:    {resp.elapsed_ms}")
print(f"input_tokens:  {resp.input_tokens}")
print(f"output_tokens: {resp.output_tokens}")
print(f"text:          {resp.text!r}")
