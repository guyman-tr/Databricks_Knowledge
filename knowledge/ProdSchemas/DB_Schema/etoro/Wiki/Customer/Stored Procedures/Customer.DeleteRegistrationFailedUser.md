# Customer.DeleteRegistrationFailedUser

> Removes all records of a failed customer registration by hard-deleting the customer row from CustomerStatic, BackOffice.Customer, CustomerMoney, and TrackingId within a transaction - but only if the account has no credit balance.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (CustomerStatic delete key), @CID (all other tables) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteRegistrationFailedUser cleans up partially-created customer accounts that failed during the registration flow. When a registration attempt creates database records but the process fails before completion (network error, validation failure, partial data), these orphaned records need to be removed to prevent data pollution and enable re-registration with the same identity.

The procedure exists to support registration rollback: when a registration attempt creates rows in multiple tables (CustomerStatic, BackOffice.Customer, CustomerMoney, TrackingId) but the overall registration fails, the application calls this procedure to atomically remove all traces of the failed attempt. The four-table deletion mirrors the four tables that are written during customer registration.

The critical safety guard - checking that Credit = 0 in CustomerMoney before deleting - prevents accidentally deleting an account that has been funded. A funded account is a live customer account regardless of registration state, and deleting it would cause data loss and financial inconsistency. If Credit > 0, the procedure returns immediately without error.

---

## 2. Business Logic

### 2.1 Credit Guard - Safety Check Before Delete

**What**: The procedure will NOT delete any data if the customer has a non-zero credit balance.

**Columns/Parameters Involved**: `@CID`, `Customer.CustomerMoney.Credit`

**Rules**:
- SELECT Credit FROM Customer.CustomerMoney WHERE CID = @CID
- If Credit > 0: RETURN immediately - no DELETE executed, no error raised, return value is NULL (implicit)
- If Credit = 0 (or no row found): proceed to deletion
- Business meaning: a funded account is a real customer account, not a failed registration - never delete it

### 2.2 Atomic Four-Table Deletion

**What**: All four tables are deleted in a single transaction.

**Columns/Parameters Involved**: `@GCID`, `@CID`

**Rules**:
- DELETE TOP(1) FROM Customer.CustomerStatic WHERE GCID = @GCID
- DELETE TOP(1) FROM BackOffice.Customer WHERE CID = @CID
- DELETE TOP(1) FROM Customer.CustomerMoney WHERE CID = @CID
- DELETE TOP(1) FROM Customer.TrackingId WHERE CID = @CID
- TOP(1) is used as a safety measure - a failed registration should never have duplicate rows
- All four DELETEs are wrapped in a single transaction; if any fails, all are rolled back
- SET XACT_ABORT ON: any error automatically rolls back the transaction

### 2.3 Known Bug: CATCH Block Never Rolls Back

**What**: The CATCH block rollback condition is logically unreachable.

**Rules**:
- @InitTran is initialized to 0 and never set to 1 in the TRY block
- CATCH condition: `@@TranCount = 1 AND @InitTran = 1` will ALWAYS evaluate to FALSE
- Result: if an error occurs inside the transaction, XACT_ABORT ON handles the rollback automatically - but the explicit ROLLBACK in CATCH is dead code
- THROW after RETURN in the CATCH block is also unreachable (THROW is after RETURN)
- Net effect: XACT_ABORT ON provides the actual rollback; the explicit ROLLBACK logic is never executed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Group Customer ID - used to delete from Customer.CustomerStatic (WHERE GCID = @GCID). The GCID is the identifier used in CustomerStatic rather than CID. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID - used to delete from BackOffice.Customer, Customer.CustomerMoney, and Customer.TrackingId (WHERE CID = @CID). Also used for the credit balance guard check. |

**Return values:**

| Value | Meaning |
|-------|---------|
| NULL (implicit) | Credit > 0 - deletion was skipped because account is funded |
| 0 | All four rows deleted successfully |
| SQL error number | Error occurred during deletion (XACT_ABORT ON rollback triggered) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | Read (guard check) | Checks Credit balance before proceeding |
| @GCID | Customer.CustomerStatic | DELETE | Removes the primary customer registration record |
| @CID | BackOffice.Customer | DELETE | Removes the BackOffice customer record |
| @CID | Customer.CustomerMoney | DELETE | Removes the money/balance record |
| @CID | Customer.TrackingId | DELETE | Removes the acquisition tracking record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the registration service during registration failure cleanup.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteRegistrationFailedUser (procedure)
├── Customer.CustomerMoney (table - guard + delete)
├── Customer.CustomerStatic (table - delete)
├── BackOffice.Customer (table - cross-schema delete)
└── Customer.TrackingId (table - delete)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Read (Credit guard check) + DELETE (remove balance record) |
| Customer.CustomerStatic | Table | DELETE (remove primary customer record by GCID) |
| BackOffice.Customer | Table | DELETE (remove BackOffice customer record by CID) |
| Customer.TrackingId | Table | DELETE (remove acquisition tracking record by CID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from registration service cleanup flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Transaction setting | Any error automatically rolls back the transaction - primary rollback mechanism |
| Credit > 0 guard | Business validation | Returns immediately without deleting if account is funded |
| DELETE TOP(1) | Safety limiter | Limits deletion to at most one row per table (no bulk deletions possible via this procedure) |

---

## 8. Sample Queries

### 8.1 Execute registration cleanup (use with caution - this hard-deletes data)

```sql
-- Only call if the account was never funded and registration failed
DECLARE @result INT
EXEC @result = Customer.DeleteRegistrationFailedUser
    @GCID = 987654,
    @CID = 12345678
SELECT @result AS ReturnCode  -- 0=deleted, NULL=account has credit (skip), error number=failure
```

### 8.2 Verify credit balance before calling procedure

```sql
SELECT CID, Credit
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE CID = 12345678
-- If Credit > 0, the procedure will skip deletion
```

### 8.3 Check all four tables for the customer before deletion

```sql
SELECT 'CustomerStatic' AS TableName, CAST(COUNT(*) AS VARCHAR) AS Count FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = 987654
UNION ALL
SELECT 'BackOffice.Customer', CAST(COUNT(*) AS VARCHAR) FROM BackOffice.Customer WITH (NOLOCK) WHERE CID = 12345678
UNION ALL
SELECT 'CustomerMoney', CAST(COUNT(*) AS VARCHAR) FROM Customer.CustomerMoney WITH (NOLOCK) WHERE CID = 12345678
UNION ALL
SELECT 'TrackingId', CAST(COUNT(*) AS VARCHAR) FROM Customer.TrackingId WITH (NOLOCK) WHERE CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.DeleteRegistrationFailedUser | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DeleteRegistrationFailedUser.sql*
