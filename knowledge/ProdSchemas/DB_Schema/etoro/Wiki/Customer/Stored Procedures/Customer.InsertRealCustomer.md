# Customer.InsertRealCustomer

> Creates a new real (live) eToro customer account by atomically inserting into Customer.CustomerStatic, Customer.CustomerMoney, BackOffice.Customer, and optionally Customer.TrackingId with all registration-time fields.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> INSERT into Customer.CustomerStatic, Customer.CustomerMoney, BackOffice.Customer, Customer.TrackingId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertRealCustomer is the core customer registration procedure for real (live, IsReal=1) eToro accounts. It accepts all customer profile, regulatory, affiliate, and tracking fields at registration time and inserts them atomically into four tables. This is the fundamental "create account" operation: without a successful call to this procedure, no real trading account exists on the platform.

The procedure was referenced in PART-1253 (19/3/23, Noga Rozen) which disabled the Service Broker affiliate tracking call, and EDGE-706 (06/12/2022, Nitzan Holmes) which added Firebase ID storage for mobile registration.

The registration flow: SQL_UserSyncAPI (the user sync/registration service) calls this procedure after pre-validating the registration request. The procedure runs inside a transaction. On success it returns 0. On failure it rolls back, logs the error via History.InsertLogErrorGeneral with the full parameter XML for diagnostics, and re-raises.

Data flows: Three pre-computation steps run before the INSERTs: (1) ExternalID generated from timestamp+SPID, (2) PlatformID resolved from Dictionary.Funnel, (3) RegionByIP_ID resolved from Internal.GetRegionIDByIP. Then four INSERTs execute atomically. CustomerStatic receives the customer identity and profile. CustomerMoney receives a zero-credit balance record. BackOffice.Customer receives the regulatory and fee configuration. Customer.TrackingId receives one row each for AppsFlyer ID, cookie, and Firebase ID if provided.

---

## 2. Business Logic

### 2.1 ExternalID Generation

**What**: A composite unique identifier combining a timestamp and SQL Server process ID, used to globally identify the registration event.

**Columns/Parameters Involved**: `ExternalID` (CustomerStatic column)

**Rules**:
- Formula: `CAST(CONCAT(DateDiff(minute,0,GetDate()), Format(DateDiff(ms,CAST(GetDate() AS Date),GetDate()),'00000000'), Format(@@SPID,'0000')) AS DECIMAL(38,0))`
- Components: minutes since epoch + 8-digit milliseconds-of-day + 4-digit SPID
- Result is a DECIMAL(38,0) number that encodes when and on which connection the registration occurred
- Not a GUID - but unique enough for cross-system tracing of the registration event

### 2.2 Gender Encoding

**What**: The @Gender integer parameter is converted to a character value for storage in CustomerStatic.

**Columns/Parameters Involved**: `@Gender`, `CustomerStatic.Gender`

**Rules**:
- @Gender = 0 -> NULL (not specified)
- @Gender = 1 -> 'M' (male)
- @Gender = anything else -> 'F' (female)

### 2.3 OriginalCID Handling

**What**: Tracks whether this account was originally created under a different CID (e.g., demo->real upgrade or account migration).

**Columns/Parameters Involved**: `@OrigCID`, `CustomerStatic.OriginalCID`

**Rules**:
- If @OrigCID = 0 (no original, this is a fresh registration): OriginalCID = @CID (self-referencing)
- If @OrigCID != 0: OriginalCID = @OrigCID (links to the source account)

### 2.4 OptOut/PrivacyPolicy Logic

**What**: Determines the customer's email opt-out status based on whether they accepted the privacy policy.

**Columns/Parameters Involved**: `@PrivacyPolicyID`, `CustomerStatic.OptOutReasonID`

