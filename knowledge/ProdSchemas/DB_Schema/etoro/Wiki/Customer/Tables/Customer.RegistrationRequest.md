# Customer.RegistrationRequest

> Registration snapshot table that captures the full profile data submitted at account creation time; primarily used for IB (Introducing Broker) customer registrations, storing the exact configuration snapshot before the live account is created in CustomerStatic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | RegistrationRequestID (uniqueidentifier, PK) |
| **Partition** | No (MAIN filegroup, FILLFACTOR=90) |
| **Indexes** | 13 (clustered PK + 12 NC on each FK/key column) |

---

## 1. Business Meaning

Customer.RegistrationRequest stores a complete snapshot of the customer configuration data at the moment of registration. Each row captures exactly what was submitted during the registration form: personal details (name, birth date, address, gender), contact information (email, phone, mobile), trading configuration (provider, country, currency, time zone, trade level, player level), acquisition data (serial/affiliate ID, funnel, referral, banner), and the client application used.

The table serves as the registration audit log - it preserves the exact state of each customer's submitted registration data. Unlike CustomerStatic (which evolves as the customer changes settings), RegistrationRequest is effectively immutable after registration (only UpdateRegistrationRequest can modify it, and only to update OriginalProviderID/OriginalCID for provider migration scenarios).

The primary write path (Customer.RegisterIB) is the Introducing Broker registration flow: before inserting, RegisterIB validates that the @ProviderID has IsIB=1 in Trade.Provider. This confirms RegistrationRequest is specifically the staging and audit table for IB-mediated customer registrations, where an Introducing Broker (external partner) brings customers to eToro. The 0-row count on this environment indicates this is a non-production instance without IB registration activity.

---

## 2. Business Logic

### 2.1 IB Provider Validation Gate

**What**: Registrations through this table are restricted to Introducing Broker providers - ProviderID must have IsIB=1 in Trade.Provider.

**Columns/Parameters Involved**: `ProviderID`, `OriginalProviderID`

**Rules**:
- Customer.RegisterIB validates: EXISTS (SELECT * FROM Trade.Provider WHERE ProviderID = @ProviderID AND IsIB = 1)
- If validation fails: RAISERROR(60017) - registration is rejected
- OriginalProviderID + OriginalCID: set at creation via RegisterIB; can be updated later by Customer.UpdateRegistrationRequest if the customer's IB provider changes
- OriginalProviderID default = 0 (CRGR_NULLORIGINAL) - temporary value until real provider assignment
- OriginalCID default = 0 (CRGR_NULLORIGINAL) - temporary; updated to the real CID after account creation

### 2.2 Registration Identity: GUID-Based Request ID

**What**: RegistrationRequestID is a pre-generated GUID passed by the calling application, not a server-side IDENTITY, enabling the client to correlate the registration request with subsequent operations.

**Columns/Parameters Involved**: `RegistrationRequestID`

**Rules**:
- UNIQUEIDENTIFIER PK - caller provides the GUID before calling RegisterIB
- This allows the application to track the registration request independently of whether the insert succeeded
- Customer.UpdateRegistrationRequest uses the same GUID to update provider details post-registration
- No DEFAULT constraint on RegistrationRequestID - the GUID must always be supplied by the caller

---

## 3. Data Overview

*0 rows in this environment. This environment has no IB customer registrations. A production environment would have one row per IB-registered customer, with data patterns similar to Customer.CustomerStatic (same column set, same lookup value ranges).*

*Representative row example based on schema:*

