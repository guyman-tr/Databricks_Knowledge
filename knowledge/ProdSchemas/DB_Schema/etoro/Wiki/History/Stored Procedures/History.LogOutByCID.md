# History.LogOutByCID

> Customer logout procedure that atomically deletes all active login sessions for a CID from Customer.Login, archives them to History.Login, fires logout events, and recalculates the customer's player level on logout.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer being logged out |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogOutByCID` is the primary customer logout handler. When a customer logs out or is logged out by the platform (e.g., session expiry, forced logout), this procedure is called to terminate all active sessions for that CID. It atomically deletes all rows from `Customer.Login` (the live session store) and archives them into `History.Login` (the permanent login history) with `NumberOfConnections=0` to mark them as closed.

Beyond session management, the procedure performs several additional logout-time operations that must occur on every logout: it cleans up any in-progress game state (`Internal.CleanupGames`), sends logout notification events to downstream systems (`Customer.SendEvent` with event IDs 11/13/15), checks if a real customer with no investment needs to be prompted for a first deposit (`Customer.SendMessage`), and recalculates the customer's player level in case they qualify for an upgrade.

The procedure existed in two versions: the current `History.LogOutByCID` and the legacy `History.LogOutByCID_OLD`. The `_OLD` version is superseded but retained in the codebase. `History.LogOutByLoginID` wraps this procedure for login-ID-specific logouts.

---

## 2. Business Logic

### 2.1 Session Termination - DELETE-and-Archive Pattern

**What**: All active login records for the CID are deleted from the live session table and immediately inserted into the permanent history table in one transaction.

**Columns/Parameters Involved**: `Customer.Login`, `History.Login`, `@CID`, `@DeletedRows`, `@Output`

**Rules**:
- Guard: if no row in Customer.Login WHERE CID=@CID -> RETURN 0 immediately (customer has no active sessions)
- DELETE FROM Customer.Login WHERE CID=@CID with OUTPUT clause -> captures all deleted rows into @Output table variable
- If @DeletedRows >= 1: INSERT into History.Login from @Output, with NumberOfConnections=0 (forced to 0, marking session as closed)
- If @DeletedRows = 0: skip History.Login INSERT (no sessions were open)
- Wrapped in BEGIN TRANSACTION / COMMIT TRANSACTION for atomicity
- On @@ERROR after DELETE or INSERT: ROLLBACK + RAISERROR(60000,16,1,'History.LogOutByCID',@LocalError) + RETURN 60000
- Note: `SELECT * FROM @Output` exists as an unguarded inline debug statement - returns the @Output table variable as a result set to the caller regardless of @DeletedRows

**Diagram**:
```
[Caller: logout event]
        |
        v
Internal.CleanupGames(@CID) -- outside transaction per Misha's change
        |
        v
IF NOT EXISTS Customer.Login WHERE CID=@CID --> RETURN 0 (no sessions)
        |
        v
BEGIN TRANSACTION
  DELETE Customer.Login WHERE CID=@CID
  OUTPUT DELETED.* INTO @Output
        |
  IF @DeletedRows >= 1:
    INSERT History.Login FROM @Output (NumberOfConnections=0)
        |
COMMIT TRANSACTION
```

### 2.2 @ActionID Output - Logout State Signal

**What**: The @ActionID output parameter communicates the result of the logout operation to the caller.

**Columns/Parameters Involved**: `@ActionID` (OUTPUT), `@NumberOfConnections` (OUTPUT)

**Rules**:
- @ActionID = 0: customer does not exist in Customer.Login (never logged in or already fully logged out)
- If already logged out (no active sessions): @ActionID points to ActionID that opened the latest login
- If logged in with NumberOfConnections > 0: @ActionID points to the Action that opened the login (session still had active connections)
- If this logout caused the login to fully close (NumberOfConnections = 0): @ActionID points to the newly created logout action; @NumberOfConnections = 0
- @NumberOfConnections: the final connection count after logout (0 if the login was fully closed)

### 2.3 Logout-Time Events and First-Deposit Check

**What**: On logout of a real (non-virtual) session, the procedure fires system events and optionally sends a first-deposit prompt to new users with no investment.

**Columns/Parameters Involved**: `@IsVirtual`, `Customer.Customer.Credit`, `Customer.Customer.IsReal`, `BackOffice.CustomerAllTimeAggregatedData.TotalInvestment`

