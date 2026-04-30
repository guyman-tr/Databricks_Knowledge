# History.LogOutByLoginID

> Login-specific logout procedure that closes a single active session identified by LoginID (rather than all sessions for a CID), archives it to History.Login, fires logout events, and recalculates player level - with enhanced TRY/CATCH error logging via History.InsertLogErrorGeneral.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ActionID (used as LoginID input) - the specific session to close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogOutByLoginID` is the LoginID-specific variant of the customer logout procedures. While `History.LogOutByCID` closes ALL active sessions for a CID, this procedure closes only the specific session identified by `@ActionID` (which, despite its name, carries the LoginID value - per the inline comment "This is the LoginID"). This targeted logout is used when the caller knows exactly which login session to terminate, rather than performing a broad logout of all sessions.

The procedure performs the same core flow as `History.LogOutByCID`: deletes the specific session from `Customer.Login`, archives it to `History.Login`, fires logout events, checks for first-deposit prompt eligibility, and recalculates player level. The key improvements over `History.LogOutByCID` are: (1) the DELETE targets a specific LoginID rather than all CID sessions, (2) it uses modern `BEGIN TRY/CATCH` error handling instead of @@ERROR checks, and (3) on error it calls `History.InsertLogErrorGeneral` to log the failure with full XML parameter context before re-raising.

The `@ActionID` parameter serves dual purpose - it is supplied as the LoginID to close (INPUT role) and receives the ActionID of the closed session back (OUTPUT role), as noted in the comment "Dudu sends the LoginID value."

---

## 2. Business Logic

### 2.1 LoginID-Specific Session Termination

**What**: Only the single session identified by LoginID=@ActionID is closed, unlike LogOutByCID which closes all sessions for the CID.

**Columns/Parameters Involved**: `@ActionID`, `Customer.Login.LoginID`, `@CID`

**Rules**:
- Guard: `IF NOT EXISTS (SELECT 1 FROM Customer.Login WHERE LoginID = @ActionID)` -> RETURN 0 (session not found or already closed)
- DELETE FROM Customer.Login WHERE LoginID = @ActionID (not WHERE CID=@CID)
- Comment: "Dudu sends the LoginID value" - the caller passes the LoginID in the @ActionID parameter
- @CID is still required for: Customer.Customer lookups, first-deposit check, player level recalculation, and SendEvent calls
- History.Login INSERT: same as LogOutByCID - archives the deleted row with NumberOfConnections=0

### 2.2 Direct Player Level Update (No Stored Procedure Call)

**What**: Player level promotion is applied via a direct UPDATE statement rather than calling Customer.SetPlayerLevel, consolidating the two writes into one.

**Columns/Parameters Involved**: `Customer.Customer.PlayerLevelID`, `Customer.Customer.LotCountGroupID`, `@CalculatedPlayerLevelID`, `@LotCountGroupForUpdate`

**Rules**:
- Guarded by IF @CurrentPlayerLevelID <> 4 (same guard as current LogOutByCID, NOT present in _OLD)
- On promotion: single UPDATE CCST SET LotCountGroupID=@LotCountGroupForUpdate, PlayerLevelID=@CalculatedPlayerLevelID FROM Customer.Customer WHERE CID=@CID
- Comment: "Don't use the procedure, update in single statement (Easy)" - explains why Customer.SetPlayerLevel is not called here (direct UPDATE is simpler and avoids a procedure call round-trip)
- LogOutByCID calls Customer.SetPlayerLevel + separate Customer.Customer UPDATE for LotCountGroupID; LogOutByLoginID combines both into one UPDATE

### 2.3 TRY/CATCH with History.InsertLogErrorGeneral

**What**: On any error, the procedure logs the failure to the central error log with full XML parameter context before re-raising.

**Columns/Parameters Involved**: `History.InsertLogErrorGeneral`, `@Param_XML`, `@CID`, `@ActionID`, `@NumberOfConnections`

**Rules**:
- CATCH block: builds @Param_XML = SELECT @CID, @ActionID, @NumberOfConnections FOR XML RAW('LogOutByCID') (note: XML tag says 'LogOutByCID', not 'LogOutByLoginID')
- Calls History.InsertLogErrorGeneral with all error context: procedure name 'History.LogOutByLoginID', @Param_XML, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
- Transaction handling in CATCH: `IF @@trancount = 1 ROLLBACK TRAN; IF @@trancount > 1 COMMIT` (handles both top-level and nested transaction scenarios)
- After InsertLogErrorGeneral: RAISERROR(@Msg_Error,16,1) + RETURN 60000

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose session is being closed. Used for Customer.Customer lookups (IsReal, Credit, PlayerLevelID), first-deposit check, and SendEvent calls. The DELETE targets the specific LoginID in @ActionID, not all sessions for this CID. |
| 2 | @ActionID | BIGINT | NO (INPUT + OUTPUT) | - | CODE-BACKED | Dual-role parameter: (1) INPUT - the LoginID of the specific session to close (comment: "This is the LoginID", "Dudu sends the LoginID value"). (2) OUTPUT - after the DELETE, this is updated to the ActionID value from the deleted Customer.Login row. Returns 0 behavior if the LoginID is not found. |
| 3 | @NumberOfConnections | INTEGER | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: Connection count from the deleted session row. Set to 0 (initialized) if no session is found. Set to the NumberOfConnections value from the deleted Customer.Login row if the session was successfully closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.Login | Reads + Deletes | Guard check WHERE LoginID=@ActionID; DELETE WHERE LoginID=@ActionID (not all CID sessions) |
| (body) | History.Login | Writes (INSERT) | Archives the closed session with NumberOfConnections=0 |
| (body) | Customer.Customer | Reads + Modifies | Reads PlayerLevelID/IsReal/Credit; UPDATE LotCountGroupID + PlayerLevelID on promotion |
| (body) | BackOffice.CustomerAllTimeAggregatedData | Reads | TotalInvestment check for first-deposit prompt |
| (body) | Dictionary.PlayerLevel | Reads | Sort values for player level comparison |
| (body) | Dictionary.LotCountGroup | Reads | LotCountGroupID for the promoted player level |
| (body) | Internal.CleanupGames | Calls (EXEC) | Pre-transaction game state cleanup for @CID |
| (body) | Customer.SendMessage | Calls (EXEC) | First-deposit prompt for new real customers with no investment |
| (body) | Customer.SendEvent | Calls (EXEC) | Logout events: 11=any, 13=demo, 15=real |
| (body) | BackOffice.GetPlayerLevel | Calls (EXEC OUTPUT) | Computes new player level |
| (body) | History.InsertLogErrorGeneral | Calls (EXEC) | Logs errors with full XML parameter context in the CATCH block |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Login/session management application | - | Caller | Called when a specific LoginID needs to be closed; no callers found in SSDT repository |
| History.LogIn | (body) | Calls (EXEC) | Called when an existing open session is detected for @CID during login; force-closes the prior session before creating the new one |
| History.LogOutByLobbyID | (body) | Calls (EXEC) | Called in a cursor loop for each active session in a lobby; performs bulk lobby-wide logout |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogOutByLoginID (procedure)
+-- Customer.Login (table - specific LoginID DELETE + guard check)
+-- History.Login (table - INSERT target)
+-- Customer.Customer (table - reads + direct UPDATE on promotion)
+-- BackOffice.CustomerAllTimeAggregatedData (table - TotalInvestment check)
+-- Dictionary.PlayerLevel (table - Sort values)
+-- Dictionary.LotCountGroup (table - LotCountGroupID for promotion)
+-- Internal.CleanupGames (procedure)
+-- Customer.SendMessage (procedure)
+-- Customer.SendEvent (procedure)
+-- BackOffice.GetPlayerLevel (procedure)
+-- History.InsertLogErrorGeneral (procedure - error logging in CATCH)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | Guard check WHERE LoginID=@ActionID; DELETE WHERE LoginID=@ActionID |
| History.Login | Table | INSERT - archives closed session with NumberOfConnections=0 |
| Customer.Customer | Table | Reads PlayerLevelID, IsReal, Credit; direct UPDATE LotCountGroupID + PlayerLevelID on promotion |
| BackOffice.CustomerAllTimeAggregatedData | Table | TotalInvestment check |
| Dictionary.PlayerLevel | Table | Sort values for level comparison |
| Dictionary.LotCountGroup | Table | LotCountGroupID for promoted level |
| Internal.CleanupGames | Procedure | Pre-transaction cleanup |
| Customer.SendMessage | Procedure | First-deposit prompt |
| Customer.SendEvent | Procedure | Logout events |
| BackOffice.GetPlayerLevel | Procedure | New player level calculation |
| History.InsertLogErrorGeneral | Procedure | Error logging with XML params in CATCH block |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called by the login/session management application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Uses BEGIN TRY / BEGIN CATCH (modern pattern) vs @@ERROR checks in LogOutByCID
- @ActionID parameter comment: "This is the LoginID" - the parameter name is misleading; it carries the LoginID value as both input and output
- Player level update: direct `UPDATE Customer.Customer SET LotCountGroupID=..., PlayerLevelID=...` vs LogOutByCID's approach of calling Customer.SetPlayerLevel + separate UPDATE
- CATCH transaction handling: checks both @@trancount=1 (ROLLBACK) and @@trancount>1 (COMMIT) - handles the nested transaction case
- InsertLogErrorGeneral XML tag: `FOR XML RAW('LogOutByCID')` - the XML element name says 'LogOutByCID' rather than 'LogOutByLoginID' (minor inconsistency in error logging)
- The INSERT to History.Login has a TODO comment: "If the performance is not good I can send the row to queue --> asynchronous insert to History.Login"
- Does NOT have the debug `SELECT * FROM @Output` statement that exists in LogOutByCID and LogOutByCID_OLD
- RETURN codes: 0=success or no session found, 60000=error

---

## 8. Sample Queries

### 8.1 Close a specific login session by LoginID

```sql
DECLARE @LoginID BIGINT = 987654321  -- the LoginID to close
DECLARE @NumberOfConnections INT

EXEC History.LogOutByLoginID
    @CID                  = 12345,
    @ActionID             = @LoginID OUTPUT,  -- pass LoginID; gets ActionID back
    @NumberOfConnections  = @NumberOfConnections OUTPUT

SELECT @LoginID AS ActionIDReturned, @NumberOfConnections AS NumberOfConnections
```

### 8.2 Find a specific active session before targeted logout

```sql
SELECT
    LoginID,
    CID,
    ActionID,
    LoggedIn,
    NumberOfConnections,
    IsVirtual,
    IP,
    ClientVersion
FROM Customer.Login WITH (NOLOCK)
WHERE LoginID = @LoginID
```

### 8.3 View recent error log entries from LogOutByLoginID failures

```sql
SELECT TOP 10
    LogID,
    ProcedureName,
    ErrorMessage,
    ErrorNumber,
    ErrorLine,
    CreatedDate
FROM History.LogErrorGeneral WITH (NOLOCK)
WHERE ProcedureName = 'History.LogOutByLoginID'
ORDER BY CreatedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogOutByLoginID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogOutByLoginID.sql*
