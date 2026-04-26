# BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback — Review Needed

## Tier 4 Items

None — all columns traced to DWH_dbo dimensions/facts or ETL logic.

## Questions for Reviewer

1. **CategoryID=18 meaning**: The SP filters Fact_CustomerAction by `Dim_ActionType.CategoryID=18`. This appears to be the "crypto-relevant actions" category. Confirm this is the correct business definition for crypto activity in the dashboard context.
2. **Active_Open conjunctive logic**: The definition requires BOTH a trade-type (Manual or Copy) AND a settlement-type (Real or CFD). Is this the intended business definition, or should any crypto activity qualify?
3. **AirDrop exclusion**: The SP excludes `IsAirDrop=1` transactions. Confirm this is intentional — AirDrops should not count toward active trading engagement.
4. **Churn/Win_Back global recompute**: Every daily run recalculates Churn/Win_Back for ALL months via LAG. This means historical values can change. Is this the desired behavior, or should historical months be frozen?

## Cross-Object Consistency Notes

- **RealCID**: Description matches DWH_dbo.Dim_Customer wiki verbatim (Tier 1 — Customer.CustomerStatic).
- **Country**: Description matches DWH_dbo.Dim_Country.Name wiki verbatim (Tier 1 — Dictionary.Country).
- **Region**: Uses MarketingRegionManualName (Tier 3), not MarketingRegionName — consistent with Dim_Country wiki distinction.

## Validation

- Element count: 13 (DDL) = 13 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
