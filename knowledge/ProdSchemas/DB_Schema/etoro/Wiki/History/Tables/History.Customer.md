# History.Customer

> Slowly Changing Dimension Type 2 (SCD2) versioned history of every customer profile change, storing a complete snapshot of Customer.CustomerStatic for every modification with ValidFrom/ValidTo timestamps to enable point-in-time profile reconstruction.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 (1 CLUSTERED PK + 2 NC B-Tree + 1 NC COLUMNSTORE) |

---

## 1. Business Meaning

This table stores every historical version of a customer's profile data. When any field in `Customer.CustomerStatic` changes - a status update, country change, language preference, player level promotion - the prior state of the entire row is preserved here as a version with a time window (ValidFrom to ValidTo). The current version of a customer has ValidTo = '3000-01-01' (sentinel for "still current"). All previous versions have ValidTo set to the timestamp when the next version superseded them.

Per Confluence (Space: TR, Page: "History.Customer", April 2021): "History.Customer is a table that contains data of different versions of eToro's customers. Each customer can have more than one version, depending on different dates and changes of their data. Instead of deleting old data, it is stored as a version of the customer in this table."

The table enables compliance, audit, and BI use cases: reconstructing what a customer's profile looked like at a specific point in time (e.g., "what was this customer's regulation at the time of their deposit?"), analyzing when customers changed their status, and feeding the DWH with historical customer dimension data (confirmed by the COLUMNSTORE index on ValidFrom, ValidTo, CID, PlayerLevelID, LabelID for `DWH.V_CustomerCustomerHourly`).

With 49.3M rows spanning 2015-11-29 to present (ValidTo = '3000-01-01' for current rows), and multiple versions per customer from millisecond-level updates, this is one of the highest-volume audit tables in the History schema. The table uses PAGE compression and a COLUMNSTORE covering index for DWH reporting efficiency. PII columns have dynamic data masking (MASKED WITH FUNCTION = 'default()') applied.

---

## 2. Business Logic

### 2.1 SCD Type 2 Versioning Pattern

**What**: Each customer can have multiple rows, each representing their profile during a distinct time window.

**Columns/Parameters Involved**: `CID`, `CustomerVersionID`, `ValidFrom`, `ValidTo`

**Rules**:
- Current row: `ValidTo = '3000-01-01 00:00:00'` - sentinel value meaning "this version is still active"
- Historical row: `ValidTo` = the ValidFrom of the next version for the same CID
- For any CID, `ValidTo` of one version equals `ValidFrom` of the next, creating a gapless timeline
- To get the current state of a customer: `WHERE CID = @CID AND ValidTo = '3000-01-01'`
- To get state at a point in time T: `WHERE CID = @CID AND ValidFrom <= T AND ValidTo > T`
- The (CID, CustomerVersionID DESC) index efficiently retrieves the most recent version

**Diagram**:
```
CID=25483109 version history (top 5 rows from live data):
  v51748415: ValidFrom=05:33:39 -> ValidTo=05:33:40 (superseded ~0.66s later)
  v51748416: ValidFrom=05:33:40 -> ValidTo=05:33:40 (superseded ~0.27s later)
  v51748417: ValidFrom=05:33:40 -> ValidTo=05:33:40 (superseded ~0.18s later)
  v51748418: ValidFrom=05:33:40 -> ValidTo=05:33:46 (superseded ~5.6s later)
  v51748419: ValidFrom=05:33:46 -> ValidTo=3000-01-01 (CURRENT)
```

### 2.2 Dynamic Data Masking for PII Protection

**What**: Sensitive personal data columns are masked for non-privileged database users.

**Columns/Parameters Involved**: `UserName`, `BirthDate`, `FirstName`, `LastName`, `Address`, `Zip`, `Email`, `Phone`, `Mobile`, `PhoneBody`, `MiddleName`

