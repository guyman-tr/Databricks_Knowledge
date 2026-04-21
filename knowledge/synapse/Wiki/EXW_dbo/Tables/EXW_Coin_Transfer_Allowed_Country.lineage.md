---
object: EXW_dbo.EXW_Coin_Transfer_Allowed_Country
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_Coin_Transfer_Allowed_Country

## ETL Chain

```
EXW_Settings.Resources (ResourceId=5903 — "redeem/allow" resource family)
EXW_Settings.SystemRestrictions (SelectedValue, RestrictionWeight, TagId per ResourceId)
EXW_Settings.Tags (TagType, TagValue — classification and matching value for each restriction)
  |
  | Tag matching logic: CountryAndRegion > PlayerLevelAndCountry > Country > RegulationGroup >
  | GeoRegistrationDate > Default (resolved by max RestrictionWeight)
  |
  + DWH_dbo.Dim_Country (CountryID, Country name, Region)
  + DWH_dbo.Dim_State_and_Province (StateProvince, RegionByIP_ID — USA only)
  + DWH_dbo.Dim_PlayerLevel (PlayerLevelID, Club name)
  + DWH_dbo.Dim_Regulation (RegulationID, Regulation name)
  + EXW_Wallet.CryptoTypes (CryptoID, InstrumentId, Name — active, non-eToro cryptos only)
  + CopyFromLake.SettingsDB_Dictionary_CountryGroup (GeoRegistrationDate group membership)
    |
    | SP_EXW_WalletElligibleCountries (no date parameter — full rebuild via TRUNCATE + INSERT)
    | Coin Transfer part (lines ~954–976)
    | Cross-joins country × playerLevel × regulation × crypto to build all combinations
    | Resolves per-row SelectedValue by highest RestrictionWeight match
    | Derives [Coin Transfer Allowed] = 1 if LOWER(SelectedValue)='true', else 0
    v
EXW_dbo.EXW_Coin_Transfer_Allowed_Country
    |
    | consumed by:
    +-- SP_EXW_CompensationClosingCountries (via SELECT * FROM EXW_Coin_Transfer_Allowed_Country ectac —
    |    used to derive final redeem eligibility in the companion EXW_ReimbursementFollowUp pipeline)
    +-- EXW_dbo.EXW_WalletElligibleCountries (sibling output of same SP, different resource)
    +-- BI/reporting consumers (external — not tracked in SSDT)
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | Country | T2 | DWH_dbo.Dim_Country | Name | Passthrough; no upstream wiki for DWH_dbo.Dim_Country |
| 2 | CountryID | T2 | DWH_dbo.Dim_Country | CountryID | HASH distribution key; passthrough |
| 3 | Club | T2 | DWH_dbo.Dim_PlayerLevel | Name | Player level name passthrough; 7 values: Bronze, Platinum, Gold, Internal, Silver, Platinum Plus, Diamond |
| 4 | PlayerLevelID | T2 | DWH_dbo.Dim_PlayerLevel | PlayerLevelID | Passthrough |
| 5 | InstrumentID | T1 | EXW_Wallet.CryptoTypes (mirrors Wallet.CryptoTypes) | InstrumentId | Passthrough; type widened from int to bigint in target DDL; renamed from InstrumentId |
| 6 | CryptoID | T1 | EXW_Wallet.CryptoTypes (mirrors Wallet.CryptoTypes) | CryptoID | Passthrough |
| 7 | Crypto | T1 | EXW_Wallet.CryptoTypes (mirrors Wallet.CryptoTypes) | Name | Passthrough; renamed from Name; type narrowed from varchar(max) to nvarchar(256) |
| 8 | ResourceName | T2 | EXW_Settings.Resources | ResourceName | Constructed as 'redeem/allow/<InstrumentId>' or 'redeem/allow/crypto'; identifies the crypto-specific or general coin-transfer resource |
| 9 | SelectedValue | T2 | EXW_Settings.SystemRestrictions | SelectedValue | Raw settings value ('true'/'false') before SP boolean transform; LOWER() applied for comparison |
| 10 | TagType | T2 | EXW_Settings.Tags | TagType | Classification of the settings tag that produced this row (e.g., 'Default', 'Country', 'RegulationGroup', 'PlayerLevelAndCountry', 'GeoRegistrationDate', 'CountryAndRegion', 'CountryAndDesignatedRegulation', 'CountryRegionAndRegulation', 'CountryAndRegulation') |
| 11 | TagValue | T2 | EXW_Settings.Tags | TagValue | Specific tag value matched (e.g., 'united_states', 'RegulationGroup_4', 'bronze_united_states'); lowercase-normalized in matching |
| 12 | RestrictionWeight | T2 | EXW_Settings.SystemRestrictions | RestrictionWeight | Max weight across all matching tags for this CountryID+PlayerLevelID+CryptoID+RegulationID+RegionByIP_ID combination; higher = higher priority |
| 13 | Coin Transfer Allowed | T2 | ETL-computed | — | SP-derived: CASE WHEN LOWER(SelectedValue)='true' THEN 1 ELSE 0 END; 1=coin transfer (withdrawal/redemption) permitted; 0=blocked |
| 14 | UpdateDate | T2 | ETL-computed | — | GETDATE() at SP execution time; nullable in DDL (unlike UpdateDate in most EXW_dbo tables) |
| 15 | RegulationID | T2 | DWH_dbo.Dim_Regulation | DWHRegulationID | Regulatory jurisdiction ID; passthrough |
| 16 | Regulation | T2 | DWH_dbo.Dim_Regulation | Name | Regulatory jurisdiction name (e.g., 'CySEC', 'FCA', 'ASIC', 'BVI', 'NFA'); passthrough |
| 17 | StateProvince | T2 | DWH_dbo.Dim_State_and_Province | Name | US state/province name; NULL for all non-US rows (CountryID≠219) |
| 18 | RegionByIP_ID | T2 | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | IP-geolocation region ID for US states; NULL for all non-US rows |

## Tier Summary

- **Tier 1**: 3 columns — InstrumentID, CryptoID, Crypto — sourced verbatim from EXW_Wallet.CryptoTypes (mirrors Wallet.CryptoTypes, wiki at CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md)
- **Tier 2**: 15 columns — EXW_Settings (no upstream wiki), DWH_dbo dimensions (no upstream wiki), ETL-computed
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_Coin_Transfer_Allowed_Country
- **UC Target**: `_Not_Migrated` (no UC mapping found — settings-derived eligibility reference, Synapse-only)
