# Review Needed: BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report

## 1. Empty Table

The table returned 0 rows at query time (2026-04-29). This is a TRUNCATE + INSERT table refreshed daily by SP_M_Compliance_CDIM_Report. The empty state may indicate:
- The SP has not been executed recently
- The SP failed during its last run
- The population criteria (FCA, verified L3, depositor, active trader) currently yields 0 matches (unlikely)

**Action**: Verify the SP is scheduled and running successfully in OpsDB / SB_Daily.

## 2. Distribution Analysis Skipped

Phase 3 (distribution analysis) could not run due to the empty table. When the table is populated, verify distributions for:
- `Appropriateness_Status` -- expected: Failed (~75%), Passed (~24%), Borderline Pass (<1%)
- `PlayerStatus` -- expected: Normal (majority), with various restricted states
- `Club` -- expected: Bronze/Silver majority, Diamond/Platinum+ minority

## 3. KYC Source Table Unresolved

`BI_DB_KYCUserRawDataLeveled` has no upstream wiki in the bundle (listed as "unresolved"). The 29 KYC columns are documented as Tier 2 based on SP pivot logic. If a wiki for this table is created in the future, review whether descriptions should be upgraded.

## 4. CameFromAffiliate SubChannelID Mapping

The flag uses `SubChannelID IN (20, 31)` to identify affiliate-sourced customers. The specific meaning of SubChannelIDs 20 and 31 should be verified against Dim_Channel to confirm they represent affiliate channels. From the Dim_Channel wiki, SubChannelID values are non-sequential (range 1-52, 36 active).

## 5. NegativeMarket Filter Specificity

The NegativeMarket column only captures `BlockReasonID = 12` with `RestrictionStatusDesc = 'Failed'`. Other block reasons from BI_DB_Scored_Appropriateness_Negative_Market are not captured. Confirm with the compliance team whether this is the intended scope or if additional block reasons should be included.

## 6. Weekly/Monthly Variant

The SP comment references `complianceuk@etoro.com`. A related SP `SP_W_Mon_Compliance_CDIM_Report` exists (referenced in the Dim_Channel wiki as a consumer). This variant may cover other regulations beyond FCA. Confirm whether both reports are actively used and whether they should share documentation.

---

*Generated: 2026-04-29 | Reviewer: Compliance / BI Data Solutions*
