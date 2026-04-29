# DWH_dbo.Dim_Instrument -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 47 columns traced to source (Tier 1 upstream wiki, Tier 2 SP code, or Tier 3 live data).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ReceivedOnPriceServer | This is populated via post-load UPDATE from Ext_Dim_Instrument_ReceivedOnPriceServerStatic (an external table). Is this static file still actively maintained, or is it a historical snapshot? For instruments added after the last refresh, this will be NULL even if they are on the price server. |
| AssetClass / IndustryGroup | These come from Ext_Dim_Instrument_Classification_Static. Confirm: is this file refreshed automatically or manually? If manually, how stale can it be (Bloomberg data vintage)? |
| StatusID | Hardcoded to 1 in SP_Dim_Instrument for all real rows. Was this column ever meaningful (i.e., did it once reflect a lifecycle status), or was it always a placeholder? Should it be deprecated from the schema? |
| PipDifferenceThreshold | Upstream wiki says this is a price-validation threshold. Confirm: is it applied per-instrument and does NULL mean "no threshold applies" or "use system default"? |
| OperationMode | Upstream wiki says 0=Standard, 1=Alternate (~83 instruments, primarily European CFDs). Confirm the current count of mode=1 instruments and whether any mode values beyond 0 and 1 exist. |

## Structural Questions

| Question |
|----------|
| SP_Dim_Instrument ends by calling SP_Dim_Instrument_Snapshot @dt. Is there a risk of the snapshot failing silently (no error propagation)? If SP_Dim_Instrument_Snapshot fails, is the master ETL job aware? |
| UpdateDate and InsertDate are both set to GETDATE() in the same SP run, making them identical. Is InsertDate intended to be set once (on first creation of the row) and preserved across future reloads? If so, the current TRUNCATE + INSERT pattern destroys this intent. |
| IsFuture is computed via InstrumentGroups GroupID=25. If an instrument is removed from GroupID=25, the flag changes on next reload (it is not history-tracked). Is this acceptable for any downstream consumer that expects IsFuture to be immutable once set? |
| The table contains 15,707 rows but the InstrumentID range goes up to ~21 million. What happened to the gaps (legacy IDs, deleted instruments, retired pairs)? Are retired instruments excluded from GetInstrument or simply never inserted in the first place? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
