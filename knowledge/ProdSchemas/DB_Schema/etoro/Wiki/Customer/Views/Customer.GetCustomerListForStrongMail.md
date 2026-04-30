# Customer.GetCustomerListForStrongMail

> Legacy StrongMail email marketing feed: assembles a comprehensive customer profile per CID including identity, account status, championship activity, deposit/position history flags, manager info, and last login dates for use in segmented email campaigns.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID (from Customer.Customer) |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetCustomerListForStrongMail is a wide customer export view purpose-built for the StrongMail email marketing platform (a legacy predecessor to modern CRM tools). It assembles 32 fields per customer covering identity, financial status, championship participation, trading activity history, account manager assignment, and login history into a single exportable row per customer. StrongMail used this data to build segmented email campaign lists (e.g., target customers with a manager, or customers who have deposited but not yet opened a position).

The view is the primary integration surface between the eToro platform database and the StrongMail outbound email system. It combines live customer state (via Customer.Customer and BackOffice) with historical activity flags derived from History schema tables to produce a rich marketing profile without exposing sensitive internal mechanics.

The view requires each customer to have a row in BackOffice.CustomerAllTimeAggregatedData (INNER JOIN). This acts as a qualification gate: only customers who have been processed through BackOffice aggregation appear in the export. All other JOINs are LEFT JOINs, meaning fields like championship data, manager assignment, and login history can be NULL for customers without those records.

---

## 2. Business Logic

### 2.1 Password Blanking

**What**: The password field is always exported as an empty string, never the actual hash.

**Columns/Parameters Involved**: `Password`

**Rules**:
- DDL: `'' as Password` - hardcoded empty string regardless of actual Customer.Customer.Password value
- This is a deliberate security measure for the marketing integration: StrongMail received customer data but was never authorized to hold password hashes
- The field is included in the schema contract (column must exist in the export) but its value is always blank

### 2.2 Demo vs Real Account Flag (DB_NAME() Pattern)

**What**: DemoAccount and RealAccount are determined by the database name at query time, not by a customer data column.

**Columns/Parameters Involved**: `DemoAccount`, `RealAccount`

**Rules**:
- `CASE WHEN DB_NAME() = 'tradonomi_rep' THEN 1 ELSE 0 END AS DemoAccount`
- `CASE WHEN DB_NAME() <> 'tradonomi_rep' THEN 1 ELSE 0 END AS RealAccount`
- In the demo database (`tradonomi_rep`): every row has DemoAccount=1, RealAccount=0
- In the real database (any other name): every row has DemoAccount=0, RealAccount=1
- These flags are not per-customer - they describe the environment the query runs in. This allowed StrongMail to tag all rows from a given database run with the account type without needing to know the DB name externally.

```
DB = 'tradonomi_rep':  DemoAccount=1, RealAccount=0  (all rows are demo)
DB = 'etoro' (or any): DemoAccount=0, RealAccount=1  (all rows are real)
```

### 2.3 HasDeposited Flag (History.Credit CreditTypeID=1)

**What**: Binary flag indicating whether the customer has ever made at least one deposit, derived from History.Credit.

**Columns/Parameters Involved**: `HasDeposited`

**Rules**:
- Subquery: `SELECT MAX(CreditID), CID FROM History.Credit WHERE CreditTypeID = 1 GROUP BY CID`
- `CASE WHEN HCRD.MaxCreditID IS NULL THEN 0 ELSE 1 END AS HasDeposited`
- CreditTypeID=1 identifies deposit-type credit records in History.Credit
- If the customer has any such record (MAX is not NULL), HasDeposited=1; otherwise 0
- Used by StrongMail to target the "registered but never deposited" segment

### 2.4 HasOpenedPosition Flag (History.Position)

**What**: Binary flag indicating whether the customer has ever opened any trading position.

**Columns/Parameters Involved**: `HasOpenedPosition`

