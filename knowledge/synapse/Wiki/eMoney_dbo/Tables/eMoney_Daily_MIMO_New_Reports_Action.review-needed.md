# Review Needed — eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action

**Generated**: 2026-04-21
**Wiki Quality**: 9.0/10
**Reviewer**: eMoney Data Analytics Team

---

## Tier 4 Items (Low-Confidence — Requires Business Review)

None. All 21 columns are Tier 2 with full SP code evidence.

---

## Open Questions

1. **FundingTypeID=33 = eToroMoney**: This is hardcoded in the SP as the eMoney/Other split key. Is there a Dictionary.FundingType entry that confirms FundingTypeID=33? If Tribe introduces a new direct transfer method with a different FundingTypeID, this split logic will silently misclassify it.

2. **IsValid default to 1**: ISNULL(mda.IsValidETM, 1) means customers NOT in eMoney_Dim_Account are counted as IsValid=1. Is this intentional? These may be non-eToro-Money customers (general eToro platform customers making normal deposits/cashouts) who happen to be in eToro Money open countries. This could overstate IsValid=1 counts.

3. **Full series coverage**: The table starts from 2022-05-01. Was there MIMO reporting before May 2022? If yes, was it in a different system or schema? The SP comment says "Migration to Synapse" — what was the pre-migration source?

4. **Table naming "New"**: The "New" suffix signals this replaced eMoney_Reports_MIMO_Actions. Is eMoney_Reports_MIMO_Actions still actively queried? Should it be documented as deprecated/archived?

5. **Seniority_daily_FTD_Group NULL**: Are there rows where this field might be NULL? The SP uses DATEDIFF which could return NULL if FirstDepositDate is NULL. Does Dim_Customer.FirstDepositDate ever NULL for customers?

---

## Corrections from Previous Documentation

None — first-time documentation.

---

## Cross-Object Consistency Checks

| Column | Also in | Verified Match? |
|--------|---------|----------------|
| ActionType | DWH_dbo.Dim_ActionType | ActionTypeID 7=Deposit, 8=Cashout confirmed from SP filter |
| FundingType | DWH_dbo.Dim_FundingType | 15 distinct funding types confirmed from live query |
| Country | eMoney_dbo.eMoney_Dim_Country_Rollout | 34 countries at latest date — consistent with rollout table |
| eMoney_Reports_MIMO_Actions | Same table (predecessor) | Schema confirmed identical except Type_of_IBAN |
