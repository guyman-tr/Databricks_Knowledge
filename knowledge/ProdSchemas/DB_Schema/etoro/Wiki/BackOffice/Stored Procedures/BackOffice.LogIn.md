# BackOffice.LogIn

> Authenticates a Back Office manager by login name, returns their permissions for a given provider, inserts a login audit record, and calls Broker.ListenerAdd to register a network listener - returning ManagerID, LoginID, and ListenerID as OUTPUT params.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Login + @ProviderID; returns @ManagerID, @LoginID, @ListenerID as OUTPUT params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.LogIn` is the Back Office authentication procedure. It is called when a manager logs in to the Back Office application and performs three functions:

1. **Identity resolution**: Looks up the manager by login name, returning their ManagerID (or NULL if not found or inactive)
2. **Permission retrieval**: Returns the manager's permission list for the specified provider as a result set
3. **Session establishment**: If authenticated, inserts a login audit record into `BackOffice.Login` and registers the manager's network connection via `Broker.ListenerAdd`

The `@Password` parameter is accepted but is NOT used in the authentication logic - no password hash comparison occurs in this SP. This suggests password validation is performed by a layer above (e.g., Active Directory or a separate auth service), and this SP is called only after credentials have already been verified externally. The SP's role is then to resolve identity, load permissions, and create the session.

The `@ProviderID` parameter scopes the permissions returned to those applicable to the specific Back Office provider the manager is logging into (different BO tools may have different permission sets).

`Broker.ListenerAdd` is a cross-schema call that registers the manager's IP and port as an active listener in the broker/trading infrastructure, enabling real-time data push to the Back Office session.

---

## 2. Business Logic

### 2.1 Manager Identity Resolution

**What**: Resolves the manager's numeric ID from their login name, filtering to active managers only.

**Columns/Parameters Involved**: `@Login`, `BackOffice.Manager.Login`, `BackOffice.Manager.IsActive`

**Rules**:
- `SELECT @ManagerID = ManagerID FROM BackOffice.Manager WHERE Login = @Login AND IsActive = 1`
- If manager not found or IsActive = 0: `@ManagerID` remains NULL
- No NOLOCK - uses default locking for auth-critical read
- Case-sensitive match on Login (no LOWER/UPPER applied - contrast with LoadManagerByUsername which uses case-insensitive)

### 2.2 Permission Loading

**What**: Returns the manager's permissions for the specified provider as a result set.

**Columns/Parameters Involved**: `@Login`, `@ProviderID`, `BackOffice.ManagerToPermission.PermissionID`

**Rules**:
- `SELECT BMTP.PermissionID FROM BackOffice.Manager BMNG JOIN BackOffice.ManagerToPermission BMTP ON BMNG.ManagerID = BMTP.ManagerID WHERE BMNG.Login = @Login AND BMTP.ProviderID = @ProviderID`
- Returns ALL matching PermissionIDs as a result set (one row per permission)
- This runs regardless of whether @ManagerID was found - even if the manager is inactive, their permissions are returned (though the session would not be created)
- ProviderID scopes permissions to the specific BO application

### 2.3 Session Creation (Conditional)

**What**: Creates login audit record and broker listener only if manager is authenticated.

**Rules**:
- `IF @ManagerID IS NOT NULL` -> proceed with session creation
- `BEGIN TRANSACTION` -> `INSERT INTO BackOffice.Login (ManagerID, IP, ClientVersion, ClientTypeID)` -> `SELECT @LoginID = SCOPE_IDENTITY()` -> `EXECUTE Broker.ListenerAdd @ListenerID OUTPUT, 1, @IPAddress, @Port` -> `COMMIT TRANSACTION`
- If @ManagerID IS NULL (unknown or inactive manager): NO login record, NO listener - skips entire block
- `RETURN 0` on success

### 2.4 Error Handling

**Rules**:
- TRY/CATCH with THROW re-raises the original exception
- ROLLBACK if @@TRANCOUNT = 1 (outermost transaction)
- COMMIT if @@TRANCOUNT > 1 (nested - commits the inner savepoint)
- `RETURN 6000` after THROW (never reached in practice since THROW transfers control)

**Diagram**:
```
@Login + @ProviderID
  |
  v
SELECT @ManagerID FROM Manager WHERE Login = @Login AND IsActive = 1
SELECT permissions for @Login + @ProviderID -> result set

IF @ManagerID IS NOT NULL:
  BEGIN TRANSACTION
    INSERT BackOffice.Login -> @LoginID = SCOPE_IDENTITY()
    EXEC Broker.ListenerAdd -> @ListenerID
  COMMIT
RETURN 0

