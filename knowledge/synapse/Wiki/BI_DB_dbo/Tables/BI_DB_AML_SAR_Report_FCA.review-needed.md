# Review Notes — BI_DB_dbo.BI_DB_AML_SAR_Report_FCA

**Batch**: 16 | **Generated**: 2026-04-21 | **Reviewer**: AML / Compliance Team

---

## Tier 4 Items (Low Confidence — Review Required)

| Column | Issue | Action |
|--------|-------|--------|
| Occupation | Source: BI_DB_KYC_Panel.Q18_AnswerText (LEFT JOIN). Data quality and completeness of KYC question 18 responses unknown. NULL rate not quantified. | Confirm Q18 is the correct KYC question for occupation. Verify NULL rate with compliance team. |

---

## Open Questions for Reviewer

1. **TotalDeposit_POUND column naming**: The SP aggregates `Fact_BillingDeposit.Amount`, which is in USD — yet the column is named `TotalDeposit_POUND`. Is this a known naming inconsistency? Should it be documented as USD or is there currency conversion applied elsewhere?

2. **Consent_Required = 'Y / N'**: This hardcoded placeholder does not capture per-customer consent status. Is this intentional for the SAR submission format, or should it reflect actual consent data?

3. **SarCode NULL gap (~8,987 rows)**: Customers in the FCA depositor population whose CID is not in `V_Liabilities` for the @DateID receive NULL SarCode. Are these customers handled separately in the SAR submission workflow, or are they excluded from submissions?

4. **MOP aggregation picks most common method**: The SP picks the single most-used payment method per customer (not the most recent). For SAR purposes, is this the intended behaviour, or should the most recent transaction method be reported?

5. **SourceRef = CID**: The `SourceRef` field is set to `dc.RealCID` (the same value as CID). Is this the FCA's expected reference number format, or should it be an account number or other identifier?

---

## Known Data Quirks

- **SARDate is always the SP run date** — not a business event date. Do not use for temporal analysis.
- **No historical rows** — TRUNCATE+INSERT replaces all data daily. Point-in-time snapshots are not available.
- **TotalCO uses SUM(DISTINCT ...)** — may under-count if two separate cashouts have identical amounts.
- **Gender expanded** — Dim_Customer char values (M/F/U) → full words (Male/Female/Unknown) in this table.
- **~56% of rows have NULL IsIDProof and IsAddressProof** — these are customers without proof records in BackOffice.CustomerDocument, not a data quality issue.

---

## Cross-Object Consistency Verified

| Column | Checked Against | Result |
|--------|----------------|--------|
| CID description | DWH_dbo.Dim_Customer.RealCID wiki | MATCH — verbatim from Customer.CustomerStatic |
| GCID description | DWH_dbo.Dim_Customer.GCID wiki | MATCH — verbatim from Customer.CustomerStatic |
| BirthDate description | DWH_dbo.Dim_Customer.BirthDate wiki | MATCH |
| FirstName, LastName, MiddleName | DWH_dbo.Dim_Customer wiki | MATCH |
| RegisteredReal | DWH_dbo.Dim_Customer wiki | MATCH |
| Phone, Email | DWH_dbo.Dim_Customer wiki | MATCH |
