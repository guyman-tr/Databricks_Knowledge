# BI_DB_dbo.BI_DB_NewContactsActivityPerRep — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2).

## Questions for Reviewer

1. **Column count**: DDL has 11 columns, batch assignment said 12. Verified: 11 in DDL and INSERT.
2. **UnsuccessfullPhoneCalls**: Typo — double 'l'. Also misleading name: ActionName='Contacted__c' may not mean "unsuccessful" — it's a general contact attempt. Verify business meaning.
3. **WITH (NOLOCK)**: Used throughout SP — unnecessary in Synapse (snapshot isolation). Not harmful but misleading.
4. **Excluded ManagerIDs**: Hardcoded exclusions (0,342,787,283,887). What are these? System accounts? Should be documented or moved to config.
5. **ContactFTD 30-day window**: FTDs are attributed to the first manager contact within 30 days before deposit. Is this the agreed attribution model?
6. **UC migration**: _Not_Migrated.

## Corrections Applied

- Column count corrected from 12 to 11.
