# History.LoginArch

> UNION ALL view combining active login sessions from Customer.Login with historical login records from History.Login - provides a single query interface for the complete login history spanning current and archived sessions. Note: History.Login is now a stub returning zero rows, so this view effectively returns only Customer.Login data.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | No PK - UNION ALL view |
| **Base Objects** | Customer.Login, History.Login |

---

## 1. Business Meaning

History.LoginArch is the unified login history view that combines two data sources:
1. **Customer.Login** - the live table of current and recent login sessions (active rows with NULL LoggedOut for ongoing sessions)
2. **History.Login** - the historical archive of completed sessions (now a stub view returning zero rows since 2024-11-25)

The intent was to provide a single query surface for "all logins ever" - current sessions from Customer.Login plus archived sessions from History.Login. After the November 2024 migration that replaced the History.Login table with a stub view, this UNION ALL continues to work but now returns only Customer.Login data.

Back-office procedures, STS authentication services, and customer management queries use this view to look up a customer's last login, verify session state, or report on login history without knowing which table holds which records.

---

## 2. Business Logic

### 2.1 UNION ALL Pattern - Active + Historical

**What**: Combines active logins (Customer.Login, IsLogged=1) with historical logins (History.Login, now empty).

**Rules**:
- Customer.Login rows: LoggedIn=session start, LoggedOut=NULL (for active) or session end (for inactive); IsLogged hardcoded to 1 in this view
- History.Login rows (now empty): LoggedIn=session start, LoggedOut=session end; IsLogged=actual value from the table
- The UNION ALL produces all rows from both - no deduplication
- ActionID (BIGINT) from History.Login - not present in Customer.Login, so not included in this view
- LobbyID from History.Login - not included in this view
- Since History.Login always returns 0 rows, History.LoginArch currently = Customer.Login with IsLogged forced to 1

**Schema differences handled**:
- Customer.Login has no `ActionID` column - excluded from the UNION
- Customer.Login has no `LobbyID` column - excluded from the UNION
- LoggedOut in Customer.Login branch = NULL AS LoggedOut (active sessions have no logout time yet)
- IsLogged in Customer.Login branch = hardcoded 1 (currently logged in)

---

## 3. Data Overview

Volume reflects Customer.Login (active/recent sessions). History.Login contributes 0 rows. See Customer.Login documentation for full data profile.

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | LoginID | BIGINT | YES | CODE-BACKED | Session login identifier. From Customer.Login.LoginID or History.Login.LoginID (now always NULL). |
| 2 | CID | INT | YES | CODE-BACKED | Customer ID of the session owner. |
| 3 | LoggedIn | DATETIME | YES | CODE-BACKED | Session start timestamp. |
| 4 | LoggedOut | DATETIME | YES | CODE-BACKED | Session end timestamp. NULL for active sessions (from Customer.Login branch) and NULL from History.Login stub. |
| 5 | NumberOfConnections | INT | YES | CODE-BACKED | Number of concurrent connections during this session. |
| 6 | IP | VARCHAR(15) | YES | CODE-BACKED | Client IP address at login time. |
| 7 | ClientVersion | VARCHAR(20) | YES | CODE-BACKED | eToro application version at login time. |
| 8 | IsLogged | INT | YES | CODE-BACKED | Login state. Hardcoded 1 for Customer.Login branch (currently logged in). From History.Login branch (now always NULL/empty). |
| 9 | MACID | CHAR(17) | YES | CODE-BACKED | Client device MAC address. |
| 10 | CustomerSessionID | UNIQUEIDENTIFIER | YES | CODE-BACKED | GUID session identifier. |
| 11 | IsVirtual | BIT | YES | CODE-BACKED | Whether this is a virtual/demo account session. |
| 12 | ClientTypeID | TINYINT | YES | CODE-BACKED | Client application type (web, mobile, desktop). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Customer branch) | Customer.Login | UNION ALL (first branch) | Active login sessions. Source of all current data. |
| (History branch) | History.Login | UNION ALL (second branch) | Historical archived sessions. Currently returns 0 rows (stub). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCID | LoginArch | Reader | Customer lookup including login history |
| BackOffice.GetCustomerByCIDVerification | LoginArch | Reader | Verification with login context |
| BackOffice.CustomerFirstTimeLogged | LoginArch | Reader | Determines if a customer has ever logged in |
| BackOffice.IsFirstLogin (Function) | LoginArch | Reader | Function checking first-login status |
| STS.Authenticate_OpenbookUser | LoginArch | Reader | OpenBook authentication |
| STS.Find_OpenbookUser | LoginArch | Reader | OpenBook user lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LoginArch (view)
  -> Customer.Login (table) [cross-schema]
  -> History.Login (view/stub) [documented - always empty]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | First UNION ALL branch - provides all current data |
| History.Login | View (stub) | Second UNION ALL branch - returns 0 rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Stored Procedure | READER - login history lookup |
| BackOffice.GetCustomerByCIDVerification | Stored Procedure | READER |
| BackOffice.CustomerFirstTimeLogged | View | READER - first login detection |
| BackOffice.IsFirstLogin | Function | READER - first login check |
| STS.Authenticate_OpenbookUser | Stored Procedure | READER |
| STS.Find_OpenbookUser | Stored Procedure | READER |

---

## 7. Technical Details

### 7.1 View Definition

```sql
CREATE VIEW History.LoginArch AS
SELECT LoginID, CID, LoggedIn, NULL AS LoggedOut, NumberOfConnections,
       IP, ClientVersion, 1 AS IsLogged, MACID, CustomerSessionID, IsVirtual, ClientTypeID
FROM Customer.Login WITH (NOLOCK)
UNION ALL
SELECT LoginID, CID, LoggedIn, LoggedOut, NumberOfConnections,
       IP, ClientVersion, IsLogged, MACID, CustomerSessionID, IsVirtual, ClientTypeID
FROM History.Login WITH (NOLOCK)
```

---

## 8. Sample Queries

### 8.1 Get all login sessions for a customer
```sql
SELECT LoginID, LoggedIn, LoggedOut, IP, ClientVersion, IsLogged, ClientTypeID
FROM History.LoginArch
WHERE CID = 12345
ORDER BY LoggedIn DESC;
```

### 8.2 Find a customer's last login date
```sql
SELECT MAX(LoggedIn) AS LastLogin
FROM History.LoginArch
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LoginArch | Type: View | Source: etoro/etoro/History/Views/History.LoginArch.sql*
