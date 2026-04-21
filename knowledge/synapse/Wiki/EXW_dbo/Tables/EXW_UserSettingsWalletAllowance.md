# EXW_dbo.EXW_UserSettingsWalletAllowance

> One-row-per-Wallet-user allowance decision table. Stores the resolved Wallet access status (Allowed / ReadOnly / NotAllowed) for all 699,692 EXW users, together with the winning settings tag, compensation flags, and compliance closure indicators. Rebuilt daily by SP_EXW_UserSettingsWalletAllowance via TRUNCATE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Allowance / Settings Resolution) |
| **Production Source** | EXW_Settings system (Tags, SystemRestrictions, GcidToDynamicGroups) + EXW_DimUser |
| **Writer SP** | EXW_dbo.SP_EXW_UserSettingsWalletAllowance |
| **Refresh** | Daily; TRUNCATE + INSERT (full rebuild) |
| **Row Count** | 699,692 (as of April 2026; 1 row per GCID) |
| **Date Range** | AllowanceBeginDate: NULL–2026-04-13; UpdateDate: 2026-04-13 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_UserSettingsWalletAllowance holds the resolved Wallet access decision for every EXW user. Each row answers one question: **can this customer use their eToro Wallet right now?** The three possible answers are `Allowed`, `ReadOnly`, and `NotAllowed`.

As of April 2026: 604,796 users are Allowed (86.4%), 15,028 are ReadOnly (2.1%), and 79,868 are NotAllowed (11.4%).

The resolution logic applies a five-level priority system. Country + Regulation rules take highest precedence; customer-level individual overrides from the Settings database take second highest. The SP evaluates all applicable rules and selects the one with the highest `RestrictionWeight`, recording the winning tag and raw value alongside the resolved allowance string.

Compensation and compliance closure columns surface two compliance-driven overlays: whether the user was financially compensated as part of a Wallet closure project (Compensated, CompensationDate, Project), and whether the user's country of residence has ever had a Wallet closure event (ComplianceClosureEvent). 51,895 users (7.4%) are compensated; 18,690 (2.7%) have a ComplianceClosureEvent flag.

---

## 2. Business Logic

### 2.1 Five-Priority Settings Resolution

**What**: The SP evaluates all applicable settings rules from EXW_Settings.SystemRestrictions (ResourceId=5903) for each user and selects the one with the highest RestrictionWeight. Rules are ranked in a five-tier priority hierarchy.

**Columns Involved**: UserWalletAllowance, TagType, TagValue, SelectedValue, AllowanceBeginDate

**Priority Order** (highest weight wins):
| Priority | TagType | Matching Dimension |
|----------|---------|-------------------|
| 1 — highest | CountryRegionAndRegulation | User's CountryID + RegionID (US only) + RegulationID |
| 2 | CountryAndRegulation | User's CountryID + RegulationID |
| 3 | CountryAndRegion | User's CountryID + RegionID |
| 4 | DynamicGroup | User's group membership (EXW_Settings.GcidToDynamicGroups) |
| 5 | CustomerData | Individual GCID override (EXW_Settings.GcidToDynamicGroups ResourceId=35467) |

**Rules**:
- Country/Region rules match via LOWER(Dim_Country.Name) or LOWER(Dim_State_and_Province.Name) against EXW_Settings.Tags.TagValue
- CustomerData overrides apply when a user has an individual entry in EXW_Settings (ResourceId=35467); `IsCustomerLevelWin` flag determines tie-breaking vs group rules
- External_WalletDB_Eligibility_StatusMap is consulted when a group rule exists alongside a customer-level override — StatusMap determines which takes precedence
- TagValue is stored lowercase (e.g., `"israel"`, `"united kingdom"`, `"fca"`, or a GCID string for individual overrides)
- TagType distribution: CountryAndRegion=612,481 (87.5%), CustomerData=72,461 (10.4%), DynamicGroup=7,971 (1.1%)

### 2.2 SelectedValue → UserWalletAllowance Mapping

**What**: The raw integer settings value (SelectedValue) is mapped to a human-readable allowance string.

**Columns Involved**: SelectedValue, UserWalletAllowance

