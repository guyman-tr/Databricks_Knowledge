# DWH_dbo.Fact_Deposit_Fees — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Reason Unverified |
|--------|------------------|
| OldPaymentID | Column name only; no SP logic found that explains its purpose. Legacy payment system reference. |
| UserName | Presence confirmed from DDL; semantics inferred as customer display name. |
| TransactionID_Internal | Purpose inferred from column name — eToro internal transaction reference. |
| ResponseCode | Acquirer response code interpretation inferred from payment processing context. |
| TransactionResponse | Full processor response message description inferred. |
| Threedsparameters | Content inferred as 3DS authentication payload from payment processor. |
| DepositRiskStatus | Two risk columns exist (DepositRiskStatus vs Riskstatus) — distinction unclear. |
| Riskstatus | Distinct from DepositRiskStatus; which is processor vs platform risk? |
| CustomerStatus | Customer account status at deposit time — semantics inferred. |
| AccountManager | Assigned AM name at deposit time — interpretation inferred. |
| Funnel | Dictionary.Funnel reference inferred from naming pattern. |
| DepositType | NULL for most rows; meaning unclear. |

*Upgraded from Tier 4 to Tier 4-Atlassian (Confluence-backed):*
- **DepositCollarAmount** — backed by Confluence fee calculation docs
- **DepositValueDate** — backed by Confluence deposit issues page
- **CustomerLevel** — eToro Club tier with fee discount schedule (Confluence)
- **FTD** — First Time Deposit, key business event (Confluence)
- **CountryByRegIP** — regulatory routing for fee schedule (Confluence)
- **CardCategory** — fee schedule differentiation (Confluence)

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DepositRiskStatus vs Riskstatus | Two risk columns exist. What is the distinction? Which is set by eToro risk system vs payment processor? |
| FTD | What format — "Yes"/"No" text, "1"/"0" string, or bit? What defines FTD — first deposit across all time, or first deposit in current regulatory entity? |
| Brand vs CardCategory | Brand="Visa", CardCategory=? Are these from Billing.Deposit or from the card BIN lookup? |
| OldPaymentID | What payment system does this reference? Is it still used? |
| DepositType | All NULL in sampled rows. When is this populated? |
| Funnel | Is this from Dictionary.Funnel or a different source? |

## Structural Questions

| Question | Context |
|----------|---------|
| Pipeline status confirmation | Staging table DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion no longer exists. Is the pipeline permanently discontinued, or planned for migration to a new pipeline? |
| Relationship to Fact_BillingDeposit | How does Fact_Deposit_Fees differ from Fact_BillingDeposit? Is one a superset of the other? Can they be joined on DepositID? |
| Duplicate rows | SP DELETE clause is commented out. Are there duplicate DepositID rows from multiple SP runs? Should SELECT DISTINCT be used in aggregations? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
