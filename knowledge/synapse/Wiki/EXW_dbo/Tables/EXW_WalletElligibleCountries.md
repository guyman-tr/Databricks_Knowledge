# EXW_dbo.EXW_WalletElligibleCountries

> 4,228-row wallet open/close eligibility matrix covering all 250 countries × 14 regulations, resolved from EXW_Settings (ResourceId=5903, 'AllowedUsingWalletStatus'). Each row represents the winning wallet eligibility decision for one country × regulation combination (plus US state-level overrides), showing whether customers from that country under that regulation may open/use a wallet. Refreshed by SP_EXW_WalletElligibleCountries (TRUNCATE + INSERT, no date param) alongside EXW_Coin_Transfer_Allowed_Country. Last refreshed 2026-04-14.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_Settings.Resources + SystemRestrictions + Tags (ResourceId=5903) + DWH_dbo.Dim_Country + Dim_Regulation + Dim_State_and_Province |
| **Refresh** | Daily TRUNCATE + INSERT via SP_EXW_WalletElligibleCountries (no date parameter — full rebuild) |
| **Synapse Distribution** | HASH(CountryID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_WalletElligibleCountries is the per-country wallet eligibility reference table. It answers the question: "Can users from Country X, operating under Regulation Y, open or use an eToro Wallet?" The table has one row per country × regulation combination (4,228 rows = 250 countries × ~17 rows average, including US state-level breakdown).

The core data comes from EXW_Settings resource 5903 ('AllowedUsingWalletStatus'), which stores operator-configured rules at various granularities (by country, by country+regulation, by country+region, etc.). The SP resolves the winning rule per country × regulation × US state by selecting the highest-priority setting (max RestrictionWeight) from the applicable rule matches.

Current distribution: Closed (0) = 2,183 combinations (52%), Open (2) = 1,947 (46%), OpenForExistingOnly (3) = 98 (2%). No ReadOnly (1) entries exist in the current data — this value is defined in the SP but not currently used in the ResourceId=5903 configuration.

This table is the "wallet-level" eligibility reference (one row per country+regulation). Its companion table `EXW_Coin_Transfer_Allowed_Country` (documented, Batch 4) provides crypto-level redemption eligibility (one row per country+regulation+playerLevel+crypto). Both are populated in the same SP run.

Consumer: `SP_EXW_UserSettingsWalletAllowance` reads this table (via the TagType-based filter) to determine per-user wallet allowance.

---

## 2. Business Logic

### 2.1 Priority Resolution (Max RestrictionWeight Wins)

**What**: When multiple EXW_Settings rules match the same country × regulation × US state, the rule with the highest RestrictionWeight takes effect.

**Columns Involved**: `TagType`, `TagValue`, `RestrictionWeight`, `SelectedValue`, `CountryOpenforWallet`

**Rules**:
- 5 tag types are evaluated (UNION in SP): CountryRegionAndRegulation (newest, highest priority), CountryAndRegion, CountryAndRegulation, Country, Default (lowest).
- The SP selects `MAX(RestrictionWeight)` per country × regulation × RegionByIP_ID, then reads SelectedValue from the row with that weight.
- Afghanistan example (sample): TagType=Default, SelectedValue=0, RestrictionWeight=0 — no specific rule exists, falls back to Default=Closed.
- A country-specific rule overrides the Default if it exists with a higher RestrictionWeight.
- `CountryRegionAndRegulation` tag type was added 2026-04-14 (SP change history) — supports US state + regulation granularity.

### 2.2 US State Granularity

**What**: For USA (CountryID=219) only, the table includes state-level rows via Dim_State_and_Province.

**Columns Involved**: `CountryID`, `[US State]`, `RegionByIP_ID`

**Rules**:
- For all non-US countries: `[US State]` = NULL, `RegionByIP_ID` = 0 (via ISNULL(..., 0)).
- For USA: `[US State]` = state name (e.g., 'New York'), `RegionByIP_ID` = the IP-region identifier for that state.
- This allows state-specific wallet eligibility rules (e.g., New York State may have different rules than other US states under the same regulation).

### 2.3 SelectedValue Encoding

**What**: The `SelectedValue` column encodes the wallet accessibility decision.

**Columns Involved**: `SelectedValue`, `CountryOpenforWallet`, `CountryOpenforWalletDescription`

**Rules**:
- 0 = Closed (`CountryOpenforWalletDescription` = 'Closed'): Users from this country+regulation cannot use Wallet.
- 1 = ReadOnly (`CountryOpenforWalletDescription` = 'ReadOnly'): Defined in SP but not present in current data.
- 2 = Open (`CountryOpenforWalletDescription` = 'Open'): Wallet fully accessible.
- 3 = OpenForExistingOnly (`CountryOpenforWalletDescription` = 'OpenForExistingOnly'): Existing users retain access, no new users allowed.
- `CountryOpenforWallet` is an integer passthrough of `SelectedValue` — the two columns always have the same numeric value.

### 2.4 Comparison with EXW_Coin_Transfer_Allowed_Country

**What**: The two tables produced by the same SP serve different purposes.

**Columns Involved**: All

**Rules**:
- `EXW_WalletElligibleCountries` (this table): one row per country × regulation. Answers "can the user open/access a wallet?" ResourceId=5903, resource family='AllowedUsingWalletStatus'. No crypto dimension.
- `EXW_Coin_Transfer_Allowed_Country` (documented): one row per country × playerLevel × regulation × crypto (1.74M rows). Answers "can this user type redeem this crypto in this country?" ResourceId=5903, resource name='redeem/allow'. Has crypto dimension.
- Both use the same priority resolution approach (max RestrictionWeight), but different resource name filters.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CountryID) with HEAP. 4,228 rows is small — full-table scans are fast. JOIN operations with EXW_DimUser on CountryID will benefit from distribution alignment.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Is Wallet available in Country X under Regulation Y? | `WHERE CountryID = X AND RegulationID = Y` |
| All open countries under CySEC? | `WHERE RegulationID = 1 AND CountryOpenforWallet = 2` |
| Countries open for existing users only? | `WHERE CountryOpenforWallet = 3` |
| US state-level rules? | `WHERE CountryID = 219 AND [US State] IS NOT NULL` |
| User-level eligibility (with GCID) | Use `EXW_UserSettingsWalletAllowance` (pre-resolved per GCID) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_DimUser | `CountryID = CountryID AND RegulationID = RegulationID` | Check wallet eligibility per user |
| EXW_dbo.EXW_Coin_Transfer_Allowed_Country | `CountryID = CountryID AND RegulationID = RegulationID` | Compare wallet-level vs crypto-level eligibility |
| DWH_dbo.Dim_Country | `CountryID = CountryID` | Enrich with full country metadata |

