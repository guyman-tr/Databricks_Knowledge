# Customer.IsCustomerFund

> Full customer profile view with a fund-account flag: joins CustomerStatic, CustomerMoney, and BackOffice.Customer to add an IsFund column indicating whether the account is a managed fund (BackOffice.Customer.AccountTypeID=9).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID (from CustomerStatic) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsCustomerFund enriches the standard customer record (CustomerStatic + CustomerMoney) with fund account detection from BackOffice.Customer. The key addition is the computed `IsFund` column: `IIF(BC.AccountTypeID <> 9, 0, 1)` - which returns 1 when the BackOffice account type is 9 (managed fund/copy fund) and 0 for all other account types.

Unlike Customer.Customer (which uses a LEFT JOIN to CustomerMoney), this view uses INNER JOINs to both CustomerMoney and BackOffice.Customer. This means only customers who have rows in all three tables are returned - customers without a BackOffice.Customer row are excluded. In practice, all real customers should have BackOffice rows.

The changelog explains the business context: "Change the way that we check if the user is fund. Instead of checking in Trade.Fund table, we now check in BackOffice.Customer" (Adi, FB 45530, 13/06/2017). This view replaced an earlier mechanism that checked the Trade.Fund table for fund account identification.

The view does NOT filter to only fund accounts - it returns all customers (with IsFund=0 for non-funds). Consumers must apply WHERE IsFund=1 to get only fund accounts. BackOffice.Customer has a filtered index `NonClusteredIndex-AccountType WHERE AccountTypeID=9` optimized for fund lookups.

---

## 2. Business Logic

### 2.1 Fund Account Detection via AccountTypeID

**What**: The IsFund computed column identifies managed fund accounts using BackOffice.Customer.AccountTypeID.

**Columns/Parameters Involved**: `IsFund`, `AccountTypeID` (from BackOffice.Customer)

**Rules**:
- AccountTypeID=9 -> IsFund=1 (this is a managed/copy fund account)
- AccountTypeID<>9 -> IsFund=0 (standard customer account; default AccountTypeID=1)
- Prior mechanism (pre-June 2017): checked Trade.Fund table instead
- BackOffice.Customer has a filtered NC index (WHERE AccountTypeID=9) for efficient fund account lookup

### 2.2 INNER JOIN vs LEFT JOIN

**What**: This view uses INNER JOINs to all three base tables, unlike Customer.Customer which uses LEFT JOIN to CustomerMoney.

**Columns/Parameters Involved**: All columns

**Rules**:
- Customers without a CustomerMoney row are EXCLUDED (would be included in Customer.Customer)
- Customers without a BackOffice.Customer row are EXCLUDED
- In practice all production customers should have both rows
- Effect: Credit, BonusCredit, RealizedEquity, TotalCash, BSLRealFunds are NOT nullable (INNER JOIN guarantees they exist)

---

## 3. Data Overview

