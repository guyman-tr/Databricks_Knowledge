# Customer.RegisterIB

> Creates a pending Introducing Broker (IB) registration request: validates the provider is IB-enabled, normalizes input strings, converts birth date fields, validates label ID, and inserts a row into Customer.RegistrationRequest for downstream processing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RegistrationRequestID UNIQUEIDENTIFIER - identifies the pending IB registration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RegisterIB` handles the first step of Introducing Broker registration. Unlike `Customer.RegisterDemo` and `Customer.RegisterReal` which create full customer accounts immediately, `RegisterIB` creates only a pending registration request in `Customer.RegistrationRequest`. This record represents a broker application that requires further processing or approval before an active customer account is provisioned.

"IB" (Introducing Broker) accounts belong to partners who introduce clients to eToro. The procedure enforces that the `@ProviderID` is flagged as IB-enabled (`Trade.Provider.IsIB = 1`) - attempting to register an IB account under a non-IB provider fails with error 60017.

All string inputs are normalized via `Internal.NormalizeString` (handles unicode normalization/trimming) before storage. The birth date is constructed from separate year/month/day parameters rather than a single datetime, allowing partial birth dates.

---

## 2. Business Logic

### 2.1 IB Provider Validation

**What**: Enforces that the registration provider is configured for Introducing Broker accounts.

**Rules**:
- IF NOT EXISTS (SELECT * FROM Trade.Provider WHERE ProviderID = @ProviderID AND IsIB = 1): RAISERROR(60017) + RETURN 60017.
- Error 60017 is the "not an IB provider" error code.

### 2.2 Input Normalization

**What**: All string fields are normalized before INSERT.

**Rules**:
- `Internal.NormalizeString` applied to: Email, FirstName, LastName, Phone, Mobile, Fax, Address, City, State, Zip, IP, SubSerialID, ClientVersion, PersonID.
- Prevents unicode normalization inconsistencies and trailing space issues in the stored data.

### 2.3 Birth Date Construction

**What**: Converts year/month/day integers to a DATETIME.

**Rules**:
- If @BirthYear IS NOT NULL: DATEADD(YEAR, @BirthYear - 1900, 0) + DATEADD(MONTH, @BirthMonth) + DATEADD(DAY, @BirthDay).
- If @BirthYear IS NULL: @BirthDate = NULL.

### 2.4 Label ID Validation

**What**: Ensures a valid LabelID is used; defaults to 9 if the provided ID doesn't exist.

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Dictionary.Label WHERE LabelID = @LabelID): SET @LabelID = 9.
- LabelID 9 is the default/fallback marketing label.

### 2.5 Registration Request Insert

**What**: Stores the pending IB registration in Customer.RegistrationRequest.

**Rules**:
- INSERT Customer.RegistrationRequest with PlayerStatusID=1 (active), @Occurred=GETDATE().
- Gender stored as: 0->NULL, 1->'M', else->'F'.
- StateID resolved from Dictionary.State WHERE UPPER(Name) = UPPER(@State) AND CountryID = @CountryID.

```
Validate Trade.Provider IsIB=1
Normalize all string inputs
Build @BirthDate from year/month/day
Validate @LabelID (default to 9)
Resolve @StateID from Dictionary.State
BEGIN TX:
  INSERT Customer.RegistrationRequest
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationRequestID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Primary key of the new registration request row in Customer.RegistrationRequest. |
| 2 | @OriginalProviderID | INTEGER | NO | - | CODE-BACKED | Original provider reference. |
| 3 | @OriginalCID | INTEGER | NO | - | CODE-BACKED | Original CID if this IB was previously registered; 0 for new. |
| 4 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Trading provider ID; must have IsIB=1 in Trade.Provider or registration fails (error 60017). |
| 5 | @CountryID | INTEGER | NO | - | CODE-BACKED | IB's country. Used with @State to resolve StateID. |
| 6 | @State | VARCHAR(50) | NO | - | CODE-BACKED | State/province text; resolved to StateID via Dictionary.State. |
| 7 | @LanguageID | INTEGER | NO | - | CODE-BACKED | IB's preferred language. |
| 8 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Account base currency. |
| 9 | @TimeZoneID | INTEGER | NO | - | CODE-BACKED | Time zone for the IB account. |
| 10 | @TradeLevelID | INTEGER | NO | - | CODE-BACKED | Trading level assignment. |
| 11 | @LabelID | INTEGER | NO | - | CODE-BACKED | Marketing label; defaults to 9 if the provided ID does not exist in Dictionary.Label. |
| 12 | @FunnelID | INTEGER | NO | - | CODE-BACKED | Registration funnel. |
| 13 | @IP | VARCHAR(15) | NO | - | CODE-BACKED | Registration IP address; normalized. |
| 14 | @BirthYear | INTEGER | NO | - | CODE-BACKED | Birth year; combined with Month/Day to form @BirthDate. NULL for unknown. |
| 15 | @BirthMonth | INTEGER | NO | - | CODE-BACKED | Birth month (1-12). |
| 16 | @BirthDay | INTEGER | NO | - | CODE-BACKED | Birth day (1-31). |
| 17 | @Gender | INTEGER | NO | - | CODE-BACKED | Gender: 0=NULL, 1='M', other='F'. |
| 18 | @FirstName | NVARCHAR(50) | NO | - | CODE-BACKED | First name; normalized. |
| 19 | @LastName | NVARCHAR(50) | NO | - | CODE-BACKED | Last name; normalized. |
| 20 | @PersonID | VARCHAR(50) | NO | - | CODE-BACKED | Government ID/passport number; normalized. |
| 21 | @Address | NVARCHAR(100) | NO | - | CODE-BACKED | Street address; normalized. |
| 22 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | City; normalized. |
| 23 | @Zip | NVARCHAR(50) | NO | - | CODE-BACKED | Postal/zip code; normalized. |
| 24 | @SerialID | INTEGER | NO | - | CODE-BACKED | Affiliate/serial ID. |
| 25 | @ReferralID | INTEGER | NO | - | CODE-BACKED | Referring customer's CID. |
| 26 | @SubSerialID | VARCHAR(1024) | NO | - | CODE-BACKED | Sub-affiliate tracking string; normalized. |
| 27 | @Email | VARCHAR(50) | NO | - | CODE-BACKED | Email address; normalized. |
| 28 | @Phone | VARCHAR(30) | NO | - | CODE-BACKED | Phone number; normalized. |
| 29 | @Mobile | VARCHAR(30) | NO | - | CODE-BACKED | Mobile number; normalized. |
| 30 | @Fax | VARCHAR(30) | NO | - | CODE-BACKED | Fax number; normalized. |
| 31 | @DownloadID | INTEGER | NO | - | CODE-BACKED | Download tracking ID. |
| 32 | @BannerID | INTEGER | NO | - | CODE-BACKED | Marketing banner. |
| 33 | @ClientVersion | VARCHAR(20) | NO | - | CODE-BACKED | Client version at registration; normalized. |
| 34 | @DownloadCounter | INTEGER | NO | - | CODE-BACKED | Download attempt count. |
| 35 | @ClientTypeID | TINYINT | YES | 0 | CODE-BACKED | Client type classification. |
| 36 | @PlayerLevelID | INTEGER | YES | 1 | CODE-BACKED | Initial player tier; 1=Bronze (default). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID | Trade.Provider | READ (guard) | Validates IsIB=1 before proceeding |
| @LabelID | Dictionary.Label | READ (guard) | Validates label exists; defaults to 9 |
| @State/@CountryID | Dictionary.State | READ | Resolves StateID for the registration request |
| (output) | Customer.RegistrationRequest | INSERT | Stores the pending IB registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| IB registration API | External | Caller | Called by the IB onboarding flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RegisterIB (procedure)
├── Trade.Provider (table) [READ - IsIB=1 validation]
├── Dictionary.Label (table) [READ - LabelID validation]
├── Dictionary.State (table) [READ - StateID resolution]
├── Internal.NormalizeString (function) [CALL - string normalization]
└── Customer.RegistrationRequest (table) [INSERT - pending IB registration]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | READ - validate IsIB=1 |
| Dictionary.Label | Table | READ - validate @LabelID; default to 9 |
| Dictionary.State | Table | READ - resolve StateID from name + country |
| Internal.NormalizeString | Function | CALL - normalize all string parameters |
| Customer.RegistrationRequest | Table | INSERT - pending IB registration record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| IB registration workflow | External | Calls to create pending IB request |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsIB guard | Application | Trade.Provider.IsIB=1 required; error 60017 if not |
| Default LabelID | Application | LabelID defaults to 9 if provided value not in Dictionary.Label |
| PlayerStatusID hardcoded | Application | INSERT with PlayerStatusID=1 always |
| String normalization | Application | All string inputs normalized before storage |

---

## 8. Sample Queries

### 8.1 Check pending IB registration requests

```sql
SELECT TOP 20
    rr.RegistrationRequestID,
    rr.Email,
    rr.FirstName,
    rr.LastName,
    rr.CountryID,
    rr.Registered
FROM Customer.RegistrationRequest rr WITH (NOLOCK)
ORDER BY rr.Registered DESC
```

### 8.2 Verify IB-enabled providers

```sql
SELECT
    ProviderID,
    Name,
    IsIB
FROM Trade.Provider WITH (NOLOCK)
WHERE IsIB = 1
ORDER BY ProviderID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 36 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RegisterIB | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RegisterIB.sql*
