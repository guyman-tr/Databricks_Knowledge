# BI_DB_KYC_eToroMoney_UpgradedClubMembers — Review Needed

## Tier 4 / Uncertain Items

1. **Card exclusion intent**: SP filters `NOT (AccountProgramID = 1)` — Card program members are excluded from the feed. Program=NULL (no eMoney account) is included. Confirm with compliance/BI whether Card exclusion is intentional (Card holders have a separate KYC feed) or a legacy filter that should be revisited.

2. **OldClub_Name always = 'Bronze'**: The SP constrains `LastTier = 1` (Bronze), so OldClub_Name will always be 'Bronze'. This makes the column redundant in practice. Confirm whether this hard constraint is intended for the feed or if Silver/Gold upgrades are routed elsewhere.

3. **IDENTITY gap behavior**: ID is IDENTITY(1,1) on a HEAP table with DELETE+re-INSERT. Each daily reload creates a new ID sequence block; IDs from deleted rows are permanently lost. Confirm that no downstream system joins on ID — it should not be used as a stable foreign key.

4. **MarketingRegionManualName (T3)**: Sourced from Ext_Dim_Country via Dim_Country. Quality is Tier 3 (manual override table, not from core Dictionary). Confirm with BI/Data team whether this field is required for the compliance feed or is legacy/convenience.

5. **PII sensitivity**: Table contains customer address fields (BuildingNumber, Address, City, Zip, Country_Abbreviation) plus CID/GCID. Confirm with data governance whether this table is classified under GDPR/PII access controls and whether UC migration will require column masking or access grants beyond standard.

6. **eMoney_Account_Mappings join coverage**: The SP uses LEFT JOIN to eMoney_Account_Mappings — rows without an eMoney account get Program=NULL. Verify whether NULL is valid for the FCA compliance feed or whether it should be filtered out before delivery.

## No Review Needed
- Table name, distribution, index: confirmed from DDL (ROUND_ROBIN, HEAP)
- UK-only filter (CountryID=218): confirmed from SP code
- Bronze upgrade filter (IsUpgrade=1, LastTier=1): confirmed from SP code
- Row count, date range: confirmed via MCP (146,580 rows, 2022-02-13 to 2026-04-12)
- T1 column descriptions (CID, GCID, BuildingNumber, Address, City, Zip): verbatim from Dim_Customer upstream wiki
- Country_Abbreviation T1: verbatim from Dim_Country upstream wiki
