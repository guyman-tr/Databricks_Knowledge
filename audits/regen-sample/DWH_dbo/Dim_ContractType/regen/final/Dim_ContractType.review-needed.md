# Review Needed — DWH_dbo.Dim_ContractType

## Items for Human Review

### 1. Production Source Unknown

The original production source for this dimension table is not identifiable. The table was loaded via a one-time migration (`DWH_Migration.Dim_ContractType`), but the ultimate source system (e.g., a CRM, affiliate platform, or manual entry) is unknown. A domain expert should confirm where these 9 contract type values originate.

### 2. CPR/CPL ID Mapping Inconsistency

In `SP_Dim_Affiliate`, the CASE logic assigns:
- ContractName LIKE '%cpl%' → 8
- ContractName LIKE '%cpr%' → 8

Both CPL and CPR patterns map to ID 8. However, in Dim_ContractType, ID 1 = CPR and ID 8 = CPL. This suggests either:
- The CASE logic in SP_Dim_Affiliate has a latent bug (CPR should map to 1, not 8), or
- The mapping was intentionally changed and the dimension table values are stale.

A domain expert should verify the correct CPR mapping.

### 3. InsertDate / UpdateDate Always NULL

Both timestamp columns are NULL across all 9 rows. If these columns are intended to track row lifecycle, the migration process that loaded the data did not populate them. Consider whether they should be backfilled or removed.

### 4. Contract Type Business Definitions

The abbreviations (CPR, CPA, Rev, Hyb, eCost, ZeroCost, CPL) are not formally documented. Confirm:
- CPR = Cost Per Revenue (or Cost Per Registration?)
- CPA = Cost Per Acquisition
- Rev = Revenue Share
- Hyb = Hybrid
- eCost = Electronic Cost (?)
- ZeroCost = Zero-cost arrangement

---

*Generated: 2026-04-28*