**Rules**:
| SelectedValue | UserWalletAllowance | Meaning |
|---------------|---------------------|---------|
| 0 | NotAllowed | Wallet access fully blocked |
| 1 | ReadOnly | Wallet visible but no transactions permitted |
| 2 | Allowed | Full Wallet access |
| 3 | AllowedForExistingUsers | Allowed (mapped to `Allowed` in UserWalletAllowance CASE) |
| other/NULL | NotAllowed | Fallback — unknown values treated as blocked |

### 2.3 Compensation Flags

**What**: Users who were financially compensated as part of a Wallet country-closure project have compensation metadata stored in three columns.

**Columns Involved**: Compensated, CompensationDate, Project

**Rules**:
- `Compensated = 1` when the user's GCID appears in EXW_CompensationClosingCountries with matching criteria and a non-NULL CompensationDate; 51,895 users (7.4%)
- `CompensationDate` = TOP 1 CompensationDate per GCID ordered by DateClosure DESC (most recent closure event)
- `Project` = TOP 1 Project label per GCID ordered by DateClosure DESC; project letters correspond to closure country batches (e.g., A=31 countries, B=35 countries)
- `Compensated = 0` users still have NULL for CompensationDate and Project

### 2.4 Compliance Closure Flag

**What**: Flags users in a country that has undergone a formal Wallet closure event, regardless of individual compensation status.

**Columns Involved**: ComplianceClosureEvent

**Rules**:
- `ComplianceClosureEvent = 1` when the user's CountryID (and optionally RegulationID) appears in EXW_WalletClosedCountryProjects
- RegulationID in EXW_WalletClosedCountryProjects is NULL for 78/89 rows — most closure events apply globally regardless of regulation
- 18,690 users (2.7%) currently flagged

### 2.5 Dual-Writer: EXW_AML_Users_Report

**What**: SP_EXW_UserSettingsWalletAllowance also writes EXW_AML_Users_Report in the same execution. Both tables are produced from the same base CTEs and temp tables built during the run.

