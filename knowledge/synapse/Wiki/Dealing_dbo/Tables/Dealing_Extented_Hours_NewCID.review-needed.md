---
object: Dealing_dbo.Dealing_Extented_Hours_NewCID
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Extented_Hours_NewCID

## Auto-Generated Flags

- [ ] **Stale since Aug 2025**: OpsDB-tracked (Priority 0) but not refreshed for ~7 months. Confirm if SP was intentionally suspended or if there's an OpsDB scheduling issue.
- [ ] **NOT EXISTS full-scan performance**: SP checks all historical Dim_Position rows on each run. Confirm if this causes performance issues as Dim_Position grows (295M+ rows as of early 2025).
- [ ] **`MirrorID` semantics**: Confirm if NULL MirrorID means "direct trade" (not via copy trading) or if NULL is a data gap.
- [ ] **Typo in object name**: "Extented" is consistent across table, SP, and companion table `Dealing_Extented_Hours_Volume`. Confirm if renaming is planned.

## Reviewer Corrections

<!-- Add corrections here. -->
