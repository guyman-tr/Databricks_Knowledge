# History.LogIn

> Customer login procedure that creates an authenticated session record in Customer.Login, forces logout of any pre-existing open session, detects first-ever logins for lead tracking, fires activity events, and handles expired demo account notifications.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer) + generated @CustomerSessionID (GUID session token) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogIn` is the central customer authentication session procedure. When a customer logs in to the eToro platform, this procedure is invoked to register the login event in the database. It inserts a new active session row into `Customer.Login`, outputs a GUID session token that the application uses for subsequent authenticated calls, and returns the generated ActionID that links the session to the broader action/event log.

The procedure exists to enforce session integrity: a customer can have only one active session at a time. If the customer already has an open session in `Customer.Login`, the procedure detects it and calls `History.LogOutByLoginID` to force-close it before creating the new session. This prevents orphaned sessions that would block future logins.

Data flow: The application calls this procedure on successful credential validation. The procedure (1) reads `Customer.Login` to detect any existing open session; (2) if found, forces logout via `History.LogOutByLoginID`; (3) normalizes string inputs (client version, IP, MAC ID); (4) inserts the new session row into `Customer.Login`; (5) fires login events (10=any login, 12=demo, 14=real, 29=first weekly login) via `Customer.SendEvent`; (6) checks if this is the customer's absolute first login and, when LeadMode=2, sends lead data to the marketing pipeline via SQL Service Broker; (7) on commit, handles expired demo account messaging; (8) calls `Internal.CleanupGames` for the CID.

---

## 2. Business Logic

### 2.1 Single Active Session Enforcement

**What**: A customer may not have more than one active session simultaneously. Any existing open session is force-closed before the new session is created.

**Columns/Parameters Involved**: `@CID`, `@ActionID` (OUTPUT)

**Rules**:
- On entry, the procedure queries `Customer.Login WHERE CID = @CID` to find any open session (LoginID stored in @LastLoginID)
- If @LastLoginID IS NOT NULL, `History.LogOutByLoginID` is called with @CID and the LoginID to close the prior session before proceeding
- Only after the prior session is closed does the INSERT into `Customer.Login` proceed within the same transaction

**Diagram**:
```
Customer calls LogIn
     |
     v
SELECT LoginID FROM Customer.Login WHERE CID = @CID
     |
     +-- LoginID found? --> EXEC History.LogOutByLoginID (force close old session)
     |
     v
INSERT INTO Customer.Login (new session)
     |
     v
COMMIT
```

### 2.2 First-Ever Login Lead Tracking (LeadMode=2)

**What**: When the platform is in LeadMode=2, the procedure detects if this is a customer's absolute first login across all platforms (including OpenBook) and sends their profile as a lead to the marketing pipeline via SQL Service Broker.

**Columns/Parameters Involved**: `@CID`, `@IsVirtual`, `@LobbyID`

**Rules**:
- Reads `Maintenance.Feature WHERE FeatureID = 3` to determine LeadMode. Only when value = 2 does lead detection run.
- A customer is "never logged in before" if they have NO rows in `History.LoginArch` AND no rows in `History.LoginOpenBook` for their CID
- Test users (PlayerLevelID = 4 in Customer.Customer) are excluded from lead tracking
- When all conditions are met, a Service Broker dialog conversation to `svcLead` is opened and the customer's profile XML is sent (CID, ProviderID, OriginalProviderID, RealProviderID, IsReal, CountryID via IP lookup, SerialID, SubSerialID, DownloadID, BannerID, DownloadCounter, PlayerLevelID, FunnelID, LabelID, Occurred)

**Diagram**:
```
LeadMode = 2?
     |
     v
Customer exists AND PlayerLevelID != 4 (not test)?
     |
     v
NOT in History.LoginArch AND NOT in History.LoginOpenBook?
     |
     v
Build XML with customer profile
     |
     v
BEGIN DIALOG to svcLead, SEND XML -> marketing lead pipeline
```

### 2.3 Login Event Firing

**What**: Every login fires a set of events via `Customer.SendEvent` that update aggregations, trigger notifications, and track weekly engagement.

**Columns/Parameters Involved**: `@CID`, `@IsVirtual`

**Rules**:
- Only fires when `@IsVirtual = 0` (real session, not virtual/test)
- Event 29 (First Weekly Login): fires when this login's week number (DATEPART(week)) differs from the customer's last login date in History.Login
- Event 10: always fires for any login (real or demo)
- Event 14 (real customer login): fires when `Customer.Customer.IsReal = 1`
- Event 12 (demo login): fires when `Customer.Customer.IsReal = 0`
- If any SendEvent call returns non-zero, the procedure returns that error code immediately

**Diagram**:
```
@IsVirtual = 0?
     |
     v
Current week != last login week? -> Event 29 (First Weekly Login)
     |
     v
