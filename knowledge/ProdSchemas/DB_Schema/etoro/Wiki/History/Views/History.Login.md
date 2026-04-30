# History.Login

> Schema-compatibility stub view that permanently returns zero rows - maintains the column interface of the historical login table after its data source was deprecated and removed to EtoroArchive in November 2024.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | No PK - view with WHERE 1=0 (always empty) |
| **Base Objects** | None - all columns are CONVERT(type, NULL) literals |

---

## 1. Business Meaning

History.Login is a stub compatibility view created on 2024-11-25 (Ran Ovadia: "Ran Ovadia did this shit on 25/11/24 in order to remove the usage in History.Login from EtoroArchive"). Before this date, History.Login was backed by an actual table containing historical login session records - rows migrated out of Customer.Login when sessions ended.

The table was removed or migrated to the EtoroArchive database. Rather than break the many callers (BackOffice procedures, History stored procedures, STS authentication, Customer services) that query `FROM History.Login`, the stub view was created with the identical 13-column schema, returning NULL typed columns filtered by `WHERE 1 = 0` - making every query return an empty result set without errors.

This allows the codebase to continue compiling and executing against History.Login without modification, while the actual data no longer exists in this database.

---

## 2. Business Logic

### 2.1 Stub Pattern - WHERE 1=0

**What**: The view defines the expected column types using CONVERT(type, NULL) for each column, with a `WHERE 1 = 0` predicate that ensures the view always returns zero rows.

**Rules**:
- Any SELECT from History.Login returns 0 rows, regardless of WHERE clauses applied by callers
- The view's column list and types exactly match the former table schema so dependent code compiles without errors
- History.LoginArch (a UNION ALL view) combines Customer.Login with History.Login - since History.Login is empty, LoginArch now effectively shows only active Customer.Login sessions
- Procedures that INSERT into History.Login (e.g., History.LogIn, Customer.Ins_HistoryLoginOpenBook) may still succeed if they reference the view, but the data goes nowhere

**Columns preserved for compatibility**:
- LoginID (BIGINT), CID (INT), ActionID (BIGINT), LoggedIn (DATETIME), LoggedOut (DATETIME)
- NumberOfConnections (INT), IP (VARCHAR(15)), ClientVersion (VARCHAR(20)), IsLogged (INT)
- MACID (CHAR(17)), CustomerSessionID (UNIQUEIDENTIFIER), IsVirtual (BIT), LobbyID (INT), ClientTypeID (TINYINT)

---

## 3. Data Overview

