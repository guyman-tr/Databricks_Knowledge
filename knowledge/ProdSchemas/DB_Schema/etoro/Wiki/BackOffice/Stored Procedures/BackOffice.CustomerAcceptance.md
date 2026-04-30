# BackOffice.CustomerAcceptance

> Reports First-Time Depositors (FTDs) within a date window for BackOffice acceptance and compliance review, with optional filters for regulation, acceptance status, and white label; returns a rich customer profile result set.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (date range) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a compliance and customer acceptance reporting tool used by BackOffice acceptance teams. It identifies customers who made their First-Time Deposit (FTD) within the specified date range and returns a comprehensive profile row for each, combining data from across the platform: customer identity, regulatory jurisdiction, deposit method, total deposits, risk status, verification level, acceptance status, white label, and account type.

The output is used by BackOffice analysts to review new depositors for compliance acceptance - verifying that recently-deposited customers have been properly vetted, classified by acceptance status, and assigned to the correct regulatory jurisdiction. The `AcceptanceStatusID` in BackOffice.Customer tracks whether a customer has passed the acceptance workflow; this report surfaces customers in specific acceptance stages for bulk review.

The optional filter parameters (@RegulationIDs, @AcceptanceStatusIDs, @WhiteLabels) accept comma-delimited ID lists, enabling multi-value filtering. Dynamic SQL is used to conditionally INNER JOIN temp tables for active filters, improving query plan performance over IN-clause string splitting in the main WHERE clause.

---

## 2. Business Logic

### 2.1 FTD Detection

**What**: Identifies the first credited deposit for each customer within the date range.

**Columns/Parameters Involved**: `History.Credit.CreditTypeID`, `History.Credit.Occurred`, `Billing.Deposit.FundingID`, `@StartDate`, `@EndDate`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Occurred) to find deposit number per customer
- Filters History.Credit WHERE CreditTypeID=1 (standard deposit credits) AND Occurred BETWEEN @StartDate AND @EndDate
- Joins to Billing.Deposit to retrieve FundingID (for payment method lookup)
- Only DepositNumber=1 rows (first ever credit) are included in #FTDs CTE
- The outer WHERE also filters Occurred BETWEEN @StartDate AND @EndDate, confirming the FTD date falls within the window

### 2.2 Dynamic SQL Multi-Filter Pattern

**What**: Optional filters are applied via INNER JOIN to temp tables, dynamically constructed before execution.

**Columns/Parameters Involved**: `@RegulationIDs`, `@AcceptanceStatusIDs`, `@WhiteLabels`, `@IgnorePlayerLevelID`

