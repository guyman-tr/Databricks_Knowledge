# Compliance.GetPOADocumentsExpirationPopulationFor3Years

> Returns the population of customers whose Proof of Address (POA) documents will expire within the next month, calculating expiry as 3 years from the document's upload or issue date, used to trigger re-verification campaigns.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate, @IsInternal (inputs); CID, GCID (outputs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies customers whose Proof of Address (POA) documents are approaching expiry - calculated as 3 years from when the document was uploaded (or its stated issue date if upload date is unavailable). Under KYC (Know Your Customer) and AML (Anti-Money Laundering) regulations, eToro must maintain current, unexpired customer identity documentation. When a POA document reaches its 3-year expiry window, the customer must be notified and asked to re-upload fresh documentation.

This is the primary data feed for POA expiration notification campaigns. Without it, expired compliance documents would go unnoticed, creating regulatory risk and potentially requiring account restrictions for customers with lapsed verification. The procedure was created on 08/12/2021 by Andrii Aksani for ticket COAKV-3897 "Create new version of the GetPOADocumentsExpirationPopulation SP", replacing an earlier version with a 3-year window logic and regulation exclusion capability.

The caller provides a start date defining the beginning of the expiration window; the end date is automatically set to 1 month from today (UTC). The procedure is designed for scheduled notification jobs and supports both external customers (standard) and internal employees (via @IsInternal flag). Specific regulatory populations (e.g., certain jurisdictions) can be excluded via @ExcludeRegulationIDs.

---

## 2. Business Logic

### 2.1 POA Document 3-Year Expiry Calculation

**What**: Determines when a Proof of Address document expires by adding 3 years to its effective date.

**Columns/Parameters Involved**: `CDTDT.Occurred`, `CDTDT.IssueDate`, `ExpiryDate`

**Rules**:
- ExpiryDate = `DATEADD(year, 3, COALESCE(CDTDT.Occurred, CDTDT.IssueDate))`
- Prefers `Occurred` (the date the document was uploaded/processed in the system) over `IssueDate` (the date printed on the document itself)
- Only DocumentTypeID=1 (Proof of Address) documents are considered
- Documents that have been rejected (`RejectReasonID IS NOT NULL`) are excluded - only accepted documents count
- Obsolete documents (`CD.Obsolete = 1`) are excluded
- Window: returns customers where `ExpiryDate > @StartDate AND ExpiryDate <= @EndDate` where @EndDate = 1 month from today

**Diagram**:
```
Document uploaded/processed (Occurred)  OR  Issue date on document (IssueDate)
              |
              COALESCE -> use Occurred if available, else IssueDate
              |
              +3 years = ExpiryDate
              |
Is ExpiryDate in the window (@StartDate, GETUTCDATE()+1month]?
  YES -> include in population
  NO  -> exclude
```

### 2.2 Latest Document Per Customer (Deduplication)

**What**: When a customer has multiple POA documents, only the one with the latest expiry date is returned.

