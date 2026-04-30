# Customer.GetDemoAggregatedInfo

> Retrieves aggregated user profile information for demo (virtual) customers, including basic info, account details, settings, and bio, with lookup by CID or GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated demo customer profile rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDemoAggregatedInfo retrieves a comprehensive set of profile data for demo (virtual/practice) customers. Demo accounts let users try the eToro platform with virtual money before committing real funds. This procedure aggregates data from the demo customer record, the linked real customer record, back-office settings, general settings, and user bio into a single result set.

This procedure exists because the application needs a single call to fetch all relevant profile details for a demo user, rather than making multiple separate queries. It mirrors the pattern of the real-customer aggregated info procedures but starts from the demo customer table.

The procedure accepts a list of IDs (via table-valued parameter) and an @isGcid flag that determines whether those IDs are CIDs (demo account IDs) or GCIDs (global customer IDs). It uses OUTER APPLY to find the demo customer, then LEFT JOINs to Real_Customer, Real_BackOfficeCustomer, General_Settings, and UserBio to collect the full profile.

---

## 2. Business Logic

### 2.1 Dual Lookup Mode (CID vs GCID)

**What**: The procedure supports two lookup modes controlled by @isGcid, allowing callers to query by either demo CID or global GCID.

**Columns/Parameters Involved**: `@isGcid`, `@ids`

**Rules**:
- When @isGcid = 0: Looks up Demo_Customer by CID (demo account identifier)
- When @isGcid = 1: Looks up Demo_Customer by GCID (global customer identifier)
- Both paths return the same output columns
- OUTER APPLY on Demo_Customer means a missing demo record returns NULLs (not excluded)

**Diagram**:
```
@ids (IdList) + @isGcid
  |
  +-- @isGcid = 0 --> Demo_Customer WHERE CID = ids.Id
  |
  +-- @isGcid = 1 --> Demo_Customer WHERE GCID = ids.Id
  |
  v
LEFT JOIN Real_Customer ON GCID
LEFT JOIN Real_BackOfficeCustomer ON CID
LEFT JOIN General_Settings ON CID
OUTER APPLY UserBio ON CID
  |
  v
Return: GCID, RealCID, DemoCID, UserName, Names, Language,
        Country, Settings, GuruStatus, PlayerStatus, AccountType, etc.
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of IDs to look up. These are CIDs when @isGcid=0, or GCIDs when @isGcid=1. |
| 2 | @isGcid | int | NO | - | CODE-BACKED | Lookup mode flag: 0 = treat @ids as demo CIDs, 1 = treat @ids as GCIDs. |
| 3 | GCID (output) | int | YES | - | CODE-BACKED | Global Customer ID from Demo_Customer. |
| 4 | RealCID (output) | int | YES | - | CODE-BACKED | CID of the linked real account from Real_Customer. NULL if no real account linked. |
| 5 | DemoCID (output) | int | YES | - | CODE-BACKED | CID of the demo account from Demo_Customer. |
| 6 | UserName (output) | varchar | YES | - | CODE-BACKED | Demo account username. |
| 7 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | User's first name from demo record. |
| 8 | LastName (output) | nvarchar | YES | - | CODE-BACKED | User's last name from demo record. |
| 9 | LanguageID (output) | int | YES | - | CODE-BACKED | User's preferred language. FK to Dictionary.Language. See [Language](_glossary.md#language). |
| 10 | CountryID (output) | int | YES | - | CODE-BACKED | User's registered country. FK to Dictionary.Country. See [Country](_glossary.md#country). |
| 11 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Privacy setting from General_Settings: whether the user allows their full name to be publicly displayed. |
| 12 | AboutMe (output) | nvarchar | YES | - | CODE-BACKED | User bio text from dbo.UserBio. Free-form self-description. |
| 13 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | White label / brand ID. Aliased from LabelID. FK to Dictionary.Label. See [Label](_glossary.md#label). |
| 14 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version the user accepted. From Real_Customer. |
| 15 | HomepageId (output) | int | YES | - | CODE-BACKED | User's homepage preference from General_Settings. |
| 16 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor program status. From Real_BackOfficeCustomer. FK to Dictionary.GuruStatus. See [Guru Status](_glossary.md#guru-status). |
| 17 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status from Real_Customer: 1=Active, 4=Closed/Blocked, etc. FK to Dictionary.PlayerStatus. See [Player Status](_glossary.md#player-status). |
| 18 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type from Real_BackOfficeCustomer. FK to Dictionary.AccountType. |
| 19 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | If this is a sub-account, the CID of the master account. From Real_BackOfficeCustomer. |
| 20 | RegionID (output) | int | YES | - | CODE-BACKED | User's region from demo record. |
| 21 | CountryIDByIP (output) | int | YES | - | CODE-BACKED | Country detected from user's IP address. From demo record. |
| 22 | RegionByIP_ID (output) | int | YES | - | CODE-BACKED | Region detected from user's IP address. From demo record. |
| 23 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level from Real_BackOfficeCustomer. See [Verification Level](_glossary.md#verification-level). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Demo_Customer | OUTER APPLY | Primary demo customer lookup table |
| GCID | dbo.Real_Customer | LEFT JOIN | Links demo user to their real account |
| CID | dbo.Real_BackOfficeCustomer | LEFT JOIN | Account type, guru status, verification level |
| CID | dbo.General_Settings | LEFT JOIN | Privacy and homepage settings |
| CID | dbo.UserBio | OUTER APPLY | User bio/about me text |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called when viewing a demo user's profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDemoAggregatedInfo (procedure)
+-- dbo.Demo_Customer (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.General_Settings (table)
+-- dbo.UserBio (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Demo_Customer | Table | OUTER APPLY - primary demo customer data |
| dbo.Real_Customer | Table | LEFT JOIN on GCID - linked real account |
| dbo.Real_BackOfficeCustomer | Table | LEFT JOIN on CID - account type, guru status |
| dbo.General_Settings | Table | LEFT JOIN on CID - privacy/homepage settings |
| dbo.UserBio | Table | OUTER APPLY on CID - user bio text |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get demo aggregated info by demo CID
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (100001), (100002)
EXEC Customer.GetDemoAggregatedInfo @ids = @ids, @isGcid = 0
```

### 8.2 Get demo aggregated info by GCID
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (50001)
EXEC Customer.GetDemoAggregatedInfo @ids = @ids, @isGcid = 1
```

### 8.3 Manual equivalent - demo user with real account link
```sql
SELECT dc.GCID, rc.CID AS RealCID, dc.CID AS DemoCID,
       dc.UserName, dc.FirstName, dc.LastName, dc.LanguageID, dc.CountryID,
       gs.AllowDisplayFullName, ub.AboutMe, dc.LabelID AS WhiteLabelID,
       bc.GuruStatusID, rc.PlayerStatusID, bc.AccountTypeID
FROM dbo.Demo_Customer dc WITH (NOLOCK)
LEFT JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.GCID = dc.GCID
LEFT JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON bc.CID = rc.CID
LEFT JOIN dbo.General_Settings gs WITH (NOLOCK) ON gs.CID = rc.CID
OUTER APPLY (SELECT AboutMe FROM dbo.UserBio WITH (NOLOCK) WHERE CID = rc.CID) ub
WHERE dc.CID = @DemoCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetDemoAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetDemoAggregatedInfo.sql*