**Rules**:
- Subquery: `SELECT COUNT(*) TPOS_CNT, CID FROM History.Position GROUP BY CID`
- `CASE WHEN TPOS.TPOS_CNT IS NOT NULL THEN 1 ELSE 0 END AS HasOpenedPosition`
- Any row in History.Position for the CID = HasOpenedPosition=1 (no status filter)
- Comment in DDL: "without first open position by CID" - confirms this counts all historical positions regardless of open/close status
- Used by StrongMail to target "deposited but never traded" customers

### 2.5 Current vs Previous Account Status

**What**: Human-readable account status labels for the customer's current state and their prior state (before the last change).

**Columns/Parameters Involved**: `CurrentAccountStatus`, `PreviousAccountStatus`

**Rules**:
- `CurrentAccountStatus`: `Dictionary.PlayerLevel.Name` for the customer's current `PlayerLevelID`
- `PreviousAccountStatus`: `Dictionary.PlayerLevel.Name` for the `PlayerLevelID` in `History.Customer` at `MAX(CustomerVersionID)` WHERE `ValidTo < '3000-01-01'` (i.e., the most recently closed/superseded customer version)
- A ValidTo of 3000-01-01 or later indicates the "current" version - this filter explicitly excludes it to get the prior state
- If the customer has never had a status change, PreviousAccountStatus will be NULL -> ISNULL resolves to ''

### 2.6 Championship Fields

**What**: The customer's most recent championship performance metrics, combining current and historical championship schema data.

**Columns/Parameters Involved**: `ChampPrize`, `ChampRank`, `ChampProfit`

**Rules**:
- `ChampPrize` (ISNULL 0): `BackOffice.CustomerAllTimeAggregatedData.TotalChampWin` - total championship prize winnings across all championships
- `ChampRank` (ISNULL 0): `History.ChampionshipPlayer.WinPos` for the customer's most recent championship (MAX ChampionshipID)
- `ChampProfit` (ISNULL 0): `Championship.ChampionshipPlayer.ChampProfit` - current active championship profit
- Championship data was used by StrongMail to target customers based on competitive performance (e.g., "you finished in the top 10!")

---

## 3. Data Overview

View is not accessible in this environment (EtoroArchive DB cross-reference permission restriction on History schema tables). The view assembles live customer data with history tables, requiring cross-database access. Sample data cannot be shown.

Representative row would look like:

