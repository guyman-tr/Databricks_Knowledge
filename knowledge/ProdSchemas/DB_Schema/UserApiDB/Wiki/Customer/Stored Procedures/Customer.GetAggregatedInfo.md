# Customer.GetAggregatedInfo

> Retrieves aggregated public-facing user profile data (name, language, country, label, guru status, player status, bio) for one or more users, supporting lookup by CID, GCID, or username via legacy dbo tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ids / @usernames (multi-mode lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAggregatedInfo is a multi-mode user profile lookup procedure that returns aggregated public-facing data for one or more users. It supports three lookup modes: by legacy CID, by GCID, or by username - controlled by the @isGcid and @isUsernames bit flags.

This procedure serves social and community features that need to display user profiles, Popular Investor cards, and copy-trading leader information. It returns a focused subset of user data: name, language, country, brand label, Popular Investor status, player status, account type, region, verification level, citizenship, and user bio/strategy info from Publications.

The procedure follows a two-phase pattern: (1) resolve user identifiers and DemoCID via Real_Customer + CustomerIdentification, (2) return profile data by joining Real_Customer, Real_BackOfficeCustomer, General_Settings, and Publications. This procedure uses legacy dbo tables (Real_Customer, Real_BackOfficeCustomer) rather than the newer Customer schema tables, indicating it predates the Customer schema refactoring. Username matching is case-insensitive using LOWER() with Latin1_General_BIN collation.

---

## 2. Business Logic

### 2.1 Multi-Mode Lookup Strategy

**What**: Three mutually exclusive lookup modes determined by bit flags.

**Columns/Parameters Involved**: `@ids`, `@usernames`, `@isGcid`, `@isUsernames`

**Rules**:
- @isUsernames = 1: lookup by username (case-insensitive via LOWER + Latin1_General_BIN collation)
- @isUsernames = 0 AND @isGcid = 0: lookup by legacy CID (JOIN @ids ON ids.Id = rc.CID)
- @isUsernames = 0 AND @isGcid = 1: lookup by GCID (JOIN @ids ON ids.Id = rc.GCID)
- The @usernames list is only used when @isUsernames = 1; @ids is used otherwise

**Diagram**:
```
@isUsernames=1 --> JOIN @usernames ON LOWER(Username) = UserName_LOWER
@isGcid=0      --> JOIN @ids ON Id = CID  (legacy customer ID)
@isGcid=1      --> JOIN @ids ON Id = GCID (global customer ID)
```

### 2.2 DemoCID Resolution

**What**: Resolves each user's demo account CID for cross-referencing.

**Columns/Parameters Involved**: `GCID`, `DemoCID`

**Rules**:
- OUTER APPLY to Customer.CustomerIdentification to get DemoCID
- DemoCID may be NULL if the user has no demo account
- DemoCID is returned in the result set for caller reference

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | IdList (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing CIDs or GCIDs to look up (used when @isUsernames = 0). |
| 2 | @usernames | UsernameList (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing usernames to look up (used when @isUsernames = 1). |
| 3 | @isGcid | bit | NO | - | CODE-BACKED | When 1, @ids contains GCIDs; when 0, @ids contains legacy CIDs. Ignored if @isUsernames = 1. |
| 4 | @isUsernames | bit | NO | - | CODE-BACKED | When 1, lookup uses @usernames (case-insensitive); when 0, lookup uses @ids with @isGcid determining ID type. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | int | NO | - | CODE-BACKED | Legacy Customer ID (from Real_Customer.CID). |
| 3 | DemoCID | int | YES | - | CODE-BACKED | Demo account CID, NULL if no demo account. |
| 4 | UserName | varchar | NO | - | CODE-BACKED | Platform username (public-facing handle). |
| 5 | FirstName | varchar | YES | - | CODE-BACKED | User's first name. |
| 6 | LastName | varchar | YES | - | CODE-BACKED | User's last name. |
| 7 | LanguageID | int | NO | - | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | CountryID | int | NO | - | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 9 | AllowDisplayFullName | bit | YES | - | CODE-BACKED | Whether the user allows their full name to be displayed publicly. From General_Settings. |
| 10 | AboutMe | nvarchar | YES | - | CODE-BACKED | User's bio/about-me text from Publications. |
| 11 | AboutMeShort | nvarchar | YES | - | CODE-BACKED | Shortened bio text. Added LOY-1290 (Dec 2022). |
| 12 | BioLanguage | varchar | YES | - | CODE-BACKED | Language code of the user's bio. From Publications.LanguageCode. |
| 13 | StrategyID | int | YES | - | CODE-BACKED | Trading strategy identifier from Publications. Added LOY-1023 (Apr 2022). |
| 14 | WhiteLabelID | int | NO | - | CODE-BACKED | Brand label. FK to Dictionary.Label (aliased from LabelID). |
| 15 | PrivacyPolicyID | int | YES | - | CODE-BACKED | Privacy policy version accepted by the user. |
| 16 | HomepageId | int | YES | - | CODE-BACKED | User's homepage preference. From General_Settings. |
| 17 | GuruStatusID | int | YES | - | CODE-BACKED | Popular Investor tier. FK to Dictionary.GuruStatus. From Real_BackOfficeCustomer. |
| 18 | PlayerStatusID | int | NO | - | CODE-BACKED | Account status controlling permissions. FK to Dictionary.PlayerStatus. |
| 19 | AccountTypeID | tinyint | NO | - | CODE-BACKED | Account type (real, demo, sub-account). From Real_BackOfficeCustomer. |
| 20 | MasterAccountCID | int | YES | - | CODE-BACKED | Parent master account CID for sub-accounts. From Real_BackOfficeCustomer. |
| 21 | RegionID | int | YES | - | CODE-BACKED | Geographic region. |
| 22 | CountryIDByIP | int | YES | - | CODE-BACKED | Country detected by IP geolocation. |
| 23 | RegionByIP_ID | int | YES | - | CODE-BACKED | Region detected by IP geolocation. |
| 24 | VerificationLevelID | int | YES | - | CODE-BACKED | Identity verification tier. FK to Dictionary.VerificationLevel. From Real_BackOfficeCustomer. |
| 25 | CitizenshipCountryID | int | YES | - | CODE-BACKED | Citizenship country. FK to Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | SELECT (READER) | Primary data source for user identity and contact fields |
| (body) | dbo.Real_BackOfficeCustomer | JOIN (READER) | Guru status, account type, verification level, master CID |
| (body) | Customer.CustomerIdentification | OUTER APPLY | Resolves DemoCID from GCID |
| (body) | dbo.General_Settings | LEFT JOIN | AllowDisplayFullName, HomepageId |
| (body) | dbo.Publications | OUTER APPLY | AboutMe, AboutMeShort, BioLanguage, StrategyID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by social/community features for user profile display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAggregatedInfo (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- dbo.Real_BackOfficeCustomer (table/synonym)
+-- Customer.CustomerIdentification (table)
+-- dbo.General_Settings (table/synonym)
+-- dbo.Publications (table/synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOINed for user identity, name, language, country |
| dbo.Real_BackOfficeCustomer | Table/Synonym | JOINed for guru status, account type, verification level |
| Customer.CustomerIdentification | Table | OUTER APPLY for DemoCID resolution |
| dbo.General_Settings | Table/Synonym | LEFT JOINed for display preferences |
| dbo.Publications | Table/Synonym | OUTER APPLY for bio/strategy data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Logs error details (server, DB, proc, line, message, severity) and re-throws |

---

## 8. Sample Queries

### 8.1 Get aggregated info by GCIDs
```sql
DECLARE @ids IdList
INSERT INTO @ids (Id) VALUES (12345), (67890)
DECLARE @usernames UsernameList
EXEC Customer.GetAggregatedInfo @ids = @ids, @usernames = @usernames, @isGcid = 1, @isUsernames = 0
```

### 8.2 Get aggregated info by usernames
```sql
DECLARE @ids IdList
DECLARE @usernames UsernameList
INSERT INTO @usernames (Username) VALUES ('traderx'), ('investory')
EXEC Customer.GetAggregatedInfo @ids = @ids, @usernames = @usernames, @isGcid = 0, @isUsernames = 1
```

### 8.3 Get aggregated info by legacy CIDs
```sql
DECLARE @ids IdList
INSERT INTO @ids (Id) VALUES (54321)
DECLARE @usernames UsernameList
EXEC Customer.GetAggregatedInfo @ids = @ids, @usernames = @usernames, @isGcid = 0, @isUsernames = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAggregatedInfo.sql*
