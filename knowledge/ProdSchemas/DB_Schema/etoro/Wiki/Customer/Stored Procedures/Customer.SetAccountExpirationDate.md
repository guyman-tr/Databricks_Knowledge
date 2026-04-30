# Customer.SetAccountExpirationDate

> Updates the AccountExpirationDate field on a customer account; skips the write if the date is already set to the requested value.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT; returns 0 on success, 60000 on error |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Account expiration dates are used to control when a customer's account automatically becomes inactive or locked - commonly applied to demo accounts, trial periods, limited-access accounts, or regulatory suspension scenarios. `SetAccountExpirationDate` is the single entry point for updating this date on a customer account.

The procedure implements an idempotency check: it first reads the current `AccountExpirationDate` from `Customer.Customer` (the view over CustomerStatic) and only performs the UPDATE if the new value differs. This avoids unnecessary write transactions and audit log entries when the calling system may re-submit the same expiration date.

The default expiration date of `3000-01-01` is effectively "never expires" - a sentinel date used to indicate a permanently active account.

---

## 2. Business Logic

### 2.1 Idempotency Guard

**What**: The procedure reads the current expiration date before writing and exits early if nothing would change.

**Columns/Parameters Involved**: `@OldAccountExpirationDate`, `@AccountExpirationDate`

**Rules**:
- Reads `AccountExpirationDate` from `Customer.Customer WITH(NOLOCK)` WHERE CID = @CID.
- If old = new: RETURN immediately (no transaction, no error).
- If old != new: Execute UPDATE within a transaction.

### 2.2 Error Handling

**What**: Raises error 60000 if the UPDATE fails.

**Rules**:
- Uses @@ERROR check (legacy-style error handling rather than TRY/CATCH).
- On error: ROLLBACK + RAISERROR(60000, 16, 1) + RETURN 60000.
- On success: COMMIT + RETURN 0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the account to update. Used to locate the row in Customer.Customer and Customer.CustomerStatic (via the view). |
| 2 | @AccountExpirationDate | DATETIME | YES | '3000-01-01' | CODE-BACKED | The new expiration date for the account. Default = '3000-01-01' = effectively never expires. Set to a real date to schedule account deactivation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer (view) | READ + UPDATE | Reads current expiration date and updates it via the view (which reflects CustomerStatic) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Account expiration management systems | External | Caller | Called by admin tools, compliance workflows, or scheduled jobs managing account lifecycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetAccountExpirationDate (procedure)
+-- Customer.Customer (view) [reads and updates AccountExpirationDate]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT (check current value) + UPDATE (write new value) |

### 6.2 Objects That Depend On This

No dependents found in Customer schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR(60000) | Error code | 60000 = generic update failure in the Customer schema error code convention |
| Default '3000-01-01' | Sentinel date | Represents "never expires" - accounts with this date are permanently active |

---

## 8. Sample Queries

### 8.1 Set account expiration to a specific date

```sql
EXEC Customer.SetAccountExpirationDate
    @CID = 12345,
    @AccountExpirationDate = '2026-12-31';
```

### 8.2 Reset account to never-expire state

```sql
EXEC Customer.SetAccountExpirationDate
    @CID = 12345;
-- Uses default '3000-01-01'
```

### 8.3 Find accounts with upcoming expiration dates

```sql
SELECT
    cs.CID,
    cs.GCID,
    cs.UserName,
    c.AccountExpirationDate
FROM Customer.Customer c WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = c.CID
WHERE c.AccountExpirationDate < '3000-01-01'
    AND c.AccountExpirationDate > GETUTCDATE()
ORDER BY c.AccountExpirationDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetAccountExpirationDate | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetAccountExpirationDate.sql*