### 3.4 Gotchas

- **`CountryOpenforWallet` = `SelectedValue`**: These two columns always have the same integer value. Do not confuse them — `CountryOpenforWallet` is a direct CASE passthrough of `SelectedValue`.
- **ReadOnly (1) not present**: The SP defines SelectedValue=1 as ReadOnly, but no rows with this value exist in the current configuration. Do not assume ReadOnly is active.
- **`[US State]` has a space**: Column name `[US State]` must be bracket-quoted in all queries.
- **Default tag = no specific rule**: When TagType='Default', the country has no specific wallet configuration — it falls back to the system-wide default (currently Closed=0).
- **Full rebuild**: TRUNCATE + INSERT with no date parameter — the entire table is rebuilt on every SP run. Setting changes propagate immediately on next refresh.
- **RegionByIP_ID = 0 for non-US**: The ISNULL(..., 0) in the SP ensures RegionByIP_ID is never NULL — use `RegionByIP_ID > 0` to filter US-state rows.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo Dim tables, Dictionary source) |
| Tier 2 | Sourced from SP code / DWH computation / EXW_Settings |
| Tier 3 | Inferred from column name + context |
| Tier 4 | Best available (limited confidence) |
| Tier 5 | Glossary / domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | YES | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. HASH distribution key. (Tier 1 — Dictionary.Country upstream wiki) |
| 2 | ResourceName | varchar(100) | YES | EXW_Settings resource name for the wallet allowance configuration. Always 'AllowedUsingWalletStatus' for all rows in this table (ResourceId=5903). (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 3 | ResourceId | int | YES | EXW_Settings resource identifier. Always 5903 for all rows in this table — the wallet allowance resource. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 4 | TagType | varchar(100) | YES | Granularity type of the winning EXW_Settings rule. Values: 'CountryRegionAndRegulation'=country+US state+regulation, 'CountryAndRegion'=country+US state, 'CountryAndRegulation'=country+regulation, 'Country'=country-only, 'Default'=system fallback (no specific rule). The winning TagType reflects the most specific rule that matched. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 5 | TagValue | varchar(100) | YES | The specific tag value from EXW_Settings that matched this country+regulation combination. For CountryAndRegion: lowercase country name with underscores (e.g., 'united_states_new_york'). For Default: 'Default'. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 6 | SelectedValue | varchar(20) | YES | Raw settings value from EXW_Settings.SystemRestrictions for the winning rule. Values: 0=Closed, 1=ReadOnly (defined but not currently in use), 2=Open, 3=OpenForExistingOnly. Same as CountryOpenforWallet as an integer string. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 7 | Country | varchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dictionary.Country upstream wiki) |
| 8 | Region | varchar(100) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | CountryOpenforWallet | int | YES | Wallet accessibility decision for this country+regulation combination. 0=Closed, 1=ReadOnly, 2=Open, 3=OpenForExistingOnly. Integer passthrough of SelectedValue — always equals CAST(SelectedValue AS int). See CountryOpenforWalletDescription for the human-readable label. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 10 | US State | varchar(100) | YES | US state name (e.g., 'New York', 'California') for CountryID=219 (USA) rows. NULL for all non-US countries. Sourced from DWH_dbo.Dim_State_and_Province.Name for state-level eligibility overrides. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 11 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 — Dictionary.Country upstream wiki) |
| 12 | UpdateDate | datetime | YES | ETL refresh timestamp — GETDATE() at time of SP execution. All rows share the same UpdateDate from the last SP run. Last value: 2026-04-14. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 13 | Regulation | varchar(100) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — upstream wiki, Dictionary.Regulation) |
| 14 | RegulationID | int | YES | ETL-computed alias of regulation ID — always equals the regulation's primary key. From DWH_dbo.Dim_Regulation.DWHRegulationID. Use this column for joins to EXW_DimUser.RegulationID. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 15 | RestrictionWeight | int | YES | Priority weight of the winning EXW_Settings rule. Higher value = higher priority. The SP selects the rule with MAX(RestrictionWeight) per country × regulation × RegionByIP_ID. 0 = Default (lowest priority). (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 16 | CountryOpenforWalletDescription | varchar(256) | YES | Human-readable wallet eligibility label for this country+regulation. Values: 'Closed' (0), 'ReadOnly' (1, not in current data), 'Open' (2), 'OpenForExistingOnly' (3). Always corresponds to the CountryOpenforWallet integer value. (Tier 2 — SP_EXW_WalletElligibleCountries) |
| 17 | RegionByIP_ID | int | YES | IP-based region identifier for US state-level granularity, from DWH_dbo.Dim_State_and_Province.RegionByIP_ID. ISNULL treated as 0 for non-US countries — use RegionByIP_ID > 0 to identify US state-level rows. (Tier 2 — SP_EXW_WalletElligibleCountries) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CountryID | etoro.Dictionary.Country (via Dim_Country) | CountryID | Passthrough |
| Country | etoro.Dictionary.Country (via Dim_Country) | Name | Passthrough |
| MarketingRegionID | etoro.Dictionary.MarketingRegion (via Dim_Country) | MarketingRegionID | Passthrough |
| Regulation | etoro.Dictionary.Regulation (via Dim_Regulation) | Name | Passthrough |
| SelectedValue, TagType, TagValue, RestrictionWeight | EXW_Settings.SystemRestrictions + Tags | — | Max(RestrictionWeight) priority resolution |
| CountryOpenforWallet | — | SelectedValue | CASE 0/1/2/3 passthrough |
| CountryOpenforWalletDescription | — | SelectedValue | CASE 0/1/2/3 to human-readable string |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
EXW_Settings.Resources + SystemRestrictions + Tags (ResourceId=5903)
  + DWH_dbo.Dim_Country + Dim_State_and_Province + Dim_Regulation
  + CopyFromLake.SettingsDB_Dictionary_CountryGroup (for GeoRegistration groups)
  |-- SP_EXW_WalletElligibleCountries
  |   #prep: country × state × regulation cross-join
  |   #settings: EXW_Settings ResourceId=5903 (wallet allowance rules)
  |   #unionallowed: UNION of 5 tag-type matches
  |   #allowed: MAX(RestrictionWeight) priority resolution
  |   TRUNCATE + INSERT into EXW_WalletElligibleCountries
  |   (same SP continues to populate EXW_Coin_Transfer_Allowed_Country) ---|
  v
