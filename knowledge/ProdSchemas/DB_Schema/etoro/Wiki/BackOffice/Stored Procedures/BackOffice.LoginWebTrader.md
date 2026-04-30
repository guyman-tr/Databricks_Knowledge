# BackOffice.LoginWebTrader

> Records a back-office manager's WebTrader access to a customer account by inserting an audit row into the WebTraderLoginAttempts log.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into BackOffice.WebTraderLoginAttempts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.LoginWebTrader` is the sole writer of the `BackOffice.WebTraderLoginAttempts` audit log. When a back-office manager accessed a customer's WebTrader trading interface (view or operate on behalf of the customer), this SP was called to record the event with the customer ID, manager ID, timestamp, and the manager's internal IP address.

The procedure exists to maintain an immutable security audit trail for compliance and accountability. Without it there would be no record of which managers accessed which customer accounts via WebTrader impersonation, creating an unauditable back-door into customer trading accounts.

The SP is a single-INSERT writer: it captures GETDATE() server-side to ensure timestamp accuracy and writes all four fields atomically. The underlying table has not received new rows since 2014-03-10, indicating the WebTrader impersonation feature has been retired or replaced. The SP remains deployed but is effectively dormant.

---

## 2. Business Logic

### 2.1 Audit Log Insertion

**What**: Captures a single manager WebTrader access event as an immutable audit record.

**Columns/Parameters Involved**: `@CID`, `@ManagerID`, `@IP`, server-side `GETDATE()`

**Rules**:
- Timestamp is generated server-side (`GETDATE()`), not passed by caller - prevents caller clock manipulation.
- No validation, no RETURN code - the SP is fire-and-forget from the caller's perspective.
- SET NOCOUNT ON suppresses "1 row affected" messages - used in bulk or automated pipelines.
- No transaction management - if the INSERT fails, it fails silently to the caller.

**Diagram**:
```
Caller (BackOffice app)
    |
    v
BackOffice.LoginWebTrader(@CID, @IP, @ManagerID)
    |
    +-- SET @Date = GETDATE()
    |
    +-- INSERT INTO BackOffice.WebTraderLoginAttempts
            (CID, ManagerID, TimeStamp, IP)
            VALUES (@CID, @ManagerID, @Date, @IP)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the account being accessed. Inserted directly into WebTraderLoginAttempts.CID. FK to Customer.CustomerStatic.CID - identifies which customer account the manager is accessing via WebTrader. |
| 2 | @IP | varchar(15) | NO | - | CODE-BACKED | IPv4 address of the manager's workstation making the access. Inserted into WebTraderLoginAttempts.IP. Live data shows exclusively internal corporate IPs (10.20.10.x range), confirming these are staff-only back-office actions. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | ID of the back-office manager performing the access. Inserted into WebTraderLoginAttempts.ManagerID. Logical FK to BackOffice.Manager.ManagerID - identifies the accountable staff member. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic.CID | Implicit FK | Customer whose WebTrader account is being accessed |
| @ManagerID | BackOffice.Manager.ManagerID | Implicit FK | Manager performing the access |
| INSERT target | BackOffice.WebTraderLoginAttempts | Writer | Sole writer of the audit log table |

### 5.2 Referenced By (other objects point to this)

No callers found in the BackOffice schema. The procedure is called from external application code (BackOffice web application) not present in this repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LoginWebTrader (procedure)
+-- BackOffice.WebTraderLoginAttempts (table) [INSERT target]
      +-- Customer.CustomerStatic (table) [FK on CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WebTraderLoginAttempts | Table | INSERT target - writes the audit record |

### 6.2 Objects That Depend On This

No SQL-layer callers found. Called from external BackOffice application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Log a manager's WebTrader access to a customer account

```sql
EXEC BackOffice.LoginWebTrader
    @CID = 99999,
    @IP = '10.20.10.55',
    @ManagerID = 701;
```

### 8.2 Verify the access was recorded

```sql
SELECT TOP 1 LoginID, CID, ManagerID, TimeStamp, IP
FROM BackOffice.WebTraderLoginAttempts WITH (NOLOCK)
WHERE CID = 99999
ORDER BY TimeStamp DESC;
```

### 8.3 View all accesses by a specific manager

```sql
SELECT LoginID, CID, ManagerID, TimeStamp, IP
FROM BackOffice.WebTraderLoginAttempts WITH (NOLOCK)
WHERE ManagerID = 701
ORDER BY TimeStamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.LoginWebTrader | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LoginWebTrader.sql*
