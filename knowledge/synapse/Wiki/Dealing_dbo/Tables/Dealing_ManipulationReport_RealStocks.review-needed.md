# Review: Dealing_dbo.Dealing_ManipulationReport_RealStocks

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.5/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "ManipulationReport" or "SP_ManipulationReport_RealStocks" in Confluence for regulatory context and thresholds |
| ⚠️ Flag2 threshold unclear | Flag2 KPI joins #StocksInfo_KPIs but the exact client-units-to-exchange-volume ratio threshold was not explicitly defined in SP code reviewed | Verify with Dealing/Compliance team what the Flag2 threshold is (e.g., minimum Units/ExchangeUnitsVolume ratio) |
| ⚠️ RegulationID mapping | SP uses RegulationID IN (1,2,4) — documented as CySEC, FCA, ASIC-equivalent, but exact name-to-ID mapping inferred from Dim_Regulation joins | Confirm RegulationID=4 is indeed ASIC or another regulator |
| ⚠️ IsLowMktCap definition | Low market cap = RN_MktCap ≤ 20 (bottom 20 by market cap in most recent StocksInfo data), but the reference date for this ranking is the same @dd date — confirm whether this is correct or if a more stable ranking window is used |  Verify with the Dealing team whether the 20 threshold or ranking window ever changes |
| ℹ️ MirrorID=0 filter | Copy-trading positions are excluded (MirrorID=0 = manual only). This means copy-positions are never flagged for manipulation — intentional per regulatory scope | Confirm this exclusion is deliberate for the regulatory framework |
| ℹ️ AvgVolume KPI ranking | AvgVolume KPI selects top 20 by `(Volume - Last30DaysAvgVolume) / Last30DaysAvgVolume` percentage difference — the exact ranking metric was inferred from SP structure | Verify the sort key for AvgVolume segment |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
