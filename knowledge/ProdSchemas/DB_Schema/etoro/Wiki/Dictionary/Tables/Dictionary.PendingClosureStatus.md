# Dictionary.PendingClosureStatus

> Lookup table defining the 3 account closure workflow states — No (not pending), Suggested for Closure, and Approved for Closure — controlling the account closure pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PendingClosureStatusID (TINYINT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PendingClosureStatus defines the three states in the account closure approval workflow. When a customer account is flagged for closure (due to regulatory action, fraud, inactivity, or customer request), it doesn't close immediately — it moves through a two-step approval process: first suggested, then approved.

This table exists because account closure is a high-impact, irreversible operation that requires oversight. The two-step workflow ensures that an account isn't closed accidentally — a supervisor or compliance officer must approve the suggestion before the closure is finalized.

The PendingClosureStatusID is stored in Customer.CustomerStatic and exposed through Customer.Customer and Customer.CustomerSafty views. It is widely referenced across BackOffice procedures including GetClosedAccountsByLastChangeDate, GetHistoryCustomer, GetBlockedCustomers, GetPendingClosureAccountsByLastChangeDate, AccountPendingClosureStatusChange, and multiple customer card procedures.

---

## 2. Business Logic

### 2.1 Closure Approval Workflow

**What**: Account closure follows a mandatory two-step approval flow: suggestion → approval → closure.

**Columns/Parameters Involved**: `PendingClosureStatusID`, `PendingClosureStatusName`

**Rules**:
- **No (1)** — The account is not pending closure. Normal operating state. The default for all active accounts.
- **Suggested for Closure (2)** — An operator or automated process has flagged the account for closure. Awaiting approval from a supervisor or compliance team.
- **Approved for Closure (3)** — The closure has been approved. The account will be closed in the next processing cycle or manually by operations.
- Only transitions: 1→2 (suggest), 2→3 (approve), 2→1 (reject suggestion), 3→1 (cancel approved closure).
- BackOffice.AccountPendingClosureStatusChange is the primary procedure for transitioning between states.

**Diagram**:
```
Account Closure Workflow
    1 = No (active)
        │
        ▼ (suggest)
    2 = Suggested for Closure
        │         │
        ▼         ▼ (reject)
    3 = Approved  → back to 1
        │
        ▼
    Account Closed
```

---

## 3. Data Overview

| PendingClosureStatusID | PendingClosureStatusName | Meaning |
|---|---|---|
| 1 | No | Account is not pending closure. Normal active state — the default for all customer accounts. |
| 2 | Suggested for Closure | Account has been flagged for closure by an operator or automated process. Awaiting supervisor/compliance approval before proceeding. |
| 3 | Approved for Closure | Closure has been approved by a supervisor. The account will be closed in the next processing cycle. Irreversible without manual intervention. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PendingClosureStatusID | tinyint | NO | - | VERIFIED | Primary key identifying the closure workflow state. 1=No (not pending), 2=Suggested for Closure, 3=Approved for Closure. Stored in Customer.CustomerStatic and exposed through Customer.Customer and CustomerSafty views. Managed by BackOffice.AccountPendingClosureStatusChange. |
| 2 | PendingClosureStatusName | varchar(50) | YES | - | VERIFIED | Human-readable label for the closure state. Displayed in BackOffice customer cards, closure reports, and regulatory compliance screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | PendingClosureStatusID | Implicit | Stores the closure workflow state per customer |
| Customer.Customer | PendingClosureStatusID | Implicit (via view) | Exposes closure state in the main customer view |
| Customer.CustomerSafty | PendingClosureStatusID | Implicit (via view) | Schema-bound customer safety view |
| Customer.IsCustomerFund | PendingClosureStatusID | Implicit (via view) | Fund customer identification view |
| History.Customer | PendingClosureStatusID | Implicit | Historical audit of customer closure states |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores PendingClosureStatusID per customer |
| History.Customer | Table | Historical audit of closure state changes |
| Customer.Customer | View | Exposes closure state |
| Customer.CustomerSafty | View | Schema-bound closure state view |
| Customer.IsCustomerFund | View | Fund identification with closure state |
| BackOffice.AccountPendingClosureStatusChange | Stored Procedure | Modifier — transitions closure state |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | Stored Procedure | Reader — lists accounts pending closure |
| BackOffice.GetClosedAccountsByLastChangeDate | Stored Procedure | Reader — lists closed accounts |
| BackOffice.GetBlockedCustomers | Stored Procedure | Reader — blocked customer reports |
| BackOffice.GetHistoryCustomer | Stored Procedure | Reader — customer history with closure info |
| BackOffice.GetCustomerByCID | Stored Procedure | Reader — customer card with closure state |
| BackOffice.GetCustomerByCIDVerification | Stored Procedure | Reader — verification with closure state |
| Customer.UpdateAccountUserInfoRemote | Stored Procedure | Modifier — remote account updates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PendingClosureStatus | CLUSTERED PK | PendingClosureStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PendingClosureStatus | PRIMARY KEY | Unique pending closure status identifier |

---

## 8. Sample Queries

### 8.1 List all pending closure statuses
```sql
SELECT  PendingClosureStatusID,
        PendingClosureStatusName
FROM    [Dictionary].[PendingClosureStatus] WITH (NOLOCK)
ORDER BY PendingClosureStatusID;
```

### 8.2 Count customers by closure state
```sql
SELECT  pcs.PendingClosureStatusName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[PendingClosureStatus] pcs WITH (NOLOCK)
        ON cs.PendingClosureStatusID = pcs.PendingClosureStatusID
GROUP BY pcs.PendingClosureStatusName;
```

### 8.3 Find accounts pending closure approval
```sql
SELECT  cs.CID,
        pcs.PendingClosureStatusName
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[PendingClosureStatus] pcs WITH (NOLOCK)
        ON cs.PendingClosureStatusID = pcs.PendingClosureStatusID
WHERE   cs.PendingClosureStatusID IN (2, 3);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PendingClosureStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PendingClosureStatus.sql*
