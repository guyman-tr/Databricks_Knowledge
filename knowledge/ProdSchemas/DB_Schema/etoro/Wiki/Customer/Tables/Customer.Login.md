# Customer.Login

> Active trading session state table: one row per currently logged-in customer, tracking their session ID, IP, client type, and connection count. UNIQUE on CID enforces one active session per customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | LoginID (bigint, PK) |
| **Partition** | No (MAIN filegroup, FILLFACTOR=90) |
| **Indexes** | 4 (1 clustered PK + 1 UNIQUE NC on CID + 1 NC on LoggedIn + 1 UNIQUE NC on CustomerSessionID) |

---

## 1. Business Meaning

Customer.Login is the live trading session registry. Each row represents a customer who is currently logged in to the trading platform. The UNIQUE constraint on CID (UK_CID_CLOG) enforces that a customer can have at most one active session at a time - if a new login arrives for a CID, the previous row must first be removed or replaced.

The table exists as the real-time session state for the trade server. Financial operations (Customer.SetBalance and variants) check for session presence before executing trades - a NOT EXISTS check on Customer.Login determines whether the customer is currently connected, affecting trade authorization flow. Session lookup by CustomerSessionID (unique, indexed) is the primary session-validation path used by the trade server to authenticate incoming requests.

Data flows: the trade server writes rows on customer login and removes them on logout. The LoginInsert trigger fires on every INSERT and updates BackOffice.LastCustomerInfo with the customer's new LoginID (first login: INSERT; subsequent logins: UPDATE). This creates a persistent record of each customer's most recent session, even after the session ends. The table on this environment contains 1,644 rows dated 2013-2017, indicating this is a non-production or decommissioned environment - active production environments would have millions of live sessions rotating continuously.

---

## 2. Business Logic

### 2.1 One Active Session Per Customer (UNIQUE CID Constraint)

**What**: The UNIQUE constraint on CID enforces a single-session-per-customer model, making this a state table rather than a history log.

**Columns/Parameters Involved**: `CID`, `LoginID`, `CustomerSessionID`, `LoggedIn`

**Rules**:
- UK_CID_CLOG: UNIQUE NONCLUSTERED on CID - at most one active session row per customer
- ix_IX_CULG_SessionIDIncCID: UNIQUE on CustomerSessionID INCLUDE CID - session ID is globally unique, used for fast session lookups
- When a customer reconnects: the trade server deletes the old row and inserts a new one (new LoginID, new CustomerSessionID, updated LoggedIn timestamp)
- NumberOfConnections tracks concurrent connections within the same session (starts at 1 per HLOG_CONNECTION default)
- Financial procedures like Customer.SetBalance include: `AND NOT EXISTS (SELECT 1 FROM Customer.Login WHERE CLOG.CID = @CID)` - checking login state as part of trade authorization

### 2.2 LoginInsert Trigger - Propagates to BackOffice.LastCustomerInfo

**What**: On every login INSERT, the trigger propagates the new LoginID to BackOffice.LastCustomerInfo to maintain a persistent "last login" record that survives after the session ends.

**Columns/Parameters Involved**: `CID`, `LoginID` (Inserted)

**Rules**:
- Trigger fires FOR INSERT (not AFTER), single-row only (ROWCOUNT != 1 -> RETURN)
- First login ever: INSERT into BackOffice.LastCustomerInfo (CID, LoginID, PaymentID=NULL, CashoutID=NULL)
- Subsequent login: UPDATE BackOffice.LastCustomerInfo SET LoginID = new LoginID WHERE CID = inserted.CID
- This means BackOffice.LastCustomerInfo always has the customer's LATEST LoginID, even after logout
- Note: INSERT INTO Internal.CIDToMail block is commented out (removed 2016-03-07, was for SilverPop email integration)

---

## 3. Data Overview

