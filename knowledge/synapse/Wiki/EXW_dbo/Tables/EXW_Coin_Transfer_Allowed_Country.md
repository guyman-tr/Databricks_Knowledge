---
object: EXW_dbo.EXW_Coin_Transfer_Allowed_Country
type: Table
generated: 2026-04-20
schema: EXW_dbo
phase: 11
---

# EXW_dbo.EXW_Coin_Transfer_Allowed_Country

## 1. Object Summary

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Type** | Table |
| **Distribution** | HASH(CountryID) |
| **Index** | HEAP |
| **Row Count** | 1,746,164 |
| **UC Target** | `_Not_Migrated` — settings-derived eligibility reference; Synapse-only |
| **Primary Source** | SP_EXW_WalletElligibleCountries (Coin Transfer section, TRUNCATE + INSERT) |
| **Load Pattern** | Full rebuild on each SP run; no date parameter |
| **Downstream** | SP_EXW_CompensationClosingCountries (reads for redeem eligibility); BI consumers |

## 2. Business Purpose

`EXW_Coin_Transfer_Allowed_Country` is the **crypto withdrawal (coin transfer / redemption) eligibility matrix** for eToro's wallet platform. It materializes the Cartesian product of every active country × player level × regulation × crypto combination and resolves, for each combination, whether coin transfer (crypto withdrawal to an external blockchain address) is **permitted or blocked** based on current EXW_Settings configuration.

The table is populated by the Coin Transfer section of `SP_EXW_WalletElligibleCountries`, which reads `EXW_Settings.Resources`, `EXW_Settings.SystemRestrictions`, and `EXW_Settings.Tags` with `ResourceId=5903` (the "redeem/allow" resource family). Each row represents one unique eligibility determination for a (country, player level, regulation, crypto) tuple.

### Eligibility Resolution Logic

The SP resolves the effective `[Coin Transfer Allowed]` for each row using a **priority hierarchy** based on `RestrictionWeight` (higher = higher priority). Multiple tag types can match a given row; only the highest-weight matching tag applies:

| TagType | Priority | Example TagValue |
|---------|----------|-----------------|
| CountryRegionAndRegulation | Highest | `united_states_california_fincen` |
| CountryAndRegion | High | `united_states_california` |
| CountryAndDesignatedRegulation | High | `united_states_nfa` |
| PlayerLevelAndCountry | High | `diamond_united_kingdom` |
| CountryAndRegulation | Medium | `germany_cysec` |
| Country | Medium | `germany` |
| RegulationGroup | Medium | `RegulationGroup_4` |
| GeoRegistrationDate | Low | `GROUP:european_union` |
| Default | Lowest | `Default` |

### Key Data Gotchas

- **1.74M rows for 7 player levels × 59 cryptos × 250 countries × N regulations**: The row count is high because the table is a full combination matrix. A single change in EXW_Settings can affect hundreds of thousands of rows after the next SP run.
- **`[Coin Transfer Allowed]` = 0 by default** (when `SelectedValue` ≠ 'true'). Most rows return 0. The presence of a row does NOT imply permission — the column value determines eligibility.
- **`redeem/allow/crypto` vs `redeem/allow/{InstrumentId}`**: The SP creates two ResourceName variants per crypto — a generic 'crypto' key and an instrument-specific key. The 'crypto' rows (TagType often 'Default') act as a fallback when no instrument-specific setting exists.
- **US state granularity**: For CountryID=219 (United States), the table includes rows per state/province via `StateProvince` and `RegionByIP_ID`. Non-US rows have NULL for both.
- **`UpdateDate` is nullable**: Unlike most `UpdateDate` columns in EXW_dbo (which are NOT NULL), this column is nullable in the DDL. In practice, it is always set to GETDATE() by the SP.
- **`InstrumentID` type mismatch**: DDL declares `bigint`; source `EXW_Wallet.CryptoTypes.InstrumentId` is `int`. Type was widened in the DWH DDL for future-proofing.

## 3. ETL / Lineage Summary

```
EXW_Settings.Resources (ResourceId=5903 — "redeem/allow" resource family)
EXW_Settings.SystemRestrictions + EXW_Settings.Tags (eligibility rules with TagType + RestrictionWeight)
DWH_dbo.Dim_Country × DWH_dbo.Dim_PlayerLevel × DWH_dbo.Dim_Regulation × EXW_Wallet.CryptoTypes
  |
  | SP_EXW_WalletElligibleCountries (Coin Transfer part, ~lines 293–976)
  | TRUNCATE + INSERT full combination matrix
  | Resolves effective SelectedValue by max-weight tag match per combination
  v
EXW_dbo.EXW_Coin_Transfer_Allowed_Country
```

See [`EXW_Coin_Transfer_Allowed_Country.lineage.md`](./EXW_Coin_Transfer_Allowed_Country.lineage.md) for column-level lineage.