**Rules**:
- Only fires for @IsVirtual=0 (real browser/app sessions; skips virtual/demo game sessions)
- First-deposit prompt: IF Customer.Credit=0 AND Customer.IsReal=1 AND BackOffice.CustomerAllTimeAggregatedData.TotalInvestment=0 -> EXEC Customer.SendMessage @CIDASSTR, 2, ';' (sends first-deposit prompt message)
- Event 11: EXEC Customer.SendEvent 11, @CID - fires on any logout (real or demo)
- Event 15: EXEC Customer.SendEvent 15, @CID - fires only for Customer.IsReal=1 (real account logout)
- Event 13: EXEC Customer.SendEvent 13, @CID - fires only for Customer.IsReal=0 (demo account logout)
- If any SendEvent/SendMessage returns non-zero: RETURN the error code immediately

### 2.4 Player Level Recalculation on Logout

**What**: On logout, the customer's player level is recalculated to promote them if they now qualify for a higher level based on their trading activity.

**Columns/Parameters Involved**: `Customer.Customer.PlayerLevelID`, `Dictionary.PlayerLevel.Sort`, `@CalculatedPlayerLevelID`, `@CurrentPlayerLevelSort`, `@CalculatedPlayerLevelSort`

**Rules**:
- Skipped for PlayerLevelID=4 (Test Player Level - comment confirms: "don't calculate for Test Player Levels")
- Gets current Sort from Dictionary.PlayerLevel WHERE PlayerLevelID = @CurrentPlayerLevelID
- Calls BackOffice.GetPlayerLevel @CID, @CalculatedPlayerLevelID OUTPUT to compute the new level
- Gets calculated Sort from Dictionary.PlayerLevel WHERE PlayerLevelID = @CalculatedPlayerLevelID
- If @CalculatedPlayerLevelSort > @CurrentPlayerLevelSort (promotion only - no demotion):
  - EXEC Customer.SetPlayerLevel @CID, @CalculatedPlayerLevelID
  - UPDATE Customer.Customer.LotCountGroupID from Dictionary.LotCountGroup WHERE PlayerLevelID=@CalculatedPlayerLevelID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer being logged out. All active Customer.Login rows for this CID will be deleted and archived to History.Login. If no active sessions exist, the procedure returns 0 immediately with no changes. |
