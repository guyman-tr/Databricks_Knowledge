# Customer.TncSignature

> Records each instance of a user signing/accepting Terms and Conditions, including the method of consent and document version.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | SignID (INT IDENTITY, PK NONCLUSTERED) / GCID+SignDate (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (NC PK + clustered on GCID+SignDate + NC on SignDate) |

---

## 1. Business Meaning

Customer.TncSignature maintains the complete audit trail of Terms and Conditions (TnC) acceptances. Each row represents one TnC signing event for one user, recording when they signed, which document version they accepted, the consent method (explicit click, deep link, or negative consent), and whether the acceptance was implicit.

Multiple rows per user are expected - users re-sign TnC when terms are updated. The clustered index on (GCID, SignDate DESC) optimizes retrieval of the latest acceptance for each user.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional audit table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SignID | int (IDENTITY) | NO | - | CODE-BACKED | Surrogate PK (NONCLUSTERED). Auto-incrementing signature record identifier. |
| 2 | GCID | int | NO | - | CODE-BACKED | Part of clustered index. Global Customer ID. Multiple signatures per user expected. |
| 3 | SignDate | datetime | NO | - | CODE-BACKED | Part of clustered index (DESC). When the user accepted the TnC. |
| 4 | DocumentID | int | YES | - | CODE-BACKED | TnC document version identifier. Tracks which version of the terms was accepted. |
| 5 | ReasonID | int | NO | 0 | CODE-BACKED | FK to Dictionary.SignTncReason. Consent method: 0=By User (explicit), 1=DeepLink, 2=Negative Consent. Default: 0. See [Sign TnC Reason](_glossary.md#sign-tnc-reason). |
| 6 | IsImplicit | bit | YES | - | CODE-BACKED | Whether this was an implicit acceptance (e.g., continuing to use the platform after notification) vs explicit action. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReasonID | Dictionary.SignTncReason | Explicit FK | Consent mechanism |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SignTnc | GCID | SP writes | Records TnC acceptance |
| Customer.GetTncSignatures | GCID | SP reads | Returns TnC history |
| Customer.GetTncSignaturesByDocType | GCID | SP reads | Returns TnC by document type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.TncSignature (table)
  +-- Dictionary.SignTncReason (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.SignTncReason | Table | FK: ReasonID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SignTnc | Stored Procedure | Inserts rows |
| Customer.GetTncSignatures | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | NC PK | SignID | - | - | Active (PAGE compressed) |
| Idx_Customer_TncSignature | CLUSTERED | GCID ASC, SignDate DESC | - | - | Active (PAGE compressed) |
| IX_TncSign_SignDate | NONCLUSTERED | SignDate | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | (0) for ReasonID |
| FK_TncSignature_ReasonID | FOREIGN KEY | ReasonID -> Dictionary.SignTncReason |

---

## 8. Sample Queries

### 8.1 Get latest TnC signature for a user
```sql
SELECT TOP 1 SignID, SignDate, DocumentID, sr.Name AS ConsentMethod, IsImplicit
FROM Customer.TncSignature t WITH (NOLOCK)
JOIN Dictionary.SignTncReason sr WITH (NOLOCK) ON t.ReasonID = sr.ReasonID
WHERE t.GCID = @GCID ORDER BY t.SignDate DESC
```

### 8.2 Full TnC history for a user
```sql
SELECT SignDate, DocumentID, sr.Name AS ConsentMethod, IsImplicit
FROM Customer.TncSignature t WITH (NOLOCK)
JOIN Dictionary.SignTncReason sr WITH (NOLOCK) ON t.ReasonID = sr.ReasonID
WHERE t.GCID = @GCID ORDER BY t.SignDate DESC
```

### 8.3 Users who signed via negative consent
```sql
SELECT GCID, SignDate FROM Customer.TncSignature WITH (NOLOCK) WHERE ReasonID = 2 ORDER BY SignDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.TncSignature | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.TncSignature.sql*
