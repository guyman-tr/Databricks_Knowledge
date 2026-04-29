# BI_DB_QTFN_Report — Review Notes

**Object**: BI_DB_dbo.BI_DB_QTFN_Report
**Batch**: 15 | **Date**: 2026-04-26 | **Reviewer Needed**: ASIC Compliance team / Finance

## Tier 4 Items / Reviewer Questions

1. **Dummy TFN '987654321' for non-individual entities**: SMSF (S) and Corporate (C) entities receive a fixed TFN of '987654321'. Reviewer: is this an ATO-recognized placeholder value, or should these entities have their actual TFN sourced from a different field? If this value appears in ATO submissions, confirm it will not trigger validation errors or be misinterpreted as a real TFN.

2. **ABN placeholder logic**: Individual investors get '00000000000' (11 zeros) as their ABN, while S/C entities get the literal string 'ABN'. Reviewer: the ATO QTFN format likely expects either a valid 11-digit ABN or a specific exemption code. Are these placeholder values accepted by the ATO lodgement system, or do they need to be replaced with actual ABNs before submission?

3. **State abbreviation mapping accuracy**: The SP contains a 130+ entry CASE statement mapping full state/province names to abbreviations. This is a maintenance risk — new states, renamed provinces, or typos in Dim_State_and_Province.Name will fall through to NULL or an incorrect mapping. Reviewer: has this mapping been validated against the current Dim_State_and_Province reference data? Are there unmapped entries producing NULL State_or_territory values?

4. **PII handling compliance**: This table contains Australian Tax File Numbers, names, addresses, and dates of birth. Reviewer: confirm that access controls (row-level security, column masking, or restricted role access) are in place for this table in both Synapse and any downstream exports. TFN data is subject to the Australian Taxation Administration Act 1953 secrecy provisions.

5. **'Other' entity type handling**: 77 rows have Investor_entity_type = 'Other' (neither I, S, nor C). These get ABN = 'Other' and Non_individual_investor_name = 'Other'. Reviewer: what AccountTypeIDs produce this classification? Should these customers be excluded from the ATO submission, or do they need manual classification?

6. **No date partitioning / no history**: The table uses TRUNCATE+INSERT with no date column for incremental processing. Each run destroys all previous data. If historical QTFN snapshots are needed for audit trails, there is currently no mechanism to preserve them. Reviewer: is a historical audit trail required for ATO compliance?

7. **Postcode stripping may produce invalid results**: The stripping logic removes all letters, dashes, and spaces from Zip. For non-Australian addresses (Country_fin != Australia), this could produce meaningless numeric strings. For Australian addresses with malformed Zip data, the result may not be a valid 4-digit postcode. Reviewer: are there validation checks downstream before ATO submission?

## No Issues

- All 39 columns documented with Tier 2 suffixes (all SP-computed or constant)
- Entity type classification logic (I/S/C/Other from AccountTypeID) confirmed from SP
- PII masking for non-individual entities (spaces for S/C name and DOB fields) documented
- TRUNCATE+INSERT refresh pattern documented
- Population filter (RegulationID IN 4,10, VL3, CountryID=12) confirmed
