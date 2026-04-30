# BackOffice.GetRegistrationReport

> Returns a filterable customer registration report with account profile, aggregated trading data, verification status, and manager assignment - the primary BO export for customer lifecycle analysis and affiliate reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; returns Customer.Customer rows matching all active filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRegistrationReport` is the main Back Office customer registration export. It combines core customer identity data (name, email, phone, country, language, registration date) with aggregated lifetime activity (total deposit, cashout, balance) and status enrichment (KYC level, sales status, document status, regulation, white label, manager). Every row represents one registered customer account.

The procedure is the primary tool for Back Office teams to extract customer lists for compliance reviews, affiliate reconciliation, AML screening, and sales pipeline management. It supports wide filtering across 14 dimensions, allowing narrowing by registration date range, affiliate, country, language, player status, level, regulation, designated regulation, white label, province, and assigned manager.

STRING_SPLIT is used for multi-value list parameters (AffiliateID, Regulations, DesignatedRegulations, WhiteLabels, ProvinceIds) - no dynamic SQL injection risk as these use parameterized STRING_SPLIT rather than string concatenation.

---

## 2. Business Logic

### 2.1 Blocked Status Derivation

**What**: The [Blocked] column summarizes whether a customer is currently blocked from trading, derived from the PlayerStatus flag.

**Columns/Parameters Involved**: `Blocked`, `Dictionary.PlayerStatus.IsBlocked`

**Rules**:
- `CASE WHEN DPLS.IsBlocked = 1 THEN 'YES' ELSE 'NO' END AS Blocked`
- Reads Dictionary.PlayerStatus.IsBlocked flag - not a direct column on Customer.Customer
- Provides a simple YES/NO for BO agents reviewing compliance lists

### 2.2 DocumentStatus Default Fallback

**What**: If a customer has no DocumentStatusID set in BackOffice.Customer, defaults to DocumentStatusID = 0.

**Columns/Parameters Involved**: `DocumentStatus`, `BCST.DocumentStatusID`

**Rules**:
- NULL DocumentStatusID -> resolves to DocumentStatus where DocumentStatusID = 0 (the default/unverified status)
- This prevents NULL appearing in the report - every customer shows a document status
- Subquery SELECT used for the default case (not a join), to avoid adding a second LEFT JOIN

### 2.3 Province/Region Resolution

**What**: The ProvinceOrState column resolves the customer's sub-national region from a two-step lookup.

**Columns/Parameters Involved**: `ProvinceOrState`, `Customer.Customer.RegionID`, `Dictionary.RegionByIP`, `Dictionary.RegionName`

**Rules**:
- RegionID on Customer.Customer links to Dictionary.RegionByIP (which has a ShortName)
- Dictionary.RegionName is matched on ShortName + CountryID to get the full region name
- NULL if RegionID not set or region not found in both tables

### 2.4 Manager Assignment Display

**What**: The [Manager] column shows the full name of the BackOffice manager assigned to this customer.

**Columns/Parameters Involved**: `Manager`, `BCST.ManagerID`, `BackOffice.Manager`

**Rules**:
- `ISNULL(BMNG.FirstName, '') + ' ' + ISNULL(BMNG.LastName, '')` - always returns a string, even if manager not found (empty string)
- Manager assignment is stored in BackOffice.Customer.ManagerID
- @SingleManager = 1 + @ManagerID filters to customers assigned to a specific manager

### 2.5 Dual Regulation Fields

**What**: Customers can have both a primary regulation and a designated regulation, representing their compliance jurisdiction.

**Columns/Parameters Involved**: `Regulation`, `DesignatedRegulation`, `BCST.RegulationID`, `BCST.DesignatedRegulationID`

**Rules**:
- Regulation = primary regulatory jurisdiction from BackOffice.Customer.RegulationID
- DesignatedRegulation = secondary/designated regulation from BackOffice.Customer.DesignatedRegulationID
- Both can be filtered independently via @Regulations and @DesignatedRegulations (comma-separated IDs)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegisteredAfter | DATETIME | YES | NULL | CODE-BACKED | Filter to customers who registered on or after this date (Customer.Customer.Registered >= @RegisteredAfter). |
| 2 | @RegisteredBefore | DATETIME | YES | NULL | CODE-BACKED | Filter to customers who registered on or before this date (Customer.Customer.Registered <= @RegisteredBefore). |
| 3 | @AffiliateID | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of affiliate serial IDs (Customer.Customer.SerialID). Filters to customers acquired through specified affiliates. |
| 4 | @SubSerialID | NVARCHAR(50) | YES | NULL | CODE-BACKED | Sub-affiliate tracking ID (Customer.Customer.SubSerialID). Exact match filter for sub-affiliate attribution. |
| 5 | @DownloadID | NVARCHAR(100) | YES | NULL | CODE-BACKED | Download/tracking ID with wildcard support (* becomes %). LIKE-based filter on Customer.Customer.DownloadID for campaign tracking. |
| 6 | @CountryID | INT | YES | NULL | CODE-BACKED | Filter to customers from a specific country (Customer.Customer.CountryID). |
| 7 | @LanguageID | INT | YES | NULL | CODE-BACKED | Filter to customers with a specific interface language (Customer.Customer.LanguageID). |
| 8 | @PlayerLevelID | INT | YES | NULL | CODE-BACKED | Filter to customers at a specific player level (Customer.Customer.PlayerLevelID). Level 4 = internal/staff. |
| 9 | @PlayerStatusID | INT | YES | NULL | CODE-BACKED | Filter to customers at a specific account status (Customer.Customer.PlayerStatusID). |
| 10 | @SingleManager | BIT | YES | 0 | CODE-BACKED | When 1 (with @ManagerID provided), restricts results to customers assigned to one specific BO manager. 0 = all managers. |
| 11 | @ManagerID | INT | YES | NULL | CODE-BACKED | BackOffice.Customer.ManagerID filter. Only applied when @SingleManager = 1. |
| 12 | @Regulations | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of regulation IDs. Filters on BackOffice.Customer.RegulationID via STRING_SPLIT. |
| 13 | @DesignatedRegulations | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of designated regulation IDs. Filters on BackOffice.Customer.DesignatedRegulationID via STRING_SPLIT. |
| 14 | @WhiteLabels | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of white label IDs. Filters on Customer.Customer.LabelID via STRING_SPLIT. |
| 15 | @ProvinceIds | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of RegionIDs. Filters on Customer.Customer.RegionID via STRING_SPLIT for province/state-level filtering. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID (Customer.Customer.CID). |
| 2 | OriginalCID | INT | YES | - | CODE-BACKED | Original CID before any account migration or merge (Customer.Customer.OriginalCID). |
| 3 | UserName | NVARCHAR | NO | - | CODE-BACKED | Customer's username on the eToro platform. |
| 4 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer's email address. |
| 5 | Phone | NVARCHAR | YES | - | CODE-BACKED | Customer's phone number. |
| 6 | Country | NVARCHAR | YES | - | CODE-BACKED | Country name from registration form (Dictionary.Country via Customer.Customer.CountryID). |
| 7 | RegionID | INT | YES | - | CODE-BACKED | Region/province ID from customer's account (Customer.Customer.RegionID). Numeric; use ProvinceOrState for the name. |
| 8 | ProvinceOrState | NVARCHAR | YES | - | CODE-BACKED | Human-readable province or state name, resolved from RegionID via Dictionary.RegionByIP + Dictionary.RegionName (two-step: RegionByIP.ShortName matched to RegionName.ShortName + CountryID). |
| 9 | Language | NVARCHAR | YES | - | CODE-BACKED | Customer's preferred interface language (trimmed, from Dictionary.Language via Customer.Customer.LanguageID). |
| 10 | RegistrationDate | DATETIME | NO | - | CODE-BACKED | Date and time the customer registered on the platform (Customer.Customer.Registered). |
| 11 | Balance | DECIMAL(16,2) | YES | - | CODE-BACKED | Current account credit balance (Customer.Customer.Credit, cast to DECIMAL(16,2)). |
| 12 | Blocked | VARCHAR(3) | YES | - | VERIFIED | Whether the customer account is currently blocked. 'YES' = Dictionary.PlayerStatus.IsBlocked = 1. 'NO' = not blocked. |
| 13 | AffiliateID | INT | YES | - | CODE-BACKED | Affiliate serial ID for this customer's acquisition channel (Customer.Customer.SerialID). Used for affiliate commission attribution. |
| 14 | AffiliateRank | NVARCHAR | YES | - | CODE-BACKED | Affiliate's rank/tier name (Dictionary.AffiliateStatus.Name via BackOffice.Affiliate.AffiliateStatusID). NULL if no affiliate record. |
| 15 | TotalDeposit | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total deposited amount (BackOffice.CustomerAllTimeAggregatedData.TotalDeposit). |
| 16 | TotalCashout | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total processed cashout amount (BackOffice.CustomerAllTimeAggregatedData.TotalCashout). |
| 17 | Manager | NVARCHAR | YES | - | CODE-BACKED | Full name (FirstName + LastName) of the BackOffice manager assigned to this customer (BackOffice.Manager via BackOffice.Customer.ManagerID). Empty string if no manager assigned. |
| 18 | VerificationLevel | NVARCHAR | YES | - | VERIFIED | KYC verification level name (Dictionary.VerificationLevel via BackOffice.Customer.VerificationLevelID). Level 0 through Level 3. |
| 19 | SalesStatus | NVARCHAR | YES | - | CODE-BACKED | Sales pipeline status name (Dictionary.SalesStatus via BackOffice.Customer.SalesStatusID). Tracks where the customer is in the sales funnel. |
| 20 | WhiteLabel | NVARCHAR | YES | - | CODE-BACKED | White label brand name (Dictionary.Label via Customer.Customer.LabelID). NULL for main eToro brand. |
| 21 | ExpirationDate | DATETIME | YES | - | CODE-BACKED | Account expiration date (Customer.Customer.AccountExpirationDate). NULL for non-expiring accounts. |
| 22 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Primary regulatory jurisdiction name (Dictionary.Regulation via BackOffice.Customer.RegulationID). |
| 23 | DesignatedRegulation | NVARCHAR | YES | - | CODE-BACKED | Designated/secondary regulatory jurisdiction name (Dictionary.Regulation via BackOffice.Customer.DesignatedRegulationID). |
| 24 | DocumentStatus | NVARCHAR | NO | - | VERIFIED | KYC document verification status name (Dictionary.DocumentStatus). Defaults to DocumentStatusID = 0 if BackOffice.Customer.DocumentStatusID is NULL. |
| 25 | ManagerID | INT | YES | - | CODE-BACKED | Numeric ID of the assigned BackOffice manager (BackOffice.Customer.ManagerID). Returned for programmatic use alongside the Manager name. |
| 26 | SerialID | NVARCHAR | YES | - | CODE-BACKED | Sub-affiliate ID (Customer.Customer.SubSerialID, aliased as SerialID). Used for sub-affiliate tracking. |
| 27 | DownloadID | NVARCHAR | YES | - | CODE-BACKED | Download/campaign tracking ID (Customer.Customer.DownloadID). Used for marketing attribution. |
| 28 | CountryID | INT | YES | - | CODE-BACKED | Numeric country ID (Customer.Customer.CountryID). Returned alongside Country name for programmatic use. |
| 29 | LanguageID | INT | YES | - | CODE-BACKED | Numeric language ID (Customer.Customer.LanguageID). Returned alongside Language name. |
| 30 | PlayerStatusID | INT | YES | - | CODE-BACKED | Numeric player status ID (Customer.Customer.PlayerStatusID). Returned for programmatic filtering. |
| 31 | PlayerLevelID | INT | YES | - | CODE-BACKED | Numeric player level ID (Customer.Customer.PlayerLevelID). Returned for programmatic filtering. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (primary) | Customer.Customer | Read | Core customer record |
| CID | BackOffice.Customer | LEFT JOIN | BO attributes: ManagerID, VerificationLevelID, DocumentStatusID, RegulationID, etc. |
| CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | Lifetime aggregates |
| SerialID | BackOffice.Affiliate | LEFT JOIN | Affiliate record for AffiliateRank |
| BAFF.AffiliateStatusID | Dictionary.AffiliateStatus | LEFT JOIN | Affiliate rank name |
| CountryID | Dictionary.Country | LEFT JOIN | Country name |
| LanguageID | Dictionary.Language | LEFT JOIN | Language name |
| DocumentStatusID | Dictionary.DocumentStatus | LEFT JOIN | Document status name |
| VerificationLevelID | Dictionary.VerificationLevel | LEFT JOIN | KYC level name |
| RegulationID | Dictionary.Regulation (DCRG) | LEFT JOIN | Primary regulation name |
| DesignatedRegulationID | Dictionary.Regulation (DCRG2) | LEFT JOIN | Designated regulation name |
| PlayerStatusID | Dictionary.PlayerStatus | LEFT JOIN | Status + IsBlocked flag |
| RegionID | Dictionary.RegionByIP | LEFT JOIN | Region short name |
| DRBI.ShortName + CountryID | Dictionary.RegionName | LEFT JOIN | Full region/province name |
| SalesStatusID | Dictionary.SalesStatus | LEFT JOIN | Sales status name |
| ManagerID | BackOffice.Manager | LEFT JOIN | Manager name |
| LabelID | Dictionary.Label | LEFT JOIN | White label name |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO application layer) | (direct call) | Application | Called by BO registration report screens and exports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRegistrationReport (procedure)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── BackOffice.Affiliate (table)
├── BackOffice.Manager (table)
├── Dictionary.Country (table)
├── Dictionary.Language (table)
├── Dictionary.Label (table)
├── Dictionary.AffiliateStatus (table)
├── Dictionary.VerificationLevel (table)
├── Dictionary.DocumentStatus (table)
├── Dictionary.Regulation (table - x2)
├── Dictionary.PlayerStatus (table)
├── Dictionary.RegionByIP (table)
├── Dictionary.RegionName (table)
├── Dictionary.SalesStatus (table)
└── Dictionary.PlayerLevel (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary FROM table |
| BackOffice.Customer | Table | LEFT JOIN - BO attributes |
| BackOffice.CustomerAllTimeAggregatedData | Table | LEFT JOIN - lifetime aggregates |
| BackOffice.Affiliate | Table | LEFT JOIN via SerialID for affiliate info |
| BackOffice.Manager | Table | LEFT JOIN via ManagerID for manager name |
| Dictionary.* (multiple) | Table | LEFT JOIN for name lookups |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| STRING_SPLIT for lists | Implementation | @AffiliateID, @Regulations, @DesignatedRegulations, @WhiteLabels, @ProvinceIds use STRING_SPLIT - requires SQL Server 2016+. Not parameterized dynamic SQL. |
| @DownloadID wildcard | Logic | * in @DownloadID is replaced with % for LIKE matching - supports simple wildcard without full regex |
| @SingleManager dependency | Logic | @ManagerID filter only applies when @SingleManager = 1; if @SingleManager = 1 but @ManagerID IS NULL, no manager filter is applied |

---

## 8. Sample Queries

### 8.1 Registration report for UK customers in 2025 by a specific regulation
```sql
EXEC [BackOffice].[GetRegistrationReport]
    @RegisteredAfter = '20250101',
    @RegisteredBefore = '20251231',
    @CountryID = 235,  -- United Kingdom
    @Regulations = '3',
    @PlayerLevelID = NULL,
    @PlayerStatusID = NULL,
    @SingleManager = 0
```

### 8.2 All customers for a specific affiliate
```sql
EXEC [BackOffice].[GetRegistrationReport]
    @AffiliateID = '12345,67890',
    @RegisteredAfter = NULL,
    @RegisteredBefore = NULL
```

### 8.3 Customers assigned to a specific manager
```sql
EXEC [BackOffice].[GetRegistrationReport]
    @SingleManager = 1,
    @ManagerID = 42,
    @RegisteredAfter = NULL,
    @RegisteredBefore = NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRegistrationReport | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRegistrationReport.sql*