| CID | FirstName | Email | CurrentAccountStatus | HasDeposited | HasOpenedPosition | ManagerID | RowOrigen | Meaning |
|-----|-----------|-------|---------------------|--------------|-------------------|-----------|-----------|---------|
| (example) | John | john@... | Standard | 1 | 1 | 0 | etoro | Active real customer, has deposited and traded, no assigned manager. Standard StrongMail marketing segment. |
| (example) | Jane | jane@... | Popular Investor | 1 | 1 | 12 | etoro | Popular Investor tier customer with an assigned manager (ManagerID=12), full activity history. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - platform-internal primary key. From Customer.Customer. The primary customer identifier in the export. |
| 2 | FirstName | nvarchar(50) | YES | - | VERIFIED | Legal first name in Unicode. From Customer.Customer (base: CustomerStatic). Dynamic Data Masking on base table. Used for email personalization salutation. |
| 3 | LastName | nvarchar(50) | YES | - | VERIFIED | Legal last name in Unicode. From Customer.Customer (base: CustomerStatic). Dynamic Data Masking on base table. Used for full-name personalization. |
| 4 | UserName | varchar(20) | NO | - | VERIFIED | Customer login username. From Customer.Customer. Unique (case-insensitive). Used by StrongMail as a fallback display name when FirstName is NULL. |
| 5 | Password | varchar | NO | - | CODE-BACKED | Always exported as '' (empty string). Intentionally blanked for security - StrongMail integration is not authorized to hold password hashes. The column exists to satisfy the StrongMail schema contract. |
| 6 | Email | varchar(50) | NO | - | VERIFIED | Customer email address, ISNULL-guarded to '' when NULL. From Customer.Customer (base: CustomerStatic). Dynamic Data Masking on base table. Primary delivery address for StrongMail campaigns. |
| 7 | Credit | money | YES | - | VERIFIED | Customer's current available trading balance in USD. From Customer.Customer (base: CustomerMoney). NULL if no CustomerMoney row. Used for deposit-tier segmentation in email campaigns. |
| 8 | ChampPrize | money | NO | - | CODE-BACKED | Total championship prize winnings, defaulting to 0 if no BO record. From BackOffice.CustomerAllTimeAggregatedData.TotalChampWin. Used in championship campaign targeting. |
| 9 | ChampRank | int | NO | - | CODE-BACKED | Winning position (rank) in the customer's most recent championship (MAX ChampionshipID). From History.ChampionshipPlayer.WinPos. 0 if never participated. |
| 10 | ChampProfit | money | NO | - | CODE-BACKED | Profit achieved in the customer's current active championship. From Championship.ChampionshipPlayer.ChampProfit. 0 if not in an active championship. |
| 11 | CurrentAccountStatus | nvarchar | NO | - | CODE-BACKED | Human-readable name of the customer's current PlayerLevel. From Dictionary.PlayerLevel.Name (joined on Customer.Customer.PlayerLevelID). Examples: 'Standard', 'Popular Investor', 'VIP'. ISNULL-guarded to '' when no match. |
| 12 | PreviousAccountStatus | nvarchar | NO | - | CODE-BACKED | Human-readable name of the customer's prior PlayerLevel before the most recent change. From Dictionary.PlayerLevel.Name via History.Customer (MAX CustomerVersionID WHERE ValidTo < '3000-01-01'). '' if no prior state found. |
| 13 | CountryName | nvarchar | YES | - | CODE-BACKED | Country name based on the customer's IP-detected country. From Dictionary.Country.Name joined on Customer.Customer.CountryIDByIP (IP-detected, not profile country). Used for geo-segmentation in email campaigns. |
| 14 | ClientLnguage | nvarchar | YES | - | CODE-BACKED | Customer's preferred language name (note: typo "Lnguage" in column alias). From Dictionary.Language.Name joined on Customer.Customer.LanguageID. Used for language-localized email dispatch. |
| 15 | DemoAccount | int | NO | - | CODE-BACKED | 1 if this export was run from the demo database ('tradonomi_rep'), 0 otherwise. Derived from DB_NAME() at query time. Not a per-customer flag - all rows from the same run share this value. |
| 16 | RealAccount | int | NO | - | CODE-BACKED | 1 if this export was run from any non-demo database, 0 otherwise. Inverse of DemoAccount. Derived from DB_NAME(). |
| 17 | HasDeposited | int | NO | - | CODE-BACKED | 1 if the customer has at least one deposit record in History.Credit (CreditTypeID=1); 0 otherwise. Key StrongMail segmentation flag: separates "registered only" from "depositing" customers. |
| 18 | HasOpenedPosition | int | NO | - | CODE-BACKED | 1 if the customer has any row in History.Position (regardless of status); 0 otherwise. StrongMail segmentation: separates customers who have deposited from those who have also traded. |
| 19 | BirthDate | datetime | YES | - | VERIFIED | Customer date of birth. From Customer.Customer (base: CustomerStatic). Dynamic Data Masking on base table. Included for age-based campaign eligibility checks. |
| 20 | RegistrationDate | datetime | NO | - | VERIFIED | Account registration date. From Customer.Customer.Registered. Default=getdate() at INSERT time. Used for registration-anniversary campaigns. |
| 21 | FXEligibilityDate | datetime | YES | - | CODE-BACKED | Date the customer became eligible for FX trading. From BackOffice.Customer.FXEligibilityDate. NULL if the customer has not yet achieved FX eligibility. Used in FX onboarding campaigns. |
| 22 | LastLoginRegularClient | datetime | YES | - | CODE-BACKED | Most recent login timestamp for the classic/legacy client (ClientVersion < '2'). From History.LoginArch.LoggedIn WHERE ClientVersion < '2'. NULL if customer never used the legacy client or no login records. |
| 23 | LastLoginWebClient | datetime | YES | - | CODE-BACKED | Most recent login timestamp for the web client (ClientVersion >= '10'). From History.LoginArch.LoggedIn WHERE ClientVersion >= '10'. NULL if customer never logged in via web client. Used for re-engagement targeting. |
| 24 | LabelID | int | YES | - | VERIFIED | Internal segment label. From Customer.Customer (base: CustomerStatic). FK to Dictionary.Label. LabelID=26 = BonusOnly. Used for offer eligibility filtering in StrongMail campaigns. |
| 25 | ManagerID | int | NO | - | CODE-BACKED | Assigned account manager ID. ISNULL-guarded to 0. From BackOffice.Customer.ManagerID. 0 = no manager assigned. Used to segment managed vs self-service customers. |
| 26 | ManagerName | nvarchar | NO | - | CODE-BACKED | Full name of the assigned manager. Concatenated: ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') from BackOffice.Manager. Empty string ' ' when ManagerID=0 or manager has no name. |
| 27 | AffiliateID | int | YES | - | VERIFIED | Affiliate/introducing broker ID. From Customer.Customer.SerialID. NULL for direct/organic registrations. Used to segment affiliate-acquired customers for co-branded campaigns. |
| 28 | OriginalCID | int | NO | - | CODE-BACKED | Original customer ID from the source provider before migration. From Customer.Customer. Default=0 for non-migrated accounts. Included for matching against legacy provider records. |
| 29 | RealProviderID | int | YES | - | CODE-BACKED | Underlying real provider ID. From Customer.Customer. Nullable. Identifies the true trading provider for broker-segregated campaigns. |
| 30 | ProviderID | int | NO | - | VERIFIED | Current active provider/broker ID. From Customer.Customer. FK to Trade.Provider. Broker identification for routing and compliance filtering. |
| 31 | OriginalProviderID | int | NO | - | CODE-BACKED | Provider ID from which the account was originally migrated. From Customer.Customer. For migration-history tracking. |
| 32 | RowOrigen | nvarchar | NO | - | CODE-BACKED | Database name at query time (DB_NAME()). Explicit source tag in the export row. Allows StrongMail to track which environment/database a row came from when multiple databases are exported in the same batch. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (CCST alias) | Primary customer source: identity, credit, labels, provider fields |
| - | BackOffice.CustomerAllTimeAggregatedData | INNER JOIN on CID | Championship prize totals; also acts as qualification gate (only customers with a BO aggregate record appear) |
| - | History.ChampionshipPlayer | LEFT JOIN on CID + MAX ChampionshipID | Most recent championship rank (WinPos) |
| - | Championship.ChampionshipPlayer | LEFT JOIN on CID | Current active championship profit |
| - | Dictionary.PlayerLevel | LEFT JOIN on PlayerLevelID (x2) | Current and previous account status names |
| - | History.Customer | LEFT JOIN on CID + MAX CustomerVersionID | Previous customer state (prior PlayerLevelID) |
| - | Dictionary.Country | LEFT JOIN on CountryIDByIP | Country name from IP detection |
| - | Dictionary.Language | LEFT JOIN on LanguageID | Language name for email localization |
| - | History.Credit | LEFT JOIN subquery (CreditTypeID=1) | HasDeposited flag derivation |
| - | History.Position | LEFT JOIN subquery | HasOpenedPosition flag derivation |
| - | History.LoginArch | LEFT JOIN subquery x2 (ClientVersion filters) | Last login timestamps per client type |
| - | BackOffice.Customer | LEFT JOIN on CID | FX eligibility date, ManagerID |
| - | BackOffice.Manager | LEFT JOIN on ManagerID | Manager first/last name |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view. It was a terminal export view consumed directly by StrongMail ETL/import tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerListForStrongMail (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema]
├── History.ChampionshipPlayer (table) [cross-schema]
├── Championship.ChampionshipPlayer (table) [cross-schema]
├── Dictionary.PlayerLevel (table) [cross-schema]
├── History.Customer (table) [cross-schema]
├── Dictionary.Country (table) [cross-schema]
├── Dictionary.Language (table) [cross-schema]
├── History.Credit (table) [cross-schema]
├── History.Position (table) [cross-schema]
├── History.LoginArch (table) [cross-schema]
├── BackOffice.Customer (table) [cross-schema]
└── BackOffice.Manager (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) - primary customer data source |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | INNER JOIN - championship totals + qualification gate |
| History.ChampionshipPlayer | Table (cross-schema) | LEFT JOIN - most recent championship rank |
| Championship.ChampionshipPlayer | Table (cross-schema) | LEFT JOIN - current championship profit |
| Dictionary.PlayerLevel | Table (cross-schema) | LEFT JOIN x2 - current and previous status names |
| History.Customer | Table (cross-schema) | LEFT JOIN subquery - prior customer version for PreviousAccountStatus |
| Dictionary.Country | Table (cross-schema) | LEFT JOIN - IP country name |
| Dictionary.Language | Table (cross-schema) | LEFT JOIN - language name |
| History.Credit | Table (cross-schema) | LEFT JOIN subquery (CreditTypeID=1) - HasDeposited flag |
| History.Position | Table (cross-schema) | LEFT JOIN subquery - HasOpenedPosition flag |
| History.LoginArch | Table (cross-schema) | LEFT JOIN subquery x2 - last login per client version range |
| BackOffice.Customer | Table (cross-schema) | LEFT JOIN - FXEligibilityDate, ManagerID |
| BackOffice.Manager | Table (cross-schema) | LEFT JOIN - manager name |

