# Dictionary.VerifiedByStatus

> Lookup table defining how a customer's identity was verified — None, Manual (human review), or Electronic (automated EID check) — classifying the verification method used for KYC compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | VerifiedByStatusId (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on VerifiedByStatusId) |

---

## 1. Business Meaning

Dictionary.VerifiedByStatus classifies the method used to verify a customer's identity during the KYC process. When a customer submits identity documents, the verification can be performed either by a human compliance officer (Manual) or by an automated electronic identity verification system (Electronic). This distinction matters for regulatory reporting and audit trails — regulators may require different confidence levels for manual vs electronic verification.

Without this table, the system could not distinguish between hand-reviewed and machine-verified identities. Regulatory frameworks (MiFID II, CySEC, ASIC) require disclosure of the verification method, and some operations may be restricted based on whether identity was verified manually or electronically.

The table is referenced by customer profiles to record which verification method was used. The three states (None, Manual, Electronic) cover the full lifecycle from unverified accounts to fully automated EID-verified accounts.

---

## 2. Business Logic

### 2.1 Verification Method Classification

**What**: Three distinct methods for how a customer's identity was confirmed.

**Columns/Parameters Involved**: `VerifiedByStatusId`, `Name`

**Rules**:
- ID 0 (None) — customer identity has not been verified by any method; default state for new accounts
- ID 1 (Manual) — a compliance officer manually reviewed the customer's submitted documents (passport, utility bill, etc.) and confirmed identity
- ID 2 (Electronic) — an automated electronic identity verification system (GDC, Au10tix, or similar EID provider) confirmed the customer's identity without human intervention
- Electronic verification is faster and more scalable, but Manual may be required for complex cases (blurry documents, name mismatches, PEP screening)
- The method is recorded for audit purposes — regulators can query which customers were verified electronically vs manually

**Diagram**:
```
Verification Method Flow:
  Customer submits documents
         │
         ├─ Auto-EID pass ──► VerifiedByStatus = 2 (Electronic)
         │
         ├─ Auto-EID fail ──► Queue for human review
         │                          │
         │                          ▼
         │                    VerifiedByStatus = 1 (Manual)
         │
         └─ Not yet reviewed ► VerifiedByStatus = 0 (None)
```

---

## 3. Data Overview

| VerifiedByStatusId | Name | Meaning |
|---|---|---|
| 0 | None | No verification method has been applied — the customer's identity is unverified. Default state for accounts that haven't completed any KYC verification step. |
| 1 | Manual | A human compliance officer reviewed the customer's identity documents and confirmed their identity. Used for complex cases that automated systems cannot resolve (blurry images, name transliterations, PEP matches). |
| 2 | Electronic | An automated Electronic Identity (EID) verification system confirmed the customer's identity. Faster and more scalable than manual review; used for straightforward cases where documents are clear and data matches. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VerifiedByStatusId | int | NO | - | CODE-BACKED | Unique identifier for the verification method: 0=None (unverified), 1=Manual (human review), 2=Electronic (automated EID). Stored on customer profiles to record how identity was confirmed for regulatory audit purposes. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Display label for the verification method: "None", "Manual", or "Electronic". Used in compliance reporting and BackOffice customer displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer profiles | VerifiedByStatusId | Implicit | Records the verification method used for each customer's identity confirmation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.VerifiedByStatus (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in SSDT codebase search (referenced implicitly by customer profile columns).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_VerifiedByStatus | CLUSTERED | VerifiedByStatusId ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all verification methods
```sql
SELECT  VerifiedByStatusId,
        Name
FROM    [Dictionary].[VerifiedByStatus] WITH (NOLOCK)
ORDER BY VerifiedByStatusId;
```

### 8.2 Translate a verification status ID to label
```sql
SELECT  Name AS VerificationMethod
FROM    [Dictionary].[VerifiedByStatus] WITH (NOLOCK)
WHERE   VerifiedByStatusId = 2; -- Electronic
```

### 8.3 Show all verification methods with their business impact
```sql
SELECT  VerifiedByStatusId,
        Name,
        CASE VerifiedByStatusId
            WHEN 0 THEN 'Identity not confirmed — restricted platform access'
            WHEN 1 THEN 'Human review — compliance officer confirmed identity'
            WHEN 2 THEN 'Automated — EID system confirmed identity'
        END AS BusinessImpact
FROM    [Dictionary].[VerifiedByStatus] WITH (NOLOCK)
ORDER BY VerifiedByStatusId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.VerifiedByStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.VerifiedByStatus.sql*
