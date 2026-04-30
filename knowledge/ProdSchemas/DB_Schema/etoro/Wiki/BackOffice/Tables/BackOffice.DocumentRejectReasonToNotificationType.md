# BackOffice.DocumentRejectReasonToNotificationType

> Static configuration mapping document rejection reasons to their corresponding customer notification email templates, defining which email is sent when a specific rejection reason is applied to a customer's KYC document.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (RejectReasonID, NotificationTypeID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.DocumentRejectReasonToNotificationType is a static configuration table that defines which customer notification email template is triggered when a BackOffice agent rejects a KYC document with a specific rejection reason. When a document is marked as "Not Accepted" (DocumentTypeID=6 in CustomerDocumentToDocumentType), the system uses this table to determine which email the customer receives explaining why their document was rejected and what to resubmit.

42 rows covering 42 distinct rejection reason codes. Most are one-to-one mappings (one rejection reason -> one email template), but rejection reasons 29-35 (selfie/video rejection subtypes) all map to the same NotificationTypeID=21 ("5211SelfieVideoGeneralRejection"), using a single generic selfie rejection email for multiple specific failure modes.

The table is not referenced by any stored procedure in the BackOffice SSDT repo - it is consumed directly by the application layer (BackOffice web UI or notification service) to resolve the email template when processing a document rejection event.

Coverage: 42 of the 54 total rejection reasons have email notifications mapped. The 12 unmapped reasons (e.g., RejectReasonIDs 1, 2, 3, 7, etc.) do not trigger automated customer emails when applied.

---

## 2. Business Logic

### 2.1 Rejection Reason to Email Template Mapping

**What**: Maps each document rejection reason to the customer-facing email notification template.

**Columns Involved**: `RejectReasonID`, `NotificationTypeID`

**Rules**:
- Each RejectReasonID has at most one NotificationTypeID mapping (42 rows, 42 distinct RejectReasonIDs, 37 distinct NotificationTypeIDs).
- RejectReasonIDs 29-35 (selfie-related: Face Not Detected, Cropped, Scan, Black and White, Scan, etc.) all use NotificationTypeID=21 (5211SelfieVideoGeneralRejection) - one generic selfie rejection email covers multiple specific issues.
- RejectReasonIDs not in this table (1, 2, 3, 7, 17, 20, 23, 24, 36, 37, 38, 45) do not have mapped notifications - no email sent for those rejection reasons.
- NotificationType names follow a clear naming convention: prefix indicates document type (POI, POA, SSN, Selfie) + description of the issue.

**Notable mappings**:
- RejectReasonID=4 (POI - Expired Document) -> NotificationTypeID=1 (POIDocExpired)
- RejectReasonID=5 (POI - Incomplete Copy) -> NotificationTypeID=2 (POIIncompleteCopy)
- RejectReasonID=14 (POA - Missing Address Details) -> NotificationTypeID=13 (POAMissingAddressDetails)
- RejectReasonID=15 (POA - Proof Of Address Cannot Be Accepted) -> NotificationTypeID=14 (POAAddressCannotBeAccepted)
- RejectReasonID=39 (SSN Card - Cannot Be Accepted) -> NotificationTypeID=26 (SSNCardMissingDocument)
- RejectReasonIDs 46-54 (newer rejection reasons) map to email notifications 31-40 covering corruption, business address, SSN issues, visa expiry, selfie forgery, etc.

---

## 3. Data Overview

42 rows (static configuration). Full mapping:

