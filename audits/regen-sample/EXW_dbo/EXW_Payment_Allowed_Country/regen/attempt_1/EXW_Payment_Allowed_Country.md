# EXW_dbo.EXW_Payment_Allowed_Country

> 52,548-row crypto payment eligibility configuration table mapping every country (250) × cryptocurrency (174) combination to its payment permission status, derived from the EXW_Settings restriction engine. Populated by SP_EXW_WalletElligibleCountries via TRUNCATE+INSERT. US entries (CountryID=219) are further split by state/province (53 sub-regions). Currently all rows show PaymentAllowed=0. Single UpdateDate: 2026-04-15.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Country + EXW_Settings.Resources/SystemRestrictions/Tags + EXW_Wallet.CryptoTypes via SP_EXW_WalletElligibleCountries |
| **Refresh** | On-demand (SP_EXW_WalletElligibleCountries, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | HASH(CountryID) |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`EXW_dbo.EXW_Payment_Allowed_Country` is a configuration-derived table that records whether crypto payment operations are permitted for each country–cryptocurrency pair. It is part of the EXW (eToroX / crypto wallet) subsystem and is produced by `SP_EXW_WalletElligibleCountries`, a large multi-section SP that also populates sibling tables (`EXW_WalletElligibleCountries`, `EXW_Coin_Transfer_Allowed_Country`, etc.).

The SP builds a Cartesian product of all active countries (from `Dim_Country`, 250 rows excl. CountryID=0) × all active cryptocurrencies (from `EXW_Wallet.CryptoTypes`, 174 active instruments). For the United States (CountryID=219), entries are further split by state/province (from `Dim_State_and_Province`), producing 9,222 US rows vs. 174 rows per non-US country.

For each country–crypto pair, the SP resolves two permission domains from the `EXW_Settings` restriction engine:
1. **AllowedUser** (`payment/allowedUser` resource) — whether the user in that country is allowed to use the payment feature.
2. **Cryptos** (`cryptos/{ID}/allowedPayment` resource) — whether that specific crypto is allowed for payment in that country.

The resolution uses a weighted tag-matching system: settings are defined at multiple granularities (Default, Country, CountryAndRegion, CountryAndRegulation, CountryRegionAndRegulation), and the tag with the highest `RestrictionWeight` wins. The final `PaymentAllowed` flag is 1 only when BOTH domains resolve to `'true'`.

As of 2026-04-15, all 52,548 rows have `PaymentAllowed=0`, indicating crypto payments are currently disabled across all countries and cryptocurrencies. The `AllowedUserSelectedValue` is uniformly `'false'`.

---

## 2. Business Logic

### 2.1 Dual-Domain Permission Resolution

**What**: Payment eligibility requires both user-level and crypto-level permissions to be `'true'`.

**Columns Involved**: `AllowedUserSelectedValue`, `CryptosSelectedValue`, `PaymentAllowed`

**Rules**:
- `PaymentAllowed = 1` only when `LOWER(AllowedUserSelectedValue) = 'true'` AND `LOWER(CryptosSelectedValue) = 'true'`
- If either domain is `'false'` or NULL, PaymentAllowed = 0
- Currently all rows have PaymentAllowed=0 because AllowedUserSelectedValue is universally `'false'`

### 2.2 Tag Weight Priority System

**What**: Each permission domain resolves by finding the most specific matching tag with the highest RestrictionWeight.

**Columns Involved**: `AllowedUserTagType`, `AllowedUserTagValue`, `CryptosTagType`, `CryptosTagValue`

**Rules**:
- Tags are matched in a UNION of multiple granularities: Country, CountryAndRegion, CountryAndRegulation, CountryRegionAndRegulation, and Default
- The tag with the highest `RestrictionWeight` is selected (via `MAX(RestrictionWeight)` + correlated subquery)
- If no specific tag matches, the `Default` tag applies
- Currently all rows show TagType=`Default` with TagValue=`Default`, meaning no country-specific overrides are active for the payment resource

### 2.3 US State-Level Granularity

**What**: The United States (CountryID=219) is the only country with state/province-level entries.

**Columns Involved**: `StateProvince`, `RegionByIP_ID`, `CountryID`

**Rules**:
- For CountryID=219: StateProvince is populated from `Dim_State_and_Province.Name`, RegionByIP_ID from `Dim_State_and_Province.RegionByIP_ID`
- For all other countries: StateProvince is NULL, RegionByIP_ID is 0
- The US has 9,222 rows (53 state/province regions × 174 cryptos) vs. 174 rows per non-US country
- Tag matching for US rows can use `CountryAndRegion` tags (e.g., `united_states_delaware`) for state-level overrides

### 2.4 Crypto-Level vs. Category-Level Resolution

**What**: Settings can be defined per specific crypto ID or per crypto category. The SP uses COALESCE to prefer crypto-specific settings over category-level.

**Columns Involved**: `CryptoID`, `AllowedUserResource`, `CryptosResourceName`

**Rules**:
- The SP first checks for a crypto-specific resource (e.g., `cryptos/132/allowedPayment`)
- If no crypto-specific setting exists, it falls back to the category-level resource (e.g., `cryptos/crypto/allowedPayment`)
- COALESCE(crypto-specific, category-level) ensures the most specific setting wins

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CountryID) distributes rows by country. The US (CountryID=219) has 9,222 rows concentrated on a single distribution, while other countries have 174 rows each. For country-level queries, filter by CountryID to benefit from distribution pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is crypto payment allowed in a specific country? | `WHERE CountryID = <id> AND PaymentAllowed = 1` |
| Which cryptos are payment-enabled for a country? | `WHERE CountryID = <id> AND PaymentAllowed = 1 GROUP BY CryptoID, Crypto` |
| US state-level payment permissions | `WHERE CountryID = 219 AND StateProvince = '<state>'` |
| Global payment status overview | `SELECT CountryID, Country, SUM(PaymentAllowed) FROM ... GROUP BY CountryID, Country` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | CountryID = CountryID | Country attributes (Region, Regulation, risk flags) |
| DWH_dbo.Dim_State_and_Province | RegionByIP_ID = RegionByIP_ID | Full state/province metadata for US entries |

