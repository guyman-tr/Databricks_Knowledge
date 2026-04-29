# EXW_dbo.EXW_Conversion_Allowed_Country

> 51,642-row crypto-to-crypto conversion eligibility matrix mapping every active cryptocurrency (171 cryptos) against every country (250 countries, with US exploded to 53 state-level rows) to determine whether conversion from/to each crypto is allowed per country. Populated by SP_EXW_WalletElligibleCountries via TRUNCATE+INSERT from EXW_Settings restriction rules resolved by tag-priority weighting. Currently all conversions are blocked (FromConversionAllowed=0, ToConversionAllowed=0 for all 51,642 rows). Last refreshed 2026-04-15.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_Settings.Resources + EXW_Settings.Tags + EXW_Settings.SystemRestrictions (restriction rules) + DWH_dbo.Dim_Country + DWH_dbo.Dim_State_and_Province + EXW_Wallet.CryptoTypes |
| **Refresh** | On-demand (SP_EXW_WalletElligibleCountries, full TRUNCATE+INSERT) |
| **Synapse Distribution** | HASH(CountryID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`EXW_Conversion_Allowed_Country` is a crypto conversion eligibility matrix within the eToroX (EXW) wallet ecosystem. Each row represents a specific country (or US state) × cryptocurrency combination and records whether that combination is allowed for crypto-to-crypto conversion. The table is one of several sibling eligibility tables produced by SP_EXW_WalletElligibleCountries (alongside `EXW_Payment_Allowed_Country`, `EXW_Staking_Allowed_Country`, etc.).

The table contains 51,642 rows: 250 countries × 171 active cryptos = 42,750 base rows, plus 9,063 additional rows for United States (CountryID=219) which is broken down by 53 state/territory subdivisions. The cross-product is built from `DWH_dbo.Dim_Country` CROSS APPLY `EXW_Wallet.CryptoTypes` (WHERE IsActive=1).

The eligibility decision flows through a restriction-weight priority system from `EXW_Settings`:
1. For each country×crypto pair, three tag scopes are evaluated: Country, CountryAndRegion, and Default.
2. The tag with the highest `RestrictionWeight` wins (COALESCE of coin-level vs. category-level settings).
3. Three independent restriction resources are resolved: `conversion/allowedUser`, `cryptos/{id}/allowedConvertFrom`, and `cryptos/{id}/allowedConvertTo`.
4. `FromConversionAllowed` = 1 only if BOTH the user is allowed (AllowedUserSelectedValue='true') AND the from-crypto is allowed (FromSelectedValue='true'). Same logic for `ToConversionAllowed`.

As of the latest refresh (2026-04-15), all rows show `AllowedUserSelectedValue='false'`, making all `FromConversionAllowed` and `ToConversionAllowed` values 0. The conversion activity was explicitly deactivated per the SP change history (2026-04-14: "Remove conversion, payment and staking part, activity is not active, we will keep tables, no need to re fill them").

ETL: SP_EXW_WalletElligibleCountries performs TRUNCATE+INSERT. The "Conversion Part" section of the SP (lines ~1546-2317) builds several intermediate temp tables (#prepconv, #settingsconv, #unionc/c2, #conversionalloweduser, #fromcrypto, #tocrypto, #finalprep) before the final INSERT.

---

## 2. Business Logic

### 2.1 Tag-Priority Restriction Weight Resolution

**What**: For each country×crypto pair, the SP evaluates three tag scopes (Country, CountryAndRegion, Default) and picks the one with the highest RestrictionWeight via MAX + JOIN-back pattern.
**Columns Involved**: `AllowedUserTagType`, `AllowedUserTagValue`, `AllowedUserSelectedValue`, `FromTagType`, `FromTagValue`, `FromSelectedValue`, `ToTagType`, `ToTagValue`, `ToSelectedValue`
**Rules**:
- Three UNION queries merge Country-specific, CountryAndRegion-specific, and Default tag rows
- MAX(RestrictionWeight) per (CountryID, RegionByIP_ID, CryptoID) determines the winning rule
- COALESCE(coin-level, category-level) handles crypto vs. crypto-category precedence
- If a specific coin-level restriction exists, it takes priority over the crypto-category restriction

### 2.2 Conversion Allowed Flag Derivation

**What**: Boolean flags derived from the AND of two independent restriction checks.
**Columns Involved**: `FromConversionAllowed`, `ToConversionAllowed`
**Rules**:
- `FromConversionAllowed = CASE WHEN AllowedUserSelectedValue = 'true' AND FromSelectedValue = 'true' THEN 1 ELSE 0 END`
- `ToConversionAllowed = CASE WHEN AllowedUserSelectedValue = 'true' AND ToSelectedValue = 'true' THEN 1 ELSE 0 END`
- Both flags are 0 unless the user is allowed to convert AND the specific crypto direction is allowed
- Currently all rows have AllowedUserSelectedValue='false', so both flags are universally 0

### 2.3 US State-Level Granularity

**What**: United States (CountryID=219) is expanded to state/territory level.
**Columns Involved**: `StateProvince`, `RegionByIP_ID`, `CountryID`
**Rules**:
- For CountryID=219: StateProvince = Dim_State_and_Province.Name, RegionByIP_ID = Dim_State_and_Province.RegionByIP_ID
- For all other countries: StateProvince is empty string, RegionByIP_ID = 0
- This produces 53 state/territory rows per crypto for the US (9,063 / 171 = 53)
- Settings matching uses CountryAndRegion tag (country_state combined key) for US state-specific rules

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CountryID) — optimizes JOINs to other country-keyed tables. HEAP storage (no clustered index). 51,642 rows is small; full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which cryptos can be converted from a specific country? | `WHERE CountryID = <id> AND FromConversionAllowed = 1` |
| Is conversion allowed for a specific country+crypto? | `WHERE CountryID = <id> AND CryptoID = <id>` |
| Which countries allow any conversion? | `WHERE FromConversionAllowed = 1 OR ToConversionAllowed = 1` (currently returns 0 rows) |
| US state-level conversion rules | `WHERE CountryID = 219 AND StateProvince = '<state>'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | CountryID = CountryID | Country name, region, risk attributes |
| DWH_dbo.Dim_State_and_Province | RegionByIP_ID = RegionByIP_ID | State/province name for US rows |
| EXW_dbo.EXW_Payment_Allowed_Country | CountryID, CryptoID, RegionByIP_ID | Cross-check payment vs. conversion eligibility |

### 3.4 Gotchas

- **All conversions currently blocked**: AllowedUserSelectedValue='false' for all 51,642 rows → FromConversionAllowed=0, ToConversionAllowed=0 universally. The conversion activity was deactivated in April 2026.
- **Empty string vs. NULL for StateProvince**: Non-US rows have empty string (''), not NULL. Use `WHERE StateProvince <> ''` or `WHERE CountryID = 219` to filter US state rows.
- **RegionByIP_ID = 0 for non-US**: All non-US countries have RegionByIP_ID=0 (ISNULL default). Do not confuse with a valid region code.
- **FromResourceName/ToResourceName encode CryptoID**: Values like 'cryptos/1/allowedConvertFrom' embed the CryptoID. These are EXW_Settings resource paths, not human-readable labels.
- **CountryID=0 excluded**: The SP filters `WHERE CountryID <> 0`, so the "Not available" placeholder from Dim_Country is absent.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Country | varchar(50) | YES | Full country name in English. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country). (Tier 1 — Dictionary.Country) |
| 2 | CountryID | int | YES | Primary key in Dim_Country. 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. Distribution key for this table. CountryID=0 excluded by SP WHERE clause. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 3 | StateProvince | varchar(100) | YES | US state/territory name. Only populated for CountryID=219 (United States) — sourced from Dim_State_and_Province.Name via LEFT JOIN. Empty string for all non-US rows. 53 distinct US state/territory values. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 4 | RegionByIP_ID | int | YES | IP-based geographic region identifier from Dim_State_and_Province. Only meaningful for CountryID=219 (United States); set to 0 for all non-US countries via ISNULL(..., 0). FK to Dim_State_and_Province.RegionByIP_ID for US rows. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 5 | CryptoID | int | NOT NULL | Cryptocurrency identifier from EXW_Wallet.CryptoTypes. Filtered to IsActive=1 only. 171 distinct active cryptos. Each country has one row per active crypto. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 6 | Crypto | nvarchar(256) | YES | Cryptocurrency name/symbol from EXW_Wallet.CryptoTypes.Name. Examples: BTC, ETH, EURX, SAND, AUDX. Rename of CryptoTypes.Name. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 7 | AllowedUserResource | nvarchar(100) | YES | EXW_Settings resource path for the conversion/allowedUser restriction. Always 'conversion/allowedUser' for all rows. Resolved via MAX(RestrictionWeight) priority from EXW_Settings.Resources. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 8 | AllowedUserTagType | nvarchar(50) | YES | Tag scope that won the restriction-weight priority resolution for the allowedUser resource. Values: 'Default', 'Country', or 'CountryAndRegion'. Currently 'Default' for all 51,642 rows. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 9 | AllowedUserTagValue | nvarchar(50) | YES | Tag value that matched during restriction resolution. 'Default' when TagType='Default', country name when TagType='Country', country_region key when TagType='CountryAndRegion'. Currently 'Default' for all rows. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 10 | AllowedUserSelectedValue | nvarchar(50) | YES | Whether the user in this country is allowed to use conversion. 'true' or 'false' from EXW_Settings.SystemRestrictions (priority-resolved). Currently 'false' for all 51,642 rows — conversion activity globally disabled. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 11 | FromResourceName | nvarchar(100) | YES | EXW_Settings resource path for the allowedConvertFrom restriction. Pattern: 'cryptos/{CryptoID}/allowedConvertFrom' or 'cryptos/{CryptoCategoryName}/allowedConvertFrom'. 73 distinct values. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 12 | FromTagType | nvarchar(50) | YES | Tag scope that won priority resolution for the allowedConvertFrom resource. Values: 'Default' or 'Country'. 'Default' for most rows, 'Country' for specific country overrides (e.g., Germany, Saudi Arabia, US territories). (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 13 | FromTagValue | nvarchar(50) | YES | Tag value for the allowedConvertFrom restriction. 'Default' when FromTagType='Default', country name when FromTagType='Country'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 14 | FromSelectedValue | nvarchar(50) | YES | Whether conversion FROM this crypto is allowed in this country. 'true' or 'false' from EXW_Settings (priority-resolved). 33% of rows have 'true', 67% have 'false'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 15 | ToResourceName | nvarchar(100) | YES | EXW_Settings resource path for the allowedConvertTo restriction. Pattern: 'cryptos/{CryptoID}/allowedConvertTo' or 'cryptos/{CryptoCategoryName}/allowedConvertTo'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 16 | ToTagType | nvarchar(50) | YES | Tag scope that won priority resolution for the allowedConvertTo resource. Same pattern as FromTagType. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 17 | ToTagValue | nvarchar(50) | YES | Tag value for the allowedConvertTo restriction. Same pattern as FromTagValue. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 18 | ToSelectedValue | nvarchar(50) | YES | Whether conversion TO this crypto is allowed in this country. 'true' or 'false' from EXW_Settings (priority-resolved). (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 19 | FromConversionAllowed | int | YES | ETL-computed flag: 1 if BOTH AllowedUserSelectedValue='true' AND FromSelectedValue='true', else 0. Currently 0 for all 51,642 rows because AllowedUserSelectedValue is universally 'false'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 20 | ToConversionAllowed | int | YES | ETL-computed flag: 1 if BOTH AllowedUserSelectedValue='true' AND ToSelectedValue='true', else 0. Currently 0 for all 51,642 rows because AllowedUserSelectedValue is universally 'false'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 21 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time. Reflects when SP_EXW_WalletElligibleCountries last ran, not when the underlying settings changed. All rows share the same timestamp per refresh. (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Country | DWH_dbo.Dim_Country | Name | Rename (c.Name AS Country) |
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough (WHERE CountryID <> 0) |
| StateProvince | DWH_dbo.Dim_State_and_Province | Name | CASE: populated only for US (CountryID=219) |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | CASE + ISNULL(..., 0): 0 for non-US |
| CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough (WHERE IsActive=1) |
| Crypto | EXW_Wallet.CryptoTypes | Name | Rename (t.Name AS Crypto) |
| AllowedUserResource | EXW_Settings.Resources | ResourceName | Weight-priority resolved for 'conversion/allowedUser' |
| AllowedUserTagType | EXW_Settings.Tags | TagType | Weight-priority resolved |
| AllowedUserTagValue | EXW_Settings.Tags | TagValue | Weight-priority resolved |
| AllowedUserSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Weight-priority resolved |
| FromResourceName | EXW_Settings.Resources | ResourceName | Weight-priority resolved for 'cryptos/{id}/allowedConvertFrom' |
| FromTagType | EXW_Settings.Tags | TagType | Weight-priority resolved |
| FromTagValue | EXW_Settings.Tags | TagValue | Weight-priority resolved |
| FromSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Weight-priority resolved |
| ToResourceName | EXW_Settings.Resources | ResourceName | Weight-priority resolved for 'cryptos/{id}/allowedConvertTo' |
| ToTagType | EXW_Settings.Tags | TagType | Weight-priority resolved |
| ToTagValue | EXW_Settings.Tags | TagValue | Weight-priority resolved |
| ToSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Weight-priority resolved |
| FromConversionAllowed | — | — | CASE: AllowedUser='true' AND From='true' → 1 ELSE 0 |
| ToConversionAllowed | — | — | CASE: AllowedUser='true' AND To='true' → 1 ELSE 0 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Country (251 rows, REPLICATE)
  + DWH_dbo.Dim_State_and_Province (181 rows, REPLICATE)
  + EXW_Wallet.CryptoTypes (171 active cryptos)
  |
  v [CROSS APPLY — country × crypto cross-product]
  |
#prepconv (country+crypto base grid, ~78K rows with US states)
  |
  + EXW_Settings.Resources / Tags / SystemRestrictions
  |
  v [3× UNION (Country, CountryAndRegion, Default tags) per resource]
  v [MAX(RestrictionWeight) → winning tag per country×crypto]
  v [COALESCE(coin-level, category-level)]
  |
#conversionalloweduser + #fromcrypto + #tocrypto
  |
  v [JOIN on CountryID + CryptoID + RegionByIP_ID]
  v [CASE for FromConversionAllowed / ToConversionAllowed]
  v [TRUNCATE + INSERT]
  |
EXW_dbo.EXW_Conversion_Allowed_Country (51,642 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension lookup |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | US state/province dimension (CountryID=219 only) |
| CryptoID | EXW_Wallet.CryptoTypes | Active cryptocurrency reference |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified in the Synapse codebase (no views, no SPs read from this table).

---

## 7. Sample Queries

### 7.1 Check Conversion Eligibility for a Specific Country and Crypto

```sql
SELECT Country, Crypto, FromConversionAllowed, ToConversionAllowed,
       AllowedUserSelectedValue, FromSelectedValue, ToSelectedValue
FROM EXW_dbo.EXW_Conversion_Allowed_Country
WHERE CountryID = 219 AND CryptoID = 1 AND StateProvince = 'California'
```

### 7.2 Find Countries Where Any Crypto Conversion Is Allowed

```sql
SELECT DISTINCT Country, CountryID
FROM EXW_dbo.EXW_Conversion_Allowed_Country
WHERE FromConversionAllowed = 1 OR ToConversionAllowed = 1
-- Currently returns 0 rows (all conversions disabled)
```

### 7.3 Summarize From-Conversion Status by Tag Priority

```sql
SELECT FromTagType, FromTagValue, FromSelectedValue, COUNT(*) AS row_count
FROM EXW_dbo.EXW_Conversion_Allowed_Country
GROUP BY FromTagType, FromTagValue, FromSelectedValue
ORDER BY row_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this table. SP change history (2026-04-14, Inessa K) notes: "Remove conversion, payment and staking part, activity is not active, we will keep tables, no need to re fill them."

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 2 T1, 19 T2, 0 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 7/10, Lineage: 8/10*
*Object: EXW_dbo.EXW_Conversion_Allowed_Country | Type: Table | Production Source: EXW_Settings + Dim_Country + EXW_Wallet.CryptoTypes via SP_EXW_WalletElligibleCountries*