**Rules**:
- Each optional parameter: if NOT NULL -> STRING_SPLIT into temp table (#RegulationIDs, #AcceptanceStatusIDs, #WhiteLabels) -> INNER JOIN appended to dynamic SQL
- @IgnorePlayerLevelID (default=0): if ISNULL(@IgnorePlayerLevelID, -1) >= 0 -> adds WHERE CCST.PlayerLevelID <> @IgnorePlayerLevelID; effectively excludes test or inactive players
  - Default=0 excludes PlayerLevelID=0 customers from results
  - Pass -1 or NULL to disable the PlayerLevelID filter
- Dynamic SQL is executed via sp_executesql with parameterized inputs (safe from injection)

### 2.3 Risk Status Aggregation

**What**: Uses BackOffice.GetUserRisksByCID function instead of a simple lookup.

**Columns/Parameters Involved**: `BackOffice.GetUserRisksByCID`, `DRST.RiskStatusesNames`

**Rules**:
- OUTER APPLY BackOffice.GetUserRisksByCID(CCST.CID) -> returns RiskStatusesNames (aggregated risk status names)
- This replaces the simple Dictionary.RiskStatus JOIN (visible in commented-out code): the function handles customers with multiple risk flags, returning a combined string

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the FTD date window. Filters History.Credit.Occurred >= @StartDate for first-time deposit detection. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the FTD date window. Filters History.Credit.Occurred <= @EndDate. |
| 3 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | PlayerLevelID value to exclude from results (WHERE CustomerStatic.PlayerLevelID <> @IgnorePlayerLevelID). Default=0 excludes PlayerLevelID=0. Pass NULL or -1 to disable this filter. |
| 4 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-delimited list of RegulationIDs to filter by (e.g., '1,2,4'). NULL = no regulation filter. Parsed via STRING_SPLIT into temp table, joined as INNER JOIN. |
| 5 | @AcceptanceStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-delimited list of AcceptanceStatusIDs to filter by. NULL = no acceptance status filter. Parsed via STRING_SPLIT into temp table, joined as INNER JOIN. |
| 6 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-delimited list of LabelIDs (white label) to filter by. NULL = no white label filter. Parsed via STRING_SPLIT into temp table, joined as INNER JOIN. |

**Result Set - FTD Customer Acceptance Report:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 7 | Acceptance Status | Dictionary.AcceptanceStatus.Name | Customer's current acceptance workflow stage name |
| 8 | CID | #FTDs.CID | Customer ID |
| 9 | First Name | Customer.CustomerStatic.FirstName | Customer's first name |
| 10 | Middle Name | Customer.CustomerStatic.MiddleName | Customer's middle name |
| 11 | Last Name | Customer.CustomerStatic.LastName | Customer's last name |
| 12 | Registration Country | Dictionary.Country.Name (via CountryID) | Country the customer registered from |
| 13 | Last Login Country | Internal.GetCountryNameByIP(History.Login.IP) | Country of most recent login, resolved from IP |
| 14 | FTD Date | History.Credit.Occurred | Date/time of the customer's first credited deposit |
| 15 | Deposit Method | Dictionary.FundingType.Name | Payment method used for the FTD (card, wire, crypto, etc.) |
| 16 | Total Deposits | BackOffice.CustomerAllTimeAggregatedData.TotalDeposit | Cumulative deposit amount to date (DECIMAL(16,2)) |
| 17 | Risk Status | BackOffice.GetUserRisksByCID.RiskStatusesNames | Aggregated risk status label(s) from BackOffice.GetUserRisksByCID function |
| 18 | Customer Status | Dictionary.PlayerStatus.Name | Account status label (active, suspended, etc.) |
| 19 | Verification Level | Dictionary.VerificationLevel.Name | KYC verification tier name (Level 0-3) |
| 20 | White Label | Dictionary.Label.Name | White label / platform brand the customer is under |
| 21 | Account Type | Dictionary.AccountType.AccountTypeName | Account type (Retail, Professional, etc.) |
| 22 | Master Account | Customer.Customer: CID + FirstName + LastName | Master account identifier if this is a sub-account; format: "CID FirstName LastName" |
| 23 | ThirdPartyManagerComment | BackOffice.Customer.ThirdPartyManagerComment | Internal comment from BackOffice operator |
| 24 | Comments | Customer.CustomerStatic.Comments | Customer-facing comments on the account |
| 25 | Regulation | Dictionary.Regulation.Name | Regulatory jurisdiction name (CySEC, FCA, ASIC, etc.) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | History.Credit | Lookup (SELECT) | FTD detection - CreditTypeID=1 with ROW_NUMBER() (cross-schema) |
| FundingID | Billing.Deposit | Lookup (JOIN) | Retrieves FundingID for payment method resolution (cross-schema) |
| FundingID | Billing.Funding | Lookup (JOIN) | Resolves FundingTypeID for Deposit Method column (cross-schema) |
| CID | Customer.CustomerStatic | Lookup (JOIN) | Customer identity, country, label, player status, comments (cross-schema) |
| CID | BackOffice.Customer | Lookup (JOIN) | VerificationLevelID, RegulationID, AcceptanceStatusID, AccountTypeID, MasterAccountCID |
| CID | BackOffice.CustomerAllTimeAggregatedData | Lookup (LEFT JOIN) | TotalDeposit for Total Deposits column |
| CID | BackOffice.GetUserRisksByCID | Lookup (OUTER APPLY) | Aggregated risk status names |
| CID | History.Login | Lookup (OUTER APPLY TOP 1) | Most recent login IP for Last Login Country (cross-schema) |
| IP | Internal.GetCountryNameByIP | Function call | Resolves IP to country name for Last Login Country |
| CID | Customer.Customer | Lookup (LEFT JOIN) | Master account CID, FirstName, LastName for Master Account column (cross-schema) |
| Various IDs | Dictionary.* tables | Lookup (LEFT JOIN) | Name resolution for AcceptanceStatus, Country, FundingType, VerificationLevel, Regulation, PlayerStatus, Label, AccountType |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice compliance/acceptance reporting UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerAcceptance (procedure)
|- History.Credit (table) [FTD detection - CreditTypeID=1, cross-schema]
|- Billing.Deposit (table) [FundingID for payment method, cross-schema]
|- Billing.Funding (table) [FundingTypeID resolution, cross-schema]
|- Customer.CustomerStatic (table) [customer identity and attributes, cross-schema]
|- BackOffice.Customer (table) [VerificationLevel, Regulation, AcceptanceStatus, AccountType]
|- BackOffice.CustomerAllTimeAggregatedData (table) [TotalDeposit]
|- BackOffice.GetUserRisksByCID (function) [aggregated risk status names]
|- History.Login (table) [last login IP, cross-schema]
|- Customer.Customer (table) [master account name, cross-schema]
|- Internal.GetCountryNameByIP (function) [IP to country name, cross-schema]
+-- Dictionary.* (tables) [AcceptanceStatus, Country, FundingType, VerificationLevel, Regulation, PlayerStatus, Label, AccountType - all cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | FTD detection: CreditTypeID=1, ROW_NUMBER() to find first deposit per customer |
| Billing.Deposit | Table | JOIN to get FundingID from DepositID |
| Billing.Funding | Table | JOIN to get FundingTypeID for Deposit Method |
| Customer.CustomerStatic | Table | Customer identity, CountryID, LabelID, PlayerStatusID, Comments |
| BackOffice.Customer | Table | VerificationLevelID, RegulationID, AcceptanceStatusID, AccountTypeID, MasterAccountCID, ThirdPartyManagerComment |
| BackOffice.CustomerAllTimeAggregatedData | Table | TotalDeposit (cumulative) |
| BackOffice.GetUserRisksByCID | Function | OUTER APPLY to get aggregated risk status names |
| History.Login | Table | OUTER APPLY TOP 1 ORDER BY LoginID DESC for last login IP |
| Customer.Customer | Table | Master account CID, FirstName, LastName |
| Internal.GetCountryNameByIP | Function | IP to country name resolution |
| Dictionary.AcceptanceStatus | Table | Name for AcceptanceStatusID |
| Dictionary.Country | Table | Name for CountryID (registration country) |
| Dictionary.FundingType | Table | Name for FundingTypeID (deposit method) |
| Dictionary.VerificationLevel | Table | Name for VerificationLevelID |
| Dictionary.Regulation | Table | Name for RegulationID |
| Dictionary.PlayerStatus | Table | Name for PlayerStatusID (customer status) |
| Dictionary.Label | Table | Name for LabelID (white label) |
| Dictionary.AccountType | Table | AccountTypeName for AccountTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice compliance/acceptance reporting UI | External | Calls this to review FTD customers for acceptance workflow processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Design | Uses sp_executesql to conditionally join temp tables for active filters; parameterized - safe from SQL injection |
| INNER JOIN for filters | Design | Optional filters (RegulationIDs, AcceptanceStatusIDs, WhiteLabels) use INNER JOIN to temp tables rather than IN subqueries, improving plan quality |
| IgnorePlayerLevelID default=0 | Business | By default excludes PlayerLevelID=0 customers; pass NULL or -1 to see all players |
| CreditTypeID=1 | Business | Only standard deposit credits counted as FTDs; bonuses, compensation, and other credit types excluded |
| DepositNumber=1 | Business | Only the FIRST credited deposit per customer defines the FTD; subsequent deposits are ignored |

---

## 8. Sample Queries

### 8.1 Get FTD report for UK (FCA) customers yesterday

```sql
EXEC BackOffice.CustomerAcceptance
    @StartDate = '2026-03-16 00:00:00',
    @EndDate = '2026-03-16 23:59:59',
    @RegulationIDs = '2',          -- 2 = FCA (UK)
    @IgnorePlayerLevelID = 4       -- exclude test users (PlayerLevelID=4)
```

### 8.2 Get FTDs pending acceptance review across EU and AU

```sql
EXEC BackOffice.CustomerAcceptance
    @StartDate = '2026-03-01 00:00:00',
    @EndDate = '2026-03-17 23:59:59',
    @RegulationIDs = '1,4',         -- 1=CySEC, 4=ASIC
    @AcceptanceStatusIDs = '2,3',   -- pending/in-review acceptance statuses
    @IgnorePlayerLevelID = NULL     -- include all player levels
```

### 8.3 Get all FTDs for a white label platform this month

```sql
EXEC BackOffice.CustomerAcceptance
    @StartDate = '2026-03-01 00:00:00',
    @EndDate = '2026-03-31 23:59:59',
    @WhiteLabels = '42',            -- white label ID 42
    @IgnorePlayerLevelID = 0        -- default: exclude PlayerLevelID=0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerAcceptance | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerAcceptance.sql*
