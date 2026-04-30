# History.LoginOpenBook

> Login session log for the legacy eToro OpenBook platform, recording every successful authentication event with the customer ID, timestamp, IP address, and client type used to log in.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | LoginID (bigint IDENTITY, CLUSTERED PK) |
| **Partition** | No (on HISTORY filegroup) |
| **Indexes** | 3 active (1 CLUSTERED PK + 2 NONCLUSTERED on CID) |

---

## 1. Business Meaning

History.LoginOpenBook records every successful login to the eToro OpenBook platform. Each row represents one authentication event: who logged in (CID), when (LoggedIn in UTC), from where (IP), using which application version (ClientVersion) and client platform (ClientTypeID / ClientType). The table was the primary login history for the OpenBook product era (pre-modern platform), accumulating decades of session data.

The table serves two operational purposes: (1) security and compliance auditing - security teams and compliance officers can reconstruct a customer's login history including IP geolocation to detect suspicious access; and (2) first-login detection - the procedure History.OpenBookLogin queries this table (combined with History.Login) to determine if a customer is logging in for the first time ever, which triggers the Lead Mode flow for marketing attribution.

Data enters this table exclusively through the login procedures: History.OpenBookLogin and History.OpenBookLoginWithCID (and via Customer.Ins_HistoryLoginOpenBook and STS.Authenticate_OpenbookUser). The insert happens within a TRY/CATCH block immediately after successful password validation - if the insert fails, the login procedure still succeeds (error is swallowed by Internal.CallRaiseError). The table resides on the HISTORY filegroup, indicating it is expected to be very large.

---

## 2. Business Logic

### 2.1 First Login Detection

**What**: The table is queried (not just written) by login procedures to determine if a customer has ever previously authenticated on the OpenBook platform. First-login detection drives the marketing Lead Mode.

**Columns/Parameters Involved**: `CID`, `LoginID`

**Rules**:
- A customer is considered a "first-time OpenBook user" if no row exists in History.LoginOpenBook WHERE CID = @CID AND no row exists in History.Login WHERE CID = @CID
- When first-login is detected AND Maintenance.Feature FeatureID=3 (LeadMode) = 2 (OnFirstLogin), a Service Broker message is sent to the Lead processing service
- Test users (PlayerLevelID = 4) are excluded from lead processing even on first login
- The check uses two tables (History.Login + History.LoginOpenBook) because different login flows write to different tables - a user may have logged via a non-OpenBook path before

**Diagram**:
```
Customer authenticates via OpenBook
        |
        v
Check: EXISTS in History.Login WHERE CID = @CID?
  OR   EXISTS in History.LoginOpenBook WHERE CID = @CID?
        |
  YES --> @IsFirstLogin = 0 (returning user)
  NO  --> @IsFirstLogin = 1 (first ever login)
            |
            v
        FeatureID=3 (LeadMode) = 2?
        PlayerLevelID != 4 (not test user)?
            |
            v
        Send Service Broker message to svcLead
        INSERT INTO History.LoginOpenBook (CID, LoggedIn, IP, ClientVersion, ClientTypeID)
```

### 2.2 ClientType Dual Representation

**What**: The platform type is recorded in two columns: a numeric FK (ClientTypeID) and a denormalized text snapshot (ClientType). This reflects a schema evolution where early logins stored free-text client descriptions before the FK was rationalized.

**Columns/Parameters Involved**: `ClientTypeID`, `ClientType`

**Rules**:
- `ClientTypeID`: Numeric FK to Dictionary.ClientType (0=Unknown, 1=Download, 2=WebTrader, 3=Android, 4=iPhone, 5=OpenBook, 6=OpenBook Mobile, 7=CopyMe). DEFAULT=0.
- `ClientType`: Varchar(50) snapshot of the client type text at time of login. In older data (2014-2015 era), this stores more granular values like "OBdesktop", "Openbook Mobile Proxy - Android", "etoro.com_login_by_token". In newer logins, this may be NULL or match the Dictionary value.
- The two columns may be inconsistent for historical data - ClientType was populated by earlier versions of the login procedure before standardization
- When investigating old logins, use ClientType for the most specific platform classification; use ClientTypeID for normalized joins

---

## 3. Data Overview