| RejectReasonID | Reason | NotificationTypeID | NotificationType |
|----------------|--------|--------------------|-----------------|
| 4 | POI - Expired Document | 1 | POIDocExpired |
| 5 | POI - Incomplete Copy | 2 | POIIncompleteCopy |
| 6 | POI - Unclear Copy | 3 | POIClearerCopy |
| 8 | POI - Missing a Copy | 4 | POIMissingACopy |
| 9 | POI - Front Side of ID Required | 5 | POIFrontSideOfIDRequired |
| 10 | POI - ID/Passport Missing Expiry Date | 6 | POIIDPassportMissingExpiryDate |
| 11 | POI - Back Side Required | 7 | POIBackSideRequired |
| 12 | POI - Missing Name Details | 11->8 | POIMissingNameDetails |
| 13 | POI - Cannot Be Accepted | 12->9 | POICannotBeAccepted |
| 14 | POA - Missing Address Details | 13 | POAMissingAddressDetails |
| 15 | POA - Proof of Address Cannot Be Accepted | 14 | POAAddressCannotBeAccepted |
| 16 | POA - Under Different Name | 15 | POAAddressUnderDifferentName |
| 18 | POA - Unclear or Incomplete | 17 | POAUnclearOrIncomplete |
| 19 | POI and POA Cannot Be Same Document | 22 | POIandPOAPOICannotBePOA |
| 21 | POA - Missing Copy | 18 | POAMissingCopy |
| 22 | Missing ID and POA | 20 | MissingIDAndPOA |
| 25 | POI - Missing Name Details (v2) | 8 | POIMissingNameDetails |
| 26 | POI - Cannot Be Accepted (v2) | 9 | POICannotBeAccepted |
| 27 | POI - Under Different Name | 10 | POIUnderDifferentName |
| 28 | POA - Missing Name Details | 19 | POAMissingNameDetails |
| 29-35 | Selfie/video subtypes (Face Not Detected, Cropped, Scan, etc.) | 21 | 5211SelfieVideoGeneralRejection |
| 39 | SSN Card - Cannot Be Accepted | 26 | SSNCardMissingDocument |
| 40 | POI - Document Not US Visa | 27 | POINotUsVisa |
| 41 | POA - Box Address Not Accepted | 28 | POABoxNotAccepted |
| 42 | POI - Screenshot Not Accepted | 29 | POIScreenshotNotAccepted |
| 43 | POA - Back Side Required | 30 | POABackSideRequired |
| 44 | Selfie Motion Rejected | 34 | SelfieMotionRejectedEmail |
| 46 | POA - Business/Work Address Rejected | 33 | PoaBusinessWorkAddressRejectedEmail |
| 47 | POA - Not Acceptable | 32 | PoaNotAcceptableEmail |
| 48 | POA - Corrupted/Password Protected | 31 | PoaCorruptedOrPasswordProtectedEmail |
| 49 | POI - Visa Is Expired | 38 | PoiVisaIsExpiredEmail |
| 50 | POI - Visa Document Cropped/Unclear | 39 | PoiVisaDocumentCroppedOrUnclearEmail |
| 51 | POI - Visa Type Not Supported | 40 | PoiVisaTypeNotSupportedEmail |
| 52 | Proof of Income Rejected | 35 | ProofOfIncomeRejectedEmail |
| 53 | SSN - Unclear/Incomplete | 36 | SsnCardUnclearOrIncompleteDocumentEmail |
| 54 | SSN - Damaged Document | 37 | SsnCardDamagedDocumentEmail |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RejectReasonID | tinyint | NO | - | VERIFIED | Document rejection reason code. FK (WITH CHECK) to Dictionary.DocumentRejectReason(RejectReasonID). Leading key of composite CLUSTERED PK. TINYINT (max 255) - appropriate for the small controlled vocabulary of rejection reasons (54 values). |
| 2 | NotificationTypeID | int | NO | - | VERIFIED | Email notification template identifier. FK (WITH CHECK) to Dictionary.NotificationTypeName(NotificationTypeID). The notification service uses this ID to select the email template to send to the customer. 37 distinct values across 42 rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RejectReasonID | Dictionary.DocumentRejectReason | FK (WITH CHECK) | Document rejection reason code |
| NotificationTypeID | Dictionary.NotificationTypeName | FK (WITH CHECK) | Email notification template identifier |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views in the BackOffice SSDT repo reference this table. Consumed by application/notification service layer to resolve email templates on document rejection.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DocumentRejectReasonToNotificationType (config table)
- FK targets:
  |- Dictionary.DocumentRejectReason (table)
  |- Dictionary.NotificationTypeName (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentRejectReason | Table | FK on RejectReasonID |
| Dictionary.NotificationTypeName | Table | FK on NotificationTypeID |

### 6.2 Objects That Depend On This

None found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_DocumentRejectReasonToNotificationType | CLUSTERED PK | RejectReasonID ASC, NotificationTypeID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_DocumentRejectReasonToNotificationType | PK | Uniqueness of (RejectReasonID, NotificationTypeID) |
| FK_BackOffice_DocumentRejectReasonToNotificationType_NotificationTypeID | FK (WITH CHECK) | NotificationTypeID -> Dictionary.NotificationTypeName |
| FK_BackOffice_DocumentRejectReasonToNotificationType_RejectReasonID | FK (WITH CHECK) | RejectReasonID -> Dictionary.DocumentRejectReason |

---

## 8. Sample Queries

### 8.1 Get the notification template for a given rejection reason
```sql
SELECT r2n.RejectReasonID, drr.RejectReasonName,
       r2n.NotificationTypeID, ntn.NotificationType
FROM BackOffice.DocumentRejectReasonToNotificationType r2n WITH (NOLOCK)
JOIN Dictionary.DocumentRejectReason drr WITH (NOLOCK)
    ON drr.RejectReasonID = r2n.RejectReasonID
JOIN Dictionary.NotificationTypeName ntn WITH (NOLOCK)
    ON ntn.NotificationTypeID = r2n.NotificationTypeID
WHERE r2n.RejectReasonID = @RejectReasonID
```

### 8.2 Find rejection reasons that have no notification mapped
```sql
SELECT drr.RejectReasonID, drr.RejectReasonName
FROM Dictionary.DocumentRejectReason drr WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM BackOffice.DocumentRejectReasonToNotificationType r2n WITH (NOLOCK)
    WHERE r2n.RejectReasonID = drr.RejectReasonID
)
ORDER BY drr.RejectReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentRejectReasonToNotificationType | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.DocumentRejectReasonToNotificationType.sql*
