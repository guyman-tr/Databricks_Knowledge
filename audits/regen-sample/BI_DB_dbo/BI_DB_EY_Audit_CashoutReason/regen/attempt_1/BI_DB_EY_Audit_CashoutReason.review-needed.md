# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_CashoutReason

## Items for Human Review

### 1. ExternalID Type Mismatch
- **Column**: ExternalID
- **Issue**: In Dim_Customer, ExternalID is `decimal(38,0)`. In this table it is `varchar(200)`. The SP selects `dc1.ExternalID` without explicit CAST — implicit conversion from decimal to varchar occurs. Confirm this is intentional and no precision is lost for very large APEX IDs.

### 2. FundingTypeID_Funding vs FundingTypeID_Withdraw
- **Column**: FundingType
- **Issue**: The SP joins `Dim_FundingType ON dft.FundingTypeID = effbw.FundingTypeID_Funding` (the funding instrument's payment method, not the withdrawal request's method). Confirm this is the intended behavior for audit purposes. If auditors expect the withdrawal request method, the join should use `FundingTypeID_Withdraw` instead.

### 3. No Primary Key or Unique Index
- **Issue**: The table has no enforced PK, unique constraint, or clustered index. The combination (WithdrawID, WithdrawPaymentID) appears to be a natural key but is not enforced. If duplicate rows are a concern for audit integrity, consider adding a constraint or unique NCI.

### 4. LEFT JOIN on Dim_GuruStatus and Dim_FundingType
- **Issue**: GuruStatusName and FundingType use LEFT JOINs, so NULL values are possible if the FK value has no match in the dimension. All other dimensions use INNER JOINs. Confirm NULL handling is acceptable for audit reporting.

---

*Generated: 2026-04-29*
