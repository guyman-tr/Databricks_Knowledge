# BackOffice.Login

> Session audit log for BackOffice agent authentication events, recording every login and logout for BackOffice UI access. Used for session management, security auditing, and broker listener lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | LoginID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [HISTORY] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.Login records every time a BackOffice agent authenticates into the BackOffice management system. Each row represents one login session: who logged in (ManagerID), when (LoggedIn), from where (IP), what client version, and when they logged out (LoggedOut - NULL if session still active).

The table serves two purposes: (1) security audit trail for BackOffice access, and (2) lifecycle tracking for the Broker.Listener real-time notification system - each login registers a listener, each logout removes it.

227,694 rows as of 2026-03-17 covering 590 unique managers (out of ~960 total). The oldest session dates to 2008-01-27. Active sessions today are tracked with LoggedOut IS NULL. The ClientVersion column documents which BackOffice UI build the agent was running.

**Known bug**: The `IsLogged` computed column is always 1 due to a SQL Server NULL comparison issue - see Section 7.3.

---

## 2. Business Logic

### 2.1 Login and Session Registration

**What**: Logging in creates a row here and simultaneously registers a real-time listener in the Broker system.

**Columns Involved**: `ManagerID`, `LoggedIn`, `IP`, `ClientVersion`, `ClientTypeID`, `LoginID`

**Rules**:
- BackOffice.LogIn procedure:
  1. Looks up ManagerID in BackOffice.Manager WHERE Login=@Login AND IsActive=1.
  2. If found, INSERTs into BackOffice.Login with ManagerID, IP, ClientVersion, ClientTypeID.
  3. Sets LoggedIn via DEFAULT (getdate()) on INSERT.
  4. Calls Broker.ListenerAdd(@ListenerID, 1=backoffice, IP, Port) to register real-time notifications.
  5. Returns @ManagerID, @LoginID (SCOPE_IDENTITY()), and @ListenerID to the caller.
- Note: The @Password parameter is accepted by LogIn but NOT checked in current code - password validation has been removed (authentication now handled by a higher-level layer, e.g., Windows auth/SSO).
- IP is empty string "" in all recent logins (2026) - client no longer sends IP address.

### 2.2 Logout and Session Teardown

**What**: Logging out closes the session and deregisters the real-time listener.

**Columns Involved**: `LoggedOut`, `LoginID`

**Rules**:
- BackOffice.LogOut procedure:
  1. UPDATE BackOffice.Login SET LoggedOut = GETDATE() WHERE LoginID = @LoginID.
  2. Calls Broker.ListenerRemove(@ListenerID) to deregister real-time notifications.
  3. Transactions protect both operations atomically.
- LoggedOut IS NULL: session either still active OR was never properly closed (browser tab closed, server restart without logout). 31,028 rows have LoggedOut IS NULL (13.6% of all rows).

### 2.3 IsLogged Computed Column Bug

**What**: The `IsLogged` column is a PERSISTED computed column intended to flag whether a session is still active, but it is non-functional due to a NULL comparison bug.

