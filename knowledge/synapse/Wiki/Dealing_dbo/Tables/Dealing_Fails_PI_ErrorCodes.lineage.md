# Column Lineage: Dealing_dbo.Dealing_Fails_PI_ErrorCodes

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Fails_PI_ErrorCodes` |
| **UC Target** | `general.dealing_dbo.dealing_fails_pi_errorcodes` |
| **Primary Source** | Static reference data (eToro platform error code registry) |
| **ETL SP** | No automated ETL SP identified — maintained manually or via ad-hoc script |
| **Secondary Sources** | None |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
eToro platform error code registry (static definition)
  → Manual population / ad-hoc load
  → Dealing_dbo.Dealing_Fails_PI_ErrorCodes (234 rows, static lookup)
  ← Referenced by: SP_Fails_PI (LEFT JOIN ON ErrorCode)
```

## Column Lineage

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| ErrorCode | Platform registry | error_code | passthrough | Direct: numeric error code | Integer key; 234 defined codes (0=NO_ERROR through platform-specific codes) |
| FailReason | Platform registry | error_name | passthrough | Direct: symbolic constant name | Snake-case symbolic name (e.g., INSUFFICIENT_FUNDS_ERROR, WRONG_PARAMS_ERROR) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Total** | 2 |
