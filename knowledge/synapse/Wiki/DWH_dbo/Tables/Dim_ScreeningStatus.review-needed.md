# DWH_dbo.Dim_ScreeningStatus - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - column definitions are Tier 2 or Tier 3, but no Tier 4 UNVERIFIED.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Status meanings (Tier 3) | All 8 status descriptions are inferred from the Name field only - no upstream wiki exists. Please confirm: Is RiskMatch (4) distinct from SanctionsMatch (7) - does it cover adverse media / risk databases vs official sanctions lists? Does Technical (5) indicate a failed screening attempt that should be retried? |
| PendingInvestigation (2) vs MultipleMatch (6) | Are these manual-review states? Is PendingInvestigation for confirmed matches under review, and MultipleMatch for ambiguous screening results requiring disambiguation? |
| Unknown (0) usage | Does ID=0 represent customers who haven't been screened yet, or a failed/missing screening result? Should it be treated like a NULL in analytics? |

## Structural Questions

- **No upstream wiki**: ScreeningService.Dictionary.ScreeningStatus has no corresponding DB_Schema wiki page. This table's meanings are entirely inferred. A domain expert in AML/compliance should validate the status descriptions.
- **ScreeningService is a separate system**: This table sources from ScreeningServiceDB (a microservice), not the main etoro database. Are there more ScreeningService tables in the DWH? Should there be a ScreeningService-specific documentation section?
- **No DWH views join this table**: CustomerStatic may carry ScreeningStatusID but no DWH views pre-join it. Confirm which fact tables reference ScreeningStatusID.
- **RiskMatch (4) vs SanctionsMatch (7) severity**: The documentation assumes SanctionsMatch is more severe than RiskMatch. Is this correct for business logic (account blocking, compliance reporting)?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