**Rules**:
- Formula: `CASE [LoggedOut] WHEN NULL THEN (0) ELSE (1) END`
- SQL Server's `CASE expression WHEN value` uses = comparison. `LoggedOut = NULL` is never true in SQL Server (NULL != NULL with equality). So IsLogged is always (1) for ALL rows, even when LoggedOut IS NULL.
- **Do NOT use IsLogged to determine active sessions.** Use `WHERE LoggedOut IS NULL` instead.
- All 227,694 rows have IsLogged=1.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 227,694 |
| Unique managers who have logged in | 590 |
| Oldest session | 2008-01-27 |
| Newest session | 2026-03-17 (live) |
| LoggedOut IS NULL (unclosed sessions) | 31,028 (13.6%) |
| IsLogged distribution | All 227,694 rows = 1 (computed column bug) |
| ClientVersion range | "4.1" (early 2000s) to "8.1.34 (17/3/2026)" |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing session identifier. Clustered PK. NOT FOR REPLICATION. Returned to the client after login as the session token for subsequent logout. |
| 2 | ManagerID | int | NO | - | VERIFIED | BackOffice agent who logged in. FK (WITH CHECK) to BackOffice.Manager. Only agents with IsActive=1 in Manager can create a session. See BackOffice.Manager for agent details. |
| 3 | LoggedIn | datetime | NO | getdate() | VERIFIED | When the session started. Set via DEFAULT at INSERT time (not from LogIn procedure parameter). |
| 4 | LoggedOut | datetime | YES | - | VERIFIED | When the session was explicitly ended. NULL = session is still active or was not properly closed (browser close, server restart). Updated by BackOffice.LogOut (SET LoggedOut = GETDATE()). |
| 5 | IP | varchar(15) | NO | - | VERIFIED | IP address of the agent's machine at login time. Recent rows (2026) have empty string "" - the client stopped sending IP addresses. Historical rows contain IPv4 addresses. varchar(15) accommodates dotted-decimal IPv4 (max "255.255.255.255" = 15 chars). |
| 6 | ClientVersion | varchar(20) | NO | - | VERIFIED | Version string of the BackOffice client application. Formats vary: "4.1", "8.5", "8.9 (15/10/2012)", "8.1.34 (17/3/2026)". Allows tracking which UI build each agent is running. |
| 7 | IsLogged | computed, PERSISTED | NO | - | VERIFIED | **BUG: always 1 for all rows.** Intended: 0=logged in (LoggedOut IS NULL), 1=logged out (LoggedOut IS NOT NULL). Actual: always 1 due to NULL comparison issue in `CASE [LoggedOut] WHEN NULL THEN (0) ELSE (1) END`. Do NOT use this column for session state - use `LoggedOut IS NULL` instead. |
| 8 | ClientTypeID | tinyint | YES | 0 | CODE-BACKED | Type of BackOffice client. FK (WITH CHECK) to Dictionary.ClientType. Default 0. Used to distinguish web client from desktop client or other access methods. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | FK (WITH CHECK) | Agent who created the session. IsActive=1 required. |
| ClientTypeID | Dictionary.ClientType | FK (WITH CHECK) | Client type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.LogIn | ManagerID, LoginID | WRITER | Creates session on login |
| BackOffice.LogOut | LoginID, LoggedOut | MODIFIER | Closes session on logout |
| BackOffice.LoginWebTrader | ManagerID | WRITER | Alternative login path (WebTrader client) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Login (table)
- FK targets: BackOffice.Manager, Dictionary.ClientType
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK constraint on ManagerID; IsActive=1 check in LogIn |
| Dictionary.ClientType | Table | FK constraint on ClientTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.LogIn | Procedure | WRITER - session creation |
| BackOffice.LogOut | Procedure | MODIFIER - session close |
| BackOffice.LoginWebTrader | Procedure | WRITER - WebTrader login |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BLOG | CLUSTERED PK | LoginID ASC | - | - | Active (FILLFACTOR=90, ON [HISTORY]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BLOG | PK | LoginID uniqueness |
| FK_BMNG_BLOG | FK (WITH CHECK) | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_BO_CTID | FK (WITH CHECK) | ClientTypeID -> Dictionary.ClientType(ClientTypeID) |
| HLOG_LOGGED | DEFAULT | LoggedIn = getdate() |
| DFBL_ClientTypeID | DEFAULT | ClientTypeID = 0 |

### 7.3 Known Issue - IsLogged Computed Column

The formula `CASE [LoggedOut] WHEN NULL THEN (0) ELSE (1) END` never evaluates to 0. In SQL Server, `CASE expr WHEN value` uses equality comparison (`=`), which can never match NULL. The correct formula to detect an unclosed session would be `CASE WHEN [LoggedOut] IS NULL THEN (0) ELSE (1) END`. As a result, IsLogged=1 for all rows.

---

## 8. Sample Queries

### 8.1 Get currently active sessions (correctly using LoggedOut IS NULL)
```sql
SELECT
    l.LoginID,
    m.Login AS AgentLogin,
    m.FirstName + ' ' + m.LastName AS AgentName,
    l.LoggedIn,
    l.IP,
    l.ClientVersion
FROM BackOffice.Login l WITH (NOLOCK)
JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = l.ManagerID
WHERE l.LoggedOut IS NULL
ORDER BY l.LoggedIn DESC
```

### 8.2 Get session history for a specific agent
```sql
SELECT
    l.LoginID,
    l.LoggedIn,
    l.LoggedOut,
    DATEDIFF(MINUTE, l.LoggedIn, ISNULL(l.LoggedOut, GETDATE())) AS SessionMinutes,
    l.IP,
    l.ClientVersion
FROM BackOffice.Login l WITH (NOLOCK)
WHERE l.ManagerID = 123  -- replace with target ManagerID
ORDER BY l.LoggedIn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.3/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Login | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Login.sql*
