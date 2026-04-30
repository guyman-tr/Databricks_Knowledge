# History.LogOutByCID_OLD

> Legacy version of the customer logout procedure, superseded by History.LogOutByCID. Identical logic except the player level recalculation runs for ALL player levels including PlayerLevelID=4 (Test) - the guard added in the current version is absent here.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer being logged out |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogOutByCID_OLD` is the legacy predecessor to `History.LogOutByCID`. Both procedures implement the same customer logout flow: delete all active sessions from `Customer.Login`, archive them to `History.Login`, fire logout events, check for first-deposit prompt eligibility, and recalculate player level on logout.

The `_OLD` suffix marks this as a deprecated version retained in the codebase for reference. It is not expected to be called in production. The key behavioral difference from the current version (`History.LogOutByCID`) is that the player level recalculation in `_OLD` does NOT have the `IF @CurrentPlayerLevelID <> 4` guard - it runs the player level calculation for ALL customers including test accounts (PlayerLevelID=4). The current version added this guard to avoid unnecessary computation for test accounts.

See `History.LogOutByCID` for the full business logic description - all logic sections apply equally to this _OLD version.

---

## 2. Business Logic

### 2.1 Identical to History.LogOutByCID

All business logic is identical to `History.LogOutByCID` (see that document for full details):
- Session termination: DELETE Customer.Login OUTPUT archived to History.Login
- @ActionID / @NumberOfConnections output semantics
- Internal.CleanupGames execution before transaction
- First-deposit prompt check (Credit=0, IsReal=1, no TotalInvestment)
- Customer.SendEvent: 11 (any logout), 15 (real logout), 13 (demo logout)
- Player level promotion: BackOffice.GetPlayerLevel + Customer.SetPlayerLevel + LotCountGroupID update

### 2.2 Difference from Current Version - Missing PlayerLevel Guard

**What**: The `_OLD` version runs player level recalculation for ALL customers, including test accounts (PlayerLevelID=4). The current version skips test accounts.

**Columns/Parameters Involved**: `@CurrentPlayerLevelID`, `Dictionary.PlayerLevel.Sort`

**Rules**:
- LogOutByCID (current): `IF @CurrentPlayerLevelID <> 4 BEGIN ... END` - skips player level computation for test accounts
- LogOutByCID_OLD (this): No such guard - player level recalculation runs unconditionally for all customers including PlayerLevelID=4 test accounts
- Consequence: test accounts trigger unnecessary BackOffice.GetPlayerLevel and potentially Customer.SetPlayerLevel calls on logout

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer being logged out. Identical semantics to History.LogOutByCID.@CID - all active Customer.Login rows for this CID are deleted and archived. |
| 2 | @ActionID | BIGINT | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: Same semantics as History.LogOutByCID.@ActionID - returns 0 if no active sessions, otherwise the ActionID of the login action. |
| 3 | @NumberOfConnections | INTEGER | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: Same semantics as History.LogOutByCID.@NumberOfConnections - connection count after logout (0 if fully closed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.Login | Reads + Deletes | Same as History.LogOutByCID - guard check + DELETE with OUTPUT |
| (body) | History.Login | Writes (INSERT) | Archives deleted sessions with NumberOfConnections=0 |
| (body) | Customer.Customer | Reads | PlayerLevelID, IsReal, Credit reads |
| (body) | BackOffice.CustomerAllTimeAggregatedData | Reads | TotalInvestment check for first-deposit prompt |
| (body) | Dictionary.PlayerLevel | Reads | Sort values for player level comparison |
| (body) | Dictionary.LotCountGroup | Reads | LotCountGroupID for the promoted player level |
| (body) | Internal.CleanupGames | Calls (EXEC) | Pre-transaction game state cleanup |
| (body) | Customer.SendMessage | Calls (EXEC) | First-deposit prompt for new real customers |
| (body) | Customer.SendEvent | Calls (EXEC) | Logout events: 11=any, 13=demo, 15=real |
| (body) | BackOffice.GetPlayerLevel | Calls (EXEC OUTPUT) | Computes new player level |
| (body) | Customer.SetPlayerLevel | Calls (EXEC) | Applies player level promotion |

### 5.2 Referenced By (other objects point to this)

This procedure is the superseded legacy version. No known callers. The active version `History.LogOutByCID` should be used instead.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogOutByCID_OLD (procedure)
+-- Customer.Login (table)
+-- History.Login (table)
+-- Customer.Customer (table)
+-- BackOffice.CustomerAllTimeAggregatedData (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.LotCountGroup (table)
+-- Internal.CleanupGames (procedure)
+-- Customer.SendMessage (procedure)
+-- Customer.SendEvent (procedure)
+-- BackOffice.GetPlayerLevel (procedure)
+-- Customer.SetPlayerLevel (procedure)
```

### 6.1 Objects This Depends On

Same as History.LogOutByCID - see that document for details.

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. This is the superseded legacy version.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Uses @@ERROR-based error handling (not BEGIN TRY) - same as the current version
- Contains the same residual `SELECT * FROM @Output` debug statement (line 138) that is unguarded
- Same commented-out Service Broker code (Aggregation, Dispatcher, Dynamics/CRM integrations)
- Key difference from current version: player level recalculation runs for ALL PlayerLevelIDs including 4 (no `IF @CurrentPlayerLevelID <> 4` guard)
- RAISERROR in error path references 'History.LogOutByCID' (not 'History.LogOutByCID_OLD') - the error message text was not updated when the _OLD copy was made

---

## 8. Sample Queries

### 8.1 This procedure is not expected to be called directly

```sql
-- Use History.LogOutByCID instead:
DECLARE @ActionID BIGINT
DECLARE @NumberOfConnections INT

EXEC History.LogOutByCID
    @CID                  = 12345,
    @ActionID             = @ActionID OUTPUT,
    @NumberOfConnections  = @NumberOfConnections OUTPUT
```

### 8.2 Compare behavior difference: check if a CID has PlayerLevelID=4

```sql
-- If PlayerLevelID=4, LogOutByCID_OLD would run GetPlayerLevel (wasteful)
-- while History.LogOutByCID skips it
SELECT CID, PlayerLevelID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = @CID
```

### 8.3 View archived login history (same query works for both versions)

```sql
SELECT TOP 10
    LoginID, CID, ActionID, LoggedIn, LoggedOut, NumberOfConnections
FROM History.Login WITH (NOLOCK)
WHERE CID = @CID
ORDER BY LoggedIn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogOutByCID_OLD | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogOutByCID_OLD.sql*
