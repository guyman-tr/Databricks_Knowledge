# EXW_dbo.EXW_Conversion_Allowed_Country — Review Needed

## 1. Dormant / Deactivated Activity

- **Priority**: Medium
- **Issue**: The SP change history (2026-04-14) states conversion activity is "not active" and tables are kept but no longer re-filled. All 51,642 rows show `AllowedUserSelectedValue='false'` and `FromConversionAllowed=0`, `ToConversionAllowed=0`. Confirm whether this table should be deprecated or if conversion may be reactivated.
- **Action**: Check with the EXW team (Inessa K) whether this table is still used by any downstream application or API.

## 2. No UC Migration

- **Priority**: Low
- **Issue**: Table is not in the generic pipeline mapping (`_generic_pipeline_mapping.json`). No Unity Catalog target exists. Given the dormant status, UC migration may be intentionally skipped.
- **Action**: Confirm whether this table should be migrated to UC or formally deprecated.

## 3. EXW_Settings Source Tables — No Wiki Coverage

- **Priority**: Low
- **Issue**: The source tables `EXW_Settings.Resources`, `EXW_Settings.Tags`, and `EXW_Settings.SystemRestrictions` have no wiki documentation. These are external to Synapse (likely production EXW database). The restriction-weight resolution logic is complex and documented only from SP code analysis.
- **Action**: If EXW_Settings wiki documentation becomes available, upgrade AllowedUser*/From*/To* columns from Tier 2 to Tier 1.

## 4. EXW_Wallet.CryptoTypes — No Wiki Coverage

- **Priority**: Low
- **Issue**: `EXW_Wallet.CryptoTypes` is the source for CryptoID and Crypto columns but has no wiki. Column descriptions are grounded in SP code analysis only.
- **Action**: If CryptoTypes wiki is created, upgrade CryptoID and Crypto from Tier 2 to Tier 1.

## 5. Sibling Eligibility Tables

- **Priority**: Informational
- **Issue**: SP_EXW_WalletElligibleCountries also populates `EXW_Payment_Allowed_Country`, `EXW_Staking_Allowed_Country`, `EXW_Coin_Transfer_Allowed_Country`, and others. These tables follow the same pattern. Wikis for sibling tables should be consistent.
- **Action**: When documenting sibling tables, reuse the tag-priority resolution logic description from this wiki.
