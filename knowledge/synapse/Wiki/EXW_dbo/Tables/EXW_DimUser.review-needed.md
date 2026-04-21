# EXW_DimUser — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 2 Items (Derived — May Need Verification)

| # | Column | Description | Verification Needed |
|---|--------|-------------|---------------------|
| 1 | Country | Denormalized from Dim_Country.Name | Confirm Dim_Country is always up-to-date relative to EXW_DimUser refresh schedule |
| 2 | RegionID | Dim_Country.MarketingRegionID | Confirm marketing region groupings match business expectations |
| 3 | Region | Dim_Country.Region | Same as above |
| 4 | Regulation | Dim_Regulation.Name | Verify join is on DWHRegulationID (confirmed in SP) |
| 5 | Club | Dim_PlayerLevel.Name | Confirm all 7 PlayerLevelID values (1-7) have matches in Dim_PlayerLevel |
| 6 | UserRegion_State | Dim_State_and_Province on RegionByIP_ID | State detection is IP-based at registration — may be stale for moved users |

## Open Questions

- **UC Target**: Listed as `_Not_Migrated` — confirm whether EXW_DimUser should be exported to Unity Catalog for self-service analytics.
- **Deleted wallet users**: SP_DimUser has the DELETE step commented out (lines 36-39). Is this intentional policy (users who close wallet stay) or a bug? If users who close wallets remain, analytics on "active wallet users" requires a separate filter beyond just IsValidCustomer.
- **PlayerLevelID distribution in EXW**: 7 distinct values (1,2,3,4,5,6,7). The Dim_Customer wiki documents 1=Standard, 4=Popular Investor, 7=VIP. Confirm what values 2,3,5,6 map to in the context of Wallet users.
- **Refresh schedule**: Confirmed daily based on UpdateDate recency. Is this triggered from a scheduler or OpsDB Service Broker? Confirm if there are failure alerting mechanisms.
- **ComplianceClosureEvent vs ComplianceClosureDate**: The flag tells us IF a user is in a closed country but not WHEN they were flagged. If analysts need the closure date, they must JOIN to EXW_WalletClosedCountryProjects.

## No Reviewer Corrections at Time of Generation
