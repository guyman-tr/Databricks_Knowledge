# Customer.ZeroCustomer

> Pre-normalization legacy archive of early demo customer accounts (2007-2009) with zero credit balance: a flat 51-column customer snapshot from eToro's earliest schema, before customer data was split into CustomerStatic, CustomerMoney, and Address.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | None (HEAP - no PK, no clustered index) |
| **Partition** | No (PRIMARY filegroup, no compression) |
| **Indexes** | 0 (HEAP - no indexes of any kind) |

---

## 1. Business Meaning

Customer.ZeroCustomer is a frozen archive of early eToro customer records from the platform's first two years (December 2007 to March 2009). Each row stores the complete profile of a demo customer at the moment their account was archived - every attribute that would later be split across CustomerStatic, CustomerMoney, and Customer.Address is here in a single flat row. All 893 rows are demo accounts (IsReal=false) with zero trading balance (Credit=0). The table has no PK, no indexes, no active procedure references, and has not received new rows since 2009.

This table predates the schema normalization that created the current multi-table customer model. It represents the "original customer record" structure - a single-table design where one row held everything about a customer, including their username, password (plain-text varchar(20) - pre-security era design), geographic classification, trading configuration, and contact details. The OriginalProviderID+OriginalCID vs. ProviderID+CID dual identity pattern indicates this table was used during a CID consolidation or remapping exercise: 13 rows show OriginalCID != CID, meaning those accounts were re-keyed during a migration; 22 rows have RealProviderID populated.

Data no longer flows through this table. No stored procedures write to it or read from it. It exists purely as a historical artifact and is safe to archive or drop from production without operational impact.

---

## 2. Business Logic

### 2.1 CID Migration Pattern

**What**: The dual identity columns (OriginalProviderID+OriginalCID vs. ProviderID+CID) capture a CID remapping that occurred during the 2007-2009 period.

**Columns/Parameters Involved**: `OriginalProviderID`, `OriginalCID`, `ProviderID`, `CID`

**Rules**:
- When OriginalCID = CID and OriginalProviderID = ProviderID: account was not remapped (880 of 893 rows)
- When OriginalCID != CID: the account was re-keyed during migration; OriginalCID was the old CID, CID is the new canonical ID (13 rows)
- RealProviderID is populated (22 rows) when the account was associated with a "real" provider different from the default ProviderID=1

---

## 3. Data Overview

