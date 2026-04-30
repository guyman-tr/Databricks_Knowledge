# Dictionary.PWMBAddAccountRequestStatus

> Lookup table defining 8 lifecycle states for PayWithMyBank (PWMB) account linking requests — from creation through bank authentication to funding system update or failure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PWMBAddAccountRequestStatus tracks the lifecycle of customer requests to link their bank accounts via the PayWithMyBank (PWMB) / Open Banking payment method. When a customer initiates an ACH/bank transfer deposit, the system must verify their bank account through the PWMB provider. This table defines the possible states of that verification process.

The flow goes: Created → SentToBankAuth → (BankAuthAddAccountSuccess or BankAuthAddAccountFailed) → FundingUpdated, with special states for name conflict checks and technical errors. No SQL consumers were found in the etoro SSDT project, suggesting this is consumed by application-layer code or a separate billing microservice.

---

## 2. Business Logic

### 2.1 PWMB Account Linking Lifecycle

**What**: Each status represents a stage in the bank account linking process.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **1 = Created** — Request initiated by the customer.
- **2 = SentToBankAuth** — Request forwarded to the PWMB bank authentication service.
- **3 = BankAuthAddAccountSuccess** — Bank confirmed the account is valid and belongs to the customer.
- **4 = BankAuthAddAccountFailed** — Bank authentication rejected the account.
- **5 = FundingUpdated** — eToro's funding system updated with the new bank account (terminal state for success).
- **6 = HasNameConflict** — Account holder name doesn't match the eToro customer name.
- **7 = NoNameConflict** — Name verification passed (no conflict).
- **8 = Technical** — Technical error during the process.

**Diagram**:
```
PWMB Account Linking States
1 (Created) ──▶ 2 (SentToBankAuth)
                    │
              ┌─────┴─────┐
              ▼            ▼
    3 (Success)      4 (Failed)
         │
    ┌────┴────┐
    ▼         ▼
6 (HasName  7 (NoName
 Conflict)   Conflict)
              │
              ▼
        5 (FundingUpdated) ← terminal success

8 (Technical) ← can occur at any stage
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | Created | Initial state — bank account linking request initiated by the customer. |
| 2 | SentToBankAuth | Request sent to the PWMB bank authentication provider for verification. |
| 3 | BankAuthAddAccountSuccess | Bank authentication succeeded — account verified and belongs to the customer. |
| 4 | BankAuthAddAccountFailed | Bank authentication failed — account could not be verified. |
| 5 | FundingUpdated | Terminal success — eToro's funding system updated with the linked bank account. |
| 6 | HasNameConflict | Account holder name does not match the eToro customer name. Requires manual review or customer correction. |
| 7 | NoNameConflict | Name verification passed — account holder name matches the customer. |
| 8 | Technical | Technical error occurred during the bank linking process. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the account request status. Values 1-8 represent the 8 lifecycle states. |
| 2 | Name | varchar(25) | YES | - | VERIFIED | Human-readable status label. Used in monitoring, logs, and admin dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK consumers found in etoro SSDT project. Likely consumed by application-layer billing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No known dependents in the SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryPWMBAddAccountRequestStatus | CLUSTERED PK | ID ASC | - | - | Active (FF=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryPWMBAddAccountRequestStatus | PRIMARY KEY | Unique status identifier |

---

## 8. Sample Queries

### 8.1 List all PWMB request statuses
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[PWMBAddAccountRequestStatus] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find terminal/error states
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[PWMBAddAccountRequestStatus] WITH (NOLOCK)
WHERE   Name IN ('FundingUpdated', 'BankAuthAddAccountFailed', 'Technical');
```

### 8.3 List success-path states
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[PWMBAddAccountRequestStatus] WITH (NOLOCK)
WHERE   ID IN (1, 2, 3, 7, 5)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PWMBAddAccountRequestStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PWMBAddAccountRequestStatus.sql*