### 3.4 Gotchas

- **All PaymentAllowed=0 currently**: As of 2026-04-15, no country–crypto combination has payment enabled. This may indicate the feature is globally disabled or in a pre-launch state.
- **Data skew on CountryID=219**: The US has 53× more rows than other countries due to state-level granularity. Aggregations that don't filter by CountryID may show skewed processing.
- **RegionByIP_ID=0 for non-US**: Not a real region ID — it is the ISNULL default. Do not JOIN to Dim_State_and_Province on RegionByIP_ID=0.
- **AllowedUserSelectedValue is string, not boolean**: Values are `'true'`/`'false'` as strings (from EXW_Settings). PaymentAllowed (int) is the pre-computed boolean flag.
- **TRUNCATE+INSERT reload**: All rows are replaced on each SP execution. No history is preserved. UpdateDate reflects the last reload time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (dim-lookup passthrough from documented Synapse wiki) |
| Tier 2 | SP ETL code (traced from SP_EXW_WalletElligibleCountries source) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. In this table, used as the country dimension key for the country–crypto permission matrix. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 2 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (Name → Country rename). (Tier 1 — Dictionary.Country) |
| 3 | StateProvince | varchar(100) | YES | Full human-readable geographic name of the sub-country region (state, province, territory). Populated only for US entries (CountryID=219) from Dim_State_and_Province.Name; NULL for all other countries. 9,222 non-null rows across 53 US regions. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 4 | RegionByIP_ID | int | YES | IP-based geographic region identifier from Dim_State_and_Province. Populated only for US entries (CountryID=219); set to 0 via ISNULL for all other countries. Do not JOIN on RegionByIP_ID=0 — it is not a real region. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 5 | CryptoID | int | YES | Cryptocurrency identifier from EXW_Wallet.CryptoTypes. Identifies the specific crypto asset in the permission check. 174 distinct active cryptos. Each country has one row per CryptoID. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 6 | Crypto | nvarchar(256) | YES | Cryptocurrency display name from EXW_Wallet.CryptoTypes.Name (e.g., "BTC", "ETH"). Rename of CryptoTypes.Name → Crypto. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 7 | AllowedUserResource | nvarchar(100) | YES | EXW_Settings resource name for the user-level payment permission. Expected value: `payment/allowedUser`. Resolved from EXW_Settings.Resources via the highest-weight matching tag for this country–crypto combination. NULL if no setting resolved. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 8 | AllowedUserTagType | nvarchar(50) | YES | Tag type that won the weight-based resolution for the AllowedUser permission domain. Values include: Default, Country, CountryAndRegion, CountryAndRegulation, CountryRegionAndRegulation. Currently all rows show `Default`. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 9 | AllowedUserTagValue | nvarchar(50) | YES | Tag value that won the weight-based resolution for the AllowedUser permission domain. For `Default` tag type, this is `Default`. For country-specific tags, this is the country slug (e.g., `united_states_delaware`). (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 10 | AllowedUserSelectedValue | nvarchar(50) | YES | The resolved permission value for the AllowedUser domain. String `'true'` or `'false'`. Currently all rows show `false`, meaning user-level payment is disabled globally. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 11 | CryptosResourceName | nvarchar(100) | YES | EXW_Settings resource name for the crypto-specific payment permission. Pattern: `cryptos/{CryptoID}/allowedPayment` (e.g., `cryptos/1/allowedPayment` for BTC). Resolved via highest-weight matching tag. NULL if no setting resolved. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 12 | CryptosTagType | nvarchar(50) | YES | Tag type that won the weight-based resolution for the Cryptos permission domain. Same possible values as AllowedUserTagType. May differ from AllowedUserTagType if different tag granularities are configured for user vs. crypto resources. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 13 | CryptosTagValue | nvarchar(50) | YES | Tag value that won the weight-based resolution for the Cryptos permission domain. For `Default` tag type, this is `Default`. For country-specific tags, this is the country/region slug. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 14 | CryptosSelectedValue | nvarchar(50) | YES | The resolved permission value for the Cryptos domain. String `'true'` or `'false'`. Indicates whether the specific crypto is allowed for payment in this country. Mixed values observed: some country–crypto pairs show `true`, others `false`. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 15 | PaymentAllowed | int | YES | Final payment eligibility flag. 1=payment allowed, 0=payment blocked. Computed as: `CASE WHEN LOWER(AllowedUserSelectedValue)='true' AND LOWER(CryptosSelectedValue)='true' THEN 1 ELSE 0 END`. Currently all 52,548 rows = 0 because AllowedUserSelectedValue is universally `false`. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 16 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP execution time. Reflects when SP_EXW_WalletElligibleCountries last ran, not when settings actually changed. All rows share the same timestamp per reload (TRUNCATE+INSERT pattern). (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | DWH_dbo.Dim_Country ← etoro.Dictionary.Country | CountryID | Passthrough (dim-lookup) |
| Country | DWH_dbo.Dim_Country ← etoro.Dictionary.Country | Name | Rename (Name → Country) |
| StateProvince | DWH_dbo.Dim_State_and_Province ← etoro.Dictionary.RegionName | Name | CASE WHEN CountryID=219 ELSE NULL |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province ← etoro.Dictionary.RegionByIP | RegionByIP_ID | CASE WHEN CountryID=219 ELSE NULL; ISNULL(...,0) |
| CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough (active only) |
| Crypto | EXW_Wallet.CryptoTypes | Name | Rename (Name → Crypto) |
| AllowedUserResource | EXW_Settings.Resources | ResourceName | Max-weight tag resolution |
| AllowedUserTagType | EXW_Settings.Tags | TagType | Max-weight tag resolution |
| AllowedUserTagValue | EXW_Settings.Tags | TagValue | Max-weight tag resolution |
| AllowedUserSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Max-weight tag resolution |
| CryptosResourceName | EXW_Settings.Resources | ResourceName | Max-weight tag resolution (crypto resource) |
| CryptosTagType | EXW_Settings.Tags | TagType | Max-weight tag resolution (crypto resource) |
| CryptosTagValue | EXW_Settings.Tags | TagValue | Max-weight tag resolution (crypto resource) |
| CryptosSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Max-weight tag resolution (crypto resource) |
| PaymentAllowed | EXW_Settings.SystemRestrictions | SelectedValue (both) | CASE: both='true' → 1, else 0 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Country (250 countries)
  + DWH_dbo.Dim_State_and_Province (US states, LEFT JOIN)
  + DWH_dbo.Dim_Regulation (CROSS APPLY, non-zero)
  + EXW_Wallet.CryptoTypes (174 active cryptos, CROSS APPLY)
    |-- Cartesian product → #preppayment (country × crypto × region)
    v
EXW_Settings.Resources + SystemRestrictions + Tags
  + CopyFromLake.SettingsDB_Dictionary_CountryGroup/CountryToCountryGroup
    |-- Tag union (Country, CountryAndRegion, CountryAndRegulation,
    |   CountryRegionAndRegulation, Default) → MAX(RestrictionWeight)
    |-- COALESCE(crypto-specific, category-level) resolution
    v
  #paymentalloweduser (AllowedUser domain per country–crypto)
  #cryptosresourcename (Cryptos domain per country–crypto)
    |-- SP_EXW_WalletElligibleCountries: TRUNCATE + INSERT
    v
EXW_dbo.EXW_Payment_Allowed_Country (52,548 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension (250 countries) |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | US state/province dimension (0 for non-US) |
| CryptoID | EXW_Wallet.CryptoTypes | Cryptocurrency type reference |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found in the Synapse SSDT repo.

---

## 7. Sample Queries

### 7.1 Check Payment Status for a Specific Country and Crypto

```sql
SELECT Country, Crypto, PaymentAllowed,
       AllowedUserSelectedValue, CryptosSelectedValue
FROM EXW_dbo.EXW_Payment_Allowed_Country
WHERE CountryID = 77  -- Germany
  AND Crypto = 'BTC'
```

### 7.2 US State-Level Payment Permissions

```sql
SELECT StateProvince, Crypto, PaymentAllowed,
       AllowedUserTagType, AllowedUserTagValue,
       CryptosTagType, CryptosTagValue
FROM EXW_dbo.EXW_Payment_Allowed_Country
WHERE CountryID = 219
  AND Crypto = 'BTC'
ORDER BY StateProvince
```

### 7.3 Summary of Payment-Enabled Countries (if any)

```sql
SELECT c.Country, c.Region, COUNT(*) AS enabled_cryptos
FROM EXW_dbo.EXW_Payment_Allowed_Country pac
JOIN DWH_dbo.Dim_Country c ON pac.CountryID = c.CountryID
WHERE pac.PaymentAllowed = 1
GROUP BY c.Country, c.Region
ORDER BY enabled_cryptos DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 2 T1, 14 T2, 0 T3, 0 T4 | Elements: 16/16, Logic: 7/10, Lineage: 8/10*
*Object: EXW_dbo.EXW_Payment_Allowed_Country | Type: Table | Production Source: DWH_dbo.Dim_Country + EXW_Settings + EXW_Wallet.CryptoTypes via SP_EXW_WalletElligibleCountries*
