# BackOffice.GetBlockedCustomers

> Returns customers with specific player statuses (blocked/frozen) whose status changed within a date range, enriched with KYC document approval status, risk status, financial summary, and pending closure state - the primary blocked-customer report in BackOffice.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IDs (player status filter TVP) + @StartDate/@EndDate (status change date range); returns one row per customer with latest status change in window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetBlockedCustomers` is the main blocked/flagged customer report in BackOffice. It returns customers whose player status matches a given set (e.g., blocked, frozen, under review) AND whose status last changed within a specified date window. Compliance and back-office agents use this report to review customers that were recently blocked, work their queue, and check KYC/document status.

The procedure is more than a simple filter: it aggregates multi-dimensional status information per customer:
- **Document verification status**: POI (Proof of Identity, DocumentTypeID=2) and POA (Proof of Address, DocumentTypeID=1) approval flags via correlated EXISTS checks
- **Risk status**: OUTER APPLY to `BackOffice.GetUserRisksByCID_V2` (table-valued function) to get current multi-risk status string
- **Financial standing**: Total deposits from CustomerAllTimeAggregatedData, current balance from Credit
- **Open positions count**: Correlated COUNT from Trade.Position
- **Status history date**: RANK() OVER PARTITION BY History.Customer to find the most recent player status change

The use of OUTER APPLY to the TVF `BackOffice.GetUserRisksByCID_V2` is notable - it calls a per-customer function for every row, making this report potentially slow for large result sets. The commented-out alternative was a direct JOIN to `Dictionary.RiskStatus`.

**@IDs parameter**: When the TVP contains entries, only customers with those PlayerStatusIDs are returned. When empty (COUNT=0), ALL player statuses are included (the "show all" mode).

---

## 2. Business Logic

### 2.1 TVP Filter Pattern (Empty = All)

**What**: All three TVP parameters follow the same "empty means no filter" pattern.

**Columns/Parameters Involved**: `@IDs`, `@PlayerStatusReasonIDs`, `@PlayerStatusSubReasonIDs`

**Rules**:
- `CCST.PlayerStatusID IN (SELECT ID FROM @IDs) OR (SELECT COUNT(*) FROM @IDs) = 0` - if TVP is empty, condition is always true.
- Same pattern for @PlayerStatusReasonIDs and @PlayerStatusSubReasonIDs.
- This means passing empty TVPs for all three returns all active (non-closed) customers with any player status who had a status change in the date window.

### 2.2 Active Account Filter

**What**: Only customers with open accounts (AccountStatusID IS NULL or =1) are included.

**Columns/Parameters Involved**: `CCST.AccountStatusID`

**Rules**:
- `CCST.AccountStatusID IS NULL OR CCST.AccountStatusID = 1` - NULL is treated as Open (1).
- AccountStatusID=2 = Closed - explicitly excluded.
- Consistent with GetAccountStatusID procedure (ISNULL(AccountStatusID,1) = 1 for open).

### 2.3 Status Change Date Window (RANK-Based)

**What**: The date window filters based on when a customer's player status last changed, not when they were blocked.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `HCST.ValidTo`, `HCST.CustomerVersionID`, `Ranking`

**Rules**:
- LEFT JOIN History.Customer (HCST) ON CID AND `HCST.PlayerStatusID <> CCST.PlayerStatusID` AND ValidTo in [@StartDate, @EndDate].
- RANK() OVER (PARTITION BY HCST.CID ORDER BY CustomerVersionID DESC) - finds the most recent history entry where the status differed.
- Final WHERE: `Ranking IS NULL OR Ranking=1` - Ranking IS NULL means no history record existed in the window (customer has never changed status, registered date used as fallback).
- `ISNULL(ValidTo, Registered) >= @StartDate AND ISNULL(ValidTo, Registered) <= @EndDate` - date range applied to both the history change date and the registration date for new customers without history.
- `ISNULL(ValidTo, Registered)` AS [Date Changed] in output shows the most recent relevant date.

### 2.4 POI Approved Correlated EXISTS

**What**: Checks if the customer has a valid, non-expired POI document.

**Columns/Parameters Involved**: `POIApproved`, `CustomerDocumentToDocumentType.DocumentTypeID=2`, `ExpiryDate`

**Rules**:
- DocumentTypeID=2 = Proof of Identity.
- Must be non-obsolete (Obsolete != 1), have an ExpiryDate, and ExpiryDate > GETDATE().
- Returns 'Yes' if any qualifying POI exists, 'No' otherwise.
- An expired POI returns 'No' even if a document was uploaded.

### 2.5 POA Approved Correlated EXISTS

**What**: Checks if the customer has a valid, non-expired POA document within the type's MaxAgeInMonths.

**Columns/Parameters Involved**: `POAApproved`, `CustomerDocumentToDocumentType.DocumentTypeID=1`, `IssueDate`, `Dictionary.DocumentType.MaxAgeInMonths`

**Rules**:
- DocumentTypeID=1 = Proof of Address.
- Must be non-obsolete (Obsolete <> 1), have an IssueDate.
- `DDT.MaxAgeInMonths >= DateDiff(MM, IssueDate, GetDate())` - document must not be older than the type's maximum accepted age in months.
- Returns 'Yes' if any qualifying POA exists.

### 2.6 New Uploaded Files (Unclassified Documents)

**What**: Count of uploaded documents that have no classification yet.

**Columns/Parameters Involved**: `NumberofNewUploadedFiles`, `CustomerDocument`, `CustomerDocumentToDocumentType`

**Rules**:
- LEFT JOIN CustomerDocumentToDocumentType; WHERE DocumentID IS NULL (LEFT JOIN produces NULL = no classification exists).
- Excludes Obsolete documents (Obsolete != 1).
- This is the unreviewed document count in the agent's queue.

### 2.7 SubReason IIF Logic

**What**: PlayerStatusSubReasonID=0 is treated as "no sub-reason, use the comment instead."

**Columns/Parameters Involved**: `CCST.PlayerStatusSubReasonID`, `CCST.PlayerStatusSubReasonComment`

**Rules**:
- `IIF(CCST.PlayerStatusSubReasonID=0, CCST.PlayerStatusSubReasonComment, (SELECT Name FROM Dictionary.PlayerStatusSubReasons WHERE PlayerStatusSubReasonID=CCST.PlayerStatusSubReasonID))` AS CustomerStatusSubReason.
- When SubReasonID=0 (sentinel for "free text"), the agent's typed comment is shown.
- When SubReasonID>0, the lookup value is shown.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | TVP of PlayerStatusIDs to filter (e.g., 2=Blocked, 4=Frozen). Empty TVP returns all active customers. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the player status change date window (inclusive). Filters History.Customer.ValidTo >= @StartDate. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the player status change date window (inclusive). Filters History.Customer.ValidTo <= @EndDate. |
| 4 | @PlayerStatusReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional TVP of PlayerStatusReasonIDs. Empty = all reasons. Filters alongside @IDs. |
| 5 | @PlayerStatusSubReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional TVP of PlayerStatusSubReasonIDs. Empty = all sub-reasons. |
| 6 | Select.. | BIT | NO | 0 | CODE-BACKED | Always CAST(0 AS BIT). UI checkbox column placeholder for row selection in BackOffice grid. |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer Identifier. From Customer.Customer. |
| 8 | User Name | NVARCHAR | YES | - | CODE-BACKED | Customer login/username. From Customer.Customer.UserName. |
| 9 | First Name | NVARCHAR | YES | - | CODE-BACKED | Customer first name. From Customer.Customer.FirstName. |
| 10 | Last Name | NVARCHAR | YES | - | CODE-BACKED | Customer last name. From Customer.Customer.LastName. |
| 11 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Current player status name (LTRIM/RTRIM applied). From Dictionary.PlayerStatus.Name. |
| 12 | Reason | NVARCHAR | YES | - | CODE-BACKED | Player status reason name. From Dictionary.PlayerStatusReasons.Name. NULL if no reason set. |
| 13 | SubReason | NVARCHAR | YES | - | CODE-BACKED | Player status sub-reason. If SubReasonID=0: free-text comment. If SubReasonID>0: Dictionary.PlayerStatusSubReasons.Name. |
| 14 | Days From FTD | INT | YES | - | CODE-BACKED | Days elapsed since First Time Deposit. DateDiff(DD, FirstTimeDepositSuccessDate, GetDate()). From CustomerAllTimeAggregatedData. NULL if no FTD. |
| 15 | Number of Open Positions | INT | NO | - | CODE-BACKED | Count of open trading positions. Correlated COUNT from Trade.Position WHERE CID=CCST.CID. |
| 16 | Balance | MONEY | YES | - | CODE-BACKED | Current account balance (credit). From Customer.Customer.Credit. |
| 17 | Pending Closure Status | NVARCHAR | YES | - | CODE-BACKED | Pending closure state (LTRIM/RTRIM). ISNULL(..., 'No') defaults to 'No' if no pending closure. From Dictionary.PendingClosureStatus.PendingClosureStatusName. |
| 18 | Risk Status | NVARCHAR | YES | - | CODE-BACKED | Comma-separated or multi-value risk status string from BackOffice.GetUserRisksByCID_V2 TVF. RiskStatusesNames column. |
| 19 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction name. From Dictionary.Regulation.Name via BackOffice.Customer.RegulationID. |
| 20 | Document Status | NVARCHAR | YES | - | CODE-BACKED | KYC document review status name. From Dictionary.DocumentStatus.DocumentStatusName via BackOffice.Customer.DocumentStatusID. |
| 21 | Country By Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Country from registration form. From Dictionary.Country.Name via Customer.Customer.CountryID. |
| 22 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Player level (e.g., Standard, Silver, Gold). LTRIM/RTRIM. From Dictionary.PlayerLevel.Name via Customer.Customer.PlayerLevelID. |
| 23 | Date Changed | DATETIME | YES | - | CODE-BACKED | Date of last player status change. ISNULL(History.Customer.ValidTo, Customer.Customer.Registered) - falls back to registration date for new customers. |
| 24 | Comment | NVARCHAR | NO | '' | CODE-BACKED | BackOffice comment on the customer. ISNULL(Comments, ''). From Customer.Customer.Comments. |
| 25 | Total Deposits | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total deposits. CAST from BackOffice.CustomerAllTimeAggregatedData.TotalDeposit. |
| 26 | Manager | NVARCHAR | YES | - | CODE-BACKED | Full name of assigned BackOffice manager. FirstName+' '+LastName from BackOffice.Manager via BackOffice.Customer.ManagerID. NULL if unassigned. |
| 27 | PlayerStatusID | INT | NO | - | CODE-BACKED | Numeric player status ID. Returned for programmatic use by the UI. FK to Dictionary.PlayerStatus. |
| 28 | POI Approved | VARCHAR | NO | - | CODE-BACKED | Whether a valid non-expired Proof of Identity document exists. 'Yes'=valid POI (DocumentTypeID=2, non-obsolete, ExpiryDate>now); 'No'=no valid POI. |
| 29 | POA Approved | VARCHAR | NO | - | CODE-BACKED | Whether a valid non-expired Proof of Address document exists. 'Yes'=valid POA (DocumentTypeID=1, non-obsolete, within MaxAgeInMonths); 'No'=no valid POA. |
| 30 | Number of New Uploaded Files | INT | NO | - | CODE-BACKED | Count of documents uploaded but not yet classified by an agent (LEFT JOIN miss on CustomerDocumentToDocumentType). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IDs / PlayerStatusID | Customer.Customer | Primary source | All active customers filtered by PlayerStatus/reason/date. |
| PlayerStatusID | Dictionary.PlayerStatus | Lookup (INNER JOIN) | Resolves player status to name; also filters by @IDs via JOIN ON condition. |
| CID | BackOffice.CustomerAllTimeAggregatedData | Lookup (INNER JOIN) | Financial aggregates: TotalDeposit, FirstTimeDepositSuccessDate. |
| CID | BackOffice.Customer | Lookup (INNER JOIN) | Document status, regulation, manager assignment. |
| CID | BackOffice.GetUserRisksByCID_V2 | Lookup (OUTER APPLY TVF) | Multi-risk status string per customer. |
| PlayerLevelID | Dictionary.PlayerLevel | Lookup (INNER JOIN) | Customer level label. |
| ManagerID | BackOffice.Manager | Lookup (LEFT JOIN) | Assigned manager full name. |
| PendingClosureStatusID | Dictionary.PendingClosureStatus | Lookup (LEFT JOIN) | Pending closure state. |
| DocumentStatusID | Dictionary.DocumentStatus | Lookup (LEFT JOIN) | Document review status. |
| CountryID | Dictionary.Country | Lookup (LEFT JOIN) | Registration country. |
| RegulationID | Dictionary.Regulation | Lookup (LEFT JOIN) | Regulatory jurisdiction. |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | Lookup (LEFT JOIN) | Status reason name. |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | Lookup (LEFT JOIN) | Status sub-reason (used in IIF). |
| CID | History.Customer | Date history (LEFT JOIN) | Most recent player status change date via RANK(). |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | Document checks (correlated EXISTS + LEFT JOIN) | POI, POA approval and unclassified count. |
| DocumentID | BackOffice.CustomerDocument | Document checks (correlated) | POI/POA: non-obsolete filter. |
| InstrumentID | Dictionary.DocumentType | Document check | MaxAgeInMonths for POA validity. |
| CID | Trade.Position | Count check (correlated) | Number of open trading positions. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice UI for blocked customer management. No SQL procedure callers found in repository. Sister procedure: GetBlockedCustomers_Test_JUNKYulia0325 (identical, deprecated).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetBlockedCustomers (procedure)
├── Customer.Customer (table) [cross-schema]
├── Dictionary.PlayerStatus (table) [cross-schema]
├── BackOffice.CustomerAllTimeAggregatedData (view)
├── BackOffice.Customer (table)
├── BackOffice.GetUserRisksByCID_V2 (TVF) [OUTER APPLY]
├── Dictionary.PlayerLevel (table) [cross-schema]
├── BackOffice.Manager (table)
├── Dictionary.PendingClosureStatus (table) [cross-schema]
├── Dictionary.DocumentStatus (table) [cross-schema]
├── Dictionary.Country (table) [cross-schema]
├── Dictionary.Regulation (table) [cross-schema]
├── Dictionary.PlayerStatusReasons (table) [cross-schema]
├── Dictionary.PlayerStatusSubReasons (table) [cross-schema]
├── History.Customer (table) [cross-schema]
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
├── Dictionary.DocumentType (table) [cross-schema]
└── Trade.Position (table) [cross-schema, correlated COUNT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (cross-schema) | Primary customer record: status, names, credit, level, country. |
| BackOffice.CustomerAllTimeAggregatedData | View | TotalDeposit, FirstTimeDepositSuccessDate aggregates. |
| BackOffice.Customer | Table | Document status, regulation, manager. |
| BackOffice.GetUserRisksByCID_V2 | TVF | OUTER APPLY for multi-risk status string. |
| Dictionary.PlayerStatus | Table | Status name (INNER JOIN + TVP filter). |
| Dictionary.PlayerLevel | Table | Customer level label. |
| BackOffice.Manager | Table | Assigned manager name. |
| History.Customer | Table | Player status change date history (RANK). |
| BackOffice.CustomerDocumentToDocumentType | Table | POI/POA approval checks + unclassified count. |
| BackOffice.CustomerDocument | Table | Non-obsolete document filter for POI/POA. |
| Dictionary.DocumentType | Table | MaxAgeInMonths for POA currency check. |
| Dictionary.PlayerStatusReasons | Table | Status reason name. |
| Dictionary.PlayerStatusSubReasons | Table | Sub-reason name (scalar subquery). |
| Dictionary.PendingClosureStatus | Table | Pending closure status name. |
| Dictionary.DocumentStatus | Table | Document review status name. |
| Dictionary.Country | Table | Registration country. |
| Dictionary.Regulation | Table | Regulatory jurisdiction name. |
| Trade.Position | Table | Open position count (correlated). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetBlockedCustomers_Test_JUNKYulia0325 | Stored Procedure (DEPRECATED) | Identical copy - marked for removal March 2025. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Performance-sensitive due to: OUTER APPLY TVF per row (GetUserRisksByCID_V2), multiple correlated subqueries per row (EXISTS for POI/POA, COUNT for open positions), and RANK() window function on History.Customer.

### 7.2 Constraints

No SET NOCOUNT ON. No SET ANSI_NULLS/QUOTED_IDENTIFIER explicit. NOLOCK on all tables. CTE PreQuery builds the full enriched set, then outer SELECT applies Ranking=1 filter and date range filter. The `Trade.Position` reference is `WITH(NoLock)` without the `NOLOCK` keyword variant - both are equivalent. Commented-out alternative for RiskStatus (was JOIN Dictionary.RiskStatus, now OUTER APPLY TVF).

---

## 8. Sample Queries

### 8.1 Get all blocked customers (any status) for last 7 days
```sql
DECLARE @IDs BackOffice.IDs;
DECLARE @Reasons BackOffice.IDs;
DECLARE @SubReasons BackOffice.IDs;
-- Leave all TVPs empty = no filter
EXEC BackOffice.GetBlockedCustomers
    @IDs = @IDs,
    @StartDate = DATEADD(DAY,-7,GETUTCDATE()),
    @EndDate = GETUTCDATE(),
    @PlayerStatusReasonIDs = @Reasons,
    @PlayerStatusSubReasonIDs = @SubReasons;
```

### 8.2 Get customers blocked with specific player status (e.g., Blocked=3)
```sql
DECLARE @IDs BackOffice.IDs;
INSERT @IDs VALUES (3);  -- Blocked status
DECLARE @Reasons BackOffice.IDs;
DECLARE @SubReasons BackOffice.IDs;
EXEC BackOffice.GetBlockedCustomers
    @IDs = @IDs,
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-01',
    @PlayerStatusReasonIDs = @Reasons,
    @PlayerStatusSubReasonIDs = @SubReasons;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetBlockedCustomers | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetBlockedCustomers.sql*
