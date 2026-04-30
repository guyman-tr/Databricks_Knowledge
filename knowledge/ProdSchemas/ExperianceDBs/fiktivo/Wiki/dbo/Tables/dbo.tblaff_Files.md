# dbo.tblaff_Files

> Stores affiliate payment document attachments, linking uploaded files (invoices, payment receipts) to specific affiliates and payment records.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | FileID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_Files stores metadata for documents uploaded to the affiliate system, primarily payment-related attachments such as invoices, payment confirmations, and commission statements. Each file is linked to a specific affiliate and payment record, creating an audit trail of payment documentation.

Without this table, the affiliate system would have no structured way to associate uploaded documents with specific payment transactions. Finance teams use these attachments during payment approval workflows and audits.

Files are uploaded via the affiliate admin interface by internal staff (UploadedBy tracks the admin user). The actual files are stored on CDN (cdn.etoro.com/partners/attachments/) with the URL recorded here. File names follow the pattern "AFF {AffiliateID} - {Amount} USD.docx", indicating these are payment confirmation documents. Contains ~10.9K file records.

---

## 2. Business Logic

### 2.1 Payment Document Association

**What**: Each file is linked to both an affiliate and a specific payment transaction.

**Columns/Parameters Involved**: `AffiliateID`, `PaymentID`, `FileURL`

**Rules**:
- `AffiliateID` identifies the affiliate this document belongs to
- `PaymentID` links to the specific payment record in tblaff_PaymentHistory
- `FileURL` contains the CDN URL for the actual document
- File naming convention: "AFF {AffID} - {Amount} USD.docx" encodes the affiliate and payment amount
- Documents are hosted on cdn.etoro.com/partners/attachments/

---

## 3. Data Overview

| FileID | AffiliateID | PaymentID | UploadDate | UploadedBy | FileURL | Meaning |
|---|---|---|---|---|---|---|
| 19177 | 35954 | 20231 | 2013-01-18 | 33 | .../AFF 39554 - 200 USD.docx | Payment confirmation for $200 payment to affiliate 35954 (note: filename says 39554 - possible typo). Uploaded by admin user 33. |
| 19176 | 35472 | 20243 | 2013-01-18 | 33 | .../1_AFF 35472 - 711.58 USD.docx | Revised payment doc ("1_" prefix) for $711.58 payment to affiliate 35472. Same admin uploaded both revisions. |
| 19175 | 35472 | 19929 | 2013-01-18 | 33 | .../AFF 35472 - 711.58 USD.docx | Original payment doc for affiliate 35472 for a different payment (19929 vs 20243). Same amount suggests recurring payment pattern. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FileID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | AffiliateID | int | NO | - | VERIFIED | The affiliate this document belongs to. Maps to tblaff_Affiliates.AffiliateID. |
| 3 | PaymentID | int | NO | - | VERIFIED | The payment record this document is attached to. Maps to tblaff_PaymentHistory.PaymentID. Creates the document-to-payment audit trail. |
| 4 | UploadDate | datetime | NO | getdate() | CODE-BACKED | Timestamp when the file was uploaded. Defaults to current time. |
| 5 | UploadedBy | int | NO | - | CODE-BACKED | Internal admin user ID who uploaded the document. Value 33 appears frequently in sample data - likely a finance team member responsible for batch uploads. |
| 6 | FileURL | nvarchar(350) | YES | - | VERIFIED | CDN URL where the document is stored. Pattern: cdn.etoro.com/partners/attachments/{filename}. File names encode affiliate ID and payment amount for easy identification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate this document belongs to |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | The payment this document is attached to |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Files | CLUSTERED PK | FileID ASC | - | - | Active (fill 90%) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Files_UploadDate | DEFAULT | getdate() - Current timestamp on upload |

---

## 8. Sample Queries

### 8.1 Get all documents for an affiliate
```sql
SELECT FileID, PaymentID, UploadDate, UploadedBy, FileURL
FROM dbo.tblaff_Files WITH (NOLOCK)
WHERE AffiliateID = @AffiliateID
ORDER BY UploadDate DESC
```

### 8.2 Documents for a specific payment
```sql
SELECT f.FileID, f.FileURL, f.UploadDate, f.UploadedBy
FROM dbo.tblaff_Files f WITH (NOLOCK)
WHERE f.PaymentID = @PaymentID
```

### 8.3 Upload activity by admin user
```sql
SELECT UploadedBy, COUNT(*) AS FilesUploaded,
       MIN(UploadDate) AS FirstUpload, MAX(UploadDate) AS LastUpload
FROM dbo.tblaff_Files WITH (NOLOCK)
GROUP BY UploadedBy
ORDER BY FilesUploaded DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Files | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Files.sql*
