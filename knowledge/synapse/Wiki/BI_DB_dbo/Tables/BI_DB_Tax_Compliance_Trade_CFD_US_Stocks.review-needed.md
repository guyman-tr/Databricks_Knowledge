# BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **UPDATE-only ETL**: The MERGE (INSERT/UPDATE/DELETE) is commented out and replaced with UPDATE JOIN only. How are new qualifying CIDs initially inserted? The table appears to be a static snapshot from the last MERGE run, only updated when CID is already present.
2. **No UC mapping**: This table does not appear in the Generic Pipeline mapping. Confirm whether it should be exported to Unity Catalog.
3. **ActionTypeID filter**: The SP uses ActionTypeID IN (1, 2, 3). Verify these map to Buy/Sell/Limit order types in Dim_ActionType.

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer.RealCID (Tier 1 — Customer.CustomerStatic) ✓
