# Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325

> **DEPRECATED / JUNK** - Legacy POA document expiration SP using 1-year expiry and a 15-day window, with a declared-but-unused batch-size parameter. Superseded by `Compliance.GetPOADocumentsExpirationPopulationFor3Years`. Retained for historical reference only.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate, @IsInternal (inputs); CID, GCID (outputs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**DEPRECATED** - This procedure carries the `_JUNKYulia0325` suffix, marking it as deprecated and retained for historical reference only. The active replacement is `Compliance.GetPOADocumentsExpirationPopulationFor3Years`.

This is the predecessor of `GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325`. It shares the same 1-year expiry logic and 15-day window, but differs in two ways:
1. Does NOT attempt to INSERT into the now-missing `Compliance.POADocumentsExpirationPopulationGCID` table - making it technically executable (unlike the GCID variant)
2. Accepts an `@MaxAllowedProcessingRowsPerCycle` parameter that was intended to limit batch processing volume, but this parameter is **never used** in the query body - all eligible rows are always returned regardless of the value passed

The same change history applies (tickets 49112, RD-630, RD-10777/16557 from 2017-2019). The presence of the commented-out Billing.Deposit JOIN and the unused batch parameter suggests this SP was evolving from a batch-limited job to a full-population query before being superseded.

---

## 2. Business Logic

### 2.1 Legacy 1-Year Expiry and 15-Day Window (Deprecated)

**What**: Same as `GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325` - uses stored ExpiryDate or 1-year IssueDate offset.

**Rules**:
- ExpiryDate = `COALESCE(CDTDT.ExpiryDate, DATEADD(Year, 1, CDTDT.IssueDate))`
- @EndDate = `DATEADD(Day, 15, CAST(GETUTCDATE() AS DATE))` - 15-day forward window
- Window: `t.ExpiryDate > @StartDate AND t.ExpiryDate <= @EndDate`

See `Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325` for full diff vs. current SP.

### 2.2 Dead Parameter: @MaxAllowedProcessingRowsPerCycle

**What**: Declared parameter that has no effect on the query results.

**Rules**:
- `@MaxAllowedProcessingRowsPerCycle INT` is declared in the parameter list
- It is NEVER referenced in the query body
- All rows matching the date window are returned regardless of value passed
- This appears to be a vestigial parameter from a prior batch-limited design that was removed from the logic but not from the signature

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the expiration window. Documents expiring after this date and within 15 days of today are included (legacy logic). |
| 2 | @MaxAllowedProcessingRowsPerCycle | INT | NO | - | CODE-BACKED | **Dead parameter - has no effect.** Declared but never used in the query. Was likely intended to cap the number of rows returned per scheduled job cycle, but the limiting logic was removed. All eligible rows are always returned. |
| 3 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external/regular customers; 1 = restrict to eToro internal employees (PlayerLevelID=4). Same legacy logic as the GCID variant. |

**Return Result Set** (same columns as `GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325`, except this SP can actually execute):

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| R1 | RowNumber | INT | NO | CODE-BACKED | Always 1 - latest expiring POA per customer. |
| R2 | GCID | INT/BIGINT | NO | CODE-BACKED | Global Customer ID. |
| R3 | CID | INT | NO | CODE-BACKED | eToro customer ID. |
| R4 | DocumentToDocumentTypeID | INT | NO | CODE-BACKED | PK of BackOffice.CustomerDocumentToDocumentType. |
| R5 | DocumentID | INT | NO | CODE-BACKED | PK of BackOffice.CustomerDocument. |
| R6 | DocumentTypeID | TINYINT | NO | CODE-BACKED | Always 1 (POA). See [Document Type](_glossary.md#document-type). |
| R7 | IssueDate | DATE | YES | CODE-BACKED | Date printed on the physical document. |
| R8 | ExpiryDate | DATETIME | NO | CODE-BACKED | COALESCE(stored ExpiryDate, IssueDate + 1 year). Legacy calculation. |
| R9 | FundingID | INT | YES | CODE-BACKED | Associated funding record ID. |
| R10 | ManagerID | INT | YES | CODE-BACKED | Reviewing back-office manager. |
| R11 | Comment | NVARCHAR | YES | CODE-BACKED | Review comment. |
| R12 | RejectReasonID | INT | YES | CODE-BACKED | Reject reason (not filtered in this SP). |
| R13 | RejectEmailSent | BIT | YES | CODE-BACKED | Whether rejection email was sent. |
| R14 | UserName | NVARCHAR | YES | CODE-BACKED | Customer username. |
| R15 | Email | NVARCHAR | YES | CODE-BACKED | Customer email address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BackOffice.CustomerDocumentToDocumentType | JOIN | Primary document source |
| - | BackOffice.CustomerDocument | JOIN | Document metadata and CID |
| - | BackOffice.Customer | JOIN | Eligibility filters |
| - | Customer.Customer | JOIN | Block status, internal filter, GCID/email |
| - | Dictionary.PlayerStatus | Lookup | Blocked status IDs |
| - | Billing.Deposit | EXISTS | Approved deposit check (PaymentStatusID=2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No callers found. Deprecated. |
| Compliance.GetPOADocumentsExpirationPopulationFor3Years | - | Active successor | This SP has been replaced by the 3-year/1-month variant (created 2021-12-08 for COAKV-3897). Technically executable (unlike GCID variant) but should not be called - use For3Years instead. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325 (procedure - DEPRECATED)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
├── BackOffice.Customer (table)
├── Customer.Customer (table)
├── Dictionary.PlayerStatus (table)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Primary data source |
| BackOffice.CustomerDocument | Table | JOINed for CID and Obsolete flag |
| BackOffice.Customer | Table | Eligibility filters (VerificationLevelID=3, AccountTypeID, EvMatchStatus) |
| Customer.Customer | Table | Block status, PlayerLevelID filter; provides GCID, UserName, Email |
| Dictionary.PlayerStatus | Table | Blocked status ID subquery |
| Billing.Deposit | Table | Approved deposit existence check (PaymentStatusID=2) |

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
| VerificationLevelID = 3 | Application logic | Only fully verified (Level 3) customers |
| PaymentStatusID = 2 | Application logic | Requires an approved deposit |
| @MaxAllowedProcessingRowsPerCycle | Dead parameter | Declared but never used - no batching enforced |

---

## 8. Sample Queries

### 8.1 DO NOT CALL - use the replacement instead

```sql
-- DO NOT USE: This SP is deprecated.
-- Use the replacement:
DECLARE @ExcludeRegs dbo.IdIntList;
EXEC [Compliance].[GetPOADocumentsExpirationPopulationFor3Years]
    @StartDate = GETUTCDATE(),
    @IsInternal = 0,
    @ExcludeRegulationIDs = @ExcludeRegs;
```

### 8.2 If called (technically executes, unlike GCID variant)

```sql
-- This SP will execute without error (no missing table reference)
-- but results use legacy 1-year expiry and 15-day window
EXEC [Compliance].[GetPOADocumentsExpirationPopulation_JUNKYulia0325]
    @StartDate = '2026-01-01',
    @MaxAllowedProcessingRowsPerCycle = 1000,  -- ignored
    @IsInternal = 0;
```

### 8.3 Compare this SP vs current SP for the same customer population

```sql
-- Legacy: Approved deposit (PaymentStatusID=2), Level 3 only, 1-year expiry
-- Current: IsFTD=1, Level 2 or 3, 3-year expiry from Occurred
SELECT COUNT(DISTINCT CID) AS LegacyCustomers
FROM [BackOffice].[CustomerDocument] CD WITH (NOLOCK)
JOIN [BackOffice].[Customer] BC WITH (NOLOCK) ON BC.CID = CD.CID AND BC.VerificationLevelID = 3
WHERE EXISTS (SELECT 1 FROM [Billing].[Deposit] BD WITH (NOLOCK) WHERE BD.CID = CD.CID AND BD.PaymentStatusID = 2);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comments identify same change history as the GCID variant: tickets 49112 (2017), RD-630 (2018), RD-10777/16557 (2019).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED) | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.sql*
