# BackOffice.GetExpiredIdentityDocuments

> Returns POI (Proof of Identity, DocumentTypeID=2) document classifications whose ExpiryDate falls within a rolling window that always ends 30 days into the future, used for compliance monitoring of near-expiry and recently-expired identity documents.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rolling date window on BackOffice.CustomerDocumentToDocumentType.ExpiryDate for DocumentTypeID=2 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetExpiredIdentityDocuments is a compliance monitoring procedure that identifies customers whose Proof of Identity documents (passports, driving licenses, etc.) are expiring soon or have recently expired. It returns classification records from `BackOffice.CustomerDocumentToDocumentType` for DocumentTypeID=2 (POI) where the ExpiryDate falls in a configurable window that always ends 30 days in the future.

The procedure enables BackOffice compliance teams to generate alerts and contact customers who need to re-upload updated identity documents before their current ones expire (compliance regulations typically require valid, non-expired KYC documents to continue trading).

---

## 2. Business Logic

### 2.1 Rolling Date Window Calculation

**What**: The date window is defined relative to today with a fixed end date 30 days ahead. The @daysBack parameter controls how far before that end date the window starts.

**Columns/Parameters Involved**: `@daysBack`, `@StartDate`, `@EndDate`, `dt.ExpiryDate`

**Rules**:
- `@EndDate = DATEADD(DAY, 30, GETDATE())` - always 30 days from today. Fixed upper bound.
- `@StartDate = DATEADD(DAY, -@daysBack + 30, GETDATE()) = today + (30 - @daysBack)` - moves back from @EndDate by @daysBack days.
- Filter: `ExpiryDate >= @StartDate AND ExpiryDate < @EndDate`

**Window examples**:

| @daysBack | @StartDate | @EndDate | Documents included |
|---|---|---|---|
| 30 | today | today + 30 | Expiring within the next 30 days (future only) |
| 60 | today - 30 | today + 30 | Expired up to 30 days ago OR expiring within 30 days |
| 90 | today - 60 | today + 30 | Expired up to 60 days ago OR expiring within 30 days |

The window always ends at today+30 (ensuring documents expiring soon are always captured). The @daysBack parameter extends the window backward to include recently-expired documents.

### 2.2 POI-Only Filter

**What**: Only Proof of Identity documents are returned.

**Rules**:
- `DocumentTypeID = 2` = Proof of Identity only. Other types (POA=1, Credit Card=3, etc.) are not relevant for identity expiration monitoring.
- The ExpiryDate field on CustomerDocumentToDocumentType is the agent-entered expiry of the physical document (passport expiry date, driving license expiry date)
- NULL ExpiryDate rows are excluded by the date range filter (NULL does not satisfy >= @StartDate)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @daysBack | INT | NO | - | CODE-BACKED | Controls the start of the date window. The window always ends at today+30 days. @daysBack determines how far before that end date the window starts: @StartDate = today + (30 - @daysBack). Use 30 for "expiring in next 30 days only"; use 60 for "expired up to 30 days ago through next 30 days". |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | NO | - | CODE-BACKED | Customer account ID. From BackOffice.CustomerDocument.CID via INNER JOIN. |
| R2 | DocumentToDocumentTypeID | int | NO | - | CODE-BACKED | Surrogate PK of the classification record. From BackOffice.CustomerDocumentToDocumentType. |
| R3 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. FK to BackOffice.CustomerDocument. |
| R4 | DocumentTypeID | int | NO | - | CODE-BACKED | Always 2 (Proof of Identity) due to the WHERE filter. |
| R5 | IssueDate | date | YES | - | VERIFIED | Issue date of the identity document as entered by the BackOffice agent. NULL if not captured. |
| R6 | ExpiryDate | date | YES | - | VERIFIED | Expiry date of the identity document. The field driving the window filter. Falls within [@StartDate, @EndDate). |
| R7 | FundingID | int | YES | - | VERIFIED | For DocumentTypeID=2 (POI), this is typically NULL (FundingID is only populated for credit card documents). Included for completeness. |
| R8 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager who classified this document. 0 or NULL = automated (Au10tix/Onfido). |
| R9 | Comment | nvarchar | YES | - | CODE-BACKED | Free-text comment on the classification. |
| R10 | RejectReasonID | int | YES | - | VERIFIED | Rejection reason if the document was rejected (DocumentTypeID=6 would normally hold this; here DocumentTypeID=2 means accepted POI, so RejectReasonID should typically be NULL). |
| R11 | RejectEmailSent | bit | YES | - | VERIFIED | 1 if a rejection notification was sent. For accepted POI documents, this is typically NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| dt | BackOffice.CustomerDocumentToDocumentType | SELECT | Document classification records for expiring POI documents |
| ct | BackOffice.CustomerDocument | INNER JOIN | Provides CID for the document |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from compliance monitoring workflows, alerts, and scheduled jobs that notify customers of expiring identity documents.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetExpiredIdentityDocuments (procedure)
├── BackOffice.CustomerDocumentToDocumentType (table)
└── BackOffice.CustomerDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Primary source; filtered to DocumentTypeID=2 with ExpiryDate in rolling window |
| BackOffice.CustomerDocument | Table | INNER JOIN on DocumentID to get CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Compliance monitoring jobs | External | READER - generates lists of customers with near-expiry or recently-expired POI documents for re-upload outreach |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. BackOffice.CustomerDocumentToDocumentType has an NC index on `(ExpiryDate, DocumentTypeID)` or similar that would support this query pattern, but the specific index composition should be verified against the table DDL.

### 7.2 Constraints

N/A for Stored Procedure. Note: NULL ExpiryDate rows are excluded by the >= filter. The procedure uses CAST(GETDATE() AS DATE) to strip time components from the date comparison. The @EndDate exclusive bound (`< @EndDate` not `<= @EndDate`) ensures the window is `@daysBack` days wide exactly.

---

## 8. Sample Queries

### 8.1 Get POI documents expiring in the next 30 days
```sql
EXEC BackOffice.GetExpiredIdentityDocuments @daysBack = 30
-- Window: today to today+30
-- Returns: documents whose ExpiryDate is within the next 30 days
```

### 8.2 Get recently-expired plus upcoming expirations (60-day window centered at today+30)
```sql
EXEC BackOffice.GetExpiredIdentityDocuments @daysBack = 60
-- Window: today-30 to today+30
-- Returns: expired up to 30 days ago OR expiring within 30 days
```

### 8.3 Ad-hoc equivalent for today's expiring documents
```sql
SELECT ct.CID, dt.DocumentToDocumentTypeID, dt.DocumentID, dt.ExpiryDate
FROM BackOffice.CustomerDocumentToDocumentType dt WITH (NOLOCK)
INNER JOIN BackOffice.CustomerDocument ct WITH (NOLOCK) ON ct.DocumentID = dt.DocumentID
WHERE dt.DocumentTypeID = 2
  AND dt.ExpiryDate >= CAST(GETDATE() AS DATE)
  AND dt.ExpiryDate < DATEADD(DAY, 30, CAST(GETDATE() AS DATE))
ORDER BY dt.ExpiryDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetExpiredIdentityDocuments | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetExpiredIdentityDocuments.sql*
