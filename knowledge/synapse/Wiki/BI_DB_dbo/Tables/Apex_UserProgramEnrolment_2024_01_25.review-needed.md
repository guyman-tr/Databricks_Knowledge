# Review Needed: BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25

**Generated**: 2026-04-23
**Quality Score**: 8.0/10
**Status**: LOW PRIORITY — frozen snapshot, all columns Tier 3 (inferred from External_USABroker_Apex_UserProgramEnrolment DDL and SP context)

---

## Tier 3 Items (Verification Opportunities)

All 5 columns are Tier 3 — inferred from the live external table DDL and SP code references. No Tier 4 items.

| Column | Inference Basis | Verification Note |
|--------|----------------|-------------------|
| GCID | External_USABroker_Apex_UserProgramEnrolment column name + SP_Crypto_NOP join pattern | Confirm GCID maps to Dim_Customer.GCID (not RealCID) for US Apex accounts |
| UserProgramEnrolmentStatusID | SP_Crypto_NOP filters status=2 for active staking | Confirm status=1 is Inactive/Pending vs. another meaning |
| UserProgramID | All 13,649 rows = 2 in this snapshot; live external table may have other program IDs | Confirm UserProgramID=2 is specifically the Staking/Money Market program |
| BeginTime | SCD2 pattern standard from Apex upstream | No verification needed |
| EndTime | All rows = 9999-12-31 (SCD2 sentinel); no closed records in snapshot | Confirm snapshot was taken before any enrollments closed |

## Open Questions

1. **Was this snapshot intentional or incidental?** No writer SP exists — this was likely a manual CTAS or SELECT INTO. Was there a specific audit or reconciliation event on 2024-01-25 that triggered it?

2. **Predecessor table**: `BI_DB_dbo.USABroker_Apex_UserProgramEnrolment_old` — what date range does it cover? Is there a gap between the old snapshot and this one?

3. **Referenced by SPs?** The summary doc notes active SPs use the LIVE external table. Confirm neither `SP_Crypto_NOP` nor `SP_CMR_Automation_RealCrypto_Main_CryptoNOP_ALLRegs_USA_Staking` reference this snapshot table by name.

4. **UC migration**: Currently `_Not_Migrated`. Will this frozen snapshot ever be migrated to Unity Catalog, or is it considered obsolete?

## Corrections

- If reviewer can confirm the reason for the 2024-01-25 snapshot, upgrade quality score from 8.0 to 8.5
- If UserProgramID=2 identity is confirmed from Apex documentation, upgrade GCID/UserProgramID columns from Tier 3 to Tier 1 or Tier 2

## Reviewer Instructions

1. Check with the US Operations or Data Engineering team for context on the 2024-01-25 snapshot creation event
2. Verify SP_Crypto_NOP does NOT join to this snapshot table (only to the live external table)
3. Optionally confirm UserProgramID=2 = Staking/Money Market from Apex Clearing documentation
