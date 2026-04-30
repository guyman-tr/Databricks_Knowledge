# Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325

> **DEPRECATED / JUNK** - Legacy POA document expiration SP using 1-year expiry and a 15-day window. Superseded by `Compliance.GetPOADocumentsExpirationPopulationFor3Years`. Retained for historical reference only; will fail at runtime due to a reference to a missing table.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate, @IsInternal (inputs); CID, GCID (outputs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**DEPRECATED** - This procedure carries the `_JUNKYulia0325` suffix, marking it as a deprecated object retained only for historical reference. It should NOT be called in production. The active replacement is `Compliance.GetPOADocumentsExpirationPopulationFor3Years`.

This was the earlier version of the POA document expiration population procedure, using a 1-year expiry window (from IssueDate or the document's stored ExpiryDate) and a 15-day forward-looking window. It also attempted to INSERT results into `Compliance.POADocumentsExpirationPopulationGCID`, a staging table that no longer exists - calling this procedure will cause a runtime error.

The procedure accumulated three rounds of changes from 2017 to 2019 (adding GCID, excluding EV2 sources, fixing verification status display), but was ultimately replaced in 2021 by the `For3Years` variant which standardizes on 3-year expiry calculated from upload date, not a stored ExpiryDate column.

Key differences from the current `GetPOADocumentsExpirationPopulationFor3Years`:
- Uses 1-year expiry: `COALESCE(ExpiryDate, DATEADD(Year, 1, IssueDate))` - relies on a stored ExpiryDate column or 1-year IssueDate offset (vs. always computing 3 years from Occurred/IssueDate)
- 15-day forward window (vs. 1 month)
- Inserts into now-missing `Compliance.POADocumentsExpirationPopulationGCID` - RUNTIME ERROR
- Filters `VerificationLevelID = 3` only (vs. `IN (2, 3)`)
- Uses `Customer.Customer` table (vs. `Customer.CustomerStatic`)
- Deposit filter: `PaymentStatusID = 2` (Approved deposits) vs. `IsFTD = 1`
- No `@ExcludeRegulationIDs` parameter - cannot exclude specific regulations

---

## 2. Business Logic

### 2.1 Legacy 1-Year Expiry Calculation (Deprecated)

**What**: Used the document's stored ExpiryDate if available, falling back to 1 year from IssueDate.

**Columns/Parameters Involved**: `CDTDT.ExpiryDate`, `CDTDT.IssueDate`, `ExpiryDate`

**Rules**:
- ExpiryDate = `COALESCE(CDTDT.ExpiryDate, DATEADD(Year, 1, CDTDT.IssueDate))`
- This relied on a manually-set `ExpiryDate` column in CustomerDocumentToDocumentType; the newer SP computes it deterministically
- @EndDate = `DATEADD(Day, 15, CAST(GETUTCDATE() AS DATE))` - 15-day window (vs. 1 month in the current SP)

### 2.2 Broken INSERT to Missing Table

**What**: Attempts to persist results to a staging table that no longer exists.

**Rules**:
- `INSERT INTO Compliance.POADocumentsExpirationPopulationGCID (...)` - this table does not exist in the SSDT repo
- This INSERT is NOT commented out (the `/**/` markers are empty comment tokens used as visual separators)
- Calling this SP will raise: "Invalid object name 'Compliance.POADocumentsExpirationPopulationGCID'"

---

## 3. Data Overview

N/A for stored procedure. (Also: will fail at runtime - see Business Logic 2.2)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the expiration window. Documents expiring after this date and within 15 days of today are included (legacy logic). |
| 2 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external/regular customers; 1 = restrict to eToro internal employees (PlayerLevelID=4). Note: legacy logic differs slightly from newer SP - `@IsInternal=0` includes ALL non-internal rather than explicitly excluding PlayerLevelID=4. |

**Return Result Set** (if the SP ran without error):

| # | Column | Type | Nullable | Default | Confidence | Description |
|---|--------|------|----------|---------|------------|-------------|
| R1 | RowNumber | INT | NO | - | CODE-BACKED | Always 1 - latest expiring POA per customer (legacy deduplication logic). |
| R2 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID. |
| R3 | CID | INT | NO | - | CODE-BACKED | eToro customer ID. |
| R4 | DocumentToDocumentTypeID | INT | NO | - | CODE-BACKED | PK of BackOffice.CustomerDocumentToDocumentType. |
| R5 | DocumentID | INT | NO | - | CODE-BACKED | PK of BackOffice.CustomerDocument. |
| R6 | DocumentTypeID | TINYINT | NO | - | CODE-BACKED | Always 1 (POA). See [Document Type](_glossary.md#document-type). |
| R7 | IssueDate | DATE | YES | - | CODE-BACKED | Date printed on the document. |
| R8 | ExpiryDate | DATETIME | NO | - | CODE-BACKED | Computed: COALESCE(stored ExpiryDate, IssueDate + 1 year). Legacy calculation - differs from current SP's 3-year-from-Occurred logic. |
| R9 | FundingID | INT | YES | - | CODE-BACKED | Associated funding record ID. |
| R10 | ManagerID | INT | YES | - | CODE-BACKED | Reviewing back-office manager. |
| R11 | Comment | NVARCHAR | YES | - | CODE-BACKED | Review comment. |
| R12 | RejectReasonID | INT | YES | - | CODE-BACKED | Reject reason (not filtered - may include rejected docs). |
| R13 | RejectEmailSent | BIT | YES | - | CODE-BACKED | Whether rejection email was sent. |
| R14 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer username. |
| R15 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer email address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BackOffice.CustomerDocumentToDocumentType | JOIN | Primary document source |
| - | BackOffice.CustomerDocument | JOIN | Document metadata and CID |
| - | BackOffice.Customer | JOIN | Customer verification level/type filters |
| - | Customer.Customer | JOIN | Block status and internal filter (uses Customer.Customer, not CustomerStatic) |
| - | Dictionary.PlayerStatus | Lookup | Blocked status IDs |
| - | Billing.Deposit | EXISTS | Deposit filter (PaymentStatusID=2 = Approved) |
| - | Compliance.POADocumentsExpirationPopulationGCID | INSERT target (BROKEN) | Table no longer exists - runtime error if called |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No callers found. Deprecated - should not be called. |
| Compliance.GetPOADocumentsExpirationPopulationFor3Years | - | Active successor | This SP has been replaced by the 3-year/1-month variant (created 2021-12-08 by Andrii Aksani for COAKV-3897). Use that SP instead. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325 (procedure - DEPRECATED)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
├── BackOffice.Customer (table)
├── Customer.Customer (table)
├── Dictionary.PlayerStatus (table)
├── Billing.Deposit (table)
└── Compliance.POADocumentsExpirationPopulationGCID (table - MISSING, causes runtime error)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Primary data source |
| BackOffice.CustomerDocument | Table | JOINed for CID and Obsolete flag |
| BackOffice.Customer | Table | JOINed for eligibility filters |
| Customer.Customer | Table | JOINed for block/internal filters and GCID, UserName, Email |
| Dictionary.PlayerStatus | Table | Blocked status ID subquery |
| Billing.Deposit | Table | Approved deposit existence check (PaymentStatusID=2) |
| Compliance.POADocumentsExpirationPopulationGCID | Table | **MISSING** - INSERT target; object no longer exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | No dependents. Deprecated. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| VerificationLevelID = 3 | Application logic | Only fully verified (Level 3) customers - stricter than the current SP which accepts levels 2 and 3 |
| PaymentStatusID = 2 | Application logic | Requires an approved deposit (different from current SP's IsFTD=1 check) |
| Missing table | RUNTIME ERROR | Compliance.POADocumentsExpirationPopulationGCID does not exist - SP fails if called |

---

## 8. Sample Queries

### 8.1 DO NOT CALL - use the replacement instead

```sql
-- DO NOT USE: This SP is deprecated and will fail at runtime.
-- Use the replacement:
DECLARE @ExcludeRegs dbo.IdIntList;
EXEC [Compliance].[GetPOADocumentsExpirationPopulationFor3Years]
    @StartDate = GETUTCDATE(),
    @IsInternal = 0,
    @ExcludeRegulationIDs = @ExcludeRegs;
```

### 8.2 Compare legacy vs current expiry logic

```sql
-- Legacy: COALESCE(ExpiryDate, IssueDate + 1 year)
-- Current: IssueDate + 3 years (or Occurred + 3 years)
SELECT DocumentToDocumentTypeID,
       IssueDate,
       ExpiryDate AS StoredExpiryDate,
       COALESCE(ExpiryDate, DATEADD(year, 1, IssueDate)) AS LegacyCalcExpiry,
       DATEADD(year, 3, IssueDate) AS CurrentCalcExpiry
FROM [BackOffice].[CustomerDocumentToDocumentType] WITH (NOLOCK)
WHERE DocumentTypeID = 1
  AND IssueDate IS NOT NULL
ORDER BY DocumentToDocumentTypeID DESC;
```

### 8.3 Check if the missing target table exists

```sql
SELECT OBJECT_ID('Compliance.POADocumentsExpirationPopulationGCID') AS TableObjectID;
-- Returns NULL if the table does not exist
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comments identify change history:
- Ticket 49112 (2017-10-02): Added GCID to POA expiration population
- Ticket RD-630 (2018-09-04): Excluded EvMatch 2-source customers from doc expiry process
- Tickets RD-10777, 16557 (2019-11-26): Fixed UI showing docs still required after verification

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED) | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.sql*
