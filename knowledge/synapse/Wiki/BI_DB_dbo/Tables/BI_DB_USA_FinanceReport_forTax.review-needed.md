# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Column count discrepancy**: The batch assignment specified 13 columns but the DDL only has 12. Confirm the correct count.
2. **PII exposure**: SSN and City columns contain PII with dynamic data masking. Are access controls (UNMASK permission) properly restricted to authorized tax reporting roles?
3. **FULL OUTER JOIN logic**: Compensation and closed positions are FULL OUTER JOINed. This means a customer can appear with NULL compensation (only closes) or NULL close metrics (only compensation). Is this the intended grain?
4. **RegulationID 6 vs 7**: eToroUS (6) and FinCEN (7) are both included. Are these the same entity under different regulatory frameworks, or different customer populations?
5. **History.Credit dynamic external table**: The SP creates an external table via SP_Create_External_etoro_History_Credit. Is this used for the main table or only for the secondary BI_DB_USA_FinanceReport_forTax_CreditID table?
6. **ActionTypeID=36 only**: Compensation is limited to ActionTypeID=36. Are there other compensation-related action types that should be included for tax reporting?
