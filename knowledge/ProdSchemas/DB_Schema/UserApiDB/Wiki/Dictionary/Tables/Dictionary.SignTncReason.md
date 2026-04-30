# Dictionary.SignTncReason

> Lookup table defining the method or reason by which a user accepted the Terms and Conditions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SignTncReason tracks the consent mechanism through which users accepted the platform's Terms and Conditions. This is essential for compliance audit trails - regulators require proof that users consented and the method of consent. Different methods carry different legal weight.

"By User" is the strongest consent (explicit action), "DeepLink" is consent via a redirect flow (e.g., mobile app), and "Negative Consent" means the user was deemed to have accepted if they did not explicitly reject within a given timeframe.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| ReasonID | Name | Meaning |
|---|---|---|
| 0 | By User | User explicitly clicked "Accept" in the Terms and Conditions UI - strongest consent evidence |
| 1 | DeepLink | TnC accepted via a deep link redirect flow (mobile app or external referral) |
| 2 | Negative Consent | Deemed acceptance - user did not reject within the allowed timeframe after being notified of changes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | CODE-BACKED | Primary key. Consent method: 0=By User (explicit), 1=DeepLink (redirect), 2=Negative Consent (deemed). See [Sign TnC Reason](_glossary.md#sign-tnc-reason). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Consent method label for audit reports and compliance records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer TnC acceptance tables | ReasonID | Lookup | Records consent method for each TnC acceptance event |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_SignTncReason | CLUSTERED PK | ReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all TnC consent methods
```sql
SELECT ReasonID, Name FROM Dictionary.SignTncReason WITH (NOLOCK) ORDER BY ReasonID
```

### 8.2 Consent method distribution
```sql
SELECT sr.Name, COUNT(*) AS AcceptanceCount
FROM Customer.TncAcceptance t WITH (NOLOCK)
JOIN Dictionary.SignTncReason sr WITH (NOLOCK) ON t.ReasonID = sr.ReasonID
GROUP BY sr.Name ORDER BY AcceptanceCount DESC
```

### 8.3 Find negative consent acceptances
```sql
SELECT t.CustomerID, t.AcceptedDate
FROM Customer.TncAcceptance t WITH (NOLOCK)
WHERE t.ReasonID = 2 ORDER BY t.AcceptedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.SignTncReason | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SignTncReason.sql*