N/A - this view combines three large tables and returns all customers. Sample rows would be similar to Customer.Customer plus the IsFund flag (typically 0 for non-fund customers).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From CustomerStatic. Primary key identifier. |
| 2 | OriginalProviderID | int | NO | - | CODE-BACKED | Original provider ID for migration tracing. From CustomerStatic. |
| 3 | OriginalCID | int | NO | - | CODE-BACKED | Original CID before migration. From CustomerStatic. |
| 4 | ProviderID | int | NO | - | VERIFIED | Current trading provider ID. From CustomerStatic. FK to Trade.Provider. |
| 5 | RealProviderID | int | YES | - | CODE-BACKED | Underlying real provider ID. From CustomerStatic. |
| 6 | CountryID | int | NO | - | VERIFIED | Country of residence. From CustomerStatic. FK to Dictionary.Country. |
| 7 | CountryIDByIP | int | NO | - | CODE-BACKED | Country from IP address. From CustomerStatic. |
| 8 | StateID | int | NO | - | VERIFIED | US state ID (or 0). From CustomerStatic. FK to Dictionary.State. |
| 9 | LanguageID | int | NO | - | VERIFIED | Platform language preference. From CustomerStatic. FK to Dictionary.Language. |
| 10 | CommunicationLanguageID | int | NO | - | CODE-BACKED | Communication language. From CustomerStatic. |
| 11 | CurrencyID | int | NO | - | VERIFIED | Account base currency. From CustomerStatic. FK to Dictionary.Currency. |
| 12 | TimeZoneID | int | NO | - | VERIFIED | Customer time zone. From CustomerStatic. FK to Dictionary.TimeZone. |
| 13 | PlayerStatusID | int | NO | - | VERIFIED | Compliance status. From CustomerStatic. FK to Dictionary.PlayerStatus. |
| 14 | CampaignID | int | YES | - | VERIFIED | Marketing campaign acquisition ID. From CustomerStatic. |
| 15 | PlayerLevelID | int | NO | - | VERIFIED | Customer tier. From CustomerStatic. FK to Dictionary.PlayerLevel. |
| 16 | TradeLevelID | int | NO | - | VERIFIED | Trading knowledge level. From CustomerStatic. |
| 17 | SpreadGroupID | int | NO | - | VERIFIED | Spread/pricing group. From CustomerStatic. |
| 18 | LabelID | int | NO | - | VERIFIED | Internal segment label. From CustomerStatic. |
| 19 | FunnelID | int | YES | - | VERIFIED | Acquisition funnel. From CustomerStatic. |
| 20 | UserName | varchar(20) | NO | - | VERIFIED | Login username. From CustomerStatic. |
| 21 | Password | varchar(20) | NO | - | CODE-BACKED | Hashed password. From CustomerStatic. Note: exposed directly - use Customer.CustomerSafty if password should be hidden. |
| 22 | Registered | datetime | NO | - | VERIFIED | Registration date. From CustomerStatic. |
| 23 | IsReal | bit | NO | - | VERIFIED | Real (1) or demo (0) account. From CustomerStatic. |
| 24 | IP | varchar(15) | NO | - | VERIFIED | Registration IP (Dynamic Data Masking on base table). From CustomerStatic. |
| 25 | BirthDate | datetime | YES | - | VERIFIED | Date of birth (Dynamic Data Masking). From CustomerStatic. |
| 26 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', 'U'. From CustomerStatic. |
| 27 | FirstName | nvarchar(50) | YES | - | VERIFIED | First name (Dynamic Data Masking). From CustomerStatic. |
| 28 | LastName | nvarchar(50) | YES | - | VERIFIED | Last name (Dynamic Data Masking). From CustomerStatic. |
| 29 | Address | nvarchar(100) | YES | - | VERIFIED | Street address (Dynamic Data Masking). From CustomerStatic. |
| 30 | City | nvarchar(50) | YES | - | CODE-BACKED | City. From CustomerStatic. |
| 31 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal code (Dynamic Data Masking). From CustomerStatic. |
| 32 | SerialID | int | YES | - | VERIFIED | Affiliate/IB ID. From CustomerStatic. |
| 33 | ReferralID | int | YES | - | CODE-BACKED | Referral CID. From CustomerStatic. |
| 34 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-affiliate string. From CustomerStatic. |
| 35 | Email | varchar(50) | YES | - | VERIFIED | Email address (Dynamic Data Masking). From CustomerStatic. |
| 36 | IsEmailVerified | bit | YES | - | CODE-BACKED | Email verified flag. From CustomerStatic. |
| 37 | Phone | varchar(30) | YES | - | VERIFIED | Phone (Dynamic Data Masking). From CustomerStatic. |
| 38 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number. From CustomerStatic. |
| 39 | Mobile | varchar(30) | YES | - | VERIFIED | Mobile (Dynamic Data Masking). From CustomerStatic. |
| 40 | Comments | varchar(8000) | YES | - | CODE-BACKED | BackOffice operator notes. From CustomerStatic. |
| 41 | DownloadID | int | YES | - | CODE-BACKED | Download source ID. From CustomerStatic. |
| 42 | BannerID | int | YES | - | CODE-BACKED | Banner acquisition ID. From CustomerStatic. |
| 43 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client version at registration. From CustomerStatic. |
| 44 | PersonID | varchar(50) | YES | - | CODE-BACKED | External person ID. From CustomerStatic. |
| 45 | DownloadCounter | int | YES | - | CODE-BACKED | Download count. From CustomerStatic. |
| 46 | AccountExpirationDate | datetime | YES | - | CODE-BACKED | Demo account expiry. From CustomerStatic. |
| 47 | HelpDeskType | smallint | YES | - | CODE-BACKED | Support tier. From CustomerStatic. |
| 48 | LotCountGroupID | int | NO | - | VERIFIED | Lot/quantity group. From CustomerStatic. |
| 49 | PrivacyPolicyID | int | YES | - | VERIFIED | Privacy policy version accepted. From CustomerStatic. |
| 50 | GCID | int | YES | - | VERIFIED | Group Customer ID. From CustomerStatic via CS.GCID. |
| 51 | WeekendFeePrecentage | tinyint | YES | - | CODE-BACKED | Weekend fee %. From CustomerStatic. |
| 52 | IsEmailActivated | tinyint | YES | - | CODE-BACKED | Email activation status. From CustomerStatic. |
| 53 | UserName_LOWER | computed | YES | - | CODE-BACKED | lower(UserName). From CustomerStatic. |
| 54 | AccountStatusID | tinyint | YES | - | VERIFIED | Account operational status. From CustomerStatic. |
| 55 | PendingClosureStatusID | tinyint | YES | - | CODE-BACKED | Pending closure status. From CustomerStatic. |
| 56 | ClientTypeID | tinyint | YES | - | VERIFIED | Client type (MiFID2). From CustomerStatic. |
| 57 | IsRequestedCall | bit | YES | - | CODE-BACKED | Callback requested flag. From CustomerStatic. |
| 58 | LeverageType | int | YES | - | CODE-BACKED | Leverage scheme type. From CustomerStatic. |
| 59 | FunnelFromID | int | YES | - | CODE-BACKED | Acquisition funnel source. From CustomerStatic. |
| 60 | IsHedged | tinyint | NO | - | CODE-BACKED | Hedge status (0=PI/BonusOnly, 1=standard). From CustomerStatic. |
| 61 | LowerEmail | computed | YES | - | CODE-BACKED | lower(Email). From CustomerStatic. |
| 62 | ID | uniqueidentifier | NO | - | VERIFIED | System GUID for REST API. From CustomerStatic. |
| 63 | VerificationTitle | nvarchar(50) | NO | - | CODE-BACKED | KYC verification title. From CustomerStatic. |
| 64 | VerificationTitleVersion | uniqueidentifier | NO | - | CODE-BACKED | Verification title version GUID. From CustomerStatic. |
| 65 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | International dialing prefix. From CustomerStatic. |
| 66 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Local phone body. From CustomerStatic. |
| 67 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building number. From CustomerStatic. |
| 68 | ExternalID | decimal(38,0) | YES | - | VERIFIED | APEX broker external ID. From CustomerStatic. |
| 69 | RegionID | int | YES | - | CODE-BACKED | Geographic region ID. From CustomerStatic. |
| 70 | RegionByIP_ID | int | YES | - | CODE-BACKED | Region from IP address. From CustomerStatic. |
| 71 | PlatformID | int | YES | - | CODE-BACKED | Platform/product ID. From CustomerStatic. |
| 72 | Credit | money | NO | - | VERIFIED | Available trading balance. From CustomerMoney (INNER JOIN - guaranteed non-NULL). |
| 73 | BonusCredit | money | NO | - | VERIFIED | Promotional bonus credit. From CustomerMoney (INNER JOIN). |
| 74 | RealizedEquity | money | NO | - | VERIFIED | Cumulative realized account value. From CustomerMoney (INNER JOIN). |
| 75 | TotalCash | money | NO | - | VERIFIED | Reconciled total cash. From CustomerMoney (INNER JOIN). |
| 76 | BSLRealFunds | money | NO | - | VERIFIED | Balance Stop Loss real funds threshold. From CustomerMoney (INNER JOIN). |
| 77 | IsFund | int | NO | - | VERIFIED | Computed: IIF(BC.AccountTypeID <> 9, 0, 1). 1=managed fund account (AccountTypeID=9), 0=standard customer. Derived from BackOffice.Customer.AccountTypeID. Prior to June 2017, fund status was checked via the Trade.Fund table (FB 45530). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerStatic | FROM (base table, alias CS) | Customer identity and profile |
| - | Customer.CustomerMoney | INNER JOIN on CID (alias CM) | Balance fields |
| IsFund | BackOffice.Customer | INNER JOIN on CID (alias BC) | AccountTypeID=9 fund detection |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsCustomerFund (view)
├── Customer.CustomerStatic (table)
├── Customer.CustomerMoney (table)
└── BackOffice.Customer (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FROM (base, alias CS) - all profile columns |
| Customer.CustomerMoney | Table | INNER JOIN on CID - balance columns |
| BackOffice.Customer | Table | INNER JOIN on CID - AccountTypeID for IsFund flag |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Get all fund accounts
```sql
SELECT CID, GCID, UserName, Credit, RealizedEquity
FROM Customer.IsCustomerFund WITH (NOLOCK)
WHERE IsFund = 1
ORDER BY Credit DESC;
```

### 8.2 Count customers by fund status
```sql
SELECT IsFund, COUNT(*) AS CustomerCount
FROM Customer.IsCustomerFund WITH (NOLOCK)
GROUP BY IsFund;
```

### 8.3 Compare fund vs non-fund balance distributions
```sql
SELECT
    IsFund,
    COUNT(*) AS Customers,
    AVG(Credit) AS AvgCredit,
    SUM(Credit) AS TotalCredit
FROM Customer.IsCustomerFund WITH (NOLOCK)
GROUP BY IsFund;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.7/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 22 VERIFIED, 55 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsCustomerFund | Type: View | Source: etoro/etoro/Customer/Views/Customer.IsCustomerFund.sql*
