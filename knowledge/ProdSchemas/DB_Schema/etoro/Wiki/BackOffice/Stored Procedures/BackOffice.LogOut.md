# BackOffice.LogOut

> Closes a BackOffice manager session by stamping the logout time on the Login record and deregistering the real-time broker listener - atomically, within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.Login + EXEC Broker.ListenerRemove |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.LogOut` is the logout counterpart to `BackOffice.LogIn`. When a BackOffice agent ends their session (explicit logout from the UI), this procedure (1) stamps the LoggedOut timestamp on the session record in `BackOffice.Login`, and (2) deregisters the agent's real-time notification listener from the Broker subsystem.

The procedure exists to maintain clean session lifecycle: a row in BackOffice.Login with LoggedOut IS NULL means an active session. Without this procedure, sessions would never be formally closed, making it impossible to audit who is currently logged in, and real-time listeners would leak indefinitely, degrading notification system performance.

The two operations are wrapped in a single transaction: if the Login UPDATE fails, the transaction rolls back and the ListenerRemove is never called. If ListenerRemove returns a non-zero code, that error is propagated back to the caller. This atomicity ensures session state and listener state stay in sync.

---

## 2. Business Logic

### 2.1 Atomic Session Close + Listener Deregistration

**What**: Two-step transactional logout: close the Login session record AND deregister the broker listener.

**Columns/Parameters Involved**: `@LoginID`, `@ListenerID`, `BackOffice.Login.LoggedOut`

**Rules**:
- Step 1: UPDATE BackOffice.Login SET LoggedOut = GETDATE() WHERE LoginID = @LoginID.
- If UPDATE fails (@@ERROR != 0): ROLLBACK and RAISERROR(60000) with the original error code. Return @LocalError.
- Step 2: EXECUTE Broker.ListenerRemove @ListenerID.
- If ListenerRemove returns non-zero @Answer: return @Answer to caller (no rollback at this point - Login already updated successfully within the transaction, and COMMIT happens before the error return path executes the early return).
- On full success: COMMIT TRANSACTION, RETURN 0.

**Diagram**:
```
Caller
  |
  v
BackOffice.LogOut(@LoginID, @ListenerID)
  |
  +-- BEGIN TRANSACTION
  |
  +-- UPDATE BackOffice.Login SET LoggedOut = GETDATE()
  |     WHERE LoginID = @LoginID
  |
  +-- IF @@ERROR != 0
  |     -> ROLLBACK
  |     -> RAISERROR(60000) with original error
  |     -> RETURN @LocalError
  |
  +-- EXECUTE Broker.ListenerRemove @ListenerID
  |
  +-- IF @Answer != 0
  |     -> RETURN @Answer   (transaction committed at this point)
  |
  +-- COMMIT TRANSACTION
  |
  +-- RETURN 0
```

### 2.2 Error Code 60000

**What**: Generic BackOffice error code raised when a DB operation fails.

**Rules**:
- RAISERROR(60000, 16, 1, 'BackOffice.LogOut', @LocalError) formats as severity 16 (application error).
- The state parameter (1) and procedure name are for diagnostic context.
- Callers should check RETURN value: 0 = success, non-zero = failure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginID | int | NO | - | VERIFIED | Session identifier to close. FK to BackOffice.Login.LoginID. This ID is returned to the caller at login time (via SCOPE_IDENTITY() in BackOffice.LogIn) and must be passed back at logout. The UPDATE stamps LoggedOut = GETDATE() on this row. |
| 2 | @ListenerID | int | NO | - | VERIFIED | Broker real-time listener ID to deregister. Assigned by Broker.ListenerAdd during login and stored/tracked by the caller. Passed to Broker.ListenerRemove to disconnect the agent from the real-time notification stream. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LoginID | BackOffice.Login.LoginID | Modifier | Stamps LoggedOut timestamp on the matching session row |
| @ListenerID | Broker.ListenerRemove | Callee (cross-schema) | Deregisters the agent's real-time notification listener |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found in BackOffice schema. Called from the BackOffice web application on explicit agent logout.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LogOut (procedure)
+-- BackOffice.Login (table) [UPDATE target]
+-- Broker.ListenerRemove (procedure) [cross-schema EXEC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Login | Table | UPDATE: stamps LoggedOut = GETDATE() WHERE LoginID = @LoginID |
| Broker.ListenerRemove | Stored Procedure | EXEC: deregisters real-time notification listener |

### 6.2 Objects That Depend On This

No SQL-layer dependents found. Called externally from BackOffice application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute logout for a known session

```sql
DECLARE @rc INT;
EXEC @rc = BackOffice.LogOut
    @LoginID = 12345,
    @ListenerID = 99;
SELECT @rc AS ReturnCode;  -- 0 = success
```

### 8.2 Check if a session was properly closed after logout

```sql
SELECT LoginID, ManagerID, LoggedIn, LoggedOut
FROM BackOffice.Login WITH (NOLOCK)
WHERE LoginID = 12345;
-- LoggedOut should be non-NULL if logout succeeded
```

### 8.3 Find unclosed sessions (LoggedOut IS NULL - did not go through LogOut)

```sql
SELECT l.LoginID, m.Login, m.FirstName + ' ' + m.LastName AS AgentName,
       l.LoggedIn, l.ClientVersion
FROM BackOffice.Login l WITH (NOLOCK)
JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = l.ManagerID
WHERE l.LoggedOut IS NULL
ORDER BY l.LoggedIn DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.LogOut | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LogOut.sql*
