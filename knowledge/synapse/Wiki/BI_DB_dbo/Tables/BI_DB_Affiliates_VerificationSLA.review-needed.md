# Review: BI_DB_dbo.BI_DB_Affiliates_VerificationSLA

*Sidecar for wiki review. Does NOT contain wiki content — see BI_DB_Affiliates_VerificationSLA.md.*
*Generated: 2026-04-21 | Batch 14 #1*

## Tier 2 Items — Reviewer Confirmation Requested

| Column | Current Tier | Question |
|--------|-------------|---------|
| Regulation | Tier 2 | Resolved via Dim_Customer.DesignatedRegulationID → Dim_Regulation.Name. Is Dim_Regulation fully documented? Is `DesignatedRegulationID` the correct field for affiliate regulatory jurisdiction, or should `RegulationID` from Dim_Customer be used? |
| AccountType | Tier 2 | Confirmed AccountTypeID 6=Affiliate Private, 15=Affiliate Corporate from SP comment and Dim_Customer wiki. Verify values remain stable. |

## Business Logic Questions

1. **SLA=0 ambiguity**: The SLA column does not distinguish between "missed SLA" (Level3 reached but too slow) and "still pending" (Level3 not yet reached). Should the wiki recommend a separate flag or a companion column? Any plans to fix this in the SP?

2. **VerificationLevel3Date NULL + SLA=0**: In the current 4-month window, 83 customers are still at Level 2 (SLA outcome unknown). If the refresh runs after a customer reaches Level 3 but their Level2Date falls just outside the window, they'll be dropped — is this intentional?

3. **History table source**: SP was updated 2023-11-03 to use `[general].[etoro_History_BackOfficeCustomer]` instead of the previous BackOffice history source. Confirm this view is current and covers all affiliate verification events.

## UC Target Uncertainty

Table not found in generic pipeline mapping. Assumed `_Not_Migrated`. Reviewer should confirm:
- Is there a Databricks job that replicates this SLA computation?
- If yes, what is the UC path?
- If migrated, update wiki UC Target field and generate ALTER script.

## No Issues Found

- Element count: 14/14 — matches DDL ✓
- SLA CASE logic traced to code — matches SP lines 82–106 ✓
- Weekend offset business rules documented in Section 2.1 ✓
- Row count (571) confirmed via distribution query ✓