## 4. Column Definitions

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | Country | varchar(50) | YES | T2 | Country name from DWH_dbo.Dim_Country. Human-readable label for the country dimension. No upstream wiki for DWH_dbo dimensions. |
| 2 | CountryID | int | YES | T2 | Country identifier from DWH_dbo.Dim_Country. HASH distribution key. Excludes CountryID=0 (unknown/default). |
| 3 | Club | varchar(50) | YES | T2 | Player level name from DWH_dbo.Dim_PlayerLevel. One of 7 values: Bronze (1), Platinum (2), Gold (3), Internal (4), Silver (5), Platinum Plus (6), Diamond (7). Used in 'PlayerLevelAndCountry' tag matching for premium-user eligibility overrides. |
| 4 | PlayerLevelID | int | YES | T2 | Player level identifier from DWH_dbo.Dim_PlayerLevel. Excludes PlayerLevelID=0 (unknown/default). |
| 5 | InstrumentID | bigint | YES | T1 | Links to the eToro trading platform's instrument for this crypto (e.g., BTC=100000, ETH=100001). Used for market rate lookups and position valuation. Implicit reference to Wallet.Instruments.InstrumentId. Source: EXW_Wallet.CryptoTypes.InstrumentId (type widened from int to bigint in DWH DDL). |
| 6 | CryptoID | int | YES | T1 | Unique identifier for this crypto asset. Manually assigned (not IDENTITY). Referenced as FK by Wallet.SentTransactions, Wallet.ReceivedTransactions, Wallet.WalletBalances, Wallet.WalletAssets, Wallet.Conversions, Wallet.Payments, Wallet.AmlProviderContracts, Wallet.CryptoMarketRatesMappings, Wallet.PromotionTags, and many stored procedures. The most widely-referenced PK in the schema. Source: EXW_Wallet.CryptoTypes.CryptoID. |
| 7 | Crypto | nvarchar(256) | YES | T1 | Ticker symbol (e.g., BTC, ETH, USDT, LINK). Used for API parameter matching and internal identification. Source: EXW_Wallet.CryptoTypes.Name (renamed from Name; type narrowed from varchar(max) to nvarchar(256) in DWH DDL). |
| 8 | ResourceName | varchar(100) | YES | T2 | EXW_Settings resource identifier for the coin transfer eligibility rule. Pattern: 'redeem/allow/{InstrumentId}' for a crypto-specific rule, or 'redeem/allow/crypto' for the generic fallback rule that applies to all cryptos. ResourceId=5903 is the "redeem/allow" resource family. |
| 9 | SelectedValue | varchar(1000) | YES | T2 | Raw value from EXW_Settings.SystemRestrictions for the winning tag. Values: 'true' = coin transfer permitted; 'false' = coin transfer blocked. Lowercased before comparison. The SP transforms this to [Coin Transfer Allowed] (0/1). |
| 10 | TagType | varchar(100) | YES | T2 | Classification of the settings tag that produced this row's SelectedValue. Determines matching granularity. Values observed: 'Default', 'GeoRegistrationDate', 'Country', 'RegulationGroup', 'PlayerLevelAndCountry', 'CountryAndRegion', 'CountryAndDesignatedRegulation', 'CountryRegionAndRegulation', 'CountryAndRegulation'. Higher-specificity tag types typically have higher RestrictionWeight. |
| 11 | TagValue | varchar(100) | YES | T2 | Specific tag value matched from EXW_Settings.Tags. Examples: 'Default' (for default rules), 'RegulationGroup_4' (for ASIC-regulated users), 'united_states' (country-level rule), 'diamond_united_kingdom' (club+country rule). Matching is case-insensitive. |
| 12 | RestrictionWeight | int | YES | T2 | Priority weight of the winning tag from EXW_Settings.SystemRestrictions. Higher weight = higher priority when multiple tags match the same combination. The SP selects the maximum RestrictionWeight match and uses its SelectedValue. Used to resolve conflicts between overlapping rules. |
| 13 | Coin Transfer Allowed | int | YES | T2 | SP-derived eligibility flag. CASE WHEN LOWER(SelectedValue)='true' THEN 1 ELSE 0 END. 1 = coin transfer (crypto withdrawal to external blockchain address) is permitted for this country/club/regulation/crypto combination. 0 = blocked. The primary field used by downstream consumers to determine eligibility. |
| 14 | UpdateDate | datetime | YES | T2 | Datetime of SP execution (GETDATE()). Nullable in DDL — unlike most UpdateDate columns in EXW_dbo which are NOT NULL. In practice, always populated. |
| 15 | RegulationID | int | YES | T2 | Regulatory jurisdiction identifier from DWH_dbo.Dim_Regulation.DWHRegulationID. Represents the regulatory entity governing this combination (e.g., CySEC, FCA, ASIC, BVI, NFA, FSA Seychelles, FinCEN). |
| 16 | Regulation | varchar(50) | YES | T2 | Regulatory jurisdiction name from DWH_dbo.Dim_Regulation.Name. Human-readable label for the regulation dimension. |
| 17 | StateProvince | varchar(100) | YES | T2 | US state or province name from DWH_dbo.Dim_State_and_Province.Name. Only populated for CountryID=219 (United States). NULL for all other countries. Enables state-level eligibility granularity within the US (e.g., different rules for California). |
| 18 | RegionByIP_ID | int | YES | T2 | IP-geolocation region identifier from DWH_dbo.Dim_State_and_Province.RegionByIP_ID. Only populated for US state rows (CountryID=219). NULL for all non-US rows. Used by the EXW platform to route US users to state-appropriate rules based on detected IP region. |

