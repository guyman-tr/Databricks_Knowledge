# BI_DB_dbo.BI_DB_STP_Redeems — Review Needed

## Tier 4 / Unverified Items

- None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **Duplicate rows**: Same RedeemID appears with different UpdateDate values. Is this from overlapping SP runs (WHERE LastModificationDate >= @Date AND < @Date+2 loads 2 days but deletes only 1 day)? The DELETE scope is `< DATEADD(day,1,@Date)` but the SELECT scope is `< DATEADD(day,2,@Date)`.
2. **STP meaning**: Confirmed as "Straight-Through Processing" — is this the intended business interpretation for this redeem approval workflow?
3. **AmdinistratorsApproved typo**: Column name is misspelled in the DDL. Is there a plan to fix this or is it left for backward compatibility?

## Corrections Applied

- None.

## Atlassian

- Atlassian search unavailable (permission denied).
