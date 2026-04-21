# Review Needed: eMoney_dbo.eMoney_Country_Codes_Mapping_ISO

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Static Reference)

## Status

No critical Tier 4 items. Manually maintained ISO 3166-1 reference table with no automated refresh. Key risk: unmapped country codes cascade nulls into fact and risk scoring pipelines.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | No automated refresh | WARN | Table was manually bulk-loaded 2024-06-24. If ISO 3166-1 is updated or if FiatTransactions introduces new country codes not in ISO, this table will have gaps. Schedule periodic review of unmapped codes. |
| 2 | Null eToroDWHCountryID rows | WARN | Any country present in ISO 3166-1 but not yet mapped to DWH_dbo.Dim_Country will have null eToroDWHCountryID. Transactions from such countries will produce null in the fact table and fail HRC scoring. Confirm completeness of DWH country dimension mapping. |
| 3 | Leading-zero numeric codes | INFO | CountryNumericCode_ISO is varchar(20). Codes like '004' (Afghanistan) require consistent zero-padding in join keys. Confirm FiatTransactions stores numeric country codes with the same padding. |
| 4 | SP_eMoney_Customer_Risk_Assessment dependency | INFO | This table is a hard dependency for HRC scoring. If a customer's country code is unmapped, risk scoring will produce null or error. Monitor SP error logs for unmapped country code warnings. |

## Reviewer Confirmation Needed

- [ ] Run unmapped code check: compare FiatTransactions.TransactionCountryIso values against CountryNumericCode_ISO — confirm 0 gaps
- [ ] Confirm all DWH countries referenced by eMoney have non-null eToroDWHCountryID in this table
- [ ] Confirm SP_eMoney_Customer_Risk_Assessment handles null eToroDWHCountryID gracefully
- [ ] Schedule periodic ISO 3166-1 refresh review (e.g., annually)

*Sidecar generated: 2026-04-21 | Quality: 8.8/10 | Phases completed: P1, P2, P3, P5, P6, P8, P10B, P11*