| LoginID | CID | LoggedIn | IP | ClientTypeID | ClientType | Meaning |
|---|---|---|---|---|---|---|
| 54325896 | 934909 | 2014-12-04 | 212.179.161.98 | 0 | etoro.com_login_by_token | Legacy 2014 login via token-based authentication (SSO flow). The IP (212.179.x) is an eToro internal/Israel network IP - this appears to be an internal QA account from test data. |
| 54841300 | 934909 | 2014-12-15 | 212.179.161.98 | 0 | etoro.com_login_to_ob | Same customer authenticated through the OpenBook-specific login flow on the same day as the token login - two authentication events within the same session (token login then redirect to OpenBook). |
| 55013012 | 1652737 | 2014-12-18 | 212.179.161.98 | 0 | OBdesktop | Desktop OpenBook web application login. ClientVersion "2.7.3.10" confirms this is the legacy OpenBook desktop platform era. |
| 55756651 | 1652737 | 2015-01-04 | 212.179.161.98 | 0 | Openbook Mobile Proxy - Android | Mobile Android login through the OpenBook mobile app. UserAgent confirms Samsung Galaxy S5 (SM-G900F) running Android 4.4.2 - the 2014-era flagship device. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | bigint | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key for each login event. NOT FOR REPLICATION means this identity column does not fire during replication inserts, allowing the original value to be preserved when data is replicated to read-only replicas. CLUSTERED PK - efficient sequential reads and range scans by LoginID order (chronological by default). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the user who logged in. References Customer.CustomerStatic.CID (no explicit FK enforced here). Covered by two nonclustered indexes (IDX_HistLOB and IDX_History_LoginOpenBook_CID) to support efficient lookup of all logins for a specific customer. This is the primary filter column for compliance and security investigations. |
| 3 | LoggedIn | datetime | NO | getdate() | CODE-BACKED | Timestamp of the login event. Populated by login procedures using GETUTCDATE() (UTC), even though the DEFAULT constraint uses getdate() (local time). For all rows inserted via the standard login procedures, this is UTC. The DEFAULT only applies if the value is omitted (e.g., direct inserts), which may result in local time. When correlating with application logs, treat this as UTC. |
| 4 | IP | varchar(15) | NO | - | CODE-BACKED | IPv4 address of the client at time of login. Sourced from Customer.Customer.IP (the customer's last known IP). Maximum length 15 chars supports IPv4 dotted notation (e.g., "255.255.255.255"). Not the requesting client's IP from the HTTP request - this is the stored IP from the customer profile at time of the login call. Used for geolocation and suspicious-access detection. |
| 5 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Application version string of the eToro client software used to log in (e.g., "2.7.3.10"). Populated from the @ClientVersion parameter passed by the application. NULL for sessions where the client did not report a version. Useful for correlating login failures or anomalies with specific software releases. |
| 6 | ClientTypeID | tinyint | YES | 0 | CODE-BACKED | Numeric client platform type: 0=Unknown, 1=Download, 2=WebTrader, 3=Android, 4=iPhone, 5=OpenBook, 6=OpenBook Mobile, 7=CopyMe. FK enforced to Dictionary.ClientType. DEFAULT=0 (Unknown) - used when the calling procedure passes @ClientTypeID=0 (the default parameter value). In the test data, most logins are type 0 because older OpenBook procedures did not pass a specific type. |
| 7 | ClientType | varchar(50) | YES | - | CODE-BACKED | Denormalized text snapshot of the client platform at time of login. In legacy data (2014-2015), stores granular values like "OBdesktop", "Openbook Mobile Proxy - Android", "etoro.com_login_by_token", "WebTrader". More granular than ClientTypeID for older data. May be NULL in newer logins where the procedure only sets ClientTypeID. This column represents the free-text era before Dictionary.ClientType was used consistently. |
| 8 | UserAgent | varchar(255) | YES | - | CODE-BACKED | HTTP User-Agent string reported by the login client (browser or mobile SDK). Captures browser name and version (for web logins) or device OS and model (for mobile logins). NULL when the client did not report a user agent or when the login flow did not collect it. Useful for device fingerprinting and fraud analysis. Maximum 255 characters - long user-agent strings may be truncated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClientTypeID | Dictionary.ClientType | FK (FK_HL_CTID2) | Classifies the client platform (0=Unknown through 7=CopyMe). The FK is enforced with CHECK CONSTRAINT. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.OpenBookLogin | CID | Reader (first-login check) + Writer | Checks for existing rows to detect first login; then INSERTs new login row |
| History.OpenBookLoginWithCID | CID | Reader (first-login check) + Writer | Same pattern as OpenBookLogin but called with CID directly |
| Customer.Ins_HistoryLoginOpenBook | (INSERT) | Writer | Customer schema wrapper for inserting login records |
| History.GetUserLogins | CID | Reader | Retrieves login history for a specific user |
| STS.Authenticate_OpenbookUser | CID | Writer/Reader | STS authentication flow writes login events here |
| STS.Find_OpenbookUser | CID | Reader | User lookup via login history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LoginOpenBook (table)
  - No code-level dependencies (leaf table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ClientType | Table | FK target for ClientTypeID (FK_HL_CTID2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.OpenBookLogin | Stored Procedure | First-login detection (EXISTS check) + Writer (INSERT on successful auth) |
| History.OpenBookLoginWithCID | Stored Procedure | First-login detection + Writer |
| History.GetUserLogins | Stored Procedure | Reads all login records for a given CID |
| Customer.Ins_HistoryLoginOpenBook | Stored Procedure | Insert wrapper |
| STS.Authenticate_OpenbookUser | Stored Procedure | Writes login events during STS authentication |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HLOG2 | CLUSTERED | LoginID ASC | - | - | Active |
| IDX_HistLOB | NONCLUSTERED | CID ASC, LoggedIn ASC | IP | - | Active |
| IDX_History_LoginOpenBook_CID | NONCLUSTERED | CID ASC | LoginID, IP, LoggedIn | - | Active |

FILLFACTOR: 90% on PK, 90% on IDX_HistLOB, 80% on IDX_History_LoginOpenBook_CID - lower fill factors account for insert-heavy workload. Both nonclustered indexes compress with PAGE compression. Table resides on the HISTORY filegroup (separate from PRIMARY) - designed for large historical datasets.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HLOG2 | PRIMARY KEY | Clustered PK on LoginID |
| HLOG_LOGGED2 | DEFAULT | LoggedIn = getdate() (note: procedures override this with GETUTCDATE()) |
| DFHL_ClientTypeID2 | DEFAULT | ClientTypeID = 0 (Unknown) when not specified |
| FK_HL_CTID2 | FOREIGN KEY | ClientTypeID REFERENCES Dictionary.ClientType(ClientTypeID) |

---

## 8. Sample Queries

### 8.1 Get all login history for a specific customer

```sql
SELECT
    LoginID,
    LoggedIn,
    IP,
    ClientTypeID,
    ClientType,
    UserAgent,
    ClientVersion
FROM [History].[LoginOpenBook] WITH (NOLOCK)
WHERE CID = @CustomerCID
ORDER BY LoggedIn DESC
```

### 8.2 Detect unusual logins from new IP addresses for a customer

```sql
WITH CustomerIPs AS (
    SELECT DISTINCT IP, MIN(LoggedIn) AS FirstSeen
    FROM [History].[LoginOpenBook] WITH (NOLOCK)
    WHERE CID = @CustomerCID
    GROUP BY IP
)
SELECT
    l.LoginID,
    l.LoggedIn,
    l.IP,
    l.ClientType,
    ci.FirstSeen AS IpFirstSeenAt
FROM [History].[LoginOpenBook] l WITH (NOLOCK)
JOIN CustomerIPs ci ON ci.IP = l.IP
WHERE l.CID = @CustomerCID
  AND l.LoggedIn >= DATEADD(DAY, -90, GETDATE())
ORDER BY l.LoggedIn DESC
```

### 8.3 Login volume by client type over time

```sql
SELECT
    CAST(LoggedIn AS DATE) AS LoginDate,
    ct.ClientTypeName,
    COUNT(*) AS LoginCount
FROM [History].[LoginOpenBook] lob WITH (NOLOCK)
JOIN [Dictionary].[ClientType] ct WITH (NOLOCK) ON ct.ClientTypeID = lob.ClientTypeID
WHERE lob.LoggedIn >= DATEADD(MONTH, -3, GETDATE())
GROUP BY CAST(LoggedIn AS DATE), ct.ClientTypeName
ORDER BY LoginDate DESC, LoginCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (History.OpenBookLogin, History.GetUserLogins) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LoginOpenBook | Type: Table | Source: etoro/etoro/History/Tables/History.LoginOpenBook.sql*
