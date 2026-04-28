# EXW_dbo.EXW_Conversion_Allowed_Country

> Country-level crypto-to-crypto conversion eligibility table with separate From and To direction flags per country/crypto combination, resolved from EXW_Settings. All FromConversionAllowed and ToConversionAllowed values are currently 0 — crypto conversions were discontinued.

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

EXW_Conversion_Allowed_Country stores resolved crypto-to-crypto conversion eligibility for each country/crypto combination. Conversions have a directional component: a crypto can be a "From" source (selling) or a "To" target (buying) in a conversion pair. Each direction is independently controlled via EXW_Settings.

The full eligibility for a conversion requires:
1. User-level eligibility (AllowedUser*) — is the user in a country allowed to convert at all?
2. From-direction eligibility (From*) — is this specific crypto allowed as a conversion source?
3. To-direction eligibility (To*) — is this specific crypto allowed as a conversion target?

**Current state**: All FromConversionAllowed and ToConversionAllowed values are 0. Crypto-to-crypto conversions were discontinued; no country/crypto combination currently meets eligibility conditions. The table is preserved for audit and future reactivation capability.

---

## 2. Business Logic

### 2.1 Directional Conversion Eligibility

**What**: Conversion eligibility is computed independently for each direction.

**Columns Involved**: AllowedUserSelectedValue, FromSelectedValue, ToSelectedValue, FromConversionAllowed, ToConversionAllowed

**Rules**:
- `FromConversionAllowed = 1` when `AllowedUserSelectedValue = 'true' AND FromSelectedValue = 'true'`
- `ToConversionAllowed = 1` when `AllowedUserSelectedValue = 'true' AND ToSelectedValue = 'true'`
- A crypto can be allowed as a From source but not a To target (or vice versa)
- Currently all values are 0

### 2.2 Settings Resolution

Same three-way priority tag resolution as other Allowed_Country tables: CountryAndRegion > Country > GeoRegistrationDate by RestrictionWeight in EXW_Settings.

---

## 3. Query Advisory

### 3.1 All flags currently 0

Crypto conversions are discontinued. Both `WHERE FromConversionAllowed = 1` and `WHERE ToConversionAllowed = 1` return 0 rows.

### 3.2 Column ordering note

The DDL places `Country` before `CountryID` (unlike the other Allowed_Country tables). When querying with SELECT *, be aware of this column order difference.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code or settings-sourced |
| Tier 3 | Inferred from column name, type, and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Country | nvarchar(100) | YES | Country name from DWH_dbo.Dim_Country.Name. Text label for the country. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 2 | CountryID | int | YES | DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 3 | StateProvince | nvarchar(100) | YES | US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for other countries. (Tier 3 — inferred) |
| 4 | RegionByIP_ID | int | YES | Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries. (Tier 3 — inferred) |
| 5 | CryptoID | int | YES | Numeric crypto identifier derived from the EXW_Settings ResourceName path. Identifies which crypto the conversion eligibility applies to. (Tier 3 — inferred) |
| 6 | Crypto | nvarchar(100) | YES | Crypto name from the crypto lookup dimension. Identifies the crypto whose conversion eligibility is being described. (Tier 3 — inferred) |
| 7 | AllowedUserResource | nvarchar(200) | YES | EXW_Settings resource name for user-level conversion eligibility. Determines whether users in this country are allowed to perform crypto conversions at all. (Tier 2 — EXW_Settings) |
| 8 | AllowedUserTagType | nvarchar(100) | YES | Tag type matched during user-level conversion eligibility resolution. (Tier 2 — EXW_Settings) |
| 9 | AllowedUserTagValue | nvarchar(200) | YES | Tag value matched for user-level conversion eligibility. (Tier 2 — EXW_Settings) |
| 10 | AllowedUserSelectedValue | nvarchar(100) | YES | Raw resolved value for user-level conversion eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) |
| 11 | FromResourceName | nvarchar(200) | YES | EXW_Settings resource name for From-direction conversion eligibility. Identifies whether this crypto can be used as a conversion source in this country. (Tier 2 — EXW_Settings) |
| 12 | FromTagType | nvarchar(100) | YES | Tag type matched during From-direction eligibility resolution. (Tier 2 — EXW_Settings) |
| 13 | FromTagValue | nvarchar(200) | YES | Tag value matched for From-direction eligibility. (Tier 2 — EXW_Settings) |
| 14 | FromSelectedValue | nvarchar(100) | YES | Raw resolved value for From-direction conversion eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) |
| 15 | ToResourceName | nvarchar(200) | YES | EXW_Settings resource name for To-direction conversion eligibility. Identifies whether this crypto can be used as a conversion target in this country. (Tier 2 — EXW_Settings) |
| 16 | ToTagType | nvarchar(100) | YES | Tag type matched during To-direction eligibility resolution. (Tier 2 — EXW_Settings) |
| 17 | ToTagValue | nvarchar(200) | YES | Tag value matched for To-direction eligibility. (Tier 2 — EXW_Settings) |
| 18 | ToSelectedValue | nvarchar(100) | YES | Raw resolved value for To-direction conversion eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) |
| 19 | FromConversionAllowed | int | YES | `CASE WHEN AllowedUserSelectedValue = 'true' AND FromSelectedValue = 'true' THEN 1 ELSE 0`. Currently 0 for all rows — crypto conversions discontinued. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 20 | ToConversionAllowed | int | YES | `CASE WHEN AllowedUserSelectedValue = 'true' AND ToSelectedValue = 'true' THEN 1 ELSE 0`. Currently 0 for all rows — crypto conversions discontinued. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 21 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at insert time. (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Transform |
|---------------|-------------------|-----------|
| Country, CountryID | DWH_dbo.Dim_Country | Enumerated |
| StateProvince, RegionByIP_ID | DWH_dbo.Dim_State_and_Province | US states only |
| CryptoID, Crypto | Crypto dimension | Lookup |
| AllowedUser* | EXW_Settings (user-level conversion) | Priority-resolved |
| From* | EXW_Settings (From-direction conversion) | Priority-resolved |
| To* | EXW_Settings (To-direction conversion) | Priority-resolved |
| FromConversionAllowed | — | CASE AND condition |
| ToConversionAllowed | — | CASE AND condition |
| UpdateDate | — | GETDATE() |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension |
| AllowedUserResource | EXW_Settings.Resources | User-level conversion configuration |
| FromResourceName | EXW_Settings.Resources | From-direction conversion configuration |
| ToResourceName | EXW_Settings.Resources | To-direction conversion configuration |

---

## 7. Sample Queries

### Current conversion eligibility state

```sql
SELECT FromConversionAllowed, ToConversionAllowed,
       COUNT(*) AS combinations
FROM [EXW_dbo].[EXW_Conversion_Allowed_Country]
GROUP BY FromConversionAllowed, ToConversionAllowed;
```

### Distinct setting resources in use

```sql
SELECT DISTINCT AllowedUserResource, FromResourceName, ToResourceName
FROM [EXW_dbo].[EXW_Conversion_Allowed_Country];
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. Table is driven by EXW_Settings configuration. Crypto conversion discontinuation context is embedded in settings state.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 17 T2, 4 T3, 0 T4, 0 T5 | Elements: 21/21*
*Note: 0 Tier 1 is acceptable — EXW_Settings has no upstream wiki (configuration system)*
*Object: EXW_dbo.EXW_Conversion_Allowed_Country | Type: Table | Production Source: EXW_Settings (conversion configuration)*
