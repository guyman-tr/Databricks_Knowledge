# BackOffice.GetHistoryCustomer

> Returns the full version history of a customer's core profile record for a given CID, with all lookup IDs resolved to human-readable names, ordered chronologically.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer whose profile history is retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns every historical version of a customer's core profile as stored in `History.Customer`. It answers: "What did this customer's profile look like at each point in time?" - covering personal details (name, address, email, phone), account settings (currency, language, spread group), and lifecycle status fields (player status, player level, verification, account closure reason).

The procedure exists to support BackOffice agents and compliance teams who need to audit how a customer's profile changed over time - for example, to trace a name or address change, review when a customer's status changed, or reconstruct the state of an account at a specific date for regulatory or dispute-resolution purposes.

Data flows from `History.Customer`, which is populated by the temporal/versioning system whenever the main customer table is modified. Each row represents a discrete snapshot with a `ValidFrom` timestamp and a `CustomerVersionID` sequence number. The SP enriches raw IDs with label names from eight Dictionary lookup tables, making the output directly readable by agents without cross-referencing.

---

## 2. Business Logic

### 2.1 Lookup Resolution for Human-Readable Output

**What**: The procedure resolves eight lookup IDs to their display names, reducing the need for agents to manually look up codes.

**Columns/Parameters Involved**: `CountryID -> Country`, `LanguageID -> Language`, `CommunicationLanguageID -> CommunicationLanguage`, `CurrencyID -> Currency`, `PlayerStatusID -> PlayerStatus`, `PlayerLevelID -> PlayerLevel`, `TradeLevelID -> TradeLevel`

**Rules**:
- All lookups use LEFT JOIN so a missing dictionary entry does not suppress the customer history row.
- `LanguageID` and `CommunicationLanguageID` both join to `Dictionary.Language` using the same `LanguageID` key - this is a self-join on the same table with different aliases (`dl` and `dcl`).
- `PlayerStatusReasonID` and `PlayerStatusSubReasonID` are passed through as raw IDs (not resolved to names despite the JOIN being present in the DDL).

### 2.2 Chronological Ordering by CustomerVersionID

**What**: History rows are ordered by `CustomerVersionID` ascending, providing the exact sequence in which changes were applied.

**Columns/Parameters Involved**: `CustomerVersionID` (in ORDER BY), `ValidFrom`

**Rules**:
- `CustomerVersionID` is a monotonically increasing integer representing the system-assigned version sequence.
- `ValidFrom` is the wall-clock timestamp when the version became active; ordering by `CustomerVersionID` ensures consistent ordering even if two versions share the same millisecond timestamp.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input parameter. The internal customer identifier for which all historical profile versions are returned. |

