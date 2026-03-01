# Project Notes — POC → Full Project

- [ ] Update constitution to reflect Databricks/Data Lake as a knowledge-generating layer (not just a push target)
- [ ] UC as user feedback channel: after initial propagation, if a user manually edits a UC description, the next pipeline run should detect that change and give the user's version precedence. This inverts the authority — UC becomes the interface where users correct/refine metadata, and the pipeline respects it. Design how to detect "user-edited since last push" vs "stale from previous run."
- [ ] UC description format: specs 005+006 produce two outputs — descriptions-only and full-with-lineage. Evaluate both against real data to see what fits 1024 chars and is actually readable. Pick one format going forward.
- [ ] Agent wiring spec: spec 007 produces domain packages and routing metadata but NOT the actual Databricks AI assistant implementation. A new spec is needed for agent wiring (Genie vs custom agent, prompt engineering, cross-domain query routing).
- [ ] Domain package format: currently Markdown only. Consider adding JSON manifests per domain for machine consumption if the agent framework needs structured input.