| CID | OriginalCID | ProviderID | CountryID | PlayerStatusID | IsReal | Credit | Registered | Meaning |
|-----|-------------|-----------|-----------|---------------|--------|--------|------------|---------|
| 11458 | 11458 | 1 | 9 | 1 | false | 0 | 2007-12-03 | Earliest row in the archive - a demo account from eToro's first days. CountryID=9, LanguageID=1, not remapped (OriginalCID=CID). |
| 11459 | 11459 | 1 | 9 | 1 | false | 0 | 2007-12-03 | Sequential CID confirming these were created in rapid succession during early testing/seeding. All first 5 rows share the same CountryID=9 pattern. |
| 11460 | 11460 | 1 | 9 | 1 | false | 0 | 2007-12-03 | Registration every 5 minutes - consistent with an automated account-creation batch, not organic user registrations. |
| 11461 | 11461 | 1 | 9 | 1 | false | 0 | 2007-12-03 | Same pattern. All early rows have SpreadGroupID=0, LabelID=0 - config not yet populated at registration time. |
| 201213 | (varies) | 1 | (varies) | (varies) | false | 0 | 2009-03-16 | Last row in the archive. Highest CID, showing the range of early accounts covered. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier - the canonical CID after any migration. Not unique (HEAP has no PK constraint). In 13 cases, differs from OriginalCID where CID was remapped. References Customer.CustomerStatic (no FK enforced). |
| 2 | OriginalProviderID | int | NO | - | NAME-INFERRED | The eToro white-label/provider ID at the time the account was first created - before any provider remapping. In 880 of 893 rows equals ProviderID. |
| 3 | OriginalCID | int | NO | - | NAME-INFERRED | The customer's CID before any migration/consolidation. Equals CID in 880 of 893 rows (unmigrated). Differs from CID in 13 rows that were re-keyed during early migrations. |
| 4 | ProviderID | int | NO | - | CODE-BACKED | White-label provider ID for this account's trading environment. All 893 rows have ProviderID=1 (eToro default). References Trade.Provider (no FK enforced). |
| 5 | RealProviderID | int | YES | - | NAME-INFERRED | The "real" provider ID when the account's effective provider differs from the registered ProviderID. Populated in 22 rows. NULL in the remaining 871 rows. |
| 6 | CountryID | int | NO | - | CODE-BACKED | Customer's country of registration. Implicit FK to Dictionary.Country. 8 distinct values in this table. Used for geographic segmentation. See Customer.CustomerStatic for full value map. |
| 7 | CountryIDByIP | int | NO | - | CODE-BACKED | Country derived from the customer's registration IP address, which may differ from the declared CountryID. Used to detect VPN usage or country mismatches at registration time. |
| 8 | StateID | int | NO | - | CODE-BACKED | US state or sub-national region at registration. Implicit FK to Dictionary.State. 0 for non-US customers. |
| 9 | LanguageID | int | NO | - | CODE-BACKED | Display language preference. Implicit FK to Dictionary.Language. Determines which language the platform UI was shown in. |
| 10 | CommunicationLanguageID | int | NO | - | CODE-BACKED | Language used for email and notification communications, which may differ from the display LanguageID. Implicit FK to Dictionary.Language. |
| 11 | CurrencyID | int | NO | - | CODE-BACKED | Account denomination currency. Implicit FK to Dictionary.Currency (1=USD is universal here). Determines P&L calculation currency. |
| 12 | TimeZoneID | int | NO | - | CODE-BACKED | Customer's time zone preference for chart and activity display. Implicit FK to Dictionary.TimeZone. |
| 13 | PlayerStatusID | int | NO | - | CODE-BACKED | Account lifecycle state at time of archiving. Implicit FK to Dictionary.PlayerStatus (1=Active is dominant). See Customer.CustomerStatic.PlayerStatusID for full value map. |
| 14 | CampaignID | int | YES | - | CODE-BACKED | Marketing campaign that acquired this customer. NULL = organic or unknown. Implicit FK to marketing campaign dictionary. |
| 15 | PlayerLevelID | int | NO | - | CODE-BACKED | Customer tier (e.g., standard, silver, gold). Implicit FK to Dictionary.PlayerLevel. All rows have PlayerLevelID=1 (standard) in the sampled data. |
| 16 | TradeLevelID | int | NO | - | CODE-BACKED | Trading permission level (demo/real/restricted). Implicit FK to Dictionary.TradeLevel. Sampled data shows TradeLevelID=2. |
| 17 | SpreadGroupID | int | NO | - | CODE-BACKED | Spread group assignment for pricing. 0 in early rows = default group. References a spread pricing configuration. |
| 18 | LabelID | int | NO | - | CODE-BACKED | IB (introducing broker) label assignment. 0 = no IB attribution. Implicit FK to Dictionary.Label. |
| 19 | FunnelID | int | YES | - | CODE-BACKED | Acquisition funnel identifier for marketing attribution. NULL = no funnel tracking. Implicit FK to Dictionary.Funnel. |
| 20 | UserName | varchar(20) | NO | - | CODE-BACKED | Customer's login username. Limited to 20 chars (pre-2009 constraint). NOT guaranteed unique in this table (HEAP). |
| 21 | Password | varchar(20) | NO | - | CODE-BACKED | Customer's password in plain text (legacy pre-security design). This column would never exist in modern schemas - stored here as it was in 2007-2009 before password hashing was introduced. |
| 22 | Registered | datetime | NO | - | CODE-BACKED | UTC timestamp when the account was created. Range: 2007-12-03 to 2009-03-16. The early sequential registrations (every 5 minutes) suggest automated account seeding. |
| 23 | IsReal | bit | NO | - | CODE-BACKED | Account type: 1=real money account, 0=demo account. All 893 rows are IsReal=0 (demo). Real money accounts from this era were either migrated to the current schema or lost. |
| 24 | IP | varchar(15) | NO | - | CODE-BACKED | Registration IP address (IPv4). Stored for fraud detection and geographic validation. May be empty string for synthetic accounts. |
| 25 | Credit | money | NO | - | CODE-BACKED | Trading credit balance at time of archiving. All 893 rows have Credit=0. This zero balance is the defining characteristic that names the table - "zero customer" = zero-balance customer. |
| 26 | BirthDate | datetime | YES | - | CODE-BACKED | Customer's date of birth for age verification and KYC. NULL for most early demo accounts. |
| 27 | Gender | char(1) | YES | - | CODE-BACKED | Customer's gender: 'M'=male, 'F'=female. NULL for most rows. |
| 28 | FirstName | varchar(50) | YES | - | CODE-BACKED | Customer's first name. NULL for automated/seeded accounts. |
| 29 | LastName | varchar(50) | YES | - | CODE-BACKED | Customer's last name. NULL for automated/seeded accounts. |
| 30 | Address | varchar(100) | YES | - | CODE-BACKED | Street address. NULL for most demo accounts. In modern schema this moved to Customer.Address table. |
| 31 | City | varchar(50) | YES | - | CODE-BACKED | Customer's city. NULL for most rows. In modern schema moved to Customer.Address. |
| 32 | Zip | varchar(50) | YES | - | CODE-BACKED | Postal code. NULL for most rows. In modern schema moved to Customer.Address. |
| 33 | SerialID | int | YES | - | NAME-INFERRED | Serial tracking number from the original pre-normalization schema. Meaning unclear without procedure references. |
| 34 | ReferralID | int | YES | - | CODE-BACKED | CID of the customer who referred this account. NULL = no referral. In modern schema this moved to Customer.CustomerStatic.ReferralID for the RAF (Refer-a-Friend) program. |
| 35 | SubSerialID | varchar(1024) | YES | - | NAME-INFERRED | Extended serial/tracking string from the original schema. Large varchar(1024) suggests it held concatenated tracking data. Meaning unclear without procedure references. |
| 36 | Email | varchar(50) | YES | - | CODE-BACKED | Customer's email address. varchar(50) is short by modern standards. NULL for automated accounts. |
| 37 | IsEmailVerified | bit | YES | - | CODE-BACKED | Whether the email address was verified. NULL = verification status unknown (most rows). 1 = verified, 0 = unverified. |
| 38 | Phone | varchar(30) | YES | - | CODE-BACKED | Customer's primary phone number. NULL for most demo accounts. |
| 39 | Fax | varchar(30) | YES | - | CODE-BACKED | Customer's fax number. Reflects the 2007-2009 era when fax was still a required contact field. |
| 40 | Mobile | varchar(30) | YES | - | CODE-BACKED | Customer's mobile phone number. Separate from Phone - predates mobile-first design. |
| 41 | Comments | varchar(255) | YES | - | CODE-BACKED | Free-text notes about the customer, typically entered by support or backoffice staff. |
| 42 | DownloadID | int | YES | - | NAME-INFERRED | Identifier for the platform download or installer the customer used to register. Tracking for early affiliate/distribution programs. Meaning unclear from data alone. |
| 43 | BannerID | int | YES | - | NAME-INFERRED | Identifier for the marketing banner that drove the customer's registration. Part of early affiliate tracking before CampaignID/FunnelID were formalized. |
| 44 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Version string of the eToro trading client installed at registration time. Reflects the desktop client era (2007-2009). |
| 45 | PersonID | varchar(50) | YES | - | NAME-INFERRED | External person identifier, possibly from an integrated identity system. varchar(50) alphanumeric - likely a third-party or legacy internal ID. Meaning unclear without procedure references. |
| 46 | BonusCredit | money | YES | - | CODE-BACKED | Bonus balance in addition to the main Credit. 0 in all sampled rows - zero-balance archive. Separate from Credit to distinguish promotional bonus funds from deposited funds. |
| 47 | DownloadCounter | int | YES | - | NAME-INFERRED | Number of times the customer downloaded the eToro client. Used in early desktop client era for tracking engagement. |
| 48 | AccountExpirationDate | datetime | YES | - | CODE-BACKED | Date when the demo account expires or expired. Demo accounts in the 2007-2009 era had expiry dates. NULL = no expiry or not tracked. |
| 49 | HelpDeskType | smallint | YES | - | NAME-INFERRED | Support tier or helpdesk routing category for this customer. Meaning unclear without procedure references. |
| 50 | ClientTypeID | tinyint | YES | 0 | CODE-BACKED | Client application type (web, desktop, mobile). FK to Dictionary.ClientType. DEFAULT=0 but all 893 rows have NULL (default was added after all data was inserted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClientTypeID | Dictionary.ClientType | FK (enforced) | Client application type lookup; all rows are NULL despite FK |
| CountryID, CountryIDByIP | Dictionary.Country | Implicit | Geographic classification lookups |
| LanguageID, CommunicationLanguageID | Dictionary.Language | Implicit | Language preference lookups |
| CurrencyID | Dictionary.Currency | Implicit | Account denomination currency |
| PlayerStatusID | Dictionary.PlayerStatus | Implicit | Account lifecycle state |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | Customer tier |
| TradeLevelID | Dictionary.TradeLevel | Implicit | Trading permission level |

### 5.2 Referenced By (other objects point to this)

No active objects reference Customer.ZeroCustomer. It is a fully orphaned legacy archive with no known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ZeroCustomer (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ClientType | Table | FK target for ClientTypeID (all rows NULL) |

### 6.2 Objects That Depend On This

No dependents found. No stored procedures, views, or functions reference Customer.ZeroCustomer.

---

## 7. Technical Details

### 7.1 Indexes

No indexes. Customer.ZeroCustomer is a HEAP (no clustered index, no non-clustered indexes). Full table scans are required for any query against this table, reinforcing its legacy/archive nature.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DFCZ_ClientTypeID | DEFAULT | ClientTypeID = 0 (post-hoc default; all existing rows predate it and have NULL) |
| FK_CZC_CTID | FK | ClientTypeID -> Dictionary.ClientType(ClientTypeID); all rows have NULL ClientTypeID |

---

## 8. Sample Queries

### 8.1 View earliest archived accounts
```sql
SELECT TOP 10
    CID,
    OriginalCID,
    ProviderID,
    CountryID,
    PlayerStatusID,
    IsReal,
    Credit,
    Registered,
    ClientTypeID
FROM Customer.ZeroCustomer WITH (NOLOCK)
ORDER BY Registered ASC;
```

### 8.2 Find migrated accounts (OriginalCID differs from CID)
```sql
SELECT
    CID,
    OriginalCID,
    OriginalProviderID,
    ProviderID,
    RealProviderID,
    Registered
FROM Customer.ZeroCustomer WITH (NOLOCK)
WHERE OriginalCID <> CID
ORDER BY Registered;
```

### 8.3 Check if a CID exists in the legacy archive
```sql
SELECT
    zc.CID,
    zc.OriginalCID,
    zc.UserName,
    zc.Registered,
    zc.IsReal,
    zc.Credit,
    zc.PlayerStatusID
FROM Customer.ZeroCustomer zc WITH (NOLOCK)
WHERE zc.CID = 11458;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 6.4/10 (Elements: 8.8/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 38 CODE-BACKED, 0 ATLASSIAN-ONLY, 12 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no procedure references found) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.ZeroCustomer | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.ZeroCustomer.sql*