**Output Columns** (from `History.Customer` with lookup resolution):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ValidFrom | DATETIME | YES | - | CODE-BACKED | Timestamp when this version of the customer profile became active - i.e., when the preceding change was recorded. From `History.Customer.ValidFrom` (system-versioning period start). |
| 2 | Country | NVARCHAR | YES | - | CODE-BACKED | Country name at this version. Resolved from `Dictionary.Country` via `CountryID`. |
| 3 | StateID | INT | YES | - | NAME-INFERRED | State/province identifier at this version. Not resolved to name in this procedure. |
| 4 | Language | NVARCHAR | YES | - | CODE-BACKED | Primary language name at this version. Resolved from `Dictionary.Language` via `LanguageID`. |
| 5 | CommunicationLanguage | NVARCHAR | YES | - | CODE-BACKED | Preferred communication language name at this version. Resolved from `Dictionary.Language` via `CommunicationLanguageID` (same lookup table as Language, different column). |
| 6 | Currency | NVARCHAR | YES | - | CODE-BACKED | Account base currency name at this version. Resolved from `Dictionary.Currency` via `CurrencyID`. |
| 7 | TimeZoneID | INT | YES | - | NAME-INFERRED | Time zone identifier for the customer at this version. Not resolved to name. |
| 8 | PlayerStatus | NVARCHAR | YES | - | CODE-BACKED | Player/account status name at this version (e.g., Active, Blocked, Pending). Resolved from `Dictionary.PlayerStatus` via `PlayerStatusID`. |
| 9 | CampaignID | INT | YES | - | NAME-INFERRED | Marketing campaign identifier associated with the customer at this version. |
| 10 | PlayerLevel | NVARCHAR | YES | - | CODE-BACKED | Player level name at this version (e.g., Silver, Gold, Popular Investor). Resolved from `Dictionary.PlayerLevel` via `PlayerLevelID`. |
| 11 | TradeLevel | NVARCHAR | YES | - | CODE-BACKED | Trade level name at this version, governing trading permissions and leverage tiers. Resolved from `Dictionary.TradeLevel` via `TradeLevelID`. |
| 12 | SpreadGroupID | INT | YES | - | NAME-INFERRED | Spread group identifier at this version, determining the spread configuration applied to the customer's trades. |
| 13 | LabelID | INT | YES | - | NAME-INFERRED | Internal label/tag assigned to the customer at this version. |
| 14 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer's login username at this version. |
| 15 | IsReal | BIT | YES | - | CODE-BACKED | Account type flag: 1 = real-money account, 0 = demo account. Immutable after registration in most cases. |
| 16 | BirthDate | DATE | YES | - | CODE-BACKED | Customer's date of birth at this version. Used for age verification and KYC. |
| 17 | Gender | TINYINT | YES | - | NAME-INFERRED | Customer's gender at this version. |
| 18 | FirstName | NVARCHAR | YES | - | CODE-BACKED | Customer's first name at this version. |
| 19 | MiddleName | NVARCHAR | YES | - | CODE-BACKED | Customer's middle name at this version. |
| 20 | LastName | NVARCHAR | YES | - | CODE-BACKED | Customer's last name at this version. |
| 21 | Address | NVARCHAR | YES | - | CODE-BACKED | Street address at this version. |
| 22 | City | NVARCHAR | YES | - | CODE-BACKED | City at this version. |
| 23 | Zip | NVARCHAR | YES | - | CODE-BACKED | Postal/ZIP code at this version. |
| 24 | Email | NVARCHAR | YES | - | CODE-BACKED | Email address at this version. Tracks email change events. |
| 25 | IsEmailVerified | BIT | YES | - | CODE-BACKED | 1 = customer has clicked the verification link for the email at this version. |
| 26 | Phone | NVARCHAR | YES | - | CODE-BACKED | Primary phone number at this version. |
| 27 | Fax | NVARCHAR | YES | - | CODE-BACKED | Fax number at this version. |
| 28 | Mobile | NVARCHAR | YES | - | CODE-BACKED | Mobile phone number at this version. |
| 29 | Comments | NVARCHAR | YES | - | NAME-INFERRED | Internal comments or notes at this version. |
| 30 | SerialID | INT | YES | - | NAME-INFERRED | Serial identifier at this version. |
| 31 | AccountExpirationDate | DATETIME | YES | - | CODE-BACKED | Date after which the account expires (used for trial or promotional accounts) at this version. |
| 32 | HelpDeskType | INT | YES | - | NAME-INFERRED | Help desk classification type at this version, routing customer support requests. |
| 33 | LotCountGroupID | INT | YES | - | NAME-INFERRED | Lot count group identifier at this version, governing trading lot size constraints. |
| 34 | PrivacyPolicyID | INT | YES | - | NAME-INFERRED | Privacy policy version accepted by the customer at this version. |
| 35 | GCID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Global Customer ID at this version. Links to cross-schema customer identity (Customer.CustomerStatic). |
| 36 | WeekendFeePrecentage | DECIMAL | YES | - | CODE-BACKED | Weekend holding fee percentage applied to this customer at this version. Note: column name has a typo ("Precentage"). |
| 37 | IsEmailActivated | BIT | YES | - | CODE-BACKED | 1 = the customer's account email has been activated (distinct from IsEmailVerified - activation is the account-enablement step). |
| 38 | AccountStatusID | INT | YES | - | NAME-INFERRED | Account-level status identifier at this version (distinct from PlayerStatusID which is the trading/play status). |
| 39 | PendingClosureStatusID | INT | YES | - | CODE-BACKED | Status identifier for accounts in the pending-closure process at this version. Resolved label available via `Dictionary.PendingClosureStatus`. |
| 40 | PlayerStatusReasonID | INT | YES | - | CODE-BACKED | Reason code for the current player status at this version (e.g., why the account was blocked). From `Dictionary.PlayerStatusReasons`. |
| 41 | PlayerStatusSubReasonID | INT | YES | - | CODE-BACKED | Sub-reason code refining the player status reason at this version. From `Dictionary.PlayerStatusSubReasons`. |
| 42 | BuildingNumber | NVARCHAR | YES | - | CODE-BACKED | Building/apartment number component of the address at this version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | History.Customer | Lookup (READ) | Primary source of all customer profile history snapshots |
| CountryID | Dictionary.Country | Lookup | Resolves country code to country name |
| LanguageID | Dictionary.Language | Lookup | Resolves language code to language name |
| CommunicationLanguageID | Dictionary.Language | Lookup | Resolves communication language (same table as Language, different column) |
| CurrencyID | Dictionary.Currency | Lookup | Resolves currency code to currency name |
| PlayerStatusID | Dictionary.PlayerStatus | Lookup | Resolves player status code to status name |
| PlayerLevelID | Dictionary.PlayerLevel | Lookup | Resolves player level code to level name |
| TradeLevelID | Dictionary.TradeLevel | Lookup | Resolves trade level code to level name |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | Lookup | Reason for the player status (passed through as ID, not resolved to name in SELECT) |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | Lookup | Sub-reason for the player status (passed through as ID) |
| PendingClosureStatusID | Dictionary.PendingClosureStatus | Lookup | Status in the pending-closure workflow |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BOUser (database role) | EXECUTE permission | Permission | The BOUser database role is granted EXECUTE on this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetHistoryCustomer (procedure)
├── History.Customer (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.Country (table)
├── Dictionary.Language (table) [joined twice: LanguageID + CommunicationLanguageID]
├── Dictionary.TradeLevel (table)
├── Dictionary.Currency (table)
├── Dictionary.PlayerStatus (table)
├── Dictionary.PlayerStatusReasons (table)
├── Dictionary.PlayerStatusSubReasons (table)
└── Dictionary.PendingClosureStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Customer | Table | FROM clause; source of all customer profile version rows |
| Dictionary.PlayerLevel | Table | LEFT JOIN on PlayerLevelID to resolve level name |
| Dictionary.Country | Table | LEFT JOIN on CountryID to resolve country name |
| Dictionary.Language | Table | LEFT JOIN twice: on LanguageID (Language) and CommunicationLanguageID (CommunicationLanguage) |
| Dictionary.TradeLevel | Table | LEFT JOIN on TradeLevelID to resolve trade level name |
| Dictionary.Currency | Table | LEFT JOIN on CurrencyID to resolve currency name |
| Dictionary.PlayerStatus | Table | LEFT JOIN on PlayerStatusID to resolve status name |
| Dictionary.PlayerStatusReasons | Table | LEFT JOIN on PlayerStatusReasonID (reason ID passed through, not name-resolved in SELECT) |
| Dictionary.PlayerStatusSubReasons | Table | LEFT JOIN on PlayerStatusSubReasonID (sub-reason ID passed through) |
| Dictionary.PendingClosureStatus | Table | LEFT JOIN on PendingClosureStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called directly to power the customer profile audit history view in the BackOffice portal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages for the calling application |
| WITH (NOLOCK) on History.Customer | Query hint | Avoids blocking on the temporal history table |

---

## 8. Sample Queries

### 8.1 Retrieve full customer profile history for a customer

```sql
EXEC BackOffice.GetHistoryCustomer @CID = 12345
```

### 8.2 Query customer history directly with key changes highlighted

```sql
SELECT c.ValidFrom,
       dc.Name AS Country,
       dl.Name AS Language,
       dps.Name AS PlayerStatus,
       c.Email,
       c.UserName,
       c.IsReal
FROM History.Customer c WITH (NOLOCK)
LEFT JOIN Dictionary.Country dc WITH (NOLOCK) ON c.CountryID = dc.CountryID
LEFT JOIN Dictionary.Language dl WITH (NOLOCK) ON c.LanguageID = dl.LanguageID
LEFT JOIN Dictionary.PlayerStatus dps WITH (NOLOCK) ON c.PlayerStatusID = dps.PlayerStatusID
WHERE c.CID = 12345
ORDER BY c.CustomerVersionID;
```

### 8.3 Find customers whose email changed over their history

```sql
SELECT c1.CID,
       c1.Email AS OldEmail,
       c2.Email AS NewEmail,
       c2.ValidFrom AS ChangedAt
FROM History.Customer c1 WITH (NOLOCK)
INNER JOIN History.Customer c2 WITH (NOLOCK)
    ON c1.CID = c2.CID
    AND c2.CustomerVersionID = c1.CustomerVersionID + 1
    AND c1.Email <> c2.Email
ORDER BY c2.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 14 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetHistoryCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetHistoryCustomer.sql*