| Column | Example Value | Meaning |
|--------|--------------|---------|
| RegistrationRequestID | GUID | Application-assigned request identifier |
| ProviderID | 101 | The IB broker's ProviderID (Trade.Provider, IsIB=1) |
| CountryID | 37 | UK customer |
| CurrencyID | 2 | EUR account currency |
| LanguageID | 2 | English |
| Registered | 2024-06-15 | Date of IB registration |
| SerialID | 5001 | Affiliate/IB partner ID |
| Gender | M / F | Gender via CHECK constraint (CRGR_GENDER) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationRequestID | uniqueidentifier | NO | - | VERIFIED | Application-generated GUID uniquely identifying this registration request. Clustered PK. Passed by the calling application, enabling pre-correlation of the request with post-registration operations. |
| 2 | OriginalProviderID | int | NO | 0 | VERIFIED | The IB provider's original provider ID. Updated by Customer.UpdateRegistrationRequest if provider assignment changes. Default=0 until real value is set. References Trade.Provider. |
| 3 | OriginalCID | int | NO | 0 | VERIFIED | The customer's original CID (before any account migration/re-assignment). Default=0 at creation; updated to the real CID via UpdateRegistrationRequest. Indexed (CRGR_ORIGINAL) for lookups by original customer identity. |
| 4 | ProviderID | int | NO | - | VERIFIED | The IB (Introducing Broker) provider through which this customer registered. FK to Trade.Provider. Validated to have IsIB=1 before registration proceeds. Indexed (CRGR_PROVIDER). |
| 5 | CountryID | int | NO | - | VERIFIED | Customer's country at registration time. FK to Dictionary.Country. Indexed (CRGR_COUNTRY). |
| 6 | StateID | int | NO | 0 | VERIFIED | Customer's state/region at registration time. FK to Dictionary.State. Default=0 (no state). Indexed (CRGR_STATE). |
| 7 | LanguageID | int | NO | - | VERIFIED | Customer's preferred language at registration. FK to Dictionary.Language. Indexed (CRGR_LANGUAGE). |
| 8 | CurrencyID | int | NO | - | VERIFIED | Customer's account currency chosen at registration. FK to Dictionary.Currency. Indexed (CRGR_CURRENCY). |
| 9 | TimeZoneID | int | NO | 0 | VERIFIED | Customer's time zone at registration. FK to Dictionary.TimeZone. Default=0. Indexed (CRGR_TIMEZONE). |
| 10 | PlayerStatusID | int | NO | 0 | VERIFIED | Customer's player status at registration time. FK to Dictionary.PlayerStatus. Default=0. Indexed (CRGR_PLAYERSTATUS). |
| 11 | PlayerLevelID | int | NO | 0 | VERIFIED | Customer's player level at registration time. FK to Dictionary.PlayerLevel. Default=0 (overridable by @PlayerLevelID parameter in RegisterIB, default=1). Indexed (CRGR_PLAYERLEVEL). |
| 12 | TradeLevelID | int | NO | - | VERIFIED | Customer's trade level assigned at registration. FK to Dictionary.TradeLevel. Indexed (CRGR_TRADELEVEL). |
| 13 | LabelID | int | NO | - | VERIFIED | Affiliate/partner label ID assigned at registration. FK to Dictionary.Label (WITH NOCHECK - constraint not validated on creation). Indexed (CRGR_LABEL). |
| 14 | FunnelID | int | YES | - | VERIFIED | Marketing funnel through which this customer arrived. FK to Dictionary.Funnel. NULL if not tracked. Indexed (CRGR_FUNNEL). |
| 15 | Registered | datetime | NO | getdate() | VERIFIED | Timestamp of the registration event. Defaults to getdate(). |
| 16 | IP | varchar(15) | NO | - | CODE-BACKED | IPv4 address of the customer at registration time. Always required (NOT NULL). |
| 17 | BirthDate | datetime | YES | - | CODE-BACKED | Customer's date of birth. NULL if not provided. Computed in RegisterIB from @BirthYear, @BirthMonth, @BirthDay parameters. |
| 18 | Gender | char(1) | YES | - | VERIFIED | Customer's gender. CHECK constraint (CRGR_GENDER): value must be 'M' or 'F'. NULL if not provided. |
| 19 | FirstName | nvarchar(50) | YES | - | CODE-BACKED | Customer's first name at registration. NULL if not provided. NVarchar for Unicode support (international names). |
| 20 | LastName | nvarchar(50) | YES | - | CODE-BACKED | Customer's last name at registration. NULL if not provided. |
| 21 | PersonID | varchar(50) | YES | - | CODE-BACKED | National identity document number. NULL if not provided. |
| 22 | Address | nvarchar(100) | YES | - | CODE-BACKED | Customer's street address at registration. NULL if not provided. |
| 23 | City | nvarchar(50) | YES | - | CODE-BACKED | Customer's city at registration. NULL if not provided. |
| 24 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal code at registration. NULL if not provided. |
| 25 | SerialID | int | YES | - | CODE-BACKED | Affiliate/IB partner serial identifier. NULL if not an affiliate acquisition. Maps to the IB's serial number in the referral system. |
| 26 | ReferralID | int | YES | - | CODE-BACKED | CID of the customer who referred this person (RAF program). NULL if not a referral. |
| 27 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code (up to 1024 chars). Used for deep affiliate tracking within the IB's network. NULL if not provided. |
| 28 | Email | varchar(50) | YES | - | CODE-BACKED | Customer's email address at registration. NULL if not provided. |
| 29 | Phone | varchar(30) | YES | - | CODE-BACKED | Customer's phone number at registration. NULL if not provided. |
| 30 | Fax | varchar(30) | YES | - | CODE-BACKED | Customer's fax number. NULL if not provided. Legacy field - fax is rarely used in modern registrations. |
| 31 | Mobile | varchar(30) | YES | - | CODE-BACKED | Customer's mobile phone at registration. NULL if not provided. |
| 32 | DownloadID | int | YES | - | CODE-BACKED | Identifier of the download event that led to registration. NULL if not from a download flow. |
| 33 | BannerID | int | YES | - | CODE-BACKED | Marketing banner identifier that drove this registration. NULL if not banner-driven. |
| 34 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Version of the client application used for registration. NULL if not captured. |
| 35 | DownloadCounter | int | YES | - | CODE-BACKED | Count of downloads associated with this registration event. NULL if not applicable. |
| 36 | ClientTypeID | tinyint | YES | 0 | VERIFIED | Platform type used for registration. FK to Dictionary.ClientType. Default=0 (Unknown). Values: 0=Unknown, 1=Desktop, 2=WebTrader, 3=Android, 4=iPhone, 5=OpenBook, 6=OpenBook Mobile, 7=CopyMe. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LabelID | Dictionary.Label | FK (FK_CRRQ_DILA, WITH NOCHECK) | Affiliate/partner label at registration |
| ClientTypeID | Dictionary.ClientType | FK (FK_CRR_CTID) | Platform type used for registration |
| CountryID | Dictionary.Country | FK (FK_DCNR_CRGR) | Customer's country |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_CRGR) | Account currency chosen at registration |
| FunnelID | Dictionary.Funnel | FK (FK_DFNL_CRGR) | Marketing funnel |
| LanguageID | Dictionary.Language | FK (FK_DLNG_CRGR) | Preferred language |
| PlayerLevelID | Dictionary.PlayerLevel | FK (FK_DPLL_CRGR) | Player level at registration |
| PlayerStatusID | Dictionary.PlayerStatus | FK (FK_DPLS_CRGR) | Player status at registration |
| StateID | Dictionary.State | FK (FK_DSTT_CRGR) | State/region |
| TradeLevelID | Dictionary.TradeLevel | FK (FK_DTDL_CRGR) | Trade level |
| TimeZoneID | Dictionary.TimeZone | FK (FK_DTMZ_CRGR) | Time zone |
| ProviderID | Trade.Provider | FK (FK_TPRV_CRGR) | IB provider (must have IsIB=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RegisterIB | All columns | Writer | Inserts IB registration snapshots after provider validation |
| Customer.UpdateRegistrationRequest | OriginalProviderID, OriginalCID | Modifier | Updates provider assignment post-registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RegistrationRequest (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Label | Table | FK for LabelID |
| Dictionary.ClientType | Table | FK for ClientTypeID |
| Dictionary.Country | Table | FK for CountryID |
| Dictionary.Currency | Table | FK for CurrencyID |
| Dictionary.Funnel | Table | FK for FunnelID |
| Dictionary.Language | Table | FK for LanguageID |
| Dictionary.PlayerLevel | Table | FK for PlayerLevelID |
| Dictionary.PlayerStatus | Table | FK for PlayerStatusID |
| Dictionary.State | Table | FK for StateID |
| Dictionary.TradeLevel | Table | FK for TradeLevelID |
| Dictionary.TimeZone | Table | FK for TimeZoneID |
| Trade.Provider | Table | FK for ProviderID (must have IsIB=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RegisterIB | Stored Procedure | Writer - IB customer registration |
| Customer.UpdateRegistrationRequest | Stored Procedure | Modifier - provider re-assignment |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CRGR | Clustered PK | RegistrationRequestID ASC | - | - | Active |
| CRGR_COUNTRY | NC | CountryID ASC | - | - | Active |
| CRGR_CURRENCY | NC | CurrencyID ASC | - | - | Active |
| CRGR_FUNNEL | NC | FunnelID ASC | - | - | Active |
| CRGR_LABEL | NC | LabelID ASC | - | - | Active |
| CRGR_LANGUAGE | NC | LanguageID ASC | - | - | Active |
| CRGR_ORIGINAL | NC | OriginalCID ASC | - | - | Active |
| CRGR_PLAYERLEVEL | NC | PlayerLevelID ASC | - | - | Active |
| CRGR_PLAYERSTATUS | NC | PlayerStatusID ASC | - | - | Active |
| CRGR_PROVIDER | NC | ProviderID ASC | - | - | Active |
| CRGR_STATE | NC | StateID ASC | - | - | Active |
| CRGR_TIMEZONE | NC | TimeZoneID ASC | - | - | Active |
| CRGR_TRADELEVEL | NC | TradeLevelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CRGR_NULLORIGINAL | DEFAULT | OriginalCID = 0 (temporary until updated) |
| CRGR_NULLSTATE | DEFAULT | StateID = 0 |
| CRGR_NULLTIMEZONE | DEFAULT | TimeZoneID = 0 |
| CRGR_NULLPLAYERSTATUS | DEFAULT | PlayerStatusID = 0 |
| CRGR_NULLPLAYERLEVEL | DEFAULT | PlayerLevelID = 0 |
| CRGR_REGISTERED | DEFAULT | Registered = getdate() |
| DFCR_ClientTypeID | DEFAULT | ClientTypeID = 0 |
| CRGR_GENDER | CHECK | Gender IN ('M', 'F') |
| FK_CRRQ_DILA | FK (NOCHECK) | LabelID -> Dictionary.Label |
| FK_CRR_CTID | FK | ClientTypeID -> Dictionary.ClientType |
| FK_DCNR_CRGR | FK | CountryID -> Dictionary.Country |
| FK_DCUR_CRGR | FK | CurrencyID -> Dictionary.Currency |
| FK_DFNL_CRGR | FK | FunnelID -> Dictionary.Funnel |
| FK_DLNG_CRGR | FK | LanguageID -> Dictionary.Language |
| FK_DPLL_CRGR | FK | PlayerLevelID -> Dictionary.PlayerLevel |
| FK_DPLS_CRGR | FK | PlayerStatusID -> Dictionary.PlayerStatus |
| FK_DSTT_CRGR | FK | StateID -> Dictionary.State |
| FK_DTDL_CRGR | FK | TradeLevelID -> Dictionary.TradeLevel |
| FK_DTMZ_CRGR | FK | TimeZoneID -> Dictionary.TimeZone |
| FK_TPRV_CRGR | FK | ProviderID -> Trade.Provider |

---

## 8. Sample Queries

### 8.1 Get all IB registrations for a specific provider
```sql
SELECT
    rr.RegistrationRequestID,
    rr.OriginalCID,
    rr.ProviderID,
    rr.CountryID,
    rr.CurrencyID,
    rr.Email,
    rr.Registered,
    rr.SerialID,
    rr.ClientTypeID
FROM Customer.RegistrationRequest rr WITH (NOLOCK)
WHERE rr.ProviderID = 101
ORDER BY rr.Registered DESC;
```

### 8.2 Registration distribution by country and currency
```sql
SELECT
    c.CountryName,
    cur.CurrencyCode,
    COUNT(*) AS Registrations,
    MIN(rr.Registered) AS FirstReg,
    MAX(rr.Registered) AS LastReg
FROM Customer.RegistrationRequest rr WITH (NOLOCK)
INNER JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = rr.CountryID
INNER JOIN Dictionary.Currency cur WITH (NOLOCK) ON cur.CurrencyID = rr.CurrencyID
GROUP BY c.CountryName, cur.CurrencyCode
ORDER BY Registrations DESC;
```

### 8.3 Find registration record by GUID and resolve all lookup values
```sql
SELECT
    rr.RegistrationRequestID,
    rr.OriginalCID,
    p.ProviderName,
    c.CountryName,
    cur.CurrencyCode,
    l.LanguageName,
    pl.PlayerLevelName,
    tl.TradeLevelName,
    lbl.LabelName,
    rr.Email,
    rr.Registered,
    rr.SerialID
FROM Customer.RegistrationRequest rr WITH (NOLOCK)
INNER JOIN Trade.Provider p WITH (NOLOCK) ON p.ProviderID = rr.ProviderID
INNER JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = rr.CountryID
INNER JOIN Dictionary.Currency cur WITH (NOLOCK) ON cur.CurrencyID = rr.CurrencyID
INNER JOIN Dictionary.Language l WITH (NOLOCK) ON l.LanguageID = rr.LanguageID
INNER JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = rr.PlayerLevelID
INNER JOIN Dictionary.TradeLevel tl WITH (NOLOCK) ON tl.TradeLevelID = rr.TradeLevelID
INNER JOIN Dictionary.Label lbl WITH (NOLOCK) ON lbl.LabelID = rr.LabelID
WHERE rr.RegistrationRequestID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (RegisterIB, UpdateRegistrationRequest) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RegistrationRequest | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RegistrationRequest.sql*