(On error: ROLLBACK, THROW, RETURN 6000)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Login | VARCHAR(20) | NO | - | CODE-BACKED | Manager's login name. Case-sensitive lookup against BackOffice.Manager.Login WHERE IsActive = 1. |
| 2 | @Password | VARCHAR(20) | YES | NULL | CODE-BACKED | Accepted but NOT used in authentication logic. Password validation is performed externally before calling this SP. Present for interface compatibility. |
| 3 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Scopes the permission lookup to a specific Back Office provider/application. Only permissions with this ProviderID in ManagerToPermission are returned. |
| 4 | @IPAddress | VARCHAR(15) | NO | - | CODE-BACKED | Manager's IP address. Stored in BackOffice.Login for audit; passed to Broker.ListenerAdd for network registration. |
| 5 | @Port | INTEGER | NO | - | CODE-BACKED | Manager's connection port. Passed to Broker.ListenerAdd to register the network listener. |
| 6 | @ClientVersion | VARCHAR(20) | NO | - | CODE-BACKED | Back Office client application version. Stored in BackOffice.Login for audit and version tracking. |
| 7 | @ManagerID | INTEGER OUTPUT | YES | - | CODE-BACKED | OUTPUT. Set to the manager's numeric ID if found and active; NULL if login not found or IsActive = 0. Callers use this to determine if authentication succeeded. |
| 8 | @LoginID | INTEGER OUTPUT | YES | - | CODE-BACKED | OUTPUT. Identity value of the newly inserted BackOffice.Login row (SCOPE_IDENTITY()). NULL if session was not created (@ManagerID was NULL). |
| 9 | @ListenerID | INTEGER OUTPUT | YES | - | CODE-BACKED | OUTPUT. Listener ID returned by Broker.ListenerAdd. Used by the BO session to receive real-time data pushes from the trading broker. NULL if session was not created. |
| 10 | @ClientTypeID | TINYINT | YES | 0 | CODE-BACKED | Client type classification (e.g., 0 = default Back Office client). Stored in BackOffice.Login. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PermissionID | INT | NO | - | CODE-BACKED | Each row is a permission ID granted to this manager for the specified @ProviderID. Multiple rows returned (one per permission). Empty set if manager has no permissions for this provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Login | BackOffice.Manager | Lookup | Resolves @ManagerID (IsActive = 1 filter) |
| @Login + @ProviderID | BackOffice.ManagerToPermission | Lookup | Returns permission IDs for this login/provider |
| @ManagerID | BackOffice.Login | Writer | INSERT login audit record with IP, ClientVersion, ClientTypeID |
| @IPAddress + @Port | Broker.ListenerAdd | EXEC | Registers network listener for real-time data push |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LogIn (procedure)
├── BackOffice.Manager (table) [SELECT - ManagerID lookup + permission join]
├── BackOffice.ManagerToPermission (table) [SELECT - permission IDs for ProviderID]
├── BackOffice.Login (table) [INSERT - audit record]
└── Broker.ListenerAdd (procedure) [EXEC - register network listener]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | Identity resolution: ManagerID WHERE Login = @Login AND IsActive = 1; permission join anchor |
| BackOffice.ManagerToPermission | Table | Permission list: PermissionID WHERE ManagerID join + ProviderID = @ProviderID |
| BackOffice.Login | Table | INSERT audit record: ManagerID, IP, ClientVersion, ClientTypeID |
| Broker.ListenerAdd | Stored Procedure | Registers manager's IP:Port as a network listener; returns @ListenerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by the Back Office application login flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| No password validation | Design | @Password parameter is accepted but not used - external auth assumed |
| Case-sensitive Login match | Design | No LOWER/UPPER applied - Login must match exact case in BackOffice.Manager |
| Transaction around Login INSERT + ListenerAdd | Atomicity | Login audit and broker registration are atomic - both succeed or both rollback |
| TRY/CATCH + THROW | Error handling | Re-throws original exception to caller |
| RETURN 0 on success | Convention | Explicit return code 0 = success |

---

## 8. Sample Queries

### 8.1 Authenticate a manager

```sql
DECLARE @ManagerID INT, @LoginID INT, @ListenerID INT;

EXEC [BackOffice].[LogIn]
    @Login        = 'john.smith',
    @Password     = NULL,        -- not validated by SP
    @ProviderID   = 1,
    @IPAddress    = '192.168.1.100',
    @Port         = 8080,
    @ClientVersion = '5.2.1',
    @ManagerID    = @ManagerID OUTPUT,
    @LoginID      = @LoginID OUTPUT,
    @ListenerID   = @ListenerID OUTPUT;

SELECT
    @ManagerID  AS ManagerID,    -- NULL = not authenticated
    @LoginID    AS LoginID,      -- NULL = no session created
    @ListenerID AS ListenerID;   -- NULL = no listener registered
```

### 8.2 Check recent logins

```sql
SELECT TOP 20
    bl.LoginID,
    bl.ManagerID,
    bm.Login AS UserName,
    bl.IP,
    bl.ClientVersion,
    bl.ClientTypeID,
    bl.CreatedDate
FROM BackOffice.Login bl WITH (NOLOCK)
JOIN BackOffice.Manager bm WITH (NOLOCK) ON bm.ManagerID = bl.ManagerID
ORDER BY bl.CreatedDate DESC;
```

### 8.3 Check permissions for a manager on a provider

```sql
SELECT
    bm.Login,
    bmp.PermissionID,
    bmp.ProviderID
FROM BackOffice.Manager bm WITH (NOLOCK)
JOIN BackOffice.ManagerToPermission bmp ON bmp.ManagerID = bm.ManagerID
WHERE bm.Login = 'john.smith'
  AND bmp.ProviderID = 1
ORDER BY bmp.PermissionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.LogIn | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LogIn.sql*