Always returns 0 rows (WHERE 1=0). No data in this database since 2024-11-25.

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | LoginID | BIGINT | YES (NULL) | CODE-BACKED | Former PK of the login session record. Always NULL in this stub. |
| 2 | CID | INT | YES (NULL) | CODE-BACKED | Customer ID of the logged-in user. Always NULL. |
| 3 | ActionID | BIGINT | YES (NULL) | CODE-BACKED | Action log reference for the login event. Always NULL. Only present in History.Login, not Customer.Login. |
| 4 | LoggedIn | DATETIME | YES (NULL) | CODE-BACKED | Session start timestamp. Always NULL. |
| 5 | LoggedOut | DATETIME | YES (NULL) | CODE-BACKED | Session end timestamp. Always NULL. |
| 6 | NumberOfConnections | INT | YES (NULL) | CODE-BACKED | Number of concurrent connections during this session. Always NULL. |
| 7 | IP | VARCHAR(15) | YES (NULL) | CODE-BACKED | Client IP address (IPv4 format). Always NULL. |
| 8 | ClientVersion | VARCHAR(20) | YES (NULL) | CODE-BACKED | eToro client application version. Always NULL. |
| 9 | IsLogged | INT | YES (NULL) | CODE-BACKED | Login state flag. Always NULL. |
| 10 | MACID | CHAR(17) | YES (NULL) | CODE-BACKED | MAC address of client device. Always NULL. |
| 11 | CustomerSessionID | UNIQUEIDENTIFIER | YES (NULL) | CODE-BACKED | GUID session identifier for customer session tracking. Always NULL. |
| 12 | IsVirtual | BIT | YES (NULL) | CODE-BACKED | Whether this was a virtual/demo account login. Always NULL. |
| 13 | LobbyID | INT | YES (NULL) | CODE-BACKED | Lobby/environment identifier. Always NULL. Not present in Customer.Login. |
| 14 | ClientTypeID | TINYINT | YES (NULL) | CODE-BACKED | Client application type (web, mobile, desktop). Always NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None - the view references no base tables.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LoginArch | History.Login | UNION ALL consumer | Combines with Customer.Login - History.Login part is always empty |
| History.LogIn | History.Login | Writer (now no-op) | Originally inserted active logins; now inserts into a view that returns 0 rows |
| History.LogOutByCID | History.Login | Writer/Reader | Logout procedure that updates login records |
| History.LogOutByLoginID | History.Login | Writer/Reader | Logout by specific LoginID |
| BackOffice.GetCustomerByCID | History.Login | Reader | Customer lookup including login history |
| BackOffice.GetCustomerByCIDVerification | History.Login | Reader | Verification lookup using login history |
| STS.Authenticate_OpenbookUser | History.Login | Reader | OpenBook authentication using login records |
| STS.Find_OpenbookUser | History.Login | Reader | OpenBook user lookup |
| Customer.Ins_HistoryLoginOpenBook | History.Login | Writer | OpenBook login insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Login (view)
  No base table dependencies (stub - all NULLs)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LoginArch | View | UNION ALL - combines with Customer.Login |
| History.LogIn | Stored Procedure | Writer (now no-op) |
| History.LogOutByCID | Stored Procedure | Writer/Reader (now no-op) |
| History.LogOutByLoginID | Stored Procedure | Writer/Reader (now no-op) |
| BackOffice.GetCustomerByCID | Stored Procedure | Reader (returns empty) |
| BackOffice.GetCustomerByCIDVerification | Stored Procedure | Reader (returns empty) |
| STS.Authenticate_OpenbookUser | Stored Procedure | Reader (returns empty) |
| STS.Find_OpenbookUser | Stored Procedure | Reader (returns empty) |

---

## 7. Technical Details

### 7.1 View Definition

```sql
CREATE VIEW [History].[Login] AS
SELECT
    CONVERT(BIGINT, NULL)        AS [LoginID],
    CONVERT(INT, NULL)           AS [CID],
    CONVERT(BIGINT, NULL)        AS [ActionID],
    CONVERT(DATETIME, NULL)      AS [LoggedIn],
    CONVERT(DATETIME, NULL)      AS [LoggedOut],
    CONVERT(INT, NULL)           AS [NumberOfConnections],
    CONVERT(VARCHAR(15), NULL)   AS [IP],
    CONVERT(VARCHAR(20), NULL)   AS [ClientVersion],
    CONVERT(INT, NULL)           AS [IsLogged],
    CONVERT(CHAR(17), NULL)      AS [MACID],
    CONVERT(UNIQUEIDENTIFIER, NULL) AS [CustomerSessionID],
    CONVERT(BIT, NULL)           AS [IsVirtual],
    CONVERT(INT, NULL)           AS [LobbyID],
    CONVERT(TINYINT, NULL)       AS [ClientTypeID]
WHERE 1 = 0
```

---

## 8. Sample Queries

### 8.1 Verify the stub behavior
```sql
-- Always returns 0 rows
SELECT COUNT(*) AS AlwaysZero FROM History.Login WITH (NOLOCK);
```

### 8.2 Confirm column schema compatibility
```sql
SELECT TOP 0 * FROM History.Login;
-- Use this to verify column names/types match expected schema
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Login | Type: View | Source: etoro/etoro/History/Views/History.Login.sql*
