# BI_DB_AML_SubEntity_Categorization — Review Notes

**Object**: BI_DB_dbo.BI_DB_AML_SubEntity_Categorization
**Batch**: 15 | **Date**: 2026-04-21 | **Reviewer Needed**: AML Compliance team

## Tier 4 Items / Reviewer Questions

1. **AML_Sub_Entity nvarchar(max)**: The SP uses STRING_AGG producing comma-separated entity labels. The column allows max length. In practice, the longest observed value is "eToro_Germany, eToro_Money_Malta" (~34 chars). Consider if a normalized 4-flag boolean design would serve downstream consumers better — currently requires LIKE-based filtering.

2. **eToro_Germany dual-trigger ambiguity**: The Germany population is triggered by either HasWallet=1 OR real crypto positions yesterday. The AML_Sub_Entity label does not differentiate which trigger applied. If the AML report needs to know "wallet-holder" vs "crypto-trader" Germany customers separately, the current design cannot support it without re-running the SP.

3. **EEA/EU country hardcoded list**: Step 07 uses a hardcoded list of 37 DWHCountryIDs for EEA/EU countries. If EU membership changes (e.g., new country joins), this list requires a manual SP update. Reviewer: confirm this list is current and aligned with compliance expectations.

4. **eToro_Money_Malta VerLevel=3 requirement**: The Malta population uses `VerificationLevelID = 3` (stricter than other populations at ≥2). Only 17 rows in the table have VerLevel=2 (all non-Malta entities). Reviewer: confirm this stricter requirement is intentional for MiCA/EU AML compliance.

5. **FCA + eToro_Gibraltar overlap**: FCA customers can qualify for eToro_Gibraltar (non-Germany + HasWallet). This means an FCA-regulated UK customer with a crypto wallet appears in Gibraltar entity, NOT Money_UK. The AML_Sub_Entity may show "eToro_Gibraltar, eToro_Money_UK" for such customers — is this the intended dual classification?

6. **SP does not filter IsValidCustomer in Step 04 (Gibraltar)**: The Gibraltar population in Step 04 omits the `dc.IsValidCustomer = 1` filter that is present in Step 01 (Germany). This may include test or invalid accounts in the Gibraltar population. Verify whether this is intentional.

## Cross-Object Consistency Notes

- CID/GCID descriptions match DWH_dbo.Dim_Customer.md verbatim — CONSISTENT.
- RegulationID values (1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML) confirmed from live distribution query.

## No Issues

- File encoding: UTF-8 (explicitly set)
- All 9 columns documented with tier suffixes
- ETL pipeline ASCII diagram present
- All section headers (1–8) present
