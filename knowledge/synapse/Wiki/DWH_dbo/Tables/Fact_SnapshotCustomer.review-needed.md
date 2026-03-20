# DWH_dbo.Fact_SnapshotCustomer - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Current Description | Question |
|--------|--------------------|---------:|
| DemoCID | Legacy: demo account CID linked to this real customer. Not populated by current SP. | Was DemoCID ever populated in production? Is it intentionally deprecated or a migration gap? Should it be dropped? |
| CustomerChangeTypeID | Legacy: type of SCD2 change that created this row. Not populated by current SP. | Was this populated before 2018 (Boris SP rewrite)? Is it safe to ignore entirely? |
| CurentValue | Legacy: current value of changed attribute (pairs with CustomerChangeTypeID). Typo in column name. | Same question as CustomerChangeTypeID — deprecated? Populated in history rows? |
| PreviousValue | Legacy: previous value of changed attribute. Not populated by current SP. | Deprecated? |
| DocsOK | Legacy: documents verified flag. Not populated by current SP. DEFAULT 0. | Replaced by DocumentStatusID? Can this column be ignored entirely? |
| Bankruptcy | Legacy: bankruptcy flag. Not populated by current SP. DEFAULT 0. | Still meaningful for old history rows? Replaced by what column? |
| PremiumAccount | Legacy: premium account flag. Not populated by current SP. DEFAULT 0. | Replaced by AccountTypeID or another concept? |
| Evangelist | Legacy: ambassador/evangelist flag. Not populated by current SP. DEFAULT 0. | Still meaningful for old rows? Active program concept? |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| WeekendFeePrecentage | Column name has typo ("Precentage"). What values does it take? Is 0 "no weekend fee"? Is it a percentage (e.g., 50 = 50%) or a basis points value? |
| StocksLendingStatusID | What are the valid status values and their meaning? Is NULL equivalent to "not enrolled"? |
| DltStatusID | What are the valid DltStatusID values? DLT = Distributed Ledger Technology (Tangany wallet) — confirmed? |
| PhoneVerificationDateID | Why is this varchar(8) instead of int like other DateIDs? Can it ever be non-YYYYMMDD (e.g., empty string)? |
| EquiLendID | varchar(4000) seems very large for an identifier. Is it actually a JSON blob or array? |
| RegionID | What dimension table or lookup does RegionID correspond to? No Dim_Region table found in schema. |
| SuitabilityTestStatusID | What are the valid values and their business meaning? Is 0 "not tested" or "N/A"? |

## Structural Questions

| Question |
|----------|
| The SP uses two different load paths: DATEADD(yy...) = @date (Jan 1) inserts without MERGE; else MERGE. Are there known edge cases or incidents with the Jan 1 close/reopen logic? |
| CampaignID appears in the #CCTemp temp table (source) but is NOT inserted into Fact_SnapshotCustomer. Was CampaignID intentionally excluded? Is it available elsewhere (e.g., Dim_Campaign)? |
| Is V_Fact_SnapshotCustomer_FromDateID the correct UC-accessible view to use in Databricks, or is V_Fact_SnapshotCustomer preferred for something? |
| AccountStatusID has only 3 distinct values (0, 1, 2) in production. Is 0 truly a valid business state or is it a data quality issue (should be DEFAULT 1)? |
| DltID is nvarchar(100) but EquiLendID is varchar(4000). Both are external platform IDs — is the size difference intentional? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
