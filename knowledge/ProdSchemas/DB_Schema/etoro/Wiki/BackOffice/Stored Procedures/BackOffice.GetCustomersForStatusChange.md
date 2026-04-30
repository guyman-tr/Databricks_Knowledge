# BackOffice.GetCustomersForStatusChange

> Maintenance job that processes demo account expiration - blocks expired accounts with no deposits and re-opens blocked accounts that have since received a deposit.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; no result set returned (performs DML only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomersForStatusChange is a scheduled maintenance procedure that manages the lifecycle of demo (practice) accounts on the eToro Tradonomi platform. Demo accounts are provisioned with an expiration date; this procedure enforces that expiration by blocking accounts that have passed their due date without depositing real money, and conversely re-opens accounts that have been blocked but have since deposited.

The procedure exists to automate the demo-to-real conversion funnel. Without it, expired demo accounts would remain active indefinitely, cluttering the platform and consuming resources. It also handles the reverse case - when a previously blocked account holder finally makes a real deposit, the account is immediately re-opened and given a permanent expiration date (3000-01-01), recognizing that a real-money depositor should no longer be subject to demo expiration.

The procedure runs on a cursor over all Customer.Customer records with a non-permanent AccountExpirationDate. It runs only on server `AMS-QUAD-SQL-1` in the `tradonomi` database (the demo database), making it environment-specific by design. On `AMS-BIG-SQL-1` it returns immediately. It is designed to be called on a schedule (e.g., daily job) rather than triggered by user actions.

---

## 2. Business Logic

### 2.1 Demo Account Expiration - Block Flow

**What**: When a demo account's expiration date has passed and no real deposit has been made, the account is blocked.

**Columns/Parameters Involved**: `AccountExpirationDate`, `PlayerStatusID`, deposit sum from `Billing.GetSumAmountByCID`

**Rules**:
- Condition: `AccountExpirationDate <= GETDATE() AND PlayerStatusID <> 9 AND ISNULL(Amount, 0) <= 0`
- Action: Call `Customer.SetStatus(@CID, @PlayerStatusID=9, @ManagerID=0, 'Expiration Date Close')`
  - PlayerStatusID=9 = Trade Blocked
  - ManagerID=0 = system-initiated, not a human manager
- Action: Send message type 19 to the customer notifying them of expiration
- The customer's first name is retrieved from Customer.Customer for the message personalization (falls back to 'Customer' if NULL)
- Wrapped in a transaction: if SetStatus fails, ROLLBACK - no partial state

**Diagram**:
```
AccountExpirationDate passed?   PlayerStatusID <> 9?   Amount <= 0?
         YES                          YES                  YES
          |
          v
  Customer.SetStatus(9 - Trade Blocked, ManagerID=0)
  Customer.SendMessage(CID, messageType=19, FirstName)
```

### 2.2 Deposit-After-Expiry - Re-Open Flow

**What**: When a previously blocked (expired) account has since received a deposit, the block is reversed and expiration is removed permanently.

**Columns/Parameters Involved**: `AccountExpirationDate`, `Amount`, `PlayerStatusID`

**Rules**:
- Condition: `AccountExpirationDate <= GETDATE() AND Amount > 0 AND PlayerStatusID = 9`
- Action: Call `Customer.SetStatus(@CID, @PlayerStatusID=1, @ManagerID=0, 'Account open after deposit on Real eToro')`
  - PlayerStatusID=1 = Open
- Action: UPDATE Customer.Customer SET AccountExpirationDate = '3000-01-01' (permanent - never expires again)
- Interpretation: A real deposit signals the customer has converted from demo to real; demo expiry rules no longer apply
- Wrapped in a transaction: both SetStatus and the AccountExpirationDate update commit or rollback together

**Diagram**:
```
AccountExpirationDate passed?   Amount > 0?   PlayerStatusID = 9?
         YES                      YES               YES
          |
          v
  Customer.SetStatus(1 - Open, ManagerID=0, 'Account open after deposit')
  UPDATE AccountExpirationDate = '3000-01-01'
  (account permanently open, never expires again)
```

### 2.3 Server/Environment Guard

**What**: The procedure is designed exclusively for the Tradonomi demo database environment and will not execute on production servers.

**Rules**:
- If `@@SERVERNAME = 'AMS-BIG-SQL-1'`: RETURN immediately (production guard)
- Cursor and all DML only runs when `@@SERVERNAME = 'AMS-QUAD-SQL-1' AND DB_NAME() = 'tradonomi'`
- Ensures demo expiration logic never accidentally runs against production customer records

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (none) | - | - | - | - | This procedure has no input parameters. It operates as a batch maintenance job, processing all eligible Customer.Customer records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CUS | Customer.Customer | SELECT + UPDATE | Primary cursor source and update target - reads expiration state, updates AccountExpirationDate and indirectly PlayerStatusID via SetStatus |
| DEP | Billing.GetSumAmountByCID | LEFT JOIN | Lookup of total deposit amount per customer (by OriginalCID + OriginalProviderID) to determine if a real deposit exists |
| - | Customer.SetStatus | EXEC | Called to change PlayerStatusID to 9 (block) or 1 (open) |
| - | Customer.SendMessage | EXEC | Called to notify the customer of expiration (message type 19) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This procedure is a scheduled job - no stored procedure callers found in the BackOffice schema. Typically invoked by a SQL Server Agent job on the Tradonomi server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomersForStatusChange (procedure)
├── Customer.Customer (table)
├── Billing.GetSumAmountByCID (view/function - cross-schema)
├── Customer.SetStatus (procedure - cross-schema)
└── Customer.SendMessage (procedure - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Cursor source for accounts with AccountExpirationDate; also direct UPDATE target for AccountExpirationDate reset |
| Billing.GetSumAmountByCID | View/Function | LEFT JOIN to determine total deposit sum by OriginalCID + OriginalProviderID; determines if customer has deposited |
| Customer.SetStatus | Procedure | Called to change account status - block (9) or re-open (1) |
| Customer.SendMessage | Procedure | Called to send expiration notification (message type 19) to the customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server Agent Job (Tradonomi server) | External | Scheduled caller - invokes this procedure periodically to process expired accounts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Notable implementation details:
- Uses a STATIC, LOCAL, READ_ONLY, FORWARD_ONLY cursor for efficient one-pass iteration
- All DML (SetStatus + AccountExpirationDate update) is wrapped in explicit transactions with error checking via @@ERROR
- Server name guard (`@@SERVERNAME` check) makes this environment-specific; safe to deploy to any server but only active on Tradonomi demo server

---

## 8. Sample Queries

### 8.1 Preview accounts eligible for expiry block (no-op dry run)
```sql
SELECT CUS.CID, CUS.AccountExpirationDate, CUS.PlayerStatusID,
       ISNULL(DEP.SumAmount, 0) AS TotalDeposit
FROM Customer.Customer CUS WITH(NOLOCK)
LEFT JOIN Billing.GetSumAmountByCID DEP WITH(NOLOCK)
    ON CUS.OriginalCID = DEP.OriginalCID
    AND CUS.OriginalProviderID = DEP.OriginalProviderID
WHERE CUS.AccountExpirationDate IS NOT NULL
  AND CUS.AccountExpirationDate < '3000-01-01'
  AND CUS.AccountExpirationDate <= GETDATE()
  AND CUS.PlayerStatusID <> 9
  AND ISNULL(DEP.SumAmount, 0) <= 0
```

### 8.2 Preview accounts eligible for re-open (deposited after block)
```sql
SELECT CUS.CID, CUS.AccountExpirationDate, CUS.PlayerStatusID,
       DEP.SumAmount AS TotalDeposit
FROM Customer.Customer CUS WITH(NOLOCK)
LEFT JOIN Billing.GetSumAmountByCID DEP WITH(NOLOCK)
    ON CUS.OriginalCID = DEP.OriginalCID
    AND CUS.OriginalProviderID = DEP.OriginalProviderID
WHERE CUS.AccountExpirationDate IS NOT NULL
  AND CUS.AccountExpirationDate < '3000-01-01'
  AND CUS.AccountExpirationDate <= GETDATE()
  AND CUS.PlayerStatusID = 9
  AND DEP.SumAmount > 0
```

### 8.3 Execute the maintenance procedure (on Tradonomi server only)
```sql
-- Run only on AMS-QUAD-SQL-1 in tradonomi DB
EXEC BackOffice.GetCustomersForStatusChange
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomersForStatusChange | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomersForStatusChange.sql*
