# Dictionary.DocumentSide

> Lookup table defining which side(s) of a document were captured in an uploaded KYC image — Front, Back, Both, or Not Recognizable.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SideID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a customer uploads a KYC document (passport, ID card, driving license, etc.), the system needs to track which side of the physical document was captured in the image. Some documents require both front and back sides to be submitted (e.g., national ID cards have data on both sides), while others only need the front (e.g., passports). This table classifies the image's content: NotRecognizable (system couldn't detect the side), Front, Back, or Front & Back (both sides in one image or two images processed together).

Without this table, the KYC review process would have no way to track document side completeness. A common rejection reason is "Back side required" — this table enables the system to detect when only the front was uploaded and automatically request the missing side.

The table is referenced by `BackOffice.CustomerDocumentToDocumentType` which stores the document side for each uploaded customer document image.

---

## 2. Business Logic

### 2.1 Document Side Completeness Tracking

**What**: Document side tracking enables automated completeness checks for two-sided documents.

**Columns/Parameters Involved**: `SideID`, `Name`

**Rules**:
- NotRecognizable (0) — the system's document recognition could not determine which side was uploaded. Requires manual review
- Front (1) — only the front side of the document was captured. May be sufficient for single-sided documents or may trigger a "Back side required" request
- Back (2) — only the back side was captured. Usually insufficient on its own — the front is almost always required
- Front & Back (3) — both sides are available. The document is considered complete from a side perspective

---

## 3. Data Overview

| SideID | Name | Meaning |
|---|---|---|
| 0 | NotRecognizable | The automated document recognition system could not determine which side of the document was captured — the image may be unclear, rotated, or not a recognizable document format. Requires manual KYC review |
| 1 | Front | The front side of the document was captured — for passports and single-sided docs this is sufficient; for national ID cards the back side will also be required |
| 2 | Back | The back side of the document was captured — typically uploaded as a second image after the front was already submitted. On its own, usually insufficient for verification |
| 3 | Front & Back | Both sides of the document are available — either captured in a single image (e.g., scanned as one page) or both individual uploads have been matched. The document is side-complete |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SideID | int | NO | - | CODE-BACKED | Primary key identifying the document side. 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. Referenced by BackOffice.CustomerDocumentToDocumentType.DocumentSideID. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable side label. Used in BackOffice document review UI and KYC status displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDocumentToDocumentType | DocumentSideID | Implicit | Stores which side was captured for each uploaded document image |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DocumentSide (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | References — document side per uploaded image |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DocumentSide | CLUSTERED | SideID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all document sides
```sql
SELECT  SideID,
        Name
FROM    Dictionary.DocumentSide WITH (NOLOCK)
ORDER BY SideID
```

### 8.2 Find documents missing back side
```sql
SELECT  cdt.CID,
        cdt.DocumentID,
        ds.Name AS CapturedSide
FROM    BackOffice.CustomerDocumentToDocumentType cdt WITH (NOLOCK)
        JOIN Dictionary.DocumentSide ds WITH (NOLOCK) ON cdt.DocumentSideID = ds.SideID
WHERE   cdt.DocumentSideID = 1  -- Front only
```

### 8.3 Document side distribution
```sql
SELECT  ds.Name AS DocumentSide,
        COUNT(*) AS DocumentCount
FROM    BackOffice.CustomerDocumentToDocumentType cdt WITH (NOLOCK)
        JOIN Dictionary.DocumentSide ds WITH (NOLOCK) ON cdt.DocumentSideID = ds.SideID
GROUP BY ds.Name
ORDER BY DocumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DocumentSide | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentSide.sql*
