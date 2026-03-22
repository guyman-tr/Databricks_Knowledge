# Review: Dealing_dbo.Dealing_ApexRecon_Holdings

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.6/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "ApexRecon" or "SP_Apex_Recon" in Confluence for operational context |
| ⚠️ Dealing_Duco_EODRecon undocumented | Key source table `Dealing_Duco_EODRecon` not yet in wiki | Document Dealing_Duco_EODRecon before this table's full lineage can be validated |
| ⚠️ LP_APEX_EXT982_3EU is external staging | Apex LP holdings file lands in `Dealing_staging.LP_APEX_EXT982_3EU` — loading process not documented | Confirm how Apex files are ingested (SFTP? API?) and document the load process |
| ⚠️ LastExecutionTime always NULL | Column exists in DDL but never populated in current SP | Legacy column; confirm whether it was deprecated intentionally or should be populated |
| ⚠️ CUSIP matching complexity | Leading-zero CUSIP stripping logic (`WHEN LEFT(CUSIP,1)='0' THEN SUBSTRING(...)`) can cause mismatches for CUSIPs that legitimately start with 0 | Verify the CUSIP matching produces correct results; review #Ins_Duplicates for unresolved conflicts |
| ℹ️ RTH instruments | Instruments on 'Regular Trading Hours - RTH' exchange are treated separately (IsRTH=1 → hs_dealing_desk=12 only) | Confirm the RTH logic change in SR-334801 (2025-09-29) was applied correctly |
| ℹ️ Fivetran mapping | HS→LP account mapping comes from an automated Google Sheet sync via Fivetran | Confirm the Fivetran sync frequency and whether the mapping has audit history |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
