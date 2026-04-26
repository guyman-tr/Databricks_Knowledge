# BI_DB_dbo.BI_DB_Investment_PIMeetup — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **All ID columns varchar(8)**: CID, MirrorID, ParentCID, etc. are all varchar(8). This requires CAST for JOINs with DWH int columns. Is this a design choice or oversight?

2. **Hardcoded MeetUp date**: `pos.OpenDateID >= 20250801` is hardcoded. If the PI Meetup anchor date changes, the SP must be updated manually.

3. **No UpdateDate column**: Unlike most BI_DB tables, this DDL has no UpdateDate column. The RunDateID serves a similar purpose.

4. **SP ignores @date parameter**: The SP declares `@date` as parameter but then immediately overwrites with `@Date = CAST(GETDATE() AS DATE)`. The parameter is effectively unused.

5. **CopyFromLake source**: Uses CopyFromLake.etoro_History_Mirror rather than a DWH_staging or External table. Confirm this is the correct source for mirror operations.

## Reviewer Corrections

None yet.
