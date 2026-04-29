# Review Needed: DWH_dbo.Dim_CardType

## Items for Human Review

### 1. IsActive Value Divergence from Production
- **Issue**: DWH shows CardTypeID 0 ("None") as IsActive=1, but upstream wiki states IsActive=0 for CardTypeID 0. Similarly, Maestro (8) is IsActive=0 in DWH but IsActive=1 in upstream wiki.
- **Impact**: Downstream SPs filtering on IsActive may produce different results than production queries.
- **Action needed**: Confirm whether the DWH values represent a deliberate historical snapshot or an error.

### 2. Column Name Typo: CarTypeName
- **Issue**: Column is named `CarTypeName` (missing "d") instead of `CardTypeName`. The production source column is `Name`.
- **Impact**: Cosmetic only — all downstream SPs use this exact name. Renaming would break consumers.
- **Action needed**: Document as known quirk. No rename recommended.

### 3. Missing Card Types (18 of 32)
- **Issue**: DWH contains only CardTypeIDs 0–17 (18 rows). Production Dictionary.CardType has 32 entries per the upstream wiki.
- **Impact**: If deposits reference CardTypeIDs 18–31, JOINs to this dimension will return NULL.
- **Action needed**: Verify whether CardTypeIDs 18+ exist in any DWH fact table deposits.

### 4. Stale Data (No Refresh Since 2019)
- **Issue**: All 18 rows have UpdateDate = 2019-06-30. The table is exported daily via Generic Pipeline (Override), but the source data has not been refreshed since the initial migration load.
- **Impact**: Any new card types added in production since 2019 are missing from the DWH.
- **Action needed**: Determine if this table should be connected to SP_Dictionaries_DL_To_Synapse for ongoing refresh.

### 5. Missing Is3dsOn Column
- **Issue**: Production Dictionary.CardType has an `Is3dsOn` column (3D Secure flag) that is not carried into the DWH dimension.
- **Impact**: Any DWH-side analysis requiring 3DS status must query production directly.
- **Action needed**: Evaluate whether Is3dsOn should be added to the DWH dimension.
