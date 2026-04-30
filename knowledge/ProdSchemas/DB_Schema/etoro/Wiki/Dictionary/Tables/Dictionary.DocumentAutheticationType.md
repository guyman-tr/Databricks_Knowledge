# Dictionary.DocumentAutheticationType

> Lookup table defining the types of document authentication processes used during KYC verification — Proof of Identity (POI), Proof of Address (POA), Selfie, and biometric variants.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TypeID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

As part of the Know Your Customer (KYC) process, customers must submit documents that are authenticated through different verification pipelines. This table classifies the type of authentication being performed: POI (Proof of Identity — passport, ID card, driving license), POA (Proof of Address — utility bill, bank statement), Selfie (face photo compared to document), and biometric variants (SelfieLiveliness — video-based liveness check, SelfieMotion — motion-based liveness detection).

Without this table, the system would have no way to categorize which authentication pipeline a document is being processed through. Each type has different validation rules, acceptance criteria, and third-party provider integrations. The table is referenced by `BackOffice.DocumentAuthenticationReasons` which stores the specific reasons/outcomes for each authentication type.

Data is static and represents the five fundamental document authentication workflows in the platform's KYC system.

---

## 2. Business Logic

### 2.1 KYC Authentication Pipeline Types

**What**: Each document type goes through a specialized authentication pipeline with different validation rules.

**Columns/Parameters Involved**: `TypeID`, `Type`

**Rules**:
- POI (1) — validates government-issued identity documents (passport, national ID, driving license). Checks include expiry date, name matching, document authenticity
- POA (2) — validates address documents (utility bills, bank statements). Checks include recency (typically within 3-6 months), name matching, address completeness
- Selfie (3) — face comparison between a live selfie and the POI document photo. May use AI-based facial recognition
- SelfieLiveliness (4) — video-based liveness detection to prevent spoofing with printed photos or screens
- SelfieMotion (5) — motion-based biometric verification requiring the user to perform specific head movements

**Diagram**:
```
KYC Authentication Types:
├── Document-Based:
│   ├── POI (1) — identity document verification
│   └── POA (2) — address document verification
└── Biometric:
    ├── Selfie (3) — face photo match
    ├── SelfieLiveliness (4) — video liveness check
    └── SelfieMotion (5) — motion liveness check
```

---

## 3. Data Overview

| TypeID | Type | Meaning |
|---|---|---|
| 1 | POI | Proof of Identity authentication — the system validates a government-issued document (passport, ID card, driving license) to confirm the customer's legal identity |
| 2 | POA | Proof of Address authentication — the system validates a utility bill, bank statement, or similar document to confirm the customer's current residential address |
| 3 | Selfie | Face photo verification — a live selfie is compared against the photo on the submitted POI document using facial recognition to prevent identity fraud |
| 4 | SelfieLiveliness | Video-based liveness detection — the customer records a short video to prove they are a real person, not a printed photo or screen recording. Prevents sophisticated spoofing attacks |
| 5 | SelfieMotion | Motion-based biometric check — the customer performs specific head movements (turn left, turn right, look up) to provide additional proof of physical presence |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TypeID | int | NO | - | CODE-BACKED | Primary key identifying the authentication type. 1=POI, 2=POA, 3=Selfie, 4=SelfieLiveliness, 5=SelfieMotion. Referenced by BackOffice.DocumentAuthenticationReasons.AutheticationTypeID (note: DDL preserves the original "Authetication" typo). |
| 2 | Type | varchar(50) | YES | - | CODE-BACKED | Human-readable authentication type name. Used in BackOffice KYC review UI and compliance reports. Nullable in DDL but all 5 rows have values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DocumentAuthenticationReasons | AutheticationTypeID | Implicit | Stores authentication reasons/outcomes per authentication type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DocumentAutheticationType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | References — stores reasons per auth type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DocumentAutheticationType | CLUSTERED | TypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all authentication types
```sql
SELECT  TypeID,
        Type
FROM    Dictionary.DocumentAutheticationType WITH (NOLOCK)
ORDER BY TypeID
```

### 8.2 Classify by verification category
```sql
SELECT  TypeID,
        Type,
        CASE WHEN TypeID <= 2 THEN 'Document-Based' ELSE 'Biometric' END AS Category
FROM    Dictionary.DocumentAutheticationType WITH (NOLOCK)
ORDER BY TypeID
```

### 8.3 Show authentication reasons per type
```sql
SELECT  dat.Type AS AuthType,
        dar.ReasonID,
        dar.ReasonName
FROM    Dictionary.DocumentAutheticationType dat WITH (NOLOCK)
        JOIN BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK) ON dat.TypeID = dar.AutheticationTypeID
ORDER BY dat.TypeID, dar.ReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DocumentAutheticationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentAutheticationType.sql*