EXW_dbo.EXW_WalletElligibleCountries (4,228 rows)
  |-- SP_EXW_UserSettingsWalletAllowance (wallet access resolution per user) ---|
  v
EXW_dbo.EXW_UserSettingsWalletAllowance (documented, Batch 2)
  |-- (no UC migration) ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CountryID | DWH_dbo.Dim_Country | FK to country dimension |
| RegulationID | DWH_dbo.Dim_Regulation | FK to regulation dimension |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | FK to US state reference (US only) |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|---|---|
| EXW_dbo.EXW_UserSettingsWalletAllowance | SP_EXW_UserSettingsWalletAllowance reads CountryOpenforWallet/SelectedValue for user-level wallet access determination |

---

## 7. Sample Queries

### Countries open for wallet access under CySEC (RegulationID=1)

```sql
SELECT CountryID, Country, CountryOpenforWalletDescription, TagType, RestrictionWeight
FROM [EXW_dbo].[EXW_WalletElligibleCountries]
WHERE RegulationID = 1
  AND CountryOpenforWallet = 2
ORDER BY Country;
```

### US state-level wallet eligibility

```sql
SELECT CountryID, Country, [US State], RegionByIP_ID, Regulation, RegulationID, CountryOpenforWalletDescription
FROM [EXW_dbo].[EXW_WalletElligibleCountries]
WHERE CountryID = 219
  AND RegionByIP_ID > 0
ORDER BY RegulationID, [US State];
```

### Countries closed by Default tag (no specific rule configured)

```sql
SELECT Country, CountryID, COUNT(*) AS RegulationsAffected
FROM [EXW_dbo].[EXW_WalletElligibleCountries]
WHERE TagType = 'Default'
  AND CountryOpenforWallet = 0
GROUP BY Country, CountryID
ORDER BY Country;
```

---

## 8. Atlassian Knowledge Sources

No Jira issues or Confluence pages identified for this table. SP header: Author Inessa K, created 2021-04-07. Change history: 2026-04-14 added CountryRegionAndRegulation tag type; removed conversion, payment, and staking sections (those activities inactive — tables retained but not re-filled).

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 4 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 17/17, Logic: 9/10, Lineage: full*
*Object: EXW_dbo.EXW_WalletElligibleCountries | Type: Table | Production Source: EXW_Settings ResourceId=5903 + DWH Dim tables*
