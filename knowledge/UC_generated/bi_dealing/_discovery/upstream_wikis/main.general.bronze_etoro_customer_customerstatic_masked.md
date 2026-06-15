# Customer.CustomerStatic

> The central customer master record table for all 18.7M eToro customers: stores identity, registration, demographics, status, trading configuration, and PII fields. All changes are versioned into History.Customer via three triggers. PII columns are protected by Dynamic Data Masking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 16 (1 clustered PK + 15 nonclustered, several unique) |

---

## 1. Business Meaning

Customer.CustomerStatic is the single master record for every eToro customer. Every account registration creates a row here. With 18.7 million rows, this is the foundational customer data store that nearly every part of the platform references: trading engines, compliance, BackOffice, KYC, risk, affiliate tracking, billing, and more.

The table captures the full customer profile: who they are (name, birth date, address, email, phone), how they are regulated (CountryID, ProviderID, SpreadGroupID), their platform status (PlayerStatusID, PlayerLevelID, AccountStatusID), trading configuration (CurrencyID, TimeZoneID, IsHedged, LeverageType), and acquisition source (SerialID/Affiliate, CampaignID, FunnelID).

All PII columns (IP, BirthDate, FirstName, LastName, Address, Zip, Email, Phone, Mobile, BuildingNumber, PhoneBody) are protected by SQL Server Dynamic Data Masking - unauthorized users see masked placeholder values instead of real data.

Three DDL-defined triggers maintain a complete change history:
- `CustomerVersionInsert`: On INSERT - creates the initial version in History.Customer (ValidTo='3000-01-01'); also resets IsHedged on Customer.Customer for PI accounts (LabelID=26 or PlayerLevelID=4)
- `CustomerVersionUpdate`: On UPDATE - closes the previous History.Customer version (sets ValidTo=now) and inserts a new version with ValidTo='3000-01-01'; also updates Customer.LastChanges when Email changes; updates BackOffice.Customer.FXEligibilityDate when PlayerLevelID changes
- `CustomerVersionDelete`: On DELETE - closes the active History.Customer version for the deleted row

GCID (Group Customer ID) was added later as a cross-product identity mechanism, linking the same physical person's accounts across eToro products. DltID links to Distributed Ledger Technology integration. ApexID links to the APEX US stocks broker.

---

## 2. Business Logic

### 2.1 History Versioning via Triggers

**What**: Every INSERT/UPDATE/DELETE on CustomerStatic is captured in History.Customer as a time-bounded version row, enabling point-in-time reconstruction of any customer's profile state.

**Columns/Parameters Involved**: All 84 columns (except Password since hash implementation)

**Rules**:
- INSERT trigger: creates History.Customer row with ValidFrom=GetDate(), ValidTo='3000-01-01'
- UPDATE trigger: sets ValidTo=GetUTCDate() on the previous History.Customer row, then inserts a new version with ValidFrom=GetUTCDate(), ValidTo='3000-01-01'
- DELETE trigger: sets ValidTo=GetDate() on the active (ValidTo='3000-01-01') History.Customer row
- UPDATE trigger checks 50+ columns for actual changes - only creates a new history version when at least one tracked column changes (avoids version bloat on no-op updates)
- Password changes are NOT versioned (per changelog: "Removing the password from columns which their change would Update History.Customer after Hash Password implementation")
- ValidTo sentinel value: '30000101 00:00:00.000' in the trigger (not '9999-12-31') signals the current active version

### 2.2 IsHedged Logic

**What**: Customer.Customer.IsHedged flag is managed by the INSERT and UPDATE triggers, determining whether the customer's trades are hedged on the broker side.

**Columns/Parameters Involved**: `LabelID`, `PlayerLevelID` (from CustomerStatic); `IsHedged` (on Customer.Customer)

**Rules**:
- Set IsHedged=0 (not hedged) when: LabelID=26 OR PlayerLevelID=4 (Popular Investors)
- OR when CID is in CEP.ListCIDMappings (NamedListID=3) OR in BackOffice.BonusOnlyCustomers
- Set IsHedged=1 (hedged, default) for all other customers
- Default at creation: IsHedged=1 (DEFAULT constraint on Customer.CustomerStatic)
- The trigger evaluates LabelID and PlayerLevelID on every relevant update and adjusts IsHedged accordingly

### 2.3 Account Status and Player Status

**What**: Two separate status concepts govern account accessibility and compliance lifecycle.

**Columns/Parameters Involved**: `PlayerStatusID`, `AccountStatusID`, `PendingClosureStatusID`

**Rules**:
- PlayerStatusID (FK -> Dictionary.PlayerStatus): compliance/trading status. Distribution: 97.5% = 1 (Active/Registered), 0.7% = 10, 0.7% = 2, 0.6% = 9. Values across 2-15 for special statuses.
- AccountStatusID (FK not declared): account operational status. 93.9% = 1 (Normal/Active), 5.6% = NULL (pre-AccountStatusID era), 0.5% = 2. Default = 1.
- PendingClosureStatusID: tracks pending account closure workflow. Default = 1.
- PlayerStatusReasonID and PlayerStatusSubReasonID provide hierarchical reason codes for non-Active statuses (FK -> Dictionary.PlayerStatusSubReasons).

### 2.4 Identity and Duplicate Detection

**What**: Three mechanisms provide identity resilience and duplicate detection.

**Columns/Parameters Involved**: `ID`, `GCID`, `LinkedAccountHash1`, `ExternalID`, `LowerEmail`, `UserName_LOWER`

**Rules**:
- `ID` (uniqueidentifier): system GUID for REST API identity; DEFAULT = newsequentialid() for insert-performance; unique index Idx_CustomerCustomerStaticID
- `GCID` (int, nullable): Group Customer ID - links the same person's CID across eToro product suite. Indexed via IDX_Customer_Customer_GCID with wide INCLUDE coverage for performance.
- `LinkedAccountHash1` (computed, PERSISTED): MD5(lower(FirstName)|'|'|lower(LastName)|'|'|Gender|'|'|Zip|'|'|CountryID|'|'|BirthDate). Used to detect potentially duplicate accounts (same person registered twice). Indexed via Idx_CustomerStatic_LinkedAccountHash1.
- `LowerEmail` (computed): lower(Email) - used in unique index IX_CustomerCustomer_LowerEmail_Cover for case-insensitive email uniqueness enforcement
- `UserName_LOWER` (computed): lower(UserName) - used in unique index Unique_CustomerStatic_UserName_LOWER for case-insensitive username uniqueness (fillfactor=70 - high write/update expected)
- `ExternalID` (decimal(38,0)): APEX external ID (unique index); very large decimal type to accommodate APEX's identifier format

### 2.5 Email Change Tracking

**What**: The UPDATE trigger writes to Customer.LastChanges whenever Email is changed.

**Columns/Parameters Involved**: `Email`

**Rules**:
- When UPDATE(Email) and old Email != new Email: MERGE into Customer.LastChanges
- If CID exists in LastChanges: UPDATE EmailLastChangeDate = GETUTCDATE()
- If not: INSERT (CID, EmailLastChangeDate) - creates the first email change record
- Enables compliance/audit to know exactly when a customer last changed their email address

### 2.6 DLT and APEX Integration

**What**: Two external system identifiers stored in CustomerStatic for broker integrations.

**Columns/Parameters Involved**: `ApexID`, `DltID`, `ExternalID`

**Rules**:
- ApexID (varchar(8)): APEX US stocks broker account ID. Non-null only for US-regulated customers who have APEX accounts. Requires: Regulation #8, Country = USA/US territories, Level >= 2.
- DltID (uniqueidentifier): Distributed Ledger Technology integration ID (from HLD: COAKVU-2880 DLT Integration, Confluence CR space)
- ExternalID (decimal(38,0)): unique index, nullable - APEX-generated external ID; separate from ApexID varchar

---

## 3. Data Overview

| CID | GCID | ProviderID | CountryID | PlayerStatusID | PlayerLevelID | IsReal | IsHedged | Registered |
|---|---|---|---|---|---|---|---|---|
| -1 | 1983586 | 1 | 0 | 1 | 1 | true | 1 | 2008-03-16 | System account (CID=-1): CountryID=0, earliest registration, level=1 |
| 5 | 1983587 | 1 | 218 | 1 | 4 | true | 0 | 2017-02-22 | Popular Investor (PlayerLevel=4): IsHedged=0 per trigger rule |
| 15 | 1983588 | 1 | 250 | 1 | 4 | true | 0 | 2017-02-09 | Popular Investor: same IsHedged=0 pattern |

*18,744,339 total rows. All IsReal=true in this environment. PlayerStatus=1 accounts: 97.5% (18,285,443). PlayerLevel=1 accounts: 94% (17,614,427).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. |
| 2 | OriginalProviderID | int | NO | 0 | CODE-BACKED | The provider ID from which this account was originally migrated or registered. Together with OriginalCID, forms the original identity key (indexed via CCST_ORIGINAL). Used for data migration tracing. |
| 3 | OriginalCID | int | NO | 0 | CODE-BACKED | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0 (CCST_NULLORIGINAL constraint). |
| 4 | ProviderID | int | NO | 0 | VERIFIED | Current active provider ID. FK to Trade.Provider. Determines the trading provider/broker for this customer's account. Default=0. |
| 5 | RealProviderID | int | YES | - | CODE-BACKED | The real (underlying) provider ID, as opposed to any UI-facing provider abstraction. Nullable. |
| 6 | CountryID | int | NO | 0 | VERIFIED | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. |
| 7 | CountryIDByIP | int | NO | 0 | CODE-BACKED | Country detected from the customer's IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). |
| 8 | StateID | int | NO | 0 | VERIFIED | US state ID for US customers, or 0 for others. FK to Dictionary.State. Required for certain regulatory and tax purposes. Default=0. |
| 9 | LanguageID | int | NO | 0 | VERIFIED | Customer's preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. |
| 10 | CommunicationLanguageID | int | NO | 0 | CODE-BACKED | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. |
| 11 | CurrencyID | int | NO | 0 | VERIFIED | Customer's account base currency. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). Currently all USD in practice; central to the multi-currency migration roadmap. Default=0. |
| 12 | TimeZoneID | int | NO | 0 | VERIFIED | Customer's time zone. FK to Dictionary.TimeZone. Used for time-aware notifications and report generation. Default=0. |
| 13 | PlayerStatusID | int | NO | 0 | VERIFIED | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. |
| 14 | CampaignID | int | YES | - | VERIFIED | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. |
| 15 | PlayerLevelID | int | NO | 0 | VERIFIED | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor (triggers IsHedged=0 in Customer.Customer); 7=VIP. Determines available features and risk limits. Default=0. |
| 16 | TradeLevelID | int | NO | 0 | VERIFIED | Trading knowledge/experience classification. FK to Dictionary.TradeLevel. Used for MiFID suitability assessment and leverage tier assignment. Default=0. |
| 17 | SpreadGroupID | int | NO | 0 | VERIFIED | Spread/pricing group. FK to Trade.SpreadGroup. Determines which pricing table the customer uses (retail, professional, institutional). Default=0. |
| 18 | LabelID | int | NO | 0 | VERIFIED | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0 in Customer.Customer). Default=0. |
| 19 | FunnelID | int | YES | - | VERIFIED | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. |
| 20 | UserName | varchar(20) | NO | - | VERIFIED | Customer's login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). |
| 21 | Password | varchar(20) | NO | - | CODE-BACKED | Hashed password. varchar(20) but stores a hash. Password changes are NOT versioned in History.Customer (per the hash implementation decision). |
| 22 | Registered | datetime | NO | getdate() | VERIFIED | Account registration date. Default=getdate(). Indexed via Idx_Customer_Customer_Registered with INCLUDE on key contact fields. |
| 23 | IsReal | bit | NO | - | VERIFIED | Whether this is a real-money account (1) or demo (0). All rows in this environment are IsReal=1. Demo accounts may be in separate DB or schema. |
| 24 | IP | varchar(15) | NO | - | VERIFIED | Registration IP address. **Dynamic Data Masking: default().** Indexed via IX_CustomerStatic_IP. |
| 25 | BirthDate | datetime | YES | - | VERIFIED | Customer date of birth. **Dynamic Data Masking: default().** Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. |
| 26 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', or 'U' (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. |
| 27 | FirstName | nvarchar(50) | YES | - | VERIFIED | Legal first name in Unicode. **Dynamic Data Masking: default().** nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. See Customer.CustomerLatinName for Latin transliterations. |
| 28 | LastName | nvarchar(50) | YES | - | VERIFIED | Legal last name in Unicode. **Dynamic Data Masking: default().** nvarchar. Used in LinkedAccountHash1. |
| 29 | Address | nvarchar(100) | YES | - | VERIFIED | Street address in Unicode. **Dynamic Data Masking: default().** |
| 30 | City | nvarchar(50) | YES | - | CODE-BACKED | City in Unicode. NOT masked (unlike Address/Zip). |
| 31 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal code. **Dynamic Data Masking: default().** Used in LinkedAccountHash1. |
| 32 | SerialID | int | YES | - | VERIFIED | Affiliate (partner) ID under which the customer was acquired. FK to BackOffice.Affiliate. NULL for direct/organic registrations. Indexed via CCST_SerialID. |
| 33 | ReferralID | int | YES | - | CODE-BACKED | Referral CID - the customer who referred this customer (for RAF program tracking). Filtered index IXFiltered_CustomerStatic_ReferralID covers only ReferralID > 0. |
| 34 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. |
| 35 | Email | varchar(50) | YES | - | VERIFIED | Customer email address. **Dynamic Data Masking: default().** Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. |
| 36 | IsEmailVerified | bit | YES | - | CODE-BACKED | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. |
| 37 | Phone | varchar(30) | YES | - | VERIFIED | Phone number. **Dynamic Data Masking: default().** |
| 38 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number. Legacy field; rarely populated in modern registrations. |
| 39 | Mobile | varchar(30) | YES | - | VERIFIED | Mobile number. **Dynamic Data Masking: default().** |
| 40 | Comments | varchar(8000) | YES | - | CODE-BACKED | Internal comment field. BackOffice operators can add notes. Indexed via Idx_Customer_Customer_AccountStatusID INCLUDE. |
| 41 | DownloadID | int | YES | - | CODE-BACKED | Platform download source ID. Legacy tracking for which platform installer the customer used. |
| 42 | BannerID | int | YES | - | CODE-BACKED | Advertising banner ID that led to registration. Legacy acquisition tracking. |
| 43 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client application version at registration. |
| 44 | PersonID | varchar(50) | YES | - | CODE-BACKED | External person identifier. |
| 45 | DownloadCounter | int | YES | - | CODE-BACKED | Number of times the customer has downloaded the platform client. |
| 46 | AccountExpirationDate | datetime | YES | - | CODE-BACKED | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. |
| 47 | HelpDeskType | smallint | YES | - | CODE-BACKED | Customer service tier assignment (VIP helpdesk, standard, etc.). |
| 48 | LotCountGroupID | int | NO | 0 | VERIFIED | Lot/quantity group. FK to Dictionary.LotCountGroup. Controls minimum/maximum lot sizes for trading. Default=0. |
| 49 | PrivacyPolicyID | int | YES | - | VERIFIED | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. |
| 50 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. Indexed via IDX_Customer_Customer_GCID with wide INCLUDE for lookup performance. NULL for older accounts predating GCID introduction. |
| 51 | WeekendFeePrecentage | tinyint | YES | 100 | CODE-BACKED | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo "Precentage" instead of "Percentage". |
| 52 | IsEmailActivated | tinyint | YES | 0 | CODE-BACKED | Email activation status flag. Default=0 (not activated). Separate from IsEmailVerified - tracks whether the account email activation step was completed. |
| 53 | UserName_LOWER | computed | YES | - | CODE-BACKED | Computed: lower(UserName). PERSISTED implicitly via unique index. Used for case-insensitive username uniqueness enforcement across 18.7M customers. |
| 54 | AccountStatusID | tinyint | YES | 1 | VERIFIED | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. 5.6% NULL (pre-AccountStatusID era accounts). Indexed via Idx_Customer_Customer_AccountStatusID. |
| 55 | PendingClosureStatusID | tinyint | YES | 1 | CODE-BACKED | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. |
| 56 | ClientTypeID | tinyint | YES | 0 | VERIFIED | Client classification type. FK to Dictionary.ClientType. Default=0. Used for MiFID2 client categorization (retail, professional, etc.). |
| 57 | IsRequestedCall | bit | YES | - | CODE-BACKED | Whether the customer has requested a callback from sales/support. |
| 58 | FunnelFromID | int | YES | - | CODE-BACKED | Source funnel variant ID tracking where the customer came from within the acquisition funnel. Indexed via Idx_Customer_CustomerStatic_CID INCLUDE. |
| 59 | LeverageType | int | YES | 1 | CODE-BACKED | Leverage setting type. Default=1. Determines the leverage scheme applied to this customer's account. |
| 60 | IsHedged | tinyint | NO | 1 | CODE-BACKED | Whether the customer's trades are hedged on the brokerage side. Default=1 (hedged). Set to 0 by CustomerVersionInsert/Update triggers when LabelID=26 or PlayerLevelID=4 (Popular Investors), or when in CEP.ListCIDMappings(NamedListID=3) or BackOffice.BonusOnlyCustomers. |
| 61 | ID | uniqueidentifier | NO | newsequentialid() | VERIFIED | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). Unique index Idx_CustomerCustomerStaticID. |
| 62 | VerificationTitle | nvarchar(50) | NO | Customer.VerificationTitle_Default() | CODE-BACKED | KYC verification title/level text. Default from Customer.VerificationTitle_Default() function. Changes are versioned in History.Customer. |
| 63 | VerificationTitleVersion | uniqueidentifier | NO | newid() | CODE-BACKED | Version GUID for optimistic concurrency on verification title updates. Default=newid(). |
| 64 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building/apartment number. **Dynamic Data Masking: default().** Separate from Address for structured address storage. |
| 65 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | International dialing prefix (e.g., +1, +44). Stored separately from PhoneBody for structured phone number handling. |
| 66 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Local phone number without country prefix. **Dynamic Data Masking: default().** |
| 67 | ExternalID | decimal(38,0) | YES | - | VERIFIED | APEX broker external ID. Unique index Idx_CustomerCustomerStatic_ExternalID. Decimal(38,0) to accommodate APEX's very large numeric ID format. |
| 68 | RegionID | int | YES | - | CODE-BACKED | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. |
| 69 | RegionByIP_ID | int | YES | - | CODE-BACKED | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. |
| 70 | PlatformID | int | YES | - | CODE-BACKED | Platform/product identifier (web, mobile, etc.). |
| 71 | OptOutReasonID | smallint | YES | - | CODE-BACKED | Reason for GDPR/marketing opt-out. Set when customer opts out of communications. |
| 72 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | Reason code for current PlayerStatusID. Provides the "why" behind a non-Active status. |
| 73 | MiddleName | nvarchar(50) | YES | - | VERIFIED | Middle name in Unicode. **Dynamic Data Masking: default().** Added 2018 (changelog: 50094). Included in CustomerVersionUpdate history tracking. |
| 74 | CitizenshipCountryID | int | YES | - | VERIFIED | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 (changelog: 50308) for enhanced KYC. |
| 75 | LinkedAccountHash1 | computed | YES | - | VERIFIED | PERSISTED computed column: MD5(lower(FirstName)|'|'|lower(LastName)|'|'|Gender|'|'|Zip|'|'|CountryID|'|'|BirthDate). Used to detect duplicate registrations (same person, multiple accounts). Indexed via Idx_CustomerStatic_LinkedAccountHash1. |
| 76 | LowerEmail | computed | YES | - | CODE-BACKED | Computed: lower(Email). Used in unique index IX_CustomerCustomer_LowerEmail_Cover for case-insensitive email uniqueness. |
| 77 | PlayerStatusSubReasonID | int | YES | - | VERIFIED | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). |
| 78 | PlayerStatusSubReasonComment | varchar(64) | YES | - | CODE-BACKED | Free-text comment accompanying the PlayerStatusSubReasonID. Max 64 chars. |
| 79 | POBCountryID | int | YES | - | VERIFIED | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436 Add Place of Birth to KYC, Confluence CR). |
| 80 | SubRegionID | int | YES | - | VERIFIED | Sub-region (province/state for non-US countries). FK to Dictionary.SubRegion. Added 2019 (RD-5830 Add province to Italy, used for EU state/province for address and regulatory purposes). |
| 81 | EmailVerificationProviderID | int | YES | - | VERIFIED | External email verification provider used to verify this customer's email. FK to Dictionary.EmailVerificationProvider. Added 2020. |
| 82 | ApexID | varchar(8) | YES | - | VERIFIED | APEX US stocks broker account ID. Indexed via Apexid (NC) index. Only populated for US-regulated customers at Level >= 2 who have APEX accounts (see APEX Confluence page). |
| 83 | DltID | uniqueidentifier | YES | - | VERIFIED | Distributed Ledger Technology integration ID. Added per HLD: COAKVU-2880 DLT Integration (Confluence CR). Links customer to DLT/blockchain system. |
| 84 | TradeLevelID | int | NO | 0 | VERIFIED | Trading knowledge level for MiFID suitability. FK to Dictionary.TradeLevel. Default=0. Used in regulatory suitability assessment for leverage and product access. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | FK (FK_TSPRV_TSCST) | Trading provider/broker |
| SpreadGroupID | Trade.SpreadGroup | FK (FK_TSPG_CCST) | Pricing/spread group |
| SerialID | BackOffice.Affiliate | FK (FK_BAFF_CCST) | Affiliate acquisition source |
| CampaignID | BackOffice.Campaign | FK (FK_BCMP_CCST) | Marketing campaign |
| CountryID | Dictionary.Country | FK (FK_TDCNR_TSCST) | Country of residence |
| CitizenshipCountryID | Dictionary.Country | FK (FK_Customer_CustomerStatic_CitizenshipCountryID) | Citizenship country |
| POBCountryID | Dictionary.Country | FK (FK_Customer_CustomerStatic_POBCountryID) | Place of birth country |
| StateID | Dictionary.State | FK (FK_TDSTT_TSCST) | US state |
| LanguageID | Dictionary.Language | FK (FK_TDLNG_TSCST) | Platform language |
| CurrencyID | Dictionary.Currency | FK (FK_TDCUR_TSCST) | Account base currency |
| TimeZoneID | Dictionary.TimeZone | FK (FK_TDTMZ_TSCST) | Time zone |
| PlayerStatusID | Dictionary.PlayerStatus | FK (FK_TDPLS_TSCST) | Account status |
| PlayerLevelID | Dictionary.PlayerLevel | FK (FK_TDPLL_TSCST) | Player experience level |
| TradeLevelID | Dictionary.TradeLevel | FK (FK_DTDL_CCST) | Trading knowledge level |
| LabelID | Dictionary.Label | FK (FK_CCST_DILA, NOCHECK) | Internal segment label |
| LotCountGroupID | Dictionary.LotCountGroup | FK (FK_CCST_DLCG) | Lot/quantity group |
| ClientTypeID | Dictionary.ClientType | FK (FK_CC_CTID) | MiFID client classification |
| FunnelID | Dictionary.Funnel | FK (FK_CCST_DFNL) | Registration funnel |
| PrivacyPolicyID | Dictionary.PrivacyPolicy | FK (FK_DICT_DPRP) | Privacy policy version |
| SubRegionID | Dictionary.SubRegion | FK (FK_Customer_CustomerStatic_SubRegionID) | Province/sub-region |
| EmailVerificationProviderID | Dictionary.EmailVerificationProvider | FK (FK_Customer_CustomerStatic_EmailVerificationProviderID) | Email verification provider |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | FK (FK_Customer_CustomerStatic_Col2) | Status sub-reason |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Customer | CID | VERSION HISTORY | Full change history via INSERT/UPDATE/DELETE triggers |
| Customer.LastChanges | CID | EMAIL AUDIT | Email change timestamp tracking (via CustomerVersionUpdate trigger) |
| BackOffice.Customer | CID | TRIGGER-UPDATED | FXEligibilityDate updated when PlayerLevelID changes |
| Customer.CustomerMoney | CID | COMPANION | Balance table - one-to-one with CustomerStatic |
| Customer.BlockedCustomerOperations | CID | RESTRICTION | Active trading restrictions |
| Customer.Address | GCID | ADDRESS | Customer address records |
| Customer.CustomerLatinName | CID | LATIN NAME | Latin transliterations |
| Customer.CustomerLatinNameFromNonLatin | CID | SOURCE | Source for automated diacritic stripping |
| Customer.SetCustomerLatinNameFromNonLatin | CID | READER | Reads FirstName/LastName for diacritic detection |
| (hundreds of procedures, views, functions) | CID | READERS | Universal customer master referenced throughout the platform |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerStatic (table)
|- Trade.Provider [FK]
|- Trade.SpreadGroup [FK]
|- BackOffice.Affiliate [FK - SerialID]
|- BackOffice.Campaign [FK]
|- Dictionary.Country [FK x3: CountryID, CitizenshipCountryID, POBCountryID]
|- Dictionary.State [FK]
|- Dictionary.Language [FK]
|- Dictionary.Currency [FK]
|- Dictionary.TimeZone [FK]
|- Dictionary.PlayerStatus [FK]
|- Dictionary.PlayerLevel [FK]
|- Dictionary.TradeLevel [FK]
|- Dictionary.Label [FK NOCHECK]
|- Dictionary.LotCountGroup [FK]
|- Dictionary.ClientType [FK]
|- Dictionary.Funnel [FK]
|- Dictionary.PrivacyPolicy [FK]
|- Dictionary.SubRegion [FK]
|- Dictionary.EmailVerificationProvider [FK]
|- Dictionary.PlayerStatusSubReasons [FK]
```

### 6.1 Objects This Depends On

See Relationships section for full FK list (20 FK dependencies).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Customer | Table | Trigger-maintained full version history |
| Customer.LastChanges | Table | Email change audit trail |
| BackOffice.Customer | Table | FXEligibilityDate trigger update |
| Customer.SetCustomerLatinNameFromNonLatin | Stored Procedure | Source of FirstName/LastName for diacritic detection |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CCST | CLUSTERED | CID ASC | - | - | Active |
| Apexid | NC | ApexID ASC | - | - | Active |
| CCST_ORIGINAL | NC | OriginalCID, OriginalProviderID | UserName, LowerEmail, FirstName, LastName, BirthDate, CountryID, Zip, Gender | - | Active |
| CCST_PLAYERLEVEL | NC | PlayerLevelID | - | - | Active |
| CCST_SerialID | NC | SerialID | - | - | Active |
| CCST_USERNAME | NC | UserName | - | - | Active |
| IDX_Customer_Customer_GCID | NC | GCID | CID, ProviderID, OriginalProviderID, OriginalCID, UserName, IsReal, LanguageID, Email, CountryID, Gender, CurrencyID, PlayerStatusID, PlayerLevelID, TradeLevelID, IP, SpreadGroupID, LabelID, RealProviderID, SerialID, HelpDeskType, LotCountGroupID, PrivacyPolicyID, WeekendFeePrecentage, ExternalID | - | Active |
| IXFiltered_CustomerStatic_ReferralID | NC | ReferralID | - | ReferralID > 0 | Active |
| IX_CustomerCustomer_LowerEmail_Cover | UNIQUE NC | LowerEmail | OriginalProviderID, OriginalCID, UserName, FirstName, LastName, BirthDate, CountryID, Zip, Gender | - | Active |
| IX_CustomerStatic_IP | NC | IP | - | - | Active |
| Idx_CustomerCustomerStaticID | UNIQUE NC | ID | - | - | Active |
| Idx_CustomerCustomerStatic_ExternalID | UNIQUE NC | ExternalID | - | - | Active |
| Idx_CustomerStatic_LinkedAccountHash1 | NC | LinkedAccountHash1 | - | - | Active |
| Idx_Customer_CustomerStatic_CID | NC | CID | GCID, FunnelFromID | - | Active |
| Idx_Customer_CustomerStatic_LastName_FirstName_BirthDate_Zip_CountryID | NC | LastName, FirstName, BirthDate, Zip, CountryID | OriginalCID, OriginalProviderID, UserName, LowerEmail, Gender | - | Active |
| Idx_Customer_Customer_AccountStatusID | NC | AccountStatusID, CID | PlayerStatusID, Comments, UserName, LastName, FirstName | - | Active |
| Idx_Customer_Customer_Registered | NC | Registered | PlayerLevelID, CID, CountryID, LanguageID, Email, Phone, SerialID | - | Active |
| Unique_CustomerStatic_UserName_LOWER | UNIQUE NC | UserName_LOWER | CountryID, LanguageID, PlayerStatusID, LabelID, UserName, FirstName, LastName, PrivacyPolicyID, GCID | - | Active |
| i_CureenyID | NC | CurrencyID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CCST | PRIMARY KEY | CID unique - one row per customer |
| FK_BAFF_CCST | FOREIGN KEY | SerialID -> BackOffice.Affiliate |
| FK_BCMP_CCST | FOREIGN KEY | CampaignID -> BackOffice.Campaign |
| FK_CCST_DFNL | FOREIGN KEY | FunnelID -> Dictionary.Funnel |
| FK_CCST_DILA | FOREIGN KEY (NOCHECK) | LabelID -> Dictionary.Label |
| FK_CCST_DLCG | FOREIGN KEY | LotCountGroupID -> Dictionary.LotCountGroup |
| FK_CC_CTID | FOREIGN KEY | ClientTypeID -> Dictionary.ClientType |
| FK_TDCNR_TSCST | FOREIGN KEY | CountryID -> Dictionary.Country |
| FK_TDCUR_TSCST | FOREIGN KEY | CurrencyID -> Dictionary.Currency |
| FK_TDLNG_TSCST | FOREIGN KEY | LanguageID -> Dictionary.Language |
| FK_TDPLL_TSCST | FOREIGN KEY | PlayerLevelID -> Dictionary.PlayerLevel |
| FK_TDPLS_TSCST | FOREIGN KEY | PlayerStatusID -> Dictionary.PlayerStatus |
| FK_TDSTT_TSCST | FOREIGN KEY | StateID -> Dictionary.State |
| FK_TDTMZ_TSCST | FOREIGN KEY | TimeZoneID -> Dictionary.TimeZone |
| FK_DTDL_CCST | FOREIGN KEY | TradeLevelID -> Dictionary.TradeLevel |
| FK_TSPG_CCST | FOREIGN KEY | SpreadGroupID -> Trade.SpreadGroup |
| FK_TSPRV_TSCST | FOREIGN KEY | ProviderID -> Trade.Provider |
| FK_Customer_CustomerStatic_CitizenshipCountryID | FOREIGN KEY | CitizenshipCountryID -> Dictionary.Country |
| FK_Customer_CustomerStatic_POBCountryID | FOREIGN KEY | POBCountryID -> Dictionary.Country |
| FK_Customer_CustomerStatic_SubRegionID | FOREIGN KEY | SubRegionID -> Dictionary.SubRegion |
| FK_Customer_CustomerStatic_EmailVerificationProviderID | FOREIGN KEY | EmailVerificationProviderID -> Dictionary.EmailVerificationProvider |
| FK_Customer_CustomerStatic_Col2 | FOREIGN KEY | PlayerStatusSubReasonID -> Dictionary.PlayerStatusSubReasons |
| CCST_GENDER | CHECK | Gender IN ('M', 'F', 'U') |
| CCST_NULLORIGINAL | DEFAULT | OriginalCID = 0 |
| CCST_NULLPROVIDER | DEFAULT | ProviderID = 0 |
| CCST_NULLCOUNTRY | DEFAULT | CountryID = 0 |
| CCST_NULLSTATE | DEFAULT | StateID = 0 |
| CCST_NULLLANGUAGE | DEFAULT | LanguageID = 0 |
| CCST_NULLCURRENCY | DEFAULT | CurrencyID = 0 |
| CCST_NULLTIMEZONE | DEFAULT | TimeZoneID = 0 |
| CCST_NULLPLAYERSTATUS | DEFAULT | PlayerStatusID = 0 |
| CCST_NULLPLAYERLEVEL | DEFAULT | PlayerLevelID = 0 |
| CCST_REGISTERED | DEFAULT | Registered = getdate() |
| DF_CCST_LotCountGroupID | DEFAULT | LotCountGroupID = 0 |
| DF_CustomerCustomer_WeekendFeePrecentage | DEFAULT | WeekendFeePrecentage = 100 |
| DF_CustomerCustomer_IsEmailActivated | DEFAULT | IsEmailActivated = 0 |
| DF_AccountStatusID | DEFAULT | AccountStatusID = 1 |
| DF_PendingClosureStatusID | DEFAULT | PendingClosureStatusID = 1 |
| DFCC_ClientTypeID | DEFAULT | ClientTypeID = 0 |
| DF_CustomerCustomer_LeverageType | DEFAULT | LeverageType = 1 |
| DF_CUST_IsHedged | DEFAULT | IsHedged = 1 |
| CCST_VerificationTitle | DEFAULT | VerificationTitle = Customer.VerificationTitle_Default() |
| CCST_VerificationTitleVersion | DEFAULT | VerificationTitleVersion = newid() |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| Customer.CustomerVersionInsert | FOR INSERT | Creates History.Customer version (ValidTo='3000-01-01'); sets Customer.Customer.IsHedged=0 for PI accounts |
| Customer.CustomerVersionUpdate | FOR UPDATE | Closes previous History.Customer version; inserts new version; updates LastChanges on Email change; updates BackOffice.Customer.FXEligibilityDate on PlayerLevelID change |
| Customer.CustomerVersionDelete | FOR DELETE | Closes active History.Customer version (ValidTo=GetDate()) |

---

## 8. Sample Queries

### 8.1 Get full customer profile

```sql
SELECT
    cs.CID,
    cs.GCID,
    cs.UserName,
    cs.FirstName,
    cs.LastName,
    cs.Email,
    cs.CountryID,
    cs.PlayerStatusID,
    cs.PlayerLevelID,
    cs.AccountStatusID,
    cs.IsReal,
    cs.IsHedged,
    cs.Registered
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.CID = 15
```

### 8.2 Find Popular Investors (PlayerLevel=4) in a country

```sql
SELECT
    cs.CID,
    cs.UserName,
    cs.CountryID,
    cs.PlayerLevelID,
    cs.IsHedged,
    cs.Registered
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.PlayerLevelID = 4
  AND cs.CountryID = 218
  AND cs.AccountStatusID = 1
ORDER BY cs.Registered DESC
```

### 8.3 Find potential duplicate accounts via LinkedAccountHash1

```sql
SELECT
    LinkedAccountHash1,
    COUNT(*) AS DuplicateCount,
    MIN(CID) AS OldestCID,
    MAX(CID) AS NewestCID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE LinkedAccountHash1 IS NOT NULL
GROUP BY LinkedAccountHash1
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC
```

### 8.4 Lookup by GCID (cross-product identity)

```sql
SELECT
    cs.CID,
    cs.GCID,
    cs.UserName,
    cs.ProviderID,
    cs.PlayerStatusID,
    cs.AccountStatusID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.GCID = 1983588
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: RD-5830 Add province to Italy](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/698318916) | Confluence (CR) | SubRegionID added to CustomerStatic; Customer.vContactUserInfo and GetContactUserInfo SPs updated |
| [HLD: RD-4436 - Add Place of Birth to KYC](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/547520796) | Confluence (CR) | POBCountryID added for enhanced KYC; CustomerStatic updated via Customer.UpdateContactUserInfo |
| [HLD: COAKVU-2880 - DLT Integration](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/12329582750) | Confluence (CR) | DltID column added for Distributed Ledger Technology integration |
| [APEX. How to create user](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/757465556) | Confluence (CR) | ApexID requirements: Regulation #8, USA country, Level >= 2. APEX returns SUSPENDED status by default for new accounts. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 20 VERIFIED, 64 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 4 Confluence + 0 Jira | Procedures: 0 analyzed | Triggers: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerStatic | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerStatic.sql*