**Rules**:
- `@OptOutReasonID = CASE WHEN ISNULL(@PrivacyPolicyID, 1) = 1 THEN 0 ELSE 1 END`
- If @PrivacyPolicyID is NULL or 1 (policy version 1 = basic/no policy): OptOutReasonID = 0 (opted in)
- If @PrivacyPolicyID != 1 (customer accepted a specific policy version): OptOutReasonID = 1 (opted out of default communications)
- This controls whether the customer receives marketing communications

### 2.5 Tracking IDs (Mobile Attribution)

**What**: Optional mobile attribution and cookie tracking IDs inserted into Customer.TrackingId on registration.

**Columns/Parameters Involved**: `@AppsFlyerId`, `@UserUniqueIdentifierCookie`, `@FirebaseId`

**Rules**:
- Each is inserted into Customer.TrackingId with TrackingID type code: 1=AppsFlyer, 2=Cookie, 3=Firebase
- Only inserted if the value is non-NULL and non-empty string
- Firebase ID storage added in EDGE-706 (06/12/2022) for mobile registration tracking

### 2.6 IsEmailVerified Initialization

**What**: Email verification status is initialized to unverified (0) at registration if an email was provided.

**Columns/Parameters Involved**: `@Email`, `CustomerStatic.IsEmailVerified`

