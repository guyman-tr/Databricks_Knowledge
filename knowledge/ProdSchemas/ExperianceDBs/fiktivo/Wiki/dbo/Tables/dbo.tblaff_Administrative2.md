# dbo.tblaff_Administrative2

> System configuration table (singleton row) storing affiliate platform settings for notifications, file uploads, mail server, spider detection, and UI customization.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_Administrative2 is a singleton configuration table (1 row) storing platform-level settings for the affiliate system. It extends the configuration stored in dbo.tblaff_Administrative (documented in Batch 1) with additional settings for notification email scheduling, file upload paths, mail server credentials, spider detection, paging, P3P privacy policy, and email templates for member onboarding and payments.

Without this table, the affiliate platform would have no configurable settings for these operational aspects. The single-row design means all settings are global - there are no per-affiliate or per-brand overrides.

The table stores sensitive data including mail server credentials (MailServerUserName, MailServerPassword) and CDN paths. Settings are read by the affiliate admin interface and background services. File upload paths point to AWS S3 (`openbook-static-files-test.s3.amazonaws.com`).

---

## 2. Business Logic

### 2.1 Notification Scheduling

**What**: Controls automated notification emails to affiliates.

**Columns/Parameters Involved**: `Notification1`, `Notification2`, `Notification1SentDate`, `Notification2SentDate`

**Rules**:
- Two notification types with independent scheduling
- SentDate tracks when each notification was last sent
- Value 0 for Notification1/2 likely means disabled

### 2.2 File Upload Configuration

**What**: Defines where affiliate-uploaded files (banners, documents) are stored.

**Columns/Parameters Involved**: `FileUploadPath`, `FileUploadURL`, `DocumentUploadPath`, `DocumentUploadURL`

**Rules**:
- Paths define the S3 bucket path structure (e.g., "partners/qa/ads/", "partners/qa/attachments/")
- URLs define the CDN base URL for serving uploaded files
- Separate paths for banner/ad files vs document attachments (payment docs in tblaff_Files)

### 2.3 Email Templates

**What**: Configurable email subjects for lifecycle notifications.

**Columns/Parameters Involved**: `NewMemberMessageSubject`, `PendingMemberMessageSubject`, `RejectedMemberMessageSubject`, `NewSaleMessageSubject`, `GeneratePaymentMessageSubject`, `GeneratePaymentMessageBody`

**Rules**:
- Templates use ##placeholder## variables replaced at send time (e.g., ##RequestorName##, ##ApproverName##, ##PaymentAgregatedDetailsTable##)
- Covers affiliate lifecycle: new member welcome, pending review, rejection notification
- Payment approval notification includes HTML template with aggregated payment details

---

## 3. Data Overview

| ID | MailServerUserName | FileUploadURL | SpiderDetectionEnabled | RecordSetPagingSize | Meaning |
|---|---|---|---|---|---|
| 1 | partners@tradonomi.com | https://openbook-static-files-test.s3.amazonaws.com/ | false | 20 | Singleton config row. Mail via tradonomi.com SMTP (port 25, no SSL). Files on S3. Spider detection off. 20 records per page in admin UI. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Singleton primary key (always 1). NOT FOR REPLICATION. |
| 2 | Notification1 | int | YES | 0 | CODE-BACKED | First notification type configuration. 0 = disabled. |
| 3 | Notification2 | int | YES | 0 | CODE-BACKED | Second notification type configuration. 0 = disabled. |
| 4 | Notification1SentDate | datetime | YES | getdate() | CODE-BACKED | When Notification1 was last sent. |
| 5 | Notification2SentDate | datetime | YES | getdate() | CODE-BACKED | When Notification2 was last sent. |
| 6 | FileUploadPath | nvarchar(350) | YES | - | VERIFIED | S3 bucket path for banner/ad file uploads. E.g., "partners/qa/ads/". |
| 7 | FileUploadURL | nvarchar(350) | YES | - | VERIFIED | CDN base URL for serving uploaded banner files. Points to S3. |
| 8 | DocumentUploadPath | nvarchar(350) | YES | - | VERIFIED | S3 bucket path for document uploads (payment attachments). E.g., "partners/qa/attachments/". |
| 9 | DocumentUploadURL | nvarchar(350) | YES | - | VERIFIED | CDN base URL for serving uploaded documents. |
| 10 | SpiderDetectionEnabled | bit | NO | 0 | CODE-BACKED | Whether bot/spider detection is active for affiliate tracking. When enabled, detected spiders don't count as valid impressions/clicks. |
| 11 | BannerSortingAffiliateArea | int | YES | - | NAME-INFERRED | Banner display sorting mode in the affiliate portal. Value 1 in current config. |
| 12 | MailServerUserName | nvarchar(100) | YES | - | VERIFIED | SMTP server username for sending affiliate emails. Contains email address (partners@tradonomi.com). |
| 13 | MailServerPassword | nvarchar(100) | YES | - | VERIFIED | SMTP server password. Stored in plaintext (security concern). |
| 14 | RecordSetPagingSize | int | NO | 10 | CODE-BACKED | Default page size for admin UI data grids. Value 20 in current config. |
| 15 | P3PPolicy | nvarchar(500) | YES | - | CODE-BACKED | P3P (Platform for Privacy Preferences) compact policy header for cookie compliance. Legacy web standard. |
| 16 | NewMemberMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for new affiliate welcome message. |
| 17 | PendingMemberMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for pending affiliate application notification. |
| 18 | RejectedMemberMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for rejected affiliate notification. |
| 19 | NewSaleMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for new sale notification to affiliate. |
| 20 | AffiliateHeader | ntext | YES | - | CODE-BACKED | HTML header template for affiliate portal pages. |
| 21 | AffiliateFooter | ntext | YES | - | CODE-BACKED | HTML footer template. Contains copyright text. |
| 22 | AffiliateStyleSheet | ntext | YES | - | CODE-BACKED | CSS stylesheet for the affiliate portal. Defines the visual theme. |
| 23 | AffiliateTitle | nvarchar(200) | YES | - | VERIFIED | Browser title for the affiliate portal. "eToro Partners - Join The Forex Revolution". |
| 24 | MailServerPort | int | YES | - | CODE-BACKED | SMTP server port. Value 25 (standard unencrypted SMTP). |
| 25 | MailServerSSLEnabled | bit | YES | - | CODE-BACKED | Whether SMTP uses SSL/TLS. Currently false (port 25, unencrypted). |
| 26 | GeneratePaymentMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for payment approval notification. |
| 27 | GeneratePaymentMessageBody | ntext | YES | - | VERIFIED | HTML email body template for payment approval. Uses ##placeholder## variables (##RequestorName##, ##ApproverName##, ##PaymentAgregatedDetailsTable##) replaced at send time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Read by the affiliate admin interface and email notification services.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Administrative2_PK | NC PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Administrative2_SpiderDetectionEnabled | DEFAULT | 0 - Disabled |
| DF_tblaff_Administrative2_RecordSetPagingSize | DEFAULT | 10 |

---

## 8. Sample Queries

### 8.1 Read all configuration
```sql
SELECT * FROM dbo.tblaff_Administrative2 WITH (NOLOCK)
```

### 8.2 Get file upload settings
```sql
SELECT FileUploadPath, FileUploadURL, DocumentUploadPath, DocumentUploadURL
FROM dbo.tblaff_Administrative2 WITH (NOLOCK)
```

### 8.3 Get mail server configuration
```sql
SELECT MailServerUserName, MailServerPort, MailServerSSLEnabled
FROM dbo.tblaff_Administrative2 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 8.1/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Administrative2 | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Administrative2.sql*