**Columns/Parameters Involved**: `RowNumber`, `CID`, `ExpiryDate`

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY CD.CID ORDER BY ExpiryDate DESC)` assigns rank 1 to the latest-expiring document per customer
- Outer WHERE filters to `RowNumber = 1` - only the most recently expiring POA per CID
- This prevents duplicate notifications when a customer has submitted multiple POA documents over time

### 2.3 Customer Eligibility Filters

**What**: Restricts the population to customers who are active, verified, FTD-confirmed, and within scope.

**Columns/Parameters Involved**: `@IsInternal`, `@ExcludeRegulationIDs`, `VerificationLevelID`, `AccountTypeID`, `EvMatchStatus`, `PlayerStatusID`, `PlayerLevelID`, `IsFTD`

**Rules**:
- **Verification level**: `VerificationLevelID IN (2, 3)` - customers must be at Level 2 or 3 (partially or fully verified); unverified (Level 0/1) customers are excluded
- **Account type**: `AccountTypeID NOT IN (2, 4)` - excludes Corporate (2) and Joint Account (4) types; POA expiry campaigns target individual retail accounts only
- **Electronic verification**: `EvMatchStatus NOT IN (2)` - excludes customers whose identity was confirmed via electronic verification match (they do not require manual POA re-submission)
- **Regulation exclusion**: `DesignatedRegulationID NOT IN (@ExcludeRegulationIDs)` - allows callers to exclude specific regulatory populations (e.g., jurisdictions with different document rules)
- **Block status**: `PlayerStatusID NOT IN (SELECT PlayerStatusID FROM Dictionary.PlayerStatus WHERE IsBlocked=1)` - excludes all blocked customers (Blocked=2, Blocked Upon Request=4, Blocked-Under Investigation=6, Scalpers Block=7, Blocked-PayPal Investigation=8, Blocked-Failed Verification=14)
- **Internal/External split**: `@IsInternal=0` -> `PlayerLevelID != 4` (external/regular customers); `@IsInternal=1` -> `PlayerLevelID = 4` (internal eToro employees)
- **FTD requirement**: Customer must have at least one First Time Deposit (`Billing.Deposit WHERE IsFTD=1`) - excludes users who registered but never funded

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Beginning of the expiration window. Documents whose calculated ExpiryDate falls after this date and within 1 month of today are returned. Typically set to the last run date of the notification job to capture newly-entering-expiry customers. |
| 2 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = return external/regular customers (PlayerLevelID != 4); 1 = return internal eToro employees (PlayerLevelID = 4). Allows separate notification campaigns for staff vs retail customers. |
| 3 | @ExcludeRegulationIDs | dbo.IdIntList (table type) | NO (READONLY) | - | CODE-BACKED | Table-valued parameter containing regulation IDs to exclude from results. Customers whose `BackOffice.Customer.DesignatedRegulationID` matches any ID in this list are omitted. Used to scope campaigns to specific regulatory populations. |

**Return Result Set**:

| # | Column | Type | Nullable | Default | Confidence | Description |
|---|--------|------|----------|---------|------------|-------------|
| R1 | RowNumber | INT | NO | - | CODE-BACKED | Always 1 in the returned set (outer filter). Identifies this as the latest-expiring POA document per customer. |
| R2 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic - eToro's universal cross-system customer identifier. |
| R3 | CID | INT | NO | - | CODE-BACKED | eToro per-entity customer ID. |
| R4 | DocumentToDocumentTypeID | INT | NO | - | CODE-BACKED | PK of the BackOffice.CustomerDocumentToDocumentType record - uniquely identifies the POA document-type assignment row. |
| R5 | DocumentID | INT | NO | - | CODE-BACKED | PK of the BackOffice.CustomerDocument record - identifies the actual uploaded document. |
| R6 | DocumentTypeID | TINYINT | NO | - | CODE-BACKED | Always 1 (Proof of Address) for all rows in this result. See [Document Type](_glossary.md#document-type). |
| R7 | IssueDate | DATE | YES | - | CODE-BACKED | The date printed on the physical document (e.g., utility bill date). Used as fallback for ExpiryDate calculation when Occurred is NULL. |
| R8 | ExpiryDate | DATETIME | NO | - | CODE-BACKED | Computed: DATEADD(year, 3, COALESCE(Occurred, IssueDate)). The date when the POA document is considered expired and must be re-submitted. |
| R9 | FundingID | INT | YES | - | CODE-BACKED | Reference to the funding/deposit associated with this document submission (from BackOffice.CustomerDocumentToDocumentType). |
| R10 | ManagerID | INT | YES | - | CODE-BACKED | The back-office manager who reviewed/approved this document. |
| R11 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment added during document review. |
| R12 | RejectReasonID | INT | YES | - | CODE-BACKED | Always NULL in the returned set (rejected documents are excluded by the WHERE filter). |
| R13 | RejectEmailSent | BIT | YES | - | CODE-BACKED | Whether a rejection email was sent for this document. Always 0/NULL in results since rejected docs are excluded. |
| R14 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer's username from Customer.CustomerStatic. Included for notification targeting. |
| R15 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer's email address from Customer.CustomerStatic. Used by notification systems to send the expiry reminder. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentID | BackOffice.CustomerDocument | JOIN | Source of document metadata and CID |
| DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | JOIN (primary source) | Source of document type, dates (Occurred, IssueDate), and review metadata |
| CID | BackOffice.Customer | JOIN | Filters customers by verification level, account type, EvMatchStatus, and regulation |
| CID | Customer.CustomerStatic | JOIN | Filters by block status and PlayerLevelID; provides GCID, UserName, Email |
| PlayerStatusID | Dictionary.PlayerStatus | Lookup | Blocked player status IDs used in exclusion filter |
| CID | Billing.Deposit | EXISTS subquery | Verifies customer has made at least one First Time Deposit (IsFTD=1) |
| ID | @ExcludeRegulationIDs (dbo.IdIntList) | Parameter filter | Regulation IDs to exclude from results |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325 | - | Deprecated predecessor | Legacy 1-year/15-day SP that this replaces. That SP also attempted to INSERT into a now-missing table (RUNTIME ERROR if called). See its documentation for migration comparison. |
| Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325 | - | Deprecated predecessor | Same legacy logic as GCID variant but without the broken INSERT. Both deprecated in favor of this SP. Use this SP with the @ExcludeRegulationIDs TVP. |
| (external callers) | - | EXECUTE | Called by external compliance notification jobs/services. No SQL callers found in the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetPOADocumentsExpirationPopulationFor3Years (procedure)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
├── BackOffice.Customer (table)
├── Customer.CustomerStatic (table)
├── Dictionary.PlayerStatus (table) - subquery for blocked status IDs
├── Billing.Deposit (table) - EXISTS for FTD check
└── dbo.IdIntList (UDT) - READONLY table-valued parameter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Primary source - DocumentTypeID, dates, FundingID, ManagerID, Comment, RejectReasonID |
| BackOffice.CustomerDocument | Table | JOINed to get CID and Obsolete flag |
| BackOffice.Customer | Table | JOINed to filter VerificationLevelID, AccountTypeID, EvMatchStatus, DesignatedRegulationID |
| Customer.CustomerStatic | Table | JOINed to filter PlayerStatusID/PlayerLevelID and get GCID, UserName, Email |
| Dictionary.PlayerStatus | Table | Subquery to get blocked PlayerStatusIDs (IsBlocked=1) |
| Billing.Deposit | Table | EXISTS subquery to verify customer has at least one FTD |
| dbo.IdIntList | User Defined Type | Table-valued parameter type for @ExcludeRegulationIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT repo) | - | Called by external compliance notification services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DocumentTypeID = 1 | Application logic | Restricts to Proof of Address documents only |
| RejectReasonID IS NULL | Application logic | Excludes rejected documents - only accepted POAs count for compliance purposes |
| CD.Obsolete != 1 | Application logic | Excludes superseded/obsolete document records |
| IsFTD = 1 | Application logic | Requires at least one First Time Deposit - unfunded accounts are excluded from compliance campaigns |

---

## 8. Sample Queries

### 8.1 Run for documents expiring between now and 1 month

```sql
DECLARE @ExcludeRegs dbo.IdIntList;
-- Optionally INSERT INTO @ExcludeRegs VALUES (9) to exclude FSA Seychelles

