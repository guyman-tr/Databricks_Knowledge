"""tier1_audit — semantic audit of (Tier 1 -- X) column claims in DWH wikis.

Detects two failure modes:

  1. Tier promotion lies: a column tagged (Tier 1 -- X) whose source X is
     itself a Tier 2 or computed object — i.e. the inheritance chain
     fabricated provenance.
  2. Semantic drift: a column tagged (Tier 1 -- X) whose description has
     diverged in meaning from the actual source-of-truth wiki for X.

Sub-modules:

  parser         — extract column rows and (Tier N -- X) tags from .md
  resolver       — resolve the "X" text to a concrete source wiki path
  source_lookup  — load the source wiki, find the matching column row
  judge          — LLM-backed semantic compare with substantive-vs-cosmetic
                   discrimination
  reporter       — write CSV / MD / metadata outputs

Entry point: tools/audit_tier1_claims.py
"""
