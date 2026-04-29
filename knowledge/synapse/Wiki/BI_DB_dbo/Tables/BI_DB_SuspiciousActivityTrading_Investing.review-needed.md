# BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing — Review Needed

## Tier 4 / Unverified Items

- None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **DELETE bug**: The WHERE clause `WHERE @StartRunningDate=@StartRunningDate` always evaluates TRUE, deleting ALL rows. Is this intentional (full replace) or a bug? If intentional, it's functionally TRUNCATE.
2. **Customer exclusion filters**: PlayerLevelID<>4, LabelID<>30, CountryID<>250, AccountTypeID<>9, PlayerStatusID<>9 — what do these specific exclusions represent? (Diamond players? Internal? Specific country?)
3. **IsCopy always 'Manual'**: Since MirrorID=0 is filtered in all groups, the IsCopy column is always 'Manual'. Was copy-trade detection originally planned but disabled?
4. **Group A deduplication**: Group A uses `WHERE f.RootCID NOT IN (SELECT RootCID FROM BI_DB_SuspiciousActivityTrading_Investing WHERE ...)` to avoid duplicates within the same day. Does this mean the SP can run multiple times per day?

## Corrections Applied

- None.

## Atlassian

- Atlassian search unavailable (permission denied).