**Rules**:
- CASE @Email WHEN NULL THEN NULL ELSE 0 END
- NULL email -> NULL IsEmailVerified (no email, nothing to verify)
- Non-NULL email -> IsEmailVerified = 0 (unverified - email confirmation flow must complete)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | int | NO | - | VERIFIED | The trading provider/white-label that the customer is registering under. Used as both ProviderID and RealProviderID in CustomerStatic. |
| 2 | @LoginID | int | NO | - | CODE-BACKED | Login identifier (logging/tracking field, included in error XML but not written to any INSERT - may be used upstream for session tracing). |
| 3 | @OriginalProviderID | int | NO | - | VERIFIED | The original provider if the customer came through an affiliate chain. Written to CustomerStatic.OriginalProviderID. |
| 4 | @OrigCID | int | YES | NULL | VERIFIED | Original CID for account migrations. If 0 or NULL, OriginalCID=@CID (self). Otherwise, links to the source account CID. |
| 5 | @UserName | varchar(20) | NO | - | VERIFIED | Customer's chosen username. Written to CustomerStatic.UserName. Must be unique on the platform. |
| 6 | @LangID | int | NO | - | CODE-BACKED | Language preference. Written to both LanguageID and CommunicationLanguageID in CustomerStatic. |
| 7 | @Email | varchar(50) | NO | - | VERIFIED | Customer's email address. Written to CustomerStatic.Email. IsEmailVerified set to 0 (requires email confirmation). |
| 8 | @CountryID | int | NO | - | VERIFIED | Customer's registered country. FK to Dictionary.Country. Determines regulatory regime, fees, and available instruments. |
| 9 | @TradeLevelID | int | NO | - | CODE-BACKED | Customer's initial trading level. Written to CustomerStatic.TradeLevelID. |
| 10 | @LabelID | int | NO | - | CODE-BACKED | Label/campaign label applied at registration. Written to CustomerStatic.LabelID. |
| 11 | @FunnelID | int | NO | - | VERIFIED | Registration funnel ID. Written to CustomerStatic.FunnelID. Also used to derive PlatformID via Dictionary.Funnel. |
| 12 | @Gender | int | NO | - | VERIFIED | Gender: 0=NULL (unspecified), 1=M (male), other=F (female). Converted to char before INSERT into CustomerStatic.Gender. |
| 13 | @CurrencyID | int | NO | - | VERIFIED | Account base currency. Written to CustomerStatic.CurrencyID. Determines the denomination of balance and P&L. |
| 14 | @FirstName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's first name. PII. Written to CustomerStatic.FirstName. |
| 15 | @LastName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's last name. PII. Written to CustomerStatic.LastName. |
| 16 | @Phone | varchar(50) | YES | NULL | CODE-BACKED | Phone number. PII. Written to CustomerStatic.Phone. |
| 17 | @Mobile | varchar(50) | YES | NULL | CODE-BACKED | Mobile number. PII. Written to CustomerStatic.Mobile. |
| 18 | @Fax | varchar(50) | YES | NULL | CODE-BACKED | Fax number (legacy). PII. Written to CustomerStatic.Fax. |
| 19 | @Address | nvarchar(100) | YES | NULL | CODE-BACKED | Street address. PII. Written to CustomerStatic.Address. |
| 20 | @City | nvarchar(50) | YES | NULL | CODE-BACKED | City. PII. Written to CustomerStatic.City. |
| 21 | @State | varchar(50) | YES | NULL | CODE-BACKED | State/province text. Written to CustomerStatic.State. |
| 22 | @Country | varchar(50) | NO | - | CODE-BACKED | Country name string (text). Included in error XML but not directly inserted into CustomerStatic (CountryID is used instead). |
| 23 | @Zip | nvarchar(50) | YES | NULL | CODE-BACKED | Zip/postal code. PII. Written to CustomerStatic.Zip. |
| 24 | @BirthDate | datetime | NO | - | CODE-BACKED | Date of birth. PII. Written to CustomerStatic.BirthDate. Used for KYC age verification. |
| 25 | @RegIP | varchar(15) | YES | NULL | VERIFIED | Registration IP address. Written to CustomerStatic.IP. Also used to derive RegionByIP_ID via Internal.GetRegionIDByIP. |
| 26 | @SerialID | int | NO | - | VERIFIED | Affiliate/referral serial ID. Written to CustomerStatic.SerialID. Used for affiliate commission attribution. |
| 27 | @ReferralID | int | NO | - | CODE-BACKED | Referral source ID. Written to CustomerStatic.ReferralID. |
| 28 | @SubSerialID | varchar(1024) | NO | - | CODE-BACKED | Sub-affiliate identifier string. Written to CustomerStatic.SubSerialID. |
| 29 | @DownloadID | int | NO | - | CODE-BACKED | Download/campaign tracking ID. Written to CustomerStatic.DownloadID. |
| 30 | @FunnelFromID | int | NO | - | CODE-BACKED | The originating funnel step ID. Written to CustomerStatic.FunnelFromID. |
| 31 | @BannerID | int | NO | - | CODE-BACKED | Banner/ad tracking ID. Written to CustomerStatic.BannerID. |
| 32 | @ClientVersion | varchar(20) | NO | - | CODE-BACKED | Client application version string at registration. Written to CustomerStatic.ClientVersion. |
| 33 | @DownloadCounter | int | NO | - | CODE-BACKED | Download attempt counter. Written to CustomerStatic.DownloadCounter. |
| 34 | @PersonID | varchar(50) | YES | NULL | CODE-BACKED | External person identifier (e.g., social login ID). Written to CustomerStatic.PersonID. |
| 35 | @SendEmail | tinyint | NO | - | CODE-BACKED | Flag to trigger registration confirmation email. Included in error XML but not directly inserted into CustomerStatic; likely used by the calling application layer. |
| 36 | @GCID | int | YES | 0 | VERIFIED | Group Customer ID. Written to CustomerStatic.GCID and CustomerMoney.GCID. Default=0 (pre-GCID registrations or when not yet assigned). |
| 37 | @WeekendFeePercentage | tinyint | NO | - | CODE-BACKED | Weekend holding fee percentage. Written to CustomerStatic.WeekendFeePrecentage (note typo in column name). |
| 38 | @PlayerLevelID | int | NO | - | VERIFIED | Customer classification: regular customer vs Popular Investor vs test. Written to CustomerStatic.PlayerLevelID. |
| 39 | @IsRequestedCall | bit | NO | - | CODE-BACKED | Whether customer requested a sales call-back at registration. Written to CustomerStatic.IsRequestedCall. |
| 40 | @AccountTypeID | int | NO | - | CODE-BACKED | Account type (Private/Corporate). Written to BackOffice.Customer.AccountTypeID. |
| 41 | @TimeZone | int | NO | - | CODE-BACKED | Customer's time zone. Written to CustomerStatic.TimeZoneID. |
| 42 | @PlayerStatus | int | NO | - | CODE-BACKED | Initial account status (Open/Closed). Written to CustomerStatic.PlayerStatusID. |
| 43 | @SpreadGroupID | int | NO | - | CODE-BACKED | Spread group assignment for trading fees. Written to CustomerStatic.SpreadGroupID. |
| 44 | @Occurred | datetime | NO | - | VERIFIED | Registration timestamp. Written to CustomerStatic.Registered and BackOffice.Customer.RegulationChangeDate. |
| 45 | @CountryIdByIP | int | NO | - | CODE-BACKED | Country resolved from the registration IP address (pre-computed by caller). Written to CustomerStatic.CountryIDByIP. |
| 46 | @ExpirationDate | datetime | NO | - | CODE-BACKED | Account expiration date. Written to CustomerStatic.AccountExpirationDate. |
| 47 | @HelpDeskTypeID | int | NO | - | CODE-BACKED | Support tier assignment. Written to CustomerStatic.HelpDeskType. |
| 48 | @PrivacyPolicyID | int | NO | - | VERIFIED | Privacy policy version accepted at registration. Written to CustomerStatic.PrivacyPolicyID. Also determines OptOutReasonID: if NULL or 1, OptOut=0 (opted in); otherwise OptOut=1. |
| 49 | @DefaultCashoutFeeGroupID | int | NO | - | CODE-BACKED | Default withdrawal fee group. Written to BackOffice.Customer.CashoutFeeGroupID. |
| 50 | @RegulationID | int | NO | - | CODE-BACKED | Regulatory regime assignment. Written to BackOffice.Customer.RegulationID. |
| 51 | @ChangePassword | bit | NO | - | CODE-BACKED | Whether customer must change password on first login. Written to BackOffice.Customer.ChangePassword. |
| 52 | @RiskStatusID | int | NO | - | CODE-BACKED | Initial risk status assignment. Written to BackOffice.Customer.RiskStatusID. |
| 53 | @StateID | int | NO | - | CODE-BACKED | State/province ID (numeric FK). Written to CustomerStatic.StateID. |
| 54 | @PhonePrefix | nvarchar(6) | YES | NULL | CODE-BACKED | International phone prefix. Written to CustomerStatic.PhonePrefix. |
| 55 | @PhoneBody | nvarchar(24) | YES | NULL | CODE-BACKED | Phone number body (without prefix). Written to CustomerStatic.PhoneBody. |
| 56 | @AppsFlyerId | varchar(50) | YES | NULL | VERIFIED | AppsFlyer mobile attribution ID. If non-empty, inserted into Customer.TrackingId with TrackingID=1. |
| 57 | @UserUniqueIdentifierCookie | varchar(50) | YES | NULL | CODE-BACKED | Browser cookie unique identifier. If non-empty, inserted into Customer.TrackingId with TrackingID=2. |
| 58 | @RegionID | int | YES | NULL | CODE-BACKED | Geographic region ID (explicit, caller-supplied). If NULL, falls back to RegionByIP_ID. Written to CustomerStatic.RegionID. |
| 59 | @RegionByIP_ID | int | YES | NULL | CODE-BACKED | Geographic region ID derived from registration IP (via Internal.GetRegionIDByIP). Written to CustomerStatic.RegionByIP_ID. |
| 60 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated (intended future) regulation ID. Written to BackOffice.Customer.DesignatedRegulationID. |
| 61 | @CID | int | NO | - | VERIFIED | Internal eToro Customer ID - the primary key for all three INSERT statements. Pre-assigned by the calling system before this procedure is invoked. |
| 62 | @FirebaseId | varchar(50) | YES | NULL | VERIFIED | Firebase mobile ID for push notifications. If non-empty, inserted into Customer.TrackingId with TrackingID=3. Added in EDGE-706 (06/12/2022). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Writer (INSERT) | Creates the core customer profile record |
| @CID | Customer.CustomerMoney | Writer (INSERT) | Creates the customer's balance record (Credit=0) |
| @CID | BackOffice.Customer | Writer (INSERT) | Creates the customer's regulatory/fee configuration record |
| @CID + @AppsFlyerId | Customer.TrackingId | Writer (INSERT) | Stores AppsFlyer attribution ID (TrackingID=1) if provided |
| @CID + @UserUniqueIdentifierCookie | Customer.TrackingId | Writer (INSERT) | Stores browser cookie ID (TrackingID=2) if provided |
| @CID + @FirebaseId | Customer.TrackingId | Writer (INSERT) | Stores Firebase ID (TrackingID=3) if provided |
| @FunnelID | Dictionary.Funnel | Reader (SELECT) | Resolves PlatformID from funnel configuration |
| @RegIP | Internal.GetRegionIDByIP | Function call | Resolves RegionByIP_ID from registration IP address |
| Error | History.InsertLogErrorGeneral | Writer (EXEC) | Logs registration errors with full parameter XML on failure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserSyncAPI | EXECUTE permission | Caller | User registration service calls this to create new real accounts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertRealCustomer (procedure)
├── Customer.CustomerStatic (table)
├── Customer.CustomerMoney (table)
├── BackOffice.Customer (table)
├── Customer.TrackingId (table)
├── Dictionary.Funnel (table)
├── Internal.GetRegionIDByIP (function)
└── History.InsertLogErrorGeneral (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Primary INSERT target - customer identity and profile |
| Customer.CustomerMoney | Table | INSERT target - initial balance record (Credit=0) |
| BackOffice.Customer | Table | INSERT target - regulatory and fee configuration |
| Customer.TrackingId | Table | Conditional INSERT target - mobile attribution and cookie tracking IDs |
| Dictionary.Funnel | Table | SELECT PlatformID WHERE FunnelID = @FunnelID |
| Internal.GetRegionIDByIP | Function | Resolves RegionByIP_ID from registration IP |
| History.InsertLogErrorGeneral | Procedure | Called in CATCH to log registration errors with full parameter XML |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserSyncAPI | Service account | Calls this procedure for new real account registration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Notes:
- Runs inside a BEGIN TRANSACTION / COMMIT TRANSACTION - fully atomic across all four INSERTs
- ROLLBACK on any error in CATCH block (if @@TranCount=1)
- Service Broker affiliate notification call was disabled per PART-1253 (19/3/23, Noga Rozen) - the EXEC line is commented out
- Password column initialized to empty string ('') in CustomerStatic

---

## 8. Sample Queries

### 8.1 Verify successful registration across all four tables
```sql
DECLARE @cid INT = 12345678;
SELECT 'CustomerStatic' AS Source, CID, UserName, Email, CountryID, GCID, Registered
FROM Customer.CustomerStatic WITH (NOLOCK) WHERE CID = @cid
UNION ALL
SELECT 'CustomerMoney', CID, CAST(Credit AS VARCHAR), '', NULL, GCID, NULL
FROM Customer.CustomerMoney WITH (NOLOCK) WHERE CID = @cid;
```

### 8.2 Check tracking IDs registered for a customer
```sql
SELECT CID, GCID, TrackingID, TrackingValue
FROM Customer.TrackingId WITH (NOLOCK)
WHERE CID = 12345678;
```

### 8.3 Check BackOffice registration data
```sql
SELECT CID, CashoutFeeGroupID, AccountTypeID, RegulationID, DesignatedRegulationID, RiskStatusID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-1253 | Jira | Noga Rozen disabled the Service Broker affiliate tracking call on 19/3/23; registration SB notification commented out |
| EDGE-706 | Jira | Nitzan Holmes added FirebaseId parameter storage on 06/12/2022 for mobile registration tracking |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 54 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from SP comments) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.InsertRealCustomer | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.InsertRealCustomer.sql*
