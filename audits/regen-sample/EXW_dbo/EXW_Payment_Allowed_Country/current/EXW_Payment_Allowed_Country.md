# EXW_dbo.EXW_Payment_Allowed_Country

> Country-level crypto payment eligibility table showing whether Simplex-based crypto purchases are allowed per country/crypto combination, resolved from two EXW_Settings rules (user-level and crypto-level). All PaymentAllowed values are currently 0 — Simplex payments were discontinued.

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

EXW_Payment_Allowed_Country stores the resolved crypto payment (Simplex) eligibility for each country/crypto combination. Payment eligibility requires **both** conditions to be true: (1) the user's country must be eligible at the user level, and (2) the specific crypto must be eligible at the crypto level. Both conditions are resolved independently from EXW_Settings and stored as separate column groups (AllowedUser* and Cryptos*).

**Current state**: All PaymentAllowed values are 0. Simplex-based crypto purchases were part of the eToro Wallet offering but have been discontinued. The table structure and settings column groups are preserved for audit and potential future reactivation.

The dual-condition design (AllowedUser AND Cryptos) means that even if a country is generally payment-eligible, specific cryptos can be disabled, and vice versa.

---

## 2. Business Logic

### 2.1 Payment Eligibility — Dual Condition

**What**: Payment is allowed only when both user-level and crypto-level settings return 'true'.

**Columns Involved**: AllowedUserSelectedValue, CryptosSelectedValue, PaymentAllowed

**Rules**:
- `PaymentAllowed = 1` only when `AllowedUserSelectedValue = 'true' AND CryptosSelectedValue = 'true'`
- Either condition being 'false' results in PaymentAllowed = 0
- Currently all rows have at least one 'false' condition → PaymentAllowed = 0

### 2.2 Settings Resolution

**What**: Each of the two condition groups uses EXW_Settings priority-weighted tag matching.

**Columns Involved**: AllowedUser* columns, Cryptos* columns

**Rules**:
- Tag priority resolution: CountryAndRegion > Country > GeoRegistrationDate (by RestrictionWeight)
- AllowedUser* resolves the user-eligibility dimension (e.g., 'can users in this country buy crypto?')
- Cryptos* resolves the crypto-eligibility dimension (e.g., 'is this specific crypto available for purchase?')

### 2.3 US State Granularity

Same as EXW_Staking_Allowed_Country: US (CountryID=219) is expanded to per-state rows via Dim_State_and_Province.

---

## 3. Query Advisory

### 3.1 All flags currently 0

Simplex payments are discontinued. `WHERE PaymentAllowed = 1` returns 0 rows.

### 3.2 Diagnosing which condition blocks payment

```sql
-- See which condition blocks payment for each row
SELECT Country, Crypto,
       AllowedUserSelectedValue, CryptosSelectedValue, PaymentAllowed
FROM [EXW_dbo].[EXW_Payment_Allowed_Country]
WHERE AllowedUserSelectedValue = 'true' OR CryptosSelectedValue = 'true'
ORDER BY AllowedUserSelectedValue DESC, CryptosSelectedValue DESC;
-- Returns 0 rows if both are universally false
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
| 2 | Country | nvarchar(100) | YES | Country name from DWH_dbo.Dim_Country.Name. Text label for the country whose payment eligibility is represented. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 3 | StateProvince | nvarchar(100) | YES | US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for other countries. (Tier 3 — inferred) |
| 4 | RegionByIP_ID | int | YES | Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries. (Tier 3 — inferred) |
| 5 | CryptoID | int | YES | Numeric crypto identifier derived from the EXW_Settings ResourceName path. Identifies which crypto the payment eligibility applies to. (Tier 3 — inferred) |
| 6 | Crypto | nvarchar(100) | YES | Crypto name (e.g., ETH, BTC) from the crypto lookup dimension. Text label for the crypto. (Tier 3 — inferred) |
| 7 | AllowedUserResource | nvarchar(200) | YES | EXW_Settings resource name for the user-level payment eligibility setting. Identifies whether users in this country can make crypto purchases. (Tier 2 — EXW_Settings) |
| 8 | AllowedUserTagType | nvarchar(100) | YES | Tag type matched during user-level eligibility resolution (e.g., 'Country', 'CountryAndRegion'). (Tier 2 — EXW_Settings) |
| 9 | AllowedUserTagValue | nvarchar(200) | YES | Tag value matched for user-level eligibility (country name or country+region combination). (Tier 2 — EXW_Settings) |
| 10 | AllowedUserSelectedValue | nvarchar(100) | YES | Raw resolved value for user-level payment eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) |
| 11 | CryptosResourceName | nvarchar(200) | YES | EXW_Settings resource name for the crypto-level payment eligibility setting. Identifies whether a specific crypto can be purchased in this country. (Tier 2 — EXW_Settings) |
| 12 | CryptosTagType | nvarchar(100) | YES | Tag type matched during crypto-level eligibility resolution. (Tier 2 — EXW_Settings) |
| 13 | CryptosTagValue | nvarchar(200) | YES | Tag value matched for crypto-level eligibility. (Tier 2 — EXW_Settings) |
| 14 | CryptosSelectedValue | nvarchar(100) | YES | Raw resolved value for crypto-level payment eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) |
| 15 | PaymentAllowed | int | YES | `CASE WHEN AllowedUserSelectedValue = 'true' AND CryptosSelectedValue = 'true' THEN 1 ELSE 0 END`. Currently 0 for all rows — Simplex crypto payments were discontinued and no country/crypto combination satisfies both conditions. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 16 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at insert time. (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Transform |
|---------------|-------------------|-----------|
| CountryID, Country | DWH_dbo.Dim_Country | Enumerated |
| StateProvince, RegionByIP_ID | DWH_dbo.Dim_State_and_Province | US states only |
| CryptoID, Crypto | Crypto dimension | Lookup |
| AllowedUser* | EXW_Settings (user-level payment) | Priority-resolved |
| Cryptos* | EXW_Settings (crypto-level payment) | Priority-resolved |
| PaymentAllowed | — | CASE AND condition |
| UpdateDate | — | GETDATE() |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension |
| AllowedUserResource | EXW_Settings.Resources | User-level payment configuration |
| CryptosResourceName | EXW_Settings.Resources | Crypto-level payment configuration |

---

## 7. Sample Queries

### Current payment eligibility state

```sql
SELECT PaymentAllowed, COUNT(*) AS combinations
FROM [EXW_dbo].[EXW_Payment_Allowed_Country]
GROUP BY PaymentAllowed;
```

### All distinct setting combinations

```sql
SELECT DISTINCT AllowedUserResource, CryptosResourceName,
       AllowedUserSelectedValue, CryptosSelectedValue
FROM [EXW_dbo].[EXW_Payment_Allowed_Country]
ORDER BY AllowedUserSelectedValue DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. Table is driven by EXW_Settings configuration. Simplex payment discontinuation context is embedded in settings state.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 12 T2, 4 T3, 0 T4, 0 T5 | Elements: 16/16*
*Note: 0 Tier 1 is acceptable — EXW_Settings has no upstream wiki (configuration system)*
*Object: EXW_dbo.EXW_Payment_Allowed_Country | Type: Table | Production Source: EXW_Settings (payment configuration)*
