# Dictionary.TwoFVStatus

> Lookup table defining the three states of two-factor verification (2FA) for a customer account — None, NotRequired, or Required — controlling whether the system enforces a verification code challenge during sensitive operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TwoFVStatusID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on TwoFVStatusID) |

---

## 1. Business Meaning

Dictionary.TwoFVStatus defines the possible states of two-factor verification (2FA) for customer accounts. Each customer's account carries a TwoFVStatusID that tells the system whether to enforce a 2FA challenge when the customer attempts a protected operation (withdrawal, password reset, login from new device, etc.).

Without this table, the system would have no way to distinguish between customers who have never set up 2FA (None), customers exempt from 2FA requirements (NotRequired), and customers who must provide a verification code (Required). This three-state model allows for both opt-in 2FA and regulatory-mandated 2FA enforcement.

The status is stored on the customer's profile and checked by authentication and withdrawal procedures. When a customer's status is "Required", the system blocks the sensitive operation until a valid one-time code is submitted via the method defined in TwoFactorVerificationSendMethodType (SMS or call).

---

## 2. Business Logic

### 2.1 Three-State 2FA Enforcement Model

**What**: Accounts exist in one of three 2FA states that determine whether verification codes are required.

**Columns/Parameters Involved**: `TwoFVStatusID`, `Name`

**Rules**:
- ID 0 (None) — customer has not configured 2FA; no verification code is required but the system may prompt setup
- ID 1 (NotRequired) — 2FA has been explicitly waived for this account (e.g., corporate account, internal test user, or regulation doesn't mandate it)
- ID 2 (Required) — customer must provide a verification code for protected operations; system blocks the operation until code is validated
- Transition: None → Required happens when customer enables 2FA or when regulation mandates it
- NotRequired is typically set by compliance or operations staff, not by the customer

**Diagram**:
```
2FA Status Lifecycle:
  ┌──────────┐     Customer enables     ┌──────────┐
  │  0=None  │ ────────2FA──────────►  │2=Required│
  └──────────┘                          └──────────┘
       │                                      ▲
       │  Compliance/ops waive                │ Regulation mandates
       ▼                                      │
  ┌──────────────┐                            │
  │1=NotRequired │ ───────────────────────────┘
  └──────────────┘    (rare: policy change)
```

---

## 3. Data Overview

| TwoFVStatusID | Name | Meaning |
|---|---|---|
| 0 | None | Default state for accounts that have not configured two-factor authentication. The customer can still perform operations but may be prompted to set up 2FA for security. |
| 1 | NotRequired | Explicit exemption from 2FA — set by operations/compliance for accounts where verification codes are unnecessary (e.g., institutional accounts, internal testing, or jurisdictions without 2FA mandates). |
| 2 | Required | 2FA is active and enforced — the customer must enter a valid one-time verification code (delivered via SMS or call) before sensitive operations proceed. Most common state for verified retail accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TwoFVStatusID | int | NO | - | CODE-BACKED | Unique identifier for the 2FA status: 0=None (not configured), 1=NotRequired (explicitly exempt), 2=Required (enforced). Referenced by customer account profiles to determine 2FA enforcement. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable label for the 2FA status. Nullable by DDL but all current values are populated. Used in BackOffice displays and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer profiles | TwoFVStatusID | Implicit | Customer account records reference this table to store the account's 2FA enforcement state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TwoFVStatus (table)
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
| PK_TwoFVStatusDictionary | CLUSTERED | TwoFVStatusID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all 2FA statuses
```sql
SELECT  TwoFVStatusID,
        Name
FROM    [Dictionary].[TwoFVStatus] WITH (NOLOCK)
ORDER BY TwoFVStatusID;
```

### 8.2 Resolve a customer's 2FA status to its label
```sql
SELECT  s.Name AS TwoFAStatus
FROM    [Dictionary].[TwoFVStatus] s WITH (NOLOCK)
WHERE   s.TwoFVStatusID = 2; -- Required
```

### 8.3 Check if 2FA is enforced for a specific status ID
```sql
SELECT  CASE WHEN TwoFVStatusID = 2 THEN 'Yes - code required'
             WHEN TwoFVStatusID = 1 THEN 'No - explicitly exempt'
             ELSE 'No - not configured'
        END AS TwoFAEnforcement
FROM    [Dictionary].[TwoFVStatus] WITH (NOLOCK)
ORDER BY TwoFVStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TwoFVStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TwoFVStatus.sql*
