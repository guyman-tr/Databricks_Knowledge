"""Loop authoring — agentic case generation from Tableau tile metadata.

Pipeline per tile:
  1. tile_context.load_tile(...)        # collect everything the agent sees
  2. author_agent.run(...)              # propose Synapse SQL, run, self-critique, revise
  3. adversary_agent.run(...)           # break it or sign off
  4. uc_translate.translate_and_pin(...) # Synapse->UC + parity check
  5. emit_case.write(...)               # case YAML + per-tile authoring report

All five steps emit a structured `step_log` so the human can see what
happened end to end. Cases that fail any step are written to
`tools/eval_suite/cases/_quarantine/` with the unresolved objection.
"""
