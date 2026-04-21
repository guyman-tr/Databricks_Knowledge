# EXW_dbo.EXW_Staking_Allowed_Country

> Country-level crypto staking eligibility table showing whether staking is allowed per country/crypto combination, resolved from EXW_Settings priority-weighted tag rules. All StakingAllowed values are currently 0 — ETH staking was discontinued.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Settings Eligibility) |
| **Writer SP** | EXW_dbo.SP_EXW_WalletElligibleCountries |
| **Refresh** | Full refresh (TRUNCATE + INSERT, no date parameter) |
| **Synapse Distribution** | HASH(CountryID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |

---

## 1. Business Meaning

EXW_Staking_Allowed_Country stores the resolved staking eligibility for each country/crypto combination. Staking eligibility is controlled through the EXW_Settings configuration system: a setting with ResourceName pattern `cryptos/{N}/allowstakingmode` determines whether a specific crypto can be staked in a specific country.

**Current state**: All StakingAllowed values are 0. ETH staking was part of the eToro Wallet offering but has been discontinued. The table structure is preserved for future reactivation capability.

The EXW_Settings priority resolution works through weighted tag matching — a country can be matched by CountryAndRegion (country+state), Country name, or GeoRegistrationDate (country group tag). The highest-weight matching tag wins and its SelectedValue ('true'/'false') determines eligibility.

---

## 2. Business Logic

### 2.1 Staking Eligibility Resolution

**What**: Staking eligibility per country/crypto is resolved from the EXW_Settings system.

**Columns Involved**: ResourceName, TagType, TagValue, SelectedValue, StakingAllowed, CountryID

**Rules**:
- ResourceName pattern: `cryptos/{CryptoID}/allowstakingmode` (e.g., `cryptos/2/allowstakingmode` for ETH)
- Tag types resolved in priority order by RestrictionWeight: CountryAndRegion > Country > GeoRegistrationDate
- SelectedValue = 'true' → StakingAllowed = 1; SelectedValue = 'false' or no match → StakingAllowed = 0
- All rows currently have SelectedValue ≠ 'true' → StakingAllowed = 0 across all rows

### 2.2 US State Granularity

**What**: US is expanded to state-level rows (CountryID=219 with each state).

**Columns Involved**: CountryID, StateProvince, RegionByIP_ID

**Rules**:
- For CountryID=219 (USA), each row represents a specific US state
- StateProvince = Dim_State_and_Province.Name for that state
- RegionByIP_ID = Dim_State_and_Province.RegionByIP_ID for that state
- For all other countries, StateProvince and RegionByIP_ID are NULL

---

## 3. Query Advisory

### 3.1 All flags currently 0

Query `WHERE StakingAllowed = 1` will return 0 rows. This is not a data quality issue — it reflects the current disabled state of the staking feature.

### 3.2 Pattern for checking settings state

```sql
-- Confirm current staking eligibility state
SELECT StakingAllowed, COUNT(*) AS row_count
FROM [EXW_dbo].[EXW_Staking_Allowed_Country]
GROUP BY StakingAllowed;
-- Expected: StakingAllowed=0, N rows
```

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code (DWH-computed or settings-sourced) |
| Tier 3 | Inferred from column name, type, and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 2 | Country | nvarchar(100) | NO | Country name from DWH_dbo.Dim_Country.Name. Text label for the country whose staking eligibility is represented. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 3 | StateProvince | nvarchar(100) | YES | US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for all other countries. (Tier 3 — inferred) |
| 4 | RegionByIP_ID | int | YES | Geographic region identifier from DWH_dbo.Dim_State_and_Province.RegionByIP_ID for US state rows; NULL for non-US countries. Used for IP geolocation region matching. (Tier 3 — inferred) |
| 5 | CryptoID | int | YES | Numeric crypto identifier derived from the EXW_Settings ResourceName path (e.g., 2 from `cryptos/2/allowstakingmode`). Identifies which crypto the staking eligibility applies to. (Tier 3 — inferred) |
| 6 | Crypto | nvarchar(100) | YES | Crypto name (e.g., ETH, BTC) from the crypto lookup dimension. Text label for the crypto corresponding to CryptoID. (Tier 3 — inferred) |
| 7 | ResourceName | nvarchar(200) | YES | EXW_Settings resource name identifying the staking eligibility setting. Pattern: `cryptos/{CryptoID}/allowstakingmode`. (Tier 2 — EXW_Settings) |
| 8 | TagType | nvarchar(100) | YES | The type of tag that was matched during priority resolution (e.g., 'Country', 'CountryAndRegion', 'GeoRegistrationDate'). Reflects which tag dimension matched this country. (Tier 2 — EXW_Settings) |
| 9 | TagValue | nvarchar(200) | YES | The specific tag value that matched the country during EXW_Settings priority resolution (e.g., country name string or country+region combination). (Tier 2 — EXW_Settings) |
| 10 | SelectedValue | nvarchar(100) | YES | Raw resolved setting value from EXW_Settings priority resolution ('true' or 'false'). Currently always 'false' across all rows (staking discontinued). (Tier 2 — EXW_Settings) |
| 11 | StakingAllowed | int | YES | `CASE WHEN SelectedValue = 'true' THEN 1 ELSE 0 END`. Currently 0 for all rows — ETH staking was discontinued and no country/crypto combination has SelectedValue='true' in EXW_Settings. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 12 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at insert time. Reflects when SP_EXW_WalletElligibleCountries last wrote this row. (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | DWH_dbo.Dim_Country | CountryID | Enumerated |
| Country | DWH_dbo.Dim_Country | Name | Passthrough |
| StateProvince | DWH_dbo.Dim_State_and_Province | Name | For US states only |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | For US states only |
| CryptoID | EXW_Settings ResourceName | — | Extracted from path |
| Crypto | Crypto dimension | Name | Lookup |
| ResourceName | EXW_Settings | ResourceName | Passthrough |
| TagType | EXW_Settings | TagType | Passthrough |
| TagValue | EXW_Settings | TagValue | Passthrough |
| SelectedValue | EXW_Settings | SelectedValue | Priority-resolved |
| StakingAllowed | — | — | CASE WHEN SelectedValue='true' THEN 1 ELSE 0 |
| UpdateDate | — | — | GETDATE() |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension |
| ResourceName | EXW_Settings.Resources | Staking eligibility configuration |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| EXW_WalletElligibleCountries | Same SP writes all eligibility tables |
| Wallet eligibility reporting | Country-level staking capability status |

---

## 7. Sample Queries

### Check staking eligibility state

```sql
SELECT StakingAllowed, CryptoID, Crypto, COUNT(*) AS country_count
FROM [EXW_dbo].[EXW_Staking_Allowed_Country]
GROUP BY StakingAllowed, CryptoID, Crypto
ORDER BY StakingAllowed DESC;
```

### List unique setting patterns

```sql
SELECT DISTINCT ResourceName, TagType, SelectedValue
FROM [EXW_dbo].[EXW_Staking_Allowed_Country]
ORDER BY ResourceName;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for EXW_Staking_Allowed_Country. Table is driven by EXW_Settings configuration.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 8 T2, 4 T3, 0 T4, 0 T5 | Elements: 12/12*
*Note: 0 Tier 1 is acceptable — EXW_Settings has no upstream wiki (it is a configuration system, not a production OLTP table with documented columns)*
*Object: EXW_dbo.EXW_Staking_Allowed_Country | Type: Table | Production Source: EXW_Settings (staking configuration)*
