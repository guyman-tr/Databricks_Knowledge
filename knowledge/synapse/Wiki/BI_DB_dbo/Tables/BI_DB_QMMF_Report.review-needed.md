# Review Needed: BI_DB_dbo.BI_DB_QMMF_Report

## Tier 4 Items

None — all columns traced to SP code. However, ComplianceStateDB has no upstream wiki, so all ComplianceStateDB-sourced columns are documented from SP code analysis (Tier 2) rather than upstream documentation.

## Review Questions

1. **Row count extremely high (~1.19B)**: The DELETE+INSERT pattern by LastInteractionDate accumulates daily snapshots. With 898K distinct GCIDs over ~960 days, the average is ~1.2M rows per day. Is this expected or is there a retention/purge policy?

2. **UserInteractionActionId semantics**: Values 1, 14, 15 are inferred from SP filter and data patterns. Confirm: 1=Open, 14=Accept, 15=Decline. ComplianceStateDB may have additional action types not captured here.

3. **StateAdditionalData format**: Observed values are 'Answer-Yes', 'Answer-No', and empty string. Are there other possible values? Is this a free-text field or constrained enum?

4. **Interest consent data source**: External_Interest_Trade_InterestConsent comes from the Interest database. No wiki exists for this source. The consent logic uses ROW_NUMBER with latest ValidFrom — confirm this is the correct business rule for determining current consent status.

## Corrections Applied

None.
