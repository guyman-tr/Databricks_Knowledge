# Dictionary.PhoneVerificationListType

> Lookup table defining 2 phone verification list categories — White (trusted) and Black (blocked) — for phone number allowlist/blocklist management.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | VerificationListTypeID (INT, PK) |
| **Partition** | PRIMARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PhoneVerificationListType defines the two categories for phone number list management in the verification system. Phone numbers can be placed on either a whitelist (pre-approved, trusted) or a blacklist (blocked, known-bad) to streamline verification decisions.

This table exists because the phone verification system needs to handle known-good and known-bad numbers efficiently. Rather than re-verifying every phone number through external providers (which costs money and adds latency), the system first checks if the number appears on a white or black list.

Whitelisted numbers (1=White) bypass full verification — they are pre-approved by compliance or operations. Blacklisted numbers (2=Black) are immediately flagged or rejected — they are known fraudulent, abusive, or otherwise prohibited numbers.

---

## 2. Business Logic

### 2.1 Binary List Classification

**What**: Phone numbers are classified into trusted (white) or blocked (black) lists.

**Columns/Parameters Involved**: `VerificationListTypeID`, `VerificationListType`

**Rules**:
- **White (1)** — Trusted phone numbers that bypass full verification. Pre-approved by compliance, internal operations, or automated trust scoring.
- **Black (2)** — Blocked phone numbers that trigger immediate rejection or flagging. Known fraudulent, shared across multiple bad actors, or associated with previous abuse.

**Diagram**:
```
Phone Verification Flow
    Phone number submitted
           │
           ├── On Black list? → YES → Block / Flag
           │
           ├── On White list? → YES → Bypass verification
           │
           └── Neither → Full external verification
```

---

## 3. Data Overview

| VerificationListTypeID | VerificationListType | Meaning |
|---|---|---|
| 1 | White | Trusted phone number list — numbers that have been pre-approved and can bypass full external verification. Used for internal numbers, VIP customers, or operationally verified numbers. |
| 2 | Black | Blocked phone number list — numbers associated with fraud, abuse, or policy violations. Any customer registering with a blacklisted number is flagged for additional scrutiny or blocked outright. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VerificationListTypeID | int | NO | - | CODE-BACKED | Primary key identifying the list type. 1=White (trusted), 2=Black (blocked). Used in phone verification list management. |
| 2 | VerificationListType | varchar(50) | YES | - | CODE-BACKED | Human-readable label for the list type. "White" or "Black". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Referenced by the phone verification subsystem at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PhoneVerificationListType | CLUSTERED PK | VerificationListTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PhoneVerificationListType | PRIMARY KEY | Unique list type identifier |

---

## 8. Sample Queries

### 8.1 List all verification list types
```sql
SELECT  VerificationListTypeID,
        VerificationListType
FROM    [Dictionary].[PhoneVerificationListType] WITH (NOLOCK)
ORDER BY VerificationListTypeID;
```

### 8.2 Identify the blacklist type ID
```sql
SELECT  VerificationListTypeID
FROM    [Dictionary].[PhoneVerificationListType] WITH (NOLOCK)
WHERE   VerificationListType = 'Black';
```

### 8.3 Display as allowlist/blocklist labels
```sql
SELECT  VerificationListTypeID,
        VerificationListType,
        CASE VerificationListTypeID
            WHEN 1 THEN 'Allowlist (trusted, bypass verification)'
            WHEN 2 THEN 'Blocklist (rejected, known bad)'
        END AS BusinessMeaning
FROM    [Dictionary].[PhoneVerificationListType] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PhoneVerificationListType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PhoneVerificationListType.sql*
