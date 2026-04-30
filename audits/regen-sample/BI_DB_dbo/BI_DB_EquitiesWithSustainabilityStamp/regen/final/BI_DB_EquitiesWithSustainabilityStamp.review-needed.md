# Review Needed — BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp

## 1. Tier 3 Columns (no upstream wiki)

| Column | Reason | Suggested Action |
|--------|--------|-----------------|
| Ticker | Sourced from Fivetran Google Sheet (`External_Bi_Output_Uploads_QSR_Sustainability_List`). No wiki exists for this external table. | Confirm with QSR team whether column semantics are documented elsewhere. |
| ISIN | Same external source — no wiki. ISIN is a standard identifier so description is high-confidence. | Low priority — standard financial identifier. |
| Name | Same external source — no wiki. Company display name. | Low priority — self-explanatory column. |

## 2. Data Freshness Concern

- All 218 rows have `UpdateDate = 2024-01-30`. The table has not been refreshed in over 2 years.
- SP header (authored by Guy Manova, 2020-07-27) notes: "in the future it will be implemented in the DB."
- **Action**: Verify with QSR/Sustainability team whether this table is still actively used or has been superseded by a production-DB implementation.

## 3. Unresolved External Source

- `BI_DB_dbo.External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp` is a Fivetran-synced external table. No DDL found in SSDT repo. No wiki exists.
- The Google Sheet is the ultimate source of truth for the sustainability stamp list.
- **Action**: Document the Google Sheet URL and owner if known.

## 4. UC Migration Status

- This table is NOT in the Generic Pipeline mapping — no UC target exists.
- **Action**: Determine if this table needs UC migration or if the sustainability stamp will be implemented differently in the new platform.

## 5. INNER JOIN Gap

- The SP uses an INNER JOIN to Dim_Instrument on ISINCode = ISIN. Equities in the Google Sheet whose ISIN does not match any Dim_Instrument row are silently dropped.
- **Action**: Consider whether a LEFT JOIN with NULL InstrumentID tracking would be more appropriate for audit purposes.