| 2 | @ActionID | BIGINT | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: The action identifier associated with the logout result. Returns 0 if the customer had no active sessions. Returns the ActionID of the login that was opened (if NumberOfConnections > 0 after delete) or the ActionID of the newly created logout action (if this logout fully closed the last connection). Used by the caller to track the login lifecycle. |
| 3 | @NumberOfConnections | INTEGER | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: The number of concurrent connections that remained after this logout. Set to 0 when this logout fully closes the last active session for the CID. Set to the pre-deletion NumberOfConnections from Customer.Login if the login was not fully closed. Initialized to 0 before the DELETE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.Login | Reads + Deletes | Reads to check existence; DELETEs all active sessions for @CID via OUTPUT into @Output |
| (body) | History.Login | Writes (INSERT) | Archives deleted Customer.Login rows with NumberOfConnections=0 |
| (body) | Customer.Customer | Reads | Reads PlayerLevelID for level recalculation; reads IsReal, Credit for first-deposit check |
| (body) | BackOffice.CustomerAllTimeAggregatedData | Reads | Checks TotalInvestment to determine if first-deposit prompt should be sent |
| (body) | Dictionary.PlayerLevel | Reads | Gets Sort values for current and calculated player levels to determine if promotion applies |
| (body) | Dictionary.LotCountGroup | Reads | Gets LotCountGroupID for the new player level to update Customer.Customer.LotCountGroupID |
| (body) | Internal.CleanupGames | Calls (EXEC) | Cleans up in-progress game state for the CID; executed before the transaction |
| (body) | Customer.SendMessage | Calls (EXEC) | Sends first-deposit prompt to new real customers with no investment on logout |
| (body) | Customer.SendEvent | Calls (EXEC) | Fires logout events: 11=any logout, 13=demo logout, 15=real logout |
| (body) | BackOffice.GetPlayerLevel | Calls (EXEC OUTPUT) | Calculates the new player level based on current trading activity |
| (body) | Customer.SetPlayerLevel | Calls (EXEC) | Promotes the customer to the newly calculated player level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LogOutByLoginID | (EXEC) | Caller | Calls LogOutByCID after resolving LoginID to CID for login-specific logout |
| Login/session management application | - | Caller | Called by the application session layer on logout; no direct SSDT callers beyond LogOutByLoginID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogOutByCID (procedure)
+-- Customer.Login (table - active sessions - DELETE source)
+-- History.Login (table - session history - INSERT target)
+-- Customer.Customer (table - PlayerLevelID, IsReal, Credit reads)
+-- BackOffice.CustomerAllTimeAggregatedData (table - TotalInvestment check)
+-- Dictionary.PlayerLevel (table - Sort values for level comparison)
+-- Dictionary.LotCountGroup (table - LotCountGroupID for level update)
+-- Internal.CleanupGames (procedure - pre-transaction game cleanup)
+-- Customer.SendMessage (procedure - first-deposit prompt)
+-- Customer.SendEvent (procedure - logout event notifications)
+-- BackOffice.GetPlayerLevel (procedure - calculates new player level)
+-- Customer.SetPlayerLevel (procedure - applies player level promotion)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | Existence check + DELETE with OUTPUT (source of session records to archive) |
| History.Login | Table | INSERT target - permanent archive of closed sessions |
| Customer.Customer | Table | Reads PlayerLevelID (level recalc), IsReal and Credit (first-deposit check) |
| BackOffice.CustomerAllTimeAggregatedData | Table | Reads TotalInvestment (first-deposit check) |
| Dictionary.PlayerLevel | Table | Reads Sort for level promotion comparison |
| Dictionary.LotCountGroup | Table | Reads LotCountGroupID for the promoted player level |
| Internal.CleanupGames | Procedure | EXEC @CID - cleans up game state before the transaction |
| Customer.SendMessage | Procedure | EXEC with CIDASSTR, message type 2 - first-deposit prompt |
| Customer.SendEvent | Procedure | EXEC with event IDs 11, 13, or 15 - logout events |
| BackOffice.GetPlayerLevel | Procedure | EXEC with OUTPUT - computes new player level |
| Customer.SetPlayerLevel | Procedure | EXEC - applies the new player level |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LogOutByLoginID | Stored Procedure | Calls this procedure after resolving LoginID to CID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `Internal.CleanupGames @CID` is executed BEFORE the transaction - changed by Misha per inline comment "Changed by Misha to be out of transaction" to avoid locking issues during game state cleanup
- Inline debug statement: `SELECT * FROM @Output` (line 138) is an unguarded SELECT that always returns the @Output table variable as a result set to the caller - this appears to be residual debugging code
- Error handling uses @@ERROR check after each DML (legacy pattern pre-TRY/CATCH) rather than BEGIN TRY
- Player level promotion is one-directional only: IF @CalculatedPlayerLevelSort > @CurrentPlayerLevelSort (only upgrades, never downgrades on logout)
- Commented-out code: Service Broker DIALOG/SEND blocks for aggregation and Dynamics (CRM) integration are preserved in comments as historical reference
- @Output table variable schema mirrors Customer.Login columns exactly, with LoggedTime as DATEDIFF(MINUTE, LoggedIn, @Occurred) capped at 7200 (comment: "more than 5 days, this is bug (market closed)")
- RETURN codes: 0=success, 60000=DML error (RAISERROR'd), non-zero from SendEvent/SendMessage on those failures

---

## 8. Sample Queries

### 8.1 Log out a customer by CID

```sql
DECLARE @ActionID BIGINT
DECLARE @NumberOfConnections INT

EXEC History.LogOutByCID
    @CID                  = 12345,
    @ActionID             = @ActionID OUTPUT,
    @NumberOfConnections  = @NumberOfConnections OUTPUT

SELECT @ActionID AS ActionID, @NumberOfConnections AS NumberOfConnections
```

### 8.2 Check active sessions for a CID before logout

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
WHERE CID = @CID
```

### 8.3 View the archived login history for a CID after logout

```sql
SELECT TOP 10
    LoginID,
    CID,
    ActionID,
    LoggedIn,
    LoggedOut,
    NumberOfConnections,
    IsVirtual,
    IP
FROM History.Login WITH (NOLOCK)
WHERE CID = @CID
ORDER BY LoggedIn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogOutByCID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogOutByCID.sql*
