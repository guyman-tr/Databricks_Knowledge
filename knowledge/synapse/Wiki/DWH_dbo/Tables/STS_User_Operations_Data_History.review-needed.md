# Review Sidecar — DWH_dbo.STS_User_Operations_Data_History

## Unverified Claims (Tier 3-4)

| # | Column | Claim | Tier | Reason | Suggested Verification |
|---|--------|-------|------|--------|----------------------|
| 1 | ProxyType | "Type of proxy detected for the client IP connection" | T3 | Inferred from column name + NULL prevalence in sample; no source documentation | Query non-NULL ProxyType values to confirm semantics |
| 2 | CountryISOCode | "ISO country code resolved from ClientIp" | T3 | Inferred from column name + NULL prevalence; could also be from user profile | Cross-check with Dim_CountryIPAnonymous to confirm IP-based resolution |
| 3 | AdditionalData | "Extensible JSON or free-text field" | T3 | No non-NULL values observed in sample | Query for non-NULL AdditionalData to characterize content |

## Open Questions

1. **Row count**: `COUNT_BIG(*)` query failed due to MCP connection drop. The table clearly holds billions of rows based on partition scheme (daily since 2021-08), but exact count is unverified.
2. **Gold pipeline status**: Confluence says the Gold data lake path was "cancelled" — but Generic Pipeline ID 459 still maps it as active daily Append. Is the UC table still receiving data?
3. **Three late columns**: DSM-598 added ProxyType, CountryISOCode, AdditionalData — but they are overwhelmingly NULL in the sample (which includes 2021-2022 data). Are they populated in newer partitions (2024+)?
4. **ClientDeviceId truncation**: Column is nvarchar(50) but UUIDs in sample appear truncated (e.g. `3c24d4e9-8ef0-405f-b7f6-50abc5`). Is the truncation at source or in DWH? The view widens it to NVARCHAR(MAX) suggesting awareness.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