**Rules**:
- All PII columns use `MASKED WITH (FUNCTION = 'default()')` - returns blank strings for varchar/nvarchar, null for datetime
- Users with the `UNMASK` permission or `db_owner` role see real data
- Read-only analytics users and reporting connections see masked values
- PII masking mirrors the same pattern applied to `Customer.CustomerStatic`

### 2.3 Trace Audit Column

**What**: Automatically records the SQL session context at the time each row is inserted.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- The DEFAULT constraint generates a JSON blob: `{"HostName": "...", "AppName": "...", "SUserName": "...", "OriginalLogin": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}`
- This identifies which application, server, and stored procedure caused the history insert
- Provides forensic traceability for every customer version entry without requiring explicit logging in calling code

---

## 3. Data Overview

| CustomerVersionID | CID | ValidFrom | ValidTo | PlayerStatusID | IsReal | AccountStatusID |
|---|---|---|---|---|---|---|
| 51748419 | 25483109 | 2026-03-19 05:33:46 | 3000-01-01 (CURRENT) | 1 (Normal) | true | 1 (Open) | Current version - normal active real-money account; multiple rapid updates suggest automated system activity (e.g., login event triggering profile stamp) |
| 51748418 | 25483109 | 2026-03-19 05:33:40 | 2026-03-19 05:33:46 | 1 (Normal) | true | 1 (Open) | Superseded 5.6 seconds after creation - intermediate version from rapid sequential customer data changes |
| 51748417 | 25483109 | 2026-03-19 05:33:40 | 2026-03-19 05:33:40 | 1 (Normal) | true | 1 (Open) | Superseded 180ms after creation - sub-second versioning indicates concurrent update activity |
| 51748416 | 25483109 | 2026-03-19 05:33:40 | 2026-03-19 05:33:40 | 1 (Normal) | true | 1 (Open) | Superseded 267ms after creation - part of the same rapid-update burst |
| 51748415 | 25483109 | 2026-03-19 05:33:39 | 2026-03-19 05:33:40 | 1 (Normal) | true | 1 (Open) | Earliest in the burst - initial version that kicked off the rapid succession of updates |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK for this version record. CLUSTERED PK with PAGE compression. NOT FOR REPLICATION prevents identity gaps during replication. Monotonically increasing - higher = newer version. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | UTC timestamp when this version became the active profile state. Equals the update timestamp in Customer.CustomerStatic that triggered the history insert. Covered by COLUMNSTORE index for DWH temporal queries. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | UTC timestamp when this version was superseded by the next. Sentinel value '3000-01-01' indicates the current (still-active) version. Indexed via IX_HistoryCustomer_ValidToCID for efficient "get current" and range queries. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID - the eToro account identifier. Same as Customer.CustomerStatic.CID. Multiple rows with the same CID represent that customer's version history. Indexed via IX_HistoryCustomer_ValidToCID (ValidTo, CID) and Idx_HistoryCustomer_CID_CustomerVersionID (CID, CustomerVersionID DESC). |
| 5 | ProviderID | int | NO | - | NAME-INFERRED | Platform/white-label provider ID for this customer's account. Inherited from Customer.CustomerStatic. Identifies which eToro entity or white-label partner the account belongs to. |
| 6 | CountryID | int | NO | - | NAME-INFERRED | Country of residence at this version point. Changes may occur due to customer address updates or regulatory migration. References Dictionary.Country. |
| 7 | StateID | int | NO | - | NAME-INFERRED | State/province within the country. References Dictionary.State or similar. |
| 8 | LanguageID | int | NO | - | CODE-BACKED | UI language preference at this version point. References Dictionary.Language. See [Language](_glossary.md#language). Historically listed in glossary Used By for Customer.CustomerStatic - same semantics apply here. |
| 9 | CommunicationLanguageID | int | NO | - | CODE-BACKED | Language used for emails and notifications, which may differ from the UI language. References Dictionary.Language. See [Language](_glossary.md#language). |
| 10 | CurrencyID | int | NO | - | NAME-INFERRED | Account denomination currency at this version point. Changes to account currency are tracked as a new version. References Dictionary.Currency. |
| 11 | TimeZoneID | int | NO | - | NAME-INFERRED | Customer's configured timezone preference. References Dictionary.TimeZone or similar. |
| 12 | PlayerStatusID | int | NO | - | CODE-BACKED | Account compliance/trading restriction state at this version. One of the most frequently changing fields - status changes (block, unblock, restrict) generate a new version. See [Player Status](_glossary.md#player-status). Values: 1=Normal, 2=Blocked, etc. |
| 13 | CampaignID | int | YES | - | NAME-INFERRED | Marketing campaign attribution at acquisition time. Usually set once at registration and unchanged. NULL for organically acquired customers. |
| 14 | PlayerLevelID | int | NO | - | CODE-BACKED | Customer's trading experience/privilege level at this version. Covered by COLUMNSTORE index (PlayerLevelID) - frequently used in DWH queries to analyse customer segment distribution over time. |
| 15 | TradeLevelID | int | NO | - | NAME-INFERRED | Trading tier level classification. Determines fee structures and trading limits applicable at this version. |
| 16 | SpreadGroupID | int | NO | - | NAME-INFERRED | Spread group assignment at this version point. Controls bid/ask spread applied to the customer's trades. References Trade.SpreadGroup or similar. |
| 17 | LabelID | int | NO | - | CODE-BACKED | Customer label/tag classification. Covered by COLUMNSTORE index - used in DWH segment analysis over time. References Dictionary.Label or BackOffice.Label. |
| 18 | UserName | varchar(20) | NO | - | CODE-BACKED | eToro username. MASKED WITH (FUNCTION = 'default()') - PII. Username rarely changes but a change generates a new version. |
| 19 | Password | varchar(20) | NO | - | NAME-INFERRED | Hashed password at this version point. Password changes generate a new version entry (historical password audit). NOT masked in DDL but is a hashed value, not plaintext. |
| 20 | IsReal | bit | NO | - | CODE-BACKED | Whether this is a real-money account (1) or a demo/paper-trading account (0). Live data shows all recent rows = 1 (real). Demo accounts have CIDs typically beginning with 3 or 4 (negative or high range). |
| 21 | BirthDate | datetime | YES | - | CODE-BACKED | Customer date of birth. MASKED WITH (FUNCTION = 'default()'). Required for KYC age verification. Rarely changes; version created if corrected. |
| 22 | Gender | char(1) | YES | - | NAME-INFERRED | M/F/NULL gender. Nullable - many customers do not provide gender. |
| 23 | FirstName | nvarchar(50) | YES | - | CODE-BACKED | Customer's first name. MASKED WITH (FUNCTION = 'default()'). PII. Changes when customer updates their profile details. |
| 24 | LastName | nvarchar(50) | YES | - | CODE-BACKED | Customer's last name. MASKED WITH (FUNCTION = 'default()'). PII. |
| 25 | Address | nvarchar(100) | YES | - | CODE-BACKED | Street address line. MASKED WITH (FUNCTION = 'default()'). PII. Address changes (e.g., on KYC document submission) create new versions. |
| 26 | City | nvarchar(50) | YES | - | NAME-INFERRED | City of residence. Not masked (city is lower-sensitivity PII). |
| 27 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal/ZIP code. MASKED WITH (FUNCTION = 'default()'). PII. |
| 28 | Email | varchar(50) | YES | - | CODE-BACKED | Customer email address. MASKED WITH (FUNCTION = 'default()'). Email changes trigger a new version and historically required re-verification. |
| 29 | IsEmailVerified | bit | YES | - | NAME-INFERRED | Whether the email was verified at this version. 1 = verified; 0 or NULL = unverified. Changes as customer completes email verification. |
| 30 | Phone | varchar(30) | YES | - | CODE-BACKED | Primary phone number. MASKED WITH (FUNCTION = 'default()'). PII. |
| 31 | Fax | varchar(30) | YES | - | NAME-INFERRED | Fax number (legacy field). Rarely populated in modern accounts. |
| 32 | Mobile | varchar(30) | YES | - | CODE-BACKED | Mobile phone number. MASKED WITH (FUNCTION = 'default()'). PII. Used for 2FA and SMS notifications. |
| 33 | Comments | varchar(8000) | YES | - | NAME-INFERRED | Internal notes or comments on the customer. Free-text field. Large field (8000 chars), stored in TEXTIMAGE_ON HISTORY filegroup. |
| 34 | SerialID | int | NO | - | NAME-INFERRED | Sequential serial number for the customer account. Legacy field from early eToro platform. |
| 35 | AccountExpirationDate | datetime | YES | - | NAME-INFERRED | Date when the account is scheduled to expire. NULL for permanent accounts. Used for demo accounts with time-limited access. |
| 36 | HelpDeskType | smallint | YES | - | NAME-INFERRED | Customer support routing classification. Determines which support queue or agent group handles this customer. |
| 37 | LotCountGroupID | int | NO | 0 | CODE-BACKED | Lot size group assignment. DEFAULT = 0. Controls minimum lot/unit sizes for trading. |
| 38 | PrivacyPolicyID | int | YES | - | NAME-INFERRED | Version of the eToro Privacy Policy the customer accepted at this version point. Updates when customer accepts a new policy version. |
| 39 | GCID | int | YES | - | NAME-INFERRED | Global Customer ID - the household/person-level identifier linking all accounts belonging to the same real-world person. May be NULL for old accounts pre-GCID system. |
| 40 | WeekendFeePrecentage | tinyint | YES | 100 | CODE-BACKED | Weekend/overnight fee percentage applied to this customer's open positions. DEFAULT = 100 (full standard fee). Reduced for VIP customers or specific promotions. Note: "Precentage" is a legacy typo in the column name. |
| 41 | IsEmailActivated | tinyint | YES | - | NAME-INFERRED | Whether the customer's account email was activated (email link clicked after registration). 1 = activated; 0 = not activated; NULL = legacy. |
| 42 | AccountStatusID | tinyint | YES | - | CODE-BACKED | Open/closed state of the account. See [Account Status](_glossary.md#account-status). Values: 1 = Open (active), 2 = Closed. NULL for legacy accounts pre-AccountStatusID addition. |
| 43 | PendingClosureStatusID | tinyint | YES | - | NAME-INFERRED | Sub-state when account is in process of being closed. NULL for normally active accounts. Set when a closure request is submitted and the account is in the closure workflow. |
| 44 | PhonePrefix | nvarchar(6) | YES | - | NAME-INFERRED | International dialling prefix (e.g., "+1", "+44"). Stored separately from PhoneBody for standardized international number handling. |
| 45 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Phone number without the prefix. MASKED WITH (FUNCTION = 'default()'). PII. Used for SMS/voice communications. |
| 46 | RegionID | int | YES | - | CODE-BACKED | Geographic region by customer's declared residence. See [Region](_glossary.md#region). Used for marketing segmentation and default currency assignment. |
| 47 | RegionByIP_ID | int | YES | - | NAME-INFERRED | Geographic region detected from the customer's IP address at registration. May differ from RegionID (declared vs detected). Used for fraud and compliance geo-risk analysis. |
| 48 | OptOutReasonID | smallint | YES | - | NAME-INFERRED | Reason the customer opted out of marketing communications. NULL if not opted out. References a lookup table for opt-out reasons. |
| 49 | MiddleName | nvarchar(50) | YES | - | CODE-BACKED | Customer's middle name. MASKED WITH (FUNCTION = 'default()'). PII. Optional field - NULL for customers without a middle name or who didn't provide it. |
| 50 | CitizenshipCountryID | int | YES | - | NAME-INFERRED | Country of citizenship (may differ from CountryID which is country of residence). Required for some regulatory KYC processes. References Dictionary.Country. |
| 51 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | Reason code for the current PlayerStatus. Used when PlayerStatus is non-Normal (e.g., reason for blocking). See [Player Status](_glossary.md#player-status). |
| 52 | Trace | varchar(max) | YES | JSON blob | CODE-BACKED | Session audit JSON automatically generated by the DEFAULT constraint on each INSERT. Contains: HostName, AppName, SUserName, OriginalLogin, SPID, DBName, ObjectName. Identifies the source application and stored procedure that triggered this version creation. |
| 53 | SubRegionID | int | YES | - | NAME-INFERRED | Sub-region within the customer's region (e.g., state-level granularity beyond StateID). Used for fine-grained geographic marketing segmentation. |
| 54 | EmailVerificationProviderID | int | YES | - | NAME-INFERRED | Service used to verify the customer's email address (e.g., internal, SendGrid, third-party). NULL for accounts pre-email-verification-provider tracking. |
| 55 | PlayerStatusSubReasonID | int | YES | - | CODE-BACKED | Hierarchical sub-reason code under PlayerStatusReasonID. Provides additional granularity for compliance and operations when setting or reviewing account restrictions. See [Player Status](_glossary.md#player-status). |
| 56 | BuildingNumber | nvarchar(30) | YES | - | NAME-INFERRED | Building/apartment number as a separate address component. Supports structured address formats for certain regulatory jurisdictions where this must be explicitly captured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The source table - each row is a historical snapshot of a CustomerStatic record |
| PlayerStatusID | Dictionary.PlayerStatus | Implicit | Compliance/trading restriction state lookup. See [Player Status](_glossary.md#player-status) |
| AccountStatusID | Dictionary.AccountStatus | Implicit | Open/closed state lookup. See [Account Status](_glossary.md#account-status) |
| LanguageID | Dictionary.Language | Implicit | UI language lookup. See [Language](_glossary.md#language) |
| CommunicationLanguageID | Dictionary.Language | Implicit | Communication language lookup |
| CountryID | Dictionary.Country | Implicit | Residence country lookup |
| RegionID | Dictionary.Region | Implicit | Geographic region lookup. See [Region](_glossary.md#region) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH.V_CustomerCustomerHourly | History.Customer | VIEW JOIN | DWH hourly snapshot view built on this table; uses COLUMNSTORE index |
| BackOffice.GetHistoryCustomer | History.Customer | READER | Returns customer version history to BackOffice UI for compliance investigations |
| Customer.GetUserChangesHistory | History.Customer | READER | Returns timeline of profile changes for a customer |
| MIMOAlerts.FinancialDiscrepancies_GetCustomerPlayerLevelDuringFinancialOps | History.Customer | READER | Retrieves historical PlayerLevelID at the time of financial operations |
| Internal.GetLastCustomerVersionID | History.Customer | READER | Returns the latest CustomerVersionID for a given CID |
| Internal.GetLoggedCustomerVersionID | History.Customer | READER | Returns the CustomerVersionID that was active at a given timestamp |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Customer (table)
- no code-level dependencies (leaf table)
```

### 6.1 Objects This Depends On

No code-level dependencies (leaf table). Logically depends on `Customer.CustomerStatic` as the source for version data; written via a trigger or service that monitors CustomerStatic changes (trigger not present in SSDT project - deployed separately).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DWH.V_CustomerCustomerHourly | View | Reads versioned customer dimension for DWH hourly snapshots |
| BackOffice.GetHistoryCustomer | Stored Procedure | READER - retrieves customer change history for BackOffice |
| BackOffice.GetBlockedCustomers | Stored Procedure | READER - queries historical blocked customer states |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | Stored Procedure | READER - finds accounts entering pending closure within a date range |
| BackOffice.GetClosedAccountsByLastChangeDate | Stored Procedure | READER - finds accounts closed within a date range |
| Customer.GetUserChangesHistory | Stored Procedure | READER - returns profile change history for a CID |
| MIMOAlerts.FinancialDiscrepancies_GetCustomerPlayerLevelDuringFinancialOps | Stored Procedure | READER - retrieves player level snapshot at time of financial operations |
| Internal.GetLastCustomerVersionID | Function | READER - returns latest version ID for a CID |
| Internal.GetLoggedCustomerVersionID | Function | READER - returns version ID active at a given timestamp |
| SalesForce.GetCustomerCustomer | Stored Procedure | READER - syncs customer history to Salesforce CRM |
| Hedge.ArchiveCustomerClosedPositions | Stored Procedure | READER - cross-references customer history during hedge archival |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryCustomer | CLUSTERED (PAGE compressed) | CustomerVersionID ASC | - | - | Active |
| IX_HistoryCustomer_ValidToCID | NONCLUSTERED (PAGE compressed) | ValidTo ASC, CID ASC | - | - | Active |
| Idx_HistoryCustomer_CID_CustomerVersionID | NONCLUSTERED (PAGE compressed, FILLFACTOR=90) | CID ASC, CustomerVersionID DESC | - | - | Active |
| inx_covering_dwh_nccs | NONCLUSTERED COLUMNSTORE | ValidFrom, ValidTo, CID, PlayerLevelID, LabelID | - | - | Active |

Note: CLUSTERED on CustomerVersionID (sequential identity) means inserts are physically appended - optimal for high-insert audit workloads. PAGE compression reduces storage for this 49M+ row table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryCustomer | PRIMARY KEY CLUSTERED | CustomerVersionID - auto-increment, unique per version entry |
| Df_HistoryCustomer_LotCountGroupID | DEFAULT | LotCountGroupID = 0 if not specified |
| Df_HistoryCustomer_WeekendFeePrecentage | DEFAULT | WeekendFeePrecentage = 100 (full standard fee) if not specified |
| Df_History_Customer_Trace | DEFAULT | Auto-generated JSON blob capturing session context (HostName, AppName, SUserName, OriginalLogin, SPID, DBName, ObjectName) |

---

## 8. Sample Queries

### 8.1 Get current profile for a customer

```sql
SELECT CID, PlayerStatusID, AccountStatusID, PlayerLevelID, ValidFrom
FROM History.Customer WITH (NOLOCK)
WHERE CID = @CID
  AND ValidTo = '3000-01-01 00:00:00.000'
```

### 8.2 Reconstruct customer profile at a point in time

```sql
SELECT *
FROM History.Customer WITH (NOLOCK)
WHERE CID = @CID
  AND ValidFrom <= @PointInTime
  AND ValidTo > @PointInTime
ORDER BY ValidFrom DESC;
```

### 8.3 Track PlayerStatus changes for a customer over time

```sql
SELECT
    hc.CustomerVersionID,
    hc.ValidFrom,
    hc.ValidTo,
    ps.Name AS PlayerStatus,
    hc.PlayerStatusReasonID,
    hc.PlayerStatusSubReasonID
FROM History.Customer hc WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON hc.PlayerStatusID = ps.PlayerStatusID
WHERE hc.CID = @CID
ORDER BY hc.ValidFrom ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [History.Customer](https://etoro-jira.atlassian.net/wiki/spaces/TR/pages/1719107661/History.Customer) | Confluence (Space: TR, RegTech) | Confirms SCD2 versioning purpose: "contains data of different versions of eToro's customers. Instead of deleting old data, it is stored as a version of the customer in this table." (2021-04-01) |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 8.6/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 1 ATLASSIAN-ONLY, 35 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 11 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Customer | Type: Table | Source: etoro/etoro/History/Tables/History.Customer.sql*
