# Review Needed: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

**Generated:** 2026-04-21 | **Batch:** 19 | **Reviewer:** —

## Tier 2 Items (Reviewer Verification Needed)

- [ ] **VBT definition**: Is "KYCFlowTypeID=2" the correct definition of VBT (Verified-by-eToro)? The SP filters External_ComplianceStateDB_KycFlow/History_KycFlow WHERE KYCFlowTypeID=2. Confirm with Compliance team.
- [ ] **PlayerStatusID exclusions**: SP excludes PlayerStatusID NOT IN (2,4,13). Confirmed 2=Blocked, 4=Fraudster. What is 13? Review sidecar from BI_DB_Blocked_Customers batch notes references "AML Limited" — confirm this is correct for 13.
- [ ] **DesignatedRegulation vs Regulation**: Two separate Dim_Regulation joins — one on RegulationID, one on DesignatedRegulationID. Can these differ significantly? Document known cases where DesignatedRegulation ≠ Regulation.
- [ ] **FTDA when FTD=0**: The SP always includes fd.FirstDepositAmount even when FTD=0. Is this intentional? Analysts may incorrectly assume FTDA is NULL when FTD=0.
- [ ] **Date range starting 2019-01-01**: The table goes back to 2019-01-01 but UpdateDate starts 2020-04-22. Were rows before April 2020 backfilled or is this a different ETL era?

## Potential Data Quality Issues

- **Desk column is varchar(8000)**: Extremely wide for what appears to be a short categorical value. May cause issues in downstream tools.
- **Regulation is current-time**: Regulation/DesignatedRegulation reflect the snapshot at ETL run time, not at the time of the milestone event. Historical funnel analysis by regulation may be misleading.
- **IsVBT relies on GCID**: Older accounts without GCID will always show IsVBT=0 regardless of their KYC path.

## Open Questions

1. What downstream dashboards consume this table? (Not confirmed via Atlassian MCP)
2. Is there a non-VBT variant of this table? (BI_DB_CIDFunnelFlow is rolling 12-month; this is cumulative — are they complementary?)
3. Priority 90 dependency on BI_DB_CIDFirstDates confirmed from OpsDB dependency row — but what happens if CIDFirstDates fails? Does this SP fail gracefully?

## Corrections Log

*No corrections applied.*