**Implication**: A failure in the SP will affect both EXW_UserSettingsWalletAllowance AND EXW_AML_Users_Report. Downstream consumers of either table share the same refresh dependency.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) / HEAP. Joins to EXW_DimUser (also HASH(GCID)) are co-located and zero data-movement. HEAP means no clustered scan advantage; always filter on GCID or project narrow aggregations.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count users by allowance status | `SELECT UserWalletAllowance, COUNT(*) FROM EXW_UserSettingsWalletAllowance GROUP BY UserWalletAllowance` |
| Find blocked users in a specific country | JOIN to EXW_DimUser on GCID, filter `ud.CountryID = X AND uwa.UserWalletAllowance = 'NotAllowed'` |
| Individual overrides only | `WHERE TagType = 'CustomerData'` |
| Compensated users with project detail | `WHERE Compensated = 1` — CompensationDate and Project are populated |
| Country-rule winners | `WHERE TagType IN ('CountryAndRegion', 'CountryAndRegulation', 'CountryRegionAndRegulation')` |
| Allowance with regulation breakdown | JOIN EXW_DimUser → GROUP BY RegulationID, UserWalletAllowance |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_UserSettingsWalletAllowance.GCID` | Enrich allowance decision with user attributes (country, regulation) |
| EXW_dbo.EXW_CompensationClosingCountries | `GCID` | Lookup compensation metadata; already denormalized in this table |

### 3.4 Gotchas

- **AllowanceBeginDate is NULL for ~1,672 users**: Rows with no BeginDate in the winning restriction have NULL here; treat NULL as "no effective date" not "not applicable"
- **UserWalletAllowance is NCHAR(50)**: Always compare with N'' literal or TRIM — trailing spaces may be present due to fixed-length nchar type
- **TagValue is lowercase**: Stored as lowercase string; do not compare case-sensitively to lookup values
- **Compensated=0 does not mean no closure**: ComplianceClosureEvent=1 + Compensated=0 means the user is in a closed-wallet country but has not received compensation (yet, or ever)
- **SelectedValue=3 (AllowedForExistingUsers)**: Present in raw settings but collapsed to `Allowed` in UserWalletAllowance CASE — consumers relying on UserWalletAllowance will not see this distinction
- **Daily full rebuild**: TRUNCATE means the table is briefly empty between TRUNCATE and INSERT; queries during the window return no rows

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (Customer.CustomerStatic or BackOffice.Customer via Dim_Customer) |
| Tier 2 | Derived from SP code (computed, join-derived, or renamed from a source column) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | UserWalletAllowance | nchar(50) | YES | Resolved Wallet access decision. Values: 'Allowed' (86.4% — 604,796 users), 'NotAllowed' (11.4% — 79,868 users), 'ReadOnly' (2.1% — 15,028 users). Derived from SelectedValue CASE: 0→NotAllowed, 1→ReadOnly, 2 or 3→Allowed, else→NotAllowed. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 4 | TagType | varchar(100) | YES | Tag type of the winning settings rule. Identifies the dimension (geography tier or individual) that produced the allowance decision. Values: CountryAndRegion (87.5%), CustomerData (10.4%), DynamicGroup (1.1%), CountryAndRegulation, CountryRegionAndRegulation. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 5 | TagValue | varchar(100) | YES | Tag value of the winning settings rule. Lowercase country name, regulation name, group name, or GCID string depending on TagType. Example: 'israel', 'united kingdom', 'fca', or a GCID numeric string for CustomerData overrides. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 6 | SelectedValue | int | YES | Raw integer value from the winning EXW_Settings.SystemRestrictions rule. 0=NotAllowed, 1=ReadOnly, 2=Allowed, 3=AllowedForExistingUsers. Source of UserWalletAllowance before CASE mapping. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 7 | AllowanceBeginDate | datetime | YES | BeginDate of the winning settings restriction from EXW_Settings.SystemRestrictions. NULL for approximately 1,672 users where the winning rule has no BeginDate. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 8 | Compensated | int | YES | 1 if the user's GCID appears in EXW_CompensationClosingCountries with a qualifying CompensationDate; 0 otherwise. 51,895 users (7.4%) are compensated. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 9 | ComplianceClosureEvent | int | YES | 1 if the user's CountryID (optionally RegulationID) is found in EXW_WalletClosedCountryProjects, indicating the user is in a country that has had a Wallet closure event. 18,690 users (2.7%). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 10 | CompensationDate | date | YES | Date the user was compensated. TOP 1 per GCID ordered by DateClosure DESC (most recent closure event). NULL when Compensated=0. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 11 | Project | varchar(100) | YES | Closure project identifier for the compensation event. TOP 1 per GCID ordered by DateClosure DESC. Project letters map to country-closure batches (A=31, B=35, C=15, D=4, E=1, F=2, H=1 rows in EXW_WalletClosedCountryProjects). NULL when Compensated=0. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 12 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT. Reflects the last TRUNCATE+INSERT cycle. All rows share the same UpdateDate per daily run. Current value: 2026-04-13. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |

---

## 5. Lineage

See [`EXW_UserSettingsWalletAllowance.lineage.md`](EXW_UserSettingsWalletAllowance.lineage.md) for full column-level lineage.

**Tier Summary**: 2 Tier 1 | 10 Tier 2 | 0 Tier 3 | 0 Tier 4

| Source Object | Columns Sourced |
|---------------|----------------|
| EXW_dbo.EXW_DimUser | GCID (T1), RealCID (T1) |
| EXW_Settings.Tags | TagType, TagValue |
| EXW_Settings.SystemRestrictions | SelectedValue, AllowanceBeginDate |
| EXW_Settings.GcidToDynamicGroups | DynamicGroup membership (TagType/TagValue) |
| CopyFromLake.SettingsDB_Dictionary_DynamicGroup | DynamicGroup name resolution |
| BI_DB_dbo.External_WalletDB_Eligibility_StatusMap | Group vs customer-level conflict resolution |
| BI_DB_dbo.External_SettingsDB_DWH_V_CustomerDataWallet | CustomerData individual overrides |
| EXW_dbo.EXW_CompensationClosingCountries | Compensated, CompensationDate, Project |
| EXW_dbo.EXW_WalletClosedCountryProjects | ComplianceClosureEvent |
| DWH_dbo.Dim_State_and_Province | US regional rule matching (TagValue resolution) |

---

## 6. Relationships

### Upstream (Sources)

| Object | Relationship |
|--------|-------------|
| EXW_dbo.EXW_DimUser | JOIN on GCID — provides GCID scope and RealCID |
| EXW_Settings.Tags | Settings tag definitions (TagType, TagValue) |
| EXW_Settings.SystemRestrictions | Allowance rules per tag for ResourceId=5903 |
| EXW_Settings.GcidToDynamicGroups | User-to-dynamic-group membership |
| CopyFromLake.SettingsDB_Dictionary_DynamicGroup | Dynamic group name lookup |
| BI_DB_dbo.External_WalletDB_Eligibility_StatusMap | Conflict resolution between group and customer-level rules |
| BI_DB_dbo.External_SettingsDB_DWH_V_CustomerDataWallet | Individual customer overrides (ResourceId=35467) |
| EXW_dbo.EXW_CompensationClosingCountries | Compensation metadata (Compensated, CompensationDate, Project) |
| EXW_dbo.EXW_WalletClosedCountryProjects | ComplianceClosureEvent source |
| DWH_dbo.Dim_State_and_Province | US state/province name resolution for regional rules |

### Downstream (Consumers)

| Object | Relationship |
|--------|-------------|
| EXW_dbo.GetProviderUserIDNormalized (view) | Reads UserWalletAllowance — used in AML provider user ID lookups |
| EXW_dbo.SP_EXW_FinanceReportsBalancesNew | References allowance status for balance reporting scope |
| EXW_dbo.SP_EXW_WalletEntity | Joins allowance table for entity-level reporting |
| EXW_dbo.SP_EXW_CompensationClosingCountries | Uses allowance context in compensation workflows |
| BI_DB_dbo.SP_W_Tue_Email_for_KYT | Reads allowance and compensation flags for weekly KYT email targeting |
| JUNK_SP_AML_Email_for_KYT | Legacy AML email targeting — reads this table |

### Co-written by Same SP

| Object | Relationship |
|--------|-------------|
| EXW_dbo.EXW_AML_Users_Report | Written by the same SP (SP_EXW_UserSettingsWalletAllowance) in the same daily run |

---

## 7. Sample Queries

```sql
-- Allowance distribution across all Wallet users
SELECT
    UserWalletAllowance,
    COUNT(*)           AS UserCount,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS decimal(5,2)) AS Pct
