# DWH_dbo.Dim_Affiliate

> Denormalized affiliate partner dimension — combines AffWizz affiliate profile, channel/sub-channel classification, trading account linkage, and aggregated registration/FTD/FTDe metrics across multiple time windows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Row Count** | Low thousands (one row per affiliate partner) |
| **Production Source** | `fiktivo_dbo.tblaff_Affiliates` (AffWizz) via `Ext_Dim_Channel_Affiliate_UnifyCode` |
| **Refresh** | Daily full reload (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (AffiliateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` |
| **UC Target (PII)** | `pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate` |
| **UC Masked Columns** | Email,City |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Affiliate` is the master dimension for eToro's affiliate marketing partners. Each row represents one affiliate partner (identified by `AffiliateID`), combining:

- **Profile data** from the AffWizz affiliate management system (contact, company, website, login credentials)
- **Channel classification** (SubChannel, Channel) from the unified channel mapping
- **Trading account linkage** — resolving up to 4 username variants to find the affiliate's own eToro trading account
- **Performance aggregates** — Registration, FTD (First Time Deposit), and FTDe (First Time Deposit equivalent) counts across 7 time windows each (Yesterday, ThisMonth, LastMonth, ThisQuarter, LastQuarter, ThisYear, LastYear, Lifetime)
- **Contract classification** — affiliate payment model derived from ContractName keywords

The table answers: "Who is this affiliate, how are they classified, what contract do they have, and what are their referral performance metrics?"

### Key Business Concepts

- **FTD vs FTDe**: FTD = First Time Deposit (real money). FTDe = First Time Deposit equivalent (includes demo-to-real conversions or other qualifying events)
- **SubChannel/Channel**: Marketing classification inherited from `Ext_Dim_SubChannel_UnifyCode` — same logic as `Dim_Channel` (see Dim_Channel.md)
- **MasterAffiliateID**: Hierarchical relationship — some affiliates operate under a master affiliate umbrella
- **ContractType**: Numerically encoded payment model (0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=0-Commission, 8=CPL/CPR)

---

## 2. Business Logic

### 2.1 ContractType Classification

**What**: Derives the affiliate payment model from the free-text `ContractName` field.

**Columns Involved**: ContractType, ContractName, AffiliateID, Channel

**Rules** (evaluated in order, first match wins):
```
AffiliateID IN (12306, 14596, 30122, 37665, 18230) → 6 (eCost — hardcoded overrides)
ContractName LIKE '%internal campaigns%'             → 6 (eCost)
ContractName LIKE '%rev%' AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rev%'                            → 3 (RevShare)
ContractName LIKE '%rs%'                             → 3 (RevShare)
ContractName LIKE '%cpa%'                            → 2 (CPA)
ContractName LIKE '%plan%'                           → 2 (CPA)
ContractName LIKE '%mati%' AND '%cpl%'               → 8 (CPL)
ContractName LIKE '%mati%' AND '%%%'                 → 3 (RevShare)
ContractName LIKE '%cpl%'                            → 8 (CPL)
ContractName LIKE '%cpr%'                            → 8 (CPR)
Channel = 'Affiliate' AND ContractName LIKE '%0 commission%' → 7 (Zero Commission)
ELSE                                                 → 0 (N/A)
```

### 2.2 Trading Account Resolution

**What**: Links affiliate to their own eToro trading account using COALESCE across 4 username lookups.

**Columns Involved**: TradingAccount_RealCID, TradingAccount_UserName

**Rules**:
```
TradingAccount_RealCID = COALESCE(BO1.CID, BO2.CID, BO3.CID, BO4.CID)
TradingAccount_UserName = COALESCE(BO1.UserName, BO2.UserName, BO3.UserName, BO4.UserName)

Where BO1..BO4 = Ext_Dim_Affiliate_Customer joined on UserName1..UserName4
Collation: Latin1_General_BIN (case-sensitive, binary comparison)
```

### 2.3 SubChannel/Channel Inheritance

**What**: SubChannelID, SubChannel, and Channel are inherited from `Ext_Dim_SubChannel_UnifyCode`, joined on AffiliateID.

**Logic**: Same unified classification as Dim_Channel — see `Dim_Channel.md` for the full SubChannelID-to-Channel mapping rules.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is `REPLICATE` — a full copy exists on every compute node. JOINs with fact tables (which are typically HASH-distributed) will always use local data. The CLUSTERED INDEX on AffiliateID supports equality lookups and range scans.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliate performance summary | `SELECT * FROM Dim_Affiliate WHERE AffiliateID = @id` |
| All affiliates in a channel | `WHERE Channel = 'Affiliate'` or `Channel = 'Organic'` |
| Active affiliates | `WHERE AccountActivated = 1` |
| Hierarchy — sub-affiliates | `WHERE MasterAffiliateID = @masterAffId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Channel | ON SubChannelID = SubChannelID | Channel attributes (but Dim_Affiliate already has SubChannel/Channel) |
| DWH_dbo.Dim_Customer | ON AffiliateID = AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Affiliate country name |
| DWH_dbo.Fact_AffiliateCommission | ON AffiliateID = AffiliateID | Commission payments |

### 3.4 Gotchas

- **Masked columns**: `Email` and `City` are masked with `default()` — users without UNMASK permission see obfuscated values
- **ContractType is computed**: Derived from ContractName pattern matching. Not a source value. If ContractName doesn't match any rule → 0 (N/A)
- **TradingAccount_RealCID can be NULL**: If none of the 4 username variants resolve to an eToro user
- **Registration/FTD metrics are pre-aggregated**: These are period-level counts, not row-level data. They come from separate staging tables (`Ext_Dim_Affiliate_Registrations`, `Ext_Dim_Affiliate_FTD`, `Ext_Dim_Affiliate_FTDe`)

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | NO | Unique affiliate partner identifier from AffWizz system. Primary key. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 2 | DateCreated | datetime | NO | Date the affiliate was created/registered in AffWizz. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 3 | SubChannelID | tinyint | NO | Marketing sub-channel identifier. JOINs to Dim_Channel.SubChannelID. Values: 1=Affiliate Partners, 2=SEM, 3=SEO, etc. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 4 | Contact | nvarchar(1000) | YES | Primary contact information for the affiliate partner. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 5 | ContractName | nvarchar(100) | YES | Free-text name of the affiliate's contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 6 | ContractType | tinyint | YES | Computed affiliate payment model: 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Derived from ContractName via CASE expression. (Tier 2 — SP_Dim_Affiliate) |
| 7 | AffiliatesGroupsName | nvarchar(50) | YES | Marketing group the affiliate belongs to. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 8 | AccountActivated | bit | YES | Whether the affiliate account is active. 1=Active, 0/NULL=Inactive. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 9 | LoginName | nvarchar(1000) | YES | Affiliate's login name in the AffWizz system. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 10 | TradingAccount_RealCID | bigint | YES | Affiliate's own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. (Tier 2 — SP_Dim_Affiliate) |
| 11 | TradingAccount_UserName | varchar(50) | YES | eToro username that matched for the affiliate's trading account. First non-NULL from 4 UserName variants. (Tier 2 — SP_Dim_Affiliate) |
| 12 | Email | nvarchar(255) | YES | Affiliate's email address. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 13 | CompanyAddress | nvarchar(255) | YES | Affiliate's company street address. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 14 | City | nvarchar(255) | YES | Affiliate's city. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 15 | CountryID | int | YES | Affiliate's country. JOINs to Dim_Country.CountryID. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 16 | WebSiteURL | nvarchar(255) | YES | Affiliate's website URL used for referral traffic. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 17 | RegistrationFirstDate | datetime | YES | Date of the affiliate's first referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 18 | RegistrationLastDate | datetime | YES | Date of the affiliate's most recent referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 19 | RegistrationLifeTime | int | YES | Total registrations referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 20 | RegistrationYesterday | int | YES | Registrations referred yesterday. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 21 | RegistrationLastMonth | int | YES | Registrations referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 22 | RegistrationLastQuarter | int | YES | Registrations referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 23 | RegistrationLastYear | int | YES | Registrations referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 24 | FTDFirstDate | datetime | YES | Date of the affiliate's first referred FTD (First Time Deposit). (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 25 | FTDLastDate | datetime | YES | Date of the most recent referred FTD. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 26 | FTDLifeTime | int | YES | Total FTDs referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 27 | FTDYesterday | int | YES | FTDs referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 28 | FTDLastMonth | int | YES | FTDs referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 29 | FTDLastQuarter | int | YES | FTDs referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 30 | FTDLastYear | int | YES | FTDs referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 31 | FTDeFirstDate | datetime | YES | Date of the affiliate's first referred FTDe (FTD equivalent — includes qualifying non-deposit events). (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 32 | FTDeLastDate | datetime | YES | Date of the most recent referred FTDe. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 33 | FTDeLifeTime | int | YES | Total FTDe events referred all time. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 34 | FTDeYesterday | int | YES | FTDe events referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 35 | FTDeLastMonth | int | YES | FTDe events referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 36 | FTDeLastQuarter | int | YES | FTDe events referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 37 | FTDeLastYear | int | YES | FTDe events referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 38 | MasterAffiliateID | int | YES | Parent/master affiliate in the hierarchy. NULL if this is a standalone or top-level affiliate. JOINs to Dim_Affiliate.AffiliateID (self-reference). (Tier 2 — Ext_Dim_Affiliate_MasterAffiliate) |
| 39 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() during SP_Dim_Affiliate execution. (Tier 2 — SP_Dim_Affiliate) |
| 40 | RegistrationThisMonth | int | YES | Registrations referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 41 | RegistrationThisQuarter | int | YES | Registrations referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 42 | RegistrationThisYear | int | YES | Registrations referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 43 | FTDeThisMonth | int | YES | FTDe events referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 44 | FTDeThisQuarter | int | YES | FTDe events referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 45 | FTDeThisYear | int | YES | FTDe events referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 46 | FTDThisMonth | int | YES | FTDs referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 47 | FTDThisQuarter | int | YES | FTDs referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 48 | FTDThisYear | int | YES | FTDs referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 49 | LanguageName | nvarchar(255) | YES | Affiliate's preferred language. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 50 | WebSiteTitle | nvarchar(256) | YES | Title/name of the affiliate's website. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 51 | GCID | int | YES | Global Customer ID linking the affiliate to the eToro customer graph. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 52 | EntityName | nvarchar(510) | YES | Legal entity name for the affiliate company. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 53 | ContactPersonFullName | nvarchar(510) | YES | Full name of the affiliate's primary contact person. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 54 | Telephone | nvarchar(50) | YES | Affiliate contact phone number. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 55 | SubChannel | nvarchar(50) | NO | Marketing sub-channel name (e.g., "Affiliate Partners", "SEM Brand"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 56 | Channel | nvarchar(50) | NO | Top-level marketing channel (e.g., "Paid", "Organic", "Affiliate"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |

---

## 5. Lineage

### 5.1 Source Architecture

```
fiktivo_dbo (AffWizz staging tables)
    │
    ├─ SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse
    │   → Ext_Dim_Channel_Affiliate_UnifyCode (base affiliate profile)
    │   → Ext_Dim_SubChannel_UnifyCode (channel classification)
    │
    ├─ Ext_Dim_Affiliate_Customer (trading account lookups)
    ├─ Ext_Dim_Affiliate_Registrations (registration metrics)
    ├─ Ext_Dim_Affiliate_FTD (FTD metrics)
    ├─ Ext_Dim_Affiliate_FTDe (FTDe metrics)
    └─ Ext_Dim_Affiliate_MasterAffiliate (hierarchy)
         │
         └─ SP_Dim_Affiliate → Dim_Affiliate
```

### 5.2 Staging Table Sources

| Staging Table | Role | Join Key |
|--------------|------|----------|
| Ext_Dim_Channel_Affiliate_UnifyCode | Base profile, contact, company data | AffiliateID (base) |
| Ext_Dim_SubChannel_UnifyCode | SubChannelID, SubChannel, Channel, DateCreated | AffiliateID |
| Ext_Dim_Affiliate_Customer (×4) | TradingAccount_RealCID, TradingAccount_UserName | UserName1..4 (COLLATE Latin1_General_BIN) |
| Ext_Dim_Affiliate_Registrations | Registration metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTD | FTD metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTDe | FTDe metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_MasterAffiliate | MasterAffiliateID | AffiliateID |

---

## 6. Relationships

### 6.1 References To (this table points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| SubChannelID | DWH_dbo.Dim_Channel | Channel dimension (implicit FK) |
| CountryID | DWH_dbo.Dim_Country | Affiliate's country |
| MasterAffiliateID | DWH_dbo.Dim_Affiliate | Self-reference: parent affiliate |
| GCID | DWH_dbo.Dim_Customer | Affiliate as customer (implicit FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Key | Description |
|--------------|----------|-------------|
| DWH_dbo.Dim_Customer | AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Fact_AffiliateCommission | AffiliateID | Commission payments |
| DWH_dbo.Dim_Channel | SubChannelID (shared) | Same channel classification |

---

## 7. Sample Queries

### 7.1 Top affiliates by lifetime FTDs

```sql
SELECT TOP 20
    a.AffiliateID,
    a.EntityName,
    a.ContractName,
    a.Channel,
    a.SubChannel,
    a.FTDLifeTime,
    a.RegistrationLifeTime,
    CASE WHEN a.RegistrationLifeTime > 0
         THEN CAST(a.FTDLifeTime AS FLOAT) / a.RegistrationLifeTime
         ELSE 0 END AS ConversionRate
FROM DWH_dbo.Dim_Affiliate a
WHERE a.AccountActivated = 1
ORDER BY a.FTDLifeTime DESC;
```

### 7.2 Affiliate hierarchy

```sql
SELECT
    child.AffiliateID,
    child.EntityName AS ChildEntity,
    master.AffiliateID AS MasterID,
    master.EntityName AS MasterEntity
FROM DWH_dbo.Dim_Affiliate child
JOIN DWH_dbo.Dim_Affiliate master ON child.MasterAffiliateID = master.AffiliateID
ORDER BY master.AffiliateID, child.AffiliateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key knowledge extracted |
|--------|------|-------------------------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | AffWizz / affiliate platform overview: registration links with affiliate id + campaign query strings; sub-affiliate hierarchy (up to 5 levels); Fiktivo as hosting context — aligns with `AffiliateID`, campaign-style identifiers, and `MasterAffiliateID`. |
| [Affiliate - Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541/Affiliate+-Data+migration) | Confluence | Documents migration of affiliate commission data from legacy fiktivo tables — confirms `fiktivo` DB as the system of record for affiliate entities that feed DWH staging. |
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Lists `fiktivo.dbo.tblaff_*` (e.g. `tblaff_Affiliates`, `tblaff_MarketingExpense`, `tblaff_AffiliatesGroups`, `tblaff_AffiliateTypes`) as DWH pipeline sources — matches `Dim_Affiliate` lineage. |
| [PI As Affiliate](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13178109958/PI+As+Affiliate) | Confluence | Partners Portal proxies Affiliate API; notes use of existing SPs against Fiktivo DB — supports interpretation of affiliate profile and trading-account linkage fields as AffWizz/Fiktivo-sourced. |
| [Affiliates Compliance Review and Monitoring Procedure 2026](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/1593278467/Affiliates+Compliance+Review+and+Monitoring+Procedure+2026) | Confluence | Operational context: AffWizz login, search by Affiliate ID — mirrors `AffiliateID` as the operational key. |

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable; P10 Atlassian refresh)*
*Tiers: 0 T1, 56 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Affiliate | Type: Table | Production Source: fiktivo_dbo.tblaff_Affiliates (AffWizz)*