| LoginID | CID | LoggedIn | IsVirtual | ClientTypeID | NumberOfConnections | Meaning |
|---------|-----|----------|-----------|-------------|--------------------|----|
| 185010147 | 555 | 2017-02-15 13:10 | 1 | 0 | 1 | Virtual (demo) account session; ClientTypeID=0 (unknown/API); last recorded session in this environment |
| 185010146 | 3641831 | 2016-12-14 08:26 | 1 | 0 | 1 | Demo account session, December 2016 |
| 185010145 | 36 | 2016-12-13 16:21 | 1 | 0 | 1 | Very early CID (36 = near-first eToro customer), demo session |
| 185010144 | 15281 | 2016-12-13 14:46 | 1 | 0 | 1 | Demo account, all rows share ClientTypeID=0 |
| 185010143 | 3641161 | 2016-12-13 14:25 | 1 | 0 | 1 | Standard demo session; all 1,644 rows are IsVirtual=1, ClientTypeID=0 |

*1,644 total rows; 1,644 unique CIDs (UNIQUE constraint). All rows have ClientTypeID=0 and IsVirtual=1. Date range: 2013-01-20 to 2017-02-15. All-virtual, all-ClientTypeID=0 data pattern suggests this environment holds only demo account sessions from an archived or non-production trade server instance.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | bigint | NO | - | CODE-BACKED | Surrogate PK for the active session. Assigned by the trade server (not IDENTITY - centralized assignment, similar to MessageQueueID pattern). Referenced by BackOffice.LastCustomerInfo.LoginID after trigger propagation. |
| 2 | CID | int | NO | - | VERIFIED | Customer identifier. FK to Customer.CustomerStatic. UNIQUE constraint UK_CID_CLOG enforces one active session per customer. Used by financial procedures to verify session presence. |
| 3 | ActionID | bigint | YES | - | NAME-INFERRED | Action identifier associated with this login session. Nullable - purpose not determinable from DDL or procedure analysis in this scope. Likely references a trade or action log table. |
| 4 | LoggedIn | datetime | NO | getdate() | VERIFIED | Timestamp when the session was established (login time). Defaults to getdate() at insert. Indexed by CLOG_LOGGEDIN (DESC) to support "most recently logged in" queries. |
| 5 | NumberOfConnections | int | NO | 1 | CODE-BACKED | Count of concurrent connections within this session. Defaults to 1; incremented when the same session opens additional connections (e.g., multi-tab browser sessions). All rows in this environment show 1. |
| 6 | IP | varchar(15) | NO | - | CODE-BACKED | IPv4 address of the customer's client at login time (max 15 chars = "255.255.255.255"). Captured for security auditing and fraud detection. |
| 7 | ClientVersion | varchar(20) | NO | - | CODE-BACKED | Version string of the trading client application at login. Combined with ClientTypeID, identifies the exact platform+version for support and analytics. |
| 8 | MACID | char(17) | YES | - | CODE-BACKED | MAC address of the client machine (format: "XX:XX:XX:XX:XX:XX", 17 chars). NULL when not available (e.g., web clients cannot provide MAC addresses; only native desktop clients can). |
| 9 | CustomerSessionID | uniqueidentifier | NO | - | VERIFIED | GUID uniquely identifying this session instance. Primary session token used by the trade server to authenticate requests - the unique index ix_IX_CULG_SessionIDIncCID supports fast session lookup by this value. |
| 10 | IsVirtual | bit | NO | - | VERIFIED | Distinguishes demo (virtual) from real account sessions. 0 = real account logged in. 1 = demo/virtual account session. On this environment: all 1,644 rows are IsVirtual=1 (demo environment only). |
| 11 | LobbyID | int | YES | - | NAME-INFERRED | Lobby/room identifier for session grouping. NULL in all sampled rows - possibly deprecated or unused in recent versions. May have been used for multi-room trading environments. |
| 12 | ClientTypeID | tinyint | YES | 0 | VERIFIED | Platform type of the client application. FK to Dictionary.ClientType. 0 = Unknown (default per DFCL_ClientTypeID). Values: 0=Unknown, 1=Desktop, 2=WebTrader, 3=Android, 4=iPhone, 5=OpenBook, 6=OpenBook Mobile, 7=CopyMe. All rows on this environment have ClientTypeID=0. See [Dictionary.ClientType](../../Dictionary/Tables/Dictionary.ClientType.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_CLOG) | Every active session must belong to a registered customer |
| ClientTypeID | Dictionary.ClientType | FK (FK_CL_CTID) | Client platform classification; 0=Unknown is the default |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.LoggedCustomer | CID, LoginID | View (base table) | Exposes active sessions for application consumption |
| Customer.SetBalance | CID | Reader (EXISTS check) | Checks customer session presence as part of financial operation authorization |
| Customer.SetBalanceCompensation | CID | Reader (EXISTS check) | Same pattern - session check for compensation operations |
| Customer.SetBalanceDeposit | CID | Reader (EXISTS check) | Session presence check for deposit processing |
| LoginInsert (trigger) | CID, LoginID | Internal | AFTER INSERT trigger propagates LoginID to BackOffice.LastCustomerInfo |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Login (table)
```
Tables are leaf nodes - no code-level dependencies in CREATE TABLE (trigger side effects go to BackOffice.LastCustomerInfo at runtime but are not structural dependencies).

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID |
| Dictionary.ClientType | Table | FK target for ClientTypeID - platform classification lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.LoggedCustomer | View | Reads active session rows to present currently logged-in customers |
| Customer.SetBalance | Stored Procedure | Reader - NOT EXISTS check for session presence |
| Customer.SetBalanceCompensation | Stored Procedure | Reader - NOT EXISTS check |
| Customer.SetBalanceDeposit | Stored Procedure | Reader - NOT EXISTS check |
| BackOffice.LastCustomerInfo | Table | Written by LoginInsert trigger on every login event |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CLOG | Clustered PK | LoginID ASC | - | - | Active |
| UK_CID_CLOG | Unique NC | CID ASC | - | - | Active |
| CLOG_LOGGEDIN | NC | LoggedIn DESC | - | - | Active |
| ix_IX_CULG_SessionIDIncCID | Unique NC | CustomerSessionID ASC | CID | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| HLOG_LOGGED | DEFAULT | LoggedIn = getdate() |
| HLOG_CONNECTION | DEFAULT | NumberOfConnections = 1 |
| DFCL_ClientTypeID | DEFAULT | ClientTypeID = 0 (Unknown platform) |
| FK_CCST_CLOG | FK | CID -> Customer.CustomerStatic(CID) |
| FK_CL_CTID | FK | ClientTypeID -> Dictionary.ClientType(ClientTypeID) |
| LoginInsert | TRIGGER (FOR INSERT) | On login: updates or inserts BackOffice.LastCustomerInfo with the new LoginID |

---

## 8. Sample Queries

### 8.1 Get all currently active sessions with client platform details
```sql
SELECT
    cl.LoginID,
    cl.CID,
    cl.LoggedIn,
    cl.IP,
    cl.ClientVersion,
    cl.IsVirtual,
    cl.NumberOfConnections,
    ct.ClientTypeName,
    cl.CustomerSessionID
FROM Customer.Login cl WITH (NOLOCK)
INNER JOIN Dictionary.ClientType ct WITH (NOLOCK)
    ON ct.ClientTypeID = cl.ClientTypeID
ORDER BY cl.LoggedIn DESC;
```

### 8.2 Look up session by session GUID (trade server session validation)
```sql
SELECT
    cl.CID,
    cl.LoginID,
    cl.IsVirtual,
    cl.LoggedIn,
    cl.IP,
    cl.ClientTypeID
FROM Customer.Login cl WITH (NOLOCK)
WHERE cl.CustomerSessionID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
```

### 8.3 Check if a specific customer is currently logged in
```sql
SELECT
    CASE WHEN EXISTS (
        SELECT 1 FROM Customer.Login WITH (NOLOCK) WHERE CID = 12345
    ) THEN 'Logged In' ELSE 'Not Logged In' END AS SessionStatus,
    cl.LoggedIn,
    cl.IP,
    cl.ClientTypeID
FROM Customer.Login cl WITH (NOLOCK)
WHERE cl.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED (ActionID, LobbyID) | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (SetBalance variants) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.Login | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.Login.sql*
