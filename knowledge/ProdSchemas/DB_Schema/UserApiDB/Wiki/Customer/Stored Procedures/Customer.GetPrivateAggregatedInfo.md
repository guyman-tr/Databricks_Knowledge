# Customer.GetPrivateAggregatedInfo

> Retrieves private/internal aggregated customer profile data for login and admin operations - supports lookup by CID, GCID, or username with demo CID resolution, user attribution, Salesforce IDs, and weekend fee configuration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns private profile rows with multiple lookup modes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivateAggregatedInfo retrieves a comprehensive set of internal/private customer data used for login flows, admin dashboards, and internal API responses. Unlike the public GetAggregatedInfo procedures that return general profile data, this procedure includes sensitive/internal fields like ExternalID, SalesForce integration IDs, user attribution, weekend fee percentage, and email address.

This procedure supports three lookup modes: by CID list (@isGcid=0), by GCID list (@isGcid=1), or by username list (@isUsernames=1). It first resolves demo CIDs in a TRY/CATCH block (so demo lookup failures don't block the main query), then returns the full profile from Real_Customer, Real_BackOfficeCustomer, General_Settings, UserAttribution.UserAttributes, and Publications.

The procedure was updated over time to add TradingRiskStatusID (2018), UserAttribution/SalesForce IDs (2020), StrategyID (2022, LOY-1023), and AboutMeShort (2022, LOY-1290).

---

## 2. Business Logic

### 2.1 Triple Lookup Mode

**What**: Three code paths based on @isUsernames and @isGcid flags.

**Columns/Parameters Involved**: `@isUsernames`, `@isGcid`, `@ids`, `@usernames`

**Rules**:
- @isUsernames=1: Lookup by username using case-insensitive binary collation match on UserName_LOWER
- @isGcid=0: Lookup by CID (Real_Customer.CID = ids.Id)
- @isGcid=1: Lookup by GCID (Real_Customer.GCID = ids.Id)
- Demo CID resolution is wrapped in TRY/CATCH - failures produce NULL DemoCID, not errors

### 2.2 User Attribution (Single Per Customer)

**What**: Returns only one AttributeID per customer for performance (comment: "Using just one attribute id per customer").

**Columns/Parameters Involved**: `UserAttribution.UserAttributes.AttributeID`

**Rules**:
- LEFT JOIN (not INNER) so customers without attribution still appear
- Returns a single AttributeID per GCID - if multiple exist, the JOIN picks one arbitrarily

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of CIDs or GCIDs depending on @isGcid flag. Ignored when @isUsernames=1. |
| 2 | @usernames | dbo.UsernameList (TVP) | NO | - | CODE-BACKED | List of usernames for username-based lookup. Used only when @isUsernames=1. |
| 3 | @isGcid | bit | NO | - | CODE-BACKED | Lookup mode: 0=by CID, 1=by GCID. Ignored when @isUsernames=1. |
| 4 | @isUsernames | bit | NO | - | CODE-BACKED | When 1, lookup is by username (overrides @isGcid). |
| 5 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 6 | RealCID (output) | int | NO | - | CODE-BACKED | Real account CID. |
| 7 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID from CustomerIdentification. NULL if resolution fails. |
| 8 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 9 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name. |
| 10 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name. |
| 11 | LanguageID (output) | int | YES | - | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 12 | CountryID (output) | int | YES | - | CODE-BACKED | Registered country. FK to Dictionary.Country. |
| 13 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Privacy setting: allow public full name display. |
| 14 | AboutMe (output) | nvarchar | YES | - | CODE-BACKED | User bio from Publications. |
| 15 | AboutMeShort (output) | nvarchar | YES | - | CODE-BACKED | Short bio from Publications. Added LOY-1290 (Dec 2022). |
| 16 | BioLanguage (output) | varchar | YES | - | CODE-BACKED | Language code for bio content. |
| 17 | StrategyID (output) | int | YES | - | CODE-BACKED | Investment strategy. Added LOY-1023 (Apr 2022). |
| 18 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | Brand/white label. Aliased from LabelID. |
| 19 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version accepted. |
| 20 | HomepageId (output) | int | YES | - | CODE-BACKED | User homepage preference. |
| 21 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor status. FK to Dictionary.GuruStatus. |
| 22 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status. FK to Dictionary.PlayerStatus. |
| 23 | PlayerLevelID (output) | int | YES | - | CODE-BACKED | Player experience level. FK to Dictionary.PlayerLevel. |
| 24 | ExternalID (output) | varchar | YES | - | CODE-BACKED | External system identifier (private - not returned by public SPs). |
| 25 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type classification. |
| 26 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | Master account for sub-accounts. |
| 27 | KycState (output) | int | YES | - | CODE-BACKED | KYC verification state machine value. |
| 28 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. See [Verification Level](_glossary.md#verification-level). |
| 29 | RegulationID (output) | int | YES | - | CODE-BACKED | Primary regulation. FK to Dictionary.Regulation. |
| 30 | DesignatedRegulationID (output) | int | YES | - | CODE-BACKED | Designated regulation override. |
| 31 | TradingRiskStatusID (output) | int | YES | - | CODE-BACKED | Trading risk assessment status. Added 2018 (case 52150). |
| 32 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email address (private field). |
| 33 | PendingClosureStatusID (output) | int | YES | - | CODE-BACKED | Pending closure status. |
| 34 | Registered (output) | datetime | YES | - | CODE-BACKED | Registration timestamp. |
| 35 | IsEmailVerified (output) | bit | YES | - | CODE-BACKED | Whether email is verified. |
| 36 | AttributeID (output) | int | YES | - | CODE-BACKED | User interest attribute from UserAttribution.UserAttributes (Stocks, Crypto, CopyTrader, etc.). |
| 37 | SalesForceContactID (output) | varchar | YES | - | CODE-BACKED | Salesforce Contact ID for CRM integration. Private/internal field. |
| 38 | SalesForceAccountID (output) | varchar | YES | - | CODE-BACKED | Salesforce Account ID for CRM integration. Private/internal field. |
| 39 | AccountStatusID (output) | int | YES | - | CODE-BACKED | Current account status. |
| 40 | WeekendFeePercentage (output) | decimal | YES | - | CODE-BACKED | Customer-specific weekend fee percentage override. Aliased from WeekendFeePrecentage (note: column has a typo in DB). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids/@usernames | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Back-office/risk data |
| GCID | Customer.CustomerIdentification | OUTER APPLY | Demo CID resolution |
| CID | dbo.General_Settings | LEFT JOIN | Privacy/display settings |
| GCID | UserAttribution.UserAttributes | LEFT JOIN | User interest attribution |
| CID | dbo.Publications | OUTER APPLY | Bio/about me content |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called during login and admin profile retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivateAggregatedInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Customer.CustomerIdentification (table)
+-- dbo.General_Settings (table)
+-- UserAttribution.UserAttributes (table)
+-- dbo.Publications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - core customer data |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - back-office data |
| Customer.CustomerIdentification | Table | OUTER APPLY - demo CID |
| dbo.General_Settings | Table | LEFT JOIN - privacy settings |
| UserAttribution.UserAttributes | Table | LEFT JOIN - user interest |
| dbo.Publications | Table | OUTER APPLY - bio content |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH on demo CID | Error handling | Demo CID resolution failure returns NULL, does not block the SP |
| Collation on username | Business rule | Uses Latin1_General_BIN collation for case-insensitive username matching on UserName_LOWER |

---

## 8. Sample Queries

### 8.1 Get private info by GCID
```sql
DECLARE @ids dbo.IdList
DECLARE @usernames dbo.UsernameList
INSERT @ids VALUES (50001)
EXEC Customer.GetPrivateAggregatedInfo @ids=@ids, @usernames=@usernames, @isGcid=1, @isUsernames=0
```

### 8.2 Get private info by username
```sql
DECLARE @ids dbo.IdList
DECLARE @usernames dbo.UsernameList
INSERT @usernames VALUES ('johndoe123')
EXEC Customer.GetPrivateAggregatedInfo @ids=@ids, @usernames=@usernames, @isGcid=0, @isUsernames=1
```

### 8.3 Get private info by CID
```sql
DECLARE @ids dbo.IdList
DECLARE @usernames dbo.UsernameList
INSERT @ids VALUES (100001)
EXEC Customer.GetPrivateAggregatedInfo @ids=@ids, @usernames=@usernames, @isGcid=0, @isUsernames=0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetPrivateAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetPrivateAggregatedInfo.sql*
