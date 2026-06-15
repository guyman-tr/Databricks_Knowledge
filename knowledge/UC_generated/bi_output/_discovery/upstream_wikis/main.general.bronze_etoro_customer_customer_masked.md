# Customer.Customer

> The unified customer view: joins CustomerStatic (identity, profile, settings) with CustomerMoney (balance fields) to present the complete customer record in a single queryable surface. The primary read interface for customer data across the platform.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID (from CustomerStatic) |
| **Partition** | N/A |
| **Indexes** | N/A (view - see base tables for indexes) |

---

## 1. Business Meaning

Customer.Customer is the main customer view used across the eToro platform. It joins Customer.CustomerStatic (CID, identity, profile, classification, trading config) with Customer.CustomerMoney (Credit, BonusCredit, RealizedEquity, TotalCash, BSLRealFunds) via a LEFT JOIN on CID, presenting both the customer's profile and financial position in a single SELECT. Any stored procedure, view, or application that needs "full customer record" queries this view rather than joining the two base tables directly.

The view serves as a stable API surface. When CustomerMoney is eventually replaced by the planned CustomerMoneyByCurrency + CustomerAccount split (see CustomerMoney doc), only this view's definition needs updating - all consumers remain unchanged. Similarly, as CustomerStatic gains new columns, they are added to this view to expose them system-wide.

WITH SCHEMABINDING is declared on this view. This means neither Customer.CustomerStatic nor Customer.CustomerMoney can have columns dropped or types changed while this view exists - the schema is locked. This is an important constraint for migrations: altering base tables requires first dropping, then recreating this view.

Two columns from CustomerStatic are intentionally omitted: `ApexID` and `LinkedAccountHash1` (the duplicate-detection MD5 hash). These are accessible directly from CustomerStatic for specific use cases. The remaining 81 CustomerStatic columns plus 5 CustomerMoney columns = 86 output columns.

---

## 2. Business Logic

### 2.1 LEFT JOIN Semantics - NULLable Financial Columns

**What**: The LEFT JOIN from CustomerStatic to CustomerMoney means a customer row can exist without a corresponding CustomerMoney row, resulting in NULL financial values.

**Columns/Parameters Involved**: `Credit`, `BonusCredit`, `RealizedEquity`, `TotalCash`, `BSLRealFunds`

**Rules**:
- If C2 (CustomerMoney) row does not exist for a CID: all 5 financial columns return NULL
- In practice, CustomerMoney has a row for every customer (it is always created at registration)
- Code using this view must handle NULL for Credit/BonusCredit/RealizedEquity/TotalCash/BSLRealFunds via ISNULL or IS NOT NULL guards

### 2.2 SCHEMABINDING Constraint

**What**: WITH SCHEMABINDING locks the schema of the two base tables referenced by this view.

**Columns/Parameters Involved**: All 86 referenced columns in CustomerStatic and CustomerMoney

**Rules**:
- Cannot DROP or ALTER the type of any column referenced in this view while the view exists
- Cannot DROP Customer.CustomerStatic or Customer.CustomerMoney while this view exists
- Migration procedure for base table changes: DROP view -> ALTER table -> RECREATE view
- Customer.CustomerSafty (built on this view) additionally inherits this constraint transitively

---

## 3. Data Overview

| CID | GCID | CountryID | PlayerStatusID | PlayerLevelID | IsReal | IsHedged | Credit | Registered | Meaning |
|-----|------|-----------|---------------|--------------|--------|----------|--------|------------|---------|
| 245 | 1983785 | 63 | 1 | 1 | true | 1 | 0 | 2007-09-11 | One of the earliest real accounts. Standard level-1 hedged customer; zero balance in this environment. |
| 246 | 1983786 | 63 | 1 | 1 | true | 1 | 0 | 2007-09-12 | Early sequential CID - first bulk of real accounts registered. |
| 11163446 | 14437312 | 12 | 1 | 1 | true | 1 | 0 | 1894-07-02 | Anomalous 1894 registration date - indicates test/system accounts with a dummy epoch date. These appear at the top of ORDER BY Registered ASC. |
| (typical) | (GCID) | (varies) | 1 | 1 | true | 1 | (nonzero) | (recent) | Standard active real customer: PlayerStatus=1 (Active), PlayerLevel=1 (Standard), IsHedged=1, with a Credit balance from deposits. |
| (PI customer) | (GCID) | (varies) | 1 | 4 | true | 0 | (nonzero) | (recent) | Popular Investor: PlayerLevel=4 triggers IsHedged=0 via the CustomerVersionInsert/Update trigger on CustomerStatic. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - platform-internal primary key. From CustomerStatic. Used as the universal customer identifier across all tables. |
| 2 | OriginalProviderID | int | NO | - | CODE-BACKED | Provider ID from which this account was originally migrated or registered. From CustomerStatic. Together with OriginalCID, forms the original identity key for migration tracing. |
| 3 | OriginalCID | int | NO | - | CODE-BACKED | Original customer ID from the source provider before any migration. From CustomerStatic. Default=0 for non-migrated accounts. |
| 4 | ProviderID | int | NO | - | VERIFIED | Current active provider/broker ID. From CustomerStatic. FK to Trade.Provider. Determines the trading provider for this customer. |
| 5 | RealProviderID | int | YES | - | CODE-BACKED | The underlying real provider ID when different from ProviderID. From CustomerStatic. Nullable. |
| 6 | CountryID | int | NO | - | VERIFIED | Country of residence. From CustomerStatic. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. |
| 7 | CountryIDByIP | int | NO | - | CODE-BACKED | Country detected from the customer's IP address at registration. From CustomerStatic. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). |
| 8 | CitizenshipCountryID | int | YES | - | VERIFIED | Country of citizenship (may differ from CountryID/residence). From CustomerStatic. FK to Dictionary.Country. Added 2018 (changelog: 50308) for enhanced KYC. |
| 9 | StateID | int | NO | - | VERIFIED | US state ID for US customers, or 0 for others. From CustomerStatic. FK to Dictionary.State. Required for certain regulatory and tax purposes. |
| 10 | LanguageID | int | NO | - | VERIFIED | Customer's preferred platform language. From CustomerStatic. FK to Dictionary.Language. Controls UI language. |
| 11 | CommunicationLanguageID | int | NO | - | CODE-BACKED | Language for customer communications (emails, notifications). From CustomerStatic. May differ from LanguageID. |
| 12 | CurrencyID | int | NO | - | VERIFIED | Customer's account base currency. From CustomerStatic. FK to Dictionary.Currency (1=USD). Currently all USD in practice; central to the multi-currency migration roadmap. |
| 13 | TimeZoneID | int | NO | - | VERIFIED | Customer's time zone. From CustomerStatic. FK to Dictionary.TimeZone. Used for time-aware notifications. |
| 14 | PlayerStatusID | int | NO | - | VERIFIED | Compliance and trading account status. From CustomerStatic. FK to Dictionary.PlayerStatus. 1=Active (97.5%); other values indicate restricted, closed, banned, or special states. |
| 15 | CampaignID | int | YES | - | VERIFIED | Marketing campaign ID under which the customer was acquired. From CustomerStatic. FK to BackOffice.Campaign. NULL for organically acquired customers. |
| 16 | PlayerLevelID | int | NO | - | VERIFIED | Customer experience/permission level. From CustomerStatic. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor (triggers IsHedged=0); 7=VIP. |
| 17 | TradeLevelID | int | NO | - | VERIFIED | Trading knowledge/experience classification. From CustomerStatic. FK to Dictionary.TradeLevel. Used for MiFID suitability assessment. |
| 18 | SpreadGroupID | int | NO | - | VERIFIED | Spread/pricing group. From CustomerStatic. FK to Trade.SpreadGroup. Determines which pricing table the customer uses. |
| 19 | LabelID | int | NO | - | VERIFIED | Internal segment label. From CustomerStatic. FK to Dictionary.Label. LabelID=26 = BonusOnly (triggers IsHedged=0). |
| 20 | FunnelID | int | YES | - | VERIFIED | Registration funnel ID. From CustomerStatic. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. |
| 21 | UserName | varchar(20) | NO | - | VERIFIED | Customer's login username. From CustomerStatic. Unique (case-insensitive). |
| 22 | Password | varchar(20) | NO | - | CODE-BACKED | Hashed password. From CustomerStatic. varchar(20) stores a hash. Password changes are NOT versioned in History.Customer. Use Customer.CustomerSafty instead when password field should be hidden. |
| 23 | Registered | datetime | NO | - | VERIFIED | Account registration date. From CustomerStatic. Default=getdate() at INSERT time. |
| 24 | IsReal | bit | NO | - | VERIFIED | Account type: 1=real-money account, 0=demo account. From CustomerStatic. |
| 25 | IP | varchar(15) | NO | - | VERIFIED | Registration IP address. From CustomerStatic. Dynamic Data Masking applied on the base table. |
| 26 | Credit | money | YES | - | VERIFIED | Customer's current available trading balance in USD. From CustomerMoney (LEFT JOIN). The core field updated by every financial transaction (deposit, withdrawal, position). NULL if no CustomerMoney row exists. See Customer.CustomerMoney for full balance write architecture. |
| 27 | BirthDate | datetime | YES | - | VERIFIED | Customer date of birth. From CustomerStatic. Dynamic Data Masking on base table. Used in KYC age verification and duplicate detection (LinkedAccountHash1). |
| 28 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', or 'U' (Unknown). From CustomerStatic. CHECK constraint on base table. Used in duplicate detection hash. |
| 29 | FirstName | nvarchar(50) | YES | - | VERIFIED | Legal first name in Unicode. From CustomerStatic. Dynamic Data Masking on base table. nvarchar supports non-Latin scripts. |
| 30 | LastName | nvarchar(50) | YES | - | VERIFIED | Legal last name in Unicode. From CustomerStatic. Dynamic Data Masking on base table. |
| 31 | MiddleName | nvarchar(50) | YES | - | VERIFIED | Middle name in Unicode. From CustomerStatic. Dynamic Data Masking on base table. Added 2018 (changelog: 50094). |
| 32 | Address | nvarchar(100) | YES | - | VERIFIED | Street address in Unicode. From CustomerStatic. Dynamic Data Masking on base table. |
| 33 | City | nvarchar(50) | YES | - | CODE-BACKED | City. From CustomerStatic. Not masked (unlike Address/Zip). |
| 34 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal code. From CustomerStatic. Dynamic Data Masking on base table. Used in duplicate detection hash. |
| 35 | SerialID | int | YES | - | VERIFIED | Affiliate (partner/introducing broker) ID. From CustomerStatic. FK to BackOffice.Affiliate. NULL for direct/organic registrations. |
| 36 | ReferralID | int | YES | - | CODE-BACKED | Referral CID - the customer who referred this one. From CustomerStatic. Used for RAF (Refer-a-Friend) program tracking. |
| 37 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-affiliate identifier string. From CustomerStatic. Up to 1024 chars for complex affiliate tracking paths. |
| 38 | Email | varchar(50) | YES | - | VERIFIED | Customer email address. From CustomerStatic. Dynamic Data Masking on base table. Unique (case-insensitive). |
| 39 | IsEmailVerified | bit | YES | - | CODE-BACKED | Whether the email was verified by clicking a confirmation link. From CustomerStatic. NULL for accounts predating this flag. |
| 40 | Phone | varchar(30) | YES | - | VERIFIED | Primary phone number. From CustomerStatic. Dynamic Data Masking on base table. |
| 41 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number. From CustomerStatic. Legacy field; rarely populated in modern registrations. |
| 42 | Mobile | varchar(30) | YES | - | VERIFIED | Mobile number. From CustomerStatic. Dynamic Data Masking on base table. |
| 43 | Comments | varchar(8000) | YES | - | CODE-BACKED | Internal comment field. From CustomerStatic. BackOffice operators can add notes. varchar(8000). |
| 44 | DownloadID | int | YES | - | CODE-BACKED | Platform download source ID. From CustomerStatic. Legacy tracking for which platform installer the customer used. |
| 45 | BannerID | int | YES | - | CODE-BACKED | Advertising banner ID that led to registration. From CustomerStatic. Legacy acquisition tracking. |
| 46 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client application version at registration. From CustomerStatic. |
| 47 | PersonID | varchar(50) | YES | - | CODE-BACKED | External person identifier. From CustomerStatic. |
| 48 | BonusCredit | money | YES | - | VERIFIED | Promotional/bonus credits separate from real funds. From CustomerMoney (LEFT JOIN). NULL if no CustomerMoney row. Tracked separately to distinguish promotional funds from deposited funds. |
| 49 | DownloadCounter | int | YES | - | CODE-BACKED | Number of times the customer has downloaded the platform client. From CustomerStatic. |
| 50 | AccountExpirationDate | datetime | YES | - | CODE-BACKED | Expiration date for demo or time-limited accounts. From CustomerStatic. NULL for standard real-money accounts. |
| 51 | HelpDeskType | smallint | YES | - | CODE-BACKED | Customer service tier assignment. From CustomerStatic. |
| 52 | LotCountGroupID | int | NO | - | VERIFIED | Lot/quantity group. From CustomerStatic. FK to Dictionary.LotCountGroup. Controls min/max lot sizes for trading. |
| 53 | PrivacyPolicyID | int | YES | - | VERIFIED | Privacy policy version accepted by the customer. From CustomerStatic. FK to Dictionary.PrivacyPolicy. |
| 54 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key linking same person across eToro products. From CustomerStatic. NULL for accounts predating GCID introduction. |
| 55 | WeekendFeePrecentage | tinyint | YES | - | CODE-BACKED | Weekend swap fee percentage (100=full fee, <100=discounted). From CustomerStatic. Note: column name has typo "Precentage". |
| 56 | IsEmailActivated | tinyint | YES | - | CODE-BACKED | Email activation status flag. From CustomerStatic. Separate from IsEmailVerified - tracks account email activation step completion. |
| 57 | UserName_LOWER | computed | YES | - | CODE-BACKED | Computed: lower(UserName). From CustomerStatic. Used for case-insensitive username uniqueness enforcement. |
| 58 | RealizedEquity | money | YES | - | VERIFIED | Running total of realized account value (deposits + closed-position proceeds - withdrawals). From CustomerMoney (LEFT JOIN). NULL if no CustomerMoney row. Answers: "How much realized value does this customer have?" |
| 59 | AccountStatusID | tinyint | YES | - | VERIFIED | Account operational status. From CustomerStatic. 1=Active/Normal (93.9%); 2=Closed/Restricted; NULL=pre-AccountStatusID era. |
| 60 | PendingClosureStatusID | tinyint | YES | - | CODE-BACKED | Status in the pending account closure workflow. From CustomerStatic. Default=1 (no pending closure). |
| 61 | IsRequestedCall | bit | YES | - | CODE-BACKED | Whether the customer has requested a callback from sales/support. From CustomerStatic. |
| 62 | FunnelFromID | int | YES | - | CODE-BACKED | Source funnel variant tracking within the acquisition funnel. From CustomerStatic. |
| 63 | LeverageType | int | YES | - | CODE-BACKED | Leverage setting type (default=1). From CustomerStatic. Determines the leverage scheme applied to this account. |
| 64 | TotalCash | money | YES | - | VERIFIED | Reconciled total cash balance maintained by the Trade.UpdateTotalCash reconciliation job. From CustomerMoney (LEFT JOIN). NULL if no CustomerMoney row. |
| 65 | ClientTypeID | tinyint | YES | - | VERIFIED | Client classification type for MiFID2 categorization (retail, professional, etc.). From CustomerStatic. FK to Dictionary.ClientType. |
| 66 | IsHedged | tinyint | NO | - | CODE-BACKED | Whether this customer's trades are hedged on the broker side. From CustomerStatic. Managed by CustomerVersionInsert/Update triggers: 0 (not hedged) for Popular Investors (PlayerLevelID=4) or BonusOnly (LabelID=26) or CEP/BonusOnlyCustomers list members; 1 (hedged) for all others. |
| 67 | LowerEmail | computed | YES | - | CODE-BACKED | Computed: lower(Email). From CustomerStatic. Used for case-insensitive email uniqueness enforcement. |
| 68 | ID | uniqueidentifier | NO | - | VERIFIED | System GUID for REST API identity. From CustomerStatic. Default=newsequentialid(). Unique index on base table. |
| 69 | VerificationTitle | nvarchar(50) | NO | - | CODE-BACKED | KYC verification title/level text. From CustomerStatic. Default from Customer.VerificationTitle_Default() function. Changes are versioned in History.Customer. |
| 70 | VerificationTitleVersion | uniqueidentifier | NO | - | CODE-BACKED | Version GUID for optimistic concurrency on verification title updates. From CustomerStatic. Default=newid(). |
| 71 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building/apartment number. From CustomerStatic. Dynamic Data Masking on base table. Structured address field added 2015 (changelog: 02/08/2015). |
| 72 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | International dialing prefix (e.g., +1, +44). From CustomerStatic. Added 2015 (changelog: 27/10/2015). |
| 73 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Local phone number without country prefix. From CustomerStatic. Dynamic Data Masking on base table. Added 2015 (changelog: 27/10/2015). |
| 74 | ExternalID | decimal(38,0) | YES | - | VERIFIED | APEX broker external ID. From CustomerStatic. Unique index on base table. Decimal(38,0) accommodates APEX's large numeric ID format. |
| 75 | RegionID | int | YES | - | CODE-BACKED | Geographic region ID (GeoIP-derived or set). From CustomerStatic. Added 2016 (changelog: 40722) alongside CountryIDByIP for granular regulation. |
| 76 | RegionByIP_ID | int | YES | - | CODE-BACKED | Region detected from IP address. From CustomerStatic. Added 2016 (changelog: 40722). Separate from RegionID (profile-based) for mismatch detection. |
| 77 | PlatformID | int | YES | - | CODE-BACKED | Platform/product identifier (web, mobile, etc.). From CustomerStatic. Added 2016 (changelog: 40618). |
| 78 | BSLRealFunds | money | YES | - | VERIFIED | Real funds threshold for Balance Stop Loss (BSL) - safety floor that triggers position liquidation if equity drops below this level. From CustomerMoney (LEFT JOIN). NULL if no CustomerMoney row. Updated by PostMIMOOperations pipeline. |
| 79 | OptOutReasonID | smallint | YES | - | CODE-BACKED | Reason for GDPR/marketing opt-out. From CustomerStatic. Added 2017 (changelog: 18-07-2017). |
| 80 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | Reason code for current PlayerStatusID ("why" behind a non-Active status). From CustomerStatic. Added 2017 (changelog: 24/07/2017). |
| 81 | PlayerStatusSubReasonID | int | YES | - | VERIFIED | Sub-reason code for PlayerStatus (hierarchical). From CustomerStatic. FK to Dictionary.PlayerStatusSubReasons. Added 2019 (changelog: RD-1752). |
| 82 | PlayerStatusSubReasonComment | varchar(64) | YES | - | CODE-BACKED | Free-text comment for the PlayerStatusSubReasonID. From CustomerStatic. Max 64 chars. Added 2019. |
| 83 | POBCountryID | int | YES | - | VERIFIED | Place of birth country. From CustomerStatic. FK to Dictionary.Country. Added 2019 (HLD: RD-4436 Add Place of Birth to KYC). |
| 84 | SubRegionID | int | YES | - | VERIFIED | Sub-region (province/state for non-US countries). From CustomerStatic. FK to Dictionary.SubRegion. Added 2019 (changelog: 09/07/2019). |
| 85 | EmailVerificationProviderID | int | YES | - | VERIFIED | External email verification provider used for this customer's email. From CustomerStatic. FK to Dictionary.EmailVerificationProvider. Added 2020. |
| 86 | DltID | uniqueidentifier | YES | - | VERIFIED | Distributed Ledger Technology integration ID. From CustomerStatic. Added per HLD: COAKVU-2880 DLT Integration. Links customer to DLT/blockchain system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerStatic | FROM (base table) | 81 of 86 columns sourced from CustomerStatic (C1) |
| - | Customer.CustomerMoney | LEFT JOIN on CID | 5 financial columns (Credit, BonusCredit, RealizedEquity, TotalCash, BSLRealFunds) from CustomerMoney (C2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerSafty | - | View (built on this) | Security-safe variant: replaces Password with '', drops 8 columns |
| Customer.GetUserCredit | CID, Credit | View (built on this) | Extracts Credit*100 as UserCredit for game/credit integration |
| Customer.GetDemography | - | View (built on this) | Demographic slice used for reporting |
| Customer.GetDemoCustomersShortVersionForMail | GCID, FirstName, Email, LanguageID, LabelID | View (built on this) | Email marketing data slice for demo customers |
| Customer.GetRealCustomersShortVersionForMail | GCID, CID, FirstName, Email, LanguageID, LabelID | View (built on this) | Email marketing data slice for real customers |
| Customer.GetRealCustomersShort_Copierts24H | - | View (built on this) | Active copiers in last 24h for email campaigns |
| Customer.GetRealCustomersShort_Copierts7Days | - | View (built on this) | Active copiers in last 7 days |
| Customer.GetRealCustomersShort_FB | - | View (built on this) | Facebook-connected customers slice |
| Customer.GetRealCustomersShort_FB_Connection | - | View (built on this) | Customers with active FB social connection |
| Customer.GetRealCustomersShort_OpenPosition | - | View (built on this) | Customers with open positions slice |
| Customer.GetRealCustomers_FeedUnlock | - | View (built on this) | Real customers eligible for feed unlock |
| Customer.GetCustomerListForStrongMail | - | View (built on this) | Email list export for StrongMail email platform |
| Customer.Get_LastLoginDateToCashier | - | View (built on this) | Last cashier login date slice |
| Customer.GetOTPAbusers | GCID, Credit | Reader (SP) | Reads RealizedEquity=0 for OTP abuse detection filter |
| (many more stored procedures) | CID, GCID, and others | Reader | Hundreds of SPs query this view for customer data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Customer (view)
├── Customer.CustomerStatic (table)
└── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FROM (base table, alias C1) - 81 columns |
| Customer.CustomerMoney | Table | LEFT JOIN on C1.CID=C2.CID - 5 financial columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerSafty | View | Built on top of Customer.Customer; password-masked variant |
| Customer.GetUserCredit | View | Built on top; extracts Credit as cents |
| Customer.GetDemography | View | Built on top; demographic reporting slice |
| Customer.GetDemoCustomersShortVersionForMail | View | Built on top; email marketing for demo customers |
| Customer.GetRealCustomersShortVersionForMail | View | Built on top; email marketing for real customers |
| (10+ additional views) | View | Various narrow projections for specific use cases |
| (hundreds of stored procedures) | Stored Procedure | Primary customer data read surface |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. See Customer.CustomerStatic (16 indexes) and Customer.CustomerMoney (1 clustered PK) for base table indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH SCHEMABINDING | Schema lock | Prevents DROP/ALTER of any referenced column in CustomerStatic or CustomerMoney while this view exists. Base table DDL changes require DROP view -> ALTER table -> RECREATE view. |

---

## 8. Sample Queries

### 8.1 Get full customer record by CID
```sql
SELECT *
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Find active real customers with positive balance in a specific country
```sql
SELECT
    c.CID,
    c.GCID,
    c.UserName,
    c.CountryID,
    c.PlayerLevelID,
    c.Credit,
    c.RealizedEquity,
    c.IsHedged,
    c.Registered
FROM Customer.Customer c WITH (NOLOCK)
WHERE c.IsReal = 1
  AND c.PlayerStatusID = 1
  AND c.CountryID = 101
  AND c.Credit > 0
ORDER BY c.Credit DESC;
```

### 8.3 Popular Investors (PlayerLevel=4) with their hedge status
```sql
SELECT
    c.CID,
    c.GCID,
    c.UserName,
    c.PlayerLevelID,
    c.IsHedged,
    c.LabelID,
    c.Credit,
    c.BSLRealFunds
FROM Customer.Customer c WITH (NOLOCK)
WHERE c.PlayerLevelID = 4
  AND c.PlayerStatusID = 1
ORDER BY c.Credit DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9.8/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 25 VERIFIED, 61 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.Customer | Type: View | Source: etoro/etoro/Customer/Views/Customer.Customer.sql*
