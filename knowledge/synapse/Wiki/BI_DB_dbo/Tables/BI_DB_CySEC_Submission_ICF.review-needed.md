# BI_DB_dbo.BI_DB_CySEC_Submission_ICF — Review Needed

## Tier 4 Items

None — all columns traced to SP logic, BI_DB source tables, or DWH dimension lookups.

## Questions for Reviewer

1. **TransferDirection=1 filter**: The SP filters BI_DB_Client_Balance_CID_Level_New to TransferDirection=1 only. What does this value represent? Is it "incoming" or "total" balance?
2. **ICF applicability**: The table name says "CySEC" but includes ALL regulations (FCA, BVI, FinCEN, etc.). Is this intentional for cross-regulatory comparison, or should non-CySEC rows be excluded?
3. **IsCreditReportValidCB**: This flag from Fact_SnapshotCustomer — what determines credit report validity? Does it affect ICF eligibility?
4. **ECB rate timing**: The ECB rate is the latest available on or before the SP execution date, not the EOMONTH rate. For backfills, this means different EUR values depending on when the SP was run.
5. **Commented-out WaitforSeconds**: Line 7 shows `EXEC [DWH_dbo].[WaitforSeconds] 3600` was cancelled by Boris.P on 2024-01-02. Was this a rate-limiting safeguard?

## Cross-Object Consistency Notes

- **CID** (not RealCID): Consistent with BI_DB_Client_Balance_CID_Level_New source. JOINs to Dim_Customer use CID=RealCID.
- **Club values**: Include "Internal" (PlayerLevelID=4) — unlike many BI_DB tables, internal accounts are NOT excluded from this regulatory report.

## Validation

- Element count: 15 (DDL) = 15 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
