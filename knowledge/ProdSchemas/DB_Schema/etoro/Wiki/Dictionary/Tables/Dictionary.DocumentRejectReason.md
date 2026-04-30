# Dictionary.DocumentRejectReason

> Lookup table enumerating 49 specific reasons why a KYC document was rejected — covering POI, POA, Selfie, SSN, and Visa document categories with granular rejection descriptions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RejectReasonID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a KYC compliance officer or automated system rejects a customer-submitted document, a specific reason must be recorded to inform the customer what was wrong and what they need to fix. This table provides 49 granular rejection reasons organized by document type: POI (expired, incomplete, unclear, missing name), POA (older than 3 months, missing address, wrong name), Selfie (unclear, face mismatch, black and white), and specialized reasons for SSN cards, US Visas, and proof of income.

Without this table, the platform would have no standardized set of rejection reasons. This standardization is critical for: (1) customer communication — the rejection reason is displayed to the customer so they know exactly what to resubmit, (2) compliance audit trails — regulators require documented reasons for KYC rejections, (3) analytics — tracking the most common rejection reasons helps identify UX or process improvements.

The table is referenced by `BackOffice.DocumentRejectReasonToNotificationType` (which maps rejection reasons to notification templates sent to customers) and by document audit reporting procedures.

---

## 2. Business Logic

### 2.1 Rejection Reason Categories by Document Type

**What**: Rejection reasons are organized by the document type they apply to, with each category having type-specific validation failures.

**Columns/Parameters Involved**: `RejectReasonID`, `RejectReasonName`

**Rules**:
- **POI reasons** (4-11, 25-27, 42): Expired, Incomplete, Unclear, Missing, Front side, Expiry date missing, Back side, Missing name, Cannot be accepted, Under different name, Screenshot not accepted
- **POA reasons** (12-16, 18, 21, 28, 41, 43, 46-48): Older than 3 months, Missing issue date, Missing address, Cannot be accepted, Under different name, Unclear/incomplete, Missing, PO Box not accepted, Back side, Business/Work address, Front side, Corrupted file
- **POI+POA combined** (19, 22): One doc per requirement, Missing both POI and POA
- **Selfie reasons** (29-35, 44): Unclear, Cannot be accepted, Face doesn't match, Black and white, Overmatch, Other, Liveliness rejected, Motion rejected
- **SSN Card** (38-39, 53-54): Cannot be accepted, Missing, Unclear, Damaged
- **US Visa** (40, 49-51): Not a US Visa, Expired, Cropped/Unclear, Type not supported
- **Other** (0, 23-24, 36-37, 45, 52): General (Other), Underage, Fake Document, Duplicate, High Risk Country, Not Needed, Proof of Income Rejected

---

## 3. Data Overview

| RejectReasonID | RejectReasonName | Meaning |
|---|---|---|
| 4 | POI - Expired Document | The submitted identity document (passport, ID card, driving license) has passed its expiry date — the customer must resubmit a valid, non-expired document |
| 12 | POA - Older than 3 months | The proof of address document was issued more than 3 months ago — most regulations require POA documents within 3-6 months. Customer must submit a recent document |
| 24 | Fake Document | The document appears to be fraudulent — digitally altered, physically tampered with, or not a genuine government/institutional document. Triggers compliance escalation |
| 31 | Selfie - Face doesn't match | The face in the selfie does not match the photo on the submitted POI document — indicates potential identity fraud or the wrong person submitted the documents |
| 45 | Not Needed | The document was submitted but is not required for this customer's KYC level — no rejection per se, but the document is marked as unnecessary |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RejectReasonID | tinyint | NO | - | VERIFIED | Primary key identifying the rejection reason. 49 values from 0 (Other) to 54 (SSN Card - Damaged). Non-sequential — IDs 1-3, 7, 17, 20 are skipped. Referenced by BackOffice.DocumentRejectReasonToNotificationType for customer notification routing. |
| 2 | RejectReasonName | varchar(200) | YES | - | VERIFIED | Human-readable rejection reason displayed to the customer in their document status UI and in rejection notification emails. Prefixed by document type (POI/POA/Selfie) for clarity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DocumentRejectReasonToNotificationType | RejectReasonID | Implicit | Maps rejection reasons to notification types — determines which email template is sent to the customer when a document is rejected |
| dbo.JOB_Alert_FullReportForAu10tix | RejectReasonID | JOIN | Au10tix integration report includes rejection reason for automated document verification results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DocumentRejectReason (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentRejectReasonToNotificationType | Table | References — maps reasons to notification templates |
| dbo.JOB_Alert_FullReportForAu10tix | Procedure | Reader — Au10tix reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.RejectReason | CLUSTERED | RejectReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all rejection reasons
```sql
SELECT  RejectReasonID,
        RejectReasonName
FROM    Dictionary.DocumentRejectReason WITH (NOLOCK)
ORDER BY RejectReasonID
```

### 8.2 Group rejection reasons by document type
```sql
SELECT  CASE
            WHEN RejectReasonName LIKE 'POI%' THEN 'POI'
            WHEN RejectReasonName LIKE 'POA%' THEN 'POA'
            WHEN RejectReasonName LIKE 'Selfie%' THEN 'Selfie'
            WHEN RejectReasonName LIKE 'SSN%' THEN 'SSN'
            ELSE 'General'
        END AS DocumentType,
        COUNT(*) AS ReasonCount
FROM    Dictionary.DocumentRejectReason WITH (NOLOCK)
GROUP BY CASE
            WHEN RejectReasonName LIKE 'POI%' THEN 'POI'
            WHEN RejectReasonName LIKE 'POA%' THEN 'POA'
            WHEN RejectReasonName LIKE 'Selfie%' THEN 'Selfie'
            WHEN RejectReasonName LIKE 'SSN%' THEN 'SSN'
            ELSE 'General'
        END
```

### 8.3 Show rejection reasons with their notification mapping
```sql
SELECT  drr.RejectReasonName,
        rrn.NotificationTypeID
FROM    Dictionary.DocumentRejectReason drr WITH (NOLOCK)
        JOIN BackOffice.DocumentRejectReasonToNotificationType rrn WITH (NOLOCK) ON drr.RejectReasonID = rrn.RejectReasonID
ORDER BY drr.RejectReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DocumentRejectReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentRejectReason.sql*
