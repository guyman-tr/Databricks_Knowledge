# EXW_dbo.EXW_DimUser

> 699,692-row slowly-changing dimension of all eToro Wallet (EXW) users, built from DWH_dbo.Dim_Customer filtered to active Wallet accounts via EXW_Wallet.CustomerWalletsView. Refreshed daily by SP_DimUser using SCD Type 1 (overwrite on change). Serves as the central customer JOIN target for all EXW analytics — balance, transaction, compliance, and regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Dimension) |
| **Production Source** | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) |
| **Writer SP** | EXW_dbo.SP_DimUser |
| **Refresh** | Daily; SCD Type 1 (INSERT new Wallet users + UPDATE changed attributes) |
| **Row Count** | 699,692 (as of April 2026) |
| **Date Range** | UpdateDate: 2021-05-24 to 2026-04-12 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX (GCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_DimUser is the primary customer dimension for the eToro Wallet (EXW) analytics schema. It contains one row per Wallet user — a customer who has an active Wallet account as identified by EXW_Wallet.CustomerWalletsView. As of April 2026 it holds 699,692 users, with daily incremental refreshes by SP_DimUser.

The table is populated by joining the Wallet user list (CustomerWalletsView) to DWH_dbo.Dim_Customer, enriching each user with country, regulation, player level, and state/province attributes from DWH dimension tables. Two EXW-specific flags are computed: **IsTestAccount** (from EXW_TestUsers) and **ComplianceClosureEvent** (from EXW_WalletClosedCountryProjects — 1 if the user's country has had its Wallet service closed/compensated).

SP_DimUser uses a three-step merge pattern:
1. Identify new GCIDs (in CustomerWalletsView but not yet in EXW_DimUser) → INSERT
2. Identify changed attributes for existing users → UPDATE (triggers UpdateDate = GETDATE())
3. Previously deleted wallet users are NOT removed (commented-out DELETE section in the SP)

Regulation breakdown: CySEC (44.5%), FCA (28%), FinCEN+FINRA (8.8%), BVI (4.6%), FSA Seychelles (4.4%), ASIC & GAML (3.9%). ComplianceClosureEvent=1 for 15.3% of users (106,783 users in closed-wallet countries).

---

## 2. Business Logic

### 2.1 Wallet User Scope

**What**: Only customers with an active Wallet account are included. The Wallet user list is sourced from EXW_Wallet.CustomerWalletsView, which is the authoritative live list of wallet holders.

**Columns Involved**: GCID, RealCID

**Rules**:
- Only GCIDs present in EXW_Wallet.CustomerWalletsView are included
- EXW_DimUser.GCID ← joined from CustomerWalletsView + DWH_dbo.Dim_Customer
- Users who leave the Wallet system are NOT deleted from EXW_DimUser (DELETE step is commented out in SP_DimUser)

### 2.2 Test Account Identification

**What**: Users identified as internal/test accounts are flagged via IsTestAccount.

**Columns Involved**: IsTestAccount, GCID

**Rules**:
- `IsTestAccount = 1` when GCID appears in EXW_dbo.EXW_TestUsers (test user allowlist)
- `IsTestAccount = 0` otherwise
- 132 test accounts in current data (out of 699,692)

### 2.3 Compliance Closure Flag

**What**: Users whose country of residence is in a Wallet closure/compensation project are flagged.

**Columns Involved**: ComplianceClosureEvent, CountryID, RegulationID

**Rules**:
- `ComplianceClosureEvent = 1` when a row exists in EXW_WalletClosedCountryProjects matching the user's CountryID AND (RegulationID matches OR cp.RegulationID IS NULL)
- `ComplianceClosureEvent = 0` otherwise
- 106,783 users (15.3%) flagged — countries that had Wallet service closed and users compensated

### 2.4 Derived Dimension Enrichment

**What**: Several columns are denormalized from DWH dimension tables for query convenience.

**Columns Involved**: Country, RegionID, Region, Regulation, UserRegion_State, Club

**Rules**:
- `Country` ← Dim_Country.Name (text label, not a FK — use CountryID for joins)
- `RegionID` ← Dim_Country.MarketingRegionID (marketing region grouping)
- `Region` ← Dim_Country.Region (marketing region name string)
- `Regulation` ← Dim_Regulation.Name (text label; use RegulationID for joins)
- `UserRegion_State` ← Dim_State_and_Province.Name joined on Dim_Customer.RegionID = RegionByIP_ID
- `Club` ← Dim_PlayerLevel.Name (Bronze, Silver, Gold, Platinum, Diamond level labels)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CLUSTERED INDEX(GCID). All depth-4 EXW fact tables are also distributed on HASH(GCID), enabling co-located JOINs with zero data movement for the most common analytical join pattern: `EXW_FactBalance JOIN EXW_DimUser ON GCID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Wallet user count by regulation | `SELECT RegulationID, Regulation, COUNT(*) FROM EXW_DimUser GROUP BY RegulationID, Regulation ORDER BY COUNT(*) DESC` |
| Exclude test users from analysis | `WHERE IsTestAccount = 0` |
| Users in closed-wallet countries | `WHERE ComplianceClosureEvent = 1` |
| Valid customers only | `WHERE IsValidCustomer = 1` |
| Fully KYC-verified users | `WHERE VerificationLevelID = 3` |
| US state breakdown | `WHERE RegulationID IN (7,8,12,14) AND UserRegion_State IS NOT NULL GROUP BY UserRegion_State` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_FactBalance | `EXW_FactBalance.GCID = EXW_DimUser.GCID` | Enrich balance data with user attributes |
| EXW_dbo.EXW_AMLProviderID | `EXW_AMLProviderID.GCID = EXW_DimUser.GCID` | Join AML provider data to user profiles |
| EXW_dbo.EXW_WalletRegulation | `EXW_WalletRegulation.GCID = EXW_DimUser.GCID` | Join regulation history to current user profile |
| DWH_dbo.Dim_Customer | `DWH_dbo.Dim_Customer.GCID = EXW_DimUser.GCID` | Enrich with full DWH customer attributes not in EXW_DimUser |

### 3.4 Gotchas

- **GCID vs RealCID**: Use GCID as the primary join key (HASH distribution key). RealCID joins to Dim_Customer but may be less optimal for co-location.
- **Deleted wallet users are NOT removed**: SP_DimUser has its DELETE step commented out. Users who close their Wallet remain in EXW_DimUser indefinitely. Always filter with live wallet status if currency matters.
- **Country/Regulation text columns are denormalized**: `Country` and `Regulation` are text labels for readability. For joins and aggregation, always use `CountryID` and `RegulationID`.
- **ComplianceClosureEvent is point-in-time**: If a country is added to EXW_WalletClosedCountryProjects, existing users are updated on the next SP_DimUser run. Users who moved to a closed country after closure will have ComplianceClosureEvent=1 if their current CountryID is now in the closure list.
- **UpdateDate is last-changed timestamp**: Reflects when SP_DimUser last updated THIS row, not the original registration date. For registration dates, join to DWH_dbo.Dim_Customer.RegisteredReal.
- **Club may be NULL**: If Dim_PlayerLevel has no match for a given PlayerLevelID, Club will be NULL. The seven known PlayerLevelID values in EXW_DimUser are 1, 2, 3, 4, 5, 6, 7.
- **UserRegion_State is US/Canada/Australia focused**: Only populated where Dim_State_and_Province has a RegionByIP_ID match. Most records have NULL for UserRegion_State.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (Customer.CustomerStatic or BackOffice.Customer via Dim_Customer) |
| Tier 2 | Derived from SP code (computed, join-derived, or renamed from a Tier 2 DWH column) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key and CLUSTERED INDEX key for this table. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | Username | varchar(100) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 4 | FirstName | nvarchar(50) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 5 | LastName | nvarchar(50) | YES | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 6 | PlayerLevelID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 7 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 8 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 9 | Country | varchar(100) | YES | Denormalized country name from DWH_dbo.Dim_Country.Name, joined on CountryID. Use CountryID for joins; this is a readability label. (Tier 2 — SP_DimUser) |
| 10 | RegionID | int | YES | Marketing region ID from DWH_dbo.Dim_Country.MarketingRegionID, derived from the user's CountryID. Corresponds to geographic marketing groupings (Africa, UK, North Europe, Arabic GCC, etc.). (Tier 2 — SP_DimUser) |
| 11 | Region | varchar(100) | YES | Marketing region name from DWH_dbo.Dim_Country.Region, derived from CountryID. Text label corresponding to RegionID. Use RegionID for aggregation. (Tier 2 — SP_DimUser) |
| 12 | IsTestAccount | int | YES | 1 if this user's GCID appears in EXW_dbo.EXW_TestUsers (internal/beta test accounts); 0 otherwise. Computed by SP_DimUser via LEFT JOIN. Always filter IsTestAccount=0 in production analytics. (Tier 2 — SP_DimUser) |
| 13 | CreditReportValid | int | YES | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. Renamed from Dim_Customer.IsCreditReportValidCB. (Tier 2 — SP_Dim_Customer) |
| 14 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT time and refreshed on UPDATE when any tracked attribute changes. Reflects last SP_DimUser write for this row. Range: 2021-05-24 to 2026-04-12. (Tier 2 — SP_DimUser) |
| 15 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 16 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. (Tier 1 — BackOffice.Customer) |
| 17 | Regulation | varchar(100) | YES | Denormalized regulation name from DWH_dbo.Dim_Regulation.Name, joined on RegulationID. Use RegulationID for joins. (Tier 2 — SP_DimUser) |
| 18 | UserRegionID | int | YES | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. DWH note: mapped from Dim_Customer.RegionID (state/province region by IP). (Tier 1 — Customer.CustomerStatic) |
| 19 | UserRegion_State | varchar(100) | YES | State or province name from DWH_dbo.Dim_State_and_Province, joined on Dim_Customer.RegionID = RegionByIP_ID. Populated mainly for US, Canada, and Australian users. NULL for most non-US users. (Tier 2 — SP_DimUser) |
| 20 | Club | varchar(100) | YES | Player level club label from DWH_dbo.Dim_PlayerLevel.Name, joined on PlayerLevelID. Common values: Bronze, Silver, Gold, Platinum, Diamond. COLLATE Latin1_General_100_BIN applied on UPDATE to handle Unicode comparisons. (Tier 2 — SP_DimUser) |
| 21 | ComplianceClosureEvent | int | YES | 1 if this user's CountryID (and optionally RegulationID) appears in EXW_dbo.EXW_WalletClosedCountryProjects (country had Wallet service closed); 0 otherwise. Computed by SP_DimUser via LEFT JOIN on CountryID with NULL-coalesce on RegulationID. (Tier 2 — SP_DimUser) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via Dim_Customer |
| RealCID | etoro.Customer.CustomerStatic | RealCID | Passthrough via Dim_Customer |
| Username | etoro.Customer.CustomerStatic | UserName | Renamed; COLLATE applied |
| FirstName | etoro.Customer.CustomerStatic | FirstName | Passthrough; COLLATE applied |
| LastName | etoro.Customer.CustomerStatic | LastName | Passthrough; COLLATE applied |
| PlayerLevelID | etoro.Customer.CustomerStatic | PlayerLevelID | Passthrough |
| VerificationLevelID | etoro.BackOffice.Customer | VerificationLevelID | Passthrough |
| CountryID | etoro.Customer.CustomerStatic | CountryID | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID |
| RegionID | DWH_dbo.Dim_Country | MarketingRegionID | JOIN on CountryID |
| Region | DWH_dbo.Dim_Country | Region | JOIN on CountryID |
| IsTestAccount | EXW_dbo.EXW_TestUsers | GCID | CASE WHEN JOIN match THEN 1 ELSE 0 |
| CreditReportValid | DWH_dbo.Dim_Customer (computed) | IsCreditReportValidCB | Renamed; DWH-computed |
| UpdateDate | — | — | GETDATE() |
| IsValidCustomer | DWH_dbo.Dim_Customer (computed) | IsValidCustomer | Passthrough of DWH-computed flag |
| RegulationID | etoro.BackOffice.Customer | RegulationID | Passthrough via Dim_Customer |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationID |
| UserRegionID | etoro.Customer.CustomerStatic | RegionID | Renamed |
| UserRegion_State | DWH_dbo.Dim_State_and_Province | Name | JOIN on RegionByIP_ID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| ComplianceClosureEvent | EXW_dbo.EXW_WalletClosedCountryProjects | CountryID | CASE WHEN JOIN match THEN 1 ELSE 0 |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic (production OLTP) + etoro.BackOffice.Customer
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Customer_CustomerStatic
  |-- SP_Dim_Customer ---|
  v
DWH_dbo.Dim_Customer (107-column full customer dimension)
  |                                          |
  |-- SP_DimUser (INNER JOIN on RealCID) ---|
  |        + Wallet scope filter                |
  |   (CustomerWalletsView INNER JOIN)     ---|
  v
EXW_dbo.EXW_DimUser (699,692 Wallet users)
  |-- enriched via JOINs:
  |     Dim_Country (Country, RegionID, Region)
  |     Dim_Regulation (Regulation)
  |     Dim_State_and_Province (UserRegion_State)
  |     Dim_PlayerLevel (Club)
  |     EXW_TestUsers (IsTestAccount)
  |     EXW_WalletClosedCountryProjects (ComplianceClosureEvent)
  v
[Downstream: EXW_AMLProviderID, EXW_FactBalance, EXW_WalletRegulation, and 15+ EXW SPs]

Note: No UC export (UC Target: _Not_Migrated — to be confirmed)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | Source of all customer attributes; EXW_DimUser is a Wallet-scoped subset |
| CountryID | DWH_dbo.Dim_Country | Country dimension; source of Country, RegionID, Region |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation dimension; source of Regulation text label |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Player level dimension; source of Club label |
| UserRegionID | DWH_dbo.Dim_State_and_Province | State/province dimension; source of UserRegion_State |
| GCID | EXW_dbo.EXW_TestUsers | Test user flag source |
| CountryID+RegulationID | EXW_dbo.EXW_WalletClosedCountryProjects | Compliance closure flag source |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| EXW_dbo.EXW_AMLProviderID | LEFT JOIN on GCID for user identification |
| EXW_dbo.EXW_FactBalance | JOIN on GCID for balance + user attributes |
| EXW_dbo.EXW_WalletRegulation | JOIN on GCID for regulatory tracking |
| EXW_dbo.EXW_FactTransactions | JOIN on GCID for transaction reporting |
| Multiple EXW depth-4/5 tables | Central JOIN hub for EXW analytics layer |

---

## 7. Sample Queries

### Wallet user count by regulation (exclude test accounts)

```sql
SELECT RegulationID, Regulation, COUNT(*) AS user_count
FROM [EXW_dbo].[EXW_DimUser]
WHERE IsTestAccount = 0
GROUP BY RegulationID, Regulation
ORDER BY user_count DESC;
```

### Users in closed-wallet countries by regulation

```sql
SELECT Regulation, RegulationID, Country, CountryID,
       COUNT(*) AS affected_users
FROM [EXW_dbo].[EXW_DimUser]
WHERE ComplianceClosureEvent = 1
  AND IsTestAccount = 0
GROUP BY Regulation, RegulationID, Country, CountryID
ORDER BY affected_users DESC;
```

### Fully KYC-verified wallet users by country

```sql
SELECT CountryID, Country, RegulationID, Regulation,
       COUNT(*) AS verified_count
FROM [EXW_dbo].[EXW_DimUser]
WHERE VerificationLevelID = 3
  AND IsTestAccount = 0
  AND IsValidCustomer = 1
GROUP BY CountryID, Country, RegulationID, Regulation
ORDER BY verified_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for EXW_DimUser specifically. The table is the primary customer dimension for the EXW analytics layer — closely aligned with DWH_dbo.Dim_Customer documentation (see Dim_Customer wiki for upstream context).

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 10 T1, 11 T2, 0 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 9/10, Source: Customer.CustomerStatic + BackOffice.Customer*
*Object: EXW_dbo.EXW_DimUser | Type: Table | Production Source: etoro.Customer.CustomerStatic (via Dim_Customer)*