FROM EXW_dbo.EXW_UserSettingsWalletAllowance
GROUP BY UserWalletAllowance
ORDER BY UserCount DESC;
```

```sql
-- Blocked users by regulation — which regulatory entity has the most blocked users?
SELECT
    ud.RegulationID,
    ud.Regulation,
    uwa.UserWalletAllowance,
    COUNT(*)           AS UserCount
FROM EXW_dbo.EXW_UserSettingsWalletAllowance uwa
JOIN EXW_dbo.EXW_DimUser ud ON ud.GCID = uwa.GCID
WHERE uwa.UserWalletAllowance = 'NotAllowed'
  AND ud.IsTestAccount = 0
GROUP BY ud.RegulationID, ud.Regulation, uwa.UserWalletAllowance
ORDER BY UserCount DESC;
```

```sql
-- Individual customer overrides (CustomerData tag type) — who has a personal allowance rule?
SELECT
    uwa.GCID,
    ud.RealCID,
    uwa.UserWalletAllowance,
    uwa.SelectedValue,
    uwa.TagValue,
    uwa.AllowanceBeginDate
FROM EXW_dbo.EXW_UserSettingsWalletAllowance uwa
JOIN EXW_dbo.EXW_DimUser ud ON ud.GCID = uwa.GCID
WHERE uwa.TagType = 'CustomerData'
ORDER BY uwa.AllowanceBeginDate DESC;
```

```sql
-- Compensated users with project and compensation date
SELECT
    uwa.GCID,
    ud.CountryID,
    ud.Country,
    uwa.Project,
    uwa.CompensationDate,
    uwa.UserWalletAllowance,
    uwa.ComplianceClosureEvent
FROM EXW_dbo.EXW_UserSettingsWalletAllowance uwa
JOIN EXW_dbo.EXW_DimUser ud ON ud.GCID = uwa.GCID
WHERE uwa.Compensated = 1
ORDER BY uwa.CompensationDate DESC;
```

---

## 8. Atlassian

No Atlassian MCP results available for this object. Check Confluence for EXW_Settings ResourceId=5903 documentation, Wallet closure project records, and compensation project scope definitions.
