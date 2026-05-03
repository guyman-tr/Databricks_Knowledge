# Review Needed: BI_DB_dbo.BI_DB_Social_Activity

## Items for Human Review

### 1. Data Pipeline Dormancy

The table's last loaded ActionDateID is 20250904 (September 4, 2025). As of April 2026, no new data has been loaded for ~8 months. This may indicate:
- The pipeline was intentionally decommissioned or migrated
- The Streams microservice data source was replaced
- A pipeline failure that was never resolved

**Action**: Confirm whether SP_Social_Activity is still scheduled or has been retired.

### 2. Streams_dbo_Entries_Social_Activity_Daily — No Upstream Wiki

The primary data source (`Streams_dbo_Entries_Social_Activity_Daily`) is an external table dynamically created by `SP_Create_External_Streams_dbo_Entries_Range`. No wiki or schema documentation exists for the underlying Streams microservice. All columns sourced from it are Tier 2 (traced from SP code).

**Action**: If Streams microservice documentation exists, link it to improve tier coverage.

### 3. MediaTypeID Values Undocumented

The column `MediaTypeID` (from Streams `RichMediaScrapDataType`) has observed values 5 and 6 but no lookup table or documentation for what these values represent. The vast majority of rows have NULL.

**Action**: Identify the meaning of MediaTypeID values (5, 6, and any others) from the Streams service team.

### 4. ActionTypeID Naming Collision with BI_DB_Social_Activity_Type

The lookup table `BI_DB_Social_Activity_Type` uses `ActionID` as its PK column, not `ActionTypeID`. This creates a naming confusion: `BI_DB_Social_Activity.ActionTypeID` joins to `BI_DB_Social_Activity_Type.ActionID`. This is a schema design oddity, not a bug.

### 5. GDPR Tables

Multiple GDPR-related tables exist (`BI_DB_Social_Activity_GDRP_PostsComments`, `_LikesOnPosts`, `_LikesOnComments`) along with `SP_Social_Activity_GDRP`. These handle right-to-erasure requests. The GDPR SP name contains a typo ("GDRP" instead of "GDPR") which is consistent across all related objects.

### 6. SubTypeName Values Beyond SP Filter

The SP only inserts rows where TypeName matches specific values (Discussion, CloseTrade, CopyCloseTrade, OpenOrder, OpenTrade, StartCopyTrader, StopCopyTrader, Comment, Like). Any other Streams TypeName values are silently excluded.

**Action**: Verify whether additional TypeName values exist in the Streams feed that should be captured.
