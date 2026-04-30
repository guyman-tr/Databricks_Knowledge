# BackOffice.AccountStatusChange

> Opens or closes a customer account by updating the account status in Customer.Customer and synchronizing the blocked flag in the STS system (dbo.STS_User).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write path for changing a customer account's open/closed state on the eToro platform. Account closure is one of the most consequential operations in BackOffice: it prevents a customer from trading, depositing, or withdrawing. The procedure atomically updates two systems: the core customer record (`Customer.Customer.AccountStatusID`) and the STS (status/security) system (`dbo.STS_User.Blocked`), keeping them in sync.

The procedure exists because account status must be reflected in two places: the core eToro database (used by all trading and compliance systems) and the STS system (used for authentication and access control). If only one system were updated, a closed account might still authenticate successfully, or an open account might be blocked. The single procedure call ensures both are always updated together.

Data flows as follows: a BackOffice operator changes account status via the UI, which calls this procedure. The procedure validates the new status, updates `Customer.Customer` (with an idempotency guard so no-op updates are safe), returns the full `Dictionary.AccountStatus` lookup as a result set (allowing the caller to display valid statuses), and synchronizes the `Blocked` flag to `dbo.STS_User` using the customer's GCID. When an account is closed (status=2), downstream alert systems detect the change and send notifications (per Confluence: `AccountStatusChanged` message with CCM flag `HandleAccountStatusChangeEvents`).

---

## 2. Business Logic

### 2.1 Account Open/Close Dual-System Write

**What**: Closing an account requires synchronizing AccountStatusID in two systems to prevent authentication bypass.

**Columns/Parameters Involved**: `@AccountStatusID`, `Customer.Customer.AccountStatusID`, `dbo.STS_User.Blocked`

**Rules**:
- `AccountStatusID=2` (Closed) -> `Blocked=1` in `dbo.STS_User` (blocks authentication/access)
- `AccountStatusID=1` (Open) -> `Blocked=0` in `dbo.STS_User` (restores access)
- The `GCID` (Global Customer ID) is read from `Customer.Customer` and used to target the `STS_User` record
- @@ROWCOUNT is validated after the `STS_User` update (not the `Customer.Customer` update): if STS_User had no matching GCID, error 60000 sub-code -2 is raised

**Diagram**:
```
@AccountStatusID=1 (Open)    ->  Customer.AccountStatusID=1 + STS_User.Blocked=0
@AccountStatusID=2 (Closed)  ->  Customer.AccountStatusID=2 + STS_User.Blocked=1
```

### 2.2 Idempotency Guard on Customer Update

**What**: The Customer.Customer update is guarded so it only fires if the status actually changes.

**Columns/Parameters Involved**: `Customer.Customer.AccountStatusID`, `@AccountStatusID`

**Rules**:
- WHERE condition: `ISNULL(AccountStatusID, 0) != ISNULL(@AccountStatusID, 0)` - if the customer already has the requested status, the Customer update is a no-op
- The STS_User update is NOT guarded - it always writes the Blocked flag regardless of whether Customer status changed
- This means repeated calls with the same status are safe for Customer but will still update STS_User

### 2.3 Dictionary Result Set Return

**What**: The procedure returns the full `Dictionary.AccountStatus` lookup table as a result set after the Customer update.

**Rules**:
- The SELECT returns both rows: 1=Open, 2=Closed
- Placed AFTER the Customer.Customer update and BEFORE the STS_User update
- Allows the calling application to refresh its dropdown/display without a separate query

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the account to open or close. Used to look up the GCID for STS_User update and to target the Customer.Customer row. |
| 2 | @AccountStatusID | tinyint | NO | - | VERIFIED | New account status: 1=Open (unblocks access), 2=Closed (blocks access and sets STS_User.Blocked=1). Validated against Dictionary.AccountStatus before any update. Error 60000 (-1) for invalid values. See [Account Status](_glossary.md#account-status). |

**Result Set - Dictionary.AccountStatus (all rows):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | AccountStatusID | tinyint | NO | - | VERIFIED | Status identifier: 1=Open, 2=Closed. (Source: Dictionary.AccountStatus) |
| 4 | AccountStatusName | varchar | YES | - | VERIFIED | Human-readable label: "Open" or "Closed". Returned to allow calling app to display valid statuses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Implicit | Reads GCID, updates AccountStatusID |
| @AccountStatusID | Dictionary.AccountStatus | Lookup (validated) | Validates status ID exists before writing |
| GCID | dbo.STS_User | Implicit (cross-schema) | Updates Blocked flag to match account closure state |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice application layer by operators changing account status. Downstream: Alert Service listens for `AccountStatusChanged` events (CCM flag: `HandleAccountStatusChangeEvents`) triggered when status changes to Closed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatusChange (procedure)
|- Customer.Customer (table) [read GCID + UPDATE AccountStatusID]
|- Dictionary.AccountStatus (table) [validation + result set]
+-- dbo.STS_User (table) [UPDATE Blocked flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Reads GCID for the given CID; UPDATE AccountStatusID (idempotency-guarded) |
| Dictionary.AccountStatus | Table | EXISTS check to validate @AccountStatusID; SELECT * returned as result set |
| dbo.STS_User | Table | UPDATE Blocked=@IsBlocked WHERE GCID=@GCID; @@ROWCOUNT validated post-update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called to open/close customer accounts |
| Alert Service | External | Receives AccountStatusChanged event message on status=Closed (CCM: HandleAccountStatusChangeEvents) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Status validation | Application CHECK | @AccountStatusID must exist in Dictionary.AccountStatus (error 60000 sub-code -1) |
| STS_User row guarantee | Application CHECK | @@ROWCOUNT after STS_User update must equal 1 (error 60000 sub-code -2 if GCID not found) |
| Idempotency | Application | Customer.Customer update only fires if ISNULL(AccountStatusID,0) != ISNULL(@AccountStatusID,0) |

---

## 8. Sample Queries

### 8.1 Close a customer account

```sql
-- Close account (sets AccountStatusID=2, Blocked=1 in STS)
EXEC BackOffice.AccountStatusChange
    @CID = 12345,
    @AccountStatusID = 2  -- Closed
```

### 8.2 Reopen a customer account

```sql
-- Reopen account (sets AccountStatusID=1, Blocked=0 in STS)
EXEC BackOffice.AccountStatusChange
    @CID = 12345,
    @AccountStatusID = 1  -- Open
```

### 8.3 Check account status and STS sync state for a customer

```sql
SELECT
    c.CID,
    c.GCID,
    c.AccountStatusID,
    ast.AccountStatusName,
    s.Blocked AS STS_Blocked
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.AccountStatus ast WITH (NOLOCK)
    ON c.AccountStatusID = ast.AccountStatusID
LEFT JOIN dbo.STS_User s WITH (NOLOCK)
    ON c.GCID = s.GCID
WHERE c.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Alert Service - Entering Points For Creating Alerts](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12069732429) | Confluence | AccountStatusChanged message sent when status changes to Closed (CCM flag: HandleAccountStatusChangeEvents); Billing/deposit flow also triggers AccountStatus=Open event |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountStatusChange | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatusChange.sql*