## 5. Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| T1 | 3 | InstrumentID, CryptoID, Crypto — verbatim from EXW_Wallet.CryptoTypes (mirrors Wallet.CryptoTypes); wiki at CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md |
| T2 | 15 | EXW_Settings tables (no upstream wiki), DWH_dbo dimension tables (no upstream wiki), ETL-computed columns |
| T3 | 0 | — |
| T4 | 0 | — |

## 6. Distribution & Indexing

| Property | Value |
|----------|-------|
| Distribution | HASH(CountryID) |
| Index | HEAP |
| Rationale | HASH(CountryID) optimizes joins with Dim_Country and other country-keyed tables. HEAP is used here despite the large row count — the table is rebuilt entirely on each SP run, making CCI less advantageous (no incremental inserts). |

## 7. Relationships

| Related Object | Relationship | Notes |
|----------------|--------------|-------|
| `SP_EXW_WalletElligibleCountries` | Writer | TRUNCATE + INSERT — sole writer. Coin Transfer part of a much larger SP that also populates EXW_WalletElligibleCountries, EXW_Payment_Allowed_Country, and EXW_Staking_Allowed_Country. |
| `EXW_Settings.Resources` | Upstream | ResourceId=5903 defines the "redeem/allow" resource family. |
| `EXW_Settings.SystemRestrictions` | Upstream | Provides SelectedValue and RestrictionWeight per TagId+ResourceId. |
| `EXW_Settings.Tags` | Upstream | Provides TagType and TagValue for each restriction. |
| `EXW_Wallet.CryptoTypes` | Upstream | Provides CryptoID, InstrumentId, Name for active non-eToro cryptos. |
| `DWH_dbo.Dim_Country` | Upstream | Country dimension — all countries except CountryID=0. |
| `DWH_dbo.Dim_PlayerLevel` | Upstream | Player level dimension — all levels except PlayerLevelID=0. |
| `DWH_dbo.Dim_Regulation` | Upstream | Regulation dimension — all regulations except DWHRegulationID=0. |
| `DWH_dbo.Dim_State_and_Province` | Upstream | US state granularity — only joined for CountryID=219. |
| `SP_EXW_CompensationClosingCountries` | Downstream reader | References this table at line 2741 of the SP: `SELECT * FROM EXW_dbo.EXW_Coin_Transfer_Allowed_Country ectac`. |
| `EXW_dbo.EXW_WalletElligibleCountries` | Sibling output | The same SP populates both tables; EXW_WalletElligibleCountries uses ResourceId=5903 wallet-open rules; this table uses the redeem/allow resource. |

## 8. Known Limitations

1. **EXW_Settings not documented**: No upstream wiki exists for `EXW_Settings.Resources`, `EXW_Settings.SystemRestrictions`, or `EXW_Settings.Tags`. The semantics of TagType values and RestrictionWeight ranges are inferred from SP code alone.
2. **Row semantics are combinatorial**: A row with `[Coin Transfer Allowed]=0` and `TagType='Default'` means the default setting is blocked, but a more specific tag (higher RestrictionWeight) may override this for a specific user. Downstream queries must correctly handle the priority resolution — usually by querying for the specific combination matching the user's country+regulation+club+crypto.
3. **No intermediate state**: The TRUNCATE + INSERT pattern means there is no historical record of prior eligibility settings. If an eligibility rule changes, the change date is not captured.
4. **`redeem/allow/crypto` vs instrument-specific rows**: The 'crypto' ResourceName rows provide a general fallback. If a downstream consumer joins on InstrumentID, they may miss the generic 'crypto' rows. Consumers should be aware of this dual-key structure.
5. **US state granularity adds rows**: The JOIN on `Dim_State_and_Province` for USA creates one row per (country+state+playerLevel+regulation+crypto) combination, significantly increasing row count for US-specific rules.

## Self-Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| D1 Tier Accuracy (25%) | 10 | 3 T1 (InstrumentID, CryptoID, Crypto from CryptoTypes wiki), 15 T2 correct |
| D2 Upstream Fidelity (20%) | 10 | T1 descriptions verbatim from Wallet.CryptoTypes.md; T2 from SP code analysis |
| D3 Completeness (20%) | 10 | All 18 columns documented; no snapshot stats in element descriptions |
| D4 Business Meaning (15%) | 9 | Strong: priority resolution logic documented, TagType hierarchy, US state granularity, resource name pattern |
| D5 Data Evidence (10%) | 9 | MCP confirmed: 1.74M rows, 250 countries, 59 cryptos, 7 clubs, 9 TagTypes with counts, UpdateDate today |
| D6 Shape Fidelity (10%) | 10 | 18 columns match DDL exactly; HASH(CountryID), HEAP, nullable UpdateDate, bigint InstrumentID all correct |
| **Weighted Total** | **9.65/10** | PASS |