EXEC [Compliance].[GetPOADocumentsExpirationPopulationFor3Years]
    @StartDate = GETUTCDATE(),
    @IsInternal = 0,
    @ExcludeRegulationIDs = @ExcludeRegs;
```

### 8.2 Run for internal employees only

```sql
DECLARE @ExcludeRegs dbo.IdIntList;
EXEC [Compliance].[GetPOADocumentsExpirationPopulationFor3Years]
    @StartDate = GETUTCDATE(),
    @IsInternal = 1,
    @ExcludeRegulationIDs = @ExcludeRegs;
```

### 8.3 Check how many customers have POA documents expiring this month

```sql
SELECT COUNT(DISTINCT CD.CID) AS CustomersWithExpiringPOA,
       MIN(DATEADD(year, 3, COALESCE(CDTDT.Occurred, CDTDT.IssueDate))) AS EarliestExpiry,
       MAX(DATEADD(year, 3, COALESCE(CDTDT.Occurred, CDTDT.IssueDate))) AS LatestExpiry
FROM [BackOffice].[CustomerDocumentToDocumentType] CDTDT WITH (NOLOCK)
JOIN [BackOffice].[CustomerDocument] CD WITH (NOLOCK) ON CDTDT.DocumentID = CD.DocumentID
WHERE CDTDT.DocumentTypeID = 1
  AND CDTDT.RejectReasonID IS NULL
  AND CD.Obsolete != 1
  AND DATEADD(year, 3, COALESCE(CDTDT.Occurred, CDTDT.IssueDate)) BETWEEN GETUTCDATE() AND DATEADD(month, 1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in TRAD space for this object. DDL comment identifies origin: ticket COAKV-3897 "Create new version of the GetPOADocumentsExpirationPopulation SP" (2021-12-08, Andrii Aksani).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetPOADocumentsExpirationPopulationFor3Years | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.sql*
