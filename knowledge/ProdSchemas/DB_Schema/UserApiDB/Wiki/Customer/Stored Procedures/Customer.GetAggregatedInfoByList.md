# Customer.GetAggregatedInfoByList

> Retrieves aggregated user profile data for multiple users by CID, GCID, or username, joining the four core Customer tables plus UserSettings, UserAttribution, and Publications.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ids / @usernames (multi-mode batch lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAggregatedInfoByList is a batch-oriented user profile retrieval procedure that returns aggregated data for multiple users. Like GetAggregatedInfo, it supports three lookup modes (by CID, GCID, or username), but unlike the legacy GetAggregatedInfo, it uses the newer Customer schema tables directly rather than dbo legacy views.

This procedure serves features needing multi-user profile data: leaderboards, copy-trading lists, admin batch lookups, and social feed user cards. It returns a focused but comprehensive subset including name, email, country, brand label, guru status, player status, player level, account type, regulation, verification level, KYC state, privacy settings, and user attribution data.

Data flows in via TVP parameters. The procedure resolves user IDs in phase 1 (using CustomerIdentification for GCID or CID, or BasicUserInfo for username), then JOINs across BasicUserInfo, AccountUserInfo, ContactUserInfo, RiskUserInfo, UserSettings, UserAttribution.UserAttributes, and Publications in phase 2.

---

## 2. Business Logic

### 2.1 Multi-Mode Lookup Strategy

**What**: Three mutually exclusive lookup modes determined by bit flags.

**Columns/Parameters Involved**: `@ids`, `@usernames`, `@isGcid`, `@isUsernames`

**Rules**:
- @isUsernames = 1: lookup by username via BasicUserInfo (LOWER + Latin1_General_BIN collation), then resolve CID/DemoCID from CustomerIdentification
- @isGcid = 0: lookup by legacy CID via CustomerIdentification.CID
- @isGcid = 1: lookup by GCID via CustomerIdentification.GCID

### 2.2 User Attribution Integration

**What**: Includes marketing attribution data not present in the other GetAggregated* procedures.

**Columns/Parameters Involved**: `AttributeID`

**Rules**:
- LEFT JOIN to UserAttribution.UserAttributes for AttributeID
- This field tracks marketing/campaign attribution for the user
- Optional (LEFT JOIN) - NULL when no attribution data exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | IdList (TVP) | NO | - | CODE-BACKED | READONLY list of CIDs or GCIDs (used when @isUsernames = 0). |
| 2 | @usernames | UsernameList (TVP) | NO | - | CODE-BACKED | READONLY list of usernames (used when @isUsernames = 1). |
| 3 | @isGcid | bit | NO | - | CODE-BACKED | When 1, @ids contains GCIDs; when 0, @ids contains legacy CIDs. |
| 4 | @isUsernames | bit | NO | - | CODE-BACKED | When 1, lookup uses @usernames; when 0, uses @ids. |

**Return Columns:**

| # | Element | Source Table | Confidence | Description |
|---|---------|-------------|------------|-------------|
| 1 | GCID | resolved | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy Customer ID. |
| 3 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 4 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 5 | FirstName | BasicUserInfo | CODE-BACKED | First name. |
| 6 | LastName | BasicUserInfo | CODE-BACKED | Last name. |
| 7 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | CountryID | ContactUserInfo | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 9 | AboutMe | Publications | CODE-BACKED | User bio text. |
| 10 | AboutMeShort | Publications | CODE-BACKED | Shortened bio. |
| 11 | BioLanguage | Publications.LanguageCode | CODE-BACKED | Bio language code. |
| 12 | StrategyID | Publications | CODE-BACKED | Trading strategy ID. |
| 13 | WhiteLabelID | AccountUserInfo.LabelID | CODE-BACKED | Brand label. FK to Dictionary.Label. |
| 14 | GuruStatusID | AccountUserInfo | CODE-BACKED | Popular Investor tier. FK to Dictionary.GuruStatus. |
| 15 | PlayerStatusID | RiskUserInfo | CODE-BACKED | Account status. FK to Dictionary.PlayerStatus. |
| 16 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 17 | AccountTypeID | AccountUserInfo | CODE-BACKED | Account type (real/demo/sub). |
| 18 | MasterAccountCID | AccountUserInfo | CODE-BACKED | Parent account for sub-accounts. |
| 19 | KycState | AccountUserInfo | CODE-BACKED | KYC workflow state. |
| 20 | VerificationLevelID | RiskUserInfo | CODE-BACKED | Verification tier. FK to Dictionary.VerificationLevel. |
| 21 | RegulationID | RiskUserInfo | CODE-BACKED | Regulating entity. FK to Dictionary.Regulation. |
| 22 | DesignatedRegulationID | RiskUserInfo | CODE-BACKED | Designated regulation. |
| 23 | Email | ContactUserInfo | CODE-BACKED | Email address. |
| 24 | PendingClosureStatusID | AccountUserInfo | CODE-BACKED | Pending closure status. |
| 25 | Registered | BasicUserInfo | CODE-BACKED | Registration date. |
| 26 | IsEmailVerified | ContactUserInfo | CODE-BACKED | Email verification status. |
| 27 | AttributeID | UserAttribution.UserAttributes | CODE-BACKED | Marketing attribution ID. |
| 28 | AccountStatusID | AccountUserInfo | CODE-BACKED | Account operational status. |
| 29 | MifidCategorizationID | RiskUserInfo | CODE-BACKED | MiFID categorization. FK to Dictionary.MifidCategorization. |
| 30 | AsicClassificationID | RiskUserInfo | CODE-BACKED | ASIC classification. FK to Dictionary.AsicClassification. |
| 31 | SeychellesCategorizationID | RiskUserInfo | CODE-BACKED | Seychelles categorization. FK to Dictionary.SeychellesCategorization. |
| 32 | PrivacyPolicyID | UserSettings | CODE-BACKED | Privacy policy version. |
| 33 | AllowDisplayFullName | UserSettings | CODE-BACKED | Public name display preference. |
| 34 | HomepageId | UserSettings | CODE-BACKED | Homepage preference. |
| 35 | TradingRiskStatusID | RiskUserInfo | CODE-BACKED | Trading risk status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.CustomerIdentification | JOIN (READER) | ID resolution for all lookup modes |
| (body) | Customer.BasicUserInfo | JOIN (READER) | Identity, username, language, player level |
| (body) | Customer.AccountUserInfo | JOIN (READER) | Label, guru status, account type, KYC |
| (body) | Customer.ContactUserInfo | JOIN (READER) | Country, email, verification status |
| (body) | Customer.RiskUserInfo | JOIN (READER) | Regulation, player status, verification |
| (body) | Customer.UserSettings | LEFT JOIN (READER) | Privacy and display preferences |
| (body) | UserAttribution.UserAttributes | LEFT JOIN (READER) | Marketing attribution |
| (body) | dbo.Publications | OUTER APPLY (READER) | Bio and strategy data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by batch user lookup services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAggregatedInfoByList (procedure)
+-- Customer.CustomerIdentification (table)
+-- Customer.BasicUserInfo (table)
+-- Customer.AccountUserInfo (table)
+-- Customer.ContactUserInfo (table)
+-- Customer.RiskUserInfo (table)
+-- Customer.UserSettings (table)
+-- UserAttribution.UserAttributes (table)
+-- dbo.Publications (table/synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN - ID resolution |
| Customer.BasicUserInfo | Table | JOIN - identity data |
| Customer.AccountUserInfo | Table | JOIN - account config |
| Customer.ContactUserInfo | Table | JOIN - contact data |
| Customer.RiskUserInfo | Table | JOIN - risk/compliance |
| Customer.UserSettings | Table | LEFT JOIN - preferences |
| UserAttribution.UserAttributes | Table | LEFT JOIN - marketing attribution |
| dbo.Publications | Table/Synonym | OUTER APPLY - bio/strategy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get aggregated info by GCIDs
```sql
DECLARE @ids IdList
INSERT INTO @ids (Id) VALUES (12345), (67890)
DECLARE @usernames UsernameList
EXEC Customer.GetAggregatedInfoByList @ids, @usernames, @isGcid = 1, @isUsernames = 0
```

### 8.2 Get aggregated info by usernames
```sql
DECLARE @ids IdList
DECLARE @usernames UsernameList
INSERT INTO @usernames (Username) VALUES ('traderx'), ('investory')
EXEC Customer.GetAggregatedInfoByList @ids, @usernames, @isGcid = 0, @isUsernames = 1
```

### 8.3 Get aggregated info by legacy CIDs
```sql
DECLARE @ids IdList
INSERT INTO @ids (Id) VALUES (54321), (98765)
DECLARE @usernames UsernameList
EXEC Customer.GetAggregatedInfoByList @ids, @usernames, @isGcid = 0, @isUsernames = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 39 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAggregatedInfoByList | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAggregatedInfoByList.sql*
