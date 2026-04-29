# BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **No History.Credit upstream wiki**: The etoro.History.Credit table does not have a production wiki. Payment, CreditID, Description, and Occurred descriptions are Tier 2 (SP code analysis). If a History.Credit wiki is built, these should be upgraded to Tier 1.
2. **Negative Payment values**: CySEC regulation shows -373K total payment. Are these reversals of compensations or debits? The Payment column uses money type which supports negatives.
3. **CreditTypeID=6 / MoveMoneyReasonID=1 / CompensationReasonID=3**: These filter values are hardcoded. What do they map to in the production dictionaries? Confirm the exact meanings.
4. **Snapshot vs occurrence regulation**: The SP uses Fact_SnapshotCustomer with the SP run date's DateRangeID, meaning the regulation may not match the customer's regulation at the time of the compensation event. Is this intentional?

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer.RealCID (Tier 1 — Customer.CustomerStatic) ✓
- Regulation description matches DWH_dbo.Dim_Regulation.Name (Tier 1 — Dictionary.Regulation) ✓