Event 10 (any login - always)
     |
     v
IsReal = 1? -> Event 14 (real login)
         0? -> Event 12 (demo login)
```

### 2.4 Expired Demo Account Notification

**What**: After committing the new session, if the logging-in customer is an expired demo account, a notification message is sent.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- Check is post-COMMIT: `Customer.Customer WHERE PlayerStatusID = 9 AND AccountExpirationDate <= GETUTCDATE() AND IsReal = 0`
- PlayerStatusID=9 indicates expired demo status
- When condition is true, `Customer.SendMessage` is called with MessageTypeID=19 and the customer's first name
- If FirstName is NULL, defaults to 'Customer'

### 2.5 Virtual Session Handling

**What**: @IsVirtual=1 sessions skip all event firing, lead detection based on logins, and notifications - they only create the session record.

**Columns/Parameters Involved**: `@IsVirtual`

**Rules**:
- All event firing (events 10, 12, 14, 29) is guarded by `IF @IsVirtual = 0`
- The XMLData build (for legacy svcDispatcher - now commented out) is also guarded by `IF @IsVirtual = 0`
- @IsVirtual defaults to 0; pass 1 for automated/test sessions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the logging-in customer. Used to find existing open sessions in Customer.Login, read customer profile from Customer.Customer, look up login history in History.Login and History.LoginArch. The primary identifier driving all logic in this procedure. |
| 2 | @GameTypeID | INT | NO | - | NAME-INFERRED | Game/platform type ID for the login context. Received by the procedure but not used in any direct DML or conditional logic visible in the current body. Likely a legacy parameter retained for backward compatibility with callers. |
| 3 | @LanguageID | INT | NO | - | NAME-INFERRED | Language preference ID passed by the client. Received but not applied in the active code (the block that would have updated Customer.Customer.LanguageID is commented out). Retained for interface compatibility. |
| 4 | @ClientVersion | VARCHAR(20) | NO | - | CODE-BACKED | Client application version string (e.g., "2.1.5"). Normalized via Internal.NormalizeString before storage. Stored in Customer.Login.ClientVersion to track which app version was used for this session. |
| 5 | @IP | VARCHAR(15) | NO | - | CODE-BACKED | Customer's IP address at login time (IPv4, up to 15 chars). Normalized via Internal.NormalizeString. Stored in Customer.Login.IP. Also passed to Internal.GetCountryIDByIP for country resolution in the lead tracking XML payload. |
| 6 | @MACID | CHAR(17) | NO | - | CODE-BACKED | MAC address of the client device in standard format (17 chars: "XX:XX:XX:XX:XX:XX"). Normalized via Internal.NormalizeString. Stored in Customer.Login.MACID. Used for device fingerprinting / fraud detection at the data layer. |
| 7 | @ActionID | BIGINT | OUTPUT | - | CODE-BACKED | Output-only: receives the newly generated ActionID from Internal.GetActionID. This becomes the LoginID in Customer.Login (LoginID = ActionID = same value, both set to @ActionID). Returned to caller as the unique session identifier and audit trail anchor. |
| 8 | @NumberOfConnections | INT | OUTPUT | - | CODE-BACKED | Output-only: returns the number of connections before this login (always 0 in the current code path). Historically tracked concurrent connections; now returns 0 as a constant. Customer.Login.NumberOfConnections is set to 1 (the new connection). |
| 9 | @CustomerSessionID | CHAR(36) | OUTPUT | - | CODE-BACKED | Output-only: the GUID session token issued for this login. Generated via NEWID() and stored in Customer.Login.CustomerSessionID. The application uses this token for subsequent authenticated API calls to correlate client requests with the active session. |
| 10 | @LobbyID | INT | NO | - | CODE-BACKED | Lobby context identifier. Stored in Customer.Login.LobbyID. Identifies which lobby/context the customer is logging in to (e.g., real money vs. demo lobby). Also included in the XMLData payload for the legacy dispatcher (commented out). |
| 11 | @IsVirtual | BIT | YES | 0 | CODE-BACKED | Whether this login session is virtual (automated/test). Default 0 = real session. When 1, suppresses all event firing (SendEvent calls for events 10, 12, 14, 29), lead tracking eligibility check, and expired demo messaging. Stored in Customer.Login.IsVirtual. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Lookup | Reads IsReal, Credit, PlayerLevelID, PlayerStatusID, AccountExpirationDate, FirstName, LanguageID for event decisions and lead XML |
| @CID | Customer.Login | WRITER (INSERT) | Creates the active session row; also queries for existing open session before insert |
| @CID | History.Login | Lookup | Reads last login date (max LoggedIn WHERE CID=@CID) to determine if this is the first login of the current week for event 29 |
| @CID | History.LoginArch | Lookup | Checks if any historical login record exists for this CID to detect first-ever login for lead tracking |
| @CID | History.LoginOpenBook | Lookup | Checks if any OpenBook login record exists to detect first-ever login (OpenBook platform) |
| FeatureID=3 | Maintenance.Feature | Lookup | Reads LeadMode setting to determine if first-login lead tracking is active |
| - | History.LogOutByLoginID | Procedure call | Called when an existing open session is found; force-closes the prior session before creating new one |
| - | Internal.GetActionID | Procedure call | Generates the new ActionID/LoginID for the session |
| - | Internal.NormalizeString | Function call | Sanitizes @ClientVersion, @IP, @MACID inputs |
| - | Internal.GetCountryIDByIP | Function call | Resolves @IP to CountryID for the lead XML payload |
| - | Customer.SendEvent | Procedure call | Fires events 10 (any login), 12 (demo login), 14 (real login), 29 (first weekly login) |
| - | Customer.SendMessage | Procedure call | Sends message type 19 to expired demo customers |
| - | Internal.CleanupGames | Procedure call | Cleans up game state for the CID post-login |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LogInIB | @CID (and other params) | Procedure call | IB (Introducing Broker) variant of login that calls History.LogIn to reuse core session creation logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogIn (procedure)
+-- Customer.Login (table)
+-- Customer.Customer (table)
+-- History.Login (table)
+-- History.LoginArch (table)
+-- History.LoginOpenBook (table)
+-- Maintenance.Feature (table)
+-- History.LogOutByLoginID (procedure)
+-- Internal.GetActionID (procedure)
+-- Internal.NormalizeString (function)
+-- Internal.GetCountryIDByIP (function)
+-- Customer.SendEvent (procedure)
+-- Customer.SendMessage (procedure)
+-- Internal.CleanupGames (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | SELECT to detect existing open session; INSERT to create new session row |
| Customer.Customer | Table | SELECT to read IsReal, Credit, PlayerLevelID, PlayerStatusID, AccountExpirationDate, FirstName, LanguageID |
| History.Login | Table | SELECT max(LoggedIn) to determine last login date for weekly event check |
| History.LoginArch | Table | EXISTS check - has this CID ever logged in (archived logins) |
| History.LoginOpenBook | Table | EXISTS check - has this CID ever logged in to OpenBook platform |
| Maintenance.Feature | Table | SELECT Feature.Value WHERE FeatureID=3 to read LeadMode |
| History.LogOutByLoginID | Procedure | Called to force-close prior open session when one is detected |
| Internal.GetActionID | Procedure | Called to generate the new ActionID output parameter |
| Internal.NormalizeString | Function | Called 3x to sanitize ClientVersion, IP, MACID |
| Internal.GetCountryIDByIP | Function | Called inline in SELECT for lead XML to resolve IP to CountryID |
| Customer.SendEvent | Procedure | Called to fire login events 10, 12, 14, 29 |
| Customer.SendMessage | Procedure | Called to send expired-demo notification message type 19 |
| Internal.CleanupGames | Procedure | Called post-commit to clean up game state for the CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LogInIB | Procedure | Calls History.LogIn to execute the core session creation; LogInIB wraps it with IB-specific pre/post logic |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Session uniqueness | Application | Only one active Customer.Login row per CID is allowed; enforced by the pre-check and force-logout pattern, not a DB constraint |
| Error 60000 | RAISERROR | INSERT into Customer.Login failed; triggers ROLLBACK and returns error code 60000 to caller |

---

## 8. Sample Queries

### 8.1 Find all active sessions for a customer

```sql
SELECT LoginID, CID, LoggedIn, IP, ClientVersion, IsVirtual, LobbyID, CustomerSessionID
FROM Customer.Login WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY LoggedIn DESC
```

### 8.2 Check a customer's last login date and weekly status

```sql
SELECT
    CID,
    MAX(LoggedIn) AS LastLoginDate,
    DATEPART(week, MAX(LoggedIn)) AS LastLoginWeek
FROM History.Login WITH (NOLOCK)
WHERE CID = 12345678
GROUP BY CID
```

### 8.3 Find customers whose first-ever login triggered lead tracking (LeadMode=2 history)

```sql
SELECT la.CID, MIN(la.LoggedIn) AS FirstLoginDate, c.IsReal, c.PlayerLevelID
FROM History.LoginArch la WITH (NOLOCK)
INNER JOIN Customer.Customer c WITH (NOLOCK) ON c.CID = la.CID
WHERE c.PlayerLevelID <> 4  -- exclude test users
  AND NOT EXISTS (
    SELECT 1 FROM History.LoginOpenBook lo WITH (NOLOCK) WHERE lo.CID = la.CID
  )
GROUP BY la.CID, c.IsReal, c.PlayerLevelID
ORDER BY FirstLoginDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 8.2/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (LogOutByLoginID, LogIn body) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LogIn | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogIn.sql*
