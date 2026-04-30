# Dictionary.AccountStatus

> Lookup table defining the possible open/closed states of an eToro trading account.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountStatusID (TINYINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountStatus is a two-value lookup table that defines whether an eToro trading account is open (active) or closed. Every customer account in the platform references this table to determine its operational state.

This table is foundational to account lifecycle management. Without it, the system cannot distinguish between active accounts that can trade, deposit, and withdraw, and closed accounts that must be excluded from all operations. Procedures across BackOffice, Customer, and Hedge schemas rely on this lookup to filter, report, and enforce account state rules.

AccountStatus rows are static reference data — they are never inserted or modified by application flows. They are read by Customer.CustomerStatic (which stores AccountStatusID per customer), by multiple BackOffice procedures that report on blocked/closed customers, and by Hedge procedures that manage hedge account states.

---

## 2. Business Logic

### 2.1 Account Open/Close Lifecycle

**What**: Binary account state controlling all platform access.

**Columns/Parameters Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- An account is either fully active (Open) or fully deactivated (Closed) — there is no intermediate state at this level
- The granular restriction states (blocked, pending verification, deposit blocked, etc.) are managed by Dictionary.PlayerStatus, not AccountStatus
- When an account transitions to Closed (2), all positions must be liquidated and pending withdrawals processed before the state change is finalized
- AccountStatus=Closed is a terminal state — accounts do not transition back to Open

**Diagram**:
```
Account Created ──► [1: Open] ──► (trade, deposit, withdraw, copy)
                        │
                    Account Closure
                        │
                        ▼
                   [2: Closed] ──► (no activity, positions liquidated)
                   (terminal)
```

---

## 3. Data Overview

| AccountStatusID | AccountStatusName | Meaning |
|---|---|---|
| 1 | Open | Account is fully active — the customer can log in, trade, deposit, withdraw, copy traders, and use all platform features. This is the default state for all new accounts after registration. |
| 2 | Closed | Account has been permanently deactivated. All open positions have been liquidated, pending withdrawals processed, and the customer can no longer access the platform. Triggered by customer request, regulatory action, or compliance decisions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountStatusID | tinyint | NO | - | CODE-BACKED | Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted). Referenced by Customer.CustomerStatic.AccountStatusID and Hedge.AccountStatus tables. See [Account Status](_glossary.md#account-status). (Dictionary.AccountStatus) |
| 2 | AccountStatusName | varchar(50) | YES | - | CODE-BACKED | Human-readable label for the account state. Used in BackOffice reporting procedures (e.g., BackOffice.GetBlockedCustomers, BackOffice.GetClosedAccountsByLastChangeDate) to display account state in administrative UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | AccountStatusID | Implicit Lookup | Stores the account status for each customer — the primary consumer of this lookup |
| Hedge.AccountStatus | AccountStatusID | Implicit Lookup | Tracks hedge account operational state using the same status domain |
| Customer.Customer (view) | AccountStatusID | JOIN | Exposes account status in the main customer view |
| Customer.CustomerSafty (view) | AccountStatusID | JOIN | Includes account status in the safety-filtered customer view |
| Customer.IsCustomerFund (view) | AccountStatusID | JOIN | References account status to identify fund accounts |
| BackOffice.GetBlockedCustomers | AccountStatusID | Read | Filters customers by account status for compliance reporting |
| BackOffice.GetClosedAccountsByLastChangeDate | AccountStatusID | Read | Reports recently closed accounts |
| BackOffice.GetAccountStatusID | AccountStatusID | Read | Retrieves current account status for a customer |
| BackOffice.AccountStatusChange | AccountStatusID | Read/Write | Procedure for changing a customer's account status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores AccountStatusID per customer (implicit FK) |
| Hedge.AccountStatus | Table | Tracks hedge account states using same domain |
| Customer.Customer | View | Exposes account status in customer view |
| Customer.CustomerSafty | View | Includes account status in safety-filtered customer view |
| Customer.IsCustomerFund | View | References account status for fund identification |
| Customer.GetCustomerListForStrongMail | View | Uses account status for email targeting |
| BackOffice.GetBlockedCustomers | Stored Procedure | Reads account status for compliance reporting |
| BackOffice.GetClosedAccountsByLastChangeDate | Stored Procedure | Reports recently closed accounts |
| BackOffice.AccountStatusChange | Stored Procedure | Changes customer account status |
| BackOffice.GetAccountStatusID | Stored Procedure | Retrieves account status for a customer |
| BackOffice.GetCustomerByCID | Stored Procedure | Includes account status in customer lookup |
| BackOffice.Bulk_UpdateAccountUserInfoRemote | Stored Procedure | Bulk updates including account status |
| Hedge.AddAccountStatus | Stored Procedure | Creates hedge account status records |
| Hedge.DelAccountStatus | Stored Procedure | Removes hedge account status records |
| Hedge.ArchiveAccountStatus | Stored Procedure | Archives hedge account status history |
| Hedge.CalculateAccountStatusFromNetting | Stored Procedure | Derives account status from netting calculations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AccountStatus | CLUSTERED PK | AccountStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AccountStatus | PRIMARY KEY | Ensures unique account status identifiers |

---

## 8. Sample Queries

### 8.1 List all account statuses
```sql
SELECT  AccountStatusID,
        AccountStatusName
FROM    [Dictionary].[AccountStatus] WITH (NOLOCK)
ORDER BY AccountStatusID;
```

### 8.2 Find all closed accounts with closure date
```sql
SELECT  cs.CID,
        cs.UserName,
        das.AccountStatusName,
        cs.LastChangeDate
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[AccountStatus] das WITH (NOLOCK)
        ON cs.AccountStatusID = das.AccountStatusID
WHERE   cs.AccountStatusID = 2
ORDER BY cs.LastChangeDate DESC;
```

### 8.3 Count customers by account status
```sql
SELECT  das.AccountStatusName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[AccountStatus] das WITH (NOLOCK)
        ON cs.AccountStatusID = das.AccountStatusID
GROUP BY das.AccountStatusName
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.AccountStatus. This is a foundational lookup table whose meaning is self-evident from its data and usage patterns.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AccountStatus.sql*
