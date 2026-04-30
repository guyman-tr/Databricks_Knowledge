# Dictionary.ProviderType

> Lookup table classifying Electronic Verification providers by their verification method: electronic data matching or document scanning.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ProviderTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.ProviderType classifies Electronic Verification (EV) providers into two fundamental categories based on their verification methodology. Electronic verification providers match user data against authoritative databases (credit bureaus, government records). Document verification providers analyze uploaded identity documents and selfies using OCR and biometric technology.

This classification determines the verification workflow. Electronic providers produce instant results, while document providers require image upload and processing time. Some regulations accept electronic-only verification, while others require document verification as a fallback or primary method.

Provider type is assigned when a new EV provider is onboarded into the system (Dictionary.EvProvider). It determines which verification flow the user is routed through and affects the UI presented (data entry form vs document upload).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Binary classification. See individual element descriptions in Section 4.

---

## 3. Data Overview

| ProviderTypeID | Name | Meaning |
|---|---|---|
| 0 | ElectronicVerification | Provider verifies identity by matching user-submitted data against authoritative databases without requiring document uploads |
| 1 | DocumentsVerification | Provider verifies identity by scanning, analyzing, and validating uploaded identity documents and/or biometric selfies |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderTypeID | int | NO | - | CODE-BACKED | Primary key. Verification method: 0=ElectronicVerification (data matching), 1=DocumentsVerification (document/selfie scanning). Referenced by Dictionary.EvProvider. See [Provider Type](_glossary.md#provider-type). |
| 2 | Name | varchar(25) | YES | - | CODE-BACKED | Verification method label. PascalCase format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.EvProvider | ProviderTypeID | Explicit FK | Each EV provider is classified by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvProvider | Table | FK: ProviderTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ProviderType | CLUSTERED PK | ProviderTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List provider types
```sql
SELECT ProviderTypeID, Name FROM Dictionary.ProviderType WITH (NOLOCK) ORDER BY ProviderTypeID
```

### 8.2 Providers by type
```sql
SELECT pt.Name AS ProviderType, ep.Name AS Provider
FROM Dictionary.EvProvider ep WITH (NOLOCK)
JOIN Dictionary.ProviderType pt WITH (NOLOCK) ON ep.ProviderTypeID = pt.ProviderTypeID
ORDER BY pt.Name, ep.Name
```

### 8.3 Count providers per type
```sql
SELECT pt.Name, COUNT(*) AS ProviderCount
FROM Dictionary.EvProvider ep WITH (NOLOCK)
JOIN Dictionary.ProviderType pt WITH (NOLOCK) ON ep.ProviderTypeID = pt.ProviderTypeID
GROUP BY pt.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ProviderType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.ProviderType.sql*