### 6.2 Objects That Depend On This

No dependents found. Terminal export view.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance is governed by indexes on the 13 underlying tables.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN to BackOffice.CustomerAllTimeAggregatedData | Implicit filter | Only customers with a BO aggregate record appear; customers not yet processed by BackOffice are excluded |
| SCHEMABINDING | None | View is not schema-bound |

---

## 8. Sample Queries

### 8.1 Find managed customers eligible for FX campaigns
```sql
SELECT
    CID,
    FirstName,
    Email,
    ManagerID,
    ManagerName,
    FXEligibilityDate,
    Credit,
    CurrentAccountStatus
FROM Customer.GetCustomerListForStrongMail WITH (NOLOCK)
WHERE ManagerID > 0
  AND FXEligibilityDate IS NOT NULL
  AND HasDeposited = 1;
```

### 8.2 Find "deposited but never traded" customers for re-engagement
```sql
SELECT
    CID,
    FirstName,
    Email,
    RegistrationDate,
    Credit,
    LastLoginWebClient
FROM Customer.GetCustomerListForStrongMail WITH (NOLOCK)
WHERE HasDeposited = 1
  AND HasOpenedPosition = 0
ORDER BY RegistrationDate DESC;
```

### 8.3 Championship campaign - customers with prize winnings
```sql
SELECT
    CID,
    FirstName,
    Email,
    ChampPrize,
    ChampRank,
    ChampProfit,
    CurrentAccountStatus
FROM Customer.GetCustomerListForStrongMail WITH (NOLOCK)
WHERE ChampPrize > 0
   OR ChampRank > 0
ORDER BY ChampPrize DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view, no consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCustomerListForStrongMail | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetCustomerListForStrongMail.sql*
