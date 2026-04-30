# Compliance.GetPOIDocumentsExpirationPopulation

> Returns the population of customers whose Proof of Identity (POI) documents are expiring within the next 15 days, used to trigger re-verification notification campaigns.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate, @IsInternal (inputs); CID, GCID (outputs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the active data feed for Proof of Identity (POI) document expiration notification campaigns. POI documents (passports, national ID cards, driver's licenses - DocumentTypeID=2) have explicit expiry dates stored in the system, and this SP returns customers whose latest POI document will expire within the next 15 days of the provided start date.

Under KYC/AML regulations, eToro must keep customer identity documents current. When a POI document expires, the customer must re-upload a valid document to maintain full account functionality. This SP identifies the notification population for the re-verification workflow. It was created as part of the same 2017-2019 evolution as the POA variants (ticket 49112), and unlike the POA junk SPs, it remains active without a JUNK suffix.

Note: This SP uses a 15-day forward window, whereas the newer `GetPOADocumentsExpirationPopulationFor3Years` uses a 1-month window. A `GetPOIDocumentsExpirationPopulationFor3Years` equivalent does not exist in the schema, making this the current active SP for POI expiration monitoring. The `GCID` variant with the JUNK suffix was the version that attempted to INSERT into a staging table; this SP only SELECTs.

The `SQL_Compliance` and `PROD_BIadmins` service accounts have EXECUTE permission on this SP, indicating use by both the compliance notification service and BI reporting.

---

## 2. Business Logic

### 2.1 POI Document Expiry Using Stored ExpiryDate

**What**: Uses the explicitly stored ExpiryDate from the document record (no computed date logic needed for POI).

**Columns/Parameters Involved**: `CDTDT.ExpiryDate`, `@StartDate`, `@EndDate`

**Rules**:
- Unlike the POA expiry SP, POI expiry uses the stored `CDTDT.ExpiryDate` column directly (no COALESCE fallback)
- POI documents (passports, IDs) have government-printed expiry dates that are captured by the back-office team during document review
- @EndDate = `DATEADD(Day, 15, CAST(GETUTCDATE() AS DATE))` - 15-day forward window
- Window: `t.ExpiryDate > @StartDate AND t.ExpiryDate <= @EndDate`
- Sorted by ExpiryDate DESC to deduplicate to the latest POI per customer

### 2.2 Dead Parameter: @MaxAllowedProcessingRowsPerCycle

**What**: Declared parameter that has no effect on the query results.

**Rules**:
- `@MaxAllowedProcessingRowsPerCycle INT` is in the parameter signature but is NEVER referenced in the query body
- All matching rows are always returned regardless of this value
- Inherited from the original batch-processing design (see `GetPOADocumentsExpirationPopulation_JUNKYulia0325`)

### 2.3 Customer Eligibility Filters

**What**: Restricts results to the same population as the legacy POA SP.

**Rules**:
- `VerificationLevelID = 3`: Fully verified customers only (Level 3)
- `AccountTypeID NOT IN (2, 4)`: Excludes Corporate and Joint Account types
- `EvMatchStatus NOT IN (2)`: Excludes customers confirmed via electronic verification
- Not blocked: `PlayerStatusID NOT IN (SELECT PlayerStatusID FROM Dictionary.PlayerStatus WHERE IsBlocked=1)`
- Internal/External: `@IsInternal=0` includes all non-internal; `@IsInternal=1` restricts to `PlayerLevelID=4`
- Deposit required: `EXISTS (SELECT * FROM Billing.Deposit WHERE CID = customer AND PaymentStatusID = 2)` - requires at least one approved deposit

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the expiration window. Documents expiring after this date and within 15 days of today are returned. Typically set to the last run date of the notification job. |
| 2 | @MaxAllowedProcessingRowsPerCycle | INT | NO | - | CODE-BACKED | **Dead parameter - has no effect.** Declared but never used in the query. Inherited from legacy batch-processing design. All eligible rows are always returned. |
| 3 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external/regular customers (all non-internal); 1 = restrict to eToro internal employees (PlayerLevelID=4). |

**Return Result Set**:

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| R1 | RowNumber | INT | NO | CODE-BACKED | Always 1 - identifies this as the latest-expiring POI document for the customer (deduplicated). |
| R2 | GCID | INT/BIGINT | NO | CODE-BACKED | Global Customer ID from Customer.Customer. |
| R3 | CID | INT | NO | CODE-BACKED | eToro per-entity customer ID. |
| R4 | DocumentToDocumentTypeID | INT | NO | CODE-BACKED | PK of BackOffice.CustomerDocumentToDocumentType. |
| R5 | DocumentID | INT | NO | CODE-BACKED | PK of BackOffice.CustomerDocument. |
| R6 | DocumentTypeID | TINYINT | NO | CODE-BACKED | Always 2 (Proof of Identity) for all rows. See [Document Type](_glossary.md#document-type). |
| R7 | IssueDate | DATE | YES | CODE-BACKED | Date the document was issued by the government authority. |
| R8 | ExpiryDate | DATETIME | YES | CODE-BACKED | The government-printed expiry date of the document, stored in the system by the reviewing back-office manager. Used directly (not computed). |
| R9 | FundingID | INT | YES | CODE-BACKED | Associated funding record ID from BackOffice.CustomerDocumentToDocumentType. |
| R10 | ManagerID | INT | YES | CODE-BACKED | The back-office manager who reviewed and approved this document. |
| R11 | Comment | NVARCHAR | YES | CODE-BACKED | Free-text comment added during document review. |
| R12 | RejectReasonID | INT | YES | CODE-BACKED | Rejection reason if applicable. Not filtered - documents without rejection reasons and without explicit filter may include all statuses. |
| R13 | RejectEmailSent | BIT | YES | CODE-BACKED | Whether a rejection notification email was sent for this document. |
| R14 | UserName | NVARCHAR | YES | CODE-BACKED | Customer's username from Customer.Customer. Used by notification systems. |
| R15 | Email | NVARCHAR | YES | CODE-BACKED | Customer's email address. Used by notification systems to send the expiry reminder. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | JOIN (primary source) | Source of document type, ExpiryDate, IssueDate, and review metadata |
| DocumentID | BackOffice.CustomerDocument | JOIN | Document metadata (CID, Obsolete flag) |
| CID | BackOffice.Customer | JOIN | Eligibility filters: VerificationLevelID, AccountTypeID, EvMatchStatus |
| CID | Customer.Customer | JOIN | Block status, PlayerLevelID filter; provides GCID, UserName, Email |
| PlayerStatusID | Dictionary.PlayerStatus | Lookup | Blocked player status IDs for exclusion filter |
| CID | Billing.Deposit | EXISTS subquery | Approved deposit check (PaymentStatusID=2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325 | - | Deprecated sibling | Near-identical logic but with @MaxAllowedProcessingRowsPerCycle commented out instead of declared as dead. Retained for historical reference; this SP is the active version. |
| SQL_Compliance (service account) | - | EXECUTE permission | Compliance notification service calls this SP for POI expiry campaigns |
| PROD_BIadmins (service account) | - | EXECUTE permission | BI reporting/analytics accesses this SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetPOIDocumentsExpirationPopulation (procedure)
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
| BackOffice.CustomerDocumentToDocumentType | Table | Primary source - DocumentTypeID=2 filter, ExpiryDate, IssueDate, FundingID, ManagerID |
| BackOffice.CustomerDocument | Table | JOINed for CID and Obsolete flag |
| BackOffice.Customer | Table | JOINed for VerificationLevelID=3, AccountTypeID, EvMatchStatus filters |
| Customer.Customer | Table | JOINed for block status and PlayerLevelID; provides GCID, UserName, Email |
| Dictionary.PlayerStatus | Table | Subquery for blocked PlayerStatusIDs (IsBlocked=1) |
| Billing.Deposit | Table | EXISTS subquery for approved deposit (PaymentStatusID=2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_Compliance service | External application | Calls SP for POI document expiry notification campaigns |
| PROD_BIadmins | External reporting | BI reporting access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DocumentTypeID = 2 | Application logic | Restricts to Proof of Identity documents only (vs. DocumentTypeID=1 for POA) |
| ExpiryDate used directly | Design note | Unlike POA SP, no date computation needed - government expiry dates are stored as-is |
| CD.Obsolete != 1 | Application logic | Excludes superseded/obsolete document records |
| PaymentStatusID = 2 | Application logic | Requires at least one approved deposit - unfunded accounts excluded |
| @MaxAllowedProcessingRowsPerCycle | Dead parameter | Has no effect - all eligible rows always returned |

---

## 8. Sample Queries

### 8.1 Run daily POI expiry check (external customers)

```sql
EXEC [Compliance].[GetPOIDocumentsExpirationPopulation]
    @StartDate = GETUTCDATE(),
    @MaxAllowedProcessingRowsPerCycle = 0,  -- ignored
    @IsInternal = 0;
```

### 8.2 Run for internal employees

```sql
EXEC [Compliance].[GetPOIDocumentsExpirationPopulation]
    @StartDate = GETUTCDATE(),
    @MaxAllowedProcessingRowsPerCycle = 0,  -- ignored
    @IsInternal = 1;
```

### 8.3 Check POI documents expiring in the next 15 days

```sql
SELECT COUNT(DISTINCT CD.CID) AS CustomersWithExpiringPOI,
       MIN(CDTDT.ExpiryDate) AS EarliestExpiry,
       MAX(CDTDT.ExpiryDate) AS LatestExpiry
FROM [BackOffice].[CustomerDocumentToDocumentType] CDTDT WITH (NOLOCK)
JOIN [BackOffice].[CustomerDocument] CD WITH (NOLOCK) ON CDTDT.DocumentID = CD.DocumentID
WHERE CDTDT.DocumentTypeID = 2
  AND CD.Obsolete != 1
  AND CDTDT.ExpiryDate > GETUTCDATE()
  AND CDTDT.ExpiryDate <= DATEADD(Day, 15, CAST(GETUTCDATE() AS DATE));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comments identify same change history as POA variants: tickets 49112 (2017-10-02), RD-630 (2018-09-04), RD-10777/16557 (2019-11-26).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetPOIDocumentsExpirationPopulation | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetPOIDocumentsExpirationPopulation.sql*
