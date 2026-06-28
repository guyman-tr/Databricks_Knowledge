"""Shared diff -> ingest -> push framework for the knowledge-base automations.

Cloned from the generic half of tools/skill_suggestions/. Each app under
Data_Skills_Automation/<App>/ provides a `detect.py` (diff vs snapshot) and an
ActionSpec (prompt + artifact kind); this package supplies the reusable engine:
state snapshots, the run-log writer, the Cursor SDK bridge, notifications, and
the per-item cycle loop.
"""
