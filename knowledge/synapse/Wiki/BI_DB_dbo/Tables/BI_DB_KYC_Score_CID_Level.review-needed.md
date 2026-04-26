# BI_DB_dbo.BI_DB_KYC_Score_CID_Level — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **Q11 bracket label**: '$10K-$50K & $1M-$5M' groups two non-contiguous ranges. Is this intentional (combining mid-range and high-range), or is the missing $50K-$1M range in a separate bracket?
2. **Rev_Cluster_Dict**: What do cluster numbers 1-10 represent? The dictionary mapping (Q11_IND x Age_IND x Max33_35_IND → Cluster) is not documented. A description of each cluster's business meaning would greatly improve usability.
3. **CI on UpdateDate**: The clustered index is on UpdateDate, but all rows share the same UpdateDate after TRUNCATE+INSERT. This index provides no selectivity. Should it be on RealCID instead?
4. **Revenue30days**: Is this the same Revenue30days from BI_DB_KYC_Panel? What does it measure exactly (commissions, spread, total)?
