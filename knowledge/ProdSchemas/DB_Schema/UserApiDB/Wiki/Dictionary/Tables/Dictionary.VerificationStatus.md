# Dictionary.VerificationStatus

> Lookup table defining how a user's identity verification was completed - manual agent review or automated system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | VerificationStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.VerificationStatus indicates the method by which a user's identity was verified: no verification (None), manual review by a compliance agent (Manual), or automated electronic verification (System). This distinction matters for compliance reporting and audit trails.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

| VerificationStatusID | Name | Meaning |
|---|---|---|
| 0 | None | No identity verification performed yet |
| 1 | Manual | Identity verified by a compliance agent through manual document review |
| 2 | System | Identity verified automatically by the electronic verification system (EV providers) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VerificationStatusID | int | NO | - | CODE-BACKED | Primary key. Verification method: 0=None, 1=Manual (agent), 2=System (automated EV). See [Verification Status](_glossary.md#verification-status). |
| 2 | Name | varchar(20) | YES | - | CODE-BACKED | Method label for audit trails and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | VerificationStatusID | Lookup | Records verification method per user |

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
| PK_Dictionary_VerificationStatus | CLUSTERED PK | VerificationStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List verification statuses
```sql
SELECT VerificationStatusID, Name FROM Dictionary.VerificationStatus WITH (NOLOCK) ORDER BY VerificationStatusID
```

### 8.2 Manual vs system verification ratio
```sql
SELECT vs.Name, COUNT(*) AS UserCount FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.VerificationStatus vs WITH (NOLOCK) ON u.VerificationStatusID = vs.VerificationStatusID
WHERE u.VerificationStatusID > 0 GROUP BY vs.Name
```

### 8.3 Recently manually verified
```sql
SELECT u.CustomerID, u.VerificationDate FROM Customer.Users u WITH (NOLOCK)
WHERE u.VerificationStatusID = 1 ORDER BY u.VerificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.VerificationStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.VerificationStatus.sql*
