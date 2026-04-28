# Review Needed: BI_DB_dbo.BI_DB_CIDFunnelFlow

## Tier 3 Items — Require Human Review

### POA_POI_Phone (Column #26)
- **Issue**: Column exists in DDL (`[POA_POI_Phone] [int] NULL`) but is NOT included in the SP_CIDFunnelFlow INSERT column list. Always NULL.
- **Question**: Was this column intended to combine POA + POI + PhoneVerified? Should the SP be updated to populate it, or should the column be dropped from the DDL?
- **Current tier**: Tier 3 — DDL only, not populated.

## Verification Questions

### DepositAttempt vs FTD semantics
- **Observation**: `DepositAttempt` checks for approved deposits (PaymentStatusID=2) in Fact_BillingDeposit, while `FTD` checks if FirstDepositDate > '19000101' from Dim_Customer. These are different signals — DepositAttempt requires an approved record in the billing table, FTD relies on the Dim_Customer FTD flag. In edge cases (e.g., FTD recovery dates, data timing), they may disagree.
- **Question**: Is this intentional? Should DepositAttempt also check non-approved attempts (e.g., pending/declined)?

### ConvOver96H for non-depositors
- **Observation**: When FirstDepositDate = '19000101', DATEDIFF(hh, RegisteredReal, '19000101') produces a large negative value, so ConvOver96H = 0 for non-depositors. This means ConvOver96H only meaningfully applies to customers who have deposited.
- **Question**: Confirm this is the intended behavior — ConvOver96H should be interpreted as "depositor who took more than 96 hours", not "customer who has been waiting 96+ hours without depositing".

### State limited to US only
- **Observation**: The SP only populates RegionID when CountryID=219 (United States). All non-US customers have NULL State, even countries with states/provinces in Dim_State_and_Province (e.g., Canada, Australia).
- **Question**: Is this intentional? Should other countries with state-level regulation (e.g., Australia) also have State populated?

## UC Target Resolution
- UC target, format, partition, and table type are pending resolution during write-objects phase.
