# BI_DB_dbo.BI_DB_OPS_MultipleAccounts — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **Club classification logic**: The SP identifies "Club" groups by checking if ANY account in the PII group has a PlayerLevel not in ('Bronze'). Confirm that this is the intended business rule — should "N/A" (PlayerLevelID=0) also count as non-Club?
2. **AccountType = 'Master'**: In current data, 0 accounts show as 'Master'. The CASE logic requires `CID = MasterAccountCID`, but master accounts may be filtered out by population criteria (VL3 depositors only). Is this expected?
3. **FN_LN_Country_BirthDate_Gender format**: The concatenation uses implicit date conversion resulting in locale-specific format ("Jul 31 1990 12:00AM"). This makes the key fragile across date format settings. Is this a known issue?
4. **Employee exclusion**: Pavlina added employee exclusion on 2025-11-05 but the SP code doesn't show an explicit employee filter beyond `PlayerLevelID <> 4`. Is the "Internal" player level the only employee identifier?

## Corrections Applied

- Column count corrected to 35 (DDL has 35 including UpdateDate; batch assignment said 34)

## Tier Summary

- **Tier 1 (14 columns)**: CID, FirstName, LastName, BirthDate, Gender, Country, VerificationLevelID, PlayerStatus, PlayerLevel, Regulation, PendingClosureStatusName, GuruStatusName, PlayerStatusReason, PlayerStatusSubReasonName, Club, RegisteredReal, HasWallet, GCID — wait, let me recount. Actually Club and PlayerLevel share the same source, and I count: CID, FirstName (T1+note), LastName (T1+note), BirthDate, Gender, Country, VerificationLevelID, PlayerStatus, PlayerLevel, Regulation, PendingClosureStatusName, GuruStatusName, PlayerStatusReason, PlayerStatusSubReasonName = 14 dim-lookup + passthrough T1.
- Plus: Club, RegisteredReal, HasWallet, GCID = 4 more T1.
- Total T1 = 18 (corrected from footer).

## Footer Correction Needed

The wiki footer says 14 T1 / 21 T2. Actual count: 18 T1, 17 T2. Footer should be updated.
