# Dictionary.AuthenticationReason

> Comprehensive lookup table of 108 document authentication reasons — covering ID verification outcomes from "Ok" through fraud detection, quality issues, data mismatches, and forgery indicators — used by the KYC document verification pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AuthenticationReason catalogs every possible outcome from the automated and manual document authentication process during KYC (Know Your Customer) verification. When a customer uploads identity documents (passport, driver's license, utility bill, etc.), the verification system or compliance officer assigns one or more authentication reasons to explain the verification result.

This table is critical for the compliance pipeline. Each reason code tells the system and the compliance team exactly what was found during document review — from successful verification (0=Ok) through specific failure modes like expired documents, name mismatches, forgery detection, bad image quality, and fraud indicators. These reason codes drive automated document rejection, re-upload requests, and escalation to manual review.

Referenced by BackOffice.DocumentAuthenticationReasons (stores reasons per document), BackOffice.SetDocumentAuthenticationReasons (writes reasons), BackOffice.GetDocument and BackOffice.GetAllUserDocuments (reads reasons for display), and BackOffice.GetDocumentReason (resolves reason IDs to names).

---

## 2. Business Logic

### 2.1 Authentication Outcome Categories

**What**: Classification of document verification results by failure type.

**Columns/Parameters Involved**: `ReasonID`, `Reason`

**Rules**:
- **Success (0, 46)**: Ok (0) = document passed verification, Match (46) = biometric/data match confirmed
- **Document validity (1-2, 35, 40, 65-66, 96)**: Expired, no expiration date, issue date checks, document number issues
- **Identity mismatches (3, 14-15, 23-24, 34, 37, 39, 67-73)**: Name, gender, DOB, address, nationality, document number inconsistencies
- **Fraud indicators (4, 17-18, 54, 80-84, 97-102)**: Forged documents, vendor DB flags, police DB flags, digital tampering, edited MRZ/ID, dark web matches
- **Quality issues (19-21, 25-29, 31, 43-44, 57-64, 85-92)**: Screenshots, photos of screens, printed paper, blurred, dark, glare, damaged, cropped, covered
- **Biometric failures (32, 47-52, 103-106)**: Face not detected, faces don't match, forged selfie, fake webcam, emulator, spoofing, liveness not detected
- **Document type issues (10-11, 30, 33, 41-42, 49, 91)**: Unrecognized, unsupported, excluded document types

**Diagram**:
```
Document Authentication Flow:

  Document Upload
       │
       ▼
  Automated Verification (AI/Vendor)
       │
       ├── Pass ──► ReasonID 0 (Ok) or 46 (Match) ──► Verified ✓
       │
       ├── Fail (specific) ──► ReasonID 1-107 ──► Categorized rejection
       │     ├── Identity Mismatch (3, 14-15, 23-24...)
       │     ├── Fraud/Forgery (4, 17-18, 80-84, 97-102)
       │     ├── Quality Issue (19-21, 85-92)
       │     ├── Document Invalid (1-2, 10-11, 30, 91)
       │     └── Biometric Fail (32, 47-52, 103-106)
       │
       └── Unmapped ──► ReasonID 22 ──► Manual review required
```

---

## 3. Data Overview

| ReasonID | Reason | Meaning |
|---|---|---|
| 0 | Ok | Document passed all verification checks. Identity confirmed. Customer can proceed with KYC process. |
| 4 | Forged Document | AI or manual review detected the document is fabricated. Strongest fraud indicator — triggers compliance escalation and potential account closure. |
| 47 | Faces Do Not Match | Biometric comparison between the selfie and the document photo failed. Customer's face doesn't match their ID photo. May indicate identity theft or use of someone else's documents. |
| 80 | Not Authentic - Digital Tampering | Document image shows signs of digital editing (Photoshop, image manipulation). Detected by AI analysis of pixel patterns, compression artifacts, or metadata inconsistencies. |
| 107 | Issuing country - US | Document was issued in the United States. US-specific regulatory restriction — US-issued documents may require special handling under SEC/FINRA regulations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | VERIFIED | Primary key identifying the authentication outcome. 0=Ok (success), 1-107=specific failure/information codes. Stored in BackOffice.DocumentAuthenticationReasons per document. Written by BackOffice.SetDocumentAuthenticationReasons. Read by BackOffice.GetDocument and BackOffice.GetAllUserDocuments for compliance display. |
| 2 | Reason | varchar(50) | YES | - | VERIFIED | Human-readable description of the authentication outcome. Nullable but all current rows have values. Resolved in queries by BackOffice.GetDocumentReason functions. Displayed to compliance officers in the BackOffice document review interface. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DocumentAuthenticationReasons | ReasonID | Implicit | Stores authentication reasons per customer document |
| BackOffice.SetDocumentAuthenticationReasons | @ReasonID | Parameter INSERT | Writes authentication results after document review |
| BackOffice.GetDocument | ReasonID | JOIN | Returns document details with authentication reasons |
| BackOffice.GetAllUserDocuments | ReasonID | JOIN | Returns all customer documents with reasons |
| BackOffice.GetDocumentReason | ReasonID | Lookup | Resolves reason ID to display name |
| BackOffice.GetDocumentAuthenticationReasons | ReasonID | SELECT | Returns reasons for a specific document |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | Stores reason-to-document mappings |
| BackOffice.SetDocumentAuthenticationReasons | Stored Procedure | Writer — records authentication results |
| BackOffice.GetDocument | Stored Procedure | Reader — document display |
| BackOffice.GetAllUserDocuments | Stored Procedure | Reader — all documents for customer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AuthenticationReasons | CLUSTERED PK | ReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AuthenticationReasons | PRIMARY KEY | Unique authentication reason identifier on DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 List all authentication reasons
```sql
SELECT  ReasonID,
        Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
ORDER BY ReasonID;
```

### 8.2 Find all fraud-related reasons
```sql
SELECT  ReasonID,
        Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
WHERE   Reason LIKE '%Forged%'
   OR   Reason LIKE '%Fraud%'
   OR   Reason LIKE '%Not Authentic%'
   OR   Reason LIKE '%Tampering%'
   OR   Reason LIKE '%Dark Web%'
ORDER BY ReasonID;
```

### 8.3 Count documents by authentication reason
```sql
SELECT  dar.Reason,
        COUNT(*) AS DocumentCount
FROM    BackOffice.DocumentAuthenticationReasons bdar WITH (NOLOCK)
JOIN    Dictionary.AuthenticationReason dar WITH (NOLOCK)
        ON bdar.ReasonID = dar.ReasonID
GROUP BY dar.Reason
ORDER BY DocumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AuthenticationReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AuthenticationReason.sql*
