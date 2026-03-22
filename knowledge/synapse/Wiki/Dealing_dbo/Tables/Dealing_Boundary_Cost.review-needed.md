# Review: Dealing_dbo.Dealing_Boundary_Cost

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.5/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ No Generic Pipeline mapping | Table is a multi-source computed table; no direct production source in the mapping | Verify if there's a separate orchestration entry for this table |
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence scan) skipped | Search Confluence/Jira for "Boundary Cost" or "hedge boundary" to add business context |
| ⚠️ Data staleness | Max date observed was 2024-03-17 | Confirm if table is still actively populated or has been deprecated |
| ⚠️ etoro_Hedge_InstrumentBoundaries | Source table is in `dbo` schema (not `Dealing_dbo`); unclear which schema owns it | Confirm table owner and document |
| ℹ️ HS_Moved_Units semantic | Logic for tracking inter-HS unit movements is complex — simplified in doc | Review whether the description accurately reflects the HS migration tracking logic |
| ℹ️ UNION ALL rows | The SP has a second UNION ALL branch for instruments with all units moved out but no trades | Review-needed: are those rows represented correctly in the column descriptions? |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->

