# DWH_dbo.Fact_BillingDeposit -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All 138 columns have Tier 1 (upstream wiki Billing.Deposit) or Tier 2 (SP code) descriptions.

## Columns Needing Clarification

1. **`v` column**: An XML-extracted column with no descriptive name — appears to be an artifact of the XML attribute name in PaymentData/FundingData. What does this field contain? Is it intentional or a schema residue?
2. **`IsAftProcessedAsBool` source**: Documented as "Sourced from Billing.Funding or Billing.Deposit" — the SP may read this from either source depending on the deposit. Confirm the exact logic.
3. **`ExpirationDateID` formula**: The SP computes this via a complex formula from the `ExpirationDateAsString` XML field. Confirm the formula correctly handles all expiry date formats (MM/YY, MMYY, YYYY-MM, etc.) and sentinel values for non-card deposits.
4. **`PlatformIDAsInteger` vs `PlatformID`**: Two platform-related columns exist — `PlatformIDAsInteger` (XML-extracted string) and `PlatformID` (2nd-pass UPDATE from Fact_CustomerAction). Confirm intended use for each and whether they ever conflict.
5. **`BankName` and `CardCategory`**: These XML-extracted columns are `varchar(100)` and `varchar(50)` respectively — not `nvarchar(max)` like other XML columns. Confirm this is intentional and the length is sufficient.

## Structural Questions

1. **PlatformID NULL rate**: What percentage of Fact_BillingDeposit rows have NULL PlatformID? If session-action matching fails frequently, this affects platform breakdown analytics. Confirm acceptable NULL tolerance.
2. **Amount capping (2025-04-17)**: What is the cap threshold in the CASE expression? Is the cap value documented anywhere? Analysts using raw Amount values should be aware of this ceiling.
3. **2-pass ETL timing**: Pass 1 loads from staging; Pass 2 (`@Yesterday`) updates PlatformID. Is there a race condition risk if Pass 2 runs before Fact_CustomerAction is fully refreshed? What is the dependency order in the orchestration?
4. **73.9M rows / rolling window**: Confirm the rolling window size (how many days of ModificationDate does each ETL run cover?). If the window is too narrow, deposits that took several days to process may be missed.
5. **Ext_FBD_Fact_BillingDeposit**: This intermediate table is used as a staging buffer before the final Fact_BillingDeposit insert. Confirm whether this table is accessible to analysts or intended for ETL use only.
6. **ThreeDsAsJson vs ThreeDsResponseType**: `ThreeDsAsJson` stores raw 3DS data; `ThreeDsResponseType` stores the outcome integer as a string. Confirm whether `ThreeDsAsJson` is used downstream or is informational only.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
